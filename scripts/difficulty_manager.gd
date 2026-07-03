extends Node

# ── Difficulty Manager (Autoload) ─────────────────────────────────────────────
# Stores the four difficulty presets and the player's current selection.
# Access from any script via: DifficultyManager.get_enemy_hp_multiplier() etc.
# Normal (1.0 across the board) = original game behaviour, unchanged.

enum Difficulty { EASY, NORMAL, HARD, DIVINE }

# Each entry defines multipliers applied on top of all other scaling logic.
const PRESETS: Dictionary = {
	"Easy": {
		"enemy_hp":    0.7,
		"enemy_dmg":   0.7,
		"enemy_speed": 0.85,
		"spawn_wait":  1.35,
		"boss_hp":     0.75,
		"exp_gain":    1.2
	},
	"Normal": {
		"enemy_hp":    1.0,
		"enemy_dmg":   1.0,
		"enemy_speed": 1.0,
		"spawn_wait":  1.0,
		"boss_hp":     1.0,
		"exp_gain":    1.0
	},
	"Hard": {
		"enemy_hp":    1.5,
		"enemy_dmg":   1.4,
		"enemy_speed": 1.2,
		"spawn_wait":  0.75,
		"boss_hp":     1.8,
		"exp_gain":    1.15
	},
	"Divine": {
		"enemy_hp":    2.5,
		"enemy_dmg":   2.2,
		"enemy_speed": 1.45,
		"spawn_wait":  0.45,
		"boss_hp":     3.5,
		"exp_gain":    1.4
	}
}

# Currently active difficulty name. Defaults to Normal.
var current_difficulty: String = "Normal"


func set_difficulty(difficulty_name: String) -> void:
	if PRESETS.has(difficulty_name):
		current_difficulty = difficulty_name
	else:
		push_warning("DifficultyManager: Unknown difficulty '%s', falling back to Normal." % difficulty_name)
		current_difficulty = "Normal"


# Private helper — avoids conflict with Godot's built-in Object._get() virtual method.
func _preset_value(key: String) -> float:
	var preset: Dictionary = PRESETS.get(current_difficulty, PRESETS["Normal"])
	return float(preset.get(key, 1.0))


# ── Public getters ─────────────────────────────────────────────────────────────

func get_difficulty_name() -> String:
	return current_difficulty

func get_enemy_hp_multiplier() -> float:
	return _preset_value("enemy_hp")

func get_enemy_damage_multiplier() -> float:
	return _preset_value("enemy_dmg")

func get_enemy_speed_multiplier() -> float:
	return _preset_value("enemy_speed")

func get_spawn_wait_multiplier() -> float:
	return _preset_value("spawn_wait")

func get_boss_hp_multiplier() -> float:
	return _preset_value("boss_hp")

func get_exp_multiplier() -> float:
	return _preset_value("exp_gain")
