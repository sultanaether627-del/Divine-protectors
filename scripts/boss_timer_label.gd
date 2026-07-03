extends Label

var timer_node: Node = null


func _ready() -> void:
	await get_tree().process_frame
	timer_node = get_tree().get_first_node_in_group("boss_timer")
	if timer_node == null:
		text = "BOSS BATTLE"
		return
	if timer_node.has_signal("boss_timer_changed"):
		timer_node.boss_timer_changed.connect(_on_boss_timer_changed)
	if timer_node.has_signal("boss_choice_started"):
		timer_node.boss_choice_started.connect(_on_boss_choice_updated)
	if timer_node.has_signal("boss_choice_updated"):
		timer_node.boss_choice_updated.connect(_on_boss_choice_updated)
	if timer_node.has_signal("boss_battle_started"):
		timer_node.boss_battle_started.connect(_on_boss_battle_started)


func _on_boss_timer_changed(time_left: float) -> void:
	text = "Boss in %s" % _format_time(time_left)


func _on_boss_choice_updated(time_left: float, strength_level: int) -> void:
	text = "Press B: Fight Boss | Power +%d | Next +1 in %s" % [strength_level, _format_time(time_left)]


func _on_boss_battle_started() -> void:
	text = "BOSS BATTLE"


func _format_time(time_left: float) -> String:
	var total_seconds: int = int(ceil(time_left))
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
