extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var stats_label: Label = $PanelContainer/VBoxContainer/StatsLabel
@onready var restart_button: Button = $PanelContainer/VBoxContainer/RestartButton
@onready var menu_button: Button = $PanelContainer/VBoxContainer/MenuButton

var player: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	restart_button.pressed.connect(_on_restart)
	menu_button.pressed.connect(_on_menu)


func show_game_over(level: int, survival_time: float, boss_defeated: bool) -> void:
	visible = true
	get_tree().paused = true
	
	if boss_defeated:
		title_label.text = "VICTORY!"
		title_label.modulate = Color(1, 0.85, 0.2, 1)
	else:
		title_label.text = "GAME OVER"
		title_label.modulate = Color(1, 0.2, 0.2, 1)
	
	var minutes: int = int(survival_time) / 60
	var seconds: int = int(survival_time) % 60
	stats_label.text = "Level: %d\nSurvived: %02d:%02d" % [level, minutes, seconds]


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Ui button testing final res/main menu UI.tscn")
