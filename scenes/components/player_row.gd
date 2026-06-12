extends HBoxContainer

signal kick_requested(player_id: String)

var _player_id: String = ""

@onready var _name_label: Label = %NameLabel
@onready var _status_dot: ColorRect = %StatusDot
@onready var _score_label: Label = %ScoreLabel
@onready var _kick_btn: Button = %KickButton

func setup(player: Dictionary) -> void:
	_player_id = str(player.get("id", ""))
	_name_label.text = str(player.get("name", ""))
	_status_dot.color = Color(0.2, 0.85, 0.4) if bool(player.get("connected", false)) else Color(0.85, 0.3, 0.3)
	var score = player.get("score", null)
	_score_label.visible = score != null
	_score_label.text = "" if score == null else str(int(score))
	_kick_btn.visible = GameState.phase == "lobby"

func _on_kick_pressed() -> void:
	kick_requested.emit(_player_id)
