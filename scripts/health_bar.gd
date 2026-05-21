extends ProgressBar

@onready var health_text: Label = $HealthText
@onready var heart_icon: TextureRect = $HeartIcon

var player: Node = null
var current_form_name := "Water"

const COLOR_HEALTHY := Color(0.2, 0.8, 0.2, 1.0)
const COLOR_WARNING := Color(0.9, 0.8, 0.1, 1.0)
const COLOR_DANGER := Color(0.9, 0.15, 0.15, 1.0)


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
	_update_color(current_health, max_health)


func _on_form_changed(form_name: String) -> void:
	current_form_name = form_name
	_update_text(int(value), int(max_value))


func _update_text(current_health: int, max_health: int) -> void:
	health_text.text = "%s  %d / %d" % [current_form_name, current_health, max_health]


func _update_color(current_health: int, max_health: int) -> void:
	var ratio: float = float(current_health) / max(1.0, float(max_health))
	var bar_style := get_theme_stylebox("fill", "ProgressBar")
	if bar_style:
		var color: Color
		if ratio > 0.5:
			color = COLOR_HEALTHY
		elif ratio > 0.25:
			color = COLOR_WARNING
		else:
			color = COLOR_DANGER
		bar_style.bg_color = color
		
		if heart_icon:
			if ratio <= 0.25:
				heart_icon.modulate = COLOR_DANGER
			elif ratio <= 0.5:
				heart_icon.modulate = COLOR_WARNING
			else:
				heart_icon.modulate = COLOR_HEALTHY
