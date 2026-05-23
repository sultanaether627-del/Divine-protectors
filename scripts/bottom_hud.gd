extends Control

@onready var slot_nodes: Array[PanelContainer] = [
	$Root/TopLeftElements/ElementsMargin/ElementsVBox/FormsRow/Slot1,
	$Root/TopLeftElements/ElementsMargin/ElementsVBox/FormsRow/Slot2,
	$Root/TopLeftElements/ElementsMargin/ElementsVBox/FormsRow/Slot3,
	$Root/TopLeftElements/ElementsMargin/ElementsVBox/FormsRow/Slot4
]

@onready var level_number: Label = $Root/LevelPanel/LevelVBox/LevelNumber
@onready var xp_bar: ProgressBar = $Root/LevelPanel/LevelVBox/XPBar
@onready var attributes_label: Label = $Root/LevelPanel/LevelVBox/AttributesLabel

@onready var portrait_glow: ColorRect = $Root/BottomBar/Content/PortraitPanel/PortraitGlow
@onready var portrait_icon: TextureRect = $Root/BottomBar/Content/PortraitPanel/PortraitIcon
@onready var name_label: Label = $Root/BottomBar/Content/InfoVBox/TopInfoRow/NameLabel
@onready var hp_text: Label = $Root/BottomBar/Content/InfoVBox/TopInfoRow/HPText
@onready var hp_bar: ProgressBar = $Root/BottomBar/Content/InfoVBox/HPBar
@onready var flavor_text: Label = $Root/BottomBar/Content/InfoVBox/FlavorText
@onready var ult_icon: TextureRect = $Root/BottomBar/Content/UltPanel/UltEffectRoot/UltIcon
@onready var aura_back: TextureRect = $Root/BottomBar/Content/UltPanel/UltEffectRoot/AuraBack
@onready var aura_front: TextureRect = $Root/BottomBar/Content/UltPanel/UltEffectRoot/AuraFront
@onready var ult_status: Label = $Root/BottomBar/Content/UltPanel/UltEffectRoot/UltStatus

var player: Node = null
var ult_fx_tween: Tween = null
var last_active_key: String = ""
var last_ready_state: bool = false

var icon_textures: Dictionary = {
	"water": preload("res://sprites/icons/earth_icon.png"),
	"fire": preload("res://sprites/icons/water_icon.png"),
	"earth": preload("res://sprites/icons/fire_icon.png"),
	"wind": preload("res://sprites/icons/wind_icon.png")
}

var form_colors: Dictionary = {
	"water": Color(0.35, 0.75, 1.0, 1.0),
	"fire": Color(1.0, 0.35, 0.15, 1.0),
	"earth": Color(0.82, 0.62, 0.18, 1.0),
	"wind": Color(0.55, 1.0, 0.65, 1.0)
}

var flavor_by_form: Dictionary = {
	"water": "Flow, recover, and control.",
	"fire": "Burn through the horde.",
	"earth": "Stand firm and crush.",
	"wind": "Dash through the horde."
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	_initialise_slots()
	_update_all(true)


func _process(_delta: float) -> void:
	_update_all(false)


func _initialise_slots() -> void:
	if player == null:
		return

	for i in range(min(slot_nodes.size(), player.form_order.size())):
		var key: String = str(player.form_order[i])
		var slot: PanelContainer = slot_nodes[i]
		var icon: TextureRect = slot.get_node("Icon") as TextureRect
		var ready_fx: TextureRect = slot.get_node("ReadyFX") as TextureRect
		icon.texture = icon_textures.get(key, null)
		ready_fx.texture = icon_textures.get(key, null)


func _update_all(force_refresh: bool) -> void:
	if player == null:
		return

	var active_key: String = str(player.active_form_key)
	if not player.form_stats.has(active_key):
		return

	var stats: Dictionary = player.form_stats[active_key]
	var hp: int = int(stats.get("health", 0))
	var max_hp: int = int(stats.get("max_health", 1))
	var ult_charge: float = float(stats.get("ult_charge", 0.0))
	var ult_ready: bool = bool(stats.get("ult_ready", false))
	var form_color: Color = form_colors.get(active_key, Color.WHITE)
	var active_icon: Texture2D = icon_textures.get(active_key, null)

	level_number.text = str(player.level)
	xp_bar.max_value = max(1, int(player.xp_required))
	xp_bar.value = int(player.current_xp)
	attributes_label.text = _attribute_text()

	portrait_icon.texture = active_icon
	name_label.text = str(stats.get("display", active_key.capitalize())).to_upper()
	flavor_text.text = str(flavor_by_form.get(active_key, ""))
	portrait_glow.color = Color(form_color.r, form_color.g, form_color.b, 0.16)

	hp_bar.max_value = max(1, max_hp)
	hp_bar.value = hp
	hp_text.text = "%d / %d" % [hp, max_hp]
	_update_hp_style(float(hp) / max(1.0, float(max_hp)), form_color)

	ult_icon.texture = active_icon
	aura_back.texture = active_icon
	aura_front.texture = active_icon

	if ult_ready:
		ult_status.text = "READY"
		ult_status.modulate = Color(1.0, 0.92, 0.3, 1.0)
	else:
		var percent: int = int(round((ult_charge / max(1.0, float(player.ult_charge_time))) * 100.0))
		ult_status.text = "%d%%" % clamp(percent, 0, 100)
		ult_status.modulate = Color(0.82, 0.87, 0.95, 0.92)
		ult_icon.modulate = Color(0.28, 0.28, 0.28, 0.96)

	_update_slots(active_key)

	if force_refresh or active_key != last_active_key or ult_ready != last_ready_state:
		if ult_ready:
			_start_ult_fx(form_color)
		else:
			_stop_ult_fx()
		last_active_key = active_key
		last_ready_state = ult_ready


func _attribute_text() -> String:
	var atk_bonus: int = int(round((float(player.bullet_damage) / 10.0 - 1.0) * 100.0))
	var speed_bonus: int = int(round((float(player.movement_speed) / 400.0 - 1.0) * 100.0))
	var haste_bonus: int = int(round((0.25 / max(0.01, float(player.shoot_cooldown)) - 1.0) * 100.0))
	return "ATK %+d%%  SPD %+d%%  HASTE %+d%%" % [atk_bonus, speed_bonus, haste_bonus]


func _update_slots(active_key: String) -> void:
	for i in range(min(slot_nodes.size(), player.form_order.size())):
		var key: String = str(player.form_order[i])
		var slot: PanelContainer = slot_nodes[i]
		var stats: Dictionary = player.form_stats.get(key, {})
		var dead: bool = bool(stats.get("dead", false))
		var revive_left: float = float(stats.get("revive_left", 0.0))
		var ult_ready: bool = bool(stats.get("ult_ready", false))
		var ult_charge: float = float(stats.get("ult_charge", 0.0))
		var form_color: Color = form_colors.get(key, Color.WHITE)

		var icon: TextureRect = slot.get_node("Icon") as TextureRect
		var ready_fx: TextureRect = slot.get_node("ReadyFX") as TextureRect
		var glow: ColorRect = slot.get_node("Glow") as ColorRect
		var dead_overlay: ColorRect = slot.get_node("DeadOverlay") as ColorRect
		var status_label: Label = slot.get_node("StatusLabel") as Label
		var slot_charge: ProgressBar = slot.get_node("ChargeBar") as ProgressBar

		icon.texture = icon_textures.get(key, null)
		ready_fx.texture = icon_textures.get(key, null)
		dead_overlay.visible = dead
		glow.visible = key == active_key
		glow.color = Color(form_color.r, form_color.g, form_color.b, 0.15)
		ready_fx.visible = ult_ready and not dead
		ready_fx.modulate = Color(form_color.r, form_color.g, form_color.b, 0.16 if key != active_key else 0.24)

		slot_charge.max_value = max(1.0, float(player.ult_charge_time))
		slot_charge.value = float(player.ult_charge_time) if ult_ready else clamp(ult_charge, 0.0, float(player.ult_charge_time))

		if dead:
			status_label.visible = true
			status_label.text = "%ds" % int(ceil(revive_left))
			status_label.modulate = Color(1, 1, 1, 0.95)
			icon.modulate = Color(0.42, 0.42, 0.42, 0.9)
			slot_charge.visible = false
		else:
			status_label.visible = false
			icon.modulate = Color(1, 1, 1, 1) if ult_ready else Color(0.88, 0.88, 0.92, 1.0)
			slot_charge.visible = true

		slot.modulate = Color(1, 1, 1, 1) if key == active_key else (Color(0.9, 0.9, 0.95, 1) if not dead else Color(0.75, 0.75, 0.75, 1))


func _update_hp_style(ratio: float, form_color: Color) -> void:
	var fill_style: StyleBoxFlat = hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style == null:
		return

	if ratio > 0.55:
		fill_style.bg_color = Color(form_color.r * 0.82 + 0.18, form_color.g * 0.82 + 0.18, form_color.b * 0.82 + 0.18, 1.0)
	elif ratio > 0.25:
		fill_style.bg_color = Color(0.96, 0.74, 0.2, 1.0)
	else:
		fill_style.bg_color = Color(0.96, 0.22, 0.22, 1.0)


func _start_ult_fx(form_color: Color) -> void:
	_stop_ult_fx()

	aura_back.visible = true
	aura_front.visible = true

	aura_back.modulate = Color(form_color.r, form_color.g, form_color.b, 0.20)
	aura_front.modulate = Color(1, 1, 1, 0.16)
	ult_icon.modulate = Color(1, 1, 1, 1)

	ult_fx_tween = create_tween()
	ult_fx_tween.set_loops()
	ult_fx_tween.set_parallel(true)

	ult_fx_tween.tween_property(aura_back, "scale", Vector2(1.35, 1.35), 0.55).from(Vector2(0.72, 0.72))
	ult_fx_tween.tween_property(aura_back, "rotation", TAU, 0.95).from(0.0)
	ult_fx_tween.tween_property(aura_back, "modulate:a", 0.03, 0.55).from(0.22)

	ult_fx_tween.tween_property(aura_front, "scale", Vector2(1.15, 1.15), 0.35).from(Vector2(0.82, 0.82))
	ult_fx_tween.tween_property(aura_front, "rotation", -TAU, 0.9).from(0.0)
	ult_fx_tween.tween_property(aura_front, "modulate:a", 0.02, 0.35).from(0.18)


func _stop_ult_fx() -> void:
	if ult_fx_tween != null:
		ult_fx_tween.kill()
		ult_fx_tween = null

	aura_back.visible = false
	aura_front.visible = false
	aura_back.scale = Vector2.ONE
	aura_front.scale = Vector2.ONE
	aura_back.rotation = 0.0
	aura_front.rotation = 0.0
	ult_icon.scale = Vector2.ONE
	ult_icon.modulate = Color(0.28, 0.28, 0.28, 0.96)
