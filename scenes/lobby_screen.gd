extends Control

@onready var _room_code: Label = %RoomCodeLabel
@onready var _join_hint: Label = %JoinHint
@onready var _player_list: VBoxContainer = %PlayerList
@onready var _start_btn: Button = %StartButton
@onready var _host_status: Label = %HostStatus
@onready var _error_label: Label = %ErrorLabel

const PLAYER_ROW := preload("res://scenes/components/player_row.tscn")

func _ready() -> void:
	GameState.state_updated.connect(refresh)
	NetworkManager.error_received.connect(_on_error)
	_start_btn.pressed.connect(_on_start_pressed)
	refresh()

func refresh() -> void:
	_room_code.text = GameState.room_code
	_join_hint.text = "با گوشی به صفحهٔ وب بازیکن بروید\nو کد %s را وارد کنید" % GameState.room_code
	_host_status.text = "وضعیت میزبان: " + ("متصل" if GameState.host_connected else "قطع (۶۰ ثانیه مهلت)")
	_start_btn.disabled = not GameState.can_start_game()

	for child in _player_list.get_children():
		child.queue_free()

	for player in GameState.players:
		if player is Dictionary:
			var row := PLAYER_ROW.instantiate()
			_player_list.add_child(row)
			row.setup(player)
			row.kick_requested.connect(_on_kick_requested)

func _on_start_pressed() -> void:
	_start_btn.disabled = true
	NetworkManager.start_game(3)

func _on_kick_requested(player_id: String) -> void:
	NetworkManager.kick_player(player_id)

func _on_error(_code: String, message: String) -> void:
	_error_label.text = message
	_start_btn.disabled = not GameState.can_start_game()
