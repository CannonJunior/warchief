# Task Tracking

## Current Tasks

### ✅ Completed - 2025-10-29

#### Research & Design Phase
**Task**: Research and design 3D isometric game platform with Flutter/Dart, AI-powered NPCs using Ollama + MCP
- Researched WoW character control systems and documentation
- Researched WoW pet control commands and stances
- Researched Flutter Flame engine for isometric game development
- Researched Model Context Protocol (MCP) integration with Ollama
- Researched local LLM integration for NPC AI control
- Designed comprehensive platform architecture
- Created detailed control scheme specification (WASD, mouse, action bars, keybinds)
- Designed UI configuration system supporting SVG/PNG assets
- Created 18-week implementation plan
- Documented MCP tool definitions and AI integration patterns
- **Deliverables**:
  - PLATFORM_DESIGN.md (comprehensive architecture document)
  - QUICK_START.md (developer quick reference)
  - Updated CLAUDE.md (port changed from 8888 to 8008)

#### Phase 1 Setup (Started 2025-10-29)
**Task**: Set up Flutter web project with Flame engine
- ✅ Created start.sh script with port 8008 checking/killing
- ✅ Initialized Flutter project with web platform
- ✅ Set up pubspec.yaml with all dependencies (Flame, Riverpod, etc.)
- ✅ Created complete project directory structure (lib/game, lib/ui, lib/ai, etc.)
- ✅ Created game configuration files (game_config.json, ui_config.json)
- ✅ Created sample NPC personality file (warrior_companion.txt)
- ✅ Implemented basic WarchiefGame class with Flame
- ✅ Created main.dart entry point with Riverpod
- ✅ Added development overlay UI with control hints
- ✅ Tested and verified server runs on port 8008
- **Deliverables**:
  - start.sh (automated startup script)
  - warchief_game/ (complete Flutter project)
  - README.md (project overview)
  - Working game skeleton running on http://localhost:8008

#### Phase 1 Core Features (Completed 2025-10-29)
**Task**: Implement core game infrastructure with WASD movement, camera, and isometric rendering
- ✅ Created GameAction enum with all keybindable actions
- ✅ Implemented InputManager with keybind support
  - Continuous action callbacks (for movement)
  - One-time action callbacks (for jump, etc.)
  - Key rebinding system (ready for UI)
  - Default keybindings loaded from GameAction
- ✅ Implemented PlayerCharacter component
  - WASD movement (forward, backward, strafe)
  - Q/E rotation controls
  - Space bar jump with animation
  - Velocity-based movement system
  - Boundary enforcement
  - Health tracking (ready for combat)
- ✅ Implemented CameraController
  - Smooth camera following
  - Mouse drag for camera rotation
  - Scroll wheel for zoom (min 0.5x, max 2.0x)
  - Right-click drag support
  - Camera offset and smoothing
- ✅ Implemented IsometricMap renderer
  - 20x20 tile grid
  - Diamond-shaped isometric tiles
  - Checkerboard pattern for visibility
  - Grid-to-screen coordinate conversion
  - Custom painter for tile rendering
- ✅ Integrated all components in WarchiefGame
  - Full keyboard/mouse event handling
  - Camera follows player
  - All systems working together
  - FPS counter and control hints overlay
- **Deliverables**:
  - lib/models/game_action.dart
  - lib/game/controllers/input_manager.dart
  - lib/game/controllers/camera_controller.dart
  - lib/game/components/player_character.dart
  - lib/game/world/isometric_map.dart
  - Updated lib/game/warchief_game.dart (fully integrated)
  - Fully playable game with WASD movement on isometric map!

## Upcoming Tasks

### Phase 1: Core Infrastructure (Weeks 1-2) - ✅ COMPLETED
- [x] Set up Flutter web project with Flame engine
- [x] Implement isometric tile rendering with Flame Isometric
- [x] Create basic player character with WASD movement
- [x] Implement camera controller with mouse controls
- [x] Build input manager with keybind support

### Phase 2: UI System (Weeks 3-4)
- [ ] Design and implement UI configuration system
- [ ] Create asset-based UI components (action bars, health bars)
- [ ] Implement SVG/PNG loading and hot-reload
- [ ] Build keybind settings screen
- [ ] Create player portrait and resource bars

### Phase 3: Basic Combat & Actions (Weeks 5-6)
- [ ] Implement action bar system with 12 slots
- [ ] Create ability framework (cooldowns, costs, effects)
- [ ] Add basic enemies and combat mechanics
- [ ] Implement health/damage system
- [ ] Add animations for abilities and combat

### Phase 4: NPC Direct Control (Weeks 7-8)
- [ ] Create NPC follower component
- [ ] Implement WoW-style pet commands (Attack, Follow, Stay)
- [ ] Add stance system (Passive, Defensive, Aggressive)
- [ ] Build NPC UI frames and action bars
- [ ] Create NPC behavior tree for direct control mode

### Phase 5: Ollama + MCP Integration (Weeks 9-11)
- [ ] Set up local Ollama server integration
- [ ] Implement MCP client in Dart
- [ ] Create personality system (load from files)
- [ ] Build game state context serialization
- [ ] Define MCP tools (move, attack, use_ability, etc.)
- [ ] Test with Llama 3.1 8B for function calling

### Phase 6: Intent-Based AI Control (Weeks 12-14)
- [ ] Implement intent interpretation system
- [ ] Create high-level command parser
- [ ] Build AI decision-making loop
- [ ] Add context-aware behavior
- [ ] Test different personality profiles
- [ ] Optimize LLM prompts for game performance

### Phase 7: Advanced Features (Weeks 15-16)
- [ ] Add multiple NPC support (party system)
- [ ] Implement NPC progression (leveling, new abilities)
- [ ] Create quest/objective system
- [ ] Add NPC-to-NPC interactions
- [ ] Build formation system for multiple NPCs

### Phase 8: Polish & Optimization (Weeks 17-18)
- [ ] Optimize web build performance
- [ ] Add sound effects and music
- [ ] Implement save/load system
- [ ] Polish UI/UX
- [ ] Performance testing with multiple NPCs
- [ ] Documentation and tutorials

## Notes

- Project uses **port 8008** (not 8888)
- Always use **uv** instead of pip for package management
- All new directories need CLAUDE.md with port 8008 requirement
- Create Pytest unit tests for all new features
- Never create files longer than 500 lines - refactor instead
- Use venv_linux for Python commands

## Discovered During Work

- Need to create config directory structure (config/game_config.json, config/ui_config.json)
- Need to create personalities directory for NPC personality files
- Should set up asset pipeline early (assets/ui/, assets/sprites/, etc.)
- Consider creating utility scripts for asset validation
- May need to create custom Flame components for isometric rendering
