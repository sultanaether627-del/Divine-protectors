extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal xp_changed(current_xp: int, xp_required: int, level: int)
signal level_changed(level: int, current_xp: int, xp_required: int)
signal upgrade_options_ready(options: Array)
signal form_changed(form_name: String)

@export var movement_speed := 400.0
@export var shoot_cooldown := 0.25
@export var starting_xp_required := 10
@export var healing_per_orb := 5
@export var bullet_damage := 10.0
@export var character_revive_time := 60.0
@export var ult_charge_time := 90.0

@export var water_form_scene: PackedScene = preload("res://tscn/forms/water_form.tscn")
@export var fire_form_scene: PackedScene = preload("res://tscn/forms/fire_form.tscn")
@export var earth_form_scene: PackedScene = preload("res://tscn/forms/earth_form.tscn")
@export var wind_form_scene: PackedScene = preload("res://tscn/forms/wind_form.tscn")

@export var water_ult_scene: PackedScene = preload("res://tscn/ults/water_ult.tscn")
@export var fire_ult_scene: PackedScene = preload("res://tscn/ults/fire_ult.tscn")
@export var earth_ult_scene: PackedScene = preload("res://tscn/ults/earth_ult.tscn")
@export var wind_ult_scene: PackedScene = preload("res://tscn/ults/wind_ult.tscn")

@onready var forms_root: Node2D = $FormsRoot

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


func _ready() -> void:
	add_to_group("player")
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
	switch_form("water", true)
	xp_changed.emit(current_xp, xp_required, level)
	level_changed.emit(level, current_xp, xp_required)


func _process(delta: float) -> void:
	_update_active_ult_charge(delta)


func _build_form_stats() -> void:
	for key in form_order:
		var scene: PackedScene = form_scenes[key]
		if scene == null:
			continue
		var preview = scene.instantiate()
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
	var mov := Vector2(x_mov, y_mov)

	if active_form and active_form.has_method("set_facing"):
		var aim_dir := global_position.direction_to(get_global_mouse_position())
		active_form.set_facing(aim_dir.x)

	velocity = mov.normalized() * movement_speed
	move_and_slide()


func animate_player() -> void:
	if active_form and active_form.has_method("play_movement"):
		var moving := velocity.length() > 0.0
		var walking_backwards := false

		if moving:
			var aim_dir := global_position.direction_to(get_global_mouse_position())
			var move_dir := velocity.normalized()
			if aim_dir != Vector2.ZERO:
				walking_backwards = move_dir.dot(aim_dir.normalized()) < 0.0

		active_form.play_movement(moving, walking_backwards)


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

	var aim_dir := global_position.direction_to(get_global_mouse_position())
	if aim_dir == Vector2.ZERO:
		aim_dir = Vector2.RIGHT

	var bullet = current_bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	if active_form.has_method("get_shot_position"):
		bullet.global_position = active_form.get_shot_position()
	else:
		bullet.global_position = global_position

	bullet.direction = aim_dir
	bullet.damage = bullet_damage
	bullet.rotation = aim_dir.angle()

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


func switch_form(form_key: String, force := false) -> void:
	if not form_scenes.has(form_key):
		return
	if form_key == active_form_key and not force:
		return
	if form_stats.has(form_key) and bool(form_stats[form_key]["dead"]):
		print(form_stats[form_key]["display"], " is knocked out. Revive left: ", int(ceil(float(form_stats[form_key]["revive_left"]))), "s")
		return

	if active_form:
		active_form.queue_free()
		active_form = null

	active_form_key = form_key
	active_form = form_scenes[form_key].instantiate()
	forms_root.add_child(active_form)
	active_form.position = Vector2.ZERO

	_emit_health()
	form_changed.emit(form_stats[active_form_key]["display"])
	print("Switched to ", form_stats[active_form_key]["display"])


func is_active_form_dead() -> bool:
	return bool(form_stats[active_form_key]["dead"])


func take_damage(amount: int) -> void:
	if is_active_form_dead():
		return

	form_stats[active_form_key]["health"] = int(clamp(int(form_stats[active_form_key]["health"]) - amount, 0, int(form_stats[active_form_key]["max_health"])))
	_emit_health()
	print(form_stats[active_form_key]["display"], " health: ", form_stats[active_form_key]["health"])

	if int(form_stats[active_form_key]["health"]) <= 0:
		_knock_out_active_form()


func heal(amount: int) -> void:
	if is_active_form_dead():
		return
	form_stats[active_form_key]["health"] = int(clamp(int(form_stats[active_form_key]["health"]) + amount, 0, int(form_stats[active_form_key]["max_health"])))
	_emit_health()
	print("Healed ", form_stats[active_form_key]["display"], ": +", amount, " HP: ", form_stats[active_form_key]["health"], "/", form_stats[active_form_key]["max_health"])


func _knock_out_active_form() -> void:
	var dead_form := active_form_key
	form_stats[dead_form]["dead"] = true
	form_stats[dead_form]["health"] = 0
	form_stats[dead_form]["revive_left"] = character_revive_time
	_emit_health()
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
	print(form_stats[form_key]["display"], " is back!")
	if form_key == active_form_key:
		_emit_health()


func _emit_health() -> void:
	health_changed.emit(int(form_stats[active_form_key]["health"]), int(form_stats[active_form_key]["max_health"]))


func die() -> void:
	print("All characters died")
	get_tree().paused = false
	get_tree().reload_current_scene()


func collect_xp_orb(amount: int) -> void:
	add_xp(amount)
	heal(healing_per_orb)


func add_xp(amount: int) -> void:
	current_xp += amount

	while current_xp >= xp_required:
		current_xp -= xp_required
		level += 1
		xp_required = int(ceil(float(xp_required) * 1.10))
		print("LEVEL UP! Level: ", level)
		level_changed.emit(level, current_xp, xp_required)
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
	var types: Array[String] = ["fire_rate", "healing", "damage", "health"]
	types.shuffle()
	var options: Array = []
	for i in range(3):
		var percent: int = [5, 10, 15, 20].pick_random()
		options.append({"type": types[i], "percent": percent})
	return options


func apply_upgrade(upgrade_type: String, percent: int) -> void:
	var multiplier := 1.0 + float(percent) / 100.0

	match upgrade_type:
		"fire_rate":
			shoot_cooldown = max(0.05, shoot_cooldown * (1.0 - float(percent) / 100.0))
			print("Fire rate upgraded by ", percent, "% Cooldown: ", shoot_cooldown)
		"healing":
			healing_per_orb = max(1, int(ceil(float(healing_per_orb) * multiplier)))
			print("Healing upgraded by ", percent, "% Heal/orb: ", healing_per_orb)
		"damage":
			bullet_damage = max(1.0, bullet_damage * multiplier)
			print("Damage upgraded by ", percent, "% Bullet damage: ", bullet_damage)
		"health":
			form_stats[active_form_key]["max_health"] = int(ceil(float(form_stats[active_form_key]["max_health"]) * multiplier))
			form_stats[active_form_key]["health"] = int(clamp(int(form_stats[active_form_key]["health"]), 0, int(form_stats[active_form_key]["max_health"])))
			_emit_health()
			print("Max HP upgraded by ", percent, "% for ", form_stats[active_form_key]["display"], ". Max HP: ", form_stats[active_form_key]["max_health"])

	upgrade_pending = false
	get_tree().paused = false


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
		print(form_stats[active_form_key]["display"], " ult ready! Press X.")


func cast_ult() -> void:
	if is_active_form_dead():
		return
	if not bool(form_stats[active_form_key].get("ult_ready", false)):
		print(form_stats[active_form_key]["display"], " ult is not ready yet.")
		return
	if not ult_scenes.has(active_form_key):
		return

	var ult_scene: PackedScene = ult_scenes[active_form_key]
	if ult_scene == null:
		return

	var ult = ult_scene.instantiate()

	# Set the position BEFORE adding it to the scene.
	# Godot runs _ready() as soon as the node enters the tree,
	# so setting this after add_child() makes the ult effect apply at (0, 0).
	ult.global_position = global_position + Vector2(0, 26)
	ult.z_index = -50

	get_tree().current_scene.add_child(ult)

	form_stats[active_form_key]["ult_charge"] = 0.0
	form_stats[active_form_key]["ult_ready"] = false
	print("CAST ULT: ", form_stats[active_form_key]["display"])


func apply_water_ult() -> void:
	for key in form_order:
		if not form_stats.has(key):
			continue
		form_stats[key]["dead"] = false
		form_stats[key]["revive_left"] = 0.0
		form_stats[key]["health"] = int(form_stats[key]["max_health"])

	_emit_health()
	print("Water ult: all characters fully healed and revived.")
