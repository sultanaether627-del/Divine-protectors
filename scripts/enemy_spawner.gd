extends Node2D

const DEBUG_SPAWN := false

# All enemies are now elemental — the plain/fast/tank scenes are retired.
@export var fire_enemy_scene: PackedScene = preload("res://tscn/enemy_fire.tscn")
@export var water_enemy_scene: PackedScene = preload("res://tscn/enemy_water.tscn")
@export var earth_enemy_scene: PackedScene = preload("res://tscn/enemy_earth.tscn")
@export var air_enemy_scene: PackedScene = preload("res://tscn/enemy_air.tscn")

@export var starting_spawn_time: float = 1.0
@export var minimum_spawn_time: float = 0.14
@export var spawn_time_decrease: float = 0.105
@export var difficulty_increase_interval: float = 5.0

@export var spawn_distance: float = 420.0
@export var max_enemies: int = 100
@export var spawn_immediately: bool = true
@export var disabled: bool = false

@export var enemy_health_growth_per_minute: float = 0.12
@export var enemy_damage_growth_per_minute: float = 0.06
@export var enemy_speed_growth_per_minute: float = 0.035
@export var max_enemy_health_multiplier: float = 4.0
@export var elite_spawn_chance: float = 0.06
@export var elite_unlock_time: float = 120.0


@export var clamp_spawn_to_rect: bool = true



@export var spawn_rect_min: Vector2 = Vector2(-1900, -1400)
@export var spawn_rect_max: Vector2 = Vector2(1900, 1400)

# Safety space from the walls.
@export var spawn_margin: float = 64.0

# Elemental enemy unlock times (all unlock within the first 2 minutes)
@export var fire_enemy_unlock_time: float = 0.0
@export var water_enemy_unlock_time: float = 30.0
@export var air_enemy_unlock_time: float = 60.0
@export var earth_enemy_unlock_time: float = 90.0

var player: Node2D
var current_spawn_time: float = 1.0
var elapsed_game_time: float = 0.0


func _ready() -> void:
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		push_error("EnemySpawner: No player found. The Player must be in the 'player' group.")
		return

	if fire_enemy_scene == null:
		push_error("EnemySpawner: fire_enemy_scene is missing.")
		return

	# Apply difficulty spawn-wait multiplier so harder modes spawn enemies faster.
	current_spawn_time = starting_spawn_time * DifficultyManager.get_spawn_wait_multiplier()

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
			if DEBUG_SPAWN:
				print("New spawn time: ", current_spawn_time)


func spawn_enemy() -> void:
	if get_tree().paused or disabled:
		return

	if player == null:
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
	_apply_enemy_scaling(enemy)
	_try_make_elite(enemy)

	get_tree().current_scene.add_child(enemy)

	var spawn_pos: Vector2 = _get_spawn_position()
	enemy.global_position = spawn_pos




func _try_make_elite(enemy: Node) -> void:
	if elapsed_game_time < elite_unlock_time:
		return

	var chance: float = elite_spawn_chance
	var difficulty_name: String = DifficultyManager.get_difficulty_name()
	if difficulty_name == "Hard":
		chance *= 1.35
	elif difficulty_name == "Divine":
		chance *= 1.75
	elif difficulty_name == "Easy":
		chance *= 0.65

	if randf() <= chance and enemy.has_method("make_elite"):
		enemy.make_elite()


func _apply_enemy_scaling(enemy: Node) -> void:
	var minutes_alive: float = elapsed_game_time / 60.0
	var speed_mult: float = 1.0 + minutes_alive * enemy_speed_growth_per_minute

	var health_mult: float = 1.0
	var damage_mult: float = 1.0

	var defeat_count: int = int(get_tree().get_meta("boss_defeat_count", 0))
	if defeat_count == 0:
		# First run — original time-based scaling.
		health_mult = minf(max_enemy_health_multiplier, 1.0 + minutes_alive * enemy_health_growth_per_minute)
		damage_mult = 1.0 + minutes_alive * enemy_damage_growth_per_minute
	else:
		# Post-first-defeat — DPS-aware scaling so upgraded players stay challenged.
		var player_node: Node = get_tree().get_first_node_in_group("player")
		var player_lv: int = 1
		var player_dps: float = 15.0
		if player_node:
			if player_node.get("level") != null:
				player_lv = int(player_node.get("level"))
			var bullet_dmg: float = float(player_node.get("bullet_damage")) if player_node.get("bullet_damage") != null else 10.0
			var cooldown: float = float(player_node.get("shoot_cooldown")) if player_node.get("shoot_cooldown") != null else 0.25
			var multi: int = int(player_node.get("multi_shot_count")) if player_node.get("multi_shot_count") != null else 1
			player_dps = (bullet_dmg * float(multi)) / maxf(0.01, cooldown)
		health_mult = minf(12.0, maxf(1.0, player_dps / 15.0))
		damage_mult = 1.0 + float(player_lv) * 0.15

	# Apply difficulty multipliers on top of all other scaling.
	health_mult *= DifficultyManager.get_enemy_hp_multiplier()
	damage_mult *= DifficultyManager.get_enemy_damage_multiplier()
	speed_mult  *= DifficultyManager.get_enemy_speed_multiplier()

	if enemy.get("max_health") != null:
		enemy.set("max_health", float(enemy.get("max_health")) * health_mult)
	if enemy.get("health") != null:
		enemy.set("health", float(enemy.get("max_health")))
	if enemy.get("damage") != null:
		enemy.set("damage", int(ceil(float(enemy.get("damage")) * damage_mult)))
	if enemy.get("movement_speed") != null:
		enemy.set("movement_speed", float(enemy.get("movement_speed")) * speed_mult)


func _choose_enemy_scene() -> PackedScene:
	# All enemies are elemental. Build pool from unlocked types and pick randomly.
	var candidates: Array[PackedScene] = []

	if elapsed_game_time >= fire_enemy_unlock_time and fire_enemy_scene != null:
		candidates.append(fire_enemy_scene)
	if elapsed_game_time >= water_enemy_unlock_time and water_enemy_scene != null:
		candidates.append(water_enemy_scene)
	if elapsed_game_time >= air_enemy_unlock_time and air_enemy_scene != null:
		candidates.append(air_enemy_scene)
	if elapsed_game_time >= earth_enemy_unlock_time and earth_enemy_scene != null:
		candidates.append(earth_enemy_scene)

	# Should never be empty (fire unlocks at 0s), but fall back just in case.
	if candidates.is_empty():
		return fire_enemy_scene
	return candidates[randi() % candidates.size()]


func _get_spawn_position() -> Vector2:
	if not clamp_spawn_to_rect:
		var angle: float = randf_range(0.0, TAU)
		var spawn_offset: Vector2 = Vector2(cos(angle), sin(angle)) * spawn_distance
		return player.global_position + spawn_offset

	var left: float = min(spawn_rect_min.x, spawn_rect_max.x) + spawn_margin
	var right: float = max(spawn_rect_min.x, spawn_rect_max.x) - spawn_margin
	var top: float = min(spawn_rect_min.y, spawn_rect_max.y) + spawn_margin
	var bottom: float = max(spawn_rect_min.y, spawn_rect_max.y) - spawn_margin

	
	for i in range(40):
		var angle: float = randf_range(0.0, TAU)
		var spawn_offset: Vector2 = Vector2(cos(angle), sin(angle)) * spawn_distance
		var spawn_pos: Vector2 = player.global_position + spawn_offset

		if spawn_pos.x >= left and spawn_pos.x <= right and spawn_pos.y >= top and spawn_pos.y <= bottom:
			return spawn_pos

	
	return Vector2(
		randf_range(left, right),
		randf_range(top, bottom)
	)
