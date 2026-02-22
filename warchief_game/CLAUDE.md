# Warchief Game - Claude Code Instructions

## READ FIRST - Subsystem Documentation

**Before exploring or modifying code in a subsystem, read its documentation file:**

| Subsystem | Read This First | Key Files |
|-----------|----------------|-----------|
| Rendering / WebGL | `RENDERING_PIPELINE.md` | `lib/rendering3d/` |
| Game State / Entities | `GAME_STATE_ENTITIES.md` | `lib/game3d/state/game_state.dart` |
| AI (Ally + Monster) | `ALLY_AND_MONSTER_AI_DOCUMENTATION.md` | `lib/game3d/ai/`, `lib/game3d/systems/ai_system.dart` |
| Flight / Banking | `FLIGHT_MECHANICS.md` | `lib/game3d/state/game_state.dart` (flight section) |
| Abilities | `docs/ABILITIES_GUIDE.md` | `lib/game3d/systems/ability_system.dart`, `lib/game3d/data/abilities/` |
| Combat Stances | `assets/data/stance_config.json` | `lib/game3d/data/stances/` |
| Full Architecture | `../PLATFORM_DESIGN.md` | Everything |

**Do NOT start a codebase exploration before reading the relevant doc.** These files exist to save context window and time.

## Port Configuration
**ALWAYS port 8008.** Never change without explicit user permission.

## Commands
```bash
# Start dev server
cd /home/junior/src/warchief && ./start.sh
# Or from this directory:
flutter run -d web-server --web-port=8008 --web-hostname=localhost
# Build
flutter build web
# Analyze
flutter analyze
# Test
flutter test
```

## Project Structure (with line counts)

```
warchief_game/
├── lib/
│   ├── main.dart                    (175 lines) Entry point, global configs
│   ├── game3d/
│   │   ├── game3d_widget.dart       (2573!) Main widget, init, update, build, input
│   │   ├── state/
│   │   │   ├── game_state.dart      (2467!) Central state: player, mana, targeting, entities
│   │   │   ├── minimap_state.dart   (141)   Minimap zoom, pings, overlays
│   │   │   ├── minimap_config.dart  (284)   Minimap JSON config model
│   │   │   ├── wind_state.dart      (200)   Wind simulation + derecho storms
│   │   │   ├── wind_config.dart     (150)   Wind JSON config model
│   │   │   ├── mana_config.dart     (200)   Mana JSON config model
│   │   │   ├── gameplay_settings.dart(120)  Gameplay toggle settings
│   │   │   ├── action_bar_config.dart(200)  Action bar slot persistence
│   │   │   └── [other configs]
│   │   ├── systems/
│   │   │   ├── ability_system.dart  (2987!) Ability execution, cooldowns, effects
│   │   │   ├── ai_system.dart       (1251!) Monster + ally AI decision loops
│   │   │   ├── combat_system.dart   (876)   Damage application, dodge, pushback
│   │   │   ├── macro_system.dart    (498)   Rotation macro execution
│   │   │   ├── render_system.dart   (483)   3D render orchestration
│   │   │   └── input_system.dart    (200)   Movement/camera input
│   │   ├── ui/
│   │   │   ├── abilities_modal.dart (1801!) Abilities codex panel
│   │   │   ├── ability_editor_panel.dart (1029!) Ability property editor
│   │   │   ├── stance_editor_panel.dart  (651!) Stance property editor
│   │   │   ├── macro_builder_panel.dart  (737!) Macro builder UI
│   │   │   ├── unit_frames/
│   │   │   │   ├── combat_hud.dart  (880!) Health/mana/action bars
│   │   │   │   └── minion_frames.dart(592!) Minion health display
│   │   │   ├── minimap/
│   │   │   │   ├── minimap_widget.dart      (302) Main minimap
│   │   │   │   ├── minimap_border_icons.dart(528) Border controls
│   │   │   │   ├── minimap_terrain_painter.dart(387) Terrain rendering
│   │   │   │   ├── minimap_entity_painter.dart (246) Entity blips
│   │   │   │   ├── minimap_wind_painter.dart   (324) Wind overlay
│   │   │   │   └── minimap_green_painter.dart  (288) Green mana overlay
│   │   │   ├── settings/
│   │   │   │   ├── settings_panel.dart (543)
│   │   │   │   ├── interface_config.dart(421) Panel visibility/position
│   │   │   │   └── tuning_tab.dart    (509)
│   │   │   └── [other panels: character, bag, dps, mana_bar, chat, etc.]
│   │   ├── data/
│   │   │   ├── abilities/           Ability type definitions + registry
│   │   │   ├── stances/             Stance types, definitions, parsing
│   │   │   └── monsters/            Monster/minion definitions (567 lines!)
│   │   ├── ai/
│   │   │   ├── ally_behavior_tree.dart (765!) Ally decision tree
│   │   │   └── tactical_positioning.dart(517!) Movement/positioning AI
│   │   └── effects/                 Visual effect overlays
│   ├── rendering3d/
│   │   ├── mesh.dart                (615!) Geometry container + factories
│   │   ├── ley_lines.dart           (606!) Ley line rendering
│   │   ├── terrain_lod.dart         (537!) Terrain LOD system
│   │   ├── texture_manager.dart     (474)  WebGL texture loading
│   │   ├── camera3d.dart            (350)  3D camera system
│   │   ├── webgl_renderer.dart      (400)  Core WebGL engine
│   │   └── shaders/                 GLSL shader programs
│   └── models/
│       ├── monster_ontology.dart    Monster type system
│       └── target_dummy.dart        DPS test target
├── assets/data/                     JSON config files (stance, minimap, wind, mana, items)
├── config/                          Game config + UI config
├── personalities/                   NPC AI personality prompts
└── tests/                           Flutter tests
```

**Files marked with (!) exceed the 500-line limit and are candidates for splitting.**

## OVERSIZED FILES - Split Roadmap

14 files currently exceed the 500-line limit. Priority splits:

| File | Lines | Split Strategy |
|------|-------|---------------|
| `ability_system.dart` | 2987 | 4 files: execution core, implementations, interactions, effects |
| `game3d_widget.dart` | 2573 | 5 files: core, initializer, input, ally commands, UI builder |
| `game_state.dart` | 2467 | 3 files: core, mana/effects, world entities |
| `abilities_modal.dart` | 1801 | 3 files: core scaffold, ability list, filters/editor |
| `ai_system.dart` | 1251 | 2 files: monster AI, ally AI |
| `ability_editor_panel.dart` | 1029 | 2 files: core editor, field builders |
| `combat_hud.dart` | 880 | 2 files: layout, individual frame widgets |
| `combat_system.dart` | 876 | 2 files: damage pipeline, effect application |
| `ally_behavior_tree.dart` | 765 | 2 files: tree nodes, behavior execution |
| `macro_builder_panel.dart` | 737 | 2 files: panel scaffold, step editors |
| `stance_editor_panel.dart` | 651 | OK for now (close to limit) |
| `mesh.dart` | 615 | 2 files: core mesh, mesh factories |
| `ley_lines.dart` | 606 | 2 files: manager, rendering |
| `minion_frames.dart` | 592 | OK for now (close to limit) |

## Key Architecture Patterns

### Configuration-Driven Values
All tunable values live in JSON configs, loaded at startup, editable at runtime via Settings panel. Pattern: `GlobalConfig? globalXConfig;` → initialized in `game3d_widget.initState()`.

### Game Loop
`game3d_widget._update(dt)` runs every frame:
1. Input processing (movement, camera)
2. Physics (gravity, flight, wind)
3. Ability system update (cooldowns, casts, effects)
4. AI system update (monster + ally decisions)
5. Mana regeneration
6. Combat system (damage, DoTs)
7. Minimap update
8. Macro system update
9. UI rebuild via `setState()`

### State Management
Single `GameState` object holds all game state. No Riverpod/Provider for game logic - only for app-level config. Systems read/write GameState directly.

### Rendering Pipeline
Custom WebGL (NOT Flame's 2D renderer). See `RENDERING_PIPELINE.md`. Key path:
`game3d_widget.dart` → `render_system.dart` → `webgl_renderer.dart` → `camera3d.dart` + `mesh.dart`

### UI Panels
All major UI panels are draggable via `_draggable()` helper in game3d_widget. Visibility controlled by `InterfaceConfigManager` in `interface_config.dart`. Toggled via keyboard shortcuts (P=codex, C=character, B=bag, M=minimap, etc.).

## Dependencies
- **flame**: Game engine (used minimally - mostly custom WebGL)
- **flutter_riverpod**: State management (app-level only)
- **shared_preferences**: Persistent storage (configs, overrides, positions)
- **http**: Ollama AI API communication
