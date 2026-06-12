extends Node

enum Screen { CONNECT, LOBBY, GAME, RESULTS }

var current_screen: int = Screen.CONNECT

var room_id: String = ""
var room_code: String = ""
var host_token: String = ""
var phase: String = "disconnected"
var host_connected: bool = true
var players: Array = []
var max_players: int = 8

var round: int = 0
var total_rounds: int = 0
var phase_deadline_unix: int = 0

var submit_submitted: int = 0
var submit_total: int = 0
var vote_voted: int = 0
var vote_total: int = 0

var prompt_text: String = ""
var prompt_id: String = ""
var round_kind: String = "classic"
var subject_player_id: String = ""
var subject_name: String = ""
var reveal_round_kind: String = "classic"
var vote_options: Array = []
var reveal_truth: String = ""
var reveal_entries: Array = []
var round_scores: Array = []
var score_totals: Array = []

var game_end_totals: Array = []
var game_end_reason: String = ""

var last_error: String = ""

signal state_updated
signal game_ended
signal room_closed(reason: String)
signal screen_changed(screen: int)

func reset_session() -> void:
	room_id = ""
	room_code = ""
	host_token = ""
	phase = "disconnected"
	players = []
	_clear_round_data()
	current_screen = Screen.CONNECT
	state_updated.emit()

func _clear_round_data() -> void:
	round = 0
	total_rounds = 0
	phase_deadline_unix = 0
	submit_submitted = 0
	submit_total = 0
	vote_voted = 0
	vote_total = 0
	prompt_text = ""
	prompt_id = ""
	round_kind = "classic"
	subject_player_id = ""
	subject_name = ""
	reveal_round_kind = "classic"
	vote_options = []
	reveal_truth = ""
	reveal_entries = []
	round_scores = []
	score_totals = []
	game_end_totals = []
	game_end_reason = ""

func apply_room_state(payload: Dictionary) -> void:
	room_id = str(payload.get("roomId", room_id))
	room_code = str(payload.get("roomCode", room_code))
	phase = str(payload.get("phase", phase))
	host_connected = bool(payload.get("hostConnected", host_connected))
	max_players = int(payload.get("maxPlayers", max_players))
	players = payload.get("players", players)

	round = int(payload.get("round", round))
	total_rounds = int(payload.get("totalRounds", total_rounds))

	var deadline := str(payload.get("phaseDeadline", ""))
	phase_deadline_unix = _parse_iso_deadline(deadline)

	var submit: Dictionary = payload.get("submitProgress", {})
	if not submit.is_empty():
		submit_submitted = int(submit.get("submitted", submit_submitted))
		submit_total = int(submit.get("total", submit_total))

	var vote: Dictionary = payload.get("voteProgress", {})
	if not vote.is_empty():
		vote_voted = int(vote.get("voted", vote_voted))
		vote_total = int(vote.get("total", vote_total))

	_update_screen_from_phase()
	state_updated.emit()

func apply_room_created(payload: Dictionary) -> void:
	room_id = str(payload.get("roomId", ""))
	room_code = str(payload.get("roomCode", ""))

func apply_host_session(payload: Dictionary) -> void:
	room_id = str(payload.get("roomId", room_id))
	host_token = str(payload.get("hostToken", host_token))
	Config.room_id = room_id
	Config.host_token = host_token
	Config.room_code = room_code
	Config.save_config()

func apply_game_started(payload: Dictionary) -> void:
	total_rounds = int(payload.get("totalRounds", total_rounds))
	_set_screen(Screen.GAME)

func apply_round_prompt(payload: Dictionary) -> void:
	round = int(payload.get("round", round))
	prompt_id = str(payload.get("promptId", ""))
	prompt_text = str(payload.get("text", ""))
	round_kind = str(payload.get("roundKind", "classic"))
	subject_player_id = str(payload.get("subjectPlayerId", ""))
	subject_name = str(payload.get("subjectName", ""))
	var deadline := str(payload.get("submitDeadline", ""))
	phase_deadline_unix = _parse_iso_deadline(deadline)
	_set_screen(Screen.GAME)
	state_updated.emit()

func apply_vote_options(payload: Dictionary) -> void:
	vote_options = payload.get("options", [])
	state_updated.emit()

func apply_round_reveal(payload: Dictionary) -> void:
	reveal_truth = str(payload.get("truth", ""))
	reveal_entries = payload.get("entries", [])
	reveal_round_kind = str(payload.get("roundKind", round_kind))
	state_updated.emit()

func apply_round_scores(payload: Dictionary) -> void:
	round_scores = payload.get("roundScores", [])
	score_totals = payload.get("totals", [])
	state_updated.emit()

func apply_game_ended(payload: Dictionary) -> void:
	game_end_totals = payload.get("totals", [])
	game_end_reason = str(payload.get("reason", ""))
	_set_screen(Screen.RESULTS)
	game_ended.emit()
	state_updated.emit()

func apply_room_closed(reason: String) -> void:
	reset_session()
	Config.clear_session()
	room_closed.emit(reason)
	state_updated.emit()

func connected_player_count() -> int:
	var count := 0
	for player in players:
		if player is Dictionary and bool(player.get("connected", false)):
			count += 1
	return count

func can_start_game() -> bool:
	return phase == "lobby" and connected_player_count() >= 2

func phase_label() -> String:
	match phase:
		"lobby": return "لابی"
		"prompt": return "سؤال"
		"submit":
			return "دربارهٔ شما" if round_kind == "about" else "در حال نوشتن دروغ"
		"vote": return "رأی‌گیری"
		"reveal": return "افشاگری"
		"score": return "امتیازها"
		_: return phase

func _update_screen_from_phase() -> void:
	if phase == "lobby":
		_set_screen(Screen.LOBBY)
	elif phase in ["prompt", "submit", "vote", "reveal", "score"]:
		_set_screen(Screen.GAME)

func _set_screen(screen: int) -> void:
	if current_screen != screen:
		current_screen = screen
		screen_changed.emit(screen)

func _parse_iso_deadline(iso: String) -> int:
	if iso.is_empty():
		return 0
	# Godot 4: Time.get_unix_time_from_datetime_string needs format
	var cleaned := iso.replace("T", " ").replace("Z", "")
	if "." in cleaned:
		cleaned = cleaned.split(".")[0]
	var unix: float = Time.get_unix_time_from_datetime_string(cleaned)
	if unix < 0:
		return 0
	return int(unix)

func seconds_until_deadline() -> int:
	if phase_deadline_unix <= 0:
		return 0
	return maxi(0, phase_deadline_unix - int(Time.get_unix_time_from_system()))

func return_to_lobby() -> void:
	_clear_round_data()
	phase = "lobby"
	_set_screen(Screen.LOBBY)
	state_updated.emit()
