extends ProgressBar

@onready var label: Label = $XPText

var player: Node

const COLOR_XP := Color(0.3, 0.5, 0.95, 1.0)


func _ready() -> void:
	show_percentage = false
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	var bar_style := get_theme_stylebox("fill", "ProgressBar")
	if bar_style:
		bar_style.bg_color = COLOR_XP

	if player:
		max_value = player.xp_required
		value = player.current_xp
		_update_text(player.level, player.current_xp, player.xp_required)
		player.xp_changed.connect(_on_xp_changed)
		player.level_changed.connect(_on_level_changed)


func _on_xp_changed(current_xp: int, xp_required: int, level: int) -> void:
	max_value = xp_required
	value = current_xp
	_update_text(level, current_xp, xp_required)


func _on_level_changed(level: int, current_xp: int, xp_required: int) -> void:
	max_value = xp_required
	value = current_xp
	_update_text(level, current_xp, xp_required)


func _update_text(level: int, current_xp: int, xp_required: int) -> void:
	if label:
		label.text = "LVL %d  %d / %d XP" % [level, current_xp, xp_required]
