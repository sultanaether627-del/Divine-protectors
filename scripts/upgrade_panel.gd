extends PanelContainer

@onready var title_label: Label = $VBoxContainer/Title
@onready var option_buttons := [
	$VBoxContainer/Option1,
	$VBoxContainer/Option2,
	$VBoxContainer/Option3
]

var player: Node = null
var current_options: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if player and player.has_signal("upgrade_options_ready"):
		player.upgrade_options_ready.connect(_show_options)

	for i in range(option_buttons.size()):
		option_buttons[i].process_mode = Node.PROCESS_MODE_ALWAYS
		option_buttons[i].pressed.connect(_choose_option.bind(i))


func _show_options(options: Array) -> void:
	current_options = options
	visible = true
	title_label.text = "LEVEL UP - CHOOSE AN UPGRADE"

	for i in range(option_buttons.size()):
		var option: Dictionary = current_options[i]
		option_buttons[i].text = _option_text(option["type"], option["percent"])
		option_buttons[i].disabled = false


func _choose_option(index: int) -> void:
	if player == null or index >= current_options.size():
		return

	for button in option_buttons:
		button.disabled = true

	var option: Dictionary = current_options[index]
	visible = false
	player.apply_upgrade(option["type"], option["percent"])


func _option_text(upgrade_type: String, percent: int) -> String:
	match upgrade_type:
		"fire_rate":
			return "Fire Rate +%d%%" % percent
		"healing":
			return "Healing +%d%%" % percent
		"damage":
			return "Damage +%d%%" % percent
		"health":
			return "Max Health +%d%%" % percent
	return "Upgrade +%d%%" % percent
