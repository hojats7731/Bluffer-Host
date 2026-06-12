extends Node

const EMOJIS: Array[String] = [
	"🦊", "🐼", "🦁", "🐸", "🦄", "🐙",
	"🐯", "🐻", "🐶", "🐱", "🐨", "🐷",
]

const COLORS: Array[Color] = [
	Color(0.95, 0.45, 0.35),
	Color(0.35, 0.75, 0.95),
	Color(0.95, 0.8, 0.25),
	Color(0.55, 0.85, 0.45),
	Color(0.75, 0.45, 0.95),
	Color(0.95, 0.55, 0.75),
	Color(0.45, 0.9, 0.85),
	Color(0.9, 0.6, 0.3),
	Color(0.6, 0.65, 0.95),
	Color(0.85, 0.4, 0.4),
	Color(0.5, 0.8, 0.55),
	Color(0.8, 0.75, 0.4),
]

func avatar_id(player: Dictionary) -> int:
	var raw = player.get("avatarId", null)
	if raw != null:
		return clampi(int(raw), 0, EMOJIS.size() - 1)
	var pid := str(player.get("id", ""))
	var hash := 0
	for i in pid.length():
		hash = (hash + pid.unicode_at(i) * (i + 1)) % EMOJIS.size()
	return hash

func emoji(player: Dictionary) -> String:
	return EMOJIS[avatar_id(player)]

func color(player: Dictionary) -> Color:
	return COLORS[avatar_id(player)]

func player_name(player: Dictionary) -> String:
	return str(player.get("name", ""))
