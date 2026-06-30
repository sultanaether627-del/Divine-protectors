extends Node2D

@export var text := ""
@export var color := Color(1, 1, 1, 1)
@export var rise_distance := 44.0
@export var lifetime := 0.75

@onready var label: Label = $Label


func _ready() -> void:
	z_index = 120
	label.text = text
	label.modulate = color

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - rise_distance, lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "scale", Vector2(1.25, 1.25), lifetime * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(queue_free)
