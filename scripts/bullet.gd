extends Area2D

const DEBUG_COMBAT := false

@export var speed := 700.0
@export var damage := 10.0
@export var lifetime := 1.5

# Keep this as 1 if your walls are on collision layer 1
@export_flags_2d_physics var wall_collision_mask := 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction := Vector2.ZERO
@export var bullet_element := "water"
var speed_mult := 1.0
var size_mult := 1.0

var bullet_sheets := {
	"water": {"path": "res://sprites/water bullets anim.png", "frames": 2},
	"fire": {"path": "res://sprites/fire_bullet.png", "frames": 2},
	"earth": {"path": "res://sprites/earth bullet anim.png", "frames": 2},
	"wind": {"path": "res://sprites/wind bullet anim.png", "frames": 2}
}


func _ready() -> void:
	set_collision_mask_value(1, true) # walls
	set_collision_mask_value(2, true) # enemies/bosses

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	_setup_bullet_animation()
	
	if size_mult != 1.0 and sprite:
		sprite.scale = Vector2(size_mult, size_mult)

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		rotation = direction.angle()

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return

	var move_vector := direction.normalized() * speed * speed_mult * delta
	var from := global_position
	var to := global_position + move_vector

	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = wall_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [get_rid()]

	var result := get_world_2d().direct_space_state.intersect_ray(query)

	if result:
		queue_free()
		return

	global_position = to


func _setup_bullet_animation() -> void:
	if not bullet_sheets.has(bullet_element):
		bullet_element = "water"

	var data: Dictionary = bullet_sheets[bullet_element]
	var texture: Texture2D = load(data["path"])

	if texture == null:
		if DEBUG_COMBAT:
			print("Missing bullet sprite sheet: ", data["path"])
		return

	var frames := SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_loop("fly", true)
	frames.set_animation_speed("fly", 12.0)

	var frame_count := int(data["frames"])
	var frame_width := int(texture.get_width() / frame_count)
	var frame_height := int(texture.get_height())

	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("fly", atlas)

	sprite.sprite_frames = frames
	sprite.play("fly")


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("walls"):
		queue_free()
		return

	if body.is_in_group("enemy") or body.is_in_group("boss"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			if DEBUG_COMBAT:
				print("Bullet hit ", body.name, " for ", damage, " damage")
		queue_free()
