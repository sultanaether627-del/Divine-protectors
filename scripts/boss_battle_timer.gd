extends Node2D

signal boss_timer_changed(time_left: float)
signal boss_battle_started

@export var boss_unlock_time: float = 1.0
@export var boss_arena_scene: PackedScene = preload("res://tscn/boss_arena.tscn")
# How long after the timer hits 0 before the boss gains another strength level.
@export var strength_gain_interval: float = 30.0

var elapsed_time: float = 0.0
var boss_started: bool = false
var prompt_shown: bool = false
var extra_wait_elapsed: float = 0.0
var current_strength_level: int = 0
# When >= 0 the player chose to wait; re-show the prompt once extra_wait_elapsed reaches this value.
var next_prompt_at: float = -1.0

# Prompt UI nodes (built at runtime so no extra .tscn needed).
var prompt_canvas: CanvasLayer = null
var countdown_label: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("boss_timer")
	get_tree().set_meta("boss_strength_level", 0)
	boss_timer_changed.emit(boss_unlock_time)


func _process(delta: float) -> void:
	if boss_started:
		return

	elapsed_time += delta
	var time_left := maxf(0.0, boss_unlock_time - elapsed_time)
	boss_timer_changed.emit(time_left)

	# Timer hasn't expired yet — nothing else to do.
	if time_left > 0.0:
		return

	# Accumulate time spent past the unlock point (whether prompt is up or not).
	extra_wait_elapsed += delta

	# Track boss strength level based on how long the player has waited.
	var new_level := int(extra_wait_elapsed / strength_gain_interval)
	if new_level != current_strength_level:
		current_strength_level = new_level
		get_tree().set_meta("boss_strength_level", current_strength_level)
		if prompt_shown:
			_update_prompt_strength_label()

	# Update the countdown inside the prompt every frame.
	if prompt_shown:
		_update_countdown_label()

	# Show prompt if not already visible, and the scheduled re-show time has arrived.
	if not prompt_shown:
		if next_prompt_at < 0.0 or extra_wait_elapsed >= next_prompt_at:
			_show_boss_prompt()


func _show_boss_prompt() -> void:
	prompt_shown = true

	prompt_canvas = CanvasLayer.new()
	prompt_canvas.layer = 100
	add_child(prompt_canvas)

	# Dark overlay.
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prompt_canvas.add_child(overlay)

	# Panel container — centred box.
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(540, 320)
	panel.offset_left = -270
	panel.offset_top = -160
	panel.offset_right = 270
	panel.offset_bottom = 160
	prompt_canvas.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "THE BOSS AWAITS!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
	vbox.add_child(title)

	var strength_label := Label.new()
	strength_label.name = "StrengthLabel"
	strength_label.text = _strength_text()
	strength_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strength_label.add_theme_font_size_override("font_size", 16)
	strength_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.25, 1.0))
	vbox.add_child(strength_label)

	# Live countdown to next strength gain.
	countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.text = _countdown_text()
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 14)
	countdown_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	vbox.add_child(countdown_label)

	var desc := Label.new()
	desc.text = "Every %ds you wait the boss gains a strength level." % int(strength_gain_interval)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60, 1.0))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var fight_btn := Button.new()
	fight_btn.text = "Fight Now"
	fight_btn.custom_minimum_size = Vector2(190, 52)
	fight_btn.add_theme_font_size_override("font_size", 18)
	fight_btn.pressed.connect(_on_fight_now_pressed)
	btn_row.add_child(fight_btn)

	var wait_btn := Button.new()
	wait_btn.text = "Wait (boss grows)"
	wait_btn.custom_minimum_size = Vector2(190, 52)
	wait_btn.add_theme_font_size_override("font_size", 18)
	wait_btn.pressed.connect(_on_wait_pressed)
	btn_row.add_child(wait_btn)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _strength_text() -> String:
	if current_strength_level == 0:
		return "Boss Strength: Normal"
	return "Boss Strength  Lv.+%d  |  HP ×%.1f  |  DMG ×%.1f" % [
		current_strength_level,
		1.0 + current_strength_level * 0.6,
		1.0 + current_strength_level * 0.3
	]


func _countdown_text() -> String:
	# Seconds until the NEXT strength gain tick.
	var next_tick_at := float(current_strength_level + 1) * strength_gain_interval
	var secs_left := int(ceil(next_tick_at - extra_wait_elapsed))
	secs_left = maxi(0, secs_left)
	return "Next strength gain in: %ds" % secs_left


func _update_prompt_strength_label() -> void:
	if prompt_canvas == null:
		return
	var lbl: Label = prompt_canvas.find_child("StrengthLabel", true, false) as Label
	if lbl:
		lbl.text = _strength_text()


func _update_countdown_label() -> void:
	if countdown_label == null or not is_instance_valid(countdown_label):
		return
	countdown_label.text = _countdown_text()


# ── Button handlers ───────────────────────────────────────────────────────────

func _on_fight_now_pressed() -> void:
	_start_boss_battle()


func _on_wait_pressed() -> void:
	# Destroy the prompt entirely — no hidden overlay blocking input.
	if prompt_canvas:
		prompt_canvas.queue_free()
		prompt_canvas = null
	countdown_label = null
	prompt_shown = false
	# Schedule the next prompt one interval from now (tracked via extra_wait_elapsed).
	next_prompt_at = extra_wait_elapsed + strength_gain_interval


# ── Stat saving ───────────────────────────────────────────────────────────────

func _save_player_stats() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	get_tree().set_meta("player_level", player.level)
	get_tree().set_meta("player_current_xp", player.current_xp)
	get_tree().set_meta("player_xp_required", player.xp_required)
	get_tree().set_meta("player_bullet_damage", player.bullet_damage)
	get_tree().set_meta("player_movement_speed", player.movement_speed)
	get_tree().set_meta("player_shoot_cooldown", player.shoot_cooldown)
	get_tree().set_meta("player_armor", player.armor)
	get_tree().set_meta("player_pickup_range", player.pickup_range)
	get_tree().set_meta("player_projectile_speed_mult", player.projectile_speed_mult)
	get_tree().set_meta("player_projectile_size_mult", player.projectile_size_mult)
	get_tree().set_meta("player_multi_shot_count", player.multi_shot_count)
	get_tree().set_meta("player_xp_multiplier", player.xp_multiplier)
	get_tree().set_meta("player_healing_per_orb", player.healing_per_orb)
	get_tree().set_meta("player_ult_charge_time", player.ult_charge_time)
	get_tree().set_meta("player_active_form_key", player.active_form_key)

	var form_health_data: Dictionary = {}
	for key in player.form_stats:
		var fs: Dictionary = player.form_stats[key]
		form_health_data[key] = {
			"health": int(fs["health"]),
			"max_health": int(fs["max_health"])
		}
	get_tree().set_meta("player_form_health", form_health_data)


# ── Scene transition ──────────────────────────────────────────────────────────

func _start_boss_battle() -> void:
	if boss_started:
		return
	boss_started = true

	if prompt_canvas:
		prompt_canvas.queue_free()
		prompt_canvas = null
	countdown_label = null

	get_tree().set_meta("boss_strength_level", current_strength_level)
	_save_player_stats()

	boss_battle_started.emit()
	get_tree().paused = false

	if boss_arena_scene == null:
		push_error("BossBattleTimer: boss_arena_scene is missing.")
		return

	var err := get_tree().change_scene_to_packed(boss_arena_scene)
	if err != OK:
		push_error("BossBattleTimer: Failed to change to boss arena scene.")
