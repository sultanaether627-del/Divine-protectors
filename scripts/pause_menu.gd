extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var resume_button: Button = $PanelContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $PanelContainer/VBoxContainer/RestartButton
@onready var menu_button: Button = $PanelContainer/VBoxContainer/MenuButton

var is_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	resume_button.pressed.connect(_on_resume)
	restart_button.pressed.connect(_on_restart)
	menu_button.pressed.connect(_on_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if is_paused:
				_resume_game()
			else:
				_pause_game()


func _pause_game() -> void:
	is_paused = true
	visible = true
	get_tree().paused = true


func _resume_game() -> void:
	is_paused = false
	visible = false
	get_tree().paused = false


func _on_resume() -> void:
	_resume_game()


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Ui button testing final res/main menu UI.tscn")
