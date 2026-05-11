extends ProgressBar

@onready var label: Label = $XPText

var player: Node


func _ready() -> void:
	show_percentage = false
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if player:
		max_value = player.xp_required
		value = player.current_xp
		_update_text(player.level)
		player.xp_changed.connect(_on_xp_changed)
		player.level_changed.connect(_on_level_changed)


func _on_xp_changed(current_xp: int, xp_required: int, level: int) -> void:
	max_value = xp_required
	value = current_xp
	_update_text(level)


func _on_level_changed(level: int, current_xp: int, xp_required: int) -> void:
	max_value = xp_required
	value = current_xp
	_update_text(level)


func _update_text(level: int) -> void:
	if label:
		label.text = "LVL %d" % level
