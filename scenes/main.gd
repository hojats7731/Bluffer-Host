extends Control

@onready var _connect: Control = $ConnectScreen
@onready var _lobby: Control = $LobbyScreen
@onready var _game: Control = $GameScreen
@onready var _results: Control = $ResultsScreen

func _ready() -> void:
	GameState.screen_changed.connect(_on_screen_changed)
	GameState.room_closed.connect(_on_room_closed)
	_show_screen(GameState.Screen.CONNECT)

func _on_screen_changed(screen: int) -> void:
	_show_screen(screen)

func _on_room_closed(reason: String) -> void:
	push_warning("Room closed: %s" % reason)
	_show_screen(GameState.Screen.CONNECT)

func _show_screen(screen: int) -> void:
	_connect.visible = screen == GameState.Screen.CONNECT
	_lobby.visible = screen == GameState.Screen.LOBBY
	_game.visible = screen == GameState.Screen.GAME
	_results.visible = screen == GameState.Screen.RESULTS

	if screen in [GameState.Screen.LOBBY, GameState.Screen.GAME, GameState.Screen.RESULTS]:
		AudioManager.start_music()
	elif screen == GameState.Screen.CONNECT:
		AudioManager.stop_music()

	if screen == GameState.Screen.LOBBY:
		_lobby.call_deferred("refresh")
	elif screen == GameState.Screen.GAME:
		_game.call_deferred("refresh")
	elif screen == GameState.Screen.RESULTS:
		_results.call_deferred("refresh")
