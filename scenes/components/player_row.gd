extends HBoxContainer

signal kick_requested(player_id: String)

var _player_id: String = ""

@onready var _avatar: Label = %AvatarLabel
@onready var _name_label: Label = %NameLabel
@onready var _status_dot: ColorRect = %StatusDot
@onready var _score_label: Label = %ScoreLabel
@onready var _kick_btn: Button = %KickButton

func setup(player: Dictionary) -> void:
	_player_id = str(player.get("id", ""))
	_avatar.text = AvatarUtils.emoji(player)
	_name_label.text = AvatarUtils.player_name(player)
	_status_dot.color = Color(0.2, 0.95, 0.55) if bool(player.get("connected", false)) else Color(0.95, 0.35, 0.35)
	var score = player.get("score", null)
	_score_label.visible = score != null
	_score_label.text = "" if score == null else LocaleUtils.to_persian_digits(int(score))
	_kick_btn.visible = GameState.phase == "lobby"

	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func _on_kick_pressed() -> void:
	kick_requested.emit(_player_id)
