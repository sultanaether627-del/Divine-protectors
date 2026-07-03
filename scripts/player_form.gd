extends Node2D

@export var form_key := "water"
@export var display_name := "Water"
@export var base_max_health := 100
@export var bullet_scene: PackedScene
@export var shot_origin_offset := Vector2(0, -10)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shot_origin: Marker2D = $ShotOrigin


func _ready() -> void:
	_spawn_in_polish()
	if shot_origin:
		shot_origin.position = shot_origin_offset
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func set_facing(aim_x: float) -> void:
	if not sprite:
		return

	if aim_x > 0:
		sprite.flip_h = true
	elif aim_x < 0:
		sprite.flip_h = false

	if shot_origin:
		shot_origin.position.x = abs(shot_origin_offset.x) if sprite.flip_h else -abs(shot_origin_offset.x)
		shot_origin.position.y = shot_origin_offset.y


func play_movement(moving: bool, walking_backwards := false) -> void:
	if not sprite or not sprite.sprite_frames:
		return

	if not moving:
		sprite.speed_scale = 1.0
		if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
			sprite.play("idle")
		return

	if sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
		sprite.play("walk")

	sprite.speed_scale = -1.0 if walking_backwards else 1.0


func get_shot_position() -> Vector2:
	if shot_origin:
		return shot_origin.global_position

	return global_position



func _spawn_in_polish() -> void:
	scale = Vector2(0.82, 0.82)
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
