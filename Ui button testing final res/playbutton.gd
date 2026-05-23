extends Button

func _on_pressed() -> void:
	_play_button_click()
	get_tree().change_scene_to_file("res://tscn/world.tscn")


func _play_button_click() -> void:
	var sfx_manager = get_node_or_null("/root/SFXManager")
	if sfx_manager and sfx_manager.has_method("play_button_click"):
		sfx_manager.play_button_click()
