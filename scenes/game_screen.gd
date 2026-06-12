extends Control

@onready var _phase_label: Label = %PhaseLabel
@onready var _round_label: Label = %RoundLabel
@onready var _countdown: Label = %CountdownLabel
@onready var _prompt: Label = %PromptLabel
@onready var _detail: RichTextLabel = %DetailLabel
@onready var _progress: Label = %ProgressLabel
@onready var _end_btn: Button = %EndGameButton

func _ready() -> void:
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
	_detail.text = ""
	_progress.text = ""

	match GameState.phase:
		"prompt", "submit":
			_progress.text = "ارسال پاسخ: %d / %d" % [GameState.submit_submitted, GameState.submit_total]
		"vote":
			_progress.text = "رأی: %d / %d" % [GameState.vote_voted, GameState.vote_total]
			_detail.text = _format_vote_options()
		"reveal":
			_detail.text = _format_reveal()
		"score":
			_detail.text = _format_scores()

func _format_vote_options() -> String:
	if GameState.vote_options.is_empty():
		return ""
	var lines: PackedStringArray = ["[b]گزینه‌های رأی:[/b]"]
	for opt in GameState.vote_options:
		if opt is Dictionary:
			lines.append("• %s" % str(opt.get("text", "")))
	return "\n".join(lines)

func _format_reveal() -> String:
	var lines: PackedStringArray = ["[b]پاسخ درست:[/b] %s" % GameState.reveal_truth]
	for entry in GameState.reveal_entries:
		if entry is Dictionary:
			var author_id := str(entry.get("authorId", ""))
			var name := "پاسخ درست" if author_id.is_empty() else _player_name(author_id)
			lines.append("• %s — %s (فریب: %d)" % [
				str(entry.get("text", "")), name, int(entry.get("fooledCount", 0))
			])
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
