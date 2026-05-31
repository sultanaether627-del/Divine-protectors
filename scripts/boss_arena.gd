extends Node2D

# Boss arena visual script.
# Prefers the new 64x64 tilesheet for a sharper look.
# Tiles are rendered at 32x32 world pixels so the arena fits 1280x720.

const TILE_SIZE: int = 32
const MAP_WIDTH: int = 40
const MAP_HEIGHT: int = 23

const STONE_TILES: Array[Vector2i] = [
	Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7),
	Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8),
	Vector2i(3, 9), Vector2i(4, 9), Vector2i(5, 9),
	Vector2i(3, 10), Vector2i(4, 10), Vector2i(5, 10),
	Vector2i(3, 11), Vector2i(4, 11), Vector2i(5, 11),
	Vector2i(3, 12), Vector2i(4, 12), Vector2i(5, 12)
]

const BROWN_TILES: Array[Vector2i] = [
	Vector2i(6, 9), Vector2i(7, 9),
	Vector2i(6, 10), Vector2i(7, 10),
	Vector2i(6, 11), Vector2i(7, 11), Vector2i(8, 11),
	Vector2i(6, 12), Vector2i(7, 12), Vector2i(8, 12)
]

const ALTAR_TOP_LEFT: Vector2i = Vector2i(9, 11)
const ALTAR_TOP_RIGHT: Vector2i = Vector2i(10, 11)
const ALTAR_BOTTOM_LEFT: Vector2i = Vector2i(9, 12)
const ALTAR_BOTTOM_RIGHT: Vector2i = Vector2i(10, 12)
const PILLAR_TOP: Vector2i = Vector2i(12, 10)
const PILLAR_MID: Vector2i = Vector2i(12, 11)
const PILLAR_BASE: Vector2i = Vector2i(12, 12)
const RUBBLE_TILE: Vector2i = Vector2i(14, 12)

@onready var boss_node: Node = $Boss
@onready var enemy_spawner: Node = $BossEnemySpawner
@onready var victory_menu: CanvasLayer = $BossVictoryMenu
@onready var boss_health_bar: ProgressBar = $BossCanvas/BossHealthBar

var arena_visuals: Node2D
var tile_texture: Texture2D = null
var tile_pixel_size: int = 64
var tile_scale: float = 0.5


func _ready() -> void:
	_build_arena_visuals()
	await get_tree().process_frame
	_connect_boss_flow()


func _find_tiles_texture() -> Texture2D:
	# Prefer the new 64x64 tilesheet first for the sharpest look.
	var paths: Array[String] = [
		"res://scripts/64x64 new (1).png",
		"res://tiles 64x64.png",
		"res://tiles.png",
		"res://scripts/tiles.png"
	]

	for path in paths:
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex:
				return tex

	push_error("BossArena: Could not find tiles texture.")
	return null


func _build_arena_visuals() -> void:
	arena_visuals = Node2D.new()
	arena_visuals.name = "ArenaVisuals"
	arena_visuals.z_index = -40
	add_child(arena_visuals)
	move_child(arena_visuals, 0)

	tile_texture = _find_tiles_texture()
	if tile_texture == null:
		return

	# Detect tile pixel size from texture width.
	# The new 64x64 sheet is wide; the old 16px sheet is narrow.
	if tile_texture.get_width() >= 512:
		tile_pixel_size = 64
	else:
		tile_pixel_size = 16
	# Scale so every tile occupies TILE_SIZE x TILE_SIZE world pixels.
	tile_scale = float(TILE_SIZE) / float(tile_pixel_size)

	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			_add_tile(x, y, _pick_ground_tile(x, y), 0)

	_build_paths()
	_build_pedestal()
	_build_center_altar()
	_build_pillars()
	_scatter_rubble()


func _make_atlas_texture(atlas_coords: Vector2i) -> AtlasTexture:
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = tile_texture
	atlas_tex.region = Rect2(
		atlas_coords.x * tile_pixel_size,
		atlas_coords.y * tile_pixel_size,
		tile_pixel_size,
		tile_pixel_size
	)
	return atlas_tex


func _add_tile(x: int, y: int, atlas_coords: Vector2i, z: int = 0) -> void:
	var tile := Sprite2D.new()
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tile.centered = false
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	tile.scale = Vector2(tile_scale, tile_scale)
	tile.texture = _make_atlas_texture(atlas_coords)
	tile.z_index = z
	arena_visuals.add_child(tile)


func _pick_ground_tile(x: int, y: int) -> Vector2i:
	var edge_distance: int = mini(mini(x, MAP_WIDTH - 1 - x), mini(y, MAP_HEIGHT - 1 - y))
	var stone_index: int = absi((x * 17 + y * 29 + x * y) % STONE_TILES.size())
	var brown_index: int = absi((x * 11 + y * 7 + x * y) % BROWN_TILES.size())

	if edge_distance <= 2:
		return BROWN_TILES[brown_index]
	if edge_distance <= 4 and ((x + y) % 2 == 0):
		return BROWN_TILES[brown_index]

	if (x >= 8 and x <= MAP_WIDTH - 9 and (y == 7 or y == MAP_HEIGHT - 8)) or ((x == 8 or x == MAP_WIDTH - 9) and y >= 7 and y <= MAP_HEIGHT - 8):
		return BROWN_TILES[brown_index]

	return STONE_TILES[stone_index]


func _build_paths() -> void:
	# Main path from player spawn (bottom-centre) to boss (top-centre).
	for y in range(4, MAP_HEIGHT - 3):
		for x in range(18, 22):
			_add_tile(x, y, BROWN_TILES[(x + y) % BROWN_TILES.size()], 1)

	# Side lanes — horizontal corridors.
	for x in range(6, MAP_WIDTH - 6):
		for y in [6, 7, 15, 16]:
			_add_tile(x, y, BROWN_TILES[(x + y) % BROWN_TILES.size()], 1)

	# Player staging area (bottom section).
	for y in range(17, 21):
		for x in range(14, 26):
			_add_tile(x, y, BROWN_TILES[(x + y) % BROWN_TILES.size()], 1)


func _build_pedestal() -> void:
	# Boss platform — raised area at top-centre.
	for y in range(2, 7):
		for x in range(15, 25):
			_add_tile(x, y, BROWN_TILES[(x + y) % BROWN_TILES.size()], 2)

	for y in range(3, 6):
		for x in range(17, 23):
			_add_tile(x, y, STONE_TILES[(x + y) % STONE_TILES.size()], 3)

	_add_tile(19, 3, ALTAR_TOP_LEFT, 4)
	_add_tile(20, 3, ALTAR_TOP_RIGHT, 4)
	_add_tile(19, 4, ALTAR_BOTTOM_LEFT, 4)
	_add_tile(20, 4, ALTAR_BOTTOM_RIGHT, 4)

	for x in range(16, 24):
		if x % 3 == 0:
			_add_tile(x, 6, RUBBLE_TILE, 4)
		else:
			_add_tile(x, 6, PILLAR_BASE, 4)


func _build_center_altar() -> void:
	_add_tile(19, 11, ALTAR_TOP_LEFT, 4)
	_add_tile(20, 11, ALTAR_TOP_RIGHT, 4)
	_add_tile(19, 12, ALTAR_BOTTOM_LEFT, 4)
	_add_tile(20, 12, ALTAR_BOTTOM_RIGHT, 4)


func _build_pillars() -> void:
	var pillar_columns: Array[Vector2i] = [
		Vector2i(7, 5),  Vector2i(32, 5),
		Vector2i(7, 14), Vector2i(32, 14),
		Vector2i(12, 10), Vector2i(27, 10),
		Vector2i(12, 13), Vector2i(27, 13)
	]

	for pillar_pos in pillar_columns:
		_add_tile(pillar_pos.x, pillar_pos.y, PILLAR_TOP, 5)
		_add_tile(pillar_pos.x, pillar_pos.y + 1, PILLAR_MID, 5)
		_add_tile(pillar_pos.x, pillar_pos.y + 2, PILLAR_BASE, 5)


func _scatter_rubble() -> void:
	var rubble_positions: Array[Vector2i] = [
		Vector2i(4, 3), Vector2i(7, 2), Vector2i(32, 2), Vector2i(35, 3),
		Vector2i(3, 6), Vector2i(36, 6), Vector2i(3, 17), Vector2i(36, 17),
		Vector2i(5, 20), Vector2i(34, 20), Vector2i(10, 3), Vector2i(29, 3),
		Vector2i(11, 18), Vector2i(28, 18), Vector2i(17, 1), Vector2i(22, 1)
	]

	for rubble_pos in rubble_positions:
		_add_tile(rubble_pos.x, rubble_pos.y, RUBBLE_TILE, 5)


func _connect_boss_flow() -> void:
	if boss_node and boss_node.has_signal("boss_defeated") and not boss_node.is_connected("boss_defeated", Callable(self, "_on_boss_defeated")):
		boss_node.connect("boss_defeated", Callable(self, "_on_boss_defeated"))


func _on_boss_defeated() -> void:
	if enemy_spawner:
		enemy_spawner.set("disabled", true)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()

	if boss_health_bar:
		boss_health_bar.visible = false

	if victory_menu and victory_menu.has_method("show_victory_menu"):
		victory_menu.call("show_victory_menu")
