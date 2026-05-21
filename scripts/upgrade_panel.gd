extends PanelContainer

@onready var title_label: Label = $VBoxContainer/Title
@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var option_buttons := [
	$VBoxContainer/Option1,
	$VBoxContainer/Option2,
	$VBoxContainer/Option3
]
@onready var option_labels := [
	$VBoxContainer/Option1/OptionLabel,
	$VBoxContainer/Option2/OptionLabel,
	$VBoxContainer/Option3/OptionLabel
]
@onready var option_icons := [
	$VBoxContainer/Option1/OptionIcon,
	$VBoxContainer/Option2/OptionIcon,
	$VBoxContainer/Option3/OptionIcon
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
		option_buttons[i].process_mode = Node.PROCESS_MODE_ALWAYS
		option_buttons[i].pressed.connect(_choose_option.bind(i))
		option_buttons[i].mouse_entered.connect(_on_button_hover.bind(i))
		option_buttons[i].mouse_exited.connect(_on_button_unhover.bind(i))


func _on_level_changed(level: int, _current_xp: int, _xp_required: int) -> void:
	if level_label:
		level_label.text = "Level %d" % level


func _show_options(options: Array) -> void:
	current_options = options
	visible = true
	title_label.text = "LEVEL UP!"

	for i in range(option_buttons.size()):
		var option: Dictionary = current_options[i]
		var type: String = option["type"]
		var percent: int = option["percent"]
		
		if i < option_labels.size() and option_labels[i]:
			option_labels[i].text = _option_text(type, percent)
		if i < option_icons.size() and option_icons[i]:
			var icon: Texture2D = UPGRADE_ICONS.get(type, null)
			if icon:
				option_icons[i].texture = icon
				option_icons[i].visible = true
			else:
				option_icons[i].visible = false
		
		option_buttons[i].disabled = false
		option_buttons[i].modulate = Color(1, 1, 1, 1)


func _on_button_hover(index: int) -> void:
	option_buttons[index].modulate = Color(1.15, 1.15, 1.0, 1.0)


func _on_button_unhover(index: int) -> void:
	option_buttons[index].modulate = Color(1, 1, 1, 1)


func _choose_option(index: int) -> void:
	if player == null or index >= current_options.size():
		return

	for button in option_buttons:
		button.disabled = true

	var option: Dictionary = current_options[index]
	visible = false
	player.apply_upgrade(option["type"], option["percent"])


func _option_text(upgrade_type: String, percent: int) -> String:
	var name: String = UPGRADE_NAMES.get(upgrade_type, upgrade_type.capitalize())
	return "%s  +%d%%" % [name, percent]
