extends Control

@onready var _room_code: Label = %RoomCodeLabel
@onready var _join_hint: Label = %JoinHint
@onready var _join_url: Label = %JoinUrlLabel
@onready var _qr_texture: TextureRect = %QrTexture
@onready var _player_list: VBoxContainer = %PlayerList
@onready var _start_btn: Button = %StartButton
@onready var _rounds_option: OptionButton = %RoundsOption
@onready var _host_status: Label = %HostStatus
@onready var _error_label: Label = %ErrorLabel
@onready var _http: HTTPRequest = %QrRequest

const PLAYER_ROW := preload("res://scenes/components/player_row.tscn")

func _ready() -> void:
	GameState.state_updated.connect(refresh)
	NetworkManager.connected_changed.connect(_on_connection_changed)
	NetworkManager.error_received.connect(_on_error)
	_http.request_completed.connect(_on_qr_loaded)
	_rounds_option.add_item("۳ دور", 3)
	_rounds_option.add_item("۵ دور", 5)
	_rounds_option.add_item("۷ دور", 7)
	_rounds_option.select(0)
	_start_btn.pressed.connect(_on_start_pressed)
	refresh()

func refresh() -> void:
	_room_code.text = GameState.room_code
	var join_url := _build_join_url()
	_join_hint.text = "با گوشی به آدرس زیر بروید یا QR را اسکن کنید"
	_join_url.text = join_url
	_load_qr(join_url)
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

func _build_join_url() -> String:
	var code := GameState.room_code
	if code.is_empty():
		return ""
	var host_ip := _detect_lan_ip()
	return "http://%s:%d/?room=%s" % [host_ip, Config.web_port, code]

func _detect_lan_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			return addr
	for addr in IP.get_local_addresses():
		if addr != "127.0.0.1" and not addr.contains(":"):
			return addr
	return "127.0.0.1"

func _load_qr(join_url: String) -> void:
	if join_url.is_empty():
		_qr_texture.texture = null
		return
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http.cancel_request()
	var qr_api := "https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=%s" % join_url.uri_encode()
	_http.request(qr_api)

func _on_qr_loaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_qr_texture.texture = null
		return
	var image := Image.new()
	var err := image.load_png_from_buffer(body)
	if err != OK:
		_qr_texture.texture = null
		return
	_qr_texture.texture = ImageTexture.create_from_image(image)

func _on_start_pressed() -> void:
	_start_btn.disabled = true
	var rounds := _rounds_option.get_item_id(_rounds_option.selected)
	NetworkManager.start_game(rounds)

func _on_kick_requested(player_id: String) -> void:
	NetworkManager.kick_player(player_id)

func _on_connection_changed(_is_connected: bool) -> void:
	_host_status.text = "وضعیت میزبان: " + ("متصل" if GameState.host_connected else "قطع (۶۰ ثانیه مهلت)")

func _on_error(_code: String, message: String) -> void:
	_error_label.text = message
	_start_btn.disabled = not GameState.can_start_game()
