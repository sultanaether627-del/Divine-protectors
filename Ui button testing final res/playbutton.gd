extends TextureButton

func _on_pressed() -> void:
	_play_button_click()
	# Go to difficulty select first; that screen will load world.tscn after a choice is made.
	get_tree().change_scene_to_file("res://tscn/difficulty_select.tscn")


func _play_button_click() -> void:
	var sfx_manager = get_node_or_null("/root/SFXManager")
	if sfx_manager and sfx_manager.has_method("play_button_click"):
		sfx_manager.play_button_click()
