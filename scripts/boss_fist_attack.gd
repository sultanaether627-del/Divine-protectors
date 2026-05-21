extends Area2D

const DEBUG_BOSS := false

@export var warning_time := 1.0
@export var damage := 150
@export var linger_time := 0.2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_collision: CollisionShape2D = $CollisionShape2D
@onready var block_collision: CollisionShape2D = $BlockBody/BlockCollisionShape2D

var has_hit := false


func _ready() -> void:
	monitoring = true

	# The damage collision stays off during the warning.
	if damage_collision:
		damage_collision.disabled = true

	# The blocking collision stays ON while the fist exists, so the player cannot stand inside it.
	if block_collision:
		block_collision.disabled = false

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("smash"):
		sprite.play("smash")
		sprite.pause()
		sprite.frame = 0

	_start_attack()


func setup(is_right_fist: bool, hit_damage: int) -> void:
	damage = hit_damage

	# Alternate left/right hand visually.
	if sprite:
		sprite.flip_h = not is_right_fist


func _start_attack() -> void:
	await get_tree().create_timer(warning_time, false).timeout

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("smash"):
		sprite.play("smash")

	if damage_collision:
		damage_collision.disabled = false

	_check_hit()
	await get_tree().create_timer(linger_time, false).timeout
	_check_hit()

	await get_tree().create_timer(0.35, false).timeout
	queue_free()


func _check_hit() -> void:
	if has_hit:
		return

	for body in get_overlapping_bodies():
		if body and body.is_in_group("player") and body.has_method("take_damage"):
			has_hit = true
			body.take_damage(damage)
			if DEBUG_BOSS:
				print("Boss fist hit ", body.name, " for ", damage)
			return
