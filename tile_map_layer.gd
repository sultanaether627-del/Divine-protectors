extends TileMapLayer

var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()

var width = 64
var height = 64

@onready var PLAYER = get_parent().get_child(1)

var generated_tiles = {}
var last_player_tile = Vector2i(999999, 999999)

func _ready() -> void:
	randomize()

	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()

	moisture.frequency = 0.02
	temperature.frequency = 0.02
	altitude.frequency = 0.02


func _process(delta: float) -> void:
	var current_tile = local_to_map(PLAYER.position)

	if current_tile != last_player_tile:
		last_player_tile = current_tile
		generate_chunk(PLAYER.position)


func generate_chunk(position):
	var tile_pos = local_to_map(position)

	for x in range(width):
		for y in range(height):
			var map_x = tile_pos.x + x - width / 2
			var map_y = tile_pos.y + y - height / 2
			var current_tile = Vector2i(map_x, map_y)

			if generated_tiles.has(current_tile):
				continue

			var m = moisture.get_noise_2d(map_x, map_y)
			var t = temperature.get_noise_2d(map_x, map_y)
			var a = altitude.get_noise_2d(map_x, map_y)

			var atlas_coords = Vector2i(0, 0)

			if a < -0.2:
				atlas_coords = Vector2i(0, 0)
			elif a < -0.05:
				atlas_coords = Vector2i(1, 0)
			elif m > 0.3:
				atlas_coords = Vector2i(3, 0)
			elif t < -0.3:
				atlas_coords = Vector2i(4, 0)
			elif m > 0 and t > 0:
				atlas_coords = Vector2i(2, 0)
			else:
				atlas_coords = Vector2i(5, 0)

			set_cell(current_tile, 0, atlas_coords)
			generated_tiles[current_tile] = true
