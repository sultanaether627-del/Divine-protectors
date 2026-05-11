extends Area2D

@export var speed := 700.0
@export var damage := 10.0
@export var lifetime := 1.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction := Vector2.ZERO
@export var bullet_element := "water"

var bullet_sheets := {
	"water": {"path": "res://sprites/water bullets anim.png", "frames": 2},
	# Placeholder until you draw fire bullets.
	"fire": {"path": "res://sprites/water bullets anim.png", "frames": 2},
	"earth": {"path": "res://sprites/earth bullet anim.png", "frames": 2},
	"wind": {"path": "res://sprites/wind bullet anim.png", "frames": 2}
}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_bullet_animation()

	if direction != Vector2.ZERO:
		rotation = direction.angle()

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _setup_bullet_animation() -> void:
	if not bullet_sheets.has(bullet_element):
		bullet_element = "water"

	var data: Dictionary = bullet_sheets[bullet_element]
	var texture: Texture2D = load(data["path"])
	if texture == null:
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
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
