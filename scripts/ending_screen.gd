extends Control

@onready var menu_button: Button = $PanelContainer/VBoxContainer/MenuButton
@onready var quit_button: Button = $PanelContainer/VBoxContainer/QuitButton


func _ready() -> void:
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Ui button testing final res/main menu UI.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
