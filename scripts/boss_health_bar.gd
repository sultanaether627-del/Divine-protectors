extends ProgressBar

var boss: Node = null


func _ready() -> void:
	show_percentage = false
	min_value = 0
	visible = false
	await get_tree().process_frame
	_find_boss()


func _process(_delta: float) -> void:
	if boss == null or not is_instance_valid(boss):
		_find_boss()


func _find_boss() -> void:
	boss = get_tree().get_first_node_in_group("boss")
	if boss == null:
		visible = false
		return

	visible = true
	if boss.has_signal("health_changed") and not boss.health_changed.is_connected(_on_boss_health_changed):
		boss.health_changed.connect(_on_boss_health_changed)

	var max_hp: float = float(boss.get("max_health"))
	var hp: float = float(boss.get("health"))
	max_value = max_hp
	value = hp


func _on_boss_health_changed(current_health: float, max_health: float) -> void:
	visible = true
	max_value = max_health
	value = current_health
