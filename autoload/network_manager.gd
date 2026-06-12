extends Node

var _socket := WebSocketPeer.new()
var _handshake_complete := false
var _was_open := false
var _prefer_reconnect := false

signal connected_changed(is_connected: bool)
signal error_received(code: String, message: String)

func _process(_delta: float) -> void:
	_socket.poll()
	var state := _socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not _was_open:
			_was_open = true
			_send_hello()
		while _socket.get_available_packet_count() > 0:
			var packet := _socket.get_packet().get_string_from_utf8()
			_handle_raw_message(packet)
	elif state == WebSocketPeer.STATE_CLOSED:
		if _was_open or _handshake_complete:
			_reset_connection_flags()
			connected_changed.emit(false)
		_was_open = false

func is_server_connected() -> bool:
	return _socket.get_ready_state() == WebSocketPeer.STATE_OPEN and _handshake_complete

func connect_to_server(url: String, prefer_reconnect: bool = false) -> Error:
	_prefer_reconnect = prefer_reconnect
	Config.server_url = url
	Config.save_config()
	_reset_connection_flags()
	_was_open = false

	var err := _socket.connect_to_url(url)
	if err != OK:
		error_received.emit("CONNECTION_FAILED", "Could not connect to %s" % url)
	return err

func disconnect_from_server() -> void:
	_socket.close()
	_was_open = false
	_reset_connection_flags()
	connected_changed.emit(false)

func create_room(max_players: int = 0) -> void:
	var payload := {}
	if max_players > 0:
		payload["maxPlayers"] = max_players
	send_message("host:create_room", payload)

func start_game(rounds: int = 3) -> void:
	send_message("host:start_game", {"rounds": rounds})

func kick_player(player_id: String) -> void:
	send_message("host:kick_player", {"playerId": player_id})

func end_game() -> void:
	send_message("host:end_game", {})

func next_round() -> void:
	send_message("host:next_round", {})

func close_room() -> void:
	send_message("host:close_room", {})

func reconnect_host() -> void:
	send_message("host:reconnect", {
		"roomId": Config.room_id,
		"hostToken": Config.host_token,
	})

func send_message(type: String, payload: Dictionary = {}) -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		error_received.emit("NOT_CONNECTED", "WebSocket is not open")
		return
	_socket.send_text(JSON.stringify({"type": type, "payload": payload}))

func _send_hello() -> void:
	send_message("client:hello", {"role": "host"})

func _handle_raw_message(raw: String) -> void:
	var parsed = JSON.parse_string(raw)
	if parsed == null or not parsed is Dictionary:
		return
	_route_message(parsed)

func _route_message(msg: Dictionary) -> void:
	var type := str(msg.get("type", ""))
	var payload: Dictionary = msg.get("payload", {})

	match type:
		"server:hello":
			_handshake_complete = true
			connected_changed.emit(true)
			if _prefer_reconnect and Config.has_saved_session():
				reconnect_host()
			else:
				create_room()
		"room:created":
			GameState.apply_room_created(payload)
			Config.room_code = GameState.room_code
			Config.save_config()
		"host:session":
			GameState.apply_host_session(payload)
		"room:state":
			GameState.apply_room_state(payload)
		"game:started":
			GameState.apply_game_started(payload)
		"round:prompt":
			GameState.apply_round_prompt(payload)
		"round:vote_options":
			GameState.apply_vote_options(payload)
		"round:reveal":
			GameState.apply_round_reveal(payload)
		"round:scores":
			GameState.apply_round_scores(payload)
		"game:ended":
			GameState.apply_game_ended(payload)
		"room:closed":
			GameState.apply_room_closed(str(payload.get("reason", "Room closed")))
			disconnect_from_server()
		"server:error":
			var code := str(payload.get("code", "ERROR"))
			var message := str(payload.get("message", "Unknown error"))
			if code == "RECONNECT_FAILED" or code == "SESSION_EXPIRED":
				Config.clear_session()
				_prefer_reconnect = false
				create_room()
			error_received.emit(code, message)

func _reset_connection_flags() -> void:
	_handshake_complete = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_server_connected():
			close_room()
		disconnect_from_server()
