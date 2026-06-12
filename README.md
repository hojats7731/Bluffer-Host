# Bluffer Host

Godot 4.6 big-screen host app for [Bluffer](https://github.com/hojats7731/Bluffer) — a Persian Fibbage-style party game.

Players join from their phones via the **Bluffer-Web** client (separate repo). This app runs on a TV or laptop and displays the room code, lobby, and game phases.

## Requirements

- [Godot 4.6+](https://godotengine.org/)
- [Bluffer server](https://github.com/hojats7731/Bluffer) running locally or on a network

## Quickstart

```bash
# Terminal 1 — start server
cd ../Bluffer && docker compose up

# Terminal 2 — open Godot
# Open this folder in Godot 4.6 and press F5 (Run)
```

1. Enter server URL: `ws://127.0.0.1:3000/ws`
2. Click **ساخت اتاق جدید** (Create room)
3. Share the 4-letter room code with players
4. When 2+ players join, click **شروع بازی**

## Project structure

```
autoload/          Config, GameState, NetworkManager
scenes/            Connect, Lobby, Game, Results screens
assets/fonts/      Vazirmatn (Persian)
assets/themes/     Dark party-game theme
docs/PROTOCOL.md   Wire contract (from server repo)
```

## Protocol

Implements [Bluffer WebSocket protocol v2](docs/PROTOCOL.md) as the **host** role.

## Configuration

Server URL and reconnect tokens are saved to `user://host_config.cfg`.

## Related repos

| Repo | Role |
|------|------|
| [Bluffer](https://github.com/hojats7731/Bluffer) | Game server |
| **Bluffer-Host** (this) | Godot TV host |
| Bluffer-Web | Mobile player controllers (coming soon) |

## License

MIT
