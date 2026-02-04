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

#### Tab Targeting System (Completed 2026-02-03)
**Task**: Implement WoW-style targeting system with visual indicators
- ✅ Core targeting system in GameState
  - Tab cycles through enemies (cone-based, prioritizing facing direction)
  - Shift+Tab cycles backwards
  - ESC clears current target
  - Target validation (auto-clear when target dies)
  - Sorted by angle from player facing (60° cone priority) then distance
- ✅ Visual target indicator (yellow dashed rectangle)
  - Created Mesh.targetIndicator factory (8 dashes, 1/3 side length each)
  - Rendered at base of targeted enemy
  - Size scales with target's size
- ✅ Dynamic UI based on current target
  - CombatHUD shows current target's info (name, health, level)
  - Target Frame panel shows detailed target info with abilities
  - Portrait color matches target type (boss=purple, minion archetype colors)
- ✅ Target-of-Target display
  - Shows who the current target is targeting
  - Warning indicator when target is targeting the player
- ✅ Enemy targeting system
  - Minions track their targets via targetId property
  - DPS, Support, Healer, Tank AI all set appropriate targets
  - Boss always targets player
- **Keybinds**:
  - Tab: Cycle to next enemy target
  - Shift+Tab: Cycle to previous enemy target
  - ESC: Clear target (if no modals open)
- **Deliverables**:
  - Updated lib/game3d/state/game_state.dart (targeting state + methods)
  - Updated lib/rendering3d/mesh.dart (targetIndicator factory)
  - Updated lib/game3d/systems/render_system.dart (target indicator rendering)
  - Updated lib/game3d/systems/ai_system.dart (enemy targetId tracking)
  - Updated lib/game3d/game3d_widget.dart (Tab input, dynamic UI)

#### Minion Frames UI (Completed 2026-02-03)
**Task**: Add minion frames display symmetric to party frames
- ✅ Created MinionFrames widget mirroring PartyFrames design
  - Displays all enemy minions grouped by archetype
  - Shows minion name, health bar, ability cooldown dots
  - AI state indicator (attacking, pursuing, supporting, etc.)
  - Archetype color coding (DPS=red, Support=purple, Healer=green, Tank=orange)
  - Dead minions shown with reduced opacity
  - Alive/total count display in header
- ✅ Positioned symmetrically to party frames
  - Party frames: left of player frame
  - Minion frames: right of boss frame
- ✅ Integrated with interface configuration system
  - Toggleable via Settings > Interfaces
  - Persists visibility state
- **Deliverables**:
  - lib/game3d/ui/unit_frames/minion_frames.dart (~330 lines)
  - Updated lib/game3d/ui/unit_frames/unit_frames.dart (export)
  - Updated lib/game3d/game3d_widget.dart (MinionFrames placement)
  - Updated lib/game3d/ui/settings/interface_config.dart (minion_frames config)

#### Drag-and-Drop Action Bar (Completed 2026-02-03)
**Task**: Implement drag-and-drop ability customization for the action bar
- ✅ Created ActionBarConfig state manager
  - Tracks which abilities are assigned to each action bar slot (1-4)
  - Persists configuration via SharedPreferences
  - Provides slot color lookup from ability data
- ✅ Added draggable ability icons to Abilities Codex
  - Icons match action bar button size (60x60 pixels)
  - Drag feedback shows yellow glow border
  - Hint text "Drag icons to action bar" in header
  - Ability type icons (melee, ranged, heal, buff, etc.)
- ✅ Made action bar buttons accept ability drops
  - DragTarget widgets on each action bar slot
  - Visual feedback when dragging over slot (yellow highlight)
  - Slot color updates to match dropped ability
- ✅ Dynamic ability execution based on slot configuration
  - AbilitySystem.executeSlotAbility() looks up configured ability
  - Support for all ability categories (Player, Warrior, Mage, Rogue, Healer, Nature, Necromancer, Elemental, Utility)
  - Generic handlers for melee, projectile, AoE, and heal abilities
  - Cooldowns properly tracked per slot
- **Usage**:
  - Press P to open Abilities Codex
  - Drag any ability icon to action bar slot
  - Click ability or press hotkey (1-4) to use new ability
- **Deliverables**:
  - lib/game3d/state/action_bar_config.dart (~120 lines)
  - Updated lib/game3d/ui/abilities_modal.dart (draggable icons)
  - Updated lib/game3d/ui/unit_frames/combat_hud.dart (DragTarget slots)
  - Updated lib/game3d/systems/ability_system.dart (~640 lines, dynamic execution)
  - Updated lib/main.dart (ActionBarConfig initialization)
  - Updated lib/game3d/game3d_widget.dart (drop handler integration)

#### Interface Settings System (Completed 2026-02-03)
**Task**: Add UI interface configuration with persistent visibility settings
- ✅ Created InterfaceConfigManager for centralized UI panel configuration
  - Stores visibility states and positions for all toggleable interfaces
  - Supports save/load configuration via SharedPreferences
  - JSON serialization for persistence
  - Callback system for real-time UI updates
- ✅ Added Interfaces tab to Settings panel
  - Expandable list of all configurable interfaces
  - Toggle switches for visibility control
  - Position display and reset functionality
  - "Save Layout" and "Reset All" action buttons
  - Quick action chips: "Show All" and "Hide Optional"
- ✅ Integrated with Game3D widget
  - Visibility controlled by InterfaceConfigManager
  - Local panel state synced with global config
  - All panels (Instructions, AI Chat, Monster Abilities, Party Frames, Command Panels) respect config
  - SHIFT+key toggles update both local state and global config
  - Auto-save on visibility change
- ✅ Configurable interfaces:
  - Combat HUD, Party Frames, Boss Abilities, AI Chat, Instructions
  - Formation Panel, Attack Panel, Hold Panel, Follow Panel
- **Deliverables**:
  - lib/game3d/ui/settings/interface_config.dart (~313 lines)
  - Updated lib/game3d/ui/settings/settings_panel.dart (Interfaces tab)
  - Updated lib/main.dart (InterfaceConfigManager integration)
  - Updated lib/game3d/game3d_widget.dart (visibility checks)

#### Monster Ontology & Minion System (Completed 2026-02-02)
**Task**: Create monster type system with 4 minion archetypes (Ancient Wilds Faction)
- ✅ Created MonsterOntology with comprehensive type definitions
  - MonsterArchetype enum (DPS, Support, Healer, Tank, Boss)
  - MonsterFaction enum (Undead, Goblinoid, Orcish, Cultist, Beast, Elemental, etc.)
  - MonsterSize enum with scale factors (Tiny 0.4x to Colossal 2.0x)
  - MonsterAbilityDefinition for ability properties (damage, healing, buffs, projectiles)
  - MonsterDefinition class with stats, visuals, AI behavior
  - MonsterPowerCalculator for difficulty estimation (1-10 scale)
- ✅ Created 4 minion types (Ancient Wilds/Greek Mythology theme):
  - **Gnoll Marauder** (DPS, MP 4) - Savage hyena pack hunter
    - Rending Bite (melee + bleed debuff, 60s CD)
    - Pack Howl (self-buff +75% damage, 90s CD)
    - Savage Leap (gap closer melee, 75s CD)
  - **Satyr Hexblade** (Support, MP 5) - Fey curse-weaver with enchanted pipes
    - Discordant Pipes (AoE debuff aura -40% enemy damage, 90s CD)
    - Wild Revelry (ally buff +50% attack speed, 75s CD)
    - Cursed Blade (ranged magic projectile + healing debuff, 60s CD)
  - **Dryad Lifebinder** (Healer, MP 6) - Nature spirit healer
    - Nature's Embrace (45 HP heal, 60s CD)
    - Rejuvenation Aura (HoT aura for allies, 120s CD)
    - Entangling Roots (AoE CC immobilize, 90s CD)
    - Bark Shield (40 HP damage absorption, 75s CD)
  - **Minotaur Bulwark** (Tank, MP 7) - Labyrinth guardian
    - Gore Charge (gap closer 30 damage, 60s CD)
    - Intimidating Presence (taunt aura, 90s CD)
    - Labyrinthine Fortitude (self -60% damage taken, 120s CD)
    - Earthshaker (AoE melee + 3s stun, 90s CD)
- ✅ Ability coverage: Melee, Range, Magic, Buffs, Debuffs, Auras, Specialized (CC, Shields)
- ✅ All abilities have 60+ second cooldowns
- ✅ Created Monster runtime class with:
  - MonsterAIState enum for behavior states
  - Ability cooldowns and buff/debuff tracking
  - Combat state management
  - MonsterFactory for instance creation
- ✅ Integrated minions into game systems:
  - Spawn 8 Gnolls, 4 Satyrs, 2 Dryads, 1 Minotaur (15 total, 71 MP)
  - RenderSystem renders minions with direction indicators
  - AISystem handles archetype-specific AI behavior
  - Minion projectiles and damage handling
- **Deliverables**:
  - lib/models/monster_ontology.dart (~200 lines)
  - lib/models/monster.dart (~250 lines)
  - lib/game3d/data/monsters/minion_definitions.dart (~450 lines)
  - Updated lib/game3d/state/game_state.dart (minion spawning)
  - Updated lib/game3d/systems/render_system.dart (minion rendering)
  - Updated lib/game3d/systems/ai_system.dart (~300 lines minion AI)

#### WoW-Style Terrain Texturing (Completed 2026-01-31)
**Task**: Implement WoW-style tile terrain with texture splatting
- ✅ Created TextureManager class for procedural terrain texture generation
  - Generates grass, dirt, rock, sand diffuse textures
  - Generates corresponding normal maps for each terrain type
  - High-frequency detail texture for close-up variation
  - WebGL texture binding and mipmap generation
- ✅ Created terrain splatting shaders (terrain_shaders.dart)
  - Vertex shader with UV coordinates and height/slope calculation
  - Fragment shader with 4-texture blending via splat map
  - Height-based automatic terrain distribution (sand low, grass mid, rock high)
  - Slope-based rock override for steep terrain
  - Normal mapping support
  - Detail texture overlay with distance fade
  - Simplified shader variant for lower LOD levels
  - Debug shader for visualizing splat weights
- ✅ Added UV coordinates and proper normals to terrain mesh (terrain_lod.dart)
  - UV coordinate generation for seamless chunk borders
  - Normal calculation from heightmap gradients using central differences
  - Updated TerrainChunkWithLOD to store splat map data
- ✅ Created SplatMapGenerator for procedural terrain distribution
  - Height-based terrain type weights
  - Slope-based rock override
  - Value noise layers for natural variation
  - Smooth transitions between terrain types
- ✅ Modified WebGLRenderer for texture-based terrain rendering
  - Added initializeTerrainTexturing() method
  - Added renderTerrain() method with multi-texture binding
  - Texture unit management (0-9 for terrain textures + splat map)
  - Fallback to vertex colors when texturing not available
- ✅ Added texture uniforms to ShaderProgram
  - setUniformSampler2D() for texture unit binding
  - setUniformBool() for feature toggles
  - setUniformVector2() for 2D uniforms
- ✅ Updated InfiniteTerrainManager for texture integration
  - Splat map generation per chunk
  - GL context management for texture cleanup
  - Lazy splat map texture creation
- ✅ Extended TerrainConfig with texture settings
  - useTextureSplatting toggle
  - splatMapResolution (default: 16x16)
  - textureScale (default: 4.0)
  - Height/slope thresholds for terrain distribution
  - VRAM usage estimation
- ✅ Integrated into game3d_widget and render_system
  - Async terrain texture initialization
  - Terrain update loop integration
  - renderTerrain() call for texture-splatted rendering
- **Deliverables**:
  - lib/rendering3d/texture_manager.dart (~400 lines)
  - lib/rendering3d/shaders/terrain_shaders.dart (~350 lines)
  - lib/rendering3d/splat_map_generator.dart (~270 lines)
  - Updated lib/rendering3d/terrain_lod.dart (UV + normals)
  - Updated lib/rendering3d/webgl_renderer.dart (terrain rendering)
  - Updated lib/rendering3d/shader_program.dart (texture uniforms)
  - Updated lib/rendering3d/infinite_terrain_manager.dart (splat maps)
  - Updated lib/rendering3d/game_config_terrain.dart (texture config)
  - Updated lib/game3d/game3d_widget.dart (initialization)
  - Updated lib/game3d/systems/render_system.dart (renderTerrain)

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
