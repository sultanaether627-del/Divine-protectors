extends Node

const MENU_TRACK_PATHS: Array[String] = [
	"res://audio/music/gamelan_loop.mp3"
]

const WORLD_TRACK_PATHS: Array[String] = [
	"res://audio/music/thai_loop.mp3",
	"res://audio/music/sunda_loop.mp3",
	"res://audio/music/filipino_loop.mp3"
]

const BOSS_TRACK_PATHS: Array[String] = [
	"res://audio/music/cambodian_loop.mp3"
]

const END_TRACK_PATHS: Array[String] = [
	"res://audio/music/gamelan_loop.mp3"
]

@export var volume_db: float = -9.0

var player: AudioStreamPlayer
var current_music_group: String = ""
var check_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	player = AudioStreamPlayer.new()
	player.name = "MusicPlayer"
	player.bus = "Master"
	player.volume_db = volume_db
	add_child(player)
	call_deferred("_update_music_for_scene")


func _process(delta: float) -> void:
	check_timer += delta
	if check_timer >= 0.5:
		check_timer = 0.0
		_update_music_for_scene()

	if player and player.stream != null and not player.playing:
		player.play()


func _update_music_for_scene() -> void:
	var scene_path: String = ""
	if get_tree().current_scene != null:
		scene_path = get_tree().current_scene.scene_file_path

	var next_group: String = _get_music_group(scene_path)
	if next_group == current_music_group:
		return

	current_music_group = next_group
	var tracks: Array = _get_tracks_for_group(next_group)
	_play_random_track(tracks)


func _get_music_group(scene_path: String) -> String:
	if scene_path == "":
		return "menu"
	if scene_path.ends_with("boss_arena.tscn"):
		return "boss"
	if scene_path.ends_with("world.tscn"):
		return "world"
	if scene_path.ends_with("ending_screen.tscn"):
		return "end"
	if scene_path.find("main menu") != -1 or scene_path.find("playtestui") != -1 or scene_path.find("settings") != -1 or scene_path.find("shop") != -1:
		return "menu"
	return "world"


func _get_tracks_for_group(group_name: String) -> Array:
	var paths: Array[String] = MENU_TRACK_PATHS

	match group_name:
		"boss":
			paths = BOSS_TRACK_PATHS
		"world":
			paths = WORLD_TRACK_PATHS
		"end":
			paths = END_TRACK_PATHS
		_:
			paths = MENU_TRACK_PATHS

	var tracks: Array = []
	for path in paths:
		if ResourceLoader.exists(path):
			var stream: Resource = load(path)
			if stream:
				tracks.append(stream)
	return tracks


func _play_random_track(tracks: Array) -> void:
	if player == null:
		return
	if tracks.is_empty():
		player.stop()
		return

	var picked_index: int = randi() % tracks.size()
	var picked_stream: AudioStream = tracks[picked_index] as AudioStream
	if picked_stream == null:
		return

	player.stop()
	player.stream = picked_stream
	_set_looping(player.stream)
	player.volume_db = volume_db
	player.play()


func _set_looping(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		var mp3_stream: AudioStreamMP3 = stream as AudioStreamMP3
		mp3_stream.loop = true
