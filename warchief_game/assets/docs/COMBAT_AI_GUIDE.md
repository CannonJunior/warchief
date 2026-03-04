# Combat AI Guide

How AI-controlled units make decisions in Warchief — covering ally field AI, duel AI, and the
optional Ollama LLM strategy advisor.

---

## 1. Architecture Overview

Warchief has two separate AI stacks that operate independently:

| Stack | Used For | Entry Point |
|-------|----------|-------------|
| **Ally Behavior Tree** | Allies following and fighting alongside the player in the main world | `ally_behavior_tree.dart` |
| **Duel System AI** | Automated combatants in the Duel Arena (`U` key) | `duel_system.dart` + `duel_ai_helpers.dart` |

Both stacks run every frame inside `game3d_widget_update.dart` via the game loop.

---

## 2. Ally Behavior Tree (Field AI)

### 2.1 File Layout

```
lib/game3d/ai/
├── ally_behavior_tree.dart          — Node types, AllyBehaviorContext, factory, evaluator
├── ally_behavior_tree_branches.dart — Branch builders (_AllyBranches)
├── ally_behavior_tree_actions.dart  — Action implementations (_AllyActions)
├── ally_strategy.dart               — AllyStrategy: per-unit numeric parameters
└── tactical_positioning.dart        — Formation logic, CombatRole detection
```

### 2.2 Node Types

| Type | Behaviour |
|------|-----------|
| `Selector` | Tries children in order; returns on first success or `running`. |
| `Sequence` | Runs all children; stops and returns `failure` if any child fails. |
| `Condition` | Returns `success`/`failure` based on a boolean lambda. |
| `Action` | Executes a lambda and returns its `NodeStatus`. |

### 2.3 Priority Tree

```
AllyRootSelector
├── Priority 0 — PlayerCommand (follow / attack / hold / defensive)
├── Priority 1 — SelfPreservation (heal when HP < strategy.healThreshold)
├── Priority 1.5 — KiteFromMonster (ranged only; retreat when monster is too close)
├── Priority 2 — Combat
│   ├── MeleeAttackBranch  (abilityIndex == 0)
│   ├── RangedAttackBranch (abilityIndex == 1)
│   └── SupportBranch      (abilityIndex == 2)
└── Priority 3 — FollowPlayer (default idle behaviour)
```

Higher-priority branches preempt lower ones each frame.

### 2.4 Kite Branch (Priority 1.5)

Introduced to give ranged allies WoW-arena-style back-pedal behaviour:

- **Condition**: `abilityIndex == 1` (ranged) AND `distanceToMonster < strategy.preferredRange * 0.55`
- **Action**: `executeKiteFromMonster` — creates a `BezierPath.interception` moving the ally
  directly away from the monster to `currentPosition + awayDirection * (preferredRange + 1.0)`.
- Runs at Priority 1.5 so the ally retreats _before_ attempting an attack on the same frame.

### 2.5 AllyStrategy Parameters

Each ally carries an `AllyStrategy` object that tunes every decision in the tree:

| Field | Effect |
|-------|--------|
| `preferredRange` | Target engagement distance (melee: 2–3 units; ranged: 5–10 units) |
| `followDistance` | How far behind the player the ally idles |
| `healThreshold` | HP fraction at which self-preservation fires |
| `retreatThreshold` | HP fraction at which the ally refuses to engage |
| `defenseWeight` | 0–1; gates whether a strategy is "willing" to heal |
| `chaseEnemy` | If false the ally never approaches the monster |
| `allowMeleeIfRanged` | Allows a ranged ally to fire point-blank |
| `engageDistance` | Max distance from which ranged allies will fire |

### 2.6 Tactical Positioning

`tactical_positioning.dart` assigns each ally a `TacticalPosition` based on the `CombatRole`
detected from its abilities:

| Role | Formation Slot |
|------|----------------|
| `melee` | Front arc around monster, close range |
| `ranged` | Flanks at strategy.engageDistance |
| `support` | Behind the player, max follow distance |

The `MoveToTacticalPos` action (Priority 2, approach branch) routes allies to their formation
slot using `BezierPath.interception` rather than a straight line.

---

## 3. Duel System AI

### 3.1 File Layout

```
lib/game3d/systems/
├── duel_system.dart          — Per-frame orchestration, movement, ability use, Ollama advisor
└── duel_ai_helpers.dart      — Pure helper functions (top-level, part of duel_system.dart)

lib/game3d/state/
├── duel_manager.dart         — State machine, event log, SharedPreferences persistence
└── duel_config.dart          — JSON-driven tuning (assets/data/duel_config.json)
```

### 3.2 Per-Frame Loop (`DuelSystem.update`)

1. **Terrain snap** — Y position corrected to terrain surface so XZ-only AI movement never drifts.
2. **Mana regen + cooldown tick** — All combatants regenerated at `manaRegenPerSecond` (config).
3. **GCD + combo-window tick** — Global cooldown and combo-primer windows decremented.
4. **Projectile tick** — In-flight duel projectiles advanced; hits applied on contact.
5. **Ollama advisor tick** — Every 3 s fires an async strategy query (challenger side only).
6. **AI loop** — `_runAI` called for each alive combatant on both sides.
7. **Win / draw check** — First-kill or total-annihilation depending on `endCondition`.

### 3.3 Movement AI (`_runAI` movement block)

Inspired by WoW 3v3 arena positioning:

| Situation | Behaviour |
|-----------|-----------|
| `dist > preferred + 0.5` | Close in at full `moveSpeed` |
| Ranged + `dist < preferred * 0.55` | **Kite backwards** at full speed (flee from melee) |
| Defensive melee + `dist < preferred - 1.5` | Back off gently at 50 % speed |
| At preferred range | **Lateral strafe** at 35 % speed (perpendicular to attack axis) |

**Preferred range** comes from `_effectiveRange(abilities, strategy)`:
- Melee / support strategies return the strategy base distance (1.5–7.0 units).
- Ranged strategies use `max(base, maxRangedAbilityRange * 0.80)` so combatants stay just
  inside their longest ability's range.

**Strafing direction** alternates by `combatantIdx % 2` so challengers and enemies strafe
opposing directions, producing realistic arena footwork without coordination logic.

### 3.4 Ability Selection (`_runAI` ability block)

1. Check GCD (skip non-exempt abilities while `combatantGcds[i] > 0`).
2. Check combo window (bypass GCD for follow-up abilities after a primer).
3. **Balanced strategy** — greedy: use the first ready ability in list order.
4. **All other strategies** — priority-scored via `_abilityPriority()`:

| Strategy | Heal score | Damage score |
|----------|-----------|--------------|
| Aggressive | -1 (never), 60 if HP < 20 % | `ability.damage` |
| Berserker | -1 (never) | `ability.damage + 100` |
| Defensive | 120 if HP < 50 %, else 20 | 30 |
| Support | 120 if HP < 75 %, else 50 | 10 |

The highest-scoring ready ability fires; ties broken by list order.

### 3.5 Ollama Strategy Advisor

A lightweight LLM assists the **challenger side** in adjusting its strategy mid-fight.

**How it works:**

1. `_tickOllamaAdvisor` decrements `manager.ollamaAdvisoryTimer` each frame.
2. Every **3 seconds** it calls `_queryOllamaStrategy` as a fire-and-forget `Future`.
3. The prompt sent to the model:
   ```
   Reply one word only: aggressive, defensive, or balanced.
   Blue HP: <pct>%  Red HP: <pct>%  Time: <s>s
   Best strategy for blue side?
   ```
4. The model's first word is parsed; if it matches a known strategy the hint is stored
   in `manager.ollamaStrategyHint`.
5. `_applyOllamaHint()` in `_runAI` maps the hint to the `DuelStrategy` enum and
   overrides the challenger's base strategy for that frame's ability selection and movement.

**Model used**: `qwen2.5:3b` (≈1.8 GB — the smallest local model; responds in under 1 s).

**Fallback**: any network error or unrecognised response is silently discarded and the last
valid hint (or the player-selected base strategy) is retained.

### 3.6 DuelStrategy Profiles

| Strategy | Preferred distance | Heal behaviour | Damage priority |
|----------|--------------------|----------------|-----------------|
| Berserker | 1.5 | Never heals | Absolute maximum |
| Aggressive | 2.5 | Emergency only (<20 % HP) | Highest damage ability |
| Balanced | 2.5 | Handled by greedy ability order | First ready ability |
| Defensive | 6.0 | Aggressively above 50 % HP | Low — any damage ability |
| Support | 7.0 | Very early (above 75 % HP) | Very low |

---

## 4. Configuration

All numeric tuning lives in `assets/data/duel_config.json`:

```json
{
  "duel": {
    "maxDurationSeconds": 120,
    "manaRegenPerSecond": 5.0,
    "gcdSeconds": 1.0,
    "comboWindowSeconds": 3.0,
    "historyMaxEntries": 200
  },
  "arena": {
    "offsetX": 200,
    "offsetZ": 200,
    "separationDistance": 20
  }
}
```

Accessed at runtime via `globalDuelConfig` (type `DuelConfig`). No restart needed after editing
via the Settings panel.

---

## 5. Key Data Flow

```
game3d_widget_update.dart
  └── DuelSystem.update(dt, gameState)
        ├── _tickGcds / _tickProjectiles
        ├── _tickOllamaAdvisor  ──async──>  Ollama :11434  ──>  ollamaStrategyHint
        └── _runAI (per combatant)
              ├── movement:  _effectiveRange + _isRangedCombatant
              ├── strategy:  _applyOllamaHint (challenger only)
              └── abilities: _abilityPriority / _abilityReady / _canAffordMana
                              └── DuelManager.recordEvent  -->  duel_history.json
```

---

## 6. Extending the AI

### Add a new DuelStrategy
1. Add enum value to `DuelStrategy` in `duel_manager.dart`.
2. Add case to `_preferredDistance()` in `duel_ai_helpers.dart`.
3. Add case to `_abilityPriority()` in `duel_ai_helpers.dart`.
4. Add label to `duelStrategyLabels` map.

### Change Ollama model
Edit the `model:` parameter in `_queryOllamaStrategy` in `duel_system.dart`.
Prefer quantized models ≤ 4 B parameters for sub-second response times.

### Tune kite behaviour
- Duel kite threshold: `preferred * 0.55` in `_runAI` movement block.
- Field ally kite threshold: `strategy.preferredRange * 0.55` in `createKiteBranch`.
- Kite overshoot distance: `preferredRange + 1.0` in `executeKiteFromMonster`.
