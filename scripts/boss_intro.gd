extends CanvasLayer

@onready var title: Label = $Panel/Title
@onready var subtitle: Label = $Panel/Subtitle
@onready var panel: PanelContainer = $Panel


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.86, 0.86)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(1.15)
	tween.chain().tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)

	var shaker: Node = get_tree().get_first_node_in_group("screen_shake")
	if shaker and shaker.has_method("shake"):
		shaker.shake(7.0, 0.22)
