extends Control

@onready var _title: Label = %TitleLabel
@onready var _scores: VBoxContainer = %ScoreList
@onready var _reason: Label = %ReasonLabel
@onready var _back_btn: Button = %BackButton

func _ready() -> void:
	refresh()

func refresh() -> void:
	_title.text = "🏆 پایان بازی!"
	_reason.text = GameState.game_end_reason
	for child in _scores.get_children():
		child.queue_free()

	var ranked: Array = GameState.game_end_totals.duplicate()
	ranked.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))

	var rank := 1
	for row in ranked:
		if row is Dictionary:
			var label := Label.new()
			var emoji := _emoji_for_player(str(row.get("playerId", "")))
			label.text = "%s%s. %s — %s امتیاز" % [
				emoji,
				LocaleUtils.to_persian_digits(rank),
				str(row.get("name", "")),
				LocaleUtils.to_persian_digits(int(row.get("score", 0))),
			]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.add_theme_font_size_override("font_size", 28)
			_scores.add_child(label)
			rank += 1

func _emoji_for_player(player_id: String) -> String:
	for player in GameState.players:
		if player is Dictionary and str(player.get("id", "")) == player_id:
			return AvatarUtils.emoji(player) + " "
	return ""

func _on_back_pressed() -> void:
	GameState.return_to_lobby()
