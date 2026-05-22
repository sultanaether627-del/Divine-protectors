extends Node2D

# Final stable boss arena script.
# This does NOT use TileSetAtlasSource, because that caused the grey void / tile errors.
# It draws the arena with Sprite2D tiles directly from the existing tilesheet.

const TILE_SIZE: int = 16
const MAP_WIDTH: int = 80
const MAP_HEIGHT: int = 45

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
var tile_pixel_size: int = 16
var tile_scale: float = 1.0


func _ready() -> void:
	_build_arena_visuals()
	await get_tree().process_frame
	_connect_boss_flow()


func _find_tiles_texture() -> Texture2D:
	var paths: Array[String] = [
		"res://tiles.png",
		"res://tiles 64x64.png",
		"res://scripts/tiles.png"
	]

	for path in paths:
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex:
				return tex

	push_error("BossArena: Could not find tiles texture. Expected tiles.png or tiles 64x64.png.")
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

	# The project has used both 16px and 64px tilesheets.
	# Draw them all at 16x16 world size so the arena always fits 1280x720.
	if tile_texture.get_width() >= 1024:
		tile_pixel_size = 64
	else:
		tile_pixel_size = 16
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
	# Main path from player to boss.
	for y in range(8, MAP_HEIGHT - 6):
		for x in range(36, 44):
			_add_tile(x, y, BROWN_TILES[(x + y) % BROWN_TILES.size()], 1)

	# Side lanes.
	for x in range(13, MAP_WIDTH - 13):
		for y in [13, 14, 30, 31]:
			_add_tile(x, y, BROWN_TILES[(x + y) % BROWN_TILES.size()], 1)

	# Player staging area.
	for y in range(34, 40):
		for x in range(28, 52):
			_add_tile(x, y, BROWN_TILES[(x + y) % BROWN_TILES.size()], 1)


func _build_pedestal() -> void:
	# Boss platform, made only from existing tile pieces.
	for y in range(5, 12):
		for x in range(32, 48):
			_add_tile(x, y, BROWN_TILES[(x + y) % BROWN_TILES.size()], 2)

	for y in range(7, 10):
		for x in range(37, 43):
			_add_tile(x, y, STONE_TILES[(x + y) % STONE_TILES.size()], 3)

	_add_tile(39, 7, ALTAR_TOP_LEFT, 4)
	_add_tile(40, 7, ALTAR_TOP_RIGHT, 4)
	_add_tile(39, 8, ALTAR_BOTTOM_LEFT, 4)
	_add_tile(40, 8, ALTAR_BOTTOM_RIGHT, 4)

	for x in range(35, 45):
		if x % 3 == 0:
			_add_tile(x, 10, RUBBLE_TILE, 4)
		else:
			_add_tile(x, 10, PILLAR_BASE, 4)


func _build_center_altar() -> void:
	_add_tile(39, 22, ALTAR_TOP_LEFT, 4)
	_add_tile(40, 22, ALTAR_TOP_RIGHT, 4)
	_add_tile(39, 23, ALTAR_BOTTOM_LEFT, 4)
	_add_tile(40, 23, ALTAR_BOTTOM_RIGHT, 4)


func _build_pillars() -> void:
	var pillar_columns: Array[Vector2i] = [
		Vector2i(15, 10), Vector2i(64, 10),
		Vector2i(15, 29), Vector2i(64, 29),
		Vector2i(24, 20), Vector2i(55, 20),
		Vector2i(24, 25), Vector2i(55, 25)
	]

	for pillar_pos in pillar_columns:
		_add_tile(pillar_pos.x, pillar_pos.y, PILLAR_TOP, 5)
		_add_tile(pillar_pos.x, pillar_pos.y + 1, PILLAR_MID, 5)
		_add_tile(pillar_pos.x, pillar_pos.y + 2, PILLAR_BASE, 5)


func _scatter_rubble() -> void:
	var rubble_positions: Array[Vector2i] = [
		Vector2i(9, 6), Vector2i(14, 5), Vector2i(65, 5), Vector2i(70, 6),
		Vector2i(6, 12), Vector2i(73, 12), Vector2i(7, 34), Vector2i(72, 34),
		Vector2i(10, 39), Vector2i(68, 39), Vector2i(20, 7), Vector2i(59, 7),
		Vector2i(23, 36), Vector2i(56, 36), Vector2i(35, 4), Vector2i(44, 4)
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
