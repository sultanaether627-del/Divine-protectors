extends CanvasLayer

@onready var slots_container: VBoxContainer = $Root/SlotsContainer

var player: Node = null
var slots: Array = []
var icon_textures := {
	"water": preload("res://sprites/icons/earth_icon.png"),
	"fire": preload("res://sprites/icons/water_icon.png"),
	"earth": preload("res://sprites/icons/fire_icon.png"),
	"wind": preload("res://sprites/icons/wind_icon.png")
}
var ult_ready_textures := {
	"water": preload("res://sprites/ult_ready/earth_ready.png"),
	"fire": preload("res://sprites/ult_ready/water_ready.png"),
	"earth": preload("res://sprites/ult_ready/fire_ready.png"),
	"wind": preload("res://sprites/ult_ready/wind_ready.png")
}
var key_labels := {
	"water": "1",
	"fire": "2",
	"earth": "3",
	"wind": "4"
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player")
	_collect_slots()
	_setup_slots()
	_update_all_slots()


func _process(_delta: float) -> void:
	_update_all_slots()


func _collect_slots() -> void:
	slots.clear()
	for child in slots_container.get_children():
		slots.append(child)


func _setup_slots() -> void:
	if player == null:
		return

	var order: Array = player.form_order

	for i in range(min(slots.size(), order.size())):
		var key: String = order[i]
		var display_name := key.capitalize()

		if player.form_stats.has(key):
			display_name = str(player.form_stats[key]["display"])

		var key_text: String = str(key_labels.get(key, str(i + 1)))
		var icon_texture: Texture2D = icon_textures[key]
		var ult_texture: Texture2D = ult_ready_textures[key]

		slots[i].setup(
			key,
			display_name,
			key_text,
			icon_texture,
			ult_texture
		)


func _update_all_slots() -> void:
	if player == null:
		return
	if not player.has_method("is_inside_tree"):
		return

	var order: Array = player.form_order

	for i in range(min(slots.size(), order.size())):
		var key: String = order[i]

		if not player.form_stats.has(key):
			continue

		var stats: Dictionary = player.form_stats[key]
		var current_hp: int = int(stats.get("health", 0))
		var max_hp: int = int(stats.get("max_health", 1))
		var revive_left: float = float(stats.get("revive_left", 0.0))
		var is_active: bool = key == player.active_form_key
		var ult_ready: bool = bool(stats.get("ult_ready", false))
		var ult_charge: float = float(stats.get("ult_charge", 0.0))
		var ult_charge_time: float = float(player.ult_charge_time)

		slots[i].update_slot(current_hp, max_hp, is_active, revive_left, ult_ready, ult_charge, ult_charge_time)
