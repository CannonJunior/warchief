# Warchief Game - Flutter/Flame Project

## Port Configuration
- **ALWAYS run this web application on port 8008 ONLY**
- Never change the port without explicit user permission
- The default server port is 8008 - maintain this consistency across all sessions

## Project Structure
This is the Flutter/Flame implementation of the Warchief 3D isometric game.

```
warchief_game/
├── lib/
│   ├── main.dart              # Entry point
│   ├── game/                  # Game components
│   ├── ui/                    # UI components
│   ├── ai/                    # AI/Ollama integration
│   ├── models/                # Data models
│   └── utils/                 # Utilities
├── assets/                    # Game assets (SVG, PNG, etc.)
├── config/                    # Configuration files
├── personalities/             # NPC personality files
└── tests/                     # Unit & integration tests
```

## Development Commands

### Start the game
```bash
cd /home/junior/src/warchief
./start.sh
```

### Run from this directory
```bash
flutter run -d web-server --web-port=8008 --web-hostname=localhost
```

### Testing
```bash
flutter test
```

### Build for production
```bash
flutter build web
```

## Key Dependencies
- **flame**: Game engine
- **flame_isometric**: Isometric rendering
- **flutter_riverpod**: State management
- **http**: Ollama API communication

## Configuration Files
- `config/game_config.json`: Game settings (port, Ollama, graphics)
- `config/ui_config.json`: UI layout and assets
- `personalities/*.txt`: NPC AI personality definitions

## Architecture Notes
- Uses Flame game engine with Riverpod for state management
- AI-powered NPCs via local Ollama server (port 11434)
- Model Context Protocol (MCP) for LLM integration
- Asset-based UI system (SVG/PNG hot-reload)
- WoW-inspired control scheme (WASD, mouse camera)

## Parent Documentation
See parent directory for:
- PLATFORM_DESIGN.md - Full architecture
- QUICK_START.md - Quick reference guide
- TASK.md - Implementation tasks
