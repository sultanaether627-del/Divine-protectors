extends CharacterBody2D

const DEBUG_COMBAT := false

signal health_changed(current_health: float, max_health: float)
signal boss_defeated

@export var max_health: float = 1200.0
@export var fist_attack_scene: PackedScene = preload("res://tscn/boss_fist_attack.tscn")
@export var attack_interval: float = 4.0
@export var attack_damage: int = 150
@export var health_per_strength_level: float = 0.6
@export var damage_per_strength_level: float = 0.3
@export var scale_per_strength_level: float = 0.12
@export var attack_speed_gain_per_level: float = 0.3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var health: float = 1000.0
var player: Node2D = null
var use_right_fist := true
var is_dead := false
var strength_level: int = 0
var base_scale: Vector2 = Vector2.ONE
var base_max_health: float = 0.0
var base_attack_interval: float = 0.0
var base_attack_damage: int = 0
var hit_flash_tween: Tween = null


func _ready() -> void:
	add_to_group("boss")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	base_scale = scale
	base_max_health = max_health
	base_attack_interval = attack_interval
	base_attack_damage = attack_damage
	strength_level = int(get_tree().get_meta("boss_strength_level", 0))
	_apply_strength_scaling()
	health = max_health
	player = get_tree().get_first_node_in_group("player") as Node2D
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	health_changed.emit(health, max_health)
	_attack_loop()


func _physics_process(_delta: float) -> void:
	# Keep the boss stationary but participating in physics so the player
	# cannot walk through it.
	velocity = Vector2.ZERO
	move_and_slide()


func _apply_strength_scaling() -> void:
	var health_multiplier: float = 1.0 + (float(strength_level) * health_per_strength_level)
	var damage_multiplier: float = 1.0 + (float(strength_level) * damage_per_strength_level)
	var scale_multiplier: float = 1.0 + (float(strength_level) * scale_per_strength_level)
	max_health = base_max_health * health_multiplier
	attack_damage = int(round(base_attack_damage * damage_multiplier))
	attack_interval = maxf(1.5, base_attack_interval - (float(strength_level) * attack_speed_gain_per_level))
	scale = base_scale * scale_multiplier
	if DEBUG_COMBAT:
		print("Boss strength level: ", strength_level, " HP: ", max_health, " DMG: ", attack_damage, " Interval: ", attack_interval)


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

	_play_boss_attack_sound()
	var fist: Node = fist_attack_scene.instantiate()
	get_tree().current_scene.add_child(fist)
	fist.global_position = player.global_position
	if fist.has_method("setup"):
		fist.setup(use_right_fist, attack_damage)

	use_right_fist = not use_right_fist


func take_damage(amount: float) -> void:
	if is_dead:
		return

	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	_play_boss_hit_sound()
	_flash_on_hit()
	if DEBUG_COMBAT:
		print("Boss HP: ", health)

	if health <= 0.0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	_play_boss_death_sound()
	boss_defeated.emit()
	print("Boss defeated!")
	queue_free()


func _flash_on_hit() -> void:
	if sprite == null:
		return
	if hit_flash_tween:
		hit_flash_tween.kill()
	sprite.modulate = Color(1.0, 0.25, 0.25, 1.0)
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)


func _play_boss_attack_sound() -> void:
	var sfx_manager = get_node_or_null("/root/SFXManager")
	if sfx_manager and sfx_manager.has_method("play_boss_attack"):
		sfx_manager.play_boss_attack()


func _play_boss_hit_sound() -> void:
	var sfx_manager = get_node_or_null("/root/SFXManager")
	if sfx_manager and sfx_manager.has_method("play_boss_hit"):
		sfx_manager.play_boss_hit()


func _play_boss_death_sound() -> void:
	var sfx_manager = get_node_or_null("/root/SFXManager")
	if sfx_manager and sfx_manager.has_method("play_boss_death"):
		sfx_manager.play_boss_death()
