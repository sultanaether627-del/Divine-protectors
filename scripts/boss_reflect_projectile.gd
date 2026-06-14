extends Area2D

const DEBUG_REFLECT := false

@export var speed: float = 450.0
@export var reflected_speed: float = 900.0
@export var homing_turn_speed: float = 4.5
@export var base_hp: float = 20.0
@export var damage_to_player: int = 120
@export var damage_to_boss: float = 180.0
@export var boss_stun_time: float = 3.0
@export var lifetime: float = 8.0
@export var radius: float = 34.0

var boss: Node2D = null
var target_player: Node2D = null
var direction: Vector2 = Vector2.DOWN
var hp: float = 20.0
var reflected: bool = false
var has_finished: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var core: ColorRect = $Visual/Core
@onready var aura: ColorRect = $Visual/Aura


func _ready() -> void:
	add_to_group("boss_reflect_projectile")
	monitoring = true
	monitorable = true
	collision_layer = 2
	collision_mask = 1
	hp = _difficulty_hp()
	_setup_shape()
	_update_visual()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	var tween: Tween = create_tween()
	tween.set_loops()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale", Vector2(1.18, 1.18), 0.35).from(Vector2(0.9, 0.9))
	tween.tween_property(aura, "modulate:a", 0.18, 0.35).from(0.42)

	await get_tree().create_timer(lifetime, false).timeout
	if not has_finished:
		_explode(false)


func setup(source_boss: Node2D, player_node: Node2D, hit_damage: int) -> void:
	boss = source_boss
	target_player = player_node
	damage_to_player = hit_damage
	if target_player:
		direction = global_position.direction_to(target_player.global_position).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.DOWN


func _physics_process(delta: float) -> void:
	if has_finished:
		return

	if reflected:
		if boss == null or not is_instance_valid(boss):
			_explode(false)
			return
		direction = global_position.direction_to(boss.global_position).normalized()
		global_position += direction * reflected_speed * delta
		if global_position.distance_to(boss.global_position) <= 70.0:
			_hit_boss()
	else:
		if target_player and is_instance_valid(target_player):
			var desired_dir: Vector2 = global_position.direction_to(target_player.global_position).normalized()
			direction = direction.slerp(desired_dir, clampf(homing_turn_speed * delta, 0.0, 1.0)).normalized()
		global_position += direction * speed * delta

		if target_player and is_instance_valid(target_player):
			if global_position.distance_to(target_player.global_position) <= radius + 18.0:
				_hit_player()


func take_damage(_amount: float) -> void:
	if has_finished or reflected:
		return

	# One-shot parry: any player bullet instantly reflects the projectile.
	_flash()
	_reflect()


func _reflect() -> void:
	reflected = true
	collision_layer = 2
	collision_mask = 3
	modulate = Color(0.4, 1.0, 1.0, 1.0)
	_update_visual()
	_screen_shake(6.0, 0.12)
	_spawn_text("PARRY!", Color(0.35, 1.0, 1.0, 1.0))


func _hit_player() -> void:
	if has_finished:
		return

	if target_player and target_player.has_method("take_damage"):
		target_player.take_damage(damage_to_player)
	_screen_shake(12.0, 0.22)
	_explode(true)


func _hit_boss() -> void:
	if has_finished:
		return

	if boss and is_instance_valid(boss):
		if boss.has_method("take_damage"):
			boss.take_damage(damage_to_boss)
		if boss.has_method("stun"):
			boss.stun(boss_stun_time)
	_screen_shake(14.0, 0.25)
	_spawn_text("COUNTER!", Color(0.35, 1.0, 1.0, 1.0))
	_explode(false)


func _explode(_dangerous: bool) -> void:
	if has_finished:
		return
	has_finished = true
	monitoring = false
	collision_shape.disabled = true

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale", Vector2(1.8, 1.8), 0.16)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)


func _on_body_entered(body: Node) -> void:
	if has_finished:
		return
	if reflected:
		if body and body.is_in_group("boss"):
			_hit_boss()
	else:
		if body and body.is_in_group("player"):
			target_player = body as Node2D
			_hit_player()


func _on_area_entered(area: Area2D) -> void:
	if has_finished:
		return
	if reflected and area and (area.is_in_group("boss_hurtbox") or area.is_in_group("boss")):
		_hit_boss()


func _setup_shape() -> void:
	if collision_shape == null:
		return
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape


func _update_visual() -> void:
	if reflected:
		core.color = Color(0.25, 1.0, 1.0, 0.95)
		aura.color = Color(0.25, 1.0, 1.0, 0.35)
	else:
		core.color = Color(1.0, 0.18, 0.12, 0.95)
		aura.color = Color(1.0, 0.2, 0.12, 0.35)


func _difficulty_hp() -> float:
	var difficulty_name: String = "Normal"
	if Engine.has_singleton("DifficultyManager"):
		pass
	if get_node_or_null("/root/DifficultyManager") != null:
		difficulty_name = str(get_node("/root/DifficultyManager").get_difficulty_name())

	match difficulty_name:
		"Easy":
			return 15.0
		"Hard":
			return 30.0
		"Divine":
			return 40.0
		_:
			return base_hp


func _flash() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(core, "color", Color(1.0, 1.0, 1.0, 1.0), 0.04)
	tween.tween_callback(_update_visual)


func _screen_shake(strength: float, duration: float) -> void:
	var shaker: Node = get_tree().get_first_node_in_group("screen_shake")
	if shaker and shaker.has_method("shake"):
		shaker.shake(strength, duration)


func _spawn_text(text_value: String, color_value: Color) -> void:
	var floating_scene: PackedScene = load("res://tscn/floating_text.tscn") as PackedScene
	if floating_scene == null:
		return
	var popup = floating_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = global_position + Vector2(0, -46)
	popup.text = text_value
	popup.color = color_value
