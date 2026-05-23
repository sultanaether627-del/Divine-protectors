extends Label

var timer_node: Node = null


func _ready() -> void:
	await get_tree().process_frame
	timer_node = get_tree().get_first_node_in_group("boss_timer")

	if timer_node == null:
		text = ""
		visible = false
		return

	if timer_node.has_signal("boss_timer_changed"):
		timer_node.boss_timer_changed.connect(_on_boss_timer_changed)
	if timer_node.has_signal("boss_battle_started"):
		timer_node.boss_battle_started.connect(_on_boss_battle_started)


func _on_boss_timer_changed(time_left: float) -> void:
	visible = true
	text = "BOSS IN %s" % _format_time(time_left)


func _on_boss_battle_started() -> void:
	visible = false
	text = ""


func _format_time(time_left: float) -> String:
	var total_seconds := int(ceil(time_left))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
