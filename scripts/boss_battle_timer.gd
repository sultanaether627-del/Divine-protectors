extends Node2D

signal boss_timer_changed(time_left: float)
signal boss_battle_started

@export var boss_unlock_time: float = 900.0
@export var boss_arena_scene: PackedScene = preload("res://tscn/boss_arena.tscn")

var elapsed_time: float = 0.0
var boss_started: bool = false


func _ready() -> void:
	add_to_group("boss_timer")
	get_tree().set_meta("boss_strength_level", 0)
	boss_timer_changed.emit(boss_unlock_time)


func _process(delta: float) -> void:
	if boss_started or get_tree().paused:
		return

	elapsed_time += delta
	var time_left := maxf(0.0, boss_unlock_time - elapsed_time)
	boss_timer_changed.emit(time_left)

	if time_left <= 0.0:
		_start_boss_battle()


func _start_boss_battle() -> void:
	if boss_started:
		return

	boss_started = true
	boss_battle_started.emit()
	get_tree().paused = false

	if boss_arena_scene == null:
		push_error("BossBattleTimer: boss_arena_scene is missing.")
		return

	var err := get_tree().change_scene_to_packed(boss_arena_scene)
	if err != OK:
		push_error("BossBattleTimer: Failed to change to boss arena scene.")
