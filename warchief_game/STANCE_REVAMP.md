# Stance Revamp — 7 Playstyle-Altering Stances

## Design Philosophy

The previous 6 stances (Drunken Master, Blood Weave, Tide, Phantom Dance, Fury of the Ancestors, Starbreaker) were primarily stat-multiplier packages — they adjusted numbers but didn't fundamentally change how you play. These 7 new stances alter **playstyle, tactics, and ability interactions**, creating distinct gameplay loops that reward mastery and induce flow states.

Research basis: Nioh (Ki Pulse rhythm), Sekiro (posture/aggression), DMC/Black Myth Wukong (style meters), Ghost of Tsushima (tactical switching), Crimson Desert (elemental break), Replaced (kinetic charge bridge), 007 First Light + LEGO Batman (stealth/predator preparation).

---

## The 7 Stances

### 1. CADENCE (Rhythm Pulse)

**Icon**: `music_note` | **Color**: `[0.9, 0.6, 0.2]` (warm amber)

**Core Mechanic**: A visible pulse timer beats on the action bar (~90 BPM configurable). Abilities executed within the beat window (+-200ms) receive bonuses.

**Properties**:
- `rhythmPulseInterval`: 0.667 (seconds between beats, ~90 BPM)
- `rhythmBeatWindow`: 0.200 (+-ms tolerance for on-beat detection)
- `rhythmDamageBonus`: 0.25 (on-beat abilities deal +25% damage)
- `rhythmCooldownRefund`: 0.40 (on-beat abilities get 40% cooldown reduction on that cast)
- `rhythmManaRefund`: 0.30 (on-beat abilities refund 30% mana cost)
- `grooveMaxStacks`: 5 (consecutive on-beat casts build Groove)
- `grooveHastePerStack`: 0.05 (+5% global haste per Groove stack)
- Missing the beat resets Groove to 0

**Stat Tradeoffs**:
- `damageMultiplier`: 0.85 (-15% base damage, compensated by on-beat bonus)
- `maxHealthMultiplier`: 0.90 (-10% max health)

**Playstyle**: Musical, meditative. Players learn to time rotations to the pulse. High skill ceiling — optimal play requires planning ability sequences that land on beats.

---

### 2. TEMPEST (Animation Acceleration)

**Icon**: `speed` | **Color**: `[1.0, 0.45, 0.1]` (blazing orange)

**Core Mechanic**: Dramatically speeds up ability execution. Successful hits allow "canceling" recovery into the next ability, creating rapid combo chains with escalating damage.

**Properties**:
- `windupReduction`: 0.50 (all windup times -50%)
- `castTimeReduction`: 0.35 (all cast times -35%)
- `cancelWindowDuration`: 0.40 (0.4s window after hit to skip GCD)
- `cancelMaxChain`: 4 (chains up to 4 abilities deep)
- `cancelChainDamageScale`: [1.0, 1.10, 1.25, 1.50] (escalating damage multiplier per chain position)
- `channelTickSpeedBonus`: 0.40 (channels tick 40% faster)

**Stat Tradeoffs**:
- `damageMultiplier`: 0.80 (-20% base damage, compensated by chain scaling)
- `manaCostMultiplier`: 1.15 (+15% mana cost outside chains)
- `maxHealthMultiplier`: 0.85 (-15% max health)

**Playstyle**: Blisteringly fast. Execute 4-ability combos in the time it normally takes to cast 2. The cancel window creates a tight execution test — queue the next ability within 0.4s or the chain breaks.

---

### 3. WARDEN (Tactical Movement + Predator's Eye)

**Icon**: `shield` | **Color**: `[0.3, 0.7, 0.35]` (forest green)

**Core Mechanic**: WASD directional inputs before an ability modify its properties. Includes a stealth/observation pre-combat mechanic inspired by 007 First Light and LEGO Batman's predator systems.

**Directional Modifiers** (apply within `movementInputWindow` of ability cast):
- `movementForwardRangeBonus`: 0.30 (+30% range when pressing W)
- `movementForwardDamageBonus`: 0.15 (+15% damage when pressing W)
- `movementBackwardDamageReduction`: 0.25 (-25% damage taken for 1.5s when pressing S)
- `movementBackwardKnockbackBonus`: 0.20 (+20% knockback force when pressing S)
- `movementStrafeDodgeBonus`: 0.15 (+15% dodge chance for 1s when pressing A/D)
- `movementStrafePiercing`: true (abilities gain piercing when strafing)
- `movementStationaryDamageBonus`: 0.20 (+20% damage when stationary)
- `movementStationaryAoeBonus`: 0.10 (+10% AoE radius when stationary)
- `movementInputWindow`: 0.8 (seconds after movement input that bonus persists)
- Sprint (Shift+W) before ability: dash-attack with double knockback

**Predator's Eye** (stealth/observation pre-combat):
- `predatorActivationTime`: 2.0 (stand still out of combat for 2s to enter Predator's Eye)
- `predatorAllBonuses`: true (Calculated Strike from Predator's Eye gains ALL directional bonuses simultaneously)
- `predatorExposedDuration`: 3.0 (enemies hit by Calculated Strike are "Exposed" for 3s)
- `predatorExposedDamageBonus`: 0.25 (Exposed targets take +25% damage from all sources)
- Re-entering Predator's Eye requires leaving combat and standing still again

**Stat Tradeoffs**:
- `movementSpeedMultiplier`: 0.90 (-10% movement speed)
- `cooldownMultiplier`: 1.10 (+10% cooldowns)

**Playstyle**: Deliberate, tactical. Every movement decision has combat weight. The Predator's Eye creates an Observe -> First Strike -> Tactical Combat loop.

---

### 4. CRUCIBLE (Burst Overload)

**Icon**: `local_fire_department` | **Color**: `[1.0, 0.3, 0.15]` (molten red)

**Core Mechanic**: All cooldowns halved, but each ability cast adds Heat. Heat increases costs and vulnerability. Overheating silences you. Managing the edge between maximum output and Overheat is the core skill.

**Properties**:
- `cooldownMultiplier`: 0.50 (all cooldowns -50%)
- `heatPerCast`: 1 (each ability adds 1 Heat stack)
- `heatMaxStacks`: 10
- `heatDecayRate`: 0.5 (lose 1 stack every 2s when not casting)
- `heatManaCostPerStack`: 0.08 (+8% mana cost per Heat stack)
- `heatDamageTakenPerStack`: 0.03 (+3% damage taken per Heat stack)
- `overheatSilenceDuration`: 3.0 (at 10 Heat: silenced for 3s)
- `overheatCooldownPenalty`: 1.50 (after Overheat: all cooldowns set to 150%)
- `coolDownPayoffDamageBonus`: 0.40 (first ability at 0 Heat gets +40% damage)
- Crits reduce Heat by 1 (skill-based heat management)

**Stat Tradeoffs**: Inherent in the Heat system — casting more = higher costs + vulnerability.

**Playstyle**: Controlled aggression with burst windows. Dump 5-6 abilities rapidly, back off to let Heat decay, then burst again. Optimal play: skating at 8-9 Heat without Overheating.

---

### 5. MOMENTUM (Combo Escalation + Kinetic Overflow)

**Icon**: `trending_up` | **Color**: `[0.2, 0.5, 1.0]` (electric blue)

**Core Mechanic**: Every ability hit builds Momentum stacks. Stacks enhance all subsequent abilities. At max stacks, abilities gain splash damage and cross-domain Kinetic Overflow bonuses (inspired by Replaced's kinetic charge system).

**Properties**:
- `momentumMaxStacks`: 8
- `momentumDecayInterval`: 2.5 (lose 1 stack every 2.5s without landing a hit)
- `momentumCooldownPerStack`: 0.06 (-6% cooldown per stack)
- `momentumAoePerStack`: 0.04 (+4% AoE radius per stack)
- `momentumCastPerStack`: 0.05 (-5% cast time per stack)
- `momentumDamagePerStack`: 0.03 (+3% damage per stack)
- `momentumSplashAtMax`: true (at 8 stacks: abilities gain splash damage)
- `momentumSplashRatio`: 0.25 (splash = 25% of damage)
- `momentumSplashRadius`: 3.0 (splash radius in world units)
- AoE abilities hitting 3+ targets add 2 stacks instead of 1
- Combo-primed abilities add 2 stacks

**Kinetic Overflow** (at max stacks, cross-domain bonus):
- `kineticOverflowBonus`: 0.30 (+30% bonus)
- After melee at max -> next ranged ability: +30% damage, +50% projectile speed
- After ranged at max -> next melee ability: +30% damage, lunge/gap-close effect
- After any at max -> next heal: +30% heal amount, instant cast

**Stat Tradeoffs**:
- `damageMultiplier`: 0.80 (-20% damage at 0 stacks)
- `manaRegenMultiplier`: 0.75 (-25% mana regen)

**Playstyle**: Aggressive, non-stop rotation. Constantly pressing buttons to maintain stacks. The splash at max stacks and Kinetic Overflow create explosive payoff moments.

---

### 6. PRESSURE (Aggression Gauge + Elemental Break)

**Icon**: `compress` | **Color**: `[0.8, 0.15, 0.15]` (deep crimson)

**Core Mechanic**: Hits build an invisible pressure gauge on your current target. At 100%, the target BREAKS — devastating stun + damage amp + cooldown reset. Break effect varies by dominant damage school used during pressure building (inspired by Crimson Desert's Axiom Bracelet elemental break system).

**Properties**:
- `pressurePerMelee`: 0.15 (15% pressure per melee hit)
- `pressurePerRanged`: 0.10 (10% per ranged hit)
- `pressurePerDot`: 0.05 (5% per DoT tick)
- `pressureDecayPerSecond`: 0.08 (8%/s decay when target not being hit)
- `pressureComboBonus`: 0.05 (+5% extra pressure for consecutive hits within 1.5s)
- `pressureWindupBonus`: 0.25 (windup abilities add 25% pressure if they land)
- `pressureBreakStunDuration`: 2.0 (Break stun lasts 2s)
- `pressureBreakDamageBonus`: 0.60 (target takes +60% damage during Break)
- `pressureBreakResetsAllCooldowns`: true
- Target-switch penalty: pressure on previous target decays at 3x speed

**Elemental Break Effects** (based on dominant DamageSchool during pressure build):
- **Physical-dominant**: "Shatter" — knockdown + 60% physical damage amp (default Break)
- **Fire-dominant**: "Ignition" — target burns, nearby enemies take 40% of Break damage as AoE
- **Frost-dominant**: "Deep Freeze" — 3s freeze (longer than default stun) + 5s movement debuff
- **Lightning-dominant**: "Overload" — chain explosion, 30% of accumulated damage to 3 nearby enemies
- **Shadow-dominant**: "Void Collapse" — 4s silence + abilities during Break cost no mana
- **Other schools**: Default Break with school-appropriate visuals

**Stat Tradeoffs**:
- `damageTakenMultiplier`: 1.15 (+15% damage taken — you're in their face)
- Secondary targets: -30% damage effectiveness

**Playstyle**: Relentless aggressor. Commit to a single target and pound it. The Break moment (stun + amp + CD reset) is a massive payoff. Choosing which abilities to use during buildup controls the Break type.

---

### 7. FLUX (Stance-Dance Synergy)

**Icon**: `swap_horiz` | **Color**: `[0.6, 0.3, 0.9]` (violet)

**Core Mechanic**: Rewards rapid stance-switching as a core mechanic. The act of switching stances becomes a combat ability. You don't stay in Flux — you pass through it.

**Properties**:
- `transitionBonusDamage`: 0.50 (first ability within window: +50% damage)
- `transitionBonusWindow`: 1.5 (seconds after switching INTO Flux to get bonus)
- `transitionInstantCast`: true (first ability within window is instant cast)
- `transitionNoManaCost`: true (first ability within window costs no mana)
- `fluxMemoryDuration`: 8.0 (leave Flux, return within 8s: last ability's CD reset)
- `weaveThreshold`: 3 (3+ stance switches in weaveWindow triggers Weave State)
- `weaveWindow`: 10.0 (seconds to accumulate switches)
- `weaveBonusDuration`: 5.0 (Weave State lasts 5s)
- `weaveBonusMultiplier`: 0.20 (+20% to all effects during Weave State)
- `weaveHealPerSwitch`: 0.03 (3% max HP heal per switch during Weave State)
- `fluxSwitchCooldown`: 0.5 (stance switch cooldown while in Flux, normally 1.5s+)
- `stagnationPenaltyTime`: 5.0 (after 5s without switching, damage drops -30%)
- `stagnationDamageReduction`: 0.30

**Stat Tradeoffs**: Inherent in the stagnation penalty — staying in Flux too long is punished.

**Playstyle**: You pass through Flux as a "transit hub." Rotation: Other Stance -> Flux (bonus ability) -> Other Stance -> Flux (bonus ability). Mastery means building muscle memory for rapid stance cycling.

---

## Implementation Notes

### New Fields Required on StanceData

All 7 stances introduce new properties beyond the existing `StanceData` multiplier fields. These should be added as optional fields (defaulting to 0/false/empty) so the existing 6 stances continue to work unchanged. The new fields fall into stance-specific groups:

**Cadence group**: `rhythmPulseInterval`, `rhythmBeatWindow`, `rhythmDamageBonus`, `rhythmCooldownRefund`, `rhythmManaRefund`, `grooveMaxStacks`, `grooveHastePerStack`

**Tempest group**: `windupReduction`, `castTimeReduction`, `cancelWindowDuration`, `cancelMaxChain`, `cancelChainDamageScale` (List<double>), `channelTickSpeedBonus`

**Warden group**: `movementForwardRangeBonus`, `movementForwardDamageBonus`, `movementBackwardDamageReduction`, `movementBackwardKnockbackBonus`, `movementStrafeDodgeBonus`, `movementStrafePiercing`, `movementStationaryDamageBonus`, `movementStationaryAoeBonus`, `movementInputWindow`, `predatorActivationTime`, `predatorExposedDuration`, `predatorExposedDamageBonus`

**Crucible group**: `heatPerCast`, `heatMaxStacks`, `heatDecayRate`, `heatManaCostPerStack`, `heatDamageTakenPerStack`, `overheatSilenceDuration`, `overheatCooldownPenalty`, `coolDownPayoffDamageBonus`

**Momentum group**: `momentumMaxStacks`, `momentumDecayInterval`, `momentumCooldownPerStack`, `momentumAoePerStack`, `momentumCastPerStack`, `momentumDamagePerStack`, `momentumSplashAtMax`, `momentumSplashRatio`, `momentumSplashRadius`, `kineticOverflowBonus`

**Pressure group**: `pressurePerMelee`, `pressurePerRanged`, `pressurePerDot`, `pressureDecayPerSecond`, `pressureComboBonus`, `pressureWindupBonus`, `pressureBreakStunDuration`, `pressureBreakDamageBonus`, `pressureBreakResetsAllCooldowns`

**Flux group**: `transitionBonusDamage`, `transitionBonusWindow`, `transitionInstantCast`, `transitionNoManaCost`, `fluxMemoryDuration`, `weaveThreshold`, `weaveWindow`, `weaveBonusDuration`, `weaveBonusMultiplier`, `weaveHealPerSwitch`, `fluxSwitchCooldown`, `stagnationPenaltyTime`, `stagnationDamageReduction`

### Runtime State Required

Each stance needs runtime state tracking (on the player/GameState, NOT on StanceData):

- **Cadence**: `cadenceBeatTimer`, `cadenceGrooveStacks`, `cadenceLastBeatHit`
- **Tempest**: `tempestChainDepth`, `tempestCancelWindowTimer`, `tempestLastChainAbility`
- **Warden**: `wardenLastMoveDirection`, `wardenMoveInputTimer`, `wardenPredatorTimer`, `wardenInPredatorMode`
- **Crucible**: `crucibleHeatStacks`, `crucibleHeatDecayTimer`, `crucibleOverheated`, `crucibleOverheatTimer`
- **Momentum**: `momentumStacks`, `momentumDecayTimer`, `momentumLastAbilityType`
- **Pressure**: `pressurePerTarget` (Map<entity, double>), `pressureLastHitTimer`, `pressureDamageSchoolAccum` (Map<DamageSchool, int>)
- **Flux**: `fluxTransitionTimer`, `fluxMemoryAbility`, `fluxMemoryTimer`, `fluxSwitchCount`, `fluxWeaveTimer`, `fluxStagnationTimer`

### Files to Modify

1. **`stance_types.dart`** — Add new StanceId enum values + new fields on StanceData
2. **`stance_definitions.dart`** — Add parsing for new stance IDs and fields
3. **`stance_config.json`** — Add all 7 new stance definitions with their properties
4. **`game_state.dart`** — Add runtime state fields for active stance mechanics
5. **`ability_system.dart` / subsystems** — Hook stance mechanics into ability execution pipeline
6. **`combat_system.dart`** — Hook Pressure gauge and Momentum tracking into damage events
7. **`stance_editor_panel.dart`** — Add UI fields for new properties
8. **New file: `stance_system.dart`** — Per-frame update logic for all stance runtime state (beat timers, stack decay, heat decay, pressure decay, stagnation timers)

### Existing Infrastructure to Reuse

- `StanceData.modifierSummary` pattern for tooltip generation
- `StanceData.applyOverrides()` pattern for runtime editing
- `StanceData.copyWith()` for field replacement
- `globalStanceRegistry` singleton for stance lookup
- `ActiveEffect` system for Crucible silence, Pressure Break stun
- `StatusEffect.silence` for Overheat
- Combo prime system (`comboPrimes`) already integrates with Momentum's double-stack mechanic
- Wind/weather system already reads `windResistance` from stances
