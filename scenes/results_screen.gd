extends Control

@onready var _title: Label = %TitleLabel
@onready var _scores: VBoxContainer = %ScoreList
@onready var _reason: Label = %ReasonLabel
@onready var _back_btn: Button = %BackButton

func _ready() -> void:
	refresh()

func refresh() -> void:
	_title.text = "پایان بازی!"
	_reason.text = GameState.game_end_reason
	for child in _scores.get_children():
		child.queue_free()

	var ranked: Array = GameState.game_end_totals.duplicate()
	ranked.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))

	var rank := 1
	for row in ranked:
		if row is Dictionary:
			var label := Label.new()
			label.text = "%d. %s — %d امتیاز" % [rank, str(row.get("name", "")), int(row.get("score", 0))]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_scores.add_child(label)
			rank += 1

func _on_back_pressed() -> void:
	GameState.return_to_lobby()
