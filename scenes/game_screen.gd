extends Control

@onready var _phase_label: Label = %PhaseLabel
@onready var _round_label: Label = %RoundLabel
@onready var _countdown: Label = %CountdownLabel
@onready var _prompt: Label = %PromptLabel
@onready var _detail: RichTextLabel = %DetailLabel
@onready var _progress: Label = %ProgressLabel
@onready var _end_btn: Button = %EndGameButton

var _reveal_timer: Timer
var _reveal_lines: PackedStringArray = []
var _reveal_shown: int = 0
var _last_phase: String = ""

func _ready() -> void:
	_reveal_timer = Timer.new()
	_reveal_timer.one_shot = false
	_reveal_timer.wait_time = 1.1
	_reveal_timer.timeout.connect(_on_reveal_tick)
	add_child(_reveal_timer)

	GameState.state_updated.connect(refresh)
	_end_btn.pressed.connect(func(): NetworkManager.end_game())
	refresh()

func _process(_delta: float) -> void:
	if visible and GameState.phase_deadline_unix > 0:
		_countdown.text = "⏱ %d ثانیه" % GameState.seconds_until_deadline()

func refresh() -> void:
	_phase_label.text = GameState.phase_label()
	_round_label.text = "دور %d از %d" % [GameState.round, GameState.total_rounds] if GameState.total_rounds > 0 else ""
	_prompt.text = GameState.prompt_text
	_progress.text = ""

	if GameState.phase != "reveal":
		_reset_reveal_animation()
		_last_phase = GameState.phase
		_detail.text = ""
		match GameState.phase:
			"prompt", "submit":
				_progress.text = "ارسال پاسخ: %d / %d" % [GameState.submit_submitted, GameState.submit_total]
			"vote":
				_progress.text = "رأی: %d / %d" % [GameState.vote_voted, GameState.vote_total]
				_detail.text = _format_vote_options()
			"score":
				_detail.text = _format_scores()
		return

	if _last_phase != "reveal":
		_start_reveal_animation()
	_last_phase = GameState.phase
	_detail.text = _format_partial_reveal()

func _start_reveal_animation() -> void:
	_reveal_lines = _build_reveal_lines()
	_reveal_shown = 0
	_reveal_timer.start()
	_on_reveal_tick()

func _on_reveal_tick() -> void:
	if _reveal_shown < _reveal_lines.size():
		_reveal_shown += 1
		_detail.text = _format_partial_reveal()
	else:
		_reveal_timer.stop()

func _reset_reveal_animation() -> void:
	_reveal_timer.stop()
	_reveal_lines = []
	_reveal_shown = 0

func _format_partial_reveal() -> String:
	if _reveal_lines.is_empty():
		return ""
	var lines: PackedStringArray = []
	for i in range(mini(_reveal_shown, _reveal_lines.size())):
		lines.append(_reveal_lines[i])
	return "\n".join(lines)

func _build_reveal_lines() -> PackedStringArray:
	var lines: PackedStringArray = ["[b]پاسخ درست:[/b] %s" % GameState.reveal_truth]
	for entry in GameState.reveal_entries:
		if entry is Dictionary:
			var author_id := str(entry.get("authorId", ""))
			var name := "پاسخ درست" if author_id.is_empty() else _player_name(author_id)
			lines.append("• %s — %s (فریب: %d)" % [
				str(entry.get("text", "")), name, int(entry.get("fooledCount", 0))
			])
	return lines

func _format_vote_options() -> String:
	if GameState.vote_options.is_empty():
		return ""
	var lines: PackedStringArray = ["[b]گزینه‌های رأی:[/b]"]
	for opt in GameState.vote_options:
		if opt is Dictionary:
			lines.append("• %s" % str(opt.get("text", "")))
	return "\n".join(lines)

func _format_scores() -> String:
	var lines: PackedStringArray = ["[b]امتیازها:[/b]"]
	for row in GameState.score_totals:
		if row is Dictionary:
			lines.append("%s — %d" % [str(row.get("name", "")), int(row.get("score", 0))])
	return "\n".join(lines)

func _player_name(player_id: String) -> String:
	for player in GameState.players:
		if player is Dictionary and str(player.get("id", "")) == player_id:
			return str(player.get("name", ""))
	return player_id
