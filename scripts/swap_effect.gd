extends Node2D

@export var element_color := Color(0.45, 0.8, 1.0, 1.0)
@export var lifetime := 0.32

@onready var ring: ColorRect = $Ring
@onready var flash: ColorRect = $Flash


func _ready() -> void:
	z_index = 80
	ring.modulate = element_color
	flash.modulate = Color(element_color.r, element_color.g, element_color.b, 0.45)

	scale = Vector2(0.25, 0.25)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), lifetime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", TAU, lifetime).set_trans(Tween.TRANS_SINE)
	tween.tween_property(ring, "modulate:a", 0.0, lifetime)
	tween.tween_property(flash, "modulate:a", 0.0, lifetime * 0.65)
	tween.chain().tween_callback(queue_free)
