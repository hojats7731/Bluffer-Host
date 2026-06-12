extends Control

@onready var _url_input: LineEdit = %UrlInput
@onready var _status_label: Label = %StatusLabel
@onready var _error_label: Label = %ErrorLabel
@onready var _connect_btn: Button = %ConnectButton
@onready var _reconnect_btn: Button = %ReconnectButton

func _ready() -> void:
	_url_input.text = Config.server_url
	_reconnect_btn.visible = Config.has_saved_session()
	NetworkManager.connected_changed.connect(_on_connected_changed)
	NetworkManager.error_received.connect(_on_error)
	_set_status("برای شروع، به سرور متصل شوید")

func _on_connect_pressed() -> void:
	_error_label.text = ""
	_set_status("در حال اتصال...")
	_connect_btn.disabled = true
	_reconnect_btn.disabled = true
	Config.clear_session()
	GameState.reset_session()
	var err := NetworkManager.connect_to_server(_url_input.text.strip_edges(), false)
	if err != OK:
		_enable_buttons()

func _on_reconnect_pressed() -> void:
	_error_label.text = ""
	_set_status("در حال اتصال مجدد...")
	_connect_btn.disabled = true
	_reconnect_btn.disabled = true
	NetworkManager.connect_to_server(_url_input.text.strip_edges(), true)

func _on_connected_changed(is_connected: bool) -> void:
	if is_connected:
		_set_status("متصل شد — در حال ساخت اتاق...")
	else:
		_set_status("قطع شد")
		_enable_buttons()

func _on_error(_code: String, message: String) -> void:
	_error_label.text = message
	_enable_buttons()

func _enable_buttons() -> void:
	_connect_btn.disabled = false
	_reconnect_btn.disabled = false

func _set_status(text: String) -> void:
	_status_label.text = text
