extends ProgressBar

@onready var health_text: Label = $HealthText

var player: Node = null
var current_form_name := "Water"


func _ready() -> void:
	show_percentage = false
	min_value = 0

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if player:
		max_value = int(player.form_stats[player.active_form_key]["max_health"])
		value = int(player.form_stats[player.active_form_key]["health"])
		_update_text(value, max_value)

		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_player_health_changed)
		if player.has_signal("form_changed"):
			player.form_changed.connect(_on_form_changed)


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	max_value = max_health
	value = current_health
	_update_text(current_health, max_health)


func _on_form_changed(form_name: String) -> void:
	current_form_name = form_name
	_update_text(int(value), int(max_value))


func _update_text(current_health: int, max_health: int) -> void:
	health_text.text = "%s HP: %d / %d" % [current_form_name, current_health, max_health]
