extends Node

## SFX Manager - Full Sound Effects System
## Handles all game sound effects with volume control, pitch variation, and sound pooling

signal sfx_volume_changed(new_volume_db: float)

# Combat SFX
const HIT_SOUNDS = [
	"res://audio/sfx/combat/hit_1.wav",
	"res://audio/sfx/combat/hit_2.wav",
	"res://audio/sfx/combat/hit_3.wav",
	"res://audio/sfx/combat/impactGeneric_light_000.ogg",
	"res://audio/sfx/combat/impactGeneric_light_001.ogg",
	"res://audio/sfx/combat/impactPunch_medium_000.ogg"
]

const EXPLOSION_SOUNDS = [
	"res://audio/sfx/combat/explosion_1.wav",
	"res://audio/sfx/combat/explosion_2.wav",
	"res://audio/sfx/combat/impactPunch_heavy_000.ogg",
	"res://audio/sfx/combat/impactPunch_heavy_001.ogg"
]

const ENEMY_DEATH_SOUNDS = [
	"res://audio/sfx/enemies/enemy_death_1.wav",
	"res://audio/sfx/enemies/enemy_death_2.wav",
	"res://audio/sfx/enemies/freesound_community-dying-monster-101276.mp3"
]

const PLAYER_HIT = "res://audio/sfx/combat/player_hit.wav"

# UI SFX
const BUTTON_CLICK = "res://audio/sfx/ui/button_click.wav"
const BUTTON_HOVER = "res://audio/sfx/ui/button_hover.wav"
const MENU_NAVIGATE = "res://audio/sfx/ui/menu_navigate.wav"
const FORM_SWITCH = "res://audio/sfx/ui/form_switch.wav"
const LEVEL_UP_SOUNDS = [
	"res://audio/sfx/ui/level_up.wav",
	"res://audio/sfx/player/upshort.wav",
	"res://audio/sfx/player/upmid.wav",
	"res://audio/sfx/player/uplong.wav"
]
const ULT_READY = "res://audio/sfx/ui/ult_ready.wav"

# Player SFX
const TRANSFORM_SOUNDS = {
	"water": "res://audio/sfx/player/transform_water.wav",
	"fire": "res://audio/sfx/player/transform_fire.wav",
	"earth": "res://audio/sfx/player/transform_earth.wav", 
	"wind": "res://audio/sfx/player/transform_wind.wav"
}

const SHOOT_SOUNDS = {
	"wind": "res://audio/sfx/player/wind_bullet_shoot.mp3",
	"earth": "res://audio/sfx/player/earth_bullet_shoot.mp3",
	"fire": "res://audio/sfx/player/fire_bullet_shoot.mp3",
	"water": "res://audio/sfx/player/water_bullet_shoot.mp3"
}

const FOOTSTEP_SOUNDS = [
	"res://audio/sfx/player/footstep_concrete_000.ogg",
	"res://audio/sfx/player/footstep_concrete_001.ogg",
	"res://audio/sfx/player/footstep_concrete_002.ogg"
]

const HEALTH_PICKUP = "res://audio/sfx/player/health_pickup.wav"
const XP_PICKUP = "res://audio/sfx/player/freesound_community-effect_notify-84408.mp3"

# Enemy/Boss SFX
const ENEMY_SPAWN = "res://audio/sfx/enemies/enemy_spawn.wav"
const BOSS_ATTACK = "res://audio/sfx/enemies/boss_attack.wav"
const BOSS_HIT = "res://audio/sfx/enemies/boss_hit.wav"
const BOSS_DEATH = [
	"res://audio/sfx/enemies/boss_death.wav",
	"res://audio/sfx/enemies/dragon-studio-monster-growl-376892.mp3"
]

@export var sfx_volume_db: float = -6.0
@export var pitch_variation: float = 0.1  # 10% pitch variation for variety
@export var max_sounds: int = 16  # Maximum concurrent sounds

var sound_pool: Array[AudioStreamPlayer] = []
var current_sound_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialize_sound_pool()

func _initialize_sound_pool() -> void:
	for i in range(max_sounds):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_" + str(i)
		player.bus = "Master"
		player.volume_db = sfx_volume_db
		add_child(player)
		sound_pool.append(player)

func play(sound_path: String, volume_override: float = 0.0, pitch_override: float = 0.0) -> void:
	if sound_path.is_empty():
		return
	
	var stream = load(sound_path)
	if stream == null:
		return  # Skip silently if file not found
	
	var player = sound_pool[current_sound_index]
	current_sound_index = (current_sound_index + 1) % max_sounds
	
	player.stream = stream
	player.volume_db = sfx_volume_db if volume_override == 0.0 else volume_override
	
	# Apply pitch variation for variety
	if pitch_override != 0.0:
		player.pitch_scale = pitch_override
	elif pitch_variation > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	else:
		player.pitch_scale = 1.0
	
	player.play()

func play_random(sound_array: Array, volume_override: float = 0.0, pitch_override: float = 0.0) -> void:
	if sound_array.is_empty():
		return
	
	var random_index = randi() % sound_array.size()
	play(sound_array[random_index], volume_override, pitch_override)

## Combat SFX functions
func play_hit() -> void:
	play_random(HIT_SOUNDS)

func play_explosion() -> void:
	play_random(EXPLOSION_SOUNDS, -3.0)  # Slightly quieter

func play_enemy_death() -> void:
	play_random(ENEMY_DEATH_SOUNDS)

func play_player_hit() -> void:
	play(PLAYER_HIT, -3.0)

## UI SFX functions
func play_button_click() -> void:
	play(BUTTON_CLICK, -12.0)  # UI sounds quieter

func play_button_hover() -> void:
	play(BUTTON_HOVER, -18.0)  # Hover sounds even quieter

func play_menu_navigate() -> void:
	play(MENU_NAVIGATE, -12.0)

func play_form_switch() -> void:
	play(FORM_SWITCH, -6.0)

func play_level_up() -> void:
	play_random(LEVEL_UP_SOUNDS, -3.0)  # Random level up sound

func play_ult_ready() -> void:
	play(ULT_READY, -3.0)

## Player SFX functions
func play_transform(form: String) -> void:
	if TRANSFORM_SOUNDS.has(form):
		play(TRANSFORM_SOUNDS[form])

func play_shoot(element: String) -> void:
	if SHOOT_SOUNDS.has(element):
		play(SHOOT_SOUNDS[element])

func play_footstep() -> void:
	play_random(FOOTSTEP_SOUNDS, -24.0)  # Quiet footsteps

func play_health_pickup() -> void:
	play(HEALTH_PICKUP, -6.0)

func play_xp_pickup() -> void:
	play(XP_PICKUP, -12.0)

## Enemy/Boss SFX functions
func play_enemy_spawn() -> void:
	play(ENEMY_SPAWN, -6.0)

func play_boss_attack() -> void:
	play(BOSS_ATTACK, -3.0)

func play_boss_hit() -> void:
	play(BOSS_HIT, -6.0)

func play_boss_death() -> void:
	play_random(BOSS_DEATH, 0.0)  # Full volume for dramatic effect

## Volume control
func set_sfx_volume(new_volume_db: float) -> void:
	sfx_volume_db = new_volume_db
	for player in sound_pool:
		player.volume_db = sfx_volume_db
	sfx_volume_changed.emit(sfx_volume_db)

func get_sfx_volume() -> float:
	return sfx_volume_db
