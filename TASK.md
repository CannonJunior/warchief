# Task Tracking

## Current Tasks

### In Progress — Historically-Accurate Weapon System

5 weapon categories × 3 types = 15 weapons with historically-faithful combat mechanics. Weapons modify ability cooldowns, combo mechanics, damage-vs-armor effectiveness, and stance synergies.

#### Phase 1: Data Foundation
- ✅ **1a. New enums** — `WeaponCategory` (6 values), `WeaponType` (16 values), `ArmorCategory` (4 values) + display extensions in `lib/models/item.dart`
- ✅ **1b. Item fields** — `weaponCategory`, `weaponType`, `armorCategory` nullable fields on `Item` with full serialization
- ✅ **1c. Monster armor** — `armorCategory` field on `MonsterDefinition` in `lib/models/monster_ontology.dart`
- ✅ **1d. Weapon config JSON** — `assets/data/weapon_config.json` with 15 weapon type definitions, armor effectiveness matrix, 10 stance synergies, 5 combo modifiers
- ✅ **1e. Config loader** — `lib/game3d/state/weapon_config.dart` singleton following ComboConfig pattern
- ✅ **1f. Init** — `_initializeWeaponConfig()` in `game3d_widget_init.dart`, called from `game3d_widget.dart`
- ✅ **1g. Items** — 15 new weapon items in `items.json`, existing weapons/armor classified with categories

#### Phase 2: Combat Integration
- ✅ **2a. Data classes** — `lib/game3d/data/weapon_types.dart`: `WeaponModifiers`, `WeaponStanceSynergy`
- ✅ **2b. Weapon system** — `lib/game3d/systems/weapon_system.dart`: modifier lookup, armor effectiveness, special mechanics (halfSwording, hookShield, cleave, concussiveForce, armorPierce, shieldBreaker, parryBypass, wrapAround, unpredictable, hookPull, sweepingBlow, firstStrike, versatileStrike)
- ✅ **2c. Cooldown hook** — `ability_system_dispatch.dart`: weapon cooldown multiplier in `_setCooldownForSlot`
- ✅ **2d. Damage hook** — `ability_system_interactions.dart`: weapon damage + armor effectiveness + special mechanics in `_autoHitCurrentTarget`
- ✅ **2e. Game state** — `monsterArmorCategory` field, `ArmorCategory` import

#### Phase 3: Combo Integration
- ✅ **3a. Threshold/window mods** — `melee_combo_system.dart`: weapon category modifies combo threshold (+1 hammers, -1 chains) and window duration
- ✅ **3b. Chain bonuses** — `_applyWeaponChainBonus`: hammers add stun, axes add knockback, polearms add grip on chain finishers

#### Phase 4: Stance Synergies
- ⬜ **4a. Stance hooks** — `ability_system_stance_hooks.dart`: weapon-stance synergy lookups per stance function

#### Phase 5: UI Updates
- ⬜ **5a. Character panel** — weapon type tooltip on mainHand slot
- ⬜ **5b. Bag panel** — effectiveness hints on weapon tooltips
- ⬜ **5c. Combat HUD** — target armor category indicator

#### Build Status
- ✅ `flutter analyze --no-pub` — 0 errors (50 pre-existing info/warning issues)

---

### ✅ Completed - 2026-06-24

#### Stance Revamp — 7 Playstyle-Altering Stances
Replaced the stat-multiplier-only stance paradigm with 7 new stances that alter playstyle, tactics, and ability interactions. Research-informed by Nioh, Sekiro, DMC, Ghost of Tsushima, Crimson Desert, Replaced, 007 First Light, and LEGO Batman. See `STANCE_REVAMP.md` for full design docs.

- ✅ **Data layer**: `StanceMechanics` class (65 configurable properties), `StanceData.mechanics` field, 7 new `StanceId` enum values, JSON config with all stance definitions
  - `stance_mechanics.dart` (new, 326 lines), `stance_types.dart` (updated), `stance_definitions.dart` (updated), `stance_config.json` (updated)
- ✅ **Runtime state**: `StanceRuntimeState` class tracking beat timers, groove stacks, chain depth, heat, momentum stacks, pressure gauges per target with damage school tracking, flux transition/memory/weave/stagnation timers
  - `stance_runtime_state.dart` (new, 165 lines)
- ✅ **Runtime system**: Per-frame update + event handlers for all 7 stances
  - `stance_runtime_system.dart` (new, 430 lines)
- ✅ **Ability pipeline hooks**: Pre-execution mods, on-hit notifications, on-cast notifications
  - `ability_system_stance_hooks.dart` (new, 497 lines)
  - **Cadence**: beat timing + Groove stacks + on-beat damage/CD/mana bonuses
  - **Tempest**: windup/cast reduction + cancel-chain GCD skip + escalating damage + channel tick speed
  - **Warden**: directional input recording + per-direction ability modifiers + Predator's Eye stealth first-strike
  - **Crucible**: half-cooldowns + heat accumulation + overheat silence (interrupts casts) + 0-Heat payoff + crit heat reduction
  - **Momentum**: per-stack bonuses + stack decay + max-stack splash damage to nearby enemies + Kinetic Overflow cross-domain bonus
  - **Pressure**: gauge building per target + damage school tracking + elemental Break variants (Shatter/Ignition/Deep Freeze/Overload/Void Collapse) + stun + damage amp + cooldown reset
  - **Flux**: transition bonus (instant/free/+50%) + Memory cooldown reset on return + Weave State heal-per-switch + stagnation penalty
- ✅ **Effect application**: Pressure Break (stun + vulnerability + CD reset), Crucible Overheat (silence + cast interrupt), Warden Exposed (vulnerability debuff), Momentum splash (AoE damage), Kinetic Overflow, Flux Memory/Weave heal
- ✅ **Input integration**: Warden WASD directional recording in `input_system.dart`
- ✅ **Stance switch hooks**: `onStanceEnter`/`onStanceLeave` in `game_state_stance.dart` with Flux Memory CD reset and Weave heal
- ✅ **Mana refund pipeline**: `activeRefund{Blue,Red,White,Green,Black}Mana` helpers on GameState
- ✅ **UI**: `StanceMechanicHud` widget (401 lines) — per-stance indicators: Cadence beat pulse arc + Groove dots, Tempest chain counter, Warden directional arrow + Predator badge, Crucible heat gauge bars, Momentum stack dots + splash indicator, Pressure target gauge bar, Flux transition/weave/stagnation status badges
- ✅ Build verified: `flutter analyze --no-pub` — 0 errors (46 pre-existing info/warning issues)

### Pending — Displacement & Crowd Control Ability System

A comprehensive CC and displacement ability system expanding beyond the existing stun/freeze/root/silence/fear/blind/knockback/grip/knockdown effects. Adds new status effect types, airborne physics, per-class CC abilities with unique twists on familiar MMO/fighting-game archetypes, and a config-driven diminishing returns system.

**Existing CC infrastructure** (already implemented):
- `StatusEffect` enum: stun, freeze, slow, root, fear, blind, silence, knockback, grip, knockdown, interrupt, weakness, + vulnerability types
- `AbilityStatusEffect` multi-effect list on `AbilityData`
- `ActiveEffect` with duration/strength tracking, icons, colors
- `CcIndicatorOverlay` world-space badges for stun/freeze/root/silence/fear/blind/slow/interrupt
- `_applyStatusEffects()` in `ability_system_interactions.dart` handling displacement + timed effects
- `UnitCollisionSystem` for unit separation physics

---

#### Phase 1: New StatusEffect Types + CC Engine Expansion

Expand the `StatusEffect` enum and wire each new type through the full stack: `ActiveEffect` (icon, color, isBuff/isDebuff), `CcIndicatorOverlay` badge set, `ability_system_interactions.dart` application logic, and AI awareness in `duel_system.dart` / `ai_system.dart`.

- ✅ **1a. Add new StatusEffect enum values** — `ability_types.dart`
  Add 12 new values to the `StatusEffect` enum:
  - `daze` — Soft CC: 50% movement slow + any damage taken interrupts current cast/channel/windup. **Twist**: also resets the target's melee combo chain count, punishing aggressive overextension.
  - `airborne` — Hard CC: unit is launched upward on the Y-axis, cannot act, enables juggle follow-ups from allies. **Twist**: airborne duration extends with ambient wind strength (Windwalker synergy), and landing deals fall damage proportional to launch height.
  - `sleep` — Hard CC: long duration (4–8s), breaks on ANY damage including DoTs. **Twist**: sleeping targets passively regenerate 1% max HP/s (tactical dilemma — you CC them but they heal), and the caster gains +50% mana regen while their sleep target is asleep ("dream siphon").
  - `charm` — Hard CC: target involuntarily walks toward the caster at 60% speed, cannot use abilities. **Twist**: if charmed target passes through allied units, those allies are briefly slowed (the "heartbreak" ripple — a charm so strong it disrupts nearby friends).
  - `polymorph` — Hard CC: transformed into a critter, movement only at 70% speed, breaks on damage. **Twist**: polymorphed targets leave a faintly glowing "spirit trail" on the ground that persists 3s, granting the caster minimap vision along the path. Different classes transform into different critters (frog for nature, sheep for arcane, scarab for shadow).
  - `taunt` — Forced to basic-attack the taunter for duration. Cannot switch targets or use non-melee abilities. **Twist**: taunted targets deal 25% reduced damage to the taunter ("frustration"), but if taunt is cleansed or expires while the taunter is still in range, the victim gains a 2s "Indignation" haste buff.
  - `disorient` — Soft CC: WASD movement directions are remapped (e.g., W=strafe-left, A=backward). Camera slowly sways ±15°. **Twist**: the remapping rotates every 1.5s so the victim can't simply adapt. Spellcasting is allowed but ability queue inputs have a 0.3s random delay applied.
  - `grounded` — Soft CC: prevents all movement abilities (charges, dashes, teleports, flight launch). Normal walking and spellcasting unaffected. **Twist**: grounded targets take +20% damage from `DamageSchool.nature` (rooted to the earth = vulnerable to telluric forces). Visually, thorny vines wrap the target's feet.
  - `suppress` — Hard CC: cannot act, cannot be cleansed by allies, bypasses CC-break abilities. **Twist**: suppression is always a mutual channel — the caster is also locked in place and cannot act, creating a 2-person lockdown that allies on either side must capitalize on or rescue from. Damage to the caster breaks suppression.
  - `nearsight` — Soft CC: minimap goes fully dark, fog-of-war radius shrinks to 8 units (from normal ~50), allied nameplates/health bars hidden beyond 10 units. **Twist**: nearsighted targets also lose their CC indicator overlay badges, so they can't tell what other debuffs are on them (information denial).
  - `banish` — Unique: target is phased out of combat — invulnerable, untargetable, but cannot act or move. **Twist**: while banished, all of the target's ability cooldowns tick down at 3x speed (a "strategic timeout" — enemies use it to remove a threat, but the threat comes back with everything ready).
  - `gravityWell` — Unique positional CC: target is slowly pulled toward a fixed world-space anchor point at 2 units/s. Can resist by walking away but at 40% reduced speed. **Twist**: the gravity well also bends nearby non-homing projectiles toward its center, creating a "spell magnet" zone.

- ✅ **1b. ActiveEffect support for new types** — `active_effect.dart`
  Add icon and color entries for all 12 new StatusEffect values:
  - `daze`: Icons.blur_on, Color(0xFFDDAA33) (amber)
  - `airborne`: Icons.flight, Color(0xFFAADDFF) (sky blue)
  - `sleep`: Icons.bedtime, Color(0xFF9966CC) (lavender)
  - `charm`: Icons.favorite_border, Color(0xFFFF66AA) (pink)
  - `polymorph`: Icons.pets, Color(0xFF77CC44) (lime)
  - `taunt`: Icons.record_voice_over, Color(0xFFFF4444) (red)
  - `disorient`: Icons.explore_off, Color(0xFFCCAA00) (gold)
  - `grounded`: Icons.downloading, Color(0xFF886633) (earth brown)
  - `suppress`: Icons.lock, Color(0xFF660066) (deep purple)
  - `nearsight`: Icons.visibility_off (reuse blind icon), Color(0xFF444466) (dark indigo)
  - `banish`: Icons.remove_circle_outline, Color(0xFF333366) (void blue)
  - `gravityWell`: Icons.trip_origin, Color(0xFF6600CC) (violet)
  Update `isBuff`/`isDebuff` classification — all 12 are debuffs.

- ✅ **1c. CC Indicator Overlay expansion** — `cc_indicator_overlay.dart`
  Add all 12 new types to the `_ccTypes` set. Ensure world-space badges render correctly for each. Special handling:
  - `airborne`: badge should track the unit's actual elevated Y position (floats above normal head height)
  - `banish`: badge renders with 50% opacity ghost effect (unit is phased out)
  - `suppress`: badge renders on BOTH the caster and the target (mutual lockdown)
  - `gravityWell`: badge includes a small arrow pointing toward the gravity anchor

- ✅ **1d. CC config JSON** — `assets/data/cc_config.json` (new file)
  Configuration-driven values for the CC system:
  ```
  {
    "diminishingReturns": {
      "enabled": true,
      "window": 18.0,
      "reductions": [1.0, 0.5, 0.25, 0.0],
      "categories": {
        "stun": ["stun", "knockdown", "airborne"],
        "incapacitate": ["sleep", "polymorph", "banish", "charm"],
        "root": ["root", "grounded"],
        "silence": ["silence", "suppress"],
        "disorient": ["fear", "disorient", "daze"]
      }
    },
    "airborne": {
      "launchHeightBase": 4.0,
      "gravityAccel": 12.0,
      "windDurationBonus": 0.3,
      "fallDamagePerUnit": 5.0,
      "juggleWindowAfterLand": 0.5
    },
    "sleep": {
      "regenPerSecondPercent": 1.0,
      "casterManaRegenBonus": 0.5
    },
    "charm": {
      "walkSpeedPercent": 0.6,
      "allySlowRadius": 3.0,
      "allySlowDuration": 1.0,
      "allySlowStrength": 0.3
    },
    "polymorph": {
      "moveSpeedPercent": 0.7,
      "trailDuration": 3.0,
      "trailVisibilityRadius": 15.0
    },
    "taunt": {
      "damageReduction": 0.25,
      "indignationDuration": 2.0,
      "indignationHaste": 0.3
    },
    "disorient": {
      "remapRotateInterval": 1.5,
      "cameraSway": 15.0,
      "inputDelay": 0.3
    },
    "grounded": {
      "natureDamageBonus": 0.2
    },
    "suppress": {
      "casterBreakOnDamage": true
    },
    "nearsight": {
      "fogRadius": 8.0,
      "nameplateRadius": 10.0,
      "hidesCcOverlay": true
    },
    "banish": {
      "cooldownTickRate": 3.0
    },
    "gravityWell": {
      "pullSpeed": 2.0,
      "moveSpeedReduction": 0.4,
      "projectileBendRadius": 8.0,
      "projectileBendStrength": 0.5
    }
  }
  ```
  Create `lib/game3d/state/cc_config.dart` following the ManaConfig pattern with dot-notation getters and override persistence.

- ✅ **1e. Diminishing Returns (DR) system** — `lib/game3d/systems/cc_diminishing_returns.dart` (new file)
  Track recent CC applications per target per DR category. Within the DR window (default 18s), successive CC of the same category has reduced duration: 100% → 50% → 25% → immune. DR counter resets after the window expires with no new application. Categories share DR across their member effects (stun/knockdown/airborne all share the "stun" DR, so you can't chain stun→knockdown→launch for full duration). Wire into `_applyStatusEffects()` to modify duration before applying.

- ✅ **1f. CC break / cleanse ability support** — `ability_types.dart` + `ability_system_implementations.dart`
  Add `cleansesCC: bool` and `cleansesTypes: List<StatusEffect>` fields to `AbilityData`. When a cleanse ability is used:
  - If `cleansesTypes` is empty, remove ALL non-suppress debuffs
  - If `cleansesTypes` is specified, remove only matching types
  - Cannot cleanse `suppress` (by design — only damage to the caster breaks it)
  - Cannot cleanse `airborne` (must wait for gravity)
  Existing cleanse abilities (Arcane Cleanse from Aethermancer) should get `cleansesCC: true`.

- ✅ **1g. Stance-CC interaction rules** — `ability_system_interactions.dart` + `cc_config.dart`
  Each of the 7 new stances (STANCE_REVAMP.md) modifies how CC is applied and received. Rules are kept to 2–3 per stance for intuitive play. All multipliers belong in `cc_config.json` under a `"stanceInteractions"` block. Wire into `_applyStatusEffects()` (duration modification) and the per-stance runtime update (defensive triggers).

  **CADENCE** — *Rhythm extends everything, losing rhythm costs everything*
  - Offensive: CC abilities cast within the on-beat window get the same `rhythmDamageBonus` as duration bonus (+25% CC duration). A perfectly timed Polymorph lasts 7.5s instead of 6s.
  - Defensive: Being hard-CC'd (stun/sleep/charm/polymorph/suppress/banish/airborne) resets Groove stacks to 0. The rhythm breaks completely — you must rebuild from scratch after recovering.
  - Net effect: Cadence players are the best at applying long-duration CC but are devastated by receiving it. Encourages trading CC carefully.

  **TEMPEST** — *Too fast to lock down, too rushed to commit*
  - Offensive: CC abilities fired as part of a cancel chain (chainDepth ≥ 1) have normal duration. CC abilities outside a cancel chain have 15% reduced duration (rushed, uncommitted).
  - Defensive: All incoming hard CC durations are reduced by 20% (the target is moving too fast to fully lock down). Soft CC (daze/slow/disorient/grounded) is unaffected.
  - Net effect: Weave CC into rapid combos for full effect. Getting stunned for 2.4s instead of 3s creates small but crucial windows to recover. Tempest players should chain a damage ability → CC ability for best results.

  **WARDEN** — *Preparation is everything, losing mobility is catastrophic*
  - Offensive: CC abilities from Predator's Eye (first strike after `predatorActivationTime` of stillness) have +40% duration. Directional modifiers apply to CC: forward = +range, backward = +knockback force, stationary = +AoE radius on CC. A Predator's Eye sleep from stealth lasts 7s instead of 5s.
  - Defensive: While pressing strafe keys (A/D), incoming soft CC (daze/slow/disorient/grounded) has a 15% chance to be fully resisted (the strafe dodge bonus extends to CC avoidance).
  - Drawback: `grounded` effect on a Warden also disables ALL directional bonuses for its duration (movement IS the Warden's identity — ground them and they lose everything).

  **CRUCIBLE** — *CC is expensive heat, but massive at zero*
  - Offensive: CC abilities generate 2 Heat per cast instead of 1 (locking someone down is "hot" work). The Cool Down Payoff (first ability at 0 Heat) grants +50% CC duration if that ability applies CC. A 0-Heat stun lasts 4.5s instead of 3s.
  - Defensive: Being CC'd pauses the Heat decay timer (you can't cool off while locked down). If CC'd at 8+ Heat, you're trapped near Overheat with no way to decay — extremely dangerous.
  - Net effect: Strategic CC timing is critical. Dump damage to build Heat, let it decay, then open with a massive CC at 0 Heat. Getting CC'd at high Heat is a death sentence.

  **MOMENTUM** — *Force scales with speed, but lockdowns bleed momentum*
  - Offensive: Displacement CC (knockback, launch/airborne, grip, scatter) force scales with +5% per Momentum stack (up to +40% at 8 stacks). At max stacks, hitting an already-airborne target extends their air time by 0.5s (juggle extension).
  - Defensive: Being hard-CC'd causes Momentum stacks to decay at 3x the normal rate (each 2.5s decay tick happens every 0.83s). A 3s stun at 6 stacks leaves you at ~2 stacks when it ends.
  - Net effect: Momentum players are the kings of displacement combos — knockbacks hit like trucks at high stacks, and juggle chains extend airborne enemies. But getting stunned yourself bleeds everything you built.

  **PRESSURE** — *CC builds the break gauge, but displacement resets it*
  - Offensive: CC abilities applied to your current pressure target build +50% bonus pressure (e.g., a melee CC adds 22.5% instead of 15%). During Break state (after gauge reaches 100%), CC applied ignores diminishing returns entirely — the target is broken, pile it on.
  - Defensive: Being CC'd causes pressure on your current target to decay at 3x rate (you lose focus while locked down).
  - Drawback: Displacement CC (knockback/grip/launch) that physically MOVES your pressure target resets their pressure gauge to 50% (you're breaking contact with the target you've been working). Timed CC (stun/root/sleep) is safe for pressure — displacement is a gamble.

  **FLUX** — *Switching cleanses CC, stagnation invites it*
  - Offensive: CC applied during the transition bonus window (first 1.5s after switching INTO Flux) gets +30% duration. Stance-switch → immediate CC is the Flux player's signature move.
  - Defensive: Each stance switch cleanses one random active soft CC effect (daze, slow, disorient, or grounded). If you're dazed and slowed, switching stances removes one of them. Costs a switch, but Flux has `fluxSwitchCooldown` of 0.5s.
  - Drawback: The stagnation penalty (5s+ in Flux without switching) increases incoming CC duration by +25%. A Flux player who stops switching becomes the easiest CC target on the field.

  Add these values to `cc_config.json`:
  ```
  "stanceInteractions": {
    "cadence": { "onBeatCcDurationBonus": 0.25, "ccResetsGroove": true },
    "tempest": { "nonChainCcDurationPenalty": 0.15, "incomingHardCcReduction": 0.20 },
    "warden": { "predatorCcDurationBonus": 0.40, "strafeCcResistChance": 0.15, "groundedDisablesDirectional": true },
    "crucible": { "ccHeatCost": 2, "zeroheatCcDurationBonus": 0.50, "ccPausesHeatDecay": true },
    "momentum": { "displacementForcePerStack": 0.05, "maxStackAirborneExtension": 0.5, "ccMomentumDecayMultiplier": 3.0 },
    "pressure": { "ccPressureBuildBonus": 0.50, "breakIgnoresDR": true, "ccPressureDecayMultiplier": 3.0, "displacementPressureReset": 0.50 },
    "flux": { "transitionCcDurationBonus": 0.30, "switchCleansesSoftCc": true, "stagnationCcDurationPenalty": 0.25 }
  }
  ```

---

#### Phase 2: Displacement & Airborne Physics

Build the vertical displacement (launch/airborne) system and enhance existing knockback with terrain interaction.

- ✅ **2a. Airborne state tracking** — `game_state.dart` + `ally.dart` + `monster.dart`
  Add fields for airborne physics on player and ally models:
  - `airborneHeight: double` — current Y offset above ground (0 = grounded)
  - `airborneVelocityY: double` — vertical velocity (positive = up)
  - `isAirborne: bool` getter — true when `airborneHeight > 0.1`
  - `airborneSourceHeight: double` — peak height reached (for fall damage calc)
  Wire `isAirborne` into `isPerformingAction` and input blocking — airborne units can't move, cast, or use abilities.

- ✅ **2b. Airborne physics update loop** — `lib/game3d/systems/airborne_system.dart` (new file)
  Each frame for every unit with `airborneHeight > 0`:
  1. Apply gravity: `velocityY -= gravityAccel * dt`
  2. Update height: `airborneHeight += velocityY * dt`
  3. Track peak: `sourceHeight = max(sourceHeight, airborneHeight)`
  4. On landing (`airborneHeight <= 0`):
     - Clamp to 0, zero velocity
     - Apply fall damage: `(sourceHeight - launchHeightBase) * fallDamagePerUnit` (only if sourceHeight > base threshold)
     - Start juggle window timer (0.5s where relaunches have bonus height)
     - Apply "Grounded" micro-stagger: 0.3s where unit can't act (landing recovery)
  5. Wind bonus: if `globalWindState.effectiveStrength > 1.0`, multiply remaining airborne duration by `1 + windStrength * windDurationBonus`
  Call from `game3d_widget_update.dart` after ability system, before render.

- ✅ **2c. Launch displacement implementation** — `ability_system_interactions.dart`
  When applying `StatusEffect.airborne`:
  - Set `airborneVelocityY = sqrt(2 * gravity * launchHeight)` where `launchHeight = strength` from the AbilityStatusEffect
  - If target is already airborne (juggle), add velocity rather than replacing (combo juggle extends height)
  - If within juggle window (just landed), grant +30% bonus launch height
  - Play launch sound + upward particle burst
  Rendering: offset the unit mesh's Y position by `airborneHeight` in `render_system.dart`. Shadow stays on ground.

- ✅ **2d. Enhanced knockback — terrain collision** — `ability_system_interactions.dart`
  When knockback displaces a unit, check terrain along the displacement path:
  - If displacement path crosses a steep terrain rise (Δheight > 2.0 within 1 unit), treat as wall collision
  - Wall collision: stop displacement, deal bonus damage = `knockbackForce * 0.5`, apply 1s stun ("wall slam")
  - If knockback pushes unit off a cliff edge (Δheight < -3.0), convert to airborne state with horizontal momentum preserved
  - Tower walls (indoor zones) count as wall collisions

- ✅ **2e. Gravity Well positional system** — `lib/game3d/systems/gravity_well_system.dart` (new file)
  Track active gravity wells as `{anchorX, anchorZ, radius, pullSpeed, duration, remainingDuration, casterId}`.
  Each frame:
  1. For all units within radius, apply pull vector toward anchor: `pullDir * pullSpeed * dt * (1 - distanceRatio)`
  2. Units actively moving away can resist but at `moveSpeedReduction` penalty
  3. Non-homing projectiles within `projectileBendRadius` have their velocity vector bent toward the anchor by `projectileBendStrength`
  4. Visual: swirling particle vortex at anchor point (purple/black for Starbreaker, green for Nature)
  Register gravity wells from ability execution; remove on expiry.

- ✅ **2f. Scatter (AoE knockback)** — ability execution helper
  Add `_executeScatter()` helper for abilities that knockback all units in an AoE from a center point (not from the caster). Each target is pushed radially outward from the AoE center. Strength falls off with distance from center. Used by abilities like Thunderclap, Shockwave, Eruption.

---

#### Phase 3: Hard CC Ability Behaviors

Implement the behavioral logic for each new hard CC type. These are the "big" effects that fully remove agency.

- ✅ **3a. Sleep behavior** — `cc_behavior_system.dart` + `game3d_widget_update.dart`
  When `sleep` ActiveEffect is present on a unit:
  - Block all input/AI actions (same as stun)
  - On ANY damage tick (including DoTs, even 1 damage), immediately remove sleep effect
  - Apply passive regen: `maxHealth * regenPerSecondPercent / 100 * dt` each frame
  - Track sleep source caster; grant that caster `+manaRegenBonus` to all mana types while sleep persists
  - Visual: Z-Z-Z particle bubbles floating up from unit, soft blue-purple tint overlay
  - AI awareness: AI should prioritize NOT attacking sleeping targets (to maintain CC), except when explicitly told to burst

- ✅ **3b. Charm behavior** — `cc_behavior_system.dart` + `ai_system_monster.dart` + `duel_system.dart`
  When `charm` ActiveEffect is present:
  - Override movement: unit walks toward the charm caster's current position at `walkSpeedPercent` speed
  - Block all ability usage and manual movement input
  - "Heartbreak ripple": when charmed unit passes within `allySlowRadius` of a friendly unit, apply `allySlowDuration`/`allySlowStrength` slow to that ally (once per ally per charm instance)
  - If the charm caster moves, the charmed unit re-pathing follows
  - Visual: pink heart particles trailing behind, dreamy screen-edge vignette on charmed player
  - Charm break: standard duration expiry or cleanse (not damage-break like sleep)

- ✅ **3c. Polymorph behavior** — `cc_behavior_system.dart` (damage-break + query helpers)
  When `polymorph` ActiveEffect is present:
  - Replace unit mesh with critter mesh (small cube recolored: green=frog, white=sheep, dark=scarab based on `damageSchool` of the ability that applied it)
  - Allow movement at `moveSpeedPercent` but block all abilities, casting, and combat
  - Break on any damage (even 1 point)
  - "Spirit trail": record position every 0.5s; render fading glow dots at those positions for `trailDuration` seconds; caster's minimap shows these dots
  - On expiry/break: restore original mesh with a small "poof" particle burst
  - AI handling: polymorphed AI units wander randomly (not toward combat)

- ✅ **3d. Taunt behavior** — `cc_behavior_system.dart` (query helper) + `ai_system_monster.dart` + `duel_system.dart`
  When `taunt` ActiveEffect is present:
  - Force target acquisition on the taunter (override current target)
  - Block target switching and non-melee ability usage
  - Auto-attack the taunter (AI: path to taunter and basic-attack; Player: ability buttons except melee are grayed)
  - Apply `damageReduction` to damage dealt to the taunter specifically
  - On taunt expiry (not cleanse) while taunter is within 10 units: apply "Indignation" buff to the victim (haste for `indignationDuration`)
  - Visual: red chain link particle between taunter and target, pulsing

- ✅ **3e. Suppress behavior** — `cc_behavior_system.dart` (pair tracking, damage-break, mutual stagger)
  When `suppress` ActiveEffect is present:
  - Target: full hard CC (no actions, no cleanse, no CC-break abilities)
  - Caster: also locked in place, cannot act (mutual channel)
  - Track suppress pairs: `{casterId, targetId, remainingDuration}`
  - If caster takes damage exceeding 10% of their max HP in a single hit, break suppression on both
  - On break: both caster and target get a 0.5s "Disoriented" micro-stagger
  - Visual: dark purple chains connecting caster and target, both have suppression badge
  - AI: allies should prioritize attacking the enemy caster to break suppression on their friend

- ✅ **3f. Banish behavior** — `cc_behavior_system.dart` (cooldown acceleration + untargetable query)
  When `banish` ActiveEffect is present:
  - Unit becomes untargetable and invulnerable (skip in all target iteration loops)
  - Unit cannot act, move, or be interacted with
  - All ability cooldowns tick at `cooldownTickRate` multiplier (default 3x)
  - Visual: unit mesh rendered at 30% opacity with a dark blue-purple shimmer
  - On expiry: unit reappears with a "phase-in" flash, 0.5s grace period where they can't be damaged
  - Self-banish variant possible: some classes could banish themselves as a defensive cooldown (Ice Block / Divine Shield archetype with the cooldown acceleration twist)

---

#### Phase 4: Soft CC & Debuff Behaviors

Implement behavioral logic for each new soft CC. These restrict but don't fully remove agency.

- ✅ **4a. Daze behavior** — `game_state.dart` (speed calc) + `cc_behavior_system.dart` (damage interrupt + combo reset)
  When `daze` ActiveEffect is present:
  - Apply 50% movement speed reduction (stacks multiplicatively with slow, not additively)
  - On taking damage: if currently casting/channeling/winding up, cancel that action (spell interrupt without the school lockout of `interrupt`)
  - Reset `meleeChainCount` to 0 and clear `meleeChainModeActive` (combo chain disruption)
  - Does NOT prevent ability usage (key difference from stun — you can still fight, just badly)
  - Visual: amber stars circling above head (classic "seeing stars"), slight screen blur if player is dazed

- ✅ **4b. Disorient behavior** — `input_system.dart` (WASD remap + rotation timer) + `cc_behavior_system.dart` (query)
  When `disorient` ActiveEffect is present:
  - Player: remap WASD bindings randomly. Generate a permutation of {forward, backward, left, right} and apply. Rotate the permutation every `remapRotateInterval` seconds (default 1.5s)
  - Camera: apply sinusoidal sway of `±cameraSway` degrees to yaw
  - Ability queue: add random delay of 0–`inputDelay` seconds to each ability input
  - AI units: movement directions are randomized each AI tick, but they can still use abilities (with random delay)
  - Visual: wavy screen distortion effect, swirling yellow particles around head
  - Unlike fear (which forces fleeing), disoriented units TRY to act normally but everything is scrambled

- ✅ **4c. Grounded behavior** — `input_system.dart` (flight block) + `cc_behavior_system.dart` (query) + `game_state.dart` (nature damage bonus via config)
  When `grounded` ActiveEffect is present:
  - Block execution of abilities with `range >= 4.0` that use the dash system (gap closers)
  - Block flight launch (Spacebar in flight zones)
  - Block teleport-type abilities
  - Normal WASD movement and all non-movement abilities work fine
  - Bonus damage taken from `DamageSchool.nature`: multiply incoming nature damage by `1 + natureDamageBonus`
  - Visual: thorny green vines wrapped around feet (small particle effect at unit base), cracking earth texture under unit

- ✅ **4d. Nearsight behavior** — `cc_indicator_overlay.dart` (overlay suppression) + `cc_behavior_system.dart` (query)
  When `nearsight` ActiveEffect is present on the PLAYER:
  - Minimap: fill with dark fog overlay, only show terrain within `fogRadius` of player
  - Nameplates/health bars: hide for all units beyond `nameplateRadius` (both ally and enemy)
  - CC indicator overlay: if `hidesCcOverlay` is true, suppress rendering of all CC badges on all units (the player can't read debuff states)
  - Unit meshes beyond fog radius: render at 50% opacity or don't render (configurable)
  - Does NOT affect ability targeting range (you can still hit things you can't see if you know where they are)
  - AI handling: nearsighted AI units only consider targets within fog radius
  - Visual: dark vignette closing in on screen edges, flickering shadow at periphery

---

#### Phase 5: Per-Class CC Abilities (2–3 per class, each with unique twist)

Each class gets 2–3 new abilities that leverage the new CC/displacement types. Abilities should feel thematically consistent with the class fantasy and synergize with existing combos. All values belong in the ability data definitions, not hardcoded.

**Stance synergy notes** are included per-ability where a stance interaction is particularly strong or creates an interesting decision. These reference the rules from task 1g — the interactions are engine-level, but calling them out here helps ability designers see the combos.

- ✅ **5a. Warrior CC Abilities** — `warrior_abilities.dart`
  1. **Concussive Slam** — Melee AoE, 14s CD, Red 20 mana. Deals 30 damage + applies `daze` (4s) to all enemies within 4 units. **Twist**: if target is already dazed, upgrades to 2s `stun` instead (double-daze punish). **Stance synergy**: In PRESSURE, daze builds +50% bonus pressure on the target — double-daze→stun chains build the Break gauge rapidly. In MOMENTUM, the AoE hitting 3+ targets grants double Momentum stacks.
  2. **Thunderous Charge** — Dash 12-range, 18s CD, Red 25 mana. Charges to target, deals 35 damage + `knockback` (6 units). If target hits a wall during knockback, bonus 20 damage + 1.5s `stun` (wall slam). **Stance synergy**: In MOMENTUM, knockback force scales +5% per stack — at 8 stacks the 6-unit push becomes 8.4 units, making wall slams far more likely. In PRESSURE, the knockback resets pressure to 50% (displacement penalty) — use this as an opener, not mid-pressure-build. **Stance drawback**: WARDEN players are immune to the dash component if `grounded` (blocks charges).
  3. **Iron Maiden** — Melee 3-range, 30s CD, Red 30 mana. Applies `taunt` (4s) to target. While taunt is active, 15% of damage the taunted target deals is reflected back to them. **Twist**: the reflection uses `DamageSchool.physical` so it's affected by armor/vulnerability. **Stance synergy**: In CRUCIBLE at 0 Heat (Cool Down Payoff), taunt duration becomes 6s (+50%) — long enough to force 2 full GCD cycles of forced melee from the victim. In CADENCE, on-beat Iron Maiden lasts 5s.

- ✅ **5b. Rogue CC Abilities** — `rogue_abilities.dart`
  1. **Blackout Strike** — Melee 3-range, 20s CD, Red 15 mana. Deals 25 damage + applies `sleep` (5s). Must be used from behind the target (check facing angle > 120° from target's forward). If used from front, applies 2s `daze` instead. **Twist**: "Ambush sleep" — only works from behind, making positioning matter. **Stance synergy**: WARDEN is the natural home — Predator's Eye (stand still 2s before engaging) gives +40% CC duration, making the ambush sleep 7s. The rear-attack requirement aligns perfectly with Warden's observation→first-strike loop. In CADENCE, on-beat sleep lasts 6.25s.
  2. **Hallucinogenic Blade** — Melee 3-range, 24s CD, Red 15 + Green 10 mana. Deals 20 damage + applies `disorient` (4s). **Twist**: while target is disoriented, Rogue's next ability against them has +30% crit damage (exploit confusion). **Stance synergy**: In TEMPEST, follow Hallucinogenic Blade with a cancel-chain burst ability to capitalize on the +30% crit within the cancel window. In FLUX, apply disorient during transition bonus window for 5.2s duration — longer confusion = wider crit window.
  3. **Smoke Shroud** — Self-centered AoE 6-radius, 35s CD, Red 20 mana. Applies `nearsight` (5s) to all enemies in radius. Also applies 3s `slow` (30%). **Twist**: the Rogue gains `haste` (20%, 5s) while inside the smoke (hunter becomes the predator in the fog). **Stance synergy**: In WARDEN, Smoke Shroud → stand still 2s inside smoke → enter Predator's Eye while enemies are blinded → Calculated Strike with all bonuses. The smoke buys the preparation time Warden needs. **Stance drawback**: CRUCIBLE Rogues pay 2 Heat for the CC — using it solely for setup when Heat is high is risky.

- ✅ **5c. Mage CC Abilities** — `mage_abilities.dart`
  1. **Arcane Polymorph** — Ranged 20-range, 30s CD, Blue 35 mana, 1.5s cast. Applies `polymorph` (6s) to target — transforms into a sheep. Breaks on damage. **Twist**: when polymorph breaks, the target takes `DamageSchool.arcane` burst damage equal to 10% of their max HP ("shatter shock"). Spirit trail gives minimap vision. **Stance synergy**: In CADENCE, on-beat polymorph lasts 7.5s — an eternity of CC. In CRUCIBLE at 0 Heat, 9s polymorph (6 × 1.5). Both stances reward saving this ability for the right moment. **Stance drawback**: TEMPEST polymorph outside a cancel chain is only 5.1s (15% penalty) — Tempest Mages should weave it after a damage ability, not lead with it.
  2. **Gravity Flux** — Ranged AoE targeted ground, 25s CD, Blue 30 + Black 15 mana, 1.0s cast. Creates a `gravityWell` (8-unit radius, 6s duration) at target location. Pulls all enemies toward center. **Twist**: projectiles passing through the well are accelerated, gaining +25% damage (spell synergy — cast a Fireball through your own gravity well for bonus damage). **Stance synergy**: In MOMENTUM, the gravity well groups enemies for AoE follow-ups, which grant double Momentum stacks when hitting 3+ targets. In PRESSURE, the well doesn't displace your pressure target (it pulls, not pushes) so pressure gauge is safe — use it to pin your target while building pressure.
  3. **Deep Freeze** — Ranged 15-range, 20s CD, Blue 25 mana. Deals 15 damage + applies `freeze` (3s). If target is already `slow`ed, instead applies `banish` (2.5s) — frozen so completely they phase out of reality. **Twist**: combo enabler — slow first, then Deep Freeze for the banish, giving you time to set up burst while their cooldowns accelerate. **Stance synergy**: In PRESSURE, the slow→freeze combo builds pressure safely (timed CC, no displacement), and the 3s freeze locks the target in place for more hits. The banish variant resets pressure (target becomes untargetable) — a deliberate tradeoff between more pressure time vs. removing the target.

- ✅ **5d. Windwalker CC Abilities** — `windwalker_abilities.dart`
  1. **Tempest Lift** — Melee 4-range, 16s CD, White 20 mana. Deals 20 damage + launches target `airborne` (strength 5.0 = high launch). **Twist**: launch height scales with current wind strength — during derechos, this ability sends targets significantly higher, dealing more fall damage. Wind-themed juggle starter. **Stance synergy**: MOMENTUM is the premier juggle stance — at 8 stacks, Tempest Lift launches 40% harder AND extends the target's air time by 0.5s, giving allies a massive juggle window. In TEMPEST stance, use Tempest Lift inside a cancel chain → immediate follow-up air combo. **Stance drawback**: In PRESSURE, the launch (displacement) resets pressure to 50% — use it to start a fight, not mid-pressure-build.
  2. **Gale Scatter** — Self-centered AoE 6-radius, 22s CD, White 25 mana. AoE knockback (scatter, 5 units) to all enemies around caster + applies 2s `daze`. **Twist**: knockback distance scales with wind strength (wind at your back amplifies the push). If used while airborne, the Windwalker hovers briefly instead of being knocked down. **Stance synergy**: In MOMENTUM, scatter force scales +40% at max stacks AND hitting 3+ targets grants double stacks. A derecho-powered, max-Momentum Gale Scatter is devastating. In FLUX, the daze can be self-cleansed if caught in your own AoE (stance switch removes one soft CC).
  3. **Vertigo Vortex** — Ranged 12-range, 28s CD, White 20 + Blue 15 mana, 0.8s cast. Creates a 5-unit radius wind vortex at target location for 4s. Enemies inside are `disorient`ed and slowly pulled toward center (mini gravity well). **Twist**: the vortex also deflects incoming ranged projectiles that pass through it (wind shield zone). **Stance synergy**: In WARDEN, casting this while stationary gives +10% AoE radius (5.5 units). In CADENCE, on-beat vortex disorientation lasts 5s instead of 4s.

- ✅ **5e. Stormheart CC Abilities** — `stormheart_abilities.dart`
  1. **Thunder Clap** — Melee AoE 5-radius, 14s CD, White 15 + Red 10 mana. Deals 25 damage to all enemies in radius + applies `daze` (3s) + `interrupt`. **Twist**: if used during a melee combo chain, the AoE radius increases by 50% (riding the chain momentum into a bigger shockwave). **Stance synergy**: In TEMPEST, use Thunder Clap as a cancel-chain finisher — the daze gets full duration (inside chain) and the chain-expanded radius catches more targets. In PRESSURE, daze builds +50% bonus pressure on your target AND the interrupt stops their cast, keeping you in control. **Stance drawback**: In CRUCIBLE, costs 2 Heat for the CC component — repeated Thunder Claps build Heat fast.
  2. **Magnetic Grip** — Ranged 15-range, 18s CD, White 20 mana. Pulls target toward caster (grip, 80% of distance) + applies `grounded` (4s). **Twist**: the pull arcs through the air (target briefly goes airborne during the pull trajectory) and arrives stunned for 1s at the caster's feet — a combination pull + mini-launch + stun. **Stance synergy**: In MOMENTUM, the grip displacement force scales with stacks — at 8 stacks, 80% becomes effectively 100% (pulled all the way). The grounded follow-up traps them at your feet for melee combos. **Stance drawback**: In PRESSURE, this grip (displacement) resets pressure to 50% — best used to START an engagement, not mid-pressure-build. In WARDEN, pulling a target toward you sets up melee range for directional combos.
  3. **Ball Lightning** — Ranged AoE projectile, 25s CD, White 25 + Blue 15 mana, 0.5s cast. Fires a slow-moving lightning orb (projectile speed 5.0) that applies `charm` (2.5s) to the first enemy hit — target walks toward the orb's current position as it travels. **Twist**: the orb continues moving after charming, dragging the victim along with it toward wherever the orb is heading (directional charm — you aim where they end up). **Stance synergy**: In CADENCE, on-beat charm lasts 3.1s — long enough for the orb to drag the target significantly further. In FLUX, charm applied during transition window lasts 3.25s and can reposition an enemy into your allies' kill zone.

- ✅ **5f. Nature CC Abilities** — `nature_abilities.dart`
  1. **Living Vines** — Ranged 15-range, 20s CD, Green 25 mana, 1.0s cast. Applies `root` (4s) + `grounded` (6s) to target. **Twist**: "Creeping root" — after 2s, the root spreads to one additional enemy within 5 units of the original target (prioritizes closest). The spread target gets half-duration root (2s). **Stance synergy**: In PRESSURE, root is timed CC (not displacement) so pressure gauge is safe — the 4s root is a free pressure-building window. The creeping spread can catch a second target you're not focused on, softening them up. **Stance drawback**: Against WARDEN enemies, grounded disables their directional bonuses — Nature's vines are a direct counter to Warden's movement-based playstyle.
  2. **Hibernate** — Ranged 18-range, 35s CD, Green 30 mana, 2.0s cast. Applies `sleep` (8s) — the longest sleep in the game. **Twist**: the sleep is nature-themed "hibernation" — the regen rate is doubled (2% max HP/s instead of 1%), and the caster gains green mana regen bonus instead of generic. Forces a strategic choice: long CC but significant enemy healing. **Stance synergy**: In CADENCE, on-beat Hibernate lasts 10s (8 × 1.25) — the longest CC in the game, but the target heals 20% of max HP during that time. In CRUCIBLE at 0 Heat, 12s sleep (8 × 1.5). Both are astronomical CC durations with enormous healing drawbacks — true strategic dilemmas. **Stance drawback**: In TEMPEST without a cancel chain, Hibernate is only 6.8s — still long, but TEMPEST's haste-focused playstyle doesn't pair naturally with long setup CCs.
  3. **Erupting Thorns** — Targeted ground AoE 6-radius, 22s CD, Green 20 mana. After 1s delay, thorns erupt from the ground: deals 30 damage + launches targets `airborne` (strength 3.0 = medium launch) + applies `bleed` (6s DoT). **Twist**: the thorns persist for 4s as terrain — enemies that walk over them are `slow`ed (30%, 2s). Zone-control ability. **Stance synergy**: In MOMENTUM, the AoE launch hitting 3+ targets grants double stacks AND launch force scales with existing stacks. In WARDEN, casting while stationary gives +10% AoE radius (6.6 units) — wider thorn zone for area denial.

- ✅ **5g. Necromancer CC Abilities** — `necromancer_abilities.dart`
  1. **Soul Shackle** — Ranged 10-range, 35s CD, Black 30 mana, 1.5s cast (channeled). Applies `suppress` (3.5s) — the necromancer and target are both locked in dark chains. **Twist**: while suppressed, the necromancer drains 5% of the target's current HP/s as shadow damage, healing themselves for the amount drained. Allies must protect the necromancer or enemies must break them free. **Stance synergy**: In PRESSURE, suppress is timed CC that builds +50% bonus pressure — 3.5s of free pressure accumulation while the target can't fight back. During the subsequent Break window (stun + damage amp), follow up with burst. **Stance drawback**: Suppress locks YOU down too — in MOMENTUM, your stacks decay at 3x during the 3.5s (you're CC'd as well). In CRUCIBLE, your Heat decay pauses. Choose carefully.
  2. **Hex of the Toad** — Ranged 18-range, 28s CD, Black 25 + Green 10 mana, 1.2s cast. Applies `polymorph` (5s) — target is turned into a frog (nature/shadow fusion). **Twist**: unlike Mage polymorph, the frog hops erratically (random direction changes every 0.8s) making the target unpredictable. On polymorph break, target is `slow`ed (40%, 3s) ("slug slime" lingering effect). **Stance synergy**: In CADENCE, on-beat Hex lasts 6.25s. In FLUX, cast during transition window for 6.5s polymorph — plenty of time to reposition or set up on other targets. The lingering slow after break is useful in PRESSURE (safe timed CC for building gauge).
  3. **Grave Grasp** — Targeted ground AoE 5-radius, 20s CD, Black 20 mana. Skeletal hands erupt: `grounded` (4s) + 2s `slow` (50%) to all enemies in area. **Twist**: grounded enemies in the zone also cannot be healed by allies (the grave's grip seals off life energy). Powerful anti-healer zone control. **Stance synergy**: In WARDEN, casting while stationary gives +10% AoE radius (5.5 units). The grounded effect directly counters enemy WARDEN players (disables their directional bonuses). In PRESSURE, grounded + slow keeps the target in place for sustained pressure building without the gauge-reset risk of displacement.

- ✅ **5h. Elemental CC Abilities** — `elemental_abilities.dart`
  1. **Petrify** — Ranged 12-range, 22s CD, Red 20 + Green 15 mana, 1.0s cast. Applies custom `freeze` variant (3s) — target turns to stone. **Twist**: petrified targets take +50% damage from the next single physical damage source (shatter mechanic — one big hit shatters the stone for massive bonus damage, then the petrify breaks). Uses `vulnerablePhysical` stacking with the freeze. **Stance synergy**: In PRESSURE, Petrify is timed CC that safely builds pressure, and the +50% physical vulnerability amplifies the Break damage when you finally pop it. Petrify → build pressure → Break → shatter the stone with the Break's +60% damage. In TEMPEST, follow Petrify immediately with a physical cancel-chain hit for the shatter bonus.
  2. **Magma Geyser** — Targeted ground AoE 4-radius, 18s CD, Red 25 mana. After 0.8s delay, erupts: deals 35 fire damage + launches targets `airborne` (strength 4.0) + applies `burn` (4s DoT). **Twist**: the geyser leaves a lava pool for 5s — enemies landing in or walking through it take burn damage and are `daze`d (2s). Creates a dangerous landing zone for juggled targets. **Stance synergy**: In MOMENTUM, launch force scales with stacks (+40% at max), and the AoE hitting 3+ targets grants double stacks. The lava pool daze on landing is a free soft CC reset. In PRESSURE, the burn DoT ticks build pressure at 5% per tick — sustained gauge build. **Stance drawback**: Launch is displacement, so PRESSURE resets to 50% if used on your pressure target.
  3. **Glacial Prison** — Ranged 15-range, 30s CD, Blue 25 + Red 10 mana, 1.5s cast. Applies `banish` (3s) — target is encased in a crystal of fire and ice, immune but unable to act. **Twist**: on expiry, the prison explodes in a 4-unit AoE dealing 20 damage (split fire + frost) and applying `slow` (30%, 3s) to nearby enemies. The banished target takes no explosion damage. Used offensively (remove a threat then AoE their allies) or defensively (banish a friend to save them, then the explosion pushes enemies back). **Stance synergy**: In CRUCIBLE at 0 Heat, banish lasts 4.5s — the target comes back with cooldowns at 13.5x ticked (3x rate × 4.5s). In CADENCE, on-beat banish is 3.75s. Both let you remove a key threat while setting up on others. **Stance drawback**: In PRESSURE, banish makes the target untargetable — pressure decays completely. Only use this on a SECONDARY target, not your pressure target.

- ✅ **5i. Spiritkin CC Abilities** — `spiritkin_abilities.dart`
  1. **Primal Roar** — Self-centered AoE 8-radius, 24s CD, Green 25 mana. No damage. Applies `fear` (3s) + `daze` (4s) to all enemies in radius. **Twist**: feared enemies run AWAY at 130% speed (instead of normal fear 100%), but the 4s daze outlasts the fear, so when fear ends they're slowed and vulnerable to follow-up. The burst of terrified fleeing creates distance, then the daze lets you close in. **Stance synergy**: In WARDEN, casting while stationary gives +10% AoE radius (8.8 units — huge fear zone). In FLUX, fear+daze applied during transition window both get +30% duration (3.9s fear + 5.2s daze). If caught in your own AoE (self-centered), FLUX can cleanse the daze from yourself with a stance switch. **Stance drawback**: In CRUCIBLE, costs 2 Heat per CC effect (fear + daze = 4 Heat in one cast) — extremely hot.
  2. **Spirit Sever** — Ranged 12-range, 22s CD, Green 20 + Black 10 mana. Deals 15 shadow damage + applies `nearsight` (5s) + `silence` (2s). **Twist**: the severed target's spirit is briefly visible to the caster as a ghost outline — the caster can see the target through obstacles/walls for the nearsight duration (vision swap — you blind them but gain truesight on them). **Stance synergy**: In CADENCE, on-beat nearsight lasts 6.25s and silence 2.5s. In WARDEN with Predator's Eye, silence is 2.8s and nearsight 7s — long enough to reposition into another Predator's Eye ambush while they're blind. The truesight-through-walls synergizes perfectly with Warden's stalker fantasy.
  3. **Feral Pounce** — Dash 10-range, 16s CD, Green 15 mana. Leaps to target, deals 25 damage + applies `knockdown` (1.5s). If target was already affected by any CC (slow, root, daze, etc.), the knockdown is extended to 2.5s. **Twist**: "predator instinct" — bonus duration on already-CC'd targets rewards chaining effects. Combo follow-up after Primal Roar's daze. **Stance synergy**: In TEMPEST, Feral Pounce → cancel-chain into another ability while they're knocked down. The predator instinct bonus (2.5s on CC'd targets) gives the cancel chain a generous window. In MOMENTUM, the dash → knockdown → melee follow-up builds stacks rapidly. **Stance drawback**: PRESSURE users note: knockdown is timed CC (safe for pressure gauge) but the dash displacement is not — the POUNCE itself is fine since you're going TO the target.

- ✅ **5j. Starbreaker CC Abilities** — `starbreaker_abilities.dart`
  1. **Void Collapse** — Ranged AoE targeted ground, 25s CD, Black 30 mana, 1.0s cast. Creates a `gravityWell` (6-unit radius, 5s duration) at target location. **Twist**: after the well expires, it implodes — all units still within 4 units are launched `airborne` (strength 4.5) and take 25 void damage. Two-phase ability: pull them in, then blow them up. **Stance synergy**: In MOMENTUM, the implosion launch at max stacks sends targets 40% higher (strength 6.3) AND the AoE hitting 3+ targets during the pull phase grants double stacks — the well itself IS a stack engine. In PRESSURE, tension: the gravity well pull doesn't displace your target (it's positional pull, not knockback), so pressure gauge is safe during the 5s pull phase. But the implosion launch IS displacement — you get 5s of free pressure building, then the launch resets to 50%. Time your Break BEFORE the implosion.
  2. **Dimensional Rift** — Ranged 20-range, 30s CD, Black 25 + Blue 15 mana, 0.8s cast. Applies `banish` (3s) to target. **Twist**: while the target is banished, a shadow clone of the target appears at the banish location (purely visual + takes damage). All damage dealt to the shadow clone is stored and applied to the real target when banish expires as `DamageSchool.shadow` burst. Players can "pre-load" burst damage during the banish window. **Stance synergy**: In CRUCIBLE at 0 Heat, banish lasts 4.5s — more time to load damage onto the shadow clone. In TEMPEST, use the 3s banish window to rapid-fire cancel-chain abilities into the shadow clone for massive stored burst. In MOMENTUM, each hit on the shadow clone builds stacks, so the real target reappears into a max-stack damage monster.
  3. **Singularity Crush** — Melee 3-range, 20s CD, Black 25 mana. Deals 30 damage + applies `suppress` (2.5s). **Twist**: unlike Necromancer's Soul Shackle (which is ranged+channeled+drain), this is a melee instant suppress — the Starbreaker grabs the target in a void field. The caster IS locked down (suppress is mutual), but since it's melee range both units are in the kill zone for allies. Shorter duration but no cast time. **Stance synergy**: In PRESSURE, suppress builds +50% bonus pressure — 2.5s of guaranteed pressure accumulation. In CRUCIBLE, this is instant cast so it doesn't consume the 0-Heat payoff (use a CC AFTER the payoff ability). **Stance drawback**: In MOMENTUM, your stacks decay at 3x during suppress (you're locked down too). In CADENCE, suppress resets Groove (you're CC'd). Use this when you have little to lose.

- ✅ **5k. Greenseer CC Abilities** — `greenseer_abilities.dart`
  1. **Dreamweave** — Ranged 18-range, 28s CD, Green 30 mana, 1.5s cast. Applies `charm` (3.5s). **Twist**: the charmed target's movement leaves behind a trail of blooming flowers (cosmetic + minor green mana regen zone for allies who walk through it, 2/s for 3s). Weaponized CC that also benefits allies positionally. **Stance synergy**: In CADENCE, on-beat charm lasts 4.4s — long enough for the flower trail to cover significant ground for ally mana benefit. In FLUX, charm during transition window lasts 4.55s. In WARDEN with Predator's Eye, 4.9s charm with guaranteed first-strike setup. **Stance drawback**: In TEMPEST without cancel chain, only 3.0s charm — barely enough to reposition.
  2. **Verdant Entangle** — Targeted ground AoE 7-radius, 20s CD, Green 20 mana. Creates a growth zone for 6s. Enemies entering are `root`ed (2s, once per enemy per cast) + `grounded` (full 6s). **Twist**: allies standing in the zone gain +15% healing received. Dual-purpose zone: CC enemies and buff ally healing. Synergizes with Nature's `Hibernate` — sleep an enemy in the zone, they regen HP but so does the Greenseer's healing target. **Stance synergy**: In WARDEN, stationary cast gives +10% AoE radius (7.7 units). The grounded effect directly counters enemy WARDEN players. In PRESSURE, root + grounded keeps the target in place for sustained pressure without displacement risk — a pressure player's dream zone.
  3. **Thornwall** — Targeted ground line 12-range, 30s CD, Green 25 + Red 10 mana, 1.0s cast. Creates a wall of thorns (4 units wide, 2 units tall, lasts 5s). Enemies crossing the wall are `knockback`ed (3 units backward) + take 20 nature damage + 3s `bleed`. **Twist**: functions as terrain — projectiles are blocked, pathfinding must go around. First true terrain-creation CC ability. **Stance synergy**: In MOMENTUM, the wall's knockback on enemies who cross it scales with your Momentum stacks. In WARDEN, the wall creates line-of-sight breaks for re-entering Predator's Eye in the middle of combat. **Stance drawback**: In PRESSURE, enemies knockbacked by the wall counts as displacement — if your pressure target runs through the wall, their pressure gauge resets to 50%. Position the wall to TRAP them, not between you and them.

- ✅ **5l. Leyweaver CC Abilities** — `leyweaver_abilities.dart`
  1. **Binding Light** — Ranged 18-range, 22s CD, Blue 25 mana, 1.0s cast. Applies `root` (3s) + `silence` (2s) to target. **Twist**: while rooted, the target is also tethered to the ground point — if an ally knockbacks/displaces the target, the tether snaps them back to the root point at the end of displacement (anti-synergy protection — root means ROOTED, no one moves them, not even your allies). Helps healers lock down a target predictably. **Stance synergy**: In PRESSURE, root + silence is pure timed CC — no displacement, safe for pressure gauge. The tether prevents allies' knockbacks from resetting your pressure (Binding Light protects YOUR pressure build from friendly displacement). In CADENCE, on-beat root lasts 3.75s, silence 2.5s.
  2. **Purifying Radiance** — Self-centered AoE 10-radius, 35s CD, Blue 30 mana. Cleanses ALL CC effects from ALL allies within radius. Also applies `daze` (3s) to all enemies in radius. **Twist**: for each unique CC type cleansed, the AoE damage component increases by 10 (base 0 damage). Cleansing 3 different CC types from allies turns this into a 30-damage AoE punish. Reactive "the more you CC my friends, the harder I hit back." **Stance synergy**: In CADENCE, on-beat Purifying Radiance extends the daze to 3.75s AND the cleanse on beat removes one additional CC type. In FLUX, the mass cleanse also triggers for yourself (stance switching cleanses one soft CC — this cleanses ALL on allies), making FLUX Leyweaver the ultimate anti-CC support. **Stance drawback**: In CRUCIBLE, the cleanse function generates 2 Heat (it's a CC ability that applies daze) — don't spam it at high Heat.
  3. **Sanctuary** — Targeted ground AoE 6-radius, 40s CD, Blue 40 mana, 2.0s cast. Creates a holy zone (6s duration). Allies inside are immune to new CC applications (existing CC is NOT removed). Enemies inside are `slow`ed (20%). **Twist**: any CC that would be applied to an ally inside the sanctuary is instead reflected to the nearest enemy within the zone at 50% duration. CC reflection zone — enemies trying to CC inside the sanctuary get a taste of their own medicine. **Stance synergy**: In WARDEN, stationary cast gives +10% AoE radius (6.6 units). Allies in the Sanctuary can freely use CADENCE (no Groove reset from incoming CC) or MOMENTUM (no accelerated decay from CC). The zone removes the primary defensive weakness of those stances. In FLUX, the CC reflection applies stance duration bonuses to the reflected CC — reflected CC during your transition window gets +30% duration on the enemy.

- ✅ **5m. Aethermancer CC Abilities** — `aethermancer_abilities.dart`
  1. **Aether Lock** — Ranged 15-range, 20s CD, White 20 + Blue 15 mana, 0.8s cast. Applies `grounded` (5s) + `silence` (3s). **Twist**: the ultimate anti-caster CC combo — can't cast, can't escape. While locked, the target's mana regeneration is reversed (they LOSE mana at their normal regen rate). Drains resources on top of denying actions. **Stance synergy**: In CRUCIBLE at 0 Heat, silence lasts 4.5s and grounded 7.5s — the target is shut down for an enormous window. In CADENCE, on-beat silence is 3.75s. The mana drain is especially devastating against enemy CRUCIBLE players (they can't cast to shed Heat, and Heat decay pauses because silence counts as CC). **Stance drawback**: Against enemy FLUX players, the grounded is immediately cleansable with a stance switch (soft CC). The silence persists though, which prevents them from capitalizing on the switch.
  2. **Zephyr Banishment** — Ranged 18-range, 30s CD, White 30 mana, 1.0s cast. Applies `banish` (2.5s) to target, but the banished target is visually swept upward by wind (cosmetic Y-offset, not real airborne). **Twist**: when banish ends, the target reappears 8 units in a random direction from their original position (spatial displacement on return). The uncertainty of where they'll land disrupts enemy formations. **Stance synergy**: In FLUX, banish during transition window lasts 3.25s — more repositioning uncertainty. In CADENCE, on-beat banish is 3.1s. The random displacement on return is especially punishing for enemy PRESSURE players — they lose all built-up pressure when their target vanishes and they reappear far away.
  3. **Ley Surge Overload** — Self-centered AoE 6-radius, 25s CD, Blue 25 + White 10 mana. Deals 20 arcane damage + applies `disorient` (3s) to all enemies in radius. **Twist**: disoriented enemies near ley lines or ley power nodes take continuous arcane damage (5/s) for the disorient duration — the chaotic ley energy surges into their scrambled minds. Positional CC that's stronger near ley lines. **Stance synergy**: In WARDEN, stationary cast gives +10% AoE radius (6.6 units) and fighting near ley lines (where the Aethermancer wants to be for blue mana) maximizes the bonus damage. In MOMENTUM, the AoE disorient hitting 3+ targets grants double stacks. **Stance drawback**: In TEMPEST without a cancel chain, disorient is only 2.55s — still useful but the ley-line bonus damage has less time to tick.

---

#### Phase 6: CC Configuration, Tuning & Polish

- ✅ **6a. CC Tuning Tab** — `cc_tuning_tab.dart` (new, 345 lines) + `settings_panel.dart`
  Add a "Crowd Control" section to the Tuning tab in Settings. Fields for all CC config values: DR window/reductions, airborne physics, per-effect tuning values. Uses the standard ConfigEditorPanel pattern.

- ✅ **6b. Ability Editor CC fields** — `ability_editor_panel.dart` + `ability_editor_panel_sections.dart`
  Add CC-related fields to the ability editor: multi-effect `statusEffects` list editor (add/remove effects, set type/duration/strength per entry), `cleansesCC` toggle, `cleansesTypes` multi-select, scatter radius, gravity well duration/radius.

- ✅ **6c. Duel AI CC awareness** — `duel_ai_helpers.dart` + `duel_system.dart`
  Update duel AI to understand new CC types:
  - Don't attack sleeping targets unless going for burst kill
  - Prioritize attacking suppression casters to free allies
  - Use CC-break abilities when available and CC'd
  - Avoid gravity well zones and thorn walls
  - Target charmed enemies with burst (they can't defend)
  - Use movement abilities to escape grounded zones
  - Stance-aware CC usage: AI should consider its own stance when deciding CC timing (e.g., CRUCIBLE AI saves CC for 0-Heat payoff, MOMENTUM AI prefers displacement CC at high stacks, PRESSURE AI avoids displacement CC on its pressure target, CADENCE AI attempts to time CC on beat)
  - Stance-aware CC defense: AI in FLUX should stance-switch to cleanse soft CC, AI in TEMPEST should rely on reduced CC duration for aggressive play during CC recovery
  Priority scoring for CC abilities in `_abilityPriority()`.

- ✅ **6d. Combat log CC entries** — `ability_system_interactions.dart` + `cc_behavior_system.dart`
  Log all CC application, expiry, break, cleanse, and DR reduction events to combat log with appropriate formatting:
  - "Arcane Polymorph → Target [polymorphed] (6.0s)"
  - "Sleep broke on Target (damage from Fireball)"
  - "Diminishing Returns: Stun reduced 3.0s → 1.5s (2nd application)"
  - "Purifying Radiance cleansed [root, silence, slow] from Ally"

- ✅ **6e. CC visual effects pass** — `effects/cc_visual_effects.dart` (new, 456 lines)
  Create lightweight visual indicators for each new CC type:
  - Sleep: floating Z particles + blue tint
  - Charm: pink heart trail + screen vignette (player only)
  - Polymorph: mesh swap + poof particles
  - Taunt: red chain tether between units
  - Disorient: screen distortion + swirl particles
  - Grounded: vine wrap at feet + ground cracks
  - Suppress: dark chain links connecting units
  - Nearsight: dark vignette + fog overlay (player only)
  - Banish: translucent mesh + phase shimmer
  - Gravity Well: swirling vortex particles at anchor
  - Daze: circling amber stars above head
  - Airborne: upward wind streak trail during flight

- ✅ **6f. CC interaction matrix documentation** — `docs/CC_SYSTEM_GUIDE.md`
  Document all CC interactions, DR categories, per-class ability lists with twists, and combo synergies. Include a matrix of which effects stack, overwrite, or are mutually exclusive. Reference for future ability design.

- ✅ **6g. Stance-CC interaction documentation** — `docs/CC_SYSTEM_GUIDE.md` (section)
  Add a "Stance Interactions" section to the CC guide documenting:
  - Per-stance CC offense/defense/drawback summary table (7 stances × 3 columns)
  - Stance matchup chart: which stances counter or are countered by which CC strategies (e.g., "WARDEN is countered by grounded effects", "FLUX counters soft CC but is vulnerable to hard CC during stagnation", "CADENCE has the highest CC durations but is devastated by receiving CC")
  - Recommended stance picks per role: CC-focused player → CADENCE or CRUCIBLE for duration, displacement-focused → MOMENTUM, anti-CC support → FLUX or Leyweaver in any stance, pressure assassin → PRESSURE (avoid displacement CC)
  - Cross-reference each class ability's stance synergy notes from Phase 5

---

### ✅ Completed - 2026-03-15

#### Fighting Game Combo Redesign — All Melee/Ranged Classes
- ✅ **Windwalker** (JUGGLER): Added 3 new abilities — `Dragon Ascent` (launcher, stun+knockback), `Aerial Pursuit` (aerial follow-up), `Tempest Crash` (AoE ground slam finisher). Removed 4 redundant abilities (Tailwind Retreat, Wind Affinity, Silent Mind, Windshear). Added `comboPrimes` to all 22 abilities. Full juggle chain: Dragon Ascent → Aerial Pursuit → Tempest Crash.
- ✅ **Stormheart**: Removed `Spark Jab` (duplicate of Volt Strike). New combo chain: Volt Strike → Arc Punch → Chain Shock → Storm Surge → Thundergod Fist. Added `comboPrimes` to all 19 abilities.
- ✅ **Spiritkin**: Added 2 new abilities — `Pounce` (gap-closer, slow) and `Savage Tear` (heavy dual-claw finisher with bleed). Combo chain: Pounce → Swipe → Feral Strike → Spirit Bite → Savage Tear. Added `comboPrimes` to all combat abilities.
- ✅ **Mage**: Added `comboPrimes` to all abilities. Teleport/Counterspell prime melee punish combos. Chain: Arcane Pulse → Rift Blade → Chain Lightning.
- ✅ **Elemental**: Added `comboPrimes` throughout. Elemental reaction combos: Frostbite Slash (chill) → Magma Strike (fire reaction). Chain: Frostbite Slash → Magma Strike → Flame Wave.
- ✅ **Necromancer**: Added `comboPrimes` throughout. Chain: Curse of Weakness → Grave Touch → Soul Scythe → Soul Rot → Life Drain. Fear/Null Bolt prime punish windows.
- ✅ **Nature**: Added `Thornstep` (gap-closer with root, 8-range charge). Combo chain: Thornstep → Briar Lash → Ironwood Smash → Nature's Wrath. Added `comboPrimes` to all combat abilities.
- ✅ **Starbreaker**: Added `comboPrimes` throughout. Melee stack-build chain: Void Strike → Soul Rend → Entropy Smash → Singularity → Entropy Cascade → Stellar Collapse.
- ✅ Fixed dead references in `ability_system_windwalker.dart` and `ability_system_dispatch.dart` (removed 4 functions for deleted abilities). Fixed `duel_definitions.dart` to use `tempestCharge` instead of `tailwindRetreat`.
- ✅ `flutter analyze` — 0 new errors.

#### Giant Tower + World Map Interface
- ✅ **`lib/game3d/rendering/tower_mesh.dart`** (new, ~165 lines): 7-floor octagonal stone tower. `TowerMesh.create()` → (Mesh, Transform3d). Contains `_addFloorPlatforms`, `_addExteriorWalls`, `_addSpiralRamp` (1/4-turn per floor, 56 steps), `_addBattlements` (alternating merlons). Door opening on face 4 at ground floor. Static getters `centerX`, `centerZ`, `islandBaseY` for zone detection.
- ✅ **`lib/game3d/state/map_state.dart`** (new, ~65 lines): `MapMode` enum (world/dungeon). `MapState` class with zoomLevel (0-4), selectedFloor, panX/Z, terrainDirty, `worldZoomLevels/Labels/Resolutions`, `zoomIn()`, `zoomOut()`, `pan()`, `resetPan()`.
- ✅ **`lib/game3d/ui/map/world_map_painter.dart`** (new, ~170 lines): `WorldMapPainter` CustomPainter. Samples `InfiniteTerrainManager.getTerrainHeight()` on a grid; falls back to SimplexNoise for unloaded chunks. Static cache keyed on zoom/pan/chunk-count. Draws player yellow dot.
- ✅ **`lib/game3d/ui/map/dungeon_map_painter.dart`** (new, ~180 lines): `DungeonMapPainter` CustomPainter. Octagonal floor outlines (active floor filled grey, others faint). Door arrow on ground floor. Up/down stair arrows. Player, ally, enemy dots.
- ✅ **`lib/game3d/ui/map/map_panel.dart`** (new, ~200 lines): `MapPanel` StatelessWidget. 80% screen centered overlay. Title bar, close button, reset-pan button. Floor selector (1-7 buttons) in dungeon mode. Drag-to-pan in world mode. Zoom bar (−/label/+) in world mode. Auto-switches mode based on `gameState.isIndoors`.
- ✅ **`lib/game3d/state/game_state.dart`**: Added `towerMesh`, `towerTransform`, `isIndoors`, `currentFloor`, `currentZoneName`, `mapPanelOpen`, `mKeyCycle`, `mapState` fields. Imports `map_state.dart`.
- ✅ **`lib/rendering3d/camera3d.dart`**: Added `CameraMode.dungeon` enum value. Added `_lerpTargetPitch/Distance/Fov` nullable fields. Added `setDungeonMode(bool)` (sets outdoor 35°/15/60° or dungeon 55°/11/68° targets). Added `updateCameraLerp(dt)` (lerps each target using `_cameraLerpSpeed = 8.0`).
- ✅ **`lib/game3d/game3d_widget_init.dart`**: Initializes tower mesh after floating island.
- ✅ **`lib/game3d/systems/render_system.dart`**: Renders tower mesh after floating island.
- ✅ **`lib/game3d/game3d_widget_input.dart`**: M key replaced with 4-state cycle (mKeyCycle 0-3 → minimap+map open states). Escape closes mapPanelOpen first.
- ✅ **`lib/game3d/game3d_widget_update.dart`**: Calls `camera.updateCameraLerp(dt)` each frame. `_updateTowerZone()` detects XZ+Y tower threshold → sets `isIndoors`, `currentFloor`, `currentZoneName`, triggers `camera.setDungeonMode()`.
- ✅ **`lib/game3d/game3d_widget_ui.dart`**: Added `MapPanel` to stack (shown when `mapPanelOpen`). Minimap unchanged (still `minimapOpen && _isVisible('minimap')`).
- ✅ **`lib/models/game_action.dart`**: `cameraPitchDown` rebound from `keyM` → `comma`.
- ✅ **`lib/game3d/ui/settings/interface_config.dart`**: Minimap `shortcutKey` → `''`. Added `map_panel` entry with `shortcutKey: 'M'`.
- ✅ Build verified: `flutter analyze --no-pub` — 0 new errors/warnings (3 pre-existing warnings unchanged).

#### Class Self-Buffs, Party Buffs, and Aura System
- ✅ **`ability_types.dart`**: Added `isAura` (bool), `auraRange` (double, default 10.0), `isPartyBuff` (bool) to `AbilityData` with full serialization (constructor, copyWith, toJson, fromJson, applyOverrides).
- ✅ **`active_effect.dart`**: Fixed `isDoT` to use `damagePerTick.abs() > 0` so HoT (healing-over-time with negative damagePerTick) also ticks.
- ✅ **`gameplay_aura_system.dart`** (new, 134 lines): `GameplayAuraSystem.update()` runs every second; finds all units with aura effects, applies/refreshes a 3s pulse buff to all friendlies within `auraRange`. Registered in game loop.
- ✅ **`ability_system_interactions.dart`**: Added `_activeStrengthMult()` helper; applied to melee and AoE damage so strength buffs affect outgoing damage.
- ✅ **`ability_system_implementations.dart`**: Added `_executeBuffSelf`, `_executePartyBuff`, `_executeAuraActivate` helpers + 13 concrete dispatch functions.
- ✅ **13 new 60-min buff abilities** added (one per class):
  - Warrior: "Battle Presence" — RED AURA, `strength +25%`, 10 yd range
  - Mage: "Arcane Empowerment" — BLUE AURA, `strength +25%`, 10 yd range
  - Windwalker: "Gale Stride" — WHITE AURA, `haste +20%`, 10 yd range
  - Greenseer: "Living Web" — GREEN AURA, `regen 4/2s`, 10 yd range
  - Starbreaker: "Void Resonance" — BLACK AURA, `shield 25`, 10 yd range
  - Rogue: "Shadow Form" — self-buff, `haste +25%`
  - Stormheart: "Storm Hardened" — self-buff, `regen 3/2s`
  - Nature: "Nature's Resilience" — self-buff, `regen 3/2s`
  - Spiritkin: "Spirit Bond" — self-buff, `strength +20%`
  - Necromancer: "Death Shroud" — self-buff, `shield 30`
  - Elemental: "Elemental Attunement" — self-buff, `strength +20%`
  - Leyweaver: "Blessing of Kings" — PARTY BUFF (all friendlies), `strength +15%`
  - Aethermancer: "Aether Flow" — PARTY BUFF (all friendlies), `haste +20%`
- ✅ **`ability_system_dispatch.dart`**: 13 new dispatch cases added.
- ✅ Build verified: `flutter analyze --no-pub` — 0 errors (21 pre-existing infos unchanged).

### ✅ Completed - 2026-03-14

#### Duel AI Combo Awareness
- ✅ **`lib/game3d/state/duel_manager.dart`**: Added `combatantPrimedAbilities: List<Set<String>>` field.
- ✅ **`lib/game3d/game3d_widget_duel.dart`**: Initialize and clear `combatantPrimedAbilities` at duel start/reset.
- ✅ **`lib/game3d/systems/duel_system.dart`**: Track primed abilities after each fired ability; clear on combo window expiry. `_runAI` reads primed set and prioritizes follow-up abilities.
- ✅ **`lib/game3d/systems/duel_ai_helpers.dart`**: `_abilityPriority` accepts `primedNames` set; primed abilities get priority score 200 (highest).

#### Duel Arena Randomize + Seed System
- ✅ **`lib/game3d/ui/duel/duel_panel.dart`**: Added `TextEditingController` for challenger and enemy seeds; `dispose()` cleanup.
- ✅ **`lib/game3d/ui/duel/duel_panel_setup.dart`**: Added `_randomizeRow` (Rnd button, seed TextField, ↵ button). Added `_randomizeSide`, `_computeSeed`, `_applySeed` helpers. Seeds encode partySize + per-slot classIndex×5+gearTier using stable `allCombatantTypes` index.

#### Ability Queue Exit Animation
- ✅ **`lib/game3d/state/gameplay_settings.dart`**: Added `queueExitDuration` (double, default 1.0s) with SharedPreferences persistence.
- ✅ **`lib/game3d/ui/damage_indicators.dart`**: Added `ExitingQueueLabel` class (age/maxAge/opacity). Updated `QueuedAbilityLabelOverlay` to accept and render exiting labels inline in yellow at front of queue, fading out.
- ✅ **`lib/game3d/state/game_state.dart`**: Added `exitingQueueLabels: List<ExitingQueueLabel>`.
- ✅ **`lib/game3d/systems/ability_system_updates.dart`**: Added `_updateExitingQueueLabels(dt, gs)`; `_drainAbilityQueue` creates `ExitingQueueLabel` before executing.
- ✅ **`lib/game3d/systems/ability_system.dart`**: Added `globalGameplaySettings` import; added `_updateExitingQueueLabels` call in update loop.
- ✅ **`lib/game3d/systems/ability_system_core.dart`** + **`_dispatch.dart`**: Wrapped `executingAbilityLabel` assignments with `if (!_isDrainingQueue)` guard.
- ✅ **`lib/game3d/game3d_widget_ui.dart`**: Passed `exitingLabels: gameState.exitingQueueLabels` to `QueuedAbilityLabelOverlay`.
- ✅ **`lib/game3d/ui/settings/typography_tab.dart`**: Added "Exit Fade" duration slider (0.0–3.0s) in Queue section.

#### Ley Lines Terrain Drape Fix
- ✅ **`lib/game3d/systems/render_system.dart`** (`_createLeyLineMesh`): Per-corner terrain height sampling (4 outer corners + 2 centerline per sub-quad). Cross-slope quads now tilt correctly. `subdivStep` 6.0→3.0, `maxSteps` 40→80.

### ✅ Completed - 2026-03-04

#### Code Quality & Performance Optimization (Multi-Session)
- ✅ Removed unused `healer_abilities.dart` + source-tree entry (replaced by `leyweaver_abilities.dart`)
- ✅ **Item 8**: `attackType.split(' ').first` → zero-allocation substring in `combat_system.dart:147`
- ✅ **Item 7**: 172 `.withOpacity(x)` → `.withValues(alpha: x)` across all Dart files (Flutter deprecation)
- ✅ **Item 10**: 6 `unnecessary_brace_in_string_interps` fixed across 5 files
- ✅ **Item 11**: 72 `use_super_parameters` fixed via `dart fix --apply` across 60 files
- ✅ **Item 12**: `prefer_conditional_assignment` in `bezier_path.dart:142`
- ✅ Build verified: `flutter analyze --no-pub` — 191 issues (down from 441), 0 errors
- ✅ 133 more fixes via `dart fix --apply` (annotate_overrides, curly_braces, unnecessary_this, dangling_library_doc, etc.)
- ✅ 62 `invalid_use_of_protected_member` in 11 extension-on-State part files → `ignore_for_file` directives
- ✅ Particle structs (`_GreenSparkle`, `_MeteorParticle`, `_WindParticle`): converted constructor params → inline field initializers (pool pattern)
- ✅ `use_build_context_synchronously` in `interfaces_tab.dart` — capture `ScaffoldMessenger` before `await`
- ✅ `_initializeScenarioConfig` false-positive unused warning suppressed
- ✅ `defForSlot` → `_defForSlot` to fix `library_private_types_in_public_api`
- ✅ `<String, dynamic>` angle brackets in two doc comments → backtick-escaped
- ✅ Final: `flutter analyze --no-pub` — **12 issues** (down from 441), all `info`-level architectural/intentional

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
- ✅ Cooldown list refactor — already completed: `abilityCooldowns` is `List<double>.filled(15, 0.0)` with all consumers using indexed list access
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
