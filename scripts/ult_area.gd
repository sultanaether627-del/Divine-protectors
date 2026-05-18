extends Node2D

@export var ult_type := "fire"
@export var radius := 150.0
@export var visible_time := 0.75
@export var fade_time := 0.35
@export var stun_duration := 5.0
@export var wind_push_multiplier := 3.0

@onready var sprite: Sprite2D = $Sprite2D

var player: Node = null
var effect_applied := false


func _ready() -> void:
	z_index = -50
	if sprite:
		sprite.z_index = -50

	player = get_tree().get_first_node_in_group("player")

	# Wait one frame so the PlayerController has definitely placed this ult
	# under the player before the damage/push/stun search happens.
	await get_tree().process_frame
	_apply_ult_effect()
	_play_visual_then_free()


func _apply_ult_effect() -> void:
	if effect_applied:
		return
	effect_applied = true

	if ult_type == "water":
		if player and player.has_method("apply_water_ult"):
			player.apply_water_ult()
		return

	var enemies: Array = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		if not (enemy is Node2D):
			continue

		var enemy_node: Node2D = enemy as Node2D
		var distance: float = global_position.distance_to(enemy_node.global_position)

		if distance > radius:
			continue

		match ult_type:
			"fire":
				if enemy.has_method("kill_without_xp"):
					enemy.kill_without_xp()
				elif enemy.has_method("die"):
					enemy.die()

			"wind":
				if enemy.has_method("apply_push_from"):
					enemy.apply_push_from(global_position, radius * wind_push_multiplier)

			"earth":
				if enemy.has_method("stun"):
					enemy.stun(stun_duration)


func _play_visual_then_free() -> void:
	if sprite:
		sprite.modulate.a = 1.0

	await get_tree().create_timer(visible_time).timeout

	var tween := create_tween()
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, fade_time)
	await tween.finished
	queue_free()
