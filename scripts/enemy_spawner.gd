extends Node2D

@export var enemy_scene: PackedScene = preload("res://tscn/enemy.tscn")
@export var fast_enemy_scene: PackedScene = preload("res://tscn/enemy_fast.tscn")
@export var tank_enemy_scene: PackedScene = preload("res://tscn/enemy_tank.tscn")

@export var starting_spawn_time := 1.0
@export var minimum_spawn_time := 0.18
@export var spawn_time_decrease := 0.08
@export var difficulty_increase_interval := 6.0

@export var spawn_distance := 420.0
@export var max_enemies := 100
@export var spawn_immediately := true
@export var disabled := false

# Boss arena safety. Turn this on only for the boss-room spawner.
@export var clamp_spawn_to_rect := false
@export var spawn_rect_min := Vector2(80, 110)
@export var spawn_rect_max := Vector2(1200, 660)

# Fast enemies start appearing after 2 minutes.
@export var fast_enemy_unlock_time := 120.0
@export var fast_enemy_spawn_chance := 0.35

# Tank enemies start appearing after 2.5 minutes.
@export var tank_enemy_unlock_time := 150.0
@export var tank_enemy_spawn_chance := 0.20

var player: Node2D
var current_spawn_time := 1.0
var elapsed_game_time := 0.0


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

	print("EnemySpawner started")


func _process(delta: float) -> void:
	# This timer only increases during active gameplay, not while upgrade menus pause the game.
	if not get_tree().paused and not disabled:
		elapsed_game_time += delta


func spawn_loop() -> void:
	while true:
		# false = timer pauses while the upgrade menu pauses the game.
		await get_tree().create_timer(current_spawn_time, false).timeout

		if not get_tree().paused and not disabled:
			spawn_enemy()


func difficulty_loop() -> void:
	while true:
		# Difficulty also pauses during upgrade choices.
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

	if player == null or enemy_scene == null:
		return

	if get_tree().get_nodes_in_group("enemy").size() >= max_enemies:
		return

	var scene_to_spawn := _choose_enemy_scene()
	var enemy := scene_to_spawn.instantiate() as Node2D
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE

	# Add enemies to the active scene. Walls still collide globally, and boss-room
	# spawns are clamped below so they don't appear outside the arena borders.
	get_tree().current_scene.add_child(enemy)

	var spawn_pos := _get_spawn_position()
	enemy.global_position = spawn_pos


func _choose_enemy_scene() -> PackedScene:
	var scene_to_spawn := enemy_scene

	# After 2.5 minutes, tanks have a 45% chance to spawn.
	# If the roll fails, it can still roll for a fast enemy, otherwise it stays normal.
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
	var angle := randf_range(0.0, TAU)
	var spawn_offset := Vector2(cos(angle), sin(angle)) * spawn_distance
	var spawn_pos := player.global_position + spawn_offset

	if clamp_spawn_to_rect:
		spawn_pos.x = clamp(spawn_pos.x, spawn_rect_min.x, spawn_rect_max.x)
		spawn_pos.y = clamp(spawn_pos.y, spawn_rect_min.y, spawn_rect_max.y)

	return spawn_pos
