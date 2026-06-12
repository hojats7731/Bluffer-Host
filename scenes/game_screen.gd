extends Control

enum RevealStep { IDLE, LIE_TEXT, VOTERS, LIAR, TRUTH, DONE }

@onready var _bg_top: ColorRect = %BgTop
@onready var _bg_bottom: ColorRect = %BgBottom
@onready var _phase_label: Label = %PhaseLabel
@onready var _round_label: Label = %RoundLabel
@onready var _countdown: Label = %CountdownLabel
@onready var _prompt: Label = %PromptLabel
@onready var _progress: Label = %ProgressLabel
@onready var _detail: RichTextLabel = %DetailLabel
@onready var _reveal_card: PanelContainer = %RevealCard
@onready var _reveal_title: Label = %RevealTitle
@onready var _reveal_body: Label = %RevealBody
@onready var _reveal_sub: Label = %RevealSub
@onready var _end_btn: Button = %EndGameButton

var _reveal_timer: Timer
var _reveal_step: int = RevealStep.IDLE
var _reveal_index: int = 0
var _last_phase: String = ""
var _prompt_tween: Tween

const REVEAL_BEAT := 1.35

func _ready() -> void:
	_reveal_timer = Timer.new()
	_reveal_timer.one_shot = true
	_reveal_timer.timeout.connect(_advance_reveal)
	add_child(_reveal_timer)

	GameState.state_updated.connect(refresh)
	_end_btn.pressed.connect(func(): NetworkManager.end_game())
	_reveal_card.visible = false
	refresh()

func _process(_delta: float) -> void:
	if visible and GameState.phase_deadline_unix > 0:
		var secs := GameState.seconds_until_deadline()
		_countdown.text = "⏱ %s ثانیه" % LocaleUtils.to_persian_digits(secs)

func refresh() -> void:
	_phase_label.text = GameState.phase_label()
	if GameState.total_rounds > 0:
		_round_label.text = "دور %s از %s" % [
			LocaleUtils.to_persian_digits(GameState.round),
			LocaleUtils.to_persian_digits(GameState.total_rounds),
		]
	else:
		_round_label.text = ""

	_prompt.text = GameState.prompt_text
	_detail.visible = false
	_reveal_card.visible = false
	_progress.text = ""

	if GameState.phase != "reveal":
		_reset_reveal()
		_last_phase = GameState.phase

	match GameState.phase:
		"prompt", "submit":
			_pulse_prompt()
			_progress.text = "ارسال پاسخ: %s / %s" % [
				LocaleUtils.to_persian_digits(GameState.submit_submitted),
				LocaleUtils.to_persian_digits(GameState.submit_total),
			]
		"vote":
			_progress.text = "بازیکنان در حال رأی دادن... (%s / %s)" % [
				LocaleUtils.to_persian_digits(GameState.vote_voted),
				LocaleUtils.to_persian_digits(GameState.vote_total),
			]
			_detail.visible = true
			_detail.text = "[center][b]📱 رأی خود را روی گوشی ثبت کنید[/b][/center]"
		"score":
			_detail.visible = true
			_detail.text = _format_scores()
		"reveal":
			if _last_phase != "reveal":
				_start_reveal_sequence()
			_last_phase = GameState.phase

func _pulse_prompt() -> void:
	if _prompt_tween:
		_prompt_tween.kill()
	_prompt.scale = Vector2.ONE
	_prompt_tween = create_tween().set_loops()
	_prompt_tween.tween_property(_prompt, "scale", Vector2(1.03, 1.03), 0.8)
	_prompt_tween.tween_property(_prompt, "scale", Vector2.ONE, 0.8)

func _start_reveal_sequence() -> void:
	_reveal_index = 0
	_reveal_step = RevealStep.LIE_TEXT
	_show_reveal_step()

func _advance_reveal() -> void:
	match _reveal_step:
		RevealStep.LIE_TEXT:
			_reveal_step = RevealStep.VOTERS
		RevealStep.VOTERS:
			_reveal_step = RevealStep.LIAR
		RevealStep.LIAR:
			_reveal_index += 1
			if _reveal_index < GameState.reveal_entries.size():
				_reveal_step = RevealStep.LIE_TEXT
			else:
				_reveal_step = RevealStep.TRUTH
		RevealStep.TRUTH:
			_reveal_step = RevealStep.DONE
			_reveal_timer.stop()
			return
	_show_reveal_step()

func _show_reveal_step() -> void:
	_reveal_card.visible = true
	_pop_in_card()
	AudioManager.play_reveal()

	if _reveal_step == RevealStep.TRUTH:
		_reveal_title.text = "✅ پاسخ درست"
		_reveal_body.text = GameState.reveal_truth
		_reveal_sub.text = "این بود حقیقت!"
		_reveal_timer.start(REVEAL_BEAT * 1.5)
		return

	if _reveal_index >= GameState.reveal_entries.size():
		_reveal_step = RevealStep.TRUTH
		_show_reveal_step()
		return

	var entry: Dictionary = GameState.reveal_entries[_reveal_index]
	var lie_text := str(entry.get("text", ""))
	var author_name := str(entry.get("authorName", ""))
	if author_name.is_empty() or author_name == "null":
		author_name = _player_name(str(entry.get("authorId", "")))
	var voters: Array = entry.get("voters", [])
	var fooled := int(entry.get("fooledCount", 0))
	var points := int(entry.get("pointsEarned", fooled * 100))

	match _reveal_step:
		RevealStep.LIE_TEXT:
			_reveal_title.text = "🎭 یک پاسخ..."
			_reveal_body.text = lie_text
			_reveal_sub.text = ""
		RevealStep.VOTERS:
			_reveal_title.text = "🗳️ چه کسی این را انتخاب کرد؟"
			_reveal_body.text = lie_text
			if voters.is_empty():
				_reveal_sub.text = "هیچ‌کس!"
			else:
				var names: PackedStringArray = []
				for v in voters:
					if v is Dictionary:
						names.append(str(v.get("name", "?")))
				_reveal_sub.text = "، ".join(names)
		RevealStep.LIAR:
			_reveal_title.text = "🤥 دروغ‌گو"
			_reveal_body.text = lie_text
			_reveal_sub.text = "%s نوشت — +%s امتیاز" % [
				author_name,
				LocaleUtils.to_persian_digits(points),
			]

	_reveal_timer.start(REVEAL_BEAT)

func _pop_in_card() -> void:
	_reveal_card.scale = Vector2(0.85, 0.85)
	_reveal_card.modulate.a = 0.0
	var tween := create_tween()
	tween.parallel().tween_property(_reveal_card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(_reveal_card, "modulate:a", 1.0, 0.2)

func _reset_reveal() -> void:
	_reveal_timer.stop()
	_reveal_step = RevealStep.IDLE
	_reveal_index = 0

func _format_scores() -> String:
	var lines: PackedStringArray = ["[b]🏆 امتیازها[/b]"]
	for row in GameState.score_totals:
		if row is Dictionary:
			lines.append("%s — %s" % [
				str(row.get("name", "")),
				LocaleUtils.to_persian_digits(int(row.get("score", 0))),
			])
	return "\n".join(lines)

func _player_name(player_id: String) -> String:
	if player_id.is_empty() or player_id == "null":
		return "ناشناس"
	for player in GameState.players:
		if player is Dictionary and str(player.get("id", "")) == player_id:
			return str(player.get("name", ""))
	return "ناشناس"
