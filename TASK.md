# Task Tracking

## Current Tasks

### ✅ Completed - 2026-03-03

#### Equipment Visual Representation
- ✅ **`assets/data/equipment_visual_config.json`** (new): Per-slot attachment offsets, mesh sizes, default colors. 4 visible slots (helm/mainHand/offHand/back), 7 stat-only.
- ✅ **`lib/models/item.dart`**: Added `visualColor: List<double>?` and `visualShape: String?` fields. Parsed in `fromJson`/`toJson`/`copyWithStackSize`.
- ✅ **`lib/game3d/rendering/equipment_visual.dart`** (new, ~25 lines): `EquipmentVisual` data class with `mesh`, `worldTransform`, `localOffset`, `slot`. Mirrors aura pattern on `Ally`.
- ✅ **`lib/game3d/rendering/equipment_renderer.dart`** (new, ~200 lines): `EquipmentVisualConfig` (loads JSON), `EquipmentRenderer` (static class). `buildEquipmentVisuals()`, `repositionVisuals()`, `renderVisuals()`. Global `globalEquipmentVisualConfig` singleton.
- ✅ **`lib/models/ally.dart`**: Added `List<EquipmentVisual> equipVisuals` + `rebuildEquipmentVisuals(config)` method.
- ✅ **`lib/game3d/state/game_state.dart`**: Added `List<EquipmentVisual> playerEquipVisuals` + `rebuildPlayerEquipmentVisuals(config)`.
- ✅ **`lib/game3d/systems/render_system.dart`**: Added `_renderEquipment()` delegate. Called after player mesh, inside allies loop, inside duel combatants loop.
- ✅ **`lib/game3d/ui/paper_doll_painter.dart`**: Added `PaperDollEquipment` data class. Extended `RotatableCubePainter` with `equipment` param — helm tints top face, armor tints side faces, weapon draws sword line on right, off-hand draws shield square on left.
- ✅ **`lib/game3d/ui/character_panel_columns.dart`**: Added `PaperDollEquipment? equipment` param to `buildPaperDollColumn()`, forwarded to `RotatableCubePortrait`.
- ✅ **`lib/game3d/ui/character_panel.dart`**: Added `_buildPaperDollEquipment()` helper, passes equipment to column. Calls `rebuildEquipmentVisuals/rebuildPlayerEquipmentVisuals` on equip/unequip.
- ✅ **`lib/game3d/game3d_widget.dart`**: Imports `EquipmentVisualConfig`/`globalEquipmentVisualConfig`. Calls `_initializeEquipmentVisualConfig()` in `initState`.
- ✅ **`lib/game3d/game3d_widget_init.dart`**: Added `_initializeEquipmentVisualConfig()` — async load → sets singleton → `setState`.
- ✅ Build verified: `flutter analyze --no-pub` — 0 new errors.

### ✅ Completed - 2026-03-02

#### CC World-Space Indicator Overlay + Aethermancer Freeze
- ✅ **`lib/game3d/ui/cc_indicator_overlay.dart`** (new, ~230 lines): `CcIndicatorOverlay` StatelessWidget. Projects unit positions to screen (+2.5 Y world-space head offset). Collects CC effects from player, boss, allies (excludes Spirit Wolf summon), and alive minions. Renders horizontal row of `_CcBadge` widgets centered above each unit. `_CcBadge`: 44×44px badge with colored BG/border/glow + icon + countdown text. `_CcProgressRingPainter`: draws remaining portion as colored stroke arc (action-bar cooldown style — NOT expired fill).
- ✅ **`lib/game3d/game3d_widget.dart`**: Added `import 'ui/cc_indicator_overlay.dart'`.
- ✅ **`lib/game3d/game3d_widget_ui.dart`**: Added `CcIndicatorOverlay(gameState, camera)` to Stack immediately after `DamageIndicatorOverlay`.
- ✅ **`lib/game3d/data/abilities/aethermancer_abilities.dart`**: Added `aetherChill` (Aether Chill) — ranged freeze projectile, 22 dmg, 16s CD, 3s freeze, 0.8s cast, White 18 + Blue 12 dual mana, DamageSchool.frost. Added to `all` getter.
- ✅ Build verified: `flutter analyze --no-pub` — 0 new errors.

### ✅ Completed - 2026-03-01

#### Healer → Leyweaver Rename + Aethermancer New Class
- ✅ **`lib/game3d/data/abilities/leyweaver_abilities.dart`** (new): `LeyweaverAbilities` class, all 9 abilities with `category: 'leyweaver'`. Identical stat profile to old Healer; Blue mana / Holy damage school.
- ✅ **`lib/game3d/data/abilities/aethermancer_abilities.dart`** (new): `AethermancerAbilities` class, 8 abilities. Primary mana: White; secondary: Blue. Abilities: Wind Mend, Ley Flow, Aether Circle, Zephyr Ward, Arcane Cleanse, Gale Fist, Ley Surge, Aether Surge (combo primer). Arcane + Holy damage schools.
- ✅ **`lib/game3d/data/abilities/abilities.dart`**: Swapped `healer_abilities` import/export for `leyweaver_abilities` + `aethermancer_abilities`. Updated `AbilityRegistry.categories`, `getByCategory()`, `potentialAbilities`, and `categoryCounts`.
- ✅ **`lib/game3d/data/duel/duel_definitions.dart`**: `'healer'` → `'leyweaver'` + added `'aethermancer'` in `challengerClasses`, `allCombatantTypes`, display names, ability factory, color factory, primary mana factory, secondary mana factory.
- ✅ **`lib/game3d/systems/ability_system_implementations.dart`**: Updated section header + all `HealerAbilities.` → `LeyweaverAbilities.`.
- ✅ **`lib/game3d/systems/melee_combo_system.dart`**: `case 'healer'` → `case 'leyweaver': case 'aethermancer':`.
- ✅ **`lib/game3d/state/action_bar_config.dart`**: `HealerAbilities.all` → `LeyweaverAbilities.all` + `AethermancerAbilities.all`.
- ✅ **`lib/game3d/state/abilities_config.dart`**: Updated legacy getters to `LeyweaverAbilities.*`.
- ✅ **`lib/game3d/data/abilities/player_abilities.dart`**: Updated Heal ability `category: 'leyweaver'`.
- ✅ **`lib/game3d/effects/aura_system.dart`**: `case 'healer'` → `case 'leyweaver': case 'aethermancer':`.
- ✅ **`lib/game3d/ui/abilities_modal_cards.dart`**: Same case update.
- ✅ **`lib/game3d/ui/ability_editor_panel_sections.dart`**: Added `'leyweaver'`, `'aethermancer'` to built-in categories list.
- ✅ **`assets/data/combo_config.json`**: Renamed `"healer"` → `"leyweaver"`. Added `"aethermancer"` entry (heal combo, 18 HP / chain 55 HP + 8 HP/tick).
- ✅ **`assets/data/source-tree.json`**: Updated file name reference.
- ⚠️ **`lib/game3d/data/abilities/healer_abilities.dart`**: Old file left in place (no longer imported). Can be deleted once confirmed safe.
- ✅ Build verified: `flutter analyze --no-pub` — 0 new errors.

### ✅ Completed - 2026-02-28

#### AI Settings Tab (Ollama)
- ✅ **`lib/ai/ollama_client.dart`**: Changed `baseUrl` from `const` to mutable static. Added `loadSavedEndpoint()`, `saveEndpoint()` (both persist to SharedPreferences key `'ollama_endpoint'`), and `listModels()` (queries `/api/tags`, returns list of model name strings).
- ✅ **`lib/game3d/ui/settings/ollama_tab.dart`** (new, 462 lines): Self-contained AI settings tab. Three sections: Connection (endpoint URL field + Test button + live status indicator), Model (text field + Fetch button + tap-to-select model list from server), Warrior Spirit (Temperature/Goal Interval/Max Goals sliders). Save Changes persists endpoint + all GoalsConfig overrides.
- ✅ **`lib/game3d/ui/settings/settings_panel.dart`**: Imported `ollama_tab.dart`, added `_TabItem(id: 'ai', label: 'AI', icon: Icons.smart_toy_outlined)` between Interfaces and Source Code, added `case 'ai': return const OllamaTab()` in `_buildContent()`.
- ✅ **`lib/game3d/game3d_widget_init.dart`**: `_initializeGoalsConfig()` now chains `OllamaClient.loadSavedEndpoint()` before `WarriorSpirit.init()` so the correct endpoint is active from first use.
- ✅ Build verified: `flutter analyze --no-pub` — 0 errors, 0 warnings.

#### Global Cooldown (GCD) — Action Bar Clock Animation
- ✅ **`lib/game3d/state/game_state.dart`**: Added `activeGcdMax` getter alongside existing `activeGcdRemaining` — returns Warchief's or active ally's `gcdMax` for UI sweep math.
- ✅ **`lib/game3d/ui/unit_frames/combat_hud.dart`**: Added `dart:math` import (shared with part files).
- ✅ **`lib/game3d/ui/unit_frames/combat_hud_action_bar.dart`**: `_buildActionBar` now reads `gcdRemaining`/`gcdMax` from `gameState`. Each slot's displayed `cooldown = max(slotCd, gcdRemaining)` and `maxCooldown` picks GCD or slot max accordingly — so every ability button shows the clock sweep for the full 1 s GCD duration, then reverts to its own per-ability cooldown if longer.
- ✅ Note: GCD triggering, blocking, and decrement were already implemented in `ability_system_dispatch.dart` and `ability_system_core.dart` — only the visual display was missing.
- ✅ Build verified: `flutter analyze --no-pub` — 0 new errors.

### ✅ Completed - 2026-02-27

#### Duel Arena — Banner Pole + Wind Flutter + Victory Flag
- ✅ **`lib/game3d/state/duel_banner_state.dart`** (new, 119 lines): `DuelBannerPhase` enum (`idle/dropping/fluttering/flagRising/complete`) + `DuelBannerState` class. Drives pole drop (cubic ease-out, 2 s), wind-reactive banner flutter (yaw faces wind direction, roll oscillates with amplitude ∝ wind strength), and victory flag rise animation (1.5 s).
- ✅ **`lib/game3d/rendering/duel_banner_renderer.dart`** (new, 110 lines): Lazily builds and reuses pole (`Mesh.cube` scaled thin+tall, warm wood color), banner cloth (`Mesh.plane` pitched −90° to vertical, gold/ochre), and per-winner flag (blue/red/gold depending on `winnerId`). Static Transform3d objects mutated each frame — no per-frame allocation.
- ✅ **`lib/game3d/state/game_state.dart`**: Added `duel_banner_state.dart` import + `DuelBannerState? duelBannerState` field in the DUEL STATE section.
- ✅ **`lib/game3d/game3d_widget.dart`**: Added imports for `duel_banner_state.dart` and `duel_banner_renderer.dart`.
- ✅ **`lib/game3d/game3d_widget_duel.dart`** (108 lines): Arena now spawns **in front of the active character** (15 m along forward vector). Challengers spread along forward axis on the left (−right), enemies on the right. `_startDuel` calls `duelBannerState.start(baseX, baseZ)`. `_cancelDuel` calls `duelBannerState.reset()`.
- ✅ **`lib/game3d/game3d_widget_update.dart`**: Added `gameState.duelBannerState?.update(dt, globalWindState)` after `DuelSystem.update`.
- ✅ **`lib/game3d/systems/render_system.dart`**: Added `DuelBannerRenderer.render()` call with normal blending, placed after `_renderAuras()` so it renders with proper depth.
- ✅ **`lib/game3d/systems/duel_system.dart`**: Added `gameState.duelBannerState?.notifyWinner(winnerId)` after `finalizeDuel` to trigger flag-rise animation.
- ✅ Build verified: `flutter analyze --no-pub` — 0 new errors.

#### Duel Arena — End Conditions + Previous Selections
- ✅ **`lib/models/duel_result.dart`**: Added `DuelEndCondition` enum (`firstKill`, `totalAnnihilation`) + labels map. Expanded `DuelResult` with `challengerClasses`, `enemyTypes`, `challengerGearTiers`, `enemyGearTiers`, `endCondition` fields; backward-compat `fromJson` fallbacks for old records.
- ✅ **`lib/game3d/state/duel_manager.dart`**: Added `endCondition` to `DuelSetupConfig` and `DuelManager`; `finalizeDuel` now stores full party composition + end condition in result; `reset()` clears `endCondition`.
- ✅ **`lib/game3d/systems/duel_system.dart`**: Win-check now dispatches on `manager.endCondition` — `firstKill` triggers on the first `any()` death; `totalAnnihilation` keeps the existing `every()` check.
- ✅ **`lib/game3d/game3d_widget_duel.dart`**: `_startDuel` writes `mgr.endCondition = setup.endCondition`.
- ✅ **`lib/game3d/ui/duel/duel_panel.dart`**: Added `_endCondition` and `_showRecents` state fields; added `part 'duel_panel_recents.dart'`.
- ✅ **`lib/game3d/ui/duel/duel_panel_setup.dart`**: Added "Ends:" toggle row (First Kill / Total Annihilation); calls `_buildPastPerformance()` and `_buildRecentsSection()` from the new recents part file; `_doStartDuel` passes `endCondition`.
- ✅ **`lib/game3d/ui/duel/duel_panel_recents.dart`**: New part file — `_MatchupRecord` aggregate helper, `_DuelPanelRecents` extension with: live past-performance bar (# duels / blue win% / avg time for current selection), collapsible "Recent Configurations" list (up to 8 unique matchups, each with stats + Load button that restores all setup fields including gear tiers).
- ✅ File splitting: commands file refactor to `game3d_widget_duel.dart` (87 lines); all duel UI files ≤ 421 lines.
- ✅ Build verified: `flutter analyze --no-pub` — 0 new errors.

### ✅ Completed - 2026-02-26

#### Duel Arena — Multi-Party + Gear + Strategy Enhancement
- ✅ **`assets/data/duel_config.json`**: Added `gearTiers` block (5 tiers: health/mana/damage multipliers).
- ✅ **`lib/game3d/state/duel_config.dart`**: Added `gearTierNames`, `gearTierHealthMultipliers`, `gearTierManaMultipliers`, `gearTierDamageMultipliers` getters.
- ✅ **`lib/game3d/state/duel_manager.dart`**: Added `DuelStrategy` enum (aggressive/defensive/balanced/support/berserker), `duelStrategyLabels`, `DuelSetupConfig` snapshot class, multi-party fields (`challengerPartySize`, `enemyPartySize`, `challengerPartyClasses`, `enemyPartyTypes`, `challengerGearTiers`, `enemyGearTiers`, `challengerStrategy`, `enemyStrategy`, `challengerPartyAbilities`, `enemyPartyAbilities`).
- ✅ **`lib/game3d/systems/duel_system.dart`**: Full rewrite — multi-party support (0..chalSize = blue, chalSize.. = red), `resetCooldowns(List<Ally>)` static method, priority-scored ability selection per strategy, `_preferredDistance` kiting, Support strategy party-heal targeting, gear damage multiplier applied at deal time.
- ✅ **`lib/game3d/ui/duel/duel_panel.dart`**: Resized to 560×640, added `onResetCooldowns` callback, multi-party state, `_setPartySize()` helper, Reset Cooldowns button in Active tab, `part 'duel_panel_setup.dart'`.
- ✅ **`lib/game3d/ui/duel/duel_panel_setup.dart`**: New part file — Setup tab with side headers, party size 1-5, strategy dropdown, per-slot class selector + 5 gear tier circles.
- ✅ **`lib/game3d/game3d_widget_commands.dart`**: Updated `_startDuel(DuelSetupConfig)` with multi-party spawn + gear scaling, added `_duelResetCooldowns()`.
- ✅ **`lib/game3d/game3d_widget.dart`**: Added `_duelResetCooldowns` abstract stub.
- ✅ **`lib/game3d/game3d_widget_ui.dart`**: Updated DuelPanel instantiation with `onResetCooldowns`, new 560/640 size.
- ✅ **`docs/DUEL_INTERFACE.md`**: New documentation — panel structure, gear tier table, strategy reference, AI heuristic description, 8 suggested next steps.
- ✅ Build verified: `flutter analyze --no-pub` — 0 new errors.

#### File Splitting — stance_editor_panel + minion_frames
- ✅ **`lib/game3d/ui/stance_editor_panel.dart`**: Split from 651 → 479 lines. Extracted `_tooltips` map + all `_build*` field/style methods.
- ✅ **`lib/game3d/ui/stance_editor_panel_fields.dart`**: New part file (193 lines) — `_tooltips` const map + extension `_StanceEditorFields`.
- ✅ **`lib/game3d/ui/unit_frames/minion_frames.dart`**: Split from 592 → 284 lines. Extracted all helper widget methods.
- ✅ **`lib/game3d/ui/unit_frames/minion_frame_widgets.dart`**: New part file (305 lines) — extension `_MinionFrameWidgets`.
- ✅ Build verified: `flutter analyze --no-pub` — 0 new errors.

#### Duel Arena System — Third Faction Balance Testing
- ✅ **`assets/data/duel_config.json`**: Arena offset, separation distance, duration, mana regen, history cap, challenger/enemy health/mana defaults.
- ✅ **`lib/game3d/state/duel_config.dart`**: Lightweight JSON config model with dot-notation getters. Global `globalDuelConfig` instance.
- ✅ **`lib/models/duel_result.dart`**: `DuelEvent`, `DuelCombatantStats`, `DuelResult` data models with full JSON round-trip.
- ✅ **`lib/game3d/state/duel_manager.dart`**: State machine (`idle/active/completed`), event recording, SharedPreferences persistence (key `duel_history`, capped at 200 entries FIFO), `reset()` / `finalizeDuel()`.
- ✅ **`lib/game3d/data/duel/duel_definitions.dart`**: `DuelDefinitions` factory — creates `Ally` instances for all 12 challenger classes and 4 enemy faction types; returns ability lists per combatant.
- ✅ **`lib/game3d/systems/duel_system.dart`**: Per-frame duel orchestration — AI movement, ability cycling, mana regen, cooldown ticking, win/draw/timeout detection.
- ✅ **`lib/game3d/ui/duel/duel_panel.dart`**: 3-tab draggable panel (Setup / Active / History, 440×520). Setup: dropdowns + Start button. Active: elapsed timer, damage/heal stats, last-50-events log, Cancel button. History: scrollable result rows, Clear button.
- ✅ **`lib/game3d/state/game_state.dart`**: Added `duelCombatants`, `duelManager`, `duelPanelOpen` fields + imports.
- ✅ **`lib/game3d/systems/render_system.dart`**: Duel combatant meshes rendered in aura pass.
- ✅ **`lib/game3d/game3d_widget_init.dart`**: `_initializeDuelConfig()` and `_initializeDuelManager()` methods added.
- ✅ **`lib/game3d/game3d_widget.dart`**: Added imports + init calls + abstract stubs for `_startDuel` / `_cancelDuel`.
- ✅ **`lib/game3d/game3d_widget_update.dart`**: `DuelSystem.update(dt, gameState)` called after AI system.
- ✅ **`lib/game3d/game3d_widget_ui.dart`**: Duel panel added to Stack with `_draggable()` wrapper.
- ✅ **`lib/game3d/game3d_widget_commands.dart`**: `_startDuel()` and `_cancelDuel()` helpers implemented.
- ✅ **`lib/game3d/game3d_widget_input.dart`**: `U` key toggles `gameState.duelPanelOpen`.
- ✅ Build verified: `flutter analyze --no-pub` — 0 new errors.

### ✅ Completed - 2026-02-26 (earlier)

#### Melee Combo System — Chain Combos + Per-Class Primers
- ✅ **`assets/data/combo_config.json`**: All thresholds normalized to 3; buff durations 8s, debuff durations 4s. Added per-class `chain` sub-config objects. Added `chainWindow: 7.0`.
- ✅ **`lib/game3d/state/combo_config.dart`**: Added `chainWindow` getter.
- ✅ **`lib/game3d/data/abilities/ability_types.dart`**: Added `enablesComboChain: bool = false` to `AbilityData` constructor, `copyWith`, and `applyOverrides`.
- ✅ **`lib/game3d/state/game_state.dart`**: Added `meleeChainModeActive`, `meleeChainCount`, `meleeChainTimer`, `meleeChainCategory` fields. Updated `effectivePlayerSpeed` to apply haste effect multiplier.
- ✅ **`lib/game3d/systems/melee_combo_system.dart`**: Full chain combo logic — primer detection (`enablesComboChain`), chain hit tracking (hit 3 fires regular effect, hit 7 fires chain effect), chain timer decay in `update()`. Added `_triggerChainEffect()` dispatch + per-class chain handlers: `_applyWeakness`, `_applyRoot`, `_applyPoison`. Added `_logChainActivated` / `_logChainTrigger` helpers.
- ✅ **12 class ability files** — added chain primer ability to each:
  - `warrior_abilities.dart` → `Iron Momentum` (red mana 20, CD 10)
  - `rogue_abilities.dart` → `Shadow Chain` (red mana 15, CD 10)
  - `windwalker_abilities.dart` → `Gale Fury` (white mana 15, CD 10)
  - `starbreaker_abilities.dart` → `Void Cascade` (black mana 20, CD 10)
  - `stormheart_abilities.dart` → `Thunderstorm Strike` (white 15 + red 10, CD 10)
  - `healer_abilities.dart` → `Battle Blessing` (blue mana 20, CD 10)
  - `necromancer_abilities.dart` → `Soul Chain` (black mana 20, CD 10)
  - `nature_abilities.dart` → `Ancient Surge` (green mana 15, CD 10)
  - `greenseer_abilities.dart` → `Earth Bond` (green mana 15, CD 10)
  - `mage_abilities.dart` → `Arcane Focus` (blue mana 20, CD 10)
  - `spiritkin_abilities.dart` → `Spirit Rush` (green mana 15, CD 10)
  - `elemental_abilities.dart` → `Elemental Chain` (red mana 20, CD 10)
- ✅ Build verified clean (`flutter analyze --no-pub` — 0 new errors).

### ✅ Completed - 2026-02-25

#### Wind Curl Visibility + Impassable Movement Fix
- ✅ **`lib/game3d/state/wind_state.dart`** (`getMovementModifier`): Root cause was `headFactor=0.15` keeping `rawMod` at 0.625 even at threshold — the `impassMin` floor was never reached. Fix: above `impassableThreshold`, `effectiveHeadFactor` ramps from `0.15` toward `1.0` (amplified by `t × (1−resistance)`), forcing rawMod deeply negative so the clamp always triggers. Tide (resistance=1) keeps base factor; no-stance units hit `impassMin=0.02` by ~effStr=5.
- ✅ **`lib/game3d/rendering/wind_particles.dart`** (`_rebuildMesh`): Replaced 4-vertex parallelogram (imperceptible as curved) with 6-vertex 2-segment bent strip (head → elbow at centre → tail). Mid-perpendicular uses `midAngle = windAngle − offset × 0.5`. Added `curveDurationMult=2.0` amplification and `clamp(−π/2, π/2)` to prevent spiral artifacts.
- ✅ **`lib/game3d/ui/minimap/minimap_wind_painter.dart`** (`_drawParticles`): Replaced `trailDuration = trailPx / pixelSpeed` (which shrank at high effStr, cancelling angular offset) with fixed `curveSecs=1.5`. Bumped `trailPx` 10→12. Added `clamp(−3π/4, 3π/4)` on angle offset.
- ✅ Build verified clean (`flutter analyze --no-pub` — 0 new errors).

#### Wind Threshold Tuning + Curving Wind Trails
- ✅ **`assets/data/wind_config.json`**: Lowered `driftThreshold` 2.0→1.0, `driftMaxSpeed` 0.6→1.0, `impassableThreshold` 5.0→2.5. Previous values were barely reachable given `baseStrength 0.3 × 10× derecho = 3.0` typical peak.
- ✅ **`lib/game3d/state/wind_state.dart`**: Added `windAngularVelocity` (EMA-smoothed `Δangle/dt`, shortest-arc-safe). Used by renderers to curve trail geometry.
- ✅ **`lib/game3d/rendering/wind_particles.dart`**: Bent trail quads — head end uses current `windAngle`, tail end uses `windAngle − ω × trailDuration`. Trails now curve in the direction the wind is turning, proportional to turn rate.
- ✅ **`lib/game3d/ui/minimap/minimap_wind_painter.dart`**: Replaced `drawLine(prev, curr)` with quadratic bezier whose tail is analytically computed from `windAngularVelocity`. Control point at the mid-direction angle produces smooth curves; falls through to straight line when `|ω| < 0.05`.
- ✅ Build verified clean (`flutter analyze --no-pub` — 0 new errors).

#### Wind Physical Effects on Units (Derecho Pushback)
- ✅ **`assets/data/wind_config.json`**: Added `physics` section (`driftThreshold`, `driftMaxSpeed`, `impassableThreshold`, `impassableMinSpeed`).
- ✅ **`lib/game3d/state/wind_config.dart`**: Added 4 physics getters in a new `WIND PHYSICS GETTERS` section.
- ✅ **`lib/game3d/state/wind_state.dart`**: Added `getWindDrift(dt, {resistance})` for passive position drift; updated `getMovementModifier` to accept `resistance` and apply impassable threshold logic; added `isWindImpassable` getter.
- ✅ **`lib/game3d/data/stances/stance_types.dart`**: Added `windResistance` field with default 0.0; wired into constructor, `copyWith`, `applyOverrides`, and `modifierSummary`.
- ✅ **`lib/game3d/data/stances/stance_definitions.dart`**: Added `windResistance` parse in `_parseStance()`.
- ✅ **`assets/data/stance_config.json`**: Added `windResistance` per stance — Drunken (0.0), Blood (0.0), Tide (1.0), Phantom (0.5), Fury (0.75).
- ✅ **`lib/game3d/systems/input_system.dart`**: Player movement modifier now passes `gameState.activeStance.windResistance`; passive drift applied at end of `handlePlayerMovement`.
- ✅ **`lib/game3d/game3d_widget_update.dart`**: Added `_applyWindDrift(dt)` helper; called after `AISystem.update` to drift allies and monster.
- ✅ Build verified clean (`flutter analyze --no-pub` — 0 new errors).

#### Comet System (Options A + B) with Black Mana
- ✅ **`assets/data/comet_config.json`**: All tunable values for orbital, blackMana, sky, comet visual, and meteor sections.
- ✅ **`lib/game3d/state/comet_config.dart`**: Config model following ManaConfig pattern — extends ChangeNotifier, dot-notation getters with fallbacks, `globalCometConfig` singleton.
- ✅ **`lib/game3d/state/comet_state.dart`**: Runtime orbital state — `_orbitalPhase` [0–1], bell-curve intensity, meteor shower window, three-layer black mana regen, impact crater list with proximity bonus and decay. `globalCometState` singleton.
- ✅ **`lib/game3d/rendering/meteor_particles.dart`**: Pool-based meteor streak particle system — radiant-aligned spawn, terrain impact detection, flash effect, crater registration, additive-blend mesh rendering.
- ✅ **`lib/game3d/rendering/sky_renderer.dart`**: Sky gradient quad (zenith→horizon, comet-tinted) + comet billboard (coma + ion tail + dust tail) rendered at max camera distance with additive blending.
- ✅ **`lib/game3d/data/abilities/ability_types.dart`**: Added `black` to `ManaColor` enum; added `requiresBlackMana` getter.
- ✅ **`lib/game3d/state/game_state.dart`**: Added `blackMana`, `maxBlackMana`, `currentBlackManaRegenRate` fields; `activeBlackMana`/`activeMaxBlackMana` getters; `spendBlackMana`/`canAffordBlackMana`/`generateBlackMana`/`activeHasBlackMana`/`activeSpendBlackMana` methods. Updated `_allManaColors` to include black. Added comet imports.
- ✅ **`lib/game3d/state/game_state_mana.dart`**: Added `updateBlackManaRegen()` — three-layer regen (ambient + surge + craters) for Warchief and allies.
- ✅ **`lib/models/ally.dart`**: Added `blackMana` / `maxBlackMana` fields with defaults (0.0 / 100.0).
- ✅ **`lib/game3d/ui/mana_bar.dart`**: Added black mana bar (void-purple gradient), `_buildCometInfo()` widget, and comet regen rate info display.
- ✅ **`lib/game3d/systems/render_system.dart`**: Added `SkyRenderer` + `MeteorParticleSystem` statics; sky rendered before terrain; comet + meteors rendered after effects pass. Added `_renderMeteors()` helper.
- ✅ **`lib/game3d/game3d_widget_init.dart`**: Added `_initializeCometSystem()` method (instantiates CometConfig + CometState).
- ✅ **`lib/game3d/game3d_widget.dart`**: Calls `_initializeCometSystem()` on startup + imports comet types.
- ✅ **`lib/game3d/game3d_widget_update.dart`**: Calls `globalCometState?.update(dt)` and `updateBlackManaRegen()` each frame.
- ✅ **`lib/game3d/systems/ability_system.dart`**: Added `black` to `_ManaType` internal enum.
- ✅ **`lib/game3d/systems/ability_system_mana.dart`**: Updated all mana color/type conversion functions and switch statements for black mana.
- ✅ **`lib/game3d/data/abilities/ability_balance.dart`**: Added `ManaColor.black` display color (void-purple `0xFF8020C0`) to exhaustive switch.
- ✅ Build verified clean (`flutter analyze --no-pub` — 0 new errors).

### Pending - File Size Reduction Roadmap

14 Dart files exceed the 500-line limit. See `warchief_game/CLAUDE.md` for the full split strategy table. Priority order:

1. ✅ **ability_system.dart** (3238 lines) → Split into 8 part files using Dart `part`/`part of`. Files: `ability_system_core`, `_mana`, `_dispatch`, `_cast_effects`, `_implementations`, `_windwalker`, `_interactions`, `_updates`. Build verified clean.
2. ✅ **game3d_widget.dart** (2573 lines) → Split into 7 part files: core+base (342), init (369), update (223), input (451), commands (458), ui (443), ui_helpers (389). All under 500 lines. Build verified clean.
3. ✅ **game_state.dart** (2661 lines) → Split into 5 part files via extension methods: core fields (946†), stance+effects (394), mana regen (410), targeting (427), world+spawn (531). Build verified clean. †Main file has 150+ documented fields — unavoidable minimum.
4. ✅ **abilities_modal.dart** (1809 lines) → Split into 5 part files via extension methods: main scaffold (484), cards (407), filters (295), sections (372), custom (275). All under 500 lines. Build verified clean.
5. ✅ **ai_system.dart** (1252 lines) → Split into 4 part files: main+terrain helpers (264), `_MonsterAI` (324), `_AllyAI` (222), `_MinionAI` (438). All under 500 lines. Build verified clean.
6. ✅ **ability_editor_panel.dart** (1048 lines) → Split into 3 part files via extension methods: core+logic (476), sections+balance+header (299), field widgets+styles (291). All under 500 lines. Build verified clean.
7. ✅ **combat_hud.dart** (887 lines) → Split into 3 part files via extension: main layout (322), action bar (184), portraits+helpers (388). All under 500 lines. Build verified clean.
8. ✅ **combat_system.dart** (876 lines) → Split into 2 part files: damage pipeline + convenience wrappers (487), enemy/dummy combat via `_CombatAdvanced` + top-level helpers (347). All under 500 lines. Build verified clean.
9. ✅ **ally_behavior_tree.dart** (765 lines) → Split into 3 part files: types+factory+evaluator (221), `_AllyBranches` tree builders (389), `_AllyActions` implementations (183). All under 500 lines. Build verified clean.
10. ✅ **macro_builder_panel.dart** (737 lines) → Split into 2 part files via extension: panel scaffold+state+header (316), list+editor views (427). All under 500 lines. Build verified clean.
11. ✅ **mesh.dart** (615 lines) → Split into 2 part files: core mesh+basic factories (408), `targetIndicator`+`auraDisc` implementations+math helpers (221). All under 500 lines. Build verified clean.
12. ✅ **ley_lines.dart** (606 lines) → Split into 2 part files: data types (193), `LeyLineManager`+`_Intersection` (416). All under 500 lines. Build verified clean.
13. ✅ **stance_editor_panel.dart** (651 lines) → Split into 2 part files via extension: core+state+sections (479), `_tooltips` map+field widgets+styles via `_StanceEditorFields` extension (193). All under 500 lines. Analyze clean (0 new errors).
14. ✅ **minion_frames.dart** (592 lines) → Split into 2 part files via extension: MinionFrames widget+grouping+frame layout (284), `_MinionFrameWidgets` extension with all `_build*`+`_get*` helpers (305). All under 500 lines. Analyze clean (0 new errors).

### ✅ Completed - 2026-02-22

#### Channeled Ability Visual Effects
- ✅ **ChannelEffect enum**: Added `ChannelEffect` enum (none, lifeDrain, blizzard, earthquake, conduit) to `ability_types.dart`. Added `channelEffect` field to `AbilityData` with full serialization support (constructor, copyWith, toJson, fromJson, applyOverrides).
- ✅ **Channel effects overlay**: Created `channel_effects_overlay.dart` — Flutter overlay widget with `CustomPainter` for each effect type:
  - **Life Drain**: 5 purple vortex arcs spiraling from target to caster + bright center stream
  - **Blizzard**: 40 ice crystal diamonds falling from sky in AoE + ground ring
  - **Earthquake**: 35 earth particles erupting in parabolic arcs + ground ring
  - **Conduit**: 3 jagged lightning bolts from sky to target + impact glow + caster connection
- ✅ **Fixed channeled ability execution**: Blizzard, Earthquake, and Conduit now use `_startChanneledAbility` instead of instant execution. Added `channelAoeCenter` field to GameState for AoE positioning. Added dedicated `_executeConduit` function.
- ✅ **Wired overlay into game**: `ChannelEffectOverlay` added to `game3d_widget.dart` widget tree between damage indicators and stance effects.
- ✅ **Editor dropdown**: Added `channelEffect` dropdown to ability editor panel mechanics section, with full save/load/preview support. Users can select a channel effect when editing or creating channeled abilities.
- ✅ Build verified clean (`flutter build web`)

#### Fix Buff/Debuff Display on Target Frame and Active Character
- ✅ **Fixed `_minionIndex` always empty**: `rebuildMinionIndex()` was called during `spawnMinions()` before `refreshAliveMinions()` had populated the cache, building an empty index that was never rebuilt. Fixed by iterating `minions` directly (not the cached `aliveMinions`) and rebuilding each frame in `refreshAliveMinions()`.
- ✅ **Target frame now shows buffs/debuffs**: `currentTargetActiveEffects` getter works correctly now that `_minionIndex` is populated — debuffs on targeted minions/boss display in the `BuffDebuffIcons` widget to the right of the target frame.
- ✅ **Active character effects**: Added `activeCharacterActiveEffects` getter that returns effects for the currently controlled character (Warchief's `playerActiveEffects` or active ally/summon's `activeEffects`). Combat HUD player frame now uses this instead of `playerActiveEffects`.
- ✅ **Buffs and debuffs both display**: `BuffDebuffIcons` widget already renders two rows (buffs on top, debuffs below) — now visible on both the target frame and active character frame.
- ✅ Build verified clean (`flutter build web`)

#### Channeled Abilities, Heal Numbers, Combat Number Settings
- ✅ **Channeling state**: Added `isChanneling`, `channelProgress`, `channelDuration`, `channelingAbilityName`, `channelingSlotIndex` to GameState. `channelPercentage` returns 1.0→0.0 (drains). `cancelChannel()` resets state. Updated `isPerformingAction` to include channeling.
- ✅ **Channeling bar**: Extended `cast_bar.dart` to handle channeling (purple, 0xFF9B59B6). Progress drains from full to empty. Label shows "Channeling". Movement cancels channeling (input_system.dart).
- ✅ **Channeling system**: `updateChannelingState()` in ability_system ticks channel progress and applies periodic damage/heal ticks (1/sec via `_channelTickAccum`). Life Drain converted from projectile to channeled ability.
- ✅ **Green heal numbers**: Added `isHeal` flag to `DamageIndicator`. Heals display in green (0xFF44FF44) with `+` prefix. Added `_showHealIndicator()` helper. Heal indicators added to all 7 heal sites (basic heal, greater heal, lifesteal, generic heal, windshear ally heal, boss dark heal, channel tick heal).
- ✅ **Font size +10% / bolder**: Melee 30→33, ranged 33→36.3. FontWeight `bold`→`w900`.
- ✅ **Killing blow shadows**: Black shadow (blur 4, offset 1,1) + yellow shadow (0xFFFFDD00, blur 8, offset 0,0).
- ✅ **Combat Number settings**: Added `showDamageNumbers`, `showHealNumbers`, `showChannelBar` (bool), `damageNumberScale` (double) to `GameplaySettings` with SharedPreferences persistence.
- ✅ **Settings UI**: "Combat Numbers" section in General tab with toggles for damage/heal numbers and channel bar, plus a slider for number scale (50%–200%).
- ✅ **Settings wired to rendering**: Damage/heal indicators filtered by settings in `DamageIndicatorOverlay.build()`. Font size multiplied by `damageNumberScale`. Channel bar hidden when `showChannelBar` is false in `cast_bar.dart`.
- ✅ Build verified clean (`flutter build web`)

#### Summon Skeleton Mage + Skeleton Specialization
- ✅ **Summon Skeleton Mage ability**: New `summonSkeletonMage` ability in `NecromancerAbilities` (blue-tinted, 30s cooldown, 60s duration). Registered in `all` list, legacy access in `abilities_config.dart`, switch case + mana cost (60 blue) in `ability_system.dart`.
- ✅ **Skeleton Warrior (red melee)**: Red mana attunement via `temporaryAttunements`, 50 red mana pool, action bar pre-loaded with Sword, Heavy Strike, Whirlwind, Crushing Blow, Charge.
- ✅ **Skeleton Mage (blue caster)**: Blue mana attunement, 100 blue mana pool, 20 HP, 1.8 move speed, action bar pre-loaded with Fireball, Frost Bolt, Arcane Missile, Ice Shard, Frost Nova.
- ✅ **Doubled durations**: Both summon abilities and spawn methods use 60s (up from 30s).
- ✅ **Refactored spawn helpers**: Extracted `_summonSpawnPosition()` and `_setupSummonActionBar()` to share logic between both spawn methods.
- ✅ Build verified clean (`flutter build web`)

#### Summon Skeleton: Controllable Summoned Units
- ✅ **Ally model fields**: Added `isSummoned`, `summonDuration`, `summonDurationMax`, `name` fields to `Ally` class with constructor defaults.
- ✅ **GameState helpers**: Added `isActiveSummoned`, `activeActionBarSlots` getters, `tickSummonDurations(dt)` for auto-despawn, and `spawnSummonedSkeleton()` to create bone-colored cube ally with 30s lifespan.
- ✅ **Ability system**: Replaced `_executeSummonSkeleton` stub with real spawn call. Skeleton spawns 3 units in front of caster at terrain height.
- ✅ **Action bar delimitation**: Summoned units show only 5 action bar slots (Row 2 hidden). Player characters retain all 10 slots.
- ✅ **Abilities Codex lock**: Drag-to-action-bar disabled when controlling a summoned unit. Visual indicator "(Summoned unit — action bar locked)" shown in Codex header.
- ✅ **Duration ticking**: `tickSummonDurations(dt)` called each frame in game3d_widget update loop. Expired summons auto-despawn with console log. Control returns to Warchief if active summon expires.
- ✅ **Character switching**: Summoned units fully participate in `[`/`]` cycling alongside Warchief and permanent allies.
- ✅ Build verified clean (`flutter build web`)

#### Console.log Tab in Chat Panel
- ✅ **New Console tab**: Added 4th tab to the AI Chat panel (Spirit, Raid, Combat, **Console**) with green terminal theme and INFO/WARN/ERR level prefixes.
- ✅ **Console log model**: Created `console_log_entry.dart` with `ConsoleLogLevel` enum (info, warn, error) and `ConsoleLogEntry` class.
- ✅ **Console log tab widget**: Created `console_log_tab.dart` following `combat_log_tab.dart` pattern — green-themed, monospace, reverse-chronological, color-coded by level.
- ✅ **GameState integration**: Added `consoleLogMessages` list and `addConsoleLog()` helper with automatic trimming (>250 → keep 200).
- ✅ **Ability system logging**: All ability executions log to console. Blocked abilities log with reason (cooldown, casting, range, mana, attunement). 6 stub abilities (Summon Skeleton, Taunt, Fortify, Smoke Bomb, Sprint, Battle Shout) log as ERR with "STUB" label.
- ✅ **Mana failure logging**: All 4 mana colors log insufficient mana with current/required amounts.
- ✅ **Stance switch logging**: Logged to console on every stance change.
- ✅ **Target change logging**: Logged on setTarget() and clearTarget().
- ✅ Build verified clean (`flutter build web`)

### ✅ Completed - 2026-02-21

#### Project Documentation Overhaul
- ✅ **Rewrote root CLAUDE.md**: Removed stale Mojo/Python/RAG references. Now accurately describes the Flutter/Dart game project with mandatory doc-reading instructions.
- ✅ **Rewrote warchief_game/CLAUDE.md**: Added complete file map with line counts, subsystem doc references (read-before-explore table), oversized file split roadmap, architecture patterns, game loop description, and key dependency list.
- ✅ **Archived 12 stale docs**: Moved completed/historical documentation to `warchief_game/docs/archive/` (PHASE1_COMPLETE.md, TERRAIN_FIXES_COMPLETE.md, TERRAIN_RESEARCH.md, PERFORMANCE_FIXES_COMPLETED.md, PERFORMANCE_MITIGATION_PLAN.md, ROLLBACK_PLAN.md, GAME_BEHAVIOR_CHECKLIST.md, GOALS_SYSTEM_DESIGN.md, AI_INTEGRATION.md, CLAUDE_TASK_TEMPLATE.md, ABILITY_TEST_EVALUATION.md, WARCHIEF-CONTEXT-ENGINEERING-PROMPT.md).
- ✅ **Audited all 218 source files**: Identified 14 files exceeding the 500-line limit with specific split strategies for each.
- ✅ **Minimap position fix**: Fixed InterfaceConfig default position for minimap from Offset(0,0) to Offset(1410,8) — was rendering hidden behind the instructions overlay.

#### Optimization & Tech Debt Fixes
- ✅ **dart:math delegation**: Replaced 32 lines of custom Taylor/Newton math approximations in game_state.dart with 4 one-liner delegates to `dart:math` (hardware-accelerated, more accurate).
- ✅ **Controller memory leak fix**: stance_editor_panel.dart now reuses TextEditingControllers on stance switch instead of recreating 26 controllers per switch.
- ✅ **Combat log trim standardization**: All 10 trim sites across 3 files now consistently use `> 250 → removeRange(0, len - 200)` instead of mixed `> 200 → removeAt(0)` patterns.
- ✅ **Resize handle deduplication**: Replaced 170 lines of 8 near-identical resize handles in abilities_modal.dart with a 110-line `_buildResizeHandles()` helper.
- ✅ **ActiveStance getter caching**: combat_system.dart now caches `gameState.activeStance` once before the dodge check instead of calling the getter 3 times (each call does registry lookup + override merge + copyWith).

#### Tab Targeting Improvements (WoW-inspired)
- ✅ **Melee range priority tier**: Three-tier sorting — enemies within melee range (≤5 units) are always first, sorted by distance. Then front-cone (≤60°) sorted by angle. Then everything else by distance. Melee characters always tab to the closest hittable enemy.
- ✅ **Max range filter**: Enemies beyond 50 units are excluded from tab targeting entirely. Prevents tab-targeting distant enemies you can't reach.
- ✅ **First-tab selects best target**: First tab press with no target selects index 0 (nearest/best priority) instead of skipping to index 1. Subsequent presses cycle through the sorted list.
- ✅ **Fresh sort on each keypress**: Cache is invalidated on each tab press so the sort reflects current positions and facing direction, not a 0.2s-stale snapshot.
- ✅ **Active character targeting**: Input handler now uses `activeTransform`/`activeRotation` instead of `playerTransform` — fixes tab targeting when controlling allies.
- ✅ **Auto-target on hit**: When the player takes damage with no current target, automatically acquires the nearest enemy (WoW behavior).
- ✅ **Auto-target on kill**: When current target dies, automatically picks the next nearest enemy so melee players keep swinging without manual re-targeting.
- ✅ **Fixed sort comparator**: Replaced lossy `.toInt()` and `.sign.toInt()` comparisons with proper `.compareTo()` for correct double ordering.
- ✅ Build verified clean (`flutter build web`)

#### Abilities Codex Resizable Panel
- ✅ **Resizable borders**: All 4 edges and 4 corners of the Abilities Codex panel are draggable to resize. Right/bottom expand, left/top expand while shifting position to keep the opposite edge anchored.
- ✅ **Size constraints**: Min 500x400, max 1200x900 to prevent over/under-sizing.
- ✅ **Cursor feedback**: MouseRegion wrappers show appropriate resize cursors (resizeColumn, resizeRow, resizeDownRight, resizeUpLeft, etc.) on hover.
- ✅ **Header drag-to-move**: Panel repositioning now only triggers from the header bar (not the entire panel surface), so resize handles don't conflict with dragging.
- ✅ **Dynamic layout**: Panel width/height stored as state variables (`_panelWidth`, `_panelHeight`), replacing hardcoded 750x600. Editor panel total width calculation uses dynamic width.
- ✅ Build verified clean (`flutter build web`)

#### Combat Stance Revamp: 5-Way Rock-Paper-Scissors Metagame
- ✅ **7 new StanceData fields**: Added `spellPushbackInflicted`, `spellPushbackResistance`, `ccDurationInflicted`, `ccDurationReceived`, `lifestealRatio`, `dodgeChance`, `manaCostDisruption` to `stance_types.dart` with constructor defaults, `copyWith`, `applyOverrides`, and `modifierSummary`.
- ✅ **Parsing**: Added 7 new fields to `_parseStance()` in `stance_definitions.dart` with safe `?.toDouble() ?? default` pattern.
- ✅ **Revised stance values**: Updated `stance_config.json` with rebalanced multipliers for all 5 stances creating a pentagonal RPS graph (Fury>BW/Drunken, Tide>Fury/Phantom, Phantom>Fury/Drunken, Drunken>Tide/BW, BW>Phantom/Tide).
- ✅ **Dodge mechanic**: In `combat_system.dart`, player dodge check before damage application. Uses static `math.Random` instance. Shows "DODGED" in combat log. Skipped for target dummy.
- ✅ **Spell pushback**: In `combat_system.dart`, after player takes damage while casting, pushes back `castProgress` by `castTime * 0.25 * (1 - resistance)`. Capped at 3 pushbacks per cast via `castPushbackCount` on GameState. Tide immune (1.0 resistance).
- ✅ **Lifesteal**: `_applyLifesteal()` helper in `ability_system.dart`. Heals by `damage * lifestealRatio` (NOT modified by healingMultiplier). Called at all hit points: `_autoHitCurrentTarget`, `_damageTargetWithProjectile`, non-homing projectile hits, AoE hits (Whirlwind, Frost Nova, generic AoE).
- ✅ **CC duration modifiers**: `_applyMeleeStatusEffect()`, `_applyDoTFromProjectile()`, and Fear effect multiply status duration by `activeStance.ccDurationInflicted`.
- ✅ **Stance editor**: Added COMBAT INTERACTIONS section with 7 new fields, controllers, populate, dispose, override map, and tooltips in `stance_editor_panel.dart`.
- ✅ Build verified clean (`flutter build web`)

#### Ability Category Reordering in Codex
- ✅ **AbilityOrderManager**: Created `lib/game3d/state/ability_order_manager.dart` — per-category ability ordering persisted via SharedPreferences. Stores `Map<String, List<String>>` keyed by category name. Reconciles with registry on access (new abilities appended, removed abilities pruned). Global `globalAbilityOrderManager` instance.
- ✅ **Reorderable ability lists**: Each category in the "Potential Future Abilities" section uses `ReorderableListView.builder` for drag-to-reorder. Drag handle icons on the left of each card. `onReorder` callback saves order via manager.
- ✅ **Slot number badges**: First 10 abilities in each category show numbered badges (1–9, 0) matching action bar hotkey slots, so the user knows which abilities will load.
- ✅ **Load to Action Bar uses order**: `_loadClassToActionBar` now loads abilities in user-defined order via `globalAbilityOrderManager.getOrderedAbilities()`.
- ✅ **Reset custom order**: Categories with custom order show a reset icon to revert to default registry order.
- ✅ **Initialization**: `globalAbilityOrderManager` initialized in `game3d_widget.dart` alongside other managers.
- ✅ Build verified clean (`flutter build web`)

### ✅ Completed - 2026-02-20

#### Auto-Hit for Melee and Ranged Abilities
- ✅ **Auto-hit intended target**: Melee and ranged abilities that can be successfully cast now automatically hit the intended target — no collision check needed. Uses `_autoHitCurrentTarget()` helper that routes damage to the specific target type (boss, minion, dummy) by ID.
- ✅ **Face target on strike**: All melee abilities (`updateAbility1`, `_executeHeavyStrikeEffect`, `_executeCrushingBlowEffect`, `_executeGenericWindupMelee`) call `_faceCurrentTarget()` to rotate the character toward the target before dealing damage.
- ✅ **Homing projectile auto-hit**: Homing ranged projectiles (ability 2) auto-hit at 2.5-unit threshold and skip general collision checks, preventing interception by non-targeted enemies.
- ✅ **Collision fallback**: When no target is selected, all abilities fall back to collision-based detection in the forward direction (legacy behavior preserved).
- ✅ **Piercing unaffected**: AOE abilities (Whirlwind) and non-homing projectiles retain collision-based detection for hitting non-targeted units.
- ✅ **Side effects preserved**: `_autoHitCurrentTarget()` handles red mana generation, melee streak tracking, kill goal events, and alive minion refresh — matching the side effects of the collision-based path.
- ✅ Build verified clean (`flutter build web`)

#### Blue Ley Line Overlay Enhancement
- ✅ **Thicker ley lines**: Line width multiplied by 2.5x with a soft glow layer underneath (3x width, pulsing opacity). Lines use rounded caps for cleaner visuals.
- ✅ **Prominent power nodes**: Nodes now render with four layers — outer pulsing glow ring, pulsing stroke ring border, solid core circle (1.2x radius), and bright center highlight. All pulse with elapsed time.
- ✅ **Blue mana attunement gate**: Ley lines and power nodes only render when `activeManaAttunements.contains(ManaColor.blue)` AND toggle is enabled. Replaces old `hideLeyLinesByAttunement` logic (which was gated behind `manaSourceVisibilityGated` setting).
- ✅ **Toggle icon**: Hub/network icon (Icons.hub) on minimap border at top-right (below green toggle when both attuned). Click toggles `minimapState.showBlueOverlay` on/off. Blue when active, dim when inactive. Tooltip shows "Show/Hide ley lines".
- ✅ **Entity painter gated**: Ley power node diamonds in `MinimapEntityPainter` also gated behind the same blue attunement + toggle check.
- ✅ **State**: Added `showBlueOverlay` boolean to `MinimapState` (defaults to true).
- ✅ Build verified clean (`flutter build web`)

#### Minimap Green Mana Source Overlay
- ✅ **Green mana overlay painter**: Created `minimap_green_painter.dart` — CustomPainter drawing three layers of green mana source information:
  - **Grass zones**: Coarse grid (4px step) sampling terrain height, tinting areas with grass weight in translucent green. Uses the same normalized height formula (0.15-0.65 range, peak at 0.4) as the actual green mana regen calculation.
  - **Spirit being auras**: Pulsing green rings around allies in spirit form, showing the `spiritBeingRadius` (6.0 units default) within which they broadcast 3.0/sec green mana regen. Leaf icon at center.
  - **Nature creatures**: Prominent pulsing glow rings + leaf icon around elemental and beast faction minions (e.g. Dryad Lifebinder). These are the "natural creatures that replenish high amounts of green mana."
  - Also shows proximity radius rings around green-attuned allies (green mana proximity regen sources).
- ✅ **Green mana attunement gate**: Overlay only renders when `activeManaAttunements.contains(ManaColor.green)`. Toggle icon also only appears when green-attuned.
- ✅ **Toggle icon**: Eco leaf icon (Icons.eco) on minimap border at top-right corner. Click toggles `minimapState.showGreenOverlay` on/off. Green when active, dim when inactive. Tooltip shows "Show/Hide green mana sources".
- ✅ **Layer ordering**: Green overlay placed between terrain and entity layers so grass zones appear beneath entity blips.
- ✅ **State**: Added `showGreenOverlay` boolean to `MinimapState` (defaults to true).
- ✅ Build verified clean (`flutter build web`)

#### Minimap Wind Overlay
- ✅ **Wind overlay painter**: Created `minimap_wind_painter.dart` — CustomPainter drawing animated dashed flow lines across the minimap in the wind direction. Line opacity/count scales with wind strength. Lines scroll along the wind direction for animated flow effect. Handles both rotating and fixed-north minimap modes.
- ✅ **Derecho prominence**: During derecho storms, overlay intensifies with orange pulsing radial glow, thicker/brighter flow lines that lerp from blue-white to orange with intensity, and a "DERECHO" label at top of minimap that fades in above 30% intensity.
- ✅ **White mana attunement gate**: Overlay only renders when the active character's `activeManaAttunements` contains `ManaColor.white`. Toggle icon also only appears when white-attuned.
- ✅ **Toggle icon**: Wind icon (Icons.air) added to minimap border at top-left corner. Click toggles `minimapState.showWindOverlay` on/off. Icon is blue-silver when active, dim when inactive, pulses orange during derecho. Tooltip shows "Show/Hide wind overlay".
- ✅ **State**: Added `showWindOverlay` boolean to `MinimapState` (defaults to true).
- ✅ Build verified clean (`flutter build web`)

#### Simplify Movement+Damage Abilities
- ✅ **Target-seeking dashes**: Non-AOE abilities with movement+damage now move the character toward the targeted enemy instead of dashing straight forward. Dash snaps player rotation to face target during travel.
- ✅ **Guaranteed hits**: Targeted dashes always deal damage on arrival — no collision check needed (uses `collisionThreshold: 999.0`). Damage applies when player arrives within 1.5 units or at 90% of dash duration, whichever comes first.
- ✅ **Unified `_startDash()` helper**: All dash-type abilities now go through a single `_startDash()` method that stores the ability data, duration, and snapshot of target position. Replaces 6 separate manual ability4 setups.
- ✅ **Auto-routing for generic melee gap-closers**: `_executeGenericMelee()` detects abilities with range >= 4.0 (non-AOE) and routes them through the dash system automatically. Covers Umbral Lunge, Storm Surge, Shoulder Charge, and any future gap-closers.
- ✅ **`getCurrentTargetPosition()`**: New GameState method returning the world position of the current target (boss, minion, dummy, or ally), used by dash targeting.
- ✅ **Abilities converted**: Dash Attack, Charge, Gale Step, Flying Serpent Strike, Wind Warp (ground), plus all data-driven melee gap-closers via the generic routing.
- ✅ **No-target fallback**: If no target is selected, dashes move straight forward with original collision detection (legacy behavior preserved).
- ✅ Build verified clean (`flutter build web`)

#### Flight Mechanics Enhancements
- ✅ **Groundspeed HUD**: Added `flightGroundSpeed` field to `GameState`, displayed in `FlightBuffIcon` alongside altitude (`Alt: X.X  Spd: X.X`)
- ✅ **Double-tap hard banking**: Q/E double-tap within configurable window (0.3s default) activates 50% faster bank rate and 90-degree max bank angle. Static timing fields in `InputSystem` with edge-detection on key release/press
- ✅ **Spacebar speed boost**: Spacebar now boosts flight speed (1.8x default) at cost of white mana (8.0/s default), replacing the old air brake + upward bump behavior
- ✅ **Turn speed reduction**: Yaw rate tracked per frame; groundspeed reduced proportionally to turn rate (up to 30% at max turn). Simulates aerodynamic drag
- ✅ **Config values**: Added 6 new flight config entries to `wind_config.json` and `WindConfig` getters: `doubleTapWindow`, `hardBankRateMultiplier`, `hardBankMaxAngle`, `spaceBoostMultiplier`, `spaceBoostManaCostPerSecond`, `turnSpeedReductionFactor`
- ✅ **Tuning tab**: All new config fields added to Wind > FLIGHT section in Tuning tab with tooltips
- ✅ Build verified clean (`flutter build web`)

#### Runtime Config Editing (Tuning Tab)
- ✅ **Override persistence for 5 config classes**: Added `_overrides` map, `_loadOverrides()`, `_saveOverrides()`, `setOverride()`, `clearOverride()`, `clearAllOverrides()`, `hasOverride()`, `overrides` getter, `getDefault()` to WindConfig, BuildingConfig, MinimapConfig, MacroConfig, GoalsConfig — all using SharedPreferences with unique storage keys
- ✅ **GameConfig conversion**: Converted from static `const`/`final` class to JSON-loaded instance class following ManaConfig pattern. Static getters delegate to global instance for zero call-site changes. Created `assets/data/game_config.json` with all values including Vector3 color components. Auto-creates instance in `_i` getter for safe field-initializer access. Added override persistence (SharedPreferences key `game_config_overrides`)
- ✅ **Generic ConfigEditorPanel**: Created `lib/game3d/ui/settings/config_editor_panel.dart` — reusable config editor widget taking `ConfigSectionDef` and `ConfigCallbacks`. Supports double, int, bool, and string field types. Save persists only changed fields as overrides, Restore Defaults clears all overrides. Same visual style as AbilityEditorPanel (dark theme, cyan accents, section grouping)
- ✅ **Tuning tab in Settings**: Created `lib/game3d/ui/settings/tuning_tab.dart` — new "Tuning" tab in Settings panel with sub-navigation for 7 config systems: Game (9 sections), Mana (3 sections), Wind (8 sections), Buildings (1 section), Minimap (8 sections), Macros (3 sections), Goals (1 section). Each renders a ConfigEditorPanel with complete field definitions and tooltips
- ✅ **Settings panel integration**: Added Tuning tab to `settings_panel.dart` tab list between General and Interfaces
- ✅ Build verified clean (`flutter build web`)

#### Editable Stance System
- ✅ **StanceData.copyWith() + applyOverrides()**: Added `copyWith()` with all 22 stance fields and `applyOverrides(Map<String, dynamic>)` with sparse override merging, Vector3 color [r,g,b] list handling, and bool support
- ✅ **StanceOverrideManager**: Created `lib/game3d/state/stance_override_manager.dart` — sparse override persistence (SharedPreferences key `stance_overrides`), `getEffectiveStance()`, `setOverrides()`, `clearOverrides()`, `hasOverrides()`, `loadOverrides()`, global `globalStanceOverrideManager`
- ✅ **Barrel Export**: Updated `lib/game3d/data/stances/stances.dart` to re-export `stance_override_manager.dart`
- ✅ **Initialization**: Wired `_initializeStanceOverrides()` in `game3d_widget.dart` alongside other config singletons
- ✅ **activeStance Getter**: Modified `game_state.dart` to apply user overrides via `globalStanceOverrideManager.getEffectiveStance()` between base registry lookup and Drunken Master random roll; simplified Drunken Master branch to use `copyWith()` instead of full constructor
- ✅ **StanceEditorPanel**: Created `lib/game3d/ui/stance_editor_panel.dart` (~400 lines) — side-panel editor with sections: IDENTITY (name read-only, description editable), MULTIPLIERS (9 double fields), PASSIVES (8 doubles + 3 bool toggles), SWITCHING (switchCooldown), VISUAL (color RGB); Save builds sparse override map, Restore Defaults clears overrides; tooltips on all fields
- ✅ **StanceCardsSection Double-Tap**: Added `onDoubleTap` callback prop to `StanceCardsSection` in `stance_selector.dart`, wired to open `StanceEditorPanel` in abilities modal
- ✅ **Override Indicator**: Yellow edit icon shown on stance cards with active overrides; modifier summary displays effective (overridden) values
- ✅ **Abilities Modal Integration**: Added `_editingStance` state to `abilities_modal.dart`, mutually exclusive with ability editor (opening one closes the other), total width accounts for either editor panel
- ✅ Build verified clean (`flutter build web`)

### ✅ Completed - 2026-02-19

#### Exotic Stance System
- ✅ **Data Layer**: Created `assets/data/stance_config.json` with 5 exotic stances (Drunken Master, Blood Weave, Tide, Phantom Dance, Fury of the Ancestors) — all values config-driven, not hardcoded
- ✅ **Stance Types**: Created `lib/game3d/data/stances/stance_types.dart` — `StanceId` enum, `StanceData` class with all modifiers, passive mechanics, modifier summary builder
- ✅ **Stance Registry**: Created `lib/game3d/data/stances/stance_definitions.dart` — `StanceRegistry` singleton loading from JSON config, icon/color parsing, global accessor
- ✅ **Barrel Export**: Created `lib/game3d/data/stances/stances.dart`
- ✅ **GameState Integration**: Added stance fields (`playerStance`, `stanceSwitchCooldown`, `stanceActiveTime`, Drunken re-roll fields), `activeStance` getter (with Drunken random modifier substitution), `switchStance()` (with HP proportion scaling), `cycleStance()`, `updateStanceTimers()` (Fury drain, Drunken re-rolls, cooldown ticking), `generateManaFromDamageTaken()` (Tide passive)
- ✅ **Ally Model**: Added `currentStance` field to `Ally`
- ✅ **Movement Speed**: Applied `movementSpeedMultiplier` in `effectivePlayerSpeed` getter
- ✅ **Max Health**: Applied `maxHealthMultiplier` in `playerMaxHealth` getter
- ✅ **Damage Output**: Applied `damageMultiplier` in melee hits (`updateAbility1`), projectile impacts (`_damageTargetWithProjectile`, `updateAbility2` collision), AoE (`_executeGenericAoE`)
- ✅ **Damage Taken**: Applied `damageTakenMultiplier` in `combat_system.dart` for `DamageTarget.player`
- ✅ **Tide Passive**: Damage-to-mana conversion in combat_system after player damage
- ✅ **Cooldowns**: Applied `cooldownMultiplier` in `_setCooldownForSlot()`
- ✅ **Cast/Windup Time**: Applied `castTimeMultiplier` in `_startCastTimeAbility()` and `_startWindupAbility()`
- ✅ **Healing**: Applied `healingMultiplier` in `_executeHeal()` and `_executeGenericHeal()`
- ✅ **Mana Costs**: Applied `manaCostMultiplier` in `_executeAbilityByName()`, Blood Weave HP-for-mana substitution for instant and deferred (cast/windup) abilities
- ✅ **Mana Regen**: Applied `manaRegenMultiplier` in `updateManaRegen()`, `updateWindAndWhiteMana()`, `updateGreenManaRegen()`; Blood Weave `convertsManaRegenToHeal` converts all mana regen to HP healing
- ✅ **Fury Health Drain**: 2% max HP/second in `updateStanceTimers()`, clamped to 1 HP, combat log on critical threshold
- ✅ **Drunken Re-rolls**: Independent damage/damageTaken re-rolls every 3s in `updateStanceTimers()`, combat log on re-roll
- ✅ **Stance Selector UI**: Created `lib/game3d/ui/stance_selector.dart` — compact icon (always visible) + expandable vertical list (X key), click to select, cooldown overlay, tooltips with modifier summary
- ✅ **Stance Cards in Abilities Modal**: Added `StanceCardsSection` to abilities modal (P key) showing all 5 stances as cards with descriptions and modifier breakdowns
- ✅ **Keyboard Controls**: X key toggles stance selector, Shift+X cycles stances
- ✅ **Combat Log**: Stance switch logging, Drunken re-roll logging, Fury critical HP logging
- ✅ **Game Loop**: `updateStanceTimers(dt)` wired into `_update()`, stance registry initialized in `initState()`
- ✅ **Persistence**: Stance selections saved/loaded via SharedPreferences (`stance_player`, `stance_ally_N` keys), auto-saves on switch, loads after stance registry initialization
- ✅ **Visual Effects**: Created `lib/game3d/ui/stance_effects_overlay.dart` — Drunken Master purple tint pulse on re-roll (0.4s fade), Fury of the Ancestors red vignette intensifying as HP drops (visible below 80% HP)
- ✅ **Clickable Stance Icon Bar**: Created `lib/game3d/ui/unit_frames/stance_icon_bar.dart` — row of 6 clickable stance icons (None + 5 exotic) displayed above the player health bar in CombatHUD. Active stance is prominently highlighted with glowing colored border, larger size (30px vs 24px), and colored background. Tooltips show stance name, description, and modifier summary. Respects switch cooldown.
- ✅ **Default Stance**: Added `defaultStance` field to `StanceRegistry` loaded from config JSON (set to Tide). All characters initialize with the default stance when no saved preference exists.
- ✅ **Damage Modifier Audit**: Fixed missing `damageMultiplier` on 7 named ability damage paths — Frost Nova, Heavy Strike, Whirlwind, Crushing Blow, windup melee completion, Cyclone Dive, Dash Attack. Fixed missing `healingMultiplier` on Greater Heal (hardcoded 50.0).
- ✅ **Movement Speed Audit**: Fixed missing stance `movementSpeedMultiplier` on flight speed (input_system.dart), ally `activeEffectiveSpeed` (game_state.dart), and dash attack speed (ability_system.dart). Ground WASD/QE movement already had it via `effectivePlayerSpeed`.
- ✅ Build verified clean (`flutter build web`)

### ✅ Completed - 2026-02-18

#### Fighting Game Melee Abilities + Generic Melee Damage Fix
- ✅ **Part A: Fixed generic melee damage system** — `_executeGenericMelee()` now stores active ability on `gameState.activeGenericMeleeAbility` so `updateAbility1()` reads damage/range/impactColor from AbilityData instead of hardcoded `playerSword` values; `_executeGenericWindupMelee()` now reads damage/range/impact from AbilityData instead of hardcoded 40.0/2.5/3.5; added `activeGenericMeleeAbility` nullable field to `GameState`
- ✅ **Part B: Added 35 new melee abilities across 12 categories** — fighting game-inspired combo abilities:
  - Warrior (5): Gauntlet Jab, Iron Sweep, Rending Chains, Warcry Uppercut, Execution Strike
  - Rogue (5): Shiv, Shadowfang Rake, Shadow Spike, Umbral Lunge, Death Mark
  - Windwalker (3): Zephyr Palm, Cyclone Kick, Stormfist Barrage
  - Spiritkin (4): Thornbite, Barkhide Slam, Bloodfang Rush, Primal Rend
  - Stormheart (4): Spark Jab, Chain Shock, Storm Surge, Thundergod Fist
  - Elemental (2): Frostbite Slash, Magma Strike
  - Nature (2): Briar Lash, Ironwood Smash
  - Mage (2): Arcane Pulse, Rift Blade
  - Necromancer (2): Grave Touch, Soul Scythe
  - Healer (2): Holy Smite, Judgment Hammer
  - Utility (2): Quick Slash, Shoulder Charge
  - Greenseer (2): Lifebloom Touch, Thornguard Strike
- ✅ **Part C: Added case labels in ability_system.dart** — all 35 new abilities routed through `_executeGenericAbility()` via data-driven dispatch
- ✅ Build verified clean (`flutter build web`)
- ✅ All category files remain under 500 lines

#### Abilities Codex: Mana Cost Display + Balance Rating System
- ✅ Created `ability_balance.dart` — `ManaColorDisplay` extension (display colors matching mana bar midpoints), `computeBalanceScore()` pure function (power vs cost, clamped -1..1), `_statusEffectValue()` helper, `balanceScoreColor()` (red→yellow→green), `balanceScoreLabel()` (WEAK/BELOW AVG/BALANCED/ABOVE AVG/STRONG/OP)
- ✅ Added `export 'ability_balance.dart'` to `abilities.dart` barrel file
- ✅ Updated `abilities_modal.dart` — added mana color dots + cost to both `_buildAbilityCard` and `_buildCustomAbilityCard` stats rows, added balance indicator row below stats, added `_buildManaStat()` and `_buildBalanceIndicator()` helper widgets
- ✅ Updated `ability_editor_panel.dart` — added `_buildPreviewAbility()` (constructs AbilityData from current editor fields), `_buildEditorBalancePreview()` colored badge in header, live-update listeners on all balance-relevant text controllers
- ✅ Build verified clean (`flutter build web`)

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
