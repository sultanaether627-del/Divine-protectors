extends Node2D

const DEBUG_BOSS := false
const CHALLENGE_KEY := KEY_B

signal boss_timer_changed(time_left: float)
signal boss_choice_started(time_left: float, strength_level: int)
signal boss_choice_updated(time_left: float, strength_level: int)
signal boss_strengthened(strength_level: int)
signal boss_battle_started

@export var boss_unlock_time: float = 1.0
@export var boss_strengthen_interval: float = 45.0
@export var boss_arena_scene: PackedScene = preload("res://tscn/boss_arena.tscn")

var elapsed_time: float = 0.0
var boss_started: bool = false
var choice_active: bool = false
var choice_time_left: float = 0.0
var boss_strength_level: int = 0


func _ready() -> void:
	add_to_group("boss_timer")
	get_tree().set_meta("boss_strength_level", 0)
	boss_timer_changed.emit(boss_unlock_time)
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	if boss_started:
		return
	if get_tree().paused:
		return

	if not choice_active:
		elapsed_time += delta
		var time_left: float = maxf(0.0, boss_unlock_time - elapsed_time)
		boss_timer_changed.emit(time_left)
		if elapsed_time >= boss_unlock_time:
			_unlock_boss_choice()
		return

	choice_time_left = maxf(0.0, choice_time_left - delta)
	boss_choice_updated.emit(choice_time_left, boss_strength_level)
	if choice_time_left <= 0.0:
		_strengthen_boss()


func _unhandled_input(event: InputEvent) -> void:
	if boss_started or not choice_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == CHALLENGE_KEY:
			_start_boss_battle()


func _unlock_boss_choice() -> void:
	if choice_active:
		return
	choice_active = true
	choice_time_left = boss_strengthen_interval
	boss_choice_started.emit(choice_time_left, boss_strength_level)
	boss_choice_updated.emit(choice_time_left, boss_strength_level)
	if DEBUG_BOSS:
		print("Boss challenge unlocked. Press B to fight or wait for the boss to strengthen.")


func _strengthen_boss() -> void:
	boss_strength_level += 1
	choice_time_left = boss_strengthen_interval
	boss_strengthened.emit(boss_strength_level)
	boss_choice_updated.emit(choice_time_left, boss_strength_level)
	if DEBUG_BOSS:
		print("Boss strength increased to level ", boss_strength_level)


func _start_boss_battle() -> void:
	if boss_started:
		return

	boss_started = true
	choice_active = false
	get_tree().set_meta("boss_strength_level", boss_strength_level)
	boss_battle_started.emit()
	get_tree().paused = false

	if boss_arena_scene == null:
		push_error("BossBattleTimer: boss_arena_scene is missing.")
		return

	var change_error: int = get_tree().change_scene_to_packed(boss_arena_scene)
	if change_error != OK:
		push_error("BossBattleTimer: Failed to change to boss arena scene.")

	if DEBUG_BOSS:
		print("Changed to separate boss arena scene with boss strength level ", boss_strength_level)
