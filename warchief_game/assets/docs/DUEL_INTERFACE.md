# Duel Arena Interface

The Duel Arena is a balance-testing tool that lets you pit any combination of
Warchief character classes against enemy faction types in a fully simulated
combat scenario. It is opened with **U** and rendered as a draggable 560×640px
panel.

---

## Panel Structure

The panel has three tabs:

| Tab | Purpose |
|-----|---------|
| **Setup** | Configure parties, gear quality, and strategy before a duel |
| **Active** | Live stats, event log, and in-flight controls |
| **History** | Scrollable log of past results (persisted via SharedPreferences) |

---

## Setup Tab

### Sides

| Side | Label | State key |
|------|-------|-----------|
| Blue (Challengers) | `BLUE SIDE` | `_chalClasses`, `_chalGearTiers`, `_chalStrategy` |
| Red (Enemies) | `RED SIDE` | `_enemyTypes`, `_enemyGearTiers`, `_enemyStrategy` |

### Party Size (1–5)

Each side independently selects 1–5 combatants via numbered buttons. Changing
party size grows the class / gear-tier arrays (slots are never truncated, only
extended with `null` / `0`).

### Character Slots

Each slot shows:

1. **Class/type dropdown** — challenger side draws from
   `DuelDefinitions.challengerClasses`; enemy side from
   `DuelDefinitions.enemyFactionTypes`. Abilities are loaded from the class
   registry at duel start (see `_startDuel` in `game3d_widget_commands.dart`).

2. **Gear tier selector** — five coloured circles (Common → Legendary). A filled
   circle is the active tier; unselected tiers render at 15% opacity.

   | Tier | Colour | Health × | Mana × | Damage × |
   |------|--------|----------|--------|----------|
   | 0 Common | Grey | 1.00 | 1.00 | 1.00 |
   | 1 Uncommon | Green | 1.20 | 1.20 | 1.10 |
   | 2 Rare | Blue | 1.50 | 1.50 | 1.25 |
   | 3 Epic | Purple | 1.85 | 1.85 | 1.45 |
   | 4 Legendary | Orange | 2.30 | 2.30 | 1.70 |

   Multiplier values are sourced from `assets/data/duel_config.json →
   gearTiers`. The health and mana multipliers are applied at spawn time; the
   damage multiplier is applied per-ability at deal time
   (`dmg = ability.damage * gearDamageMult`).

### Strategy Dropdown

Each side picks an **AI strategy**. Options and their behaviour are described in
the next section.

### Start Duel Button

Active once all slots for each party are filled and no duel is in progress.
Clicking builds a `DuelSetupConfig` snapshot and hands it to
`widget.onStartDuel`, which wires into `_startDuel()` in the command handler.
The panel automatically switches to the **Active** tab.

---

## Active Tab

Displays:

- Elapsed time (seconds)
- Per-side stats block: total damage dealt and total healing done
- Reverse-chronological **Event Log** (capped at 50 visible rows)

Controls visible while a duel is in progress:

- **Reset Cooldowns** — calls `DuelSystem.resetCooldowns(duelCombatants)`,
  zeroing every ability cooldown across all active combatants on both sides.
  Useful for immediately re-testing a composition after one side wins.

- **Cancel Duel** — calls `_cancelDuel()`, which invokes `manager.reset()` and
  removes all duel combatants from the game world.

---

## History Tab

Lists every completed duel (winner, matchup string, duration). Entries are
capped at `duel_config.json → historyMaxEntries` (default 200) and persist
across page reloads via `SharedPreferences`.

---

## How Characters Are Controlled

### Simulation Model

All duel combatants are standard `Ally` objects placed in the game world behind
the player. They are driven exclusively by `DuelSystem.update(dt, gameState)`,
called once per game frame during an active duel. They do **not** use the
main `ai_system.dart` code path.

### Per-Frame Loop

For each alive combatant:

1. **Mana regen** — all five mana pools regen at `duel_config.json →
   manaRegenPerSecond` (default 5/s).
2. **Cooldown tick** — ability cooldowns count down by `dt`.
3. **AI decision** (`_runAI`) — movement then ability selection.

### Target Selection

All strategies select the **weakest alive enemy** as their attack target
(minimum current HP). This greedy target selection is the same across all five
strategies and is not currently configurable.

### Movement (Engagement Range)

Each strategy has a `_preferredDistance` in world units:

| Strategy | Preferred Range |
|----------|----------------|
| Berserker | 1.5 |
| Aggressive | 2.5 |
| Balanced | 2.5 |
| Defensive | 6.0 |
| Support | 7.0 |

If `dist > preferred + 0.5`, the combatant moves toward the target at
`moveSpeed`. If the **Defensive** strategy and `dist < preferred - 1.5`, the
combatant kites backward at half speed to maintain range.

### Ability Selection

Two selection modes:

**Balanced** — greedy: iterates the ability list in definition order and uses
the first ability that is off cooldown and affordable.

**All other strategies** — priority scored: every ready and affordable ability
is scored by `_abilityPriority()`. The highest-scoring ability is used. Ties
resolve in list order.

### Strategy Reference

| Strategy | Heal threshold | Damage bias | Movement |
|----------|---------------|-------------|----------|
| **Balanced** | Greedy (list order) | — | Range 2.5 |
| **Aggressive** | Only below 20% HP | Max-damage score | Range 2.5 |
| **Berserker** | Never heals | Max-damage + 100 bonus | Range 1.5 (melee) |
| **Defensive** | Below 50% HP (score 120) | Score 30 otherwise | Range 6.0, kites |
| **Support** | Below 75% HP (score 120), score 50 otherwise | Score 10 | Range 7.0 |

**Support heal targeting**: when the healer has multiple party members alive,
it heals the **lowest-HP ally in its own party** rather than itself.

### Win Condition

- If all challengers reach 0 HP → Red side wins.
- If all enemies reach 0 HP → Blue side wins.
- Both simultaneously → Draw.
- Timeout (configurable via `duel_config.json → maxDurationSeconds`, default
  120 s) → side with more total HP remaining wins.

---

## Key Source Files

| File | Purpose |
|------|---------|
| `lib/game3d/ui/duel/duel_panel.dart` | 3-tab panel widget + Active/History tabs |
| `lib/game3d/ui/duel/duel_panel_setup.dart` | Setup tab (part file) |
| `lib/game3d/systems/duel_system.dart` | Per-frame AI, cooldowns, win detection |
| `lib/game3d/state/duel_manager.dart` | State machine, stats, persistence |
| `lib/game3d/state/duel_config.dart` | JSON config model |
| `lib/game3d/data/duel/duel_definitions.dart` | Class/type registries, ability factories |
| `assets/data/duel_config.json` | Gear multipliers, mana regen, max duration |

---

## Suggested Next Development Steps

### 1. Smarter Target Selection

Current targeting always picks the lowest-HP enemy. A richer model could:

- **Aggressive / Berserker** — focus the *highest-threat* target (most damage
  dealt so far).
- **Support** — ignore enemies entirely and focus heals on the
  most-wounded ally.
- **Focus-fire toggle** — all combatants on a side attack the same target,
  preventing damage spreading.

### 2. Ability Type Awareness

Ability selection currently uses `ability.damage` as a proxy for value. A more
capable scorer could consider:

- **DoT duration** — prefer DoTs when the target is already at low HP so the
  tick damage overshoots.
- **AoE** — upweight AoE abilities when multiple enemies are in range.
- **Crowd-control interrupts** — interrupt a casting enemy's highest-damage
  ability.
- **Resource efficiency** — prefer abilities with best
  damage-per-mana when mana is low.

### 3. Positional Tactics

Movement is currently one-dimensional (approach / kite along the line to the
target). Improvements:

- **Flanking** — Aggressive units try to approach from outside the defensive
  unit's preferred arc.
- **Formation spreading** — party members spread horizontally to reduce AoE
  damage.
- **Line-of-sight** — ranged units use terrain to duck in and out of cover.

### 4. Reactive / State-Machine AI

Replace the stateless per-frame heuristic with a lightweight finite-state
machine per combatant:

```
IDLE → ENGAGE → FIGHTING → RETREAT (low HP) → FIGHTING
                         → HEALING (support)
```

State transitions allow units to "react" (e.g. retreating when below 30% HP
rather than continuing to attack) rather than re-evaluating from scratch each
frame.

### 5. Ability Combo Sequences

Some classes have optimal opener rotations. A combo system could:

- Define ordered `List<String>` macro sequences per strategy profile.
- Execute the macro until it stalls (ability not ready / out of mana), then
  fall back to priority scoring.
- This bridges the gap between the current duel AI and the existing
  `MacroSystem` used by the player.

### 6. Cross-Party Coordination

Multi-combatant parties currently make independent decisions. A coordination
layer could:

- Assign **roles** at setup (tank, healer, DPS) based on class capability.
- Have DPS units focus-fire the target currently being kited by the tank.
- Have the healer track which DPS needs healing instead of always targeting the
  absolute lowest HP.

### 7. Gear Tier Parity Tooling

The current gear system applies flat multipliers. More nuanced parity tooling:

- **Per-stat multipliers** — separate sliders for health, mana, damage, and
  healing so testers can isolate a single variable.
- **Expected DPS readout** in the Setup tab showing projected damage output for
  the chosen class + gear combination before the duel starts.
- **Auto-balance mode** — given a desired match duration, suggest gear tiers
  for each side using past history data.

### 8. Observer / Replay Mode

Record full frame-by-frame position + ability usage to a structured log and
replay it at adjustable speed in the Active tab, with a scrubber. This would
make it much easier to diagnose *why* a particular class wins or loses.
