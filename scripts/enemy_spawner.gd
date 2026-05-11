extends Node2D

@export var enemy_scene: PackedScene = preload("res://tscn/enemy.tscn")
@export var spawn_time := 1.2
@export var spawn_distance := 360.0
@export var max_enemies := 30
@export var spawn_immediately := true

var player: Node2D
var timer: Timer


func _ready() -> void:
	# Wait one frame so the Player has time to add itself to the "player" group.
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		push_error("EnemySpawner: No player found. The Player must be in the 'player' group.")
		return

	if enemy_scene == null:
		push_error("EnemySpawner: enemy_scene is missing.")
		return

	timer = Timer.new()
	timer.wait_time = spawn_time
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(spawn_enemy)
	add_child(timer)

	if spawn_immediately:
		spawn_enemy()

	print("EnemySpawner started")


func spawn_enemy() -> void:
	if player == null or enemy_scene == null:
		return

	if get_tree().get_nodes_in_group("enemy").size() >= max_enemies:
		return

	var enemy := enemy_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(enemy)

	var angle := randf_range(0.0, TAU)
	var spawn_offset := Vector2(cos(angle), sin(angle)) * spawn_distance
	enemy.global_position = player.global_position + spawn_offset

	print("Enemy spawned at: ", enemy.global_position)
