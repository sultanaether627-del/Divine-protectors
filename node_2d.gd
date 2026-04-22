func _process(_delta: float) -> void:
	var current_tile = local_to_map(PLAYER.position)

	if current_tile != last_player_tile:
		last_player_tile = current_tile
		generate_chunk(PLAYER.position)


func generate_chunk(player_pos):
	var tile_pos = local_to_map(player_pos)

	for x in range(width):
		for y in range(height):
			var map_x = tile_pos.x + x - width // 2
			var map_y = tile_pos.y + y - height // 2
