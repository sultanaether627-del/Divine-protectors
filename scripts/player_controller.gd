extends CharacterBody2D

const DEBUG_COMBAT := false

signal health_changed(current_health: int, max_health: int)
signal xp_changed(current_xp: int, xp_required: int, level: int)
signal level_changed(level: int, current_xp: int, xp_required: int)
signal upgrade_options_ready(options: Array)
signal form_changed(form_name: String)

@export var movement_speed := 400.0
@export var acceleration := 2000.0
@export var deceleration := 1600.0
@export var shoot_cooldown := 0.25
@export var starting_xp_required := 10
@export var healing_per_orb := 5
@export var bullet_damage := 10.0
@export var character_revive_time := 60.0

@export var ult_charge_time := 10.0


@export var level_up_sound: AudioStream = preload("res://audio/sfx/ui/level_up.wav")
@export var ult_ready_sound: AudioStream = preload("res://audio/sfx/ui/ult_ready.wav")
@export var upgrade_select_sound: AudioStream = preload("res://audio/sfx/ui/button_click.wav")
@export var water_ult_sound: AudioStream = preload("res://audio/sfx/player/ult_water.wav")
@export var fire_ult_sound: AudioStream = preload("res://audio/sfx/player/ult_fire.wav")
@export var earth_ult_sound: AudioStream = preload("res://audio/sfx/player/ult_earth.wav")
@export var wind_ult_sound: AudioStream = preload("res://audio/sfx/player/ult_wind.wav")


var pickup_range := 180.0
var armor := 0.0
var projectile_speed_mult := 1.0
var projectile_size_mult := 1.0
var multi_shot_count := 1
var xp_multiplier := 1.0

@export var water_form_scene: PackedScene = preload("res://tscn/forms/water_form.tscn")
@export var fire_form_scene: PackedScene = preload("res://tscn/forms/fire_form.tscn")
@export var earth_form_scene: PackedScene = preload("res://tscn/forms/earth_form.tscn")
@export var wind_form_scene: PackedScene = preload("res://tscn/forms/wind_form.tscn")

@export var water_ult_scene: PackedScene = preload("res://tscn/ults/water_ult.tscn")
@export var fire_ult_scene: PackedScene = preload("res://tscn/ults/fire_ult.tscn")
@export var earth_ult_scene: PackedScene = preload("res://tscn/ults/earth_ult.tscn")
@export var wind_ult_scene: PackedScene = preload("res://tscn/ults/wind_ult.tscn")

@onready var forms_root: Node2D = $FormsRoot
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

@export var swap_effect_scene: PackedScene = preload("res://tscn/swap_effect.tscn")
@export var floating_text_scene: PackedScene = preload("res://tscn/floating_text.tscn")

var can_shoot := true
var level := 1
var current_xp := 0
var xp_required := 0
var upgrade_pending := false

var form_order: Array[String] = ["water", "fire", "earth", "wind"]
var form_scenes: Dictionary = {}
var ult_scenes: Dictionary = {}
var form_stats: Dictionary = {}
var active_form_key := "water"
var active_form: Node = null

var element_colors := {
	"water": Color(0.35, 0.75, 1.0, 1.0),
	"fire": Color(1.0, 0.35, 0.15, 1.0),
	"earth": Color(0.55, 0.35, 0.16, 1.0),
	"wind": Color(0.55, 1.0, 0.65, 1.0)
}

var element_identity_stats := {
	"water": {"damage": 0.95, "speed": 1.0, "armor": 1.10, "healing": 1.25},
	"fire": {"damage": 1.18, "speed": 1.0, "armor": 1.0, "healing": 1.0},
	"earth": {"damage": 1.0, "speed": 0.90, "armor": 1.25, "healing": 1.0},
	"wind": {"damage": 0.92, "speed": 1.18, "armor": 0.95, "healing": 1.0}
}


func _ready() -> void:
	add_to_group("player")
	add_child(sfx_player)
	sfx_player.bus = "Master"
	xp_required = starting_xp_required

	form_scenes = {
		"water": water_form_scene,
		"fire": fire_form_scene,
		"earth": earth_form_scene,
		"wind": wind_form_scene
	}

	ult_scenes = {
		"water": water_ult_scene,
		"fire": fire_ult_scene,
		"earth": earth_ult_scene,
		"wind": wind_ult_scene
	}

	_build_form_stats()
	var start_form: String = get_tree().get_meta("player_active_form_key", "water") as String
	_restore_stats_from_meta()
	switch_form(start_form, true)
	xp_changed.emit(current_xp, xp_required, level)
	level_changed.emit(level, current_xp, xp_required)


func _process(delta: float) -> void:
	_update_active_ult_charge(delta)


func _build_form_stats() -> void:
	for key in form_order:
		var scene: PackedScene = form_scenes[key]
		if scene == null:
			continue
		var preview: Node = scene.instantiate()
		var display_name: String = str(preview.get("display_name"))
		var max_hp: int = int(preview.get("base_max_health"))
		preview.free()

		form_stats[key] = {
			"display": display_name,
			"max_health": max_hp,
			"health": max_hp,
			"dead": false,
			"revive_left": 0.0,
			"ult_charge": 0.0,
			"ult_ready": false
		}


func _restore_stats_from_meta() -> void:
	# If the player arrived via the boss-fight transition, SceneTree metadata
	# holds all the stats that were saved just before the scene swap.
	# Read them back and then clear the keys so a fresh run starts clean.
	if not get_tree().has_meta("player_level"):
		return  # Normal fresh start — nothing to restore.

	level          = int(get_tree().get_meta("player_level", level))
	current_xp     = int(get_tree().get_meta("player_current_xp", current_xp))
	xp_required    = int(get_tree().get_meta("player_xp_required", xp_required))
	bullet_damage  = float(get_tree().get_meta("player_bullet_damage", bullet_damage))
	movement_speed = float(get_tree().get_meta("player_movement_speed", movement_speed))
	shoot_cooldown = float(get_tree().get_meta("player_shoot_cooldown", shoot_cooldown))
	armor          = float(get_tree().get_meta("player_armor", armor))
	pickup_range   = float(get_tree().get_meta("player_pickup_range", pickup_range))
	projectile_speed_mult = float(get_tree().get_meta("player_projectile_speed_mult", projectile_speed_mult))
	projectile_size_mult  = float(get_tree().get_meta("player_projectile_size_mult", projectile_size_mult))
	multi_shot_count      = int(get_tree().get_meta("player_multi_shot_count", multi_shot_count))
	xp_multiplier         = float(get_tree().get_meta("player_xp_multiplier", xp_multiplier))
	healing_per_orb       = int(get_tree().get_meta("player_healing_per_orb", healing_per_orb))
	ult_charge_time       = float(get_tree().get_meta("player_ult_charge_time", ult_charge_time))

	# Restore per-form HP (max_health drives the health bar scale, health is current HP).
	var saved_form_health = get_tree().get_meta("player_form_health", {})
	if typeof(saved_form_health) == TYPE_DICTIONARY:
		for key in saved_form_health:
			if form_stats.has(key):
				var entry: Dictionary = saved_form_health[key]
				form_stats[key]["max_health"] = int(entry.get("max_health", form_stats[key]["max_health"]))
				form_stats[key]["health"]     = int(entry.get("health", form_stats[key]["health"]))
				# Revive any knocked-out forms so the player enters the boss fight fresh.
				form_stats[key]["dead"]       = false
				form_stats[key]["revive_left"] = 0.0

	# Clear all saved metadata so a future fresh run is unaffected.
	for meta_key in [
		"player_level", "player_current_xp", "player_xp_required",
		"player_bullet_damage", "player_movement_speed", "player_shoot_cooldown",
		"player_armor", "player_pickup_range", "player_projectile_speed_mult",
		"player_projectile_size_mult", "player_multi_shot_count", "player_xp_multiplier",
		"player_healing_per_orb", "player_ult_charge_time", "player_active_form_key",
		"player_form_health"
	]:
		if get_tree().has_meta(meta_key):
			get_tree().remove_meta(meta_key)


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				switch_form("water")
			KEY_2:
				switch_form("fire")
			KEY_3:
				switch_form("earth")
			KEY_4:
				switch_form("wind")
			KEY_X:
				cast_ult()


func _physics_process(_delta: float) -> void:
	movement()
	animate_player()
	shooting()


func movement() -> void:
	var x_mov := Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov := Input.get_action_strength("down") - Input.get_action_strength("up")
	var input_dir := Vector2(x_mov, y_mov)

	if active_form and active_form.has_method("set_facing"):
		var aim_dir: Vector2 = global_position.direction_to(get_global_mouse_position())
		active_form.set_facing(aim_dir.x)

	var target_velocity := input_dir.normalized() * movement_speed
	
	if input_dir.length() > 0.01:
		velocity = velocity.move_toward(target_velocity, acceleration * get_physics_process_delta_time())
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * get_physics_process_delta_time())
	
	move_and_slide()


func animate_player() -> void:
	if active_form and active_form.has_method("play_movement"):
		var moving := velocity.length() > 0.0
		var walking_backwards := false

		if moving:
			var aim_dir: Vector2 = global_position.direction_to(get_global_mouse_position())
			var move_dir := velocity.normalized()
			if aim_dir != Vector2.ZERO:
				walking_backwards = move_dir.dot(aim_dir.normalized()) < 0.0

		active_form.play_movement(moving, walking_backwards)



func _element_stat(stat_name: String, fallback: float = 1.0) -> float:
	if element_identity_stats.has(active_form_key):
		var data: Dictionary = element_identity_stats[active_form_key]
		return float(data.get(stat_name, fallback))
	return fallback


func shooting() -> void:
	if not Input.is_action_pressed("shoot"):
		return
	if not can_shoot:
		return
	if is_active_form_dead():
		return
	if active_form == null:
		push_warning("No active form loaded.")
		return

	var current_bullet_scene: PackedScene = active_form.get("bullet_scene")
	if current_bullet_scene == null:
		push_warning("Active form has no bullet scene assigned.")
		return

	can_shoot = false

	SFXManager.play_shoot(active_form_key)

	var aim_dir: Vector2 = global_position.direction_to(get_global_mouse_position())
	if aim_dir == Vector2.ZERO:
		aim_dir = Vector2.RIGHT

	for shot in range(multi_shot_count):
		var bullet: Node = current_bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)

		if active_form.has_method("get_shot_position"):
			bullet.global_position = active_form.get_shot_position()
		else:
			bullet.global_position = global_position

		var spread_angle: float = 0.0
		if multi_shot_count > 1:
			spread_angle = deg_to_rad(8.0) * (shot - (multi_shot_count - 1) / 2.0)
		var shot_dir: Vector2 = aim_dir.rotated(spread_angle)
		bullet.direction = shot_dir
		bullet.damage = bullet_damage * _element_stat("damage", 1.0)
		bullet.rotation = shot_dir.angle()
		bullet.speed_mult = projectile_speed_mult * _element_stat("speed", 1.0)
		bullet.size_mult = projectile_size_mult
		# Tell the bullet which element fired it for elemental weakness calc.
		if bullet.get("bullet_element") != null:
			bullet.bullet_element = active_form_key

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


func switch_form(form_key: String, force := false) -> void:
	if not form_scenes.has(form_key):
		return
	if form_key == active_form_key and not force:
		return
	if form_stats.has(form_key) and bool(form_stats[form_key]["dead"]):
		_spawn_floating_text("%s DOWN" % str(form_stats[form_key]["display"]), Color(1.0, 0.25, 0.25, 1.0), global_position + Vector2(0, -70))
		if DEBUG_COMBAT:
			print(form_stats[form_key]["display"], " is knocked out. Revive left: ", int(ceil(float(form_stats[form_key]["revive_left"]))), "s")
		return

	if active_form:
		_play_swap_effect(active_form_key)
		active_form.queue_free()
		active_form = null

	active_form_key = form_key
	active_form = form_scenes[form_key].instantiate()
	forms_root.add_child(active_form)
	active_form.position = Vector2.ZERO

	_play_swap_effect(active_form_key)
	_spawn_floating_text(str(form_stats[active_form_key]["display"]), element_colors.get(active_form_key, Color.WHITE), global_position + Vector2(0, -78))

	_emit_health()
	form_changed.emit(form_stats[active_form_key]["display"])
	if DEBUG_COMBAT:
		print("Switched to ", form_stats[active_form_key]["display"])


func is_active_form_dead() -> bool:
	return bool(form_stats[active_form_key]["dead"])


func take_damage(amount: int) -> void:
	if is_active_form_dead():
		return

	var total_armor: float = clampf(armor + (_element_stat("armor", 1.0) - 1.0), 0.0, 0.75)
	var reduced := int(ceil(float(amount) * (1.0 - total_armor)))
	form_stats[active_form_key]["health"] = int(clamp(int(form_stats[active_form_key]["health"]) - reduced, 0, int(form_stats[active_form_key]["max_health"])))
	_emit_health()
	
	_shake_camera(4.0, 0.08)
	
	if DEBUG_COMBAT:
		print(form_stats[active_form_key]["display"], " health: ", form_stats[active_form_key]["health"])

	if int(form_stats[active_form_key]["health"]) <= 0:
		_knock_out_active_form()


func heal(amount: int) -> void:
	if is_active_form_dead():
		return
	var final_heal: int = int(ceil(float(amount) * _element_stat("healing", 1.0)))
	form_stats[active_form_key]["health"] = int(clamp(int(form_stats[active_form_key]["health"]) + final_heal, 0, int(form_stats[active_form_key]["max_health"])))
	_emit_health()
	if DEBUG_COMBAT:
		print("Healed ", form_stats[active_form_key]["display"], ": +", amount, " HP: ", form_stats[active_form_key]["health"], "/", form_stats[active_form_key]["max_health"])


func _knock_out_active_form() -> void:
	var dead_form := active_form_key
	form_stats[dead_form]["dead"] = true
	form_stats[dead_form]["health"] = 0
	form_stats[dead_form]["revive_left"] = character_revive_time
	_emit_health()
	if DEBUG_COMBAT:
		print(form_stats[dead_form]["display"], " knocked out. Revives in ", int(character_revive_time), " seconds.")
	_revive_countdown(dead_form)

	var next_form := _find_alive_form(dead_form)
	if next_form == "":
		die()
		return
	switch_form(next_form)


func _find_alive_form(exclude_form := "") -> String:
	for key in form_order:
		if key != exclude_form and not bool(form_stats[key]["dead"]):
			return key
	return ""


func _revive_countdown(form_key: String) -> void:
	while float(form_stats[form_key]["revive_left"]) > 0.0:
		await get_tree().create_timer(1.0).timeout
		form_stats[form_key]["revive_left"] = max(0.0, float(form_stats[form_key]["revive_left"]) - 1.0)

	form_stats[form_key]["dead"] = false
	form_stats[form_key]["health"] = int(form_stats[form_key]["max_health"])
	form_stats[form_key]["revive_left"] = 0.0
	if DEBUG_COMBAT:
		print(form_stats[form_key]["display"], " is back!")
	if form_key == active_form_key:
		_emit_health()


func _emit_health() -> void:
	health_changed.emit(int(form_stats[active_form_key]["health"]), int(form_stats[active_form_key]["max_health"]))


func die() -> void:
	if DEBUG_COMBAT:
		print("All characters died")
	get_tree().paused = false
	
	var game_over := get_tree().get_first_node_in_group("game_over")
	if game_over == null:
		var nodes := get_tree().get_nodes_in_group("game_over")
		if nodes.size() > 0:
			game_over = nodes[0]
	
	if game_over and game_over.has_method("show_game_over"):
		var survival_time := 0.0
		var spawner := get_tree().get_first_node_in_group("enemy_spawner")
		if spawner == null:
			var spawners := get_tree().get_nodes_in_group("enemy_spawner")
			if spawners.size() > 0:
				spawner = spawners[0]
		if spawner and spawner.get("elapsed_game_time") != null:
			survival_time = float(spawner.elapsed_game_time)
		
		game_over.show_game_over(level, survival_time, false)
	else:
		get_tree().reload_current_scene()


func collect_xp_orb(amount: int) -> void:
	add_xp(amount)
	heal(healing_per_orb)


func add_xp(amount: int) -> void:
	current_xp += int(ceil(float(amount) * xp_multiplier))

	while current_xp >= xp_required:
		current_xp -= xp_required
		level += 1
		xp_required = int(ceil(float(xp_required) * 1.10))
		level_changed.emit(level, current_xp, xp_required)
		_level_up_effect()
		_start_upgrade_choice()
		break

	xp_changed.emit(current_xp, xp_required, level)


func _start_upgrade_choice() -> void:
	if upgrade_pending:
		return
	upgrade_pending = true
	var options := _make_upgrade_options()
	upgrade_options_ready.emit(options)
	get_tree().paused = true


func _make_upgrade_options() -> Array:
	var types: Array[String] = ["fire_rate", "healing", "damage", "health", "movement_speed", "pickup_range", "armor", "projectile_speed", "projectile_size", "multi_shot", "xp_multiplier"]
	types.shuffle()
	var options: Array = []
	for i in range(3):
		var percent: int = [5, 10, 15, 20].pick_random()
		options.append({"type": types[i], "percent": percent})
	return options


func apply_upgrade(upgrade_type: String, percent: int) -> void:
	var multiplier: float = 1.0 + float(percent) / 100.0

	match upgrade_type:
		"fire_rate":
			shoot_cooldown = max(0.05, shoot_cooldown * (1.0 - float(percent) / 100.0))
			if DEBUG_COMBAT:
				print("Fire rate upgraded by ", percent, "% Cooldown: ", shoot_cooldown)
		"healing":
			healing_per_orb = max(1, int(ceil(float(healing_per_orb) * multiplier)))
			if DEBUG_COMBAT:
				print("Healing upgraded by ", percent, "% Heal/orb: ", healing_per_orb)
		"damage":
			bullet_damage = max(1.0, bullet_damage * multiplier)
			if DEBUG_COMBAT:
				print("Damage upgraded by ", percent, "% Bullet damage: ", bullet_damage)
		"health":
			form_stats[active_form_key]["max_health"] = int(ceil(float(form_stats[active_form_key]["max_health"]) * multiplier))
			form_stats[active_form_key]["health"] = int(clamp(int(form_stats[active_form_key]["health"]), 0, int(form_stats[active_form_key]["max_health"])))
			_emit_health()
		"movement_speed":
			movement_speed = max(100.0, movement_speed * multiplier)
		"pickup_range":
			pickup_range = max(50.0, pickup_range * multiplier)
		"armor":
			armor = min(0.8, armor + float(percent) / 100.0)
		"projectile_speed":
			projectile_speed_mult = max(0.5, projectile_speed_mult * multiplier)
		"projectile_size":
			projectile_size_mult = max(0.3, projectile_size_mult * multiplier)
		"multi_shot":
			multi_shot_count = min(5, multi_shot_count + 1)
		"xp_multiplier":
			xp_multiplier = max(0.5, xp_multiplier * multiplier)

	upgrade_pending = false
	get_tree().paused = false


func _shake_camera(strength: float, duration: float) -> void:
	var camera: Camera2D = $Camera2D
	if camera:
		var original_offset := camera.offset
		var tween: Tween = create_tween()
		var steps := int(duration / 0.02)
		for _i in range(steps):
			tween.tween_callback(func():
				camera.offset = original_offset + Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
			)
			tween.tween_interval(0.02)
		tween.tween_callback(func(): camera.offset = original_offset)


func _level_up_effect() -> void:
	_play_sfx(level_up_sound)
	_screen_shake(5.0, 0.14)
	_spawn_floating_text("LEVEL UP!", Color(1.0, 0.88, 0.25, 1.0), global_position + Vector2(0, -90))
	if active_form and active_form.has_node("AnimatedSprite2D"):
		var s: AnimatedSprite2D = active_form.get_node("AnimatedSprite2D")
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(s, "modulate", Color(1.5, 1.5, 2.0, 1), 0.1)
		tween.tween_property(s, "scale", Vector2(1.15, 1.15), 0.1)
		tween.tween_interval(0.1)
		tween.tween_property(s, "modulate", Color(1, 1, 1, 1), 0.2)
		tween.tween_property(s, "scale", Vector2(1, 1), 0.2)
	
	_shake_camera(2.0, 0.06)




func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.bus = "Master"
	audio.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)


func _screen_shake(strength: float, duration: float) -> void:
	var shaker: Node = get_tree().get_first_node_in_group("screen_shake")
	if shaker and shaker.has_method("shake"):
		shaker.shake(strength, duration)


func _play_ult_sfx(element_key: String) -> void:
	match element_key:
		"water":
			_play_sfx(water_ult_sound)
		"fire":
			_play_sfx(fire_ult_sound)
		"earth":
			_play_sfx(earth_ult_sound)
		"wind":
			_play_sfx(wind_ult_sound)
		_:
			pass


func _play_swap_effect(form_key: String) -> void:
	if swap_effect_scene == null:
		return
	var effect = swap_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position + Vector2(0, -14)
	effect.element_color = element_colors.get(form_key, Color.WHITE)


func _spawn_floating_text(text: String, color: Color, world_position: Vector2) -> void:
	if floating_text_scene == null:
		return
	var popup = floating_text_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = world_position
	popup.text = text
	popup.color = color


func _update_active_ult_charge(delta: float) -> void:
	if get_tree().paused:
		return
	if not form_stats.has(active_form_key):
		return
	if bool(form_stats[active_form_key]["dead"]):
		return
	if bool(form_stats[active_form_key]["ult_ready"]):
		return

	form_stats[active_form_key]["ult_charge"] = min(ult_charge_time, float(form_stats[active_form_key]["ult_charge"]) + delta)
	if float(form_stats[active_form_key]["ult_charge"]) >= ult_charge_time:
		form_stats[active_form_key]["ult_ready"] = true
		if DEBUG_COMBAT:
			print(form_stats[active_form_key]["display"], " ult ready! Press X.")


func cast_ult() -> void:
	if is_active_form_dead():
		return
	if not bool(form_stats[active_form_key].get("ult_ready", false)):
		if DEBUG_COMBAT:
			print(form_stats[active_form_key]["display"], " ult is not ready yet.")
		return

	if active_form_key == "wind":
		_play_ult_sfx(active_form_key)
		_screen_shake(7.0, 0.18)
		_cast_wind_dash_ult()
		_reset_active_ult()
		return

	if not ult_scenes.has(active_form_key):
		return

	var ult_scene: PackedScene = ult_scenes[active_form_key]
	if ult_scene == null:
		return

	var ult = ult_scene.instantiate()
	ult.global_position = global_position + Vector2(0, 26)
	ult.z_index = -2
	ult.z_as_relative = false

	get_tree().current_scene.add_child(ult)
	_play_ult_sfx(active_form_key)
	_screen_shake(8.0, 0.2)

	_reset_active_ult()
	if DEBUG_COMBAT:
		print("CAST ULT: ", form_stats[active_form_key]["display"])


func _reset_active_ult() -> void:
	form_stats[active_form_key]["ult_charge"] = 0.0
	form_stats[active_form_key]["ult_ready"] = false


func _cast_wind_dash_ult() -> void:
	var aim_dir: Vector2 = global_position.direction_to(get_global_mouse_position())
	if aim_dir.length() <= 0.01:
		aim_dir = Vector2.RIGHT

	var dash_distance: float = 650.0
	var dash_width: float = 120.0
	var start_pos: Vector2 = global_position
	var end_pos: Vector2 = start_pos + aim_dir.normalized() * dash_distance
	end_pos = _clamp_dash_end_position(end_pos)

	_kill_enemies_along_dash(start_pos, end_pos, dash_width)

	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", end_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_play_wind_dash_fx(start_pos, end_pos)



func _clamp_dash_end_position(end_pos: Vector2) -> Vector2:
	var scene := get_tree().current_scene
	if scene == null:
		return end_pos

	# Boss arena bounds from boss_arena.tscn walls.
	if scene.name == "BossArena" or scene.scene_file_path.ends_with("boss_arena.tscn"):
		return Vector2(
			clampf(end_pos.x, 96.0, 1184.0),
			clampf(end_pos.y, 110.0, 650.0)
		)

	return end_pos


func _kill_enemies_along_dash(start_pos: Vector2, end_pos: Vector2, width: float) -> void:
	var dash_vec: Vector2 = end_pos - start_pos
	var dash_len: float = dash_vec.length()
	if dash_len <= 0.01:
		return

	var dash_dir: Vector2 = dash_vec.normalized()

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == null or not is_instance_valid(enemy) or not (enemy is Node2D):
			continue

		var enemy_node: Node2D = enemy as Node2D
		var enemy_pos: Vector2 = enemy_node.global_position
		var projection: float = clampf((enemy_pos - start_pos).dot(dash_dir), 0.0, dash_len)
		var closest: Vector2 = start_pos + dash_dir * projection
		var distance: float = enemy_pos.distance_to(closest)

		if distance <= width:
			if enemy.has_method("kill_without_xp"):
				enemy.kill_without_xp()
			elif enemy.has_method("die"):
				enemy.die()


func _play_wind_dash_fx(start_pos: Vector2, end_pos: Vector2) -> void:
	var line := Line2D.new()
	line.width = 12.0
	line.default_color = Color(0.55, 1.0, 0.65, 0.75)
	line.z_index = 120
	line.z_as_relative = false
	line.add_point(start_pos)
	line.add_point(end_pos)
	get_tree().current_scene.add_child(line)

	var tween: Tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.28)
	tween.tween_callback(Callable(line, "queue_free"))


func apply_water_ult() -> void:
	for key in form_order:
		if not form_stats.has(key):
			continue
		form_stats[key]["dead"] = false
		form_stats[key]["revive_left"] = 0.0
		form_stats[key]["health"] = int(form_stats[key]["max_health"])

	_emit_health()
	if DEBUG_COMBAT:
		print("Water ult: all characters fully healed and revived.")
