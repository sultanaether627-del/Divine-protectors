extends Area2D

const DEBUG_BOSS := false

@export var warning_time: float = 1.0
@export var damage: int = 150
@export var linger_time: float = 0.2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_collision: CollisionShape2D = $CollisionShape2D

var has_hit := false
var impact_active := false
var marker_visible := true
var marker_center: Vector2 = Vector2.ZERO
var marker_radius: float = 76.0


func _ready() -> void:
	# Keep the fist visually above the player, while still using the same warning/damage area.
	z_index = 80
	z_as_relative = false
	monitoring = true
	_update_marker_from_collision()
	queue_redraw()

	# Damage and blocking stay OFF during the warning.
	# The marker/shadow is the only thing showing where the fist will hit.
	if damage_collision:
		damage_collision.disabled = true
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("smash"):
		sprite.play("smash")
		sprite.pause()
		sprite.frame = 0

	_start_attack()


func _draw() -> void:
	if not marker_visible:
		return

	var fill_color: Color
	var outline_color: Color
	if impact_active:
		fill_color = Color(0.95, 0.15, 0.05, 0.34)
		outline_color = Color(1.0, 0.35, 0.15, 0.85)
	else:
		fill_color = Color(0.0, 0.0, 0.0, 0.36)
		outline_color = Color(1.0, 0.15, 0.05, 0.75)

	# This circle is drawn from the exact same center/radius as the damage collision.
	draw_circle(marker_center, marker_radius, fill_color)
	draw_arc(marker_center, marker_radius, 0.0, TAU, 64, outline_color, 4.0)


func _update_marker_from_collision() -> void:
	if damage_collision == null:
		return
	marker_center = damage_collision.position
	var circle_shape: CircleShape2D = damage_collision.shape as CircleShape2D
	if circle_shape != null:
		marker_radius = circle_shape.radius


func setup(is_right_fist: bool, hit_damage: int) -> void:
	damage = hit_damage
	if sprite:
		sprite.flip_h = not is_right_fist


func _start_attack() -> void:
	await get_tree().create_timer(warning_time, false).timeout

	impact_active = true
	queue_redraw()
	_screen_shake(10.0, 0.18)

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("smash"):
		sprite.play("smash")

	if damage_collision:
		damage_collision.disabled = false

	_check_hit()
	await get_tree().create_timer(linger_time, false).timeout
	_check_hit()

	marker_visible = false
	queue_redraw()
	await get_tree().create_timer(0.35, false).timeout
	queue_free()


func _check_hit() -> void:
	if has_hit:
		return

	for body in get_overlapping_bodies():
		if body and body.is_in_group("player") and body.has_method("take_damage"):
			has_hit = true
			body.take_damage(damage)
			_screen_shake(18.0, 0.24)
			if DEBUG_BOSS:
				print("Boss fist hit ", body.name, " for ", damage)
			return

func _screen_shake(strength: float, duration: float) -> void:
	var shaker: Node = get_tree().get_first_node_in_group("screen_shake")
	if shaker and shaker.has_method("shake"):
		shaker.shake(strength, duration)

	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("_shake_camera"):
		player_node._shake_camera(strength * 0.25, duration)
