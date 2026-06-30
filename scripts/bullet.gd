extends Area2D

const DEBUG_COMBAT := false

@export var speed := 700.0
@export var damage := 10.0
@export var lifetime := 1.5

# Layer 1 is used by map walls and some old bodies.
# Layer 2 is enemy/boss hurtboxes.
@export_flags_2d_physics var hit_collision_mask := 3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction: Vector2 = Vector2.ZERO
@export var bullet_element := "water"
var speed_mult: float = 1.0
var size_mult: float = 1.0
var has_hit: bool = false

var bullet_sheets: Dictionary = {
	"water": {"path": "res://sprites/water bullets anim.png", "frames": 2},
	"fire": {"path": "res://sprites/fire_bullet.png", "frames": 2},
	"earth": {"path": "res://sprites/earth bullet anim.png", "frames": 2},
	"wind": {"path": "res://sprites/wind bullet anim.png", "frames": 2}
}


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_mask = hit_collision_mask
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	_setup_bullet_animation()
	
	if size_mult != 1.0 and sprite:
		sprite.scale = Vector2(size_mult, size_mult)

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		rotation = direction.angle()

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	if has_hit or direction == Vector2.ZERO:
		return

	var move_vector: Vector2 = direction.normalized() * speed * speed_mult * delta
	var from: Vector2 = global_position
	var to: Vector2 = global_position + move_vector

	# Raycast stops fast bullets from passing through the boss between frames.
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = hit_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.exclude = [get_rid()]

	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if result:
		var collider_node: Node = result.get("collider") as Node
		if _try_damage_target(collider_node):
			queue_free()
			return

		# Do not let bullets hit XP drops/orbs.
		if collider_node and (collider_node.is_in_group("xp_drop") or collider_node.name.to_lower().find("xp") != -1):
			global_position = to
			return

		# Do not let the bullet delete itself because it sees the player/own form.
		if collider_node and _is_player_related(collider_node):
			global_position = to
			return

		# Any other physics body on these layers is treated as wall/solid.
		queue_free()
		return

	global_position = to


func _setup_bullet_animation() -> void:
	if not bullet_sheets.has(bullet_element):
		bullet_element = "water"

	var data: Dictionary = bullet_sheets[bullet_element]
	var texture: Texture2D = load(str(data["path"])) as Texture2D

	if texture == null:
		if DEBUG_COMBAT:
			print("Missing bullet sprite sheet: ", data["path"])
		return

	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_loop("fly", true)
	frames.set_animation_speed("fly", 12.0)

	var frame_count: int = int(data["frames"])
	var frame_width: int = int(texture.get_width() / frame_count)
	var frame_height: int = int(texture.get_height())

	for i in range(frame_count):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("fly", atlas)

	sprite.sprite_frames = frames
	sprite.play("fly")


func _on_body_entered(body: Node) -> void:
	if has_hit:
		return
	if _try_damage_target(body):
		queue_free()
		return
	if body and body.is_in_group("walls"):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return
	if area and (area.is_in_group("xp_drop") or area.name.to_lower().find("xp") != -1):
		return
	if _try_damage_target(area):
		queue_free()


func _try_damage_target(node: Node) -> bool:
	var target: Node = _find_damage_target(node)
	if target == null:
		return false

	has_hit = true
	# Use elemental take_damage if available so weaknesses are applied.
	if target.has_method("take_damage_elemental"):
		target.take_damage_elemental(damage, bullet_element)
	else:
		target.take_damage(damage)
	if DEBUG_COMBAT:
		print("Bullet hit ", target.name, " (element:", bullet_element, ") for ", damage, " damage")
	return true


func _find_damage_target(node: Node) -> Node:
	var current: Node = node
	while current != null:
		if current.is_in_group("boss_reflect_projectile") and current.has_method("take_damage"):
			return current
		if (current.is_in_group("enemy") or current.is_in_group("boss")) and current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func _is_player_related(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if current.is_in_group("player"):
			return true
		current = current.get_parent()
	return false
