# Task Tracking

## Current Tasks

### ✅ Completed - 2026-02-16

#### Green Mana System + Dual-Mana Abilities + 3 New Character Classes
- ✅ Added `green` to `ManaColor` enum, added `secondaryManaColor`/`secondaryManaCost` dual-mana fields to `AbilityData` (constructor, copyWith, toJson, fromJson, applyOverrides, getters)
- ✅ Added green mana fields to `GameState` (greenMana, maxGreenMana, regen rate, spirit form, spend/has/generate methods, active character delegates)
- ✅ Added green mana fields to `Ally` model (greenMana, maxGreenMana, inSpiritForm)
- ✅ Added `maxGreenMana`/`greenManaRegen` to `ItemStats` (item.dart, inventory.dart)
- ✅ Added green mana config to `mana_config.dart` (8 getters) and `mana_config.json` (grass regen, proximity, spirit being, decay)
- ✅ Implemented `updateGreenManaRegen(dt)` — grass-based regen, proximity regen from green-attuned allies, spirit being regen bonus, decay logic
- ✅ Updated `ability_system.dart` — added `green` to `_ManaType`, dual-mana check/spend logic, 30 new ability handlers (spiritkin/stormheart/greenseer)
- ✅ Created `spiritkin_abilities.dart` (10 abilities: green+red primal nature warriors)
- ✅ Created `stormheart_abilities.dart` (10 abilities: white+red lightning warriors)
- ✅ Created `greenseer_abilities.dart` (10 abilities: green druidic oracle-healers)
- ✅ Updated `abilities.dart` registry with new categories, imports, exports, getByCategory, potentialAbilities, categoryCounts
- ✅ Updated `action_bar_config.dart` — added new ability classes to search list
- ✅ Updated `mana_bar.dart` — green mana bar display with nature regen info widget
- ✅ Updated `aura_system.dart` — spiritkin/stormheart/greenseer category colors
- ✅ Updated `abilities_modal.dart` — new category colors in `_getCategoryColor`
- ✅ Updated `ability_editor_panel.dart` — secondary mana color dropdown + secondary mana cost field
- ✅ Created `green_mana_sparkles.dart` — arc-sparkle particle system between mana sources and green mana users
- ✅ Updated `render_system.dart` — green sparkle rendering with attunement visibility gating
- ✅ Added Talisman of Growth to `items.json` (rare, green attunement, +30 maxGreenMana, +2 regen)
- ✅ Updated All-Source Talisman to include green attunement + maxGreenMana
- ✅ Added Talisman of Growth to sample items in `game_state.dart`
- ✅ Wired `updateGreenManaRegen(dt)` into game loop in `game3d_widget.dart`

#### Talisman-Based Mana Attunement System
- ✅ Added `manaAttunement` field (`List<ManaColor>`) to `Item` model — fromJson parses string array, toJson serializes, copyWithStackSize passes through
- ✅ Added `manaAttunements` getter to `Inventory` — scans equipped items and collects all mana colors
- ✅ Added `temporaryAttunements` field (`Set<ManaColor>`) to `Ally` model — for future buff/aura attunements
- ✅ Added `temporaryAttunements`, `playerManaAttunements`, `activeManaAttunements` to `GameState` — unified attunement getters for Warchief and active ally
- ✅ Added 4 talisman items to `items.json`: All-Source Talisman (legendary, all 3 colors), Talisman of the Ley (rare, blue), Talisman of Blood (rare, red), Talisman of the Wind (rare, white)
- ✅ Equipped All-Source Talisman on Warchief starting equipment, placed 3 single-color talismans in bag
- ✅ Gated player blue/red mana regen behind attunement checks in `updateManaRegen()`
- ✅ Gated player white mana regen/decay behind attunement check in `updateWindAndWhiteMana()`
- ✅ Gated ally blue/red/white mana regen behind per-ally attunement checks
- ✅ Added attunement gate in `ability_system.dart` `_executeAbilityByName()` — blocks mana abilities when not attuned to required color
- ✅ Updated `ManaBar` widget — only shows mana bars for attuned colors, gates info widgets (wind/ley line/power node) behind attunement, shows "No Mana Attunement" when empty
- ✅ Existing `amulet_of_fortitude` unchanged (defensive-only talisman, no attunement)
- ✅ Physical abilities (ManaColor.none, manaCost 0) work without any talisman
- ✅ Build verified clean (`flutter build web`)

#### Performance Optimizations
- ✅ Cached `AbilityRegistry.findByName` — results stored in `Map<String, AbilityData?>` so repeated lookups (every frame in buff/debuff icons) are O(1) instead of linear scans
- ✅ Fixed ley line mesh cache hash — now hashes segment endpoint coordinates instead of just count, preventing stale mesh when segments shift but count stays the same
- ⬜ Cooldown list refactor — replace 10 individual `abilityNCooldown` fields with a `List<double>` (147 references across 7 files, deferred to next session)
- ✅ Added `_minionIndex` map to `GameState` for O(1) minion lookup by `instanceId` — used by `currentTargetActiveEffects` instead of linear scan
- ✅ Added terrain color cache to `MinimapTerrainPainter` — static `List<Color>` grid only recomputed when player position/rotation/zoom changes, eliminating redundant height sampling and color interpolation on unchanged frames
- ✅ Build verified clean (`flutter build web`)

#### Buff/Debuff Icon Fixes & Ability Icon System
- ✅ Fixed CombatHUD target debuff icons — now shows effects for the actual current target (boss, minion, ally) instead of always showing boss effects via new `currentTargetActiveEffects` getter on `GameState`
- ✅ Created ability icon system — added `AbilityTypeIcon` extension on `AbilityType` in `ability_types.dart` with `.icon` getter, plus `typeIcon` and `flutterColor` getters on `AbilityData`
- ✅ Updated `BuffDebuffIcons` to look up source ability via `AbilityRegistry.findByName(effect.sourceName)` and use the ability's type icon and color instead of the `StatusEffect` mapping
- ✅ Updated `MinionFrames._buildBuffIndicators` to use the same ability icon lookup for active effects
- ✅ Consolidated Codex: replaced private `_getAbilityTypeIcon` in `abilities_modal.dart` with shared `ability.type.icon` extension
- ✅ Added mouse-over tooltips showing ability name to icons in both `BuffDebuffIcons` and `MinionFrames`
- ✅ Build verified clean (`flutter build web`)

#### Cast Time Fix, Haste & Melt Attributes
- ✅ Fixed cast/windup time accuracy — clamped `castProgress` to `currentCastTime` on completion so logged duration matches configured time exactly (previously overshot by up to one frame ~16ms)
- ✅ Added combat log entries for cast and windup completions — logged as `CombatLogType.ability` with source `'Player'` and duration in action text
- ✅ Added `haste` and `melt` integer fields to `ItemStats` — fromJson, toJson, nonZeroStats, totalEquippedStats all updated
- ✅ Added `activeHaste` and `activeMelt` getters to `GameState` — reads from active character's equipped item stats
- ✅ Applied Haste to `_startCastTimeAbility` and `_startWindupAbility` — formula: `baseTime / (1 + haste/100)` (100% Haste halves a 2s cast to 1s)
- ✅ Applied Melt to `_setCooldownForSlot` — formula: `baseCooldown / (1 + melt/100)` (same scaling as Haste)
- ✅ Build verified clean (`flutter build web`)

#### Attunement Settings Toggles
- ✅ Created `lib/game3d/state/gameplay_settings.dart` — `GameplaySettings` class with `attunementRequired` and `manaSourceVisibilityGated` booleans, SharedPreferences persistence via `load()`/`save()`
- ✅ Added `globalGameplaySettings` singleton initialized in `game3d_widget.dart` alongside other config singletons
- ✅ Added "Mana Attunement" section to Settings > General tab with two toggles:
  - **Require Mana Attunement** (default ON) — when off, all characters have full access to all mana pools unconditionally (pre-talisman behavior)
  - **Gate Mana Source Visibility** (default OFF) — when on, hides Ley Lines (blue) and wind particles (white) if the active character lacks the corresponding attunement
- ✅ All attunement getters (`playerManaAttunements`, `activeManaAttunements`, ally attunements) return all three colors when `attunementRequired` is disabled
- ✅ Gated 3D Ley Line rendering in `render_system.dart` — hidden when active character is not blue-attuned and visibility toggle is on
- ✅ Gated wind particle rendering in `render_system.dart` — hidden when active character is not white-attuned and visibility toggle is on
- ✅ Gated minimap Ley Line/power node drawing in `minimap_terrain_painter.dart` — hidden by same blue attunement check
- ✅ Added `_buildSectionHeader()` helper to `settings_panel.dart` for styled category headers
- ✅ Settings persist across sessions via SharedPreferences
- ✅ Build verified clean (`flutter build web`)

### ✅ Completed - 2026-02-15

#### Increase Damage Number Size, DoT Damage Display & Combat Log
- ✅ Increased floating combat damage number font size by 50% in `damage_indicators.dart` — melee: 20→30, ranged: 22→33
- ✅ Added `sourceName` field to `ActiveEffect` model — stores the ability name that created the effect for combat log attribution
- ✅ Passed `sourceName` (from `projectile.abilityName`) when creating DoT effects in `_applyDoTFromProjectile()`
- ✅ Added `_logDoTTick()` helper to `GameState` — spawns a floating `DamageIndicator` at the target's world position and adds a `CombatLogEntry` (with ability name and status effect type) for every DoT tick
- ✅ Wired `_logDoTTick()` into all four entity loops in `updateActiveEffects()`: player, boss monster, allies, and minions
- ✅ Build verified clean (`flutter build web`)

#### Fix Custom Ability Colors, Load-to-Action-Bar, Add Type Filter, Fix DoT Ticking
- ✅ Fixed `_buildCustomAbilityCard()` in `abilities_modal.dart` — replaced hardcoded `Colors.green` background/border/star with `_getCategoryColor(ability.category)` so custom abilities in built-in categories show the correct color
- ✅ Fixed `_loadClassToActionBar()` — now combines `AbilityRegistry.getByCategory()` + `globalCustomAbilityManager.getByCategory()` so custom abilities load to action bar alongside built-in ones
- ✅ Fixed `_buildLoadClassRow()` dropdown — count includes custom abilities; custom-only categories appear in dropdown
- ✅ Added `_enabledTypes` set and `_typeFilterExpanded` toggle state to `_AbilitiesModalState`
- ✅ Built `_buildTypeFilter()` — non-scrolling type filter bar below category filter with: type count indicator, All/None quick-toggle, expand/collapse, colored chips per `AbilityType`
- ✅ Built `_buildTypeFilterChip()` — tappable checkbox chips colored by `_getTypeColor()`, toggling type in `_enabledTypes`
- ✅ Applied type filtering to all ability display loops (player, monster, ally, potential, custom category sections)
- ✅ Added DoT fields to `ActiveEffect` model: `damagePerTick`, `tickInterval`, `tickAccumulator`, `isDoT` getter
- ✅ Added status/DoT fields to `Projectile` model: `statusEffect`, `statusDuration`, `dotTicks`
- ✅ Passed DoT fields from `AbilityData` to `Projectile` in `_executeGenericProjectile()`
- ✅ Added `_applyDoTFromProjectile()` — creates `ActiveEffect` with DoT data on target (boss or minion) when projectile hits
- ✅ Wired DoT application in both homing (`_damageTargetWithProjectile`) and non-homing (`checkAndDamageEnemies`) hit paths
- ✅ Updated `updateActiveEffects(dt)` in `game_state.dart` — accumulates tick time per effect; applies `damagePerTick` damage when accumulator reaches `tickInterval` for player, boss, allies, and minions
- ✅ Added `Soul Rot` necromancer DoT ability — `AbilityType.dot`, 60 damage over 5 ticks across 10s, `StatusEffect.poison`, fires projectile that applies DoT `ActiveEffect` on hit
- ✅ Wired `Soul Rot` in `ability_system.dart` — named handler `_executeSoulRot()`, mana cost entry (30 blue), switch case dispatch
- ✅ Fixed ability overrides not persisting to game execution — added `_effective()` helper to `AbilitySystem` that applies `AbilityOverrideManager` overrides; wrapped all ~45 raw ability references (`XxxAbilities.yyy`) with `_effective()`; also applied overrides in generic execution methods (`_executeGenericProjectile`, `_executeGenericMelee`, `_executeGenericAoE`, `_executeGenericHeal`)
- ✅ Build verified clean (`flutter build web`)

#### Buff/Debuff Icons in CombatHUD + Fix Fear Ability
- ✅ Added `StatusEffect.fear` to enum in `ability_types.dart` — causes uncontrolled fleeing
- ✅ Changed Fear ability in `necromancer_abilities.dart` to use `StatusEffect.fear` (was `StatusEffect.stun`)
- ✅ Created `lib/models/active_effect.dart` — `ActiveEffect` class with type, remainingDuration, totalDuration, strength, isBuff/isDebuff, tick(), progress, iconFor(), colorFor()
- ✅ Added `List<ActiveEffect> activeEffects` field to `Ally` model
- ✅ Added `List<ActiveEffect> activeEffects` field to `Monster` model
- ✅ Added `playerActiveEffects`, `monsterActiveEffects` lists to `GameState`
- ✅ Added `updateActiveEffects(double dt)` to `GameState` — ticks and expires effects on player, boss, allies, and minions
- ✅ Wired `updateActiveEffects(dt)` in `game3d_widget.dart` game loop after mana updates
- ✅ Fixed `_executeFear()` in `ability_system.dart` — applies fear ActiveEffect to boss, generates flee BezierPath away from player, logs to combat log
- ✅ Added fear/stun checks in `ai_system.dart` `updateMonsterAI()` — feared monster regenerates flee paths, stunned monster stops movement, both skip normal AI
- ✅ Created `lib/game3d/ui/unit_frames/buff_debuff_icons.dart` — reusable widget showing buff row (top) and debuff row (bottom) with color-coded icons and progress ring overlay
- ✅ Added BuffDebuffIcons to `combat_hud.dart` — LEFT of player frame, RIGHT of target frame
- ✅ Added BuffDebuffIcons to `party_frames.dart` — LEFT of each ally frame (12px icons)
- ✅ Extended `_buildBuffIndicators()` in `minion_frames.dart` — shows active effects from new system alongside existing DMG+/DMG-/DEF indicators
- ✅ Exported `buff_debuff_icons.dart` from `unit_frames.dart` barrel file
- ✅ Build verified clean (`flutter build web`)

#### Add Category Filter to Abilities Codex
- ✅ Added `_enabledCategories` set and `_filterExpanded` toggle state to `_AbilitiesModalState`
- ✅ Added `_getAllCategories()` helper — collects built-in categories from `AbilityRegistry.categories` + custom categories from `globalCustomAbilityManager` + custom options from `globalCustomOptionsManager`
- ✅ Built `_buildCategoryFilter()` — non-scrolling filter bar between header and content with: category count indicator, All/None quick-toggle buttons, expand/collapse toggle
- ✅ Built `_buildFilterChip()` — tappable checkbox chips colored by `_getCategoryColor()`, toggling category in `_enabledCategories`
- ✅ Applied filtering to "CURRENTLY ASSIGNED ABILITIES" — hides player/monster/ally sub-sections when unchecked, hides entire section header when all 3 disabled
- ✅ Applied filtering to "POTENTIAL FUTURE ABILITIES" — skips categories not in `_enabledCategories`
- ✅ Applied filtering to `_buildCustomCategorySections()` — skips custom categories not enabled
- ✅ Build verified clean (`flutter build web`)

#### Fix Custom Ability Double-Click Editing in Abilities Codex
- ✅ Added `ValueKey` to `AbilityEditorPanel` in `abilities_modal.dart` — key based on ability name + isCreatingNew flag forces Flutter to recreate panel state when switching between abilities
- ✅ Fixed `didUpdateWidget` in `ability_editor_panel.dart` — now also checks `isNewAbility` flag changes, not just ability name changes, ensuring fields repopulate when switching between override mode and full-save mode
- ✅ Added `behavior: HitTestBehavior.opaque` to custom ability card `GestureDetector` — ensures double-tap gesture registers across the full card bounds
- ✅ Build verified clean (`flutter build web`)

#### Fix Macro Execution + Combat Log Tab
- ✅ Made `getCooldownForSlot` public in `ability_system.dart` — renamed from `_getCooldownForSlot`, updated internal call site
- ✅ Added pre-checks in `macro_system.dart` `_executeAbilityForCharacter()` — checks cooldown, casting/winding up, and mana cost before calling `executeSlotAbility()`; macro now waits and retries on next frame when ability would fail instead of unconditionally advancing
- ✅ Created `lib/models/combat_log_entry.dart` — `CombatLogType` enum (damage/heal/buff/debuff/death/ability), `CombatLogEntry` class with source, action, type, amount, target, timestamp, formatted time
- ✅ Added `combatLogMessages` list to `game_state.dart`, updated `chatPanelActiveTab` comment to include tab 2
- ✅ Added `_logCombat()` helper to `combat_system.dart` — logs damage events from `checkAndApplyDamage()` with target type resolution, caps at 200 entries
- ✅ Added `_logHeal()` helper to `ability_system.dart` — logs heal events from `_executeHeal()`, `_executeGenericHeal()`, and `_executeGreaterHealEffect()`
- ✅ Created `lib/game3d/ui/combat_log_tab.dart` — `CombatLogTab` widget modeled after `RaidChatTab`, color-coded entries (red=damage, green=heal, yellow=buff, purple=debuff), monospace timestamps, scrollable list
- ✅ Added 3rd "Combat" tab to `chat_panel.dart` — red color scheme (0xFFCC3333), menu_book icon, border color tri-state, tab content routing
- ✅ Wired `combatLogMessages` prop through `game3d_widget.dart` → `ChatPanel`
- ✅ Build verified clean (`flutter build web`)

#### Macro Builder Fix: Ability Execution + Character Name Display
- ✅ Fixed `AbilityRegistry.findByName()` — now searches `PlayerAbilities` (Sword, Fireball, Heal, Dash Attack) first, then potentialAbilities; previously returned null for all Player abilities, silently killing macro execution
- ✅ Fixed `_executeAbilityForCharacter()` — uses `globalActionBarConfigManager.getConfig(characterIndex)` (target character's config) instead of `globalActionBarConfig` (active character's config); prevents wrong-config lookup when active character differs from macro target
- ✅ Restructured macro execution: active character path uses full AbilitySystem (animations/projectiles), non-active allies use direct cooldown+mana, non-active Warchief logs clear error
- ✅ Fixed macro step dropdown — includes `PlayerAbilities.all` so Sword, Fireball, Heal, Dash Attack appear in the ability selector
- ✅ Updated `MacroExecution.getCharacterName()` — matches Character Panel format: `'Warchief · Lv10 Warrior · "The Commander"'`, `'Ally N · LvX Class · "Title"'`
- ✅ Updated macro builder panel `_charName` and running indicator — displays full character identity instead of generic "this character"
- ✅ Build verified clean (`flutter build web`)

#### Spell Rotation & Macro System — Phase 3: Macro Builder UI Panel
- ✅ Added `macroPanelOpen` bool to `game_state.dart` UI STATE section
- ✅ Added `isRunningOnCharacter(int)` static method to `MacroSystem` for UI play/stop state
- ✅ Created `lib/game3d/ui/macro_step_list.dart` (~340 lines) — extracted step list + add-step form widget with numbered step cards, reorder/delete, inline add form with action type dropdown, ability selector, wait duration, condition dropdown
- ✅ Created `lib/game3d/ui/macro_builder_panel.dart` (~450 lines) — main draggable panel with list view (saved macros, play/stop/edit/delete, active indicator) and editor view (name field, loop toggle, step list, save/cancel)
- ✅ Wired R key handler in `game3d_widget.dart` — toggles `macroPanelOpen`, respects `_isVisible('rotation_builder')`
- ✅ Wired Escape handler — closes macro panel before chat panel in priority chain
- ✅ Wired `MacroBuilderPanel` into build Stack before ChatPanel with `_isVisible()` guard
- ✅ Updated `rotation_builder` in `interface_config.dart` — added `shortcutKey: 'R'`, updated description
- ✅ All new files under 500 lines (macro_step_list: ~340, macro_builder_panel: ~450)
- ✅ Build verified clean (`flutter build web`)

### ✅ Completed - 2026-02-14

#### Spell Rotation & Macro System — Phase 1 + 2: Engine + Chat
- ✅ Created `assets/data/macro_config.json` — GCD timing, alert thresholds, execution behavior config
- ✅ Created `lib/game3d/state/macro_config.dart` — config class following WindConfig pattern with dot-notation getters, global singleton
- ✅ Created `lib/models/macro.dart` — `MacroActionType` enum, `MacroStep` (action, delay, condition), `Macro` (steps, loop, loopCount) with JSON serialization
- ✅ Created `lib/models/raid_chat_message.dart` — `RaidAlertType` (info/warning/critical/success), `RaidAlertCategory` (mana/health/cooldown/aggro/rotation/phase), `RaidChatMessage` with formatted timestamps
- ✅ Created `lib/game3d/state/macro_manager.dart` — CRUD + SharedPreferences persistence for per-character macros (`macros_char_0`, `macros_char_1`, etc.)
- ✅ Created `lib/game3d/systems/macro_system.dart` — `MacroExecution` runtime state, `MacroSystem` with `startMacro()`, `stopMacro()`, `stopAll()`, `update()` loop, GCD tracking, step delays, condition checking, throttled raid chat alerts for low mana/health
- ✅ Added `raidChatMessages`, `chatPanelOpen`, `chatPanelActiveTab` fields to `game_state.dart`
- ✅ Created `lib/game3d/ui/raid_chat.dart` — `RaidChatTab` widget with color-coded messages (cyan/yellow/red/green), monospace timestamps, auto-scroll
- ✅ Created `lib/game3d/ui/chat_panel.dart` — tabbed `ChatPanel` replacing standalone WarriorSpiritPanel for backtick key, Spirit tab (purple, interactive) + Raid tab (orange, read-only), draggable, 340×400
- ✅ Updated `game3d_widget.dart` — imported MacroConfig/MacroManager/MacroSystem/ChatPanel, added `_initializeMacroConfig()`, `MacroSystem.update(dt, gameState)` in update loop, backtick toggles `chatPanelOpen`, Escape closes `chatPanelOpen`, ChatPanel rendered with Spirit + Raid tabs
- ✅ Registered `'chat_panel'` and `'rotation_builder'` interfaces in `interface_config.dart`
- ✅ WarriorSpiritPanel kept as standalone V-key fallback (shown only when chat panel is closed)
- ✅ All values config-driven via `macro_config.json` — nothing hardcoded
- ✅ All new files under 500 lines (macro_config: ~100, macro: ~120, raid_chat_message: ~50, macro_manager: ~115, macro_system: ~340, raid_chat: ~100, chat_panel: ~370)
- ✅ Build verified clean (`flutter build web`)

#### Fix Ability System to Use Active Character Instead of Hardcoded Warchief
- ✅ Added active character mana helpers to `GameState`: `activeBlueMana`, `activeRedMana`, `activeWhiteMana` getters + max variants
- ✅ Added `activeHasBlueMana()`, `activeHasRedMana()`, `activeHasWhiteMana()` check methods
- ✅ Added `activeSpendBlueMana()`, `activeSpendRedMana()`, `activeSpendWhiteMana()` spend methods
- ✅ Added `activeWhiteMana` setter for Silent Mind restore
- ✅ Added `activeHealth` getter/setter and `activeMaxHealth` getter
- ✅ Fixed `getDistanceToCurrentTarget()` to use `activeTransform` instead of `playerTransform`
- ✅ Replaced all `gameState.playerTransform` → `gameState.activeTransform` in `ability_system.dart` (~35 occurrences)
- ✅ Replaced all `gameState.playerRotation` → `gameState.activeRotation` in `ability_system.dart` (~23 occurrences)
- ✅ Replaced all mana check/spend calls to active variants (hasBlueMana→activeHasBlueMana, spendBlueMana→activeSpendBlueMana, etc.)
- ✅ Replaced all `gameState.playerHealth` → `gameState.activeHealth` and `playerMaxHealth` → `activeMaxHealth`
- ✅ Fixed Silent Mind: `whiteMana = maxWhiteMana` → `activeWhiteMana = activeMaxWhiteMana`
- ✅ All ~30+ ability methods now operate on the active character (Warchief or ally)
- ✅ Build verified clean (`flutter build web`)

#### Ability Aura Glow Effect System
- ✅ Added `Mesh.auraDisc()` factory to `mesh.dart` — flat circular disc with radial alpha falloff (17 vertices × 2 faces, 32 triangles), center alpha 0.35 → mid 0.2 → outer 0.0
- ✅ Created `lib/game3d/effects/aura_system.dart` — `AuraType` enum, `getCategoryColorVec3()` color map (warrior=red, mage=blue, healer=green, etc.), `computeAuraColor()` averages unique category colors from action bar, `createOrUpdateAuraMesh()` with color-change detection to avoid per-frame allocation
- ✅ Added `auraMesh`, `auraTransform`, `lastAuraColor` fields to `Ally` model
- ✅ Added `playerAuraMesh`, `playerAuraTransform`, `lastPlayerAuraColor` fields to `GameState`
- ✅ Added `_renderAuras()` to `render_system.dart` — enables WebGL additive blending (SRC_ALPHA + ONE), disables depth writes, renders player + ally auras, restores GL state; render order: shadow → **auras** → target indicator
- ✅ Wired aura initialization in `game3d_widget.dart` — player aura created after shadow setup, ally auras created in `_addAlly()`
- ✅ Added `_updateAuraPositions()` — positions all aura discs at terrain height + 0.02 each frame
- ✅ Added `_refreshAllAuraColors()` — recomputes player + all ally aura colors; called on ability drop, and every 60 frames (~1s) to catch load-class and other config changes
- ✅ All new files under 500 lines (aura_system: ~115 lines)
- ✅ Build verified clean (`flutter build web`)

#### Active Character Control, Ally Mana, Panel Integration & Friendly Colors
- ✅ Added 6 mana fields to `Ally` model: `blueMana`, `maxBlueMana`, `redMana`, `maxRedMana`, `whiteMana`, `maxWhiteMana` with constructor defaults
- ✅ Added `activeTransform`, `activeRotation` (getter/setter), `activeEffectiveSpeed` getters to `GameState` — returns Warchief or active ally data
- ✅ Added `_resetPhysicsForSwitch()` — resets verticalVelocity, jumping, grounded, jumpsRemaining, cancels casts/windups, ends flight when switching away from Warchief
- ✅ Added `characterPanelSelectedIndex` to `GameState` for panel carousel sync
- ✅ Added `'player'` type handling in `getCurrentTarget()` and `validateTarget()`
- ✅ Added ally mana regen loops in `updateManaRegen()` — blue mana from ley lines + item bonuses, red mana from power nodes + item bonuses
- ✅ Added ally white mana regen in `updateWindAndWhiteMana()` — shares global wind exposure level, regen/decay like player
- ✅ Redirected `InputSystem` to use `activeTransform`/`activeRotation`/`activeEffectiveSpeed` — WASD now controls active character
- ✅ Added flight guard in `_handleFlightMovement()` — flight is Warchief-only
- ✅ Redirected `PhysicsSystem` — `update()`, `_checkGroundCollision()`, `getPlayerHeight()` use `activeTransform`; `_updateFlight()` stays on `playerTransform`
- ✅ Added AI skip in `updateAllyMovement()` and `updateAllyAI()` — player-controlled ally excluded from AI processing
- ✅ Updated camera follow, shadow follow, terrain loading, direction indicator to use `activeTransform`/`activeRotation`
- ✅ Modified `[`/`]` keys — when Character Panel is open, cycles panel carousel; otherwise cycles active controlled character
- ✅ Added `didUpdateWidget()` to `CharacterPanel` — syncs `_currentIndex` when `initialIndex` changes externally
- ✅ Added `isFriendly` flag to `_getTargetData()` — `true` for player/ally targets, `false` for enemies
- ✅ Added `targetBorderColor`/`targetHealthColor` params to `CombatHUD` — defaults to red, green when targeting friendlies
- ✅ Build verified clean (`flutter build web`)

### ✅ Completed - 2026-02-13

#### Party System & Active Character
- ✅ Added `cyclePartyNext`, `cyclePartyPrev`, `tabTargetFriendly` to `GameAction` enum with `]`, `[`, Shift+Tab key bindings and display names
- ✅ Added `Inventory` field to `Ally` model with default empty `Inventory()`
- ✅ Added `activeCharacterIndex`, `isWarchiefActive`, `activeAlly`, `cycleActiveCharacterNext()`, `cycleActiveCharacterPrev()` to `GameState`
- ✅ Added `_friendlyTabIndex`, `getTargetableFriendlies()`, `tabToNextFriendlyTarget()` to `GameState` for friendly target cycling
- ✅ Refactored `ActionBarConfig` for per-character persistence — `_storageKey` uses `'action_bar_config'` for Warchief (backward compatible) and `'action_bar_config_ally_N'` for allies
- ✅ Created `ActionBarConfigManager` with `_configs` map, `activeConfig`, `getConfig()`, `setActiveIndex()` — lazy-loads per-character configs
- ✅ Changed `globalActionBarConfig` to a getter alias for `globalActionBarConfigManager?.activeConfig` — all existing consumers work unchanged
- ✅ Wired `[`/`]` keys in `game3d_widget.dart` — cycles active character and updates action bar config
- ✅ Updated Shift+Tab handler — now cycles friendly targets instead of reverse enemy targeting
- ✅ Updated `_buildCombatHUD()` — player frame shows active character's name, health, max health, level, and portrait color
- ✅ Updated `C` key — character panel opens to `initialIndex: gameState.activeCharacterIndex`
- ✅ Added `initialIndex` parameter to `CharacterPanel`, used in `initState()` to set `_currentIndex`
- ✅ Updated `buildPaperDollColumn()` — removed early return for allies, now shows equipment slots for ALL characters (player and allies)
- ✅ Ally equipment: pass `_currentAlly?.inventory` instead of always using `playerInventory`; equip/unequip callbacks work for both player and ally inventories
- ✅ Replaced `_buildAllyCenter()` with compact `_buildAllyStatusCompact()` shown below equipment slots (strategy, command, ability chips)
- ✅ Added White Mana resource bar to `character_panel_stats.dart` (silver-white color, real values from gameState)
- ✅ Build verified clean (`flutter build web`)
- **Keybinds**: `[` = cycle party prev, `]` = cycle party next, Shift+Tab = friendly target cycle

#### Flight Banking & Barrel Roll System
- ✅ Added `flightBankAngle` field to `game_state.dart` flight state section, reset in `startFlight()` and `endFlight()`
- ✅ Added 6 banking config values to `wind_config.json` `flight` section: `bankRate`, `maxBankAngle`, `autoLevelRate`, `autoLevelThreshold`, `bankToTurnMultiplier`, `barrelRollRate`
- ✅ Added 6 banking getters to `wind_config.dart` following existing `_resolve` pattern
- ✅ Replaced Q/E disabled section in `input_system.dart` with full banking/barrel roll logic
- ✅ Modified A/D yaw to use bank-enhanced turn rate (sin-based multiplier formula)
- ✅ Barrel roll combos: Q+A = left barrel roll, E+D = right barrel roll (continuous, uncapped)
- ✅ Auto-level suppressed when |bankAngle| >= 90 deg (inverted flight rule)
- ✅ Visual roll applied via `playerTransform.rotation.z`
- ✅ Created `warchief_game/FLIGHT_MECHANICS.md` context document for future sessions
- ✅ All values config-driven via `wind_config.json` — nothing hardcoded
- ✅ Build verified clean (`flutter build web`)

#### Goals System - Phase 1: Framework + Warrior Spirit
- ✅ Created `warchief_game/GOALS_SYSTEM_DESIGN.md` — design doc covering SDT philosophy, goal taxonomy, state machine, Warrior Spirit architecture, data flow, integration points
- ✅ Created `warchief_game/AI_INTEGRATION.md` — AI reference doc covering OllamaClient API, MCP patterns, AIChatPanel UI, Warrior Spirit integration, how to add new AI features
- ✅ Created `warchief_game/CLAUDE_TASK_TEMPLATE.md` — reusable prompt template for future Claude Code tasks with patterns reference and anti-patterns
- ✅ Created `assets/data/goals_config.json` — 8 goal definitions (first_blood, gnoll_hunter, wind_walker, ley_pilgrim, builders_pride, derecho_survivor, sword_mastery, ally_commander), Warrior Spirit config, goal category colors
- ✅ Created `lib/game3d/state/goals_config.dart` — config class following BuildingConfig/ManaConfig pattern with JSON asset defaults, global singleton, dot-notation resolution
- ✅ Created `lib/models/goal.dart` — Goal, GoalDefinition, GoalSource, GoalTrackingType, GoalStatus, GoalCategory enums with JSON parsing
- ✅ Created `lib/game3d/systems/goal_system.dart` — event processing (counter/threshold/mastery/discovery/narrative), completion checks, goal acceptance/abandonment
- ✅ Created `lib/game3d/ai/warrior_spirit.dart` — hybrid deterministic+LLM Warrior Spirit with Ollama chat, narrative goal suggestions, fallback static text, periodic update, initial greeting
- ✅ Updated `lib/game3d/state/game_state.dart` — added goals list, activeGoals/completedGoals getters, warriorSpiritMessages, pendingSpiritGoal, goalsPanelOpen, warriorSpiritPanelOpen, consecutiveMeleeHits, visitedPowerNodes
- ✅ Created `lib/game3d/ui/goals_panel.dart` — draggable G-key panel with category-grouped goals, progress bars, pending spirit suggestion with accept/decline buttons
- ✅ Created `lib/game3d/ui/warrior_spirit_panel.dart` — draggable V-key chat panel with message history, text input, send button, "Spirit is thinking..." indicator
- ✅ Updated `lib/game3d/game3d_widget.dart` — GoalsConfig init, WarriorSpirit init, G/V key handlers, Escape close, game loop Warrior Spirit update, flight duration tracking, power node visit tracking, ally command goal events, GoalsPanel + WarriorSpiritPanel UI wiring
- ✅ Updated `lib/game3d/systems/combat_system.dart` — goal event emission on enemy kills (enemy_killed, kill_<type>, boss_killed), melee streak tracking (consecutive_melee_hits)
- ✅ All values config-driven via `goals_config.json` — no hardcoded goal data
- ✅ All new files under 500 lines
- ✅ Build verified clean (`flutter build web`)

#### Building System - Phase 1: Warchief's Home
- ✅ Created `assets/data/building_config.json` — building type definitions (warchief_home, barracks, workshop) with tiers, parts geometry, aura effects, minimap display
- ✅ Created `lib/game3d/state/building_config.dart` — config class following ManaConfig pattern with JSON asset defaults, global singleton
- ✅ Created `lib/models/building.dart` — Building + BuildingDefinition + BuildingTierDef models with JSON parsing, aura/range checks, distance calculations
- ✅ Created `lib/rendering3d/building_mesh.dart` — procedural mesh factory generating foundation, walls (with door cutout), and peaked roof from tier config parts
- ✅ Created `lib/game3d/systems/building_system.dart` — placement (terrain-snapped), upgrade, aura effects (health+mana regen), ley line proximity bonus
- ✅ Updated `lib/game3d/state/game_state.dart` — added buildings list, buildingPanelOpen/selectedBuilding UI state, spawnWarchiefHome(), getNearestBuilding()
- ✅ Updated `lib/game3d/systems/render_system.dart` — added building render loop after ley lines, before shadows
- ✅ Updated `lib/game3d/ui/minimap/minimap_entity_painter.dart` — added building blips as colored squares from tier config
- ✅ Created `lib/game3d/ui/building_panel.dart` — draggable info/upgrade panel with aura stats, ley line bonus display, upgrade button
- ✅ Updated `lib/game3d/game3d_widget.dart` — building config init, H key handler, Escape close, game loop aura update, BuildingPanel wiring, warchief home spawn after config load
- ✅ All values config-driven via `building_config.json` — no hardcoded building data
- ✅ All new files under 500 lines

### ✅ Completed - 2026-02-12

#### Minimap North Indicator + Rotation Toggle + Fixed-North Mirror Fix
- ✅ Added gold "N" compass indicator on minimap border — rotates in rotating mode to show north direction, stays at top in fixed-north mode
- ✅ Added rotation mode toggle button (compass/north icon) at bottom-left of minimap border — switches between rotating and fixed-north modes
- ✅ Added `isRotatingMode` bool to `MinimapState` (default: true = rotating)
- ✅ Changed `playerStartRotation` from 0 to 180 degrees — character starts facing north (+Z), north is up in rotating minimap
- ✅ Fixed mirror effect in fixed-north mode: negated X axis in all coordinate mappings (entities, terrain, ley lines, pings, tap handler) to compensate for the game's rotateY convention mirroring X vs standard compass
- ✅ Fixed arrow rotation sense in fixed-north mode: changed formula from `(rotation + 180)` to `(180 - rotation)` — right turn = clockwise on minimap, left turn = counter-clockwise
- ✅ All files under 500 lines (border_icons: 359, entity: 222, terrain: 283, ping: 279, widget: 253)
- ✅ Build verified clean (`flutter build web`)

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
