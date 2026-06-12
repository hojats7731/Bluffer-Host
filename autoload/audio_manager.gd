extends Node

const MUSIC_PATH := "res://assets/audio/background.ogg"
const REVEAL_PATH := "res://assets/audio/reveal_sting.ogg"
const JOIN_PATH := "res://assets/audio/join_chime.ogg"

var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	_music.volume_db = -10.0
	add_child(_music)

	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "Master"
	_sfx.volume_db = -4.0
	add_child(_sfx)

	if ResourceLoader.exists(MUSIC_PATH):
		_music.stream = load(MUSIC_PATH)
		_music.finished.connect(_loop_music)

func start_music() -> void:
	if _music.stream == null:
		return
	if not _music.playing:
		_music.play()

func stop_music() -> void:
	_music.stop()

func _loop_music() -> void:
	_music.play()

func play_reveal() -> void:
	_play_one_shot(REVEAL_PATH)

func play_join() -> void:
	_play_one_shot(JOIN_PATH)

func _play_one_shot(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	_sfx.stream = load(path)
	_sfx.play()
