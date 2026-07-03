extends Control

@onready var label: Label = $XPText
@onready var level_label: Label = $LevelText

var player: Node = null
var elapsed_time := 0.0


func _ready() -> void:
	visible = false
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	elapsed_time += delta
