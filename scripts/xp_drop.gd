extends Area2D

@export var xp_amount := 1
@export var attract_distance := 180.0
@export var collect_distance := 18.0
@export var move_speed := 45.0
@export var max_move_speed := 650.0
@export var acceleration := 9.0

var player: Node2D
var current_speed := 0.0
var collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	current_speed = move_speed


func _physics_process(delta: float) -> void:
	if player == null or collected:
		return

	var distance := global_position.distance_to(player.global_position)

	if distance <= attract_distance:
		var direction := global_position.direction_to(player.global_position)
		current_speed = min(current_speed + acceleration * 100.0 * delta, max_move_speed)
		global_position += direction * current_speed * delta

	if distance <= collect_distance:
		collect()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect()


func collect() -> void:
	if collected:
		return
	collected = true
	if player:
		if player.has_method("collect_xp_orb"):
			player.collect_xp_orb(xp_amount)
		elif player.has_method("add_xp"):
			player.add_xp(xp_amount)
	queue_free()
