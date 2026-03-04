# Warchief Project - Claude Code Instructions

## READ FIRST - Mandatory Context Loading

Before exploring code or starting any task, **read these files in order**:

1. **`TASK.md`** - Check for current/pending tasks. Add new tasks before starting work.
2. **`warchief_game/CLAUDE.md`** - Game-specific architecture, file map, and subsystem docs.

Only explore the codebase AFTER reading the above. These files exist to prevent redundant exploration.

## Project Overview

This is a **3D isometric game** built with **Flutter/Dart** using a custom WebGL rendering pipeline. WoW-inspired controls, AI-powered NPCs via local Ollama, and a JSON-configuration-driven design.

- **Language**: Dart (Flutter framework). No Python, Mojo, or other languages in the game.
- **Port**: ALWAYS **8008**. Never change without explicit permission.
- **Entry point**: `warchief_game/lib/main.dart`
- **Start command**: `./start.sh` or `flutter run -d web-server --web-port=8008 --web-hostname=localhost`
- **Build command**: `flutter build web`

## Critical Rules

### Never Hardcode Values
Write values into JSON config files under `warchief_game/assets/data/` or `warchief_game/config/` and read them at runtime. Prompt the user if you ever create a hardcoded value.

### 500-Line File Limit
Never create a file longer than 500 lines. If approaching this limit, split into focused modules. See `warchief_game/CLAUDE.md` for the current oversized files that need splitting.

### Configuration-Driven Design
All tunable values (colors, speeds, multipliers, sizes, cooldowns) belong in JSON config files, not in Dart source code. Existing configs:
- `config/game_config.json` - Game settings
- `assets/data/stance_config.json` - Combat stances
- `assets/data/minimap_config.json` - Minimap settings
- `assets/data/wind_config.json` - Wind/weather system
- `assets/data/mana_config.json` - Mana system tuning
- `assets/data/items.json` - Item definitions

### Inline Reasoning Comments
When writing complex logic, add `// Reason:` comments explaining **why**, not what.

### Task Tracking
- Mark completed tasks in `TASK.md` immediately after finishing.
- Add discovered sub-tasks under a "Discovered During Work" section.

## Documentation Files

| File | Purpose | When to Read |
|------|---------|-------------|
| `TASK.md` | Task tracking and history | Every session start |
| `PLATFORM_DESIGN.md` | Full architecture spec | Understanding overall design |
| `QUICK_START.md` | Quick reference guide | Getting oriented |
| `warchief_game/CLAUDE.md` | Game code map and subsystem docs | Before any code changes |
| `warchief_game/RENDERING_PIPELINE.md` | WebGL rendering architecture | Touching rendering code |
| `warchief_game/GAME_STATE_ENTITIES.md` | Entity system reference | Touching game_state.dart |
| `warchief_game/ALLY_AND_MONSTER_AI_DOCUMENTATION.md` | AI system docs | Touching AI code |
| `warchief_game/FLIGHT_MECHANICS.md` | Flight system reference | Touching flight code |
| `warchief_game/docs/ABILITIES_GUIDE.md` | Ability system guide | Touching abilities |

## Style Conventions

- Follow Dart style conventions (lowerCamelCase for methods/variables, UpperCamelCase for classes)
- Use `///` doc comments for public APIs
- Group code with `// ==================== SECTION ====================` headers
- Prefer `final` for local variables
- Use null-safety (`?.`, `??`, `!`) consistently
