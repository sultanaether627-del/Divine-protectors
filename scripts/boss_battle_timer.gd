extends Node2D

signal boss_timer_changed(time_left: float)
signal boss_battle_started

@export var boss_unlock_time: float = 900.0
@export_file("*.tscn") var boss_arena_path: String = "res://tscn/boss_arena.tscn"

var elapsed_time: float = 0.0
var boss_started: bool = false


func _ready() -> void:
	add_to_group("boss_timer")
	get_tree().set_meta("boss_strength_level", 0)
	boss_timer_changed.emit(boss_unlock_time)


func _process(delta: float) -> void:
	if boss_started:
		return
	if get_tree().paused:
		return

	elapsed_time += delta
	var time_left: float = maxf(0.0, boss_unlock_time - elapsed_time)
	boss_timer_changed.emit(time_left)

	if time_left <= 0.0:
		boss_started = true
		boss_battle_started.emit()
		call_deferred("_start_boss_battle")


func _start_boss_battle() -> void:
	get_tree().paused = false

	if not ResourceLoader.exists(boss_arena_path):
		push_error("BossBattleTimer: boss arena path does not exist: " + boss_arena_path)
		boss_started = false
		return

	var err: int = get_tree().change_scene_to_file(boss_arena_path)
	if err != OK:
		push_error("BossBattleTimer: Failed to change to boss arena scene. Error: " + str(err))
		boss_started = false
