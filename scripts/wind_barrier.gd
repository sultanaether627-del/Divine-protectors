extends Node2D

@export var radius := 150.0
@export var duration := 10.0
@export var fade_time := 0.35
@export var floor_offset := Vector2(0, 26)
@export var push_padding := 8.0
@export var enemy_push_speed := 520.0

@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D = null
var ending := false


func _ready() -> void:
	z_index = -50
	if sprite:
		sprite.z_index = -50
		sprite.modulate.a = 1.0

	var found_player: Node = get_tree().get_first_node_in_group("player")
	if found_player and found_player is Node2D:
		player = found_player as Node2D

	# Keep this barrier active for the full ult duration.
	_start_lifetime()


func _physics_process(_delta: float) -> void:
	if ending:
		return
	if player == null or not is_instance_valid(player):
		return

	# Visual stays on the floor under the active player.
	global_position = player.global_position + floor_offset

	_keep_enemies_out()


func _keep_enemies_out() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		if not (enemy is Node2D):
			continue

		var enemy_node: Node2D = enemy as Node2D
		var from_player: Vector2 = enemy_node.global_position - player.global_position
		var distance: float = from_player.length()

		if distance <= 0.01:
			from_player = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
			distance = from_player.length()

		if distance < radius:
			var push_dir: Vector2 = from_player.normalized()
			var target_pos: Vector2 = player.global_position + push_dir * (radius + push_padding)
			enemy_node.global_position = target_pos

			# If the enemy has velocity, force it outward so it doesn't immediately slide back in.
			if "velocity" in enemy_node:
				enemy_node.velocity = push_dir * enemy_push_speed


func _start_lifetime() -> void:
	await get_tree().create_timer(duration).timeout
	ending = true

	var tween := create_tween()
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, fade_time)
	await tween.finished
	queue_free()
