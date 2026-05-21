extends PanelContainer

@onready var icon_rect: TextureRect = $HBoxContainer/Icon
@onready var info_box: VBoxContainer = $HBoxContainer/InfoBox
@onready var name_label: Label = $HBoxContainer/InfoBox/NameLabel
@onready var hp_bar: ProgressBar = $HBoxContainer/InfoBox/HPBar
@onready var cooldown_label: Label = $HBoxContainer/InfoBox/CooldownLabel
@onready var key_label: Label = $KeyLabel
@onready var active_marker: ColorRect = $ActiveMarker
@onready var dead_overlay: ColorRect = $DeadOverlay
@onready var ult_ready_icon: TextureRect = $UltReadyIcon

var form_key := "water"
var normal_icon_texture: Texture2D
var ult_icon_texture: Texture2D


func setup(slot_form_key: String, display_name: String, key_text: String, icon_texture: Texture2D, ult_texture: Texture2D) -> void:
	form_key = slot_form_key
	normal_icon_texture = icon_texture
	ult_icon_texture = ult_texture
	name_label.text = display_name
	key_label.text = key_text
	icon_rect.texture = normal_icon_texture
	ult_ready_icon.visible = false


func update_slot(current_hp: int, max_hp: int, is_active: bool, revive_left: float, ult_ready: bool, ult_charge: float, ult_charge_time: float) -> void:
	hp_bar.max_value = max(1, max_hp)
	hp_bar.value = clamp(current_hp, 0, max_hp)
	active_marker.visible = is_active

	var is_dead: bool = revive_left > 0.0
	dead_overlay.visible = is_dead
	cooldown_label.visible = is_dead

	# Instead of showing a small separate ult icon, replace the character icon
	# with the ult-ready version when that character's ult is available.
	ult_ready_icon.visible = false
	if ult_ready and not is_dead and ult_icon_texture:
		icon_rect.texture = ult_icon_texture
	else:
		icon_rect.texture = normal_icon_texture

	if is_dead:
		cooldown_label.text = "%ds" % int(ceil(revive_left))
		modulate = Color(0.55, 0.55, 0.55, 1.0)
	elif is_active:
		if ult_ready:
			cooldown_label.text = "ULT READY"
			cooldown_label.modulate = Color(1, 0.85, 0.2, 1)
			_pulse_ult_ready()
		else:
			var percent: int = int(clamp((ult_charge / max(1.0, ult_charge_time)) * 100.0, 0.0, 100.0))
			cooldown_label.text = "ULT %d%%" % percent
			cooldown_label.modulate = Color(1, 1, 1, 1)
		cooldown_label.visible = true
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		cooldown_label.text = ""
		modulate = Color(0.82, 0.82, 0.82, 1.0)


func _pulse_ult_ready() -> void:
	if not has_node("UltReadyIcon"):
		return
	var icon: TextureRect = $UltReadyIcon
	if icon and not icon.visible:
		icon.visible = true
		icon.modulate.a = 0.6
		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(icon, "modulate:a", 1.0, 0.4)
		tween.tween_property(icon, "modulate:a", 0.6, 0.4)
