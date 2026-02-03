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
