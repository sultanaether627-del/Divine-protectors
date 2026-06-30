extends Control

# ── Difficulty Select Screen ───────────────────────────────────────────────────
# Shown after the main menu Play button is pressed.
# Player picks a difficulty then the game loads world.tscn.

# Button colours matching each difficulty theme.
const BUTTON_COLORS: Dictionary = {
	"Easy":   Color(0.3,  0.85, 0.4,  1.0),
	"Normal": Color(0.35, 0.65, 1.0,  1.0),
	"Hard":   Color(1.0,  0.55, 0.2,  1.0),
	"Divine": Color(0.85, 0.2,  0.9,  1.0)
}

const DIFFICULTY_DESCS: Dictionary = {
	"Easy":   "Reduced enemy stats. Great for learning the game.",
	"Normal": "The original experience. Balanced challenge.",
	"Hard":   "Stronger enemies, faster spawns. For veterans.",
	"Divine": "Maximum chaos. Only the worthy survive."
}


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Full-screen dark background
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.10, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Outer VBox centred on screen
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_CENTER)
	outer.custom_minimum_size = Vector2(560, 520)
	outer.offset_left   = -280
	outer.offset_top    = -260
	outer.offset_right  = 280
	outer.offset_bottom = 260
	outer.add_theme_constant_override("separation", 18)
	add_child(outer)

	# Title
	var title := Label.new()
	title.text = "SELECT DIFFICULTY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
	outer.add_child(title)

	var sub := Label.new()
	sub.text = "Choose how challenging your run will be."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	outer.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	outer.add_child(spacer)

	# One button per difficulty
	for diff_name in ["Easy", "Normal", "Hard", "Divine"]:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		outer.add_child(row)

		var btn := Button.new()
		btn.text = diff_name
		btn.custom_minimum_size = Vector2(560, 64)
		btn.add_theme_font_size_override("font_size", 22)
		# Tint label colour to difficulty colour
		btn.add_theme_color_override("font_color", BUTTON_COLORS[diff_name])
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		# Connect with the difficulty name bound as argument
		btn.pressed.connect(_on_difficulty_selected.bind(diff_name))
		row.add_child(btn)

		var desc := Label.new()
		desc.text = DIFFICULTY_DESCS[diff_name]
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		row.add_child(desc)

	# Back button at the bottom
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	outer.add_child(spacer2)

	var back_btn := Button.new()
	back_btn.text = "< Back"
	back_btn.custom_minimum_size = Vector2(160, 44)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_on_back_pressed)
	# Centre the back button by wrapping it in an HBoxContainer
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(back_btn)
	outer.add_child(hbox)


func _on_difficulty_selected(difficulty_name: String) -> void:
	# Store the choice in the DifficultyManager autoload.
	DifficultyManager.set_difficulty(difficulty_name)
	# Play button click SFX if available.
	var sfx := get_node_or_null("/root/SFXManager")
	if sfx and sfx.has_method("play_button_click"):
		sfx.play_button_click()
	# Transition straight to the game world.
	get_tree().change_scene_to_file("res://tscn/world.tscn")


func _on_back_pressed() -> void:
	var sfx := get_node_or_null("/root/SFXManager")
	if sfx and sfx.has_method("play_button_click"):
		sfx.play_button_click()
	get_tree().change_scene_to_file("res://Ui button testing final res/main menu UI.tscn")
