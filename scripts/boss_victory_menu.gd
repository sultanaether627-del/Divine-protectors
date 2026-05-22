extends CanvasLayer

@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $PanelContainer/VBoxContainer/SubTitleLabel
@onready var continue_button: Button = $PanelContainer/VBoxContainer/ContinueButton
@onready var end_season_button: Button = $PanelContainer/VBoxContainer/EndSeasonButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	end_season_button.pressed.connect(_on_end_season_pressed)


func show_victory_menu() -> void:
	title_label.text = "BOSS DEFEATED"
	subtitle_label.text = "Continue the fight on the map, or end the season."
	visible = true
	get_tree().paused = true


func _on_continue_pressed() -> void:
	visible = false
	get_tree().paused = false
	var err: int = get_tree().change_scene_to_file("res://tscn/world.tscn")
	if err != OK:
		push_error("BossVictoryMenu: Could not return to res://tscn/world.tscn")


func _on_end_season_pressed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://tscn/ending_screen.tscn")
