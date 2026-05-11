extends CharacterBody2D

@export var movement_speed := 81.0
@export var max_health := 30.0
@export var damage := 10
@export var damage_cooldown := 0.8
@export var xp_drop_scene: PackedScene = preload("res://tscn/xp_drop.tscn")
@export var xp_drops_on_death := 1

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var health := 0.0
var can_damage := true
var is_dead := false


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("move"):
		sprite.play("move")


func _physics_process(_delta: float) -> void:
	if player and not is_dead:
		var direction := global_position.direction_to(player.global_position)
		velocity = direction * movement_speed
		move_and_slide()

		if direction.x > 0:
			sprite.flip_h = true
		elif direction.x < 0:
			sprite.flip_h = false

		if sprite.sprite_frames and sprite.sprite_frames.has_animation("move") and sprite.animation != "move":
			sprite.play("move")

		check_player_collision()


func check_player_collision() -> void:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if collision == null:
			continue

		var body := collision.get_collider()
		if body == null:
			continue

		if body.is_in_group("player") and can_damage:
			can_damage = false

			if body.has_method("take_damage"):
				body.take_damage(damage)

			await get_tree().create_timer(damage_cooldown).timeout
			can_damage = true


func take_damage(amount: float) -> void:
	if is_dead:
		return

	health -= amount
	print("Enemy health: ", health)

	if health <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	remove_from_group("enemy")
	set_physics_process(false)
	call_deferred("_safe_die")


func _safe_die() -> void:
	for i in range(xp_drops_on_death):
		var xp_drop = xp_drop_scene.instantiate()
		get_tree().current_scene.add_child(xp_drop)
		xp_drop.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))

	queue_free()
