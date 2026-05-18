extends CharacterBody2D

signal health_changed(current_health: float, max_health: float)
signal boss_defeated

@export var max_health := 1000.0
@export var fist_attack_scene: PackedScene = preload("res://tscn/boss_fist_attack.tscn")
@export var attack_interval := 4.0
@export var attack_damage := 150

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var health := 1000.0
var player: Node2D = null
var use_right_fist := true
var is_dead := false


func _ready() -> void:
	add_to_group("boss")
	health = max_health
	player = get_tree().get_first_node_in_group("player") as Node2D
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	health_changed.emit(health, max_health)
	_attack_loop()


func _attack_loop() -> void:
	while not is_dead:
		await get_tree().create_timer(attack_interval, false).timeout
		if get_tree().paused or is_dead:
			continue
		_spawn_fist_attack()


func _spawn_fist_attack() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or fist_attack_scene == null:
		return

	var fist = fist_attack_scene.instantiate()
	get_tree().current_scene.add_child(fist)

	# The fist appears over the player's current position, then smashes after its warning delay.
	fist.global_position = player.global_position
	if fist.has_method("setup"):
		fist.setup(use_right_fist, attack_damage)

	use_right_fist = not use_right_fist


func take_damage(amount: float) -> void:
	if is_dead:
		return

	health = max(0.0, health - amount)
	health_changed.emit(health, max_health)
	print("Boss HP: ", health)

	if health <= 0.0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	boss_defeated.emit()
	print("Boss defeated!")
	queue_free()
