extends Node2D

@export var fade_time := 0.25
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	z_index = 120
	z_as_relative = false
	if sprite:
		sprite.z_index = 120
		sprite.z_as_relative = false
		sprite.modulate.a = 0.7

	var tween := create_tween()
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)
