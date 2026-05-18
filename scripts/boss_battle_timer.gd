extends Node2D

signal boss_timer_changed(time_left: float)
signal boss_battle_started

@export var boss_unlock_time := 900.0
@export var boss_arena_scene: PackedScene = preload("res://tscn/boss_arena.tscn")

var elapsed_time := 0.0
var boss_started := false
var player: Node2D = null
var arena: Node2D = null


func _ready() -> void:
	add_to_group("boss_timer")
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player") as Node2D
	boss_timer_changed.emit(boss_unlock_time)


func _process(delta: float) -> void:
	if boss_started:
		return
	if get_tree().paused:
		return

	elapsed_time += delta
	var time_left: float = max(0.0, boss_unlock_time - elapsed_time)
	boss_timer_changed.emit(time_left)

	if elapsed_time >= boss_unlock_time:
		_start_boss_battle()


func _start_boss_battle() -> void:
	if boss_started:
		return

	boss_started = true
	print("Boss battle unlocked!")

	player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		push_error("BossBattleTimer: Player not found.")
		return

	# Stop the normal world spawner so the boss room controls enemy spawns.
	var old_spawner: Node = get_tree().current_scene.get_node_or_null("EnemySpawner")
	if old_spawner:
		old_spawner.set("disabled", true)
		old_spawner.set_process(false)
		old_spawner.set_physics_process(false)
		old_spawner.visible = false

	# Clear existing enemies before teleporting into the boss arena.
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	arena = boss_arena_scene.instantiate() as Node2D
	# Keep the arena floor behind gameplay nodes. Boss/attacks/UI still display normally.
	arena.z_index = -10
	get_tree().current_scene.add_child(arena)
	arena.global_position = Vector2.ZERO

	var spawn_point: Node2D = arena.get_node_or_null("PlayerSpawn") as Node2D
	if spawn_point:
		player.global_position = spawn_point.global_position
	else:
		player.global_position = Vector2(640, 500)

	# Make sure the player stays visible after the arena is added.
	player.visible = true
	player.z_index = 20

	boss_battle_started.emit()
