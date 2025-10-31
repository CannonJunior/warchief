# Quick Start Guide - Warchief 3D Isometric Game

## What Is This Project?

A 3D isometric game built with Flutter/Dart featuring:
- **WoW-inspired character controls** (WASD movement, mouse camera)
- **AI-powered NPC companions** using local Ollama LLMs
- **Dual NPC control modes**: Intent-based AI or direct commands
- **Configurable UI** with easy SVG/PNG asset replacement
- **Fully rebindable controls**
- **Web-first development** with hot-reload support

## Tech Stack Summary

| Component | Technology |
|-----------|------------|
| Framework | Flutter + Dart |
| Game Engine | Flame + Flame Isometric |
| AI/LLM | Ollama (local) |
| AI Protocol | Model Context Protocol (MCP) |
| Maps | Tiled Integration |
| State Management | Riverpod |
| Target Platform | Web (dev), Multi-platform (future) |

## Core Features

### 1. WoW-Style Controls
- **WASD**: Movement
- **Q/E**: Strafe/Rotate
- **Space**: Jump
- **Mouse + Right Click**: Camera rotation
- **1-9, 0, -, =**: 12 action bar slots
- All keys rebindable via settings UI

### 2. NPC Control System

**Mode A: Intent-Based (AI)**
```dart
// Player gives high-level instructions
npc.giveIntent("Focus on healing me when I'm low");
// NPC uses Ollama LLM to decide actions
```

**Mode B: Direct Commands (Manual)**
```dart
// Player issues specific commands like WoW pets
npc.attack(target);
npc.follow();
npc.stay();
npc.setStance(NPCStance.defensive);
```

### 3. MCP Integration
NPCs use Model Context Protocol to:
- Receive game state context (player health, nearby enemies, etc.)
- Access available tools/actions (move, attack, heal, etc.)
- Make context-aware decisions
- Execute function calls in real-time

## Project Structure

```
warchief/
├── lib/
│   ├── game/              # Flame game components
│   ├── ui/                # UI components (action bars, health bars)
│   ├── ai/                # Ollama + MCP integration
│   ├── models/            # Data models
│   └── utils/             # Utilities
├── assets/
│   ├── ui/                # SVG/PNG UI assets
│   ├── sprites/           # Character sprites
│   ├── tiles/             # Isometric tiles
│   └── icons/             # Ability icons
├── config/
│   ├── game_config.json   # Game settings (port 8008)
│   └── ui_config.json     # UI layout configuration
├── personalities/
│   ├── warrior_companion.txt
│   ├── healer_companion.txt
│   └── mage_companion.txt
├── PLATFORM_DESIGN.md     # Full architecture (this is the main doc!)
├── CLAUDE.md              # Project instructions
└── TASK.md                # Task tracking
```

## Getting Started

### Prerequisites
```bash
# Install Flutter
flutter doctor

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull recommended models
ollama pull llama3.1:8b-instruct-q8_0
ollama pull mistral:7b-instruct-q4
ollama pull qwen2.5:7b-instruct
```

### Setup
```bash
# Clone and setup
cd warchief
uv sync                    # Install dependencies

# Start Ollama (in separate terminal)
ollama serve               # Runs on port 11434

# Run game
uv run server.py           # Game runs on port 8008
```

## Development Workflow

### 1. Adding UI Components
```bash
# 1. Create/update SVG/PNG in assets/ui/
# 2. Update config/ui_config.json
# 3. Hot-reload automatically updates UI
```

### 2. Creating NPC Personalities
```bash
# 1. Write personality file in personalities/
# 2. Define available tools/actions
# 3. Test with: ollama run llama3.1:8b-instruct-q8_0
# 4. Integrate into game
```

### 3. Testing AI Behavior
```bash
# Test LLM locally first
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.1:8b-instruct-q8_0",
  "messages": [{"role": "user", "content": "Test prompt"}],
  "stream": false
}'
```

## Key Files to Read

1. **PLATFORM_DESIGN.md** - Complete architecture (13 sections, 1000+ lines)
2. **config/game_config.json** - Game settings
3. **config/ui_config.json** - UI layout
4. **personalities/*.txt** - NPC personality prompts
5. **CLAUDE.md** - Project instructions for Claude

## Implementation Phases

| Phase | Duration | Focus |
|-------|----------|-------|
| 1 | Weeks 1-2 | Core infrastructure (Flame, movement, camera) |
| 2 | Weeks 3-4 | UI system (assets, config, keybinds) |
| 3 | Weeks 5-6 | Combat & actions |
| 4 | Weeks 7-8 | NPC direct control |
| 5 | Weeks 9-11 | Ollama + MCP integration |
| 6 | Weeks 12-14 | Intent-based AI control |
| 7 | Weeks 15-16 | Advanced features |
| 8 | Weeks 17-18 | Polish & optimization |

## Common Commands

```bash
# Development
uv run server.py           # Run game server (port 8008)
uv run pytest              # Run tests

# Ollama
ollama list                # List installed models
ollama run MODEL_NAME      # Test model interactively
ollama serve               # Start Ollama server

# Flutter
flutter pub get            # Install dependencies
flutter run -d chrome      # Run in Chrome
flutter build web          # Build for production
```

## Key Design Decisions

1. **Local-First**: Everything runs locally (no cloud APIs)
2. **Configuration Over Code**: Use JSON/assets instead of hardcoding
3. **Web-First Development**: Fast iteration with hot-reload
4. **Modular Components**: Clean separation (game/ui/ai)
5. **Port 8008**: Standard port for this project

## Recommended Models for NPCs

| Model | Role | RAM | Strength |
|-------|------|-----|----------|
| Llama 3.1 8B | Combat/Strategy | 8GB | Best function calling |
| Mistral 7B | Dialogue | 4GB | Natural language |
| Qwen 2.5 7B | Support | 5GB | Good reasoning |
| Phi3 Mini | Simple NPCs | 2GB | Very fast |

## Next Steps

1. Read **PLATFORM_DESIGN.md** for full architecture
2. Set up development environment (Flutter + Ollama)
3. Start with Phase 1 implementation
4. Test with simple NPCs before adding AI
5. Iterate on personality prompts

## Resources

- **Flame Docs**: https://docs.flame-engine.org
- **Ollama Docs**: https://github.com/ollama/ollama
- **MCP Docs**: https://modelcontextprotocol.io
- **Flutter Docs**: https://docs.flutter.dev

---

**For detailed architecture, see PLATFORM_DESIGN.md**
