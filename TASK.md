# Task Tracking

## Current Tasks

### ✅ Completed - 2026-02-12

#### Minimap Rotation Fix (Rotating Minimap)
- ✅ Converted minimap from fixed-north to player-relative rotating view (forward = always up, like WoW)
- ✅ Updated `minimap_terrain_painter.dart` — added `playerRotation` param, rotates pixel-to-world sampling so terrain rotates with player, rotates ley line coordinate conversion, `shouldRepaint` triggers on rotation change
- ✅ Updated `minimap_entity_painter.dart` — rotates `_worldToMinimap` coordinates by player facing, simplified `_drawPlayerArrow` to always point up (no rotation needed in rotating minimap)
- ✅ Updated `minimap_ping_overlay.dart` — added `playerRotation` param, rotates ping coordinate conversion
- ✅ Updated `minimap_widget.dart` — passes `playerRotation` to terrain and ping painters, updated `_handleTap` to un-rotate tap coordinates back to world space
- ✅ Fixes: turning left on screen now rotates minimap correctly (entities to your left appear on the left), arrow always points forward, no more mirrored sensing
- ✅ Build verified clean (`flutter build web`)

#### Minimap Improvements
- ✅ Made minimap draggable using `_draggable()` pattern (same as all other panels), default position top-right
- ✅ Fixed player arrow direction — rotated 180 degrees so it points in the direction the player is facing
- ✅ Made player arrow bright white with black shadow outline for better visibility (was faint silver with transparent glow)
- ✅ Fixed terrain coverage when zoomed out — uses `SimplexNoise` directly as fallback for unloaded chunks beyond render distance, terrain now fills entire circular minimap at all zoom levels
- ✅ Build verified clean (`flutter build web`)

#### Categorized Interface Settings
- ✅ Added `category` and `shortcutKey` fields to `InterfaceConfig` class (constructor, copyWith, toJson)
- ✅ Removed 4 stale registrations (formation_panel, attack_panel, hold_panel, follow_panel) replaced by unified AllyCommandsPanel
- ✅ Added 5 new registrations: abilities_codex (P), character_panel (C), bag_panel (B), dps_panel (SHIFT+D), ally_commands (F)
- ✅ Assigned all 12 interfaces to categories: `game_abilities` (3 items) and `ui_panels` (9 items)
- ✅ Added category query methods to `InterfaceConfigManager` (categories, categoryLabel, interfacesForCategory)
- ✅ Created `lib/game3d/ui/settings/interfaces_tab.dart` — extracted InterfacesTab widget with categorized sections, shortcut key badges, expand/collapse details
- ✅ Updated `settings_panel.dart` — delegates to InterfacesTab, removed ~250 lines of extracted code (847→485 lines)
- ✅ Wired `_isVisible()` into all modal rendering conditions in `game3d_widget.dart` (minimap, character, ally commands, abilities, bag, DPS)
- ✅ Wired `_isVisible()` into all keyboard handlers (P, C, B, M, F, SHIFT+D) — disabled interfaces block their shortcut keys
- ✅ Removed stale `_defaultPositions` entries (formation_panel, attack_panel, hold_panel, follow_panel)
- ✅ All files under 500 lines (interfaces_tab: 389, settings_panel: 485, interface_config: 394)
- ✅ Build verified clean (`flutter build web`)

#### Minimap System
- ✅ Created `assets/data/minimap_config.json` — all minimap tuning values (terrain, entities, zoom, suns, pings, clock, wind)
- ✅ Created `lib/game3d/state/minimap_config.dart` — config class following WindConfig pattern with dot-notation getters, global singleton
- ✅ Created `lib/game3d/state/minimap_state.dart` — state class with zoom levels, active pings, elapsed time, terrain cache, MinimapPing class, PingType enum
- ✅ Created `lib/game3d/ui/minimap/minimap_widget.dart` — top-level 160px circular minimap with terrain/entity/ping layers, click-to-ping, clock widget
- ✅ Created `lib/game3d/ui/minimap/minimap_terrain_painter.dart` — CustomPainter sampling heightmap, height-to-color mapping (sand/grass/rock), ley line segments and power nodes
- ✅ Created `lib/game3d/ui/minimap/minimap_entity_painter.dart` — CustomPainter for player arrow (silver triangle), allies (green), enemies (red), boss (large red), target dummy (yellow X)
- ✅ Created `lib/game3d/ui/minimap/minimap_border_icons.dart` — 3 orbiting sun icons (Solara/Kethis/Umbris), zoom +/- buttons, wind direction arrow on border (absorbs WindIndicator)
- ✅ Created `lib/game3d/ui/minimap/minimap_ping_overlay.dart` — expanding concentric ring animation on minimap + world-space diamond ping via worldToScreen(), off-screen edge arrows
- ✅ Added `MinimapState minimapState` and `minimapOpen` to `game_state.dart`
- ✅ Wired minimap into `game3d_widget.dart` — config init, update loop, M key toggle, replaced WindIndicator with MinimapWidget, added MinimapPingWorldOverlay
- ✅ Registered `'minimap'` interface in `interface_config.dart`
- ✅ All values config-driven via `minimap_config.json` — nothing hardcoded
- ✅ All new files under 500 lines (config: 214, state: 129, widget: 227, terrain: 206, entity: 200, border: 259, ping: 262)
- ✅ Build verified clean (`flutter build web`)

### ✅ Completed - 2026-02-11

#### Wind Trail Effects + Derecho Storms
- ✅ Added wind trail rendering: particles now render as elongated streaks aligned with wind direction (configurable length/width in `wind_config.json`)
- ✅ Added `trails` config section to `wind_config.json` — `enabled`, `length` (1.2), `width` (0.08)
- ✅ Added `derecho` config section to `wind_config.json` — `averageInterval` (300s), `durationMin/Max` (30-60s), `strengthMultiplier` (10x), `manaRegenMultiplier` (10x), `visualMultiplier` (10x), `rampUpTime/rampDownTime` (5s), `color`
- ✅ Added trail + derecho getters to `wind_config.dart` (including `_resolveBool` helper)
- ✅ Added derecho state to `wind_state.dart` — `isDerechoActive`, `derechoIntensity` (smooth ramp), `effectiveWindStrength` (10x during derecho), `derechoManaMultiplier`, `derechoVisualMultiplier`, random Poisson trigger after half-interval
- ✅ Wind vector, movement modifier, and exposure level now use `effectiveWindStrength` for derecho amplification
- ✅ Movement modifier clamped to 0.1 minimum so player can crawl against derecho headwind
- ✅ Rewrote `wind_particles.dart` — pre-allocates particle pool at max (normal * 10x), active count scales with derecho, trail quads aligned to wind direction, color lerps to derecho palette during storms
- ✅ Applied `derechoManaMultiplier` to white mana regen in `game_state.dart` `updateWindAndWhiteMana()`
- ✅ Updated `wind_indicator.dart` — shows "DERECHO" warning label with pulsing orange/red border, arrow transitions to orange, strength display shows >100% during storms
- ✅ Direction drift speed increases 3x during derecho for chaotic wind feel
- ✅ All values config-driven via `wind_config.json` — nothing hardcoded
- ✅ Build verified clean (`flutter build web`)

#### Double-Click to Edit Bag Items
- ✅ Added edit mode to `ItemEditorPanel` — `existingItem`, `existingItemIndex`, `onItemSaved` parameters
- ✅ Editor populates all controllers from existing item in `initState`
- ✅ Added `_onSave()` (preserves item ID) and `_onRevert()` (resets all fields to original) methods
- ✅ Header shows "EDIT ITEM" / edit icon vs "NEW ITEM" / add icon
- ✅ Footer shows "Save" / "Revert" in edit mode vs "Create" / "Cancel" in create mode
- ✅ Added double-click (`onDoubleTap`) to bag slots in `bag_panel.dart`
- ✅ Replaced `_isEditorOpen` with `_editingItem`, `_editingItemIndex`, `_isCreatingNew` state
- ✅ Editor panel uses `ValueKey` on item ID for proper rebuild when switching items
- ✅ `onItemSaved` callback updates inventory via `setBagItem` and closes editor
- ✅ Build verified clean (`flutter build web`)

#### Wind Visibility, Regen Doubling, Per-Color Mana Item Stats
- ✅ Increased wind particle count from 60 to 150, size from 0.08 to 0.25, alpha from 0.3 to 0.6 in `wind_config.json`
- ✅ Added `particleSize` getter to `wind_config.dart`, updated `wind_particles.dart` to read size from config
- ✅ Doubled wind regeneration rate: `windExposureRegen` 2.5 → 5.0
- ✅ Replaced single `mana` field in `ItemStats` with 6 per-color fields: `maxBlueMana`, `maxRedMana`, `maxWhiteMana`, `blueManaRegen`, `redManaRegen`, `whiteManaRegen`
- ✅ Updated `inventory.dart` `totalEquippedStats` to sum new fields
- ✅ Added MANA section to item editor panel with 6 new fields (3 max mana + 3 regen)
- ✅ Added tooltips for all 6 new mana fields in `item_editor_fields.dart`
- ✅ Updated `game_state.dart` max mana getters to include equipped item bonuses
- ✅ Wired per-color mana regen bonuses into `updateManaRegen()` and `updateWindAndWhiteMana()`
- ✅ Updated `item_config.dart` power calculation to use per-color mana fields
- ✅ Migrated existing items (`orb_of_power`, `ring_of_wisdom`) from `mana` to `maxBlueMana`
- ✅ Build verified clean (`flutter build web`)

#### Wind Walker Class: Abilities + Flight System
- ✅ Added `flight` section to `assets/data/wind_config.json` — all flight tuning values (speed, pitch, boost, brake, mana drain, thresholds)
- ✅ Added flight getters to `lib/game3d/state/wind_config.dart` — 11 config-driven flight parameters
- ✅ Created `lib/game3d/data/abilities/windwalker_abilities.dart` — 10 Wind Walker abilities (5 movement, 5 non-movement)
- ✅ Registered 'windwalker' category in `abilities.dart` — export, import, categories, getByCategory, potentialAbilities, categoryCounts
- ✅ Added Wind Walker abilities to `action_bar_config.dart` ability lookup
- ✅ Added flight state to `game_state.dart` — isFlying, flightPitchAngle, flightSpeed, flightAltitude, startFlight/endFlight/toggleFlight
- ✅ Added flight mana drain + low-mana descent + forced landing to `updateWindAndWhiteMana()`
- ✅ Added Sovereign of the Sky buff timer to game state
- ✅ Flight bypass in `physics_system.dart` — skip gravity, apply pitch-based altitude, ground collision ends flight
- ✅ Flight controls in `input_system.dart` — W=pitch up, S=pitch down, auto-level, ALT=boost, Space=brake, Q/E disabled
- ✅ Added `sprint` action to `game_action.dart` bound to Left Alt
- ✅ Added 10 Wind Walker ability handlers in `ability_system.dart` — Gale Step, Zephyr Roll, Tailwind Retreat, Flying Serpent Strike, Take Flight, Cyclone Dive, Wind Wall, Tempest Charge, Healing Gale, Sovereign of the Sky
- ✅ Created `lib/game3d/ui/flight_buff_icon.dart` — pulsing wing icon with altitude readout, red tint on low mana
- ✅ Wired FlightBuffIcon into `combat_hud.dart` above player UnitFrame when flying
- ✅ All flight parameters config-driven via wind_config.json — nothing hardcoded
- ✅ Build verified clean (`flutter build web`)
- ✅ New files under 500 lines (windwalker_abilities: 202, flight_buff_icon: 128)

### ✅ Completed - 2026-02-10

#### Wind Effects System: Foundation + Unit Movement
- ✅ Created `assets/data/wind_config.json` — all tuning values (wind drift, White Mana, movement, projectile, particles)
- ✅ Created `lib/game3d/state/wind_config.dart` — config loader following ManaConfig pattern
- ✅ Created `lib/game3d/state/wind_state.dart` — wind simulation with layered sine wave drift (no sudden jumps)
- ✅ Created `lib/game3d/rendering/wind_particles.dart` — batched particle system rendered in Effects pass
- ✅ Created `lib/game3d/ui/wind_indicator.dart` — HUD wind compass (top-right corner)
- ✅ Added `white` to `ManaColor` enum in `ability_types.dart`
- ✅ Added White Mana fields + `updateWindAndWhiteMana()` to `game_state.dart` (regen from wind exposure, decay when sheltered)
- ✅ Added White Mana bar (silver-white gradient) to `mana_bar.dart` with wind exposure info
- ✅ Applied wind movement modifier to player (`input_system.dart`), allies, and minions (`ai_system.dart`)
- ✅ Applied wind force to all projectile types (player, ally, minion, monster)
- ✅ Updated `ability_system.dart` for white mana cost checking, spending, and deferred spending
- ✅ Wired wind particles into `render_system.dart` Effects pass
- ✅ Initialized WindConfig + WindState globals in `game3d_widget.dart`
- ✅ Added WindIndicator widget to HUD Stack
- ✅ Registered `wind_config.json` in `source-tree.json`
- ✅ All values config-driven — nothing hardcoded
- ✅ All files under 500 lines

#### Item Editor Panel: "+ Add New Item" for Bag Panel
- ✅ Created `assets/data/item_config.json` with power level weights, rarity bonuses, sentience thresholds
- ✅ Created `lib/game3d/state/item_config.dart` — config loader + power calculator (ManaConfig pattern)
- ✅ Created `lib/game3d/state/custom_item_manager.dart` — persistence manager (CustomAbilityManager pattern)
- ✅ Created `lib/game3d/ui/item_editor_panel.dart` — side panel UI with 6 sections
- ✅ Created `lib/game3d/ui/item_editor_fields.dart` — shared field widgets and power/sentience section
- ✅ Added `ItemSentience` enum + extension to `item.dart` with fromJson/toJson/copyWithStackSize support
- ✅ Added "+ ADD NEW ITEM" button and Row layout with conditional editor panel to `bag_panel.dart`
- ✅ Wired `onItemCreated` callback through `game3d_widget.dart` to add items to inventory
- ✅ Initialized `ItemConfig` and `CustomItemManager` global singletons in `game3d_widget.dart`
- ✅ Power level bar with gradient fill, 3-way sentience toggle gated by config thresholds
- ✅ Type dropdown changes available slot options; stack fields only for consumable/material
- ✅ All tuning values in JSON config — nothing hardcoded
- ✅ Build verified clean, all files under 500 lines

#### Character Panel Equipment Rearrangement + Bag Drag-to-Equip + Talisman Slot
- ✅ Added `talisman` to `EquipmentSlot` enum with `canAcceptItem()` slot validation helper (ring interchangeability)
- ✅ Expanded bag from 24 to 60 slots, added `equipToSlot()` method to Inventory
- ✅ Replaced Stack/Positioned silhouette layout with Column-based: Helm → Cube → Row1 (5 armor slots) → Row2 (rings/weapons/talisman)
- ✅ Made equipment slots `DragTarget<Item>` with green glow on valid hover
- ✅ Wired `_handleEquipFromBag` callback in CharacterPanel (removes from bag, equips, returns displaced item)
- ✅ Made bag items `Draggable<Item>` with feedback widget and `onDragEnd` safe removal
- ✅ Added Amulet of Fortitude talisman item to items.json and starting inventory
- ✅ Passed `onItemEquipped` refresh callback through game3d_widget.dart
- ✅ Build verified clean, all files under 500 lines

#### Equipment Drag-to-Bag, Rich Tooltips, Game Attribute System
- ✅ Replaced item stats (strength/agility/intelligence/stamina/spirit) with game attributes (Brawn/Yar/Auspice/Valor/Chuff/X/Zeal)
- ✅ Converted all Stamina values to Health in items.json (merged with existing health bonuses)
- ✅ Made `playerMaxHealth` a dynamic getter: `basePlayerMaxHealth + totalEquippedStats.health`
- ✅ Health delta tracking on equip/unequip adjusts current health proportionally
- ✅ Made equipped items `Draggable<EquipmentDragData>` for drag-to-bag unequipping
- ✅ Added `DragTarget<EquipmentDragData>` to BagPanel with gold highlight on valid hover
- ✅ Created shared rich tooltip (`buildItemTooltip`) used by both equipment slots and bag slots
- ✅ Added `EquipSlotHover` stateful widget for hover-triggered tooltip on equipment slots
- ✅ Extracted tooltip into `item_tooltip.dart` to keep files under 500 lines
- ✅ Fixed fallback items in `item_database.dart` to use new attribute names
- ✅ Build verified clean, all files under 500 lines

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

#### Bug Fix: Startup Script & Performance (Completed 2026-02-04)
**Task**: Fix project startup crash caused by script issues and excessive UI rebuilds
- ✅ Fixed start.sh script to correctly locate Flutter project
  - Was checking for pubspec.yaml in `/warchief/` instead of `/warchief/warchief_game/`
  - This caused `flutter create` to run on every startup, interfering with build cache
  - Updated script to properly detect GAME_DIR before checking for pubspec.yaml
- ✅ Made Game3D widget const in main.dart
  - Prevents unnecessary widget recreation during parent rebuilds
  - Changed `Game3D()` to `const Game3D()`
- ✅ Added debouncing to interface config updates
  - `onConfigChanged` was triggering setState on every drag frame (~60x/second)
  - Added `_scheduleConfigUpdate()` that batches updates using `addPostFrameCallback`
  - Reduces rebuild frequency to once per animation frame maximum
- **Root Cause**: Every panel drag caused excessive GameScreen rebuilds due to direct setState in onConfigChanged callback, combined with script running `flutter create` on every startup
- **Deliverables**:
  - Updated start.sh (correct project detection)
  - Updated lib/main.dart (const Game3D, debounced callbacks)

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

#### Click-to-Select Unit Targeting (Completed 2026-02-09)
**Task**: Implement left-click targeting of all entity types in the 3D world
- ✅ Extracted shared worldToScreen utility from damage_indicators.dart
  - New file: lib/game3d/utils/screen_projection.dart
  - DamageIndicatorOverlay now uses shared utility (no behavioral change)
- ✅ Created EntityPickingSystem for screen-space entity picking
  - Projects all entities (boss, minions, allies, target dummy) to screen coords
  - Finds closest entity to click within configurable radius
  - New file: lib/game3d/systems/entity_picking_system.dart
- ✅ Added GameConfig.clickSelectionRadius = 60.0 pixels
- ✅ Added ally targeting support to GameState
  - getCurrentTarget() returns ally type with entity
  - getDistanceToCurrentTarget() computes distance to ally
  - getTargetOfTarget() returns 'player' for allies
  - validateTarget() handles ally targets
- ✅ Added click-to-select via Listener on game world SizedBox
  - Left-click picks nearest entity within radius
  - Click empty space deselects (clears target)
  - Works alongside existing Tab targeting
- ✅ Added ally target display in CombatHUD
  - Shows ally name, health, green portrait color (0xFF66CC66)
- ✅ Added green target indicator for allies in RenderSystem
  - Ally indicator uses Vector3(0.2, 1.0, 0.2) green color
  - Mesh regenerates on target ID change (for color switching)
- **Keybinds**: Left-click to select, Tab still cycles enemies, ESC clears
- **Deliverables**:
  - lib/game3d/utils/screen_projection.dart (new shared utility)
  - lib/game3d/systems/entity_picking_system.dart (new picking system)
  - Updated lib/game3d/ui/damage_indicators.dart (uses shared utility)
  - Updated lib/game3d/state/game_config.dart (clickSelectionRadius)
  - Updated lib/game3d/state/game_state.dart (ally targeting in 4 methods)
  - Updated lib/game3d/game3d_widget.dart (Listener + _handleWorldClick + ally UI)
  - Updated lib/game3d/systems/render_system.dart (ally indicator + color tracking)

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
