extends Node2D

@export var orbit_radius := 46.0
@export var hidden_distance := 18.0
@export var fade_distance := 90.0
@export var rotation_offset := PI / 2.0

@onready var sprite: Sprite2D = $Sprite2D


func _process(_delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var owner_pos: Vector2 = get_parent().global_position
	var to_mouse: Vector2 = mouse_pos - owner_pos
	var distance: float = to_mouse.length()

	if distance <= 0.01:
		visible = false
		return

	visible = true

	var aim_dir: Vector2 = to_mouse.normalized()

	position = aim_dir * orbit_radius
	rotation = aim_dir.angle() + rotation_offset

	var alpha: float = 1.0

	if distance <= hidden_distance:
		alpha = 0.0
	elif distance < fade_distance:
		alpha = inverse_lerp(hidden_distance, fade_distance, distance)

	modulate.a = alpha
