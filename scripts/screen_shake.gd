extends CanvasLayer

var camera: Camera2D = null
var shake_strength: float = 0.0
var shake_time: float = 0.0
var original_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("screen_shake")
	await get_tree().process_frame
	_find_camera()


func _process(delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		_find_camera()
		return

	if shake_time <= 0.0:
		camera.offset = original_offset
		return

	shake_time -= delta
	var amount: float = shake_strength * (shake_time / max(0.01, shake_time + delta))
	camera.offset = original_offset + Vector2(randf_range(-amount, amount), randf_range(-amount, amount))

	if shake_time <= 0.0:
		camera.offset = original_offset


func shake(strength: float = 8.0, duration: float = 0.18) -> void:
	_find_camera()
	if camera == null:
		return

	original_offset = camera.offset
	shake_strength = max(shake_strength, strength)
	shake_time = max(shake_time, duration)


func _find_camera() -> void:
	var viewport := get_viewport()
	if viewport:
		camera = viewport.get_camera_2d()
