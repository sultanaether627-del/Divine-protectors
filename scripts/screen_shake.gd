extends CanvasLayer

var cameras: Array[Camera2D] = []
var shake_strength: float = 0.0
var shake_time: float = 0.0
var original_offsets: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("screen_shake")
	await get_tree().process_frame
	_find_cameras()


func _process(delta: float) -> void:
	if cameras.is_empty():
		_find_cameras()

	if shake_time <= 0.0:
		_restore_offsets()
		return

	shake_time -= delta
	var fade: float = clamp(shake_time / max(0.01, shake_time + delta), 0.0, 1.0)
	var amount: float = shake_strength * fade
	var random_offset: Vector2 = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))

	for cam in cameras:
		if cam != null and is_instance_valid(cam):
			if not original_offsets.has(cam):
				original_offsets[cam] = cam.offset
			cam.offset = original_offsets[cam] + random_offset

	if shake_time <= 0.0:
		_restore_offsets()


func shake(strength: float = 8.0, duration: float = 0.18) -> void:
	_find_cameras()
	if cameras.is_empty():
		return

	for cam in cameras:
		if cam != null and is_instance_valid(cam) and not original_offsets.has(cam):
			original_offsets[cam] = cam.offset

	shake_strength = max(shake_strength, strength)
	shake_time = max(shake_time, duration)


func _restore_offsets() -> void:
	for cam in original_offsets.keys():
		if cam != null and is_instance_valid(cam):
			cam.offset = original_offsets[cam]
	original_offsets.clear()


func _find_cameras() -> void:
	cameras.clear()

	var viewport := get_viewport()
	if viewport:
		var active_cam: Camera2D = viewport.get_camera_2d()
		if active_cam != null:
			cameras.append(active_cam)

	for node in get_tree().get_nodes_in_group("player"):
		if node is Node:
			var cam: Camera2D = node.get_node_or_null("Camera2D") as Camera2D
			if cam != null and not cameras.has(cam):
				cameras.append(cam)

	for node in get_tree().get_nodes_in_group("camera"):
		if node is Camera2D and not cameras.has(node):
			cameras.append(node)
