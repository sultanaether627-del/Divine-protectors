extends Node2D

const DEBUG_SPAWN := false

@export var enemy_scene: PackedScene = preload("res://tscn/enemy.tscn")
@export var fast_enemy_scene: PackedScene = preload("res://tscn/enemy_fast.tscn")
@export var tank_enemy_scene: PackedScene = preload("res://tscn/enemy_tank.tscn")

@export var starting_spawn_time: float = 1.0
@export var minimum_spawn_time: float = 0.18
@export var spawn_time_decrease: float = 0.08
@export var difficulty_increase_interval: float = 6.0

@export var spawn_distance: float = 420.0
@export var max_enemies: int = 100
@export var spawn_immediately: bool = true
@export var disabled: bool = false

# KEEP THIS ON so enemies cannot spawn outside your arena.
@export var clamp_spawn_to_rect: bool = true

# CHANGE THESE IN THE INSPECTOR TO MATCH YOUR MAP.
# Put the values INSIDE the wall border, not outside.
@export var spawn_rect_min: Vector2 = Vector2(-2500, -900)
@export var spawn_rect_max: Vector2 = Vector2(2500, 900)

# Safety space from the walls.
@export var spawn_margin: float = 64.0

# Fast enemies start appearing after 2 minutes.
@export var fast_enemy_unlock_time: float = 120.0
@export var fast_enemy_spawn_chance: float = 0.35

# Tank enemies start appearing after 2.5 minutes.
@export var tank_enemy_unlock_time: float = 150.0
@export var tank_enemy_spawn_chance: float = 0.20

var player: Node2D
var current_spawn_time: float = 1.0
var elapsed_game_time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		push_error("EnemySpawner: No player found. The Player must be in the 'player' group.")
		return

	if enemy_scene == null:
		push_error("EnemySpawner: enemy_scene is missing.")
		return

	current_spawn_time = starting_spawn_time

	if spawn_immediately and not get_tree().paused:
		spawn_enemy()

	spawn_loop()
	difficulty_loop()

	if DEBUG_SPAWN:
		print("EnemySpawner started")


func _process(delta: float) -> void:
	if not get_tree().paused and not disabled:
		elapsed_game_time += delta


func spawn_loop() -> void:
	while true:
		await get_tree().create_timer(current_spawn_time, false).timeout

		if not get_tree().paused and not disabled:
			spawn_enemy()


func difficulty_loop() -> void:
	while true:
		await get_tree().create_timer(difficulty_increase_interval, false).timeout

		if not get_tree().paused and not disabled:
			current_spawn_time = max(
				minimum_spawn_time,
				current_spawn_time - spawn_time_decrease
			)
			print("New spawn time: ", current_spawn_time)


func spawn_enemy() -> void:
	if get_tree().paused or disabled:
		return

	if player == null:
		return

	if enemy_scene == null:
		return

	if get_tree().get_nodes_in_group("enemy").size() >= max_enemies:
		return

	var scene_to_spawn: PackedScene = _choose_enemy_scene()

	if scene_to_spawn == null:
		return

	var enemy: Node2D = scene_to_spawn.instantiate() as Node2D

	if enemy == null:
		return

	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE

	get_tree().current_scene.add_child(enemy)

	var spawn_pos: Vector2 = _get_spawn_position()
	enemy.global_position = spawn_pos


func _choose_enemy_scene() -> PackedScene:
	var scene_to_spawn: PackedScene = enemy_scene

	if elapsed_game_time >= tank_enemy_unlock_time and tank_enemy_scene != null:
		if randf() <= tank_enemy_spawn_chance:
			scene_to_spawn = tank_enemy_scene
		elif elapsed_game_time >= fast_enemy_unlock_time and fast_enemy_scene != null:
			if randf() <= fast_enemy_spawn_chance:
				scene_to_spawn = fast_enemy_scene

	elif elapsed_game_time >= fast_enemy_unlock_time and fast_enemy_scene != null:
		if randf() <= fast_enemy_spawn_chance:
			scene_to_spawn = fast_enemy_scene

	return scene_to_spawn


func _get_spawn_position() -> Vector2:
	if not clamp_spawn_to_rect:
		var angle: float = randf_range(0.0, TAU)
		var spawn_offset: Vector2 = Vector2(cos(angle), sin(angle)) * spawn_distance
		return player.global_position + spawn_offset

	var left: float = min(spawn_rect_min.x, spawn_rect_max.x) + spawn_margin
	var right: float = max(spawn_rect_min.x, spawn_rect_max.x) - spawn_margin
	var top: float = min(spawn_rect_min.y, spawn_rect_max.y) + spawn_margin
	var bottom: float = max(spawn_rect_min.y, spawn_rect_max.y) - spawn_margin

	# Try to spawn around the player, but only if the position is inside the map.
	for i in range(40):
		var angle: float = randf_range(0.0, TAU)
		var spawn_offset: Vector2 = Vector2(cos(angle), sin(angle)) * spawn_distance
		var spawn_pos: Vector2 = player.global_position + spawn_offset

		if spawn_pos.x >= left and spawn_pos.x <= right and spawn_pos.y >= top and spawn_pos.y <= bottom:
			return spawn_pos

	# Backup: if it cannot spawn around the player, spawn anywhere inside the map.
	return Vector2(
		randf_range(left, right),
		randf_range(top, bottom)
	)
