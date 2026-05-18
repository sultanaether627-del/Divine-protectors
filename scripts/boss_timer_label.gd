extends Label

var timer_node: Node = null


func _ready() -> void:
	await get_tree().process_frame
	timer_node = get_tree().get_first_node_in_group("boss_timer")
	if timer_node and timer_node.has_signal("boss_timer_changed"):
		timer_node.boss_timer_changed.connect(_on_boss_timer_changed)
	if timer_node and timer_node.has_signal("boss_battle_started"):
		timer_node.boss_battle_started.connect(_on_boss_battle_started)


func _on_boss_timer_changed(time_left: float) -> void:
	var total_seconds: int = int(ceil(time_left))
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	text = "Boss in %02d:%02d" % [minutes, seconds]


func _on_boss_battle_started() -> void:
	text = "BOSS BATTLE"
