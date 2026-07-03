extends Area2D

@export var xp_amount := 1
@export var attract_distance := 180.0
@export var collect_distance := 18.0

@export var move_speed := 45.0
@export var max_move_speed := 650.0
@export var acceleration := 9.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D
var current_speed := 0.0
var collected := false
var burst_velocity: Vector2 = Vector2.ZERO
var burst_damping: float = 8.0


func _ready() -> void:
	add_to_group("xp_drop")
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	body_entered.connect(_on_body_entered)

	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player")

	current_speed = move_speed

	# XP animation
	if sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
		elif sprite.sprite_frames.has_animation("default"):
			sprite.play("default")


func _physics_process(delta: float) -> void:
	if player == null or collected:
		return

	var effective_attract := attract_distance
	if player.has_method("get") and player.get("pickup_range") != null:
		effective_attract = float(player.pickup_range)

	var distance := global_position.distance_to(player.global_position)

	if distance <= effective_attract:
		var direction := global_position.direction_to(player.global_position)
		var t: float = 1.0 - clamp(distance / effective_attract, 0.0, 1.0)
		var speed: float = lerp(float(move_speed), float(max_move_speed), t * t)
		global_position += direction * speed * delta

	if distance <= collect_distance:
		collect()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect()


func collect() -> void:
	if collected:
		return

	collected = true
	
	if sprite:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tween.tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.15)
		await tween.finished

	if player:
		# Scale XP by the difficulty exp multiplier.
		var scaled_xp: int = maxi(1, int(round(float(xp_amount) * DifficultyManager.get_exp_multiplier())))
		if player.has_method("collect_xp_orb"):
			player.collect_xp_orb(scaled_xp)

		elif player.has_method("add_xp"):
			player.add_xp(scaled_xp)

	queue_free()



func set_initial_burst(velocity_value: Vector2) -> void:
	burst_velocity = velocity_value
