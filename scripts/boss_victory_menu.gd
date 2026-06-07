extends CanvasLayer

@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $PanelContainer/VBoxContainer/SubTitleLabel
@onready var continue_button: Button = $PanelContainer/VBoxContainer/ContinueButton
@onready var end_season_button: Button = $PanelContainer/VBoxContainer/EndSeasonButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	end_season_button.pressed.connect(_on_end_season_pressed)


func show_victory_menu() -> void:
	title_label.text = "BOSS DEFEATED"
	subtitle_label.text = "Continue the fight on the map, or end the season."
	visible = true
	get_tree().paused = true


func _on_continue_pressed() -> void:
	visible = false
	get_tree().paused = false
	_save_player_stats()
	# Tell the fresh BossBattleTimer in world.tscn that the boss is already dead
	# so it never re-triggers the fight prompt.
	get_tree().set_meta("boss_already_defeated", true)
	var err: int = get_tree().change_scene_to_file("res://tscn/world.tscn")
	if err != OK:
		push_error("BossVictoryMenu: Could not return to res://tscn/world.tscn")


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


func _on_end_season_pressed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://tscn/ending_screen.tscn")
