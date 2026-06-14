extends CharacterBody2D

const DEBUG_COMBAT := false

signal health_changed(current_health: float, max_health: float)
signal boss_defeated

@export var max_health: float = 1200.0
@export var fist_attack_scene: PackedScene = preload("res://tscn/boss_fist_attack.tscn")
@export var reflect_projectile_scene: PackedScene = preload("res://tscn/boss_reflect_projectile.tscn")
@export var reflect_projectile_interval: float = 8.0
@export var reflect_projectile_damage: int = 120

@export var attack_interval: float = 4.0
@export var attack_damage: int = 150
@export var health_per_strength_level: float = 0.6
@export var damage_per_strength_level: float = 0.3
@export var scale_per_strength_level: float = 0.12
@export var attack_speed_gain_per_level: float = 0.3

@export var dash_interval: float = 10.0
@export var dash_warning_time: float = 0.95
@export var dash_damage: int = 180
@export var dash_speed: float = 1700.0
@export var dash_width: float = 84.0
@export var dash_return_time: float = 0.38

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var health: float = 1000.0
var player: Node2D = null
var use_right_fist := true
var is_dead := false
var is_stunned := false
var stun_token := 0
var is_dashing := false
var is_enraged := false

var strength_level: int = 0
var base_scale: Vector2 = Vector2.ONE
var base_max_health: float = 0.0
var base_attack_interval: float = 0.0
var base_attack_damage: int = 0
var original_position: Vector2 = Vector2.ZERO
var hit_flash_tween: Tween = null
var saved_dash_collision_layer: int = 0
var saved_dash_collision_mask: int = 0
var dash_has_hit_player: bool = false


func _ready() -> void:
	add_to_group("boss")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	base_scale = scale
	original_position = global_position
	strength_level = int(get_tree().get_meta("boss_strength_level", 0))

	var player_level: int = int(get_tree().get_meta("player_level", 1))
	var live_player: Node = get_tree().get_first_node_in_group("player")
	if live_player and live_player.get("level") != null:
		player_level = int(live_player.get("level"))
	var boss_level: int = player_level + 1

	base_max_health = 800.0 + float(boss_level) * 350.0
	base_attack_damage = 30 + boss_level * 12
	base_attack_interval = attack_interval

	var defeat_count: int = int(get_tree().get_meta("boss_defeat_count", 0))
	var rematch_mult: float = pow(2.0, defeat_count)
	base_max_health = base_max_health * rematch_mult
	base_attack_damage = int(round(float(base_attack_damage) * rematch_mult))

	base_max_health = base_max_health * DifficultyManager.get_boss_hp_multiplier()

	_apply_level_scaling(player_level)
	_apply_strength_scaling()
	health = max_health
	player = get_tree().get_first_node_in_group("player") as Node2D

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	health_changed.emit(health, max_health)
	_attack_loop()
	_reflect_projectile_loop()
	_dash_loop()


func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	if is_dashing:
		return
	velocity = Vector2.ZERO
	move_and_slide()


func _apply_level_scaling(player_level: int) -> void:
	var boss_level: int = player_level + 1
	var hp_mult: float  = 1.0 + float(boss_level) * 0.25
	var dmg_mult: float = 1.0 + float(boss_level) * 0.18
	var spd_mult: float = 1.0 + float(boss_level) * 0.02
	base_max_health = base_max_health * hp_mult
	base_attack_damage = int(round(float(base_attack_damage) * dmg_mult))
	base_attack_interval = maxf(1.5, base_attack_interval - float(boss_level) * spd_mult * 0.05)


func _apply_strength_scaling() -> void:
	var health_multiplier: float = 1.0 + (float(strength_level) * health_per_strength_level)
	var damage_multiplier: float = 1.0 + (float(strength_level) * damage_per_strength_level)
	var scale_multiplier: float = 1.0 + (float(strength_level) * scale_per_strength_level)
	max_health = base_max_health * health_multiplier
	attack_damage = int(round(base_attack_damage * damage_multiplier))
	attack_interval = maxf(1.5, base_attack_interval - (float(strength_level) * attack_speed_gain_per_level))
	scale = base_scale * scale_multiplier


func _attack_loop() -> void:
	while not is_dead:
		await get_tree().create_timer(attack_interval, false).timeout
		if get_tree().paused or is_dead or is_stunned or is_dashing:
			continue

		if is_enraged:
			_spawn_double_fist_combo()
		else:
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


func _spawn_double_fist_combo() -> void:
	_spawn_fist_attack()
	await get_tree().create_timer(0.62, false).timeout
	if get_tree().paused or is_dead or is_stunned or is_dashing:
		return
	_spawn_fist_attack()


func _reflect_projectile_loop() -> void:
	while not is_dead:
		await get_tree().create_timer(reflect_projectile_interval if not is_enraged else reflect_projectile_interval * 0.8, false).timeout
		if get_tree().paused or is_dead or is_stunned or is_dashing:
			continue
		_spawn_reflect_projectile()


func _spawn_reflect_projectile() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or reflect_projectile_scene == null:
		return

	var projectile: Node = reflect_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + Vector2(35, 150)

	if projectile.has_method("setup"):
		projectile.setup(self, player, reflect_projectile_damage)


func _dash_loop() -> void:
	while not is_dead:
		await get_tree().create_timer(dash_interval if not is_enraged else dash_interval * 0.72, false).timeout
		if get_tree().paused or is_dead or is_stunned or is_dashing:
			continue
		await _perform_titan_dash()


func _perform_titan_dash() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	is_dashing = true
	dash_has_hit_player = false

	var start_pos: Vector2 = global_position
	var target_pos: Vector2 = player.global_position
	var dash_dir: Vector2 = start_pos.direction_to(target_pos)
	if dash_dir.length() <= 0.01:
		dash_dir = Vector2.DOWN

	var end_pos: Vector2 = _clamp_to_arena(start_pos + dash_dir.normalized() * 960.0)
	var indicator: Line2D = _create_dash_indicator(start_pos, end_pos)

	await get_tree().create_timer(dash_warning_time if not is_enraged else dash_warning_time * 0.72, false).timeout

	if is_dead or is_stunned:
		if indicator:
			indicator.queue_free()
		is_dashing = false
		return

	if indicator:
		indicator.default_color = Color(1.0, 0.05, 0.02, 0.9)
		indicator.width = dash_width

	# Disable boss collision during dash so it damages the player without physically pushing them through walls.
	_disable_dash_collision()

	var dash_time: float = max(0.12, start_pos.distance_to(end_pos) / dash_speed)
	var elapsed: float = 0.0
	while elapsed < dash_time:
		var delta: float = get_process_delta_time()
		elapsed += delta
		var t: float = clampf(elapsed / dash_time, 0.0, 1.0)
		global_position = start_pos.lerp(end_pos, t)
		_damage_player_on_dash_line(start_pos, global_position)
		await get_tree().process_frame

	global_position = end_pos
	_damage_player_on_dash_line(start_pos, end_pos)

	_restore_dash_collision()

	await get_tree().create_timer(0.18, false).timeout

	var return_tween: Tween = create_tween()
	return_tween.tween_property(self, "global_position", original_position, dash_return_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await return_tween.finished

	if indicator:
		var fade: Tween = create_tween()
		fade.tween_property(indicator, "modulate:a", 0.0, 0.16)
		fade.tween_callback(indicator.queue_free)

	is_dashing = false


func _create_dash_indicator(start_pos: Vector2, end_pos: Vector2) -> Line2D:
	var line := Line2D.new()
	line.width = dash_width
	line.default_color = Color(1.0, 0.05, 0.02, 0.34)
	line.z_index = 90
	line.z_as_relative = false
	line.add_point(start_pos)
	line.add_point(end_pos)
	get_tree().current_scene.add_child(line)
	return line


func _damage_player_on_dash_line(start_pos: Vector2, end_pos: Vector2) -> void:
	if dash_has_hit_player:
		return

	player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var dash_vec: Vector2 = end_pos - start_pos
	var dash_len: float = dash_vec.length()
	if dash_len <= 0.01:
		return

	var dash_dir: Vector2 = dash_vec.normalized()
	var projection: float = clampf((player.global_position - start_pos).dot(dash_dir), 0.0, dash_len)
	var closest: Vector2 = start_pos + dash_dir * projection
	var distance: float = player.global_position.distance_to(closest)

	if distance <= dash_width:
		dash_has_hit_player = true
		if player.has_method("take_damage"):
			player.take_damage(dash_damage if not is_enraged else int(dash_damage * 1.2))
		player.global_position = _clamp_to_arena(player.global_position)
		_screen_shake(16.0, 0.24)


func _disable_dash_collision() -> void:
	saved_dash_collision_layer = collision_layer
	saved_dash_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0


func _restore_dash_collision() -> void:
	collision_layer = saved_dash_collision_layer
	collision_mask = saved_dash_collision_mask


func _clamp_to_arena(pos: Vector2) -> Vector2:
	var scene := get_tree().current_scene
	if scene and (scene.name == "BossArena" or scene.scene_file_path.ends_with("boss_arena.tscn")):
		return Vector2(clampf(pos.x, 110.0, 1170.0), clampf(pos.y, 125.0, 635.0))
	return pos


func take_damage(amount: float) -> void:
	if is_dead:
		return

	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	_play_boss_hit_sound()
	_flash_on_hit()

	if not is_enraged and health <= max_health * 0.5:
		_enter_enrage()

	if health <= 0.0:
		die()


func _enter_enrage() -> void:
	is_enraged = true
	attack_interval = maxf(1.15, attack_interval * 0.72)
	reflect_projectile_interval = maxf(7.0, reflect_projectile_interval * 0.78)
	dash_interval = maxf(5.5, dash_interval * 0.75)
	if sprite:
		sprite.modulate = Color(1.25, 0.45, 0.35, 1.0)
	_spawn_floating_text("THE TITAN IS ENRAGED", Color(1.0, 0.24, 0.12, 1.0), global_position + Vector2(0, -130))
	_screen_shake(12.0, 0.32)


func stun(duration: float) -> void:
	if is_dead:
		return

	stun_token += 1
	var my_token: int = stun_token
	is_stunned = true
	if sprite:
		sprite.modulate = Color(0.45, 1.0, 1.0, 1.0)

	await get_tree().create_timer(duration, false).timeout

	if my_token != stun_token or is_dead:
		return
	is_stunned = false
	if sprite:
		sprite.modulate = Color(1.25, 0.45, 0.35, 1.0) if is_enraged else Color(1, 1, 1, 1)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	_play_boss_death_sound()
	_screen_shake(22.0, 0.45)
	_spawn_floating_text("BOSS DEFEATED", Color(1.0, 0.9, 0.25, 1.0), global_position + Vector2(0, -160))

	if sprite:
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.08)
		tween.tween_property(sprite, "scale", sprite.scale * 1.35, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(sprite, "modulate:a", 0.0, 0.35)

	await get_tree().create_timer(0.65, false).timeout
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
	hit_flash_tween.tween_property(sprite, "modulate", Color(1.25, 0.45, 0.35, 1.0) if is_enraged else Color(1, 1, 1, 1), 0.12)


func _screen_shake(strength: float, duration: float) -> void:
	var shaker: Node = get_tree().get_first_node_in_group("screen_shake")
	if shaker and shaker.has_method("shake"):
		shaker.shake(strength, duration)


func _spawn_floating_text(text_value: String, color_value: Color, pos: Vector2) -> void:
	var floating_scene: PackedScene = load("res://tscn/floating_text.tscn") as PackedScene
	if floating_scene == null:
		return
	var popup = floating_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = pos
	popup.text = text_value
	popup.color = color_value


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
