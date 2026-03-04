# Warchief - 3D Isometric Game with AI-Powered NPCs

A 3D isometric game built with Flutter and Dart featuring AI-powered NPC companions using local LLMs (Ollama + Model Context Protocol).

## Features

- **WoW-Inspired Controls**: WASD movement, mouse camera, rebindable keys
- **AI-Powered NPCs**: Control companions with high-level intent or direct commands
- **Local LLM Integration**: Ollama + MCP for privacy-focused AI
- **Asset-Based UI**: Easy SVG/PNG asset replacement with hot-reload
- **Web-First Development**: Fast iteration on port 8008

## Quick Start

### Prerequisites

```bash
# Install Flutter (if not installed)
# Visit: https://docs.flutter.dev/get-started/install

# Install Ollama (for AI features, optional for now)
curl -fsSL https://ollama.com/install.sh | sh

# Pull recommended models (optional)
ollama pull llama3.1:8b-instruct-q8_0
```

### Running the Game

```bash
# Simple: Use the start script
./start.sh

# Or manually:
cd warchief_game
flutter run -d web-server --web-port=8008 --web-hostname=localhost
```

Then open your browser to: **http://localhost:8008**

## Project Structure

```
warchief/
├── start.sh                     # Quick start script
├── PLATFORM_DESIGN.md           # Complete architecture (READ THIS!)
├── QUICK_START.md               # Developer quick reference
├── TASK.md                      # Implementation tasks
├── CLAUDE.md                    # Project instructions
└── warchief_game/               # Flutter/Flame project
    ├── lib/
    │   ├── game/                # Game components
    │   ├── ui/                  # UI components
    │   ├── ai/                  # AI/Ollama integration
    │   ├── models/              # Data models
    │   └── utils/               # Utilities
    ├── assets/                  # Game assets
    ├── config/                  # Configuration files
    └── personalities/           # NPC personality files
```

## Current Status

**Phase 1: Core Infrastructure** ✅ (COMPLETED)
- [x] Flutter project setup with Flame engine
- [x] Project directory structure
- [x] Basic game loop and rendering
- [x] Configuration system
- [x] Start script with port management
- [x] Isometric tile rendering (20x20 grid)
- [x] Player character with WASD movement
- [x] Camera controller with mouse drag and zoom
- [x] Input manager with full keybind support
- [x] Q/E rotation, Space jump
- [x] All systems integrated and working

**🎮 Game is PLAYABLE!**
Visit http://localhost:8008 after running `./start.sh`

**Next Up: Phase 2 (UI System)**
- [ ] UI configuration system
- [ ] Action bars (12 slots)
- [ ] Health/resource bars
- [ ] Keybind settings screen

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter + Dart |
| Game Engine | Flame 1.19.0 |
| Isometric | flame_isometric 0.4.2 |
| State | Riverpod 2.6.1 |
| AI/LLM | Ollama (local) |
| Protocol | Model Context Protocol |
| Port | **8008** |

## Configuration

### Game Settings
Edit `warchief_game/config/game_config.json`:
- Server port (default: 8008)
- Ollama integration settings
- Graphics options (FPS, zoom, tile size)
- NPC AI settings

### UI Configuration
Edit `warchief_game/config/ui_config.json`:
- UI component layout
- Asset paths for SVG/PNG files
- Theme settings

## Development

### Hot Reload
While the game is running, press `r` to hot reload changes.

### Running Tests
```bash
cd warchief_game
flutter test
```

### Building for Production
```bash
cd warchief_game
flutter build web
```

## Documentation

- **[PLATFORM_DESIGN.md](PLATFORM_DESIGN.md)** - Complete architecture and design (1000+ lines)
- **[QUICK_START.md](QUICK_START.md)** - Quick reference guide
- **[TASK.md](TASK.md)** - Implementation roadmap (18 weeks)
- **[CLAUDE.md](CLAUDE.md)** - AI assistant instructions

## Control Scheme ✅ WORKING

| Key(s) | Action | Status |
|--------|--------|--------|
| W | Move Forward | ✅ Working |
| S | Move Backward (half speed) | ✅ Working |
| A | Rotate Left | ✅ Working |
| D | Rotate Right | ✅ Working |
| Q | Strafe Left | ✅ Working |
| E | Strafe Right | ✅ Working |
| Space | Jump | ✅ Working |
| Right Click + Drag | Camera Rotation | ✅ Working (no context menu) |
| Mouse Scroll | Camera Zoom | ✅ Working |
| 1-9, 0, -, = | Action Bar (12 slots) | 📋 Bound (UI pending) |
| All Keys | Rebindable | ✅ System ready |

## AI Features (Coming Soon)

### Intent-Based Control
```
Player: "Focus on healing me when I'm low"
NPC: *Uses Ollama LLM to decide actions*
```

### Direct Control (WoW-Style)
```
/petattack - Attack target
/petfollow - Follow player
/petstay - Stay in place
/petpassive - Passive stance
```

## Contributing

This is a personal project following the architecture in PLATFORM_DESIGN.md.

## License

Private project - All rights reserved

## Resources

- [Flutter Docs](https://docs.flutter.dev)
- [Flame Docs](https://docs.flame-engine.org)
- [Ollama Docs](https://github.com/ollama/ollama)
- [MCP Docs](https://modelcontextprotocol.io)

---

**Current Build**: v0.1.0 (Development)
**Port**: 8008
**Status**: Phase 1 Complete ✅
