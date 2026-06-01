extends PanelContainer

@onready var title_label: Label = $VBoxContainer/LeftInfo/Title
@onready var level_label: Label = $VBoxContainer/LeftInfo/LevelLabel
@onready var stats_label: Label = $VBoxContainer/LeftInfo/StatsLabel

@onready var option_buttons: Array = [
	$VBoxContainer/OptionsBox/Option1,
	$VBoxContainer/OptionsBox/Option2,
	$VBoxContainer/OptionsBox/Option3
]

@onready var option_labels: Array = [
	$VBoxContainer/OptionsBox/Option1/OptionLabel,
	$VBoxContainer/OptionsBox/Option2/OptionLabel,
	$VBoxContainer/OptionsBox/Option3/OptionLabel
]

@onready var option_icons: Array = [
	$VBoxContainer/OptionsBox/Option1/OptionIcon,
	$VBoxContainer/OptionsBox/Option2/OptionIcon,
	$VBoxContainer/OptionsBox/Option3/OptionIcon
]

var player: Node = null
var current_options: Array = []

const UPGRADE_ICONS := {
	"fire_rate": preload("res://UI-20260510T082413Z-3-001/UI/attack speed.png"),
	"healing": preload("res://UI-20260510T082413Z-3-001/UI/lifesteal.png"),
	"damage": preload("res://UI-20260510T082413Z-3-001/UI/atk.png"),
	"health": preload("res://UI-20260510T082413Z-3-001/UI/heart.png"),
	"movement_speed": preload("res://UI-20260510T082413Z-3-001/UI/speed.png"),
	"pickup_range": preload("res://UI-20260510T082413Z-3-001/UI/pick up range.png"),
	"armor": preload("res://UI-20260510T082413Z-3-001/UI/lowhp.png"),
	"projectile_speed": preload("res://UI-20260510T082413Z-3-001/UI/attack speed2.png"),
	"projectile_size": preload("res://UI-20260510T082413Z-3-001/UI/atk2.png"),
	"multi_shot": preload("res://UI-20260510T082413Z-3-001/UI/atk2.png"),
	"xp_multiplier": preload("res://UI-20260510T082413Z-3-001/UI/pick up range2.png")
}

const UPGRADE_NAMES := {
	"fire_rate": "Attack Speed",
	"healing": "Life Steal",
	"damage": "Damage",
	"health": "Max Health",
	"movement_speed": "Move Speed",
	"pickup_range": "Pickup Range",
	"armor": "Armor",
	"projectile_speed": "Projectile Speed",
	"projectile_size": "Projectile Size",
	"multi_shot": "Multi Shot",
	"xp_multiplier": "XP Gain"
}

const UPGRADE_DESCRIPTIONS := {
	"fire_rate": "Shoot faster.",
	"healing": "XP orbs heal more.",
	"damage": "Bullets deal more damage.",
	"health": "Raises max HP.",
	"movement_speed": "Move faster.",
	"pickup_range": "Collect XP from farther away.",
	"armor": "Take less damage.",
	"projectile_speed": "Bullets move faster.",
	"projectile_size": "Bullets become larger.",
	"multi_shot": "Adds another projectile.",
	"xp_multiplier": "Gain more XP."
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if player and player.has_signal("upgrade_options_ready"):
		player.upgrade_options_ready.connect(_show_options)

	if player and player.has_signal("level_changed"):
		player.level_changed.connect(_on_level_changed)

	for i in range(option_buttons.size()):
		var button: Button = option_buttons[i]
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.pressed.connect(_choose_option.bind(i))
		button.mouse_entered.connect(_on_button_hover.bind(i))
		button.mouse_exited.connect(_on_button_unhover.bind(i))


func _on_level_changed(level: int, _current_xp: int, _xp_required: int) -> void:
	if level_label and not visible:
		level_label.text = "Level %d" % level


func _show_options(options: Array) -> void:
	current_options = options
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)

	title_label.text = "LEVEL UP!"
	level_label.text = "Choose one blessing"
	_update_stats_label()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	for i in range(option_buttons.size()):
		if i >= current_options.size():
			option_buttons[i].visible = false
			continue

		option_buttons[i].visible = true

		var option: Dictionary = current_options[i]
		var type: String = str(option.get("type", "damage"))
		var percent: int = int(option.get("percent", 5))

		var label: Label = option_labels[i]
		if label:
			label.text = _option_text(type, percent)

		var icon_rect: TextureRect = option_icons[i]
		if icon_rect:
			var icon: Texture2D = UPGRADE_ICONS.get(type, null)
			icon_rect.texture = icon
			icon_rect.visible = icon != null

		var button: Button = option_buttons[i]
		button.disabled = false
		button.modulate = Color(1, 1, 1, 1)
		button.scale = Vector2(1, 1)


func _on_button_hover(index: int) -> void:
	if index >= option_buttons.size():
		return

	var button: Button = option_buttons[index]
	button.modulate = Color(1.16, 1.12, 0.86, 1.0)

	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.025, 1.025), 0.08)


func _on_button_unhover(index: int) -> void:
	if index >= option_buttons.size():
		return

	var button: Button = option_buttons[index]
	button.modulate = Color(1, 1, 1, 1)

	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1, 1), 0.08)


func _choose_option(index: int) -> void:
	if player == null or index >= current_options.size():
		return

	for button in option_buttons:
		button.disabled = true

	var option: Dictionary = current_options[index]
	visible = false
	player.apply_upgrade(str(option.get("type", "damage")), int(option.get("percent", 5)))


func _option_text(upgrade_type: String, percent: int) -> String:
	var name: String = UPGRADE_NAMES.get(upgrade_type, upgrade_type.capitalize())
	var description: String = UPGRADE_DESCRIPTIONS.get(upgrade_type, "")

	if upgrade_type == "multi_shot":
		return "%s\n+1 extra projectile\n%s" % [name, description]

	return "%s  +%d%%\n%s" % [name, percent, description]


func _update_stats_label() -> void:
	if player == null or stats_label == null:
		return

	var damage_bonus: int = int(round((float(player.bullet_damage) / 10.0 - 1.0) * 100.0))
	var speed_bonus: int = int(round((float(player.movement_speed) / 400.0 - 1.0) * 100.0))
	var haste_bonus: int = int(round((0.25 / max(0.01, float(player.shoot_cooldown)) - 1.0) * 100.0))

	# Show pickup range as tile dots (each ● = ~32px / 1 tile of range).
	var tile_size: float = 32.0
	var range_tiles: int = int(round(float(player.pickup_range) / tile_size))
	range_tiles = clamp(range_tiles, 1, 10)
	var range_dots: String = "●".repeat(range_tiles)

	stats_label.text = "ATK      %+d%%\nSPD      %+d%%\nHASTE    %+d%%\nPICKUP  %s" % [
		damage_bonus,
		speed_bonus,
		haste_bonus,
		range_dots
	]
