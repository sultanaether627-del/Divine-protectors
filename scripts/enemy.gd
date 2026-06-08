extends CharacterBody2D

const DEBUG_COMBAT := false

@export var movement_speed := 80.0
@export var max_health := 30.0
@export var damage := 10
@export var damage_cooldown := 0.8
@export var separation_radius := 28.0
@export var separation_strength := 60.0
@export var xp_drop_scene: PackedScene = preload("res://tscn/xp_drop.tscn")
@export var xp_drops_on_death := 1
@export var floating_text_scene: PackedScene = preload("res://tscn/floating_text.tscn")
# Element type: "fire", "water", "earth", "air", or "" for default
@export var element: String = ""

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health := 0.0
var can_damage := true
var is_dead := false
var is_stunned := false
var saved_collision_layer := 1
var saved_collision_mask := 1
var stun_token := 0

const ELEMENT_COLORS: Dictionary = {
	"fire":  Color(1.0,  0.35, 0.1,  1.0),
	"water": Color(0.2,  0.6,  1.0,  1.0),
	"earth": Color(0.4,  0.75, 0.2,  1.0),
	"air":   Color(0.85, 1.0,  1.0,  1.0),
}

# Elemental matchup multipliers: [attacker_element][defender_element] = multiplier
# water > fire (1.75x), earth > air (1.75x)
# earth > water (water weak to earth = 0.6x), air > fire (fire weak to air = 0.6x)
# All other matchups neutral (1.0x)
const ELEMENT_MATCHUPS: Dictionary = {
	"water": {"fire": 1.75, "earth": 0.6,  "air": 1.0,  "water": 1.0},
	"earth": {"air":  1.75, "water": 1.75, "fire": 1.0,  "earth": 1.0},
	"air":   {"fire": 1.75, "water": 1.0,  "earth": 0.6, "air":   1.0},
	"fire":  {"water": 0.6, "air":   0.6,  "earth": 1.0, "fire":  1.0},
}


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("enemy")
	collision_layer = 1
	set_collision_mask_value(1, true)
	health = max_health
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("move"):
		sprite.play("move")
	_apply_element_color()
	_enemy_spawn_polish()


func _apply_element_color() -> void:
	if element == "" or sprite == null:
		return
	if ELEMENT_COLORS.has(element):
		sprite.modulate = ELEMENT_COLORS[element]


func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if is_stunned:
		velocity = Vector2.ZERO
		return

	if player:
		var direction := global_position.direction_to(player.global_position)
		velocity = direction * movement_speed
		
		_apply_separation()
		
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

			# Briefly move the enemy to layer 2 so the player can walk away
			# freely during the damage cooldown (no getting stuck).
			var old_layer := collision_layer
			var old_mask := collision_mask
			collision_layer = 2
			collision_mask = 0

			await get_tree().create_timer(damage_cooldown).timeout

			if not is_dead and not is_stunned:
				collision_layer = old_layer
				collision_mask = old_mask

			can_damage = true


func _apply_separation() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	var separation := Vector2.ZERO
	var count := 0
	
	for other in enemies:
		if other == self or not is_instance_valid(other):
			continue
		var dist := global_position.distance_to(other.global_position)
		if dist < separation_radius and dist > 0.01:
			var away := global_position.direction_to(other.global_position)
			separation -= away * (1.0 - dist / separation_radius)
			count += 1
	
	if count > 0:
		velocity += separation * separation_strength


func take_damage(amount: float) -> void:
	if is_dead:
		return

	health -= amount
	_spawn_damage_text(amount, 1.0)
	_flash_hit()

	if DEBUG_COMBAT:
		print("Enemy health: ", health)

	if health <= 0:
		die()


func take_damage_elemental(amount: float, attacker_element: String) -> void:
	if is_dead:
		return

	# Look up the damage multiplier for this attacker vs this enemy's element.
	var multiplier := 1.0
	if element != "" and attacker_element != "" and ELEMENT_MATCHUPS.has(attacker_element):
		var row: Dictionary = ELEMENT_MATCHUPS[attacker_element]
		if row.has(element):
			multiplier = float(row[element])

	var final_damage := amount * multiplier
	health -= final_damage
	_spawn_damage_text(final_damage, multiplier)
	_flash_hit()

	if DEBUG_COMBAT:
		print("Enemy (", element, ") hit by ", attacker_element, " x", multiplier, " -> ", final_damage)

	if health <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	remove_from_group("enemy")
	set_physics_process(false)
	_death_pop_polish()
	call_deferred("_safe_die")


func kill_without_xp() -> void:
	if is_dead:
		return

	xp_drops_on_death = 0
	die()


func _safe_die() -> void:
	_death_effect()
	await get_tree().create_timer(0.15).timeout
	
	for i in range(xp_drops_on_death):
		var xp_drop = xp_drop_scene.instantiate()
		get_tree().current_scene.add_child(xp_drop)
		xp_drop.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))

	await get_tree().create_timer(0.12, false).timeout
	queue_free()


func _flash_hit() -> void:
	if sprite:
		sprite.modulate = Color(3, 3, 3, 1)
		var restore_color := Color(1, 1, 1, 1)
		if element != "" and ELEMENT_COLORS.has(element):
			restore_color = ELEMENT_COLORS[element]
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", restore_color, 0.1)


func _death_effect() -> void:
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3, 1)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.15)


func apply_push_from(origin: Vector2, push_distance: float) -> void:
	if is_dead:
		return

	var push_dir := origin.direction_to(global_position)
	if push_dir == Vector2.ZERO:
		push_dir = Vector2.RIGHT.rotated(randf_range(0.0, TAU))

	global_position += push_dir.normalized() * push_distance


func stun(duration: float) -> void:
	if is_dead:
		return

	stun_token += 1
	var my_token := stun_token
	is_stunned = true
	velocity = Vector2.ZERO

	saved_collision_layer = collision_layer
	saved_collision_mask = collision_mask

	# Put stunned enemies on layer 2 so the player can phase through them.
	# Bullets are set to also detect layer 2, so stunned enemies still take damage.
	collision_layer = 2
	collision_mask = 0

	if sprite:
		sprite.speed_scale = 0.0
		sprite.modulate = Color(0.55, 0.75, 1.0, 1.0)

	await get_tree().create_timer(duration).timeout

	if is_dead or my_token != stun_token:
		return

	is_stunned = false
	collision_layer = saved_collision_layer
	collision_mask = saved_collision_mask

	if sprite:
		sprite.speed_scale = 1.0
		# Restore element tint after stun; default enemies get white
		if element != "" and ELEMENT_COLORS.has(element):
			sprite.modulate = ELEMENT_COLORS[element]
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)



func _enemy_spawn_polish() -> void:
	if sprite:
		var original_scale := sprite.scale
		sprite.scale = original_scale * 0.75
		sprite.modulate.a = 0.35
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "scale", original_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.18)


func _spawn_damage_text(amount: float, multiplier: float = 1.0) -> void:
	if floating_text_scene == null:
		return
	var popup = floating_text_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = global_position + Vector2(randf_range(-10, 10), -42)
	popup.text = "-%d" % int(ceil(amount))


	# Color based on elemental matchup effectiveness:
	# Super-effective (>1.0) = bright gold, not-very-effective (<1.0) = grey
	if multiplier > 1.0:
		popup.color = Color(1.0, 0.95, 0.2, 1.0)  # Gold — super effective
	elif multiplier < 1.0:
		popup.color = Color(0.65, 0.65, 0.65, 1.0)  # Grey — resisted
	elif element != "" and ELEMENT_COLORS.has(element):
		popup.color = ELEMENT_COLORS[element]
	else:
		popup.color = Color(1.0, 0.35, 0.2, 1.0)

	popup.color = Color(1.0, 0.35, 0.2, 1.0)

func _screen_shake(strength: float, duration: float) -> void:
	var shaker: Node = get_tree().get_first_node_in_group("screen_shake")
	if shaker and shaker.has_method("shake"):
		shaker.shake(strength, duration)



func _death_pop_polish() -> void:
	if sprite == null:
		return
	if scale.x >= 1.8 or max_health >= 100.0:
		_screen_shake(4.0, 0.12)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", sprite.scale * 1.25, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.18)
