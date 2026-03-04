# Warchief Game - Abilities & Unit Configuration Guide

This document describes all game abilities, their locations, and how to configure game units.

## File Locations

| File | Purpose |
|------|---------|
| `lib/game3d/state/abilities_config.dart` | All ability definitions (damage, cooldown, colors, effects) |
| `lib/game3d/state/game_config.dart` | Unit parameters (health, size, speed, positions) |
| `lib/game3d/state/game_state.dart` | Runtime state and cooldown tracking |
| `lib/game3d/systems/ability_system.dart` | Player ability logic |
| `lib/game3d/systems/ai_system.dart` | Monster and ally ability logic |
| `lib/game3d/systems/combat_system.dart` | Damage calculations and collision detection |

---

## Currently Assigned Abilities

### Player Abilities
| Slot | Ability | Type | Damage | Cooldown | Description |
|------|---------|------|--------|----------|-------------|
| 1 | Sword | Melee | 25 | 1.5s | Swift melee attack |
| 2 | Fireball | Ranged | 20 | 3.0s | Blazing projectile |
| 3 | Heal | Heal | - | 10.0s | Restores 20 HP |

### Monster Abilities
| Slot | Ability | Type | Damage | Cooldown | Description |
|------|---------|------|--------|----------|-------------|
| 1 | Dark Strike | Melee | 15 | 2.0s | Giant shadow sword attack |
| 2 | Shadow Bolt | Ranged | 12 | 4.0s | Dark energy projectile |
| 3 | Dark Heal | Heal | - | 8.0s | Restores 25 HP |

### Ally Abilities
| Slot | Ability | Type | Damage | Cooldown | Description |
|------|---------|------|--------|----------|-------------|
| 1 | Ally Sword | Melee | 10 | 5.0s | Ally melee attack |
| 2 | Ally Fireball | Ranged | 15 | 5.0s | Ally projectile |
| 3 | Ally Heal | Heal | - | 5.0s | Restores 15 HP |

---

## Potential Future Abilities (Unassigned)

These abilities are defined in `abilities_config.dart` and ready for use with future units.

### Warrior Category
| Ability | Type | Damage | Cooldown | Special Effects |
|---------|------|--------|----------|-----------------|
| Shield Bash | Melee | 10 | 6.0s | Stun 1.5s |
| Whirlwind | AoE | 18 | 8.0s | Hits 5 targets, 3.0 radius |
| Charge | Melee | 15 | 10.0s | Knockback 5.0 force |
| Taunt | Debuff | - | 12.0s | Forces enemies to target you |
| Fortify | Buff | - | 15.0s | Shield absorbs 50 damage |

### Mage Category
| Ability | Type | Damage | Cooldown | Special Effects |
|---------|------|--------|----------|-----------------|
| Frost Bolt | Ranged | 15 | 2.5s | Slow 50% for 3s |
| Blizzard | Channeled | 8/tick | 20.0s | AoE slow, 8 ticks over 4s |
| Lightning Bolt | Ranged | 30 | 4.0s | 1.5s cast time |
| Chain Lightning | Ranged | 20 | 8.0s | Bounces to 4 targets |
| Meteor | AoE | 50 | 30.0s | Burn DoT, 4.0 radius, 2s cast |
| Arcane Shield | Buff | - | 25.0s | Absorbs 40 damage for 8s |
| Teleport | Utility | - | 15.0s | Instant blink 10 units |

### Rogue Category
| Ability | Type | Damage | Cooldown | Special Effects |
|---------|------|--------|----------|-----------------|
| Backstab | Melee | 40 | 6.0s | High damage from behind |
| Poison Blade | Melee | 12 | 8.0s | Poison DoT 6s, 6 ticks |
| Smoke Bomb | Debuff | - | 18.0s | AoE blind 3s, 4.0 radius |
| Fan of Knives | AoE | 15 | 10.0s | Hits 8 targets, 6.0 radius |
| Shadow Step | Utility | - | 20.0s | Teleport behind target |

### Healer Category
| Ability | Type | Heal | Cooldown | Special Effects |
|---------|------|------|----------|-----------------|
| Holy Light | Heal | 35 | 4.0s | 1.5s cast time |
| Rejuvenation | Heal | 40 | 6.0s | HoT over 8s, 8 ticks |
| Circle of Healing | Heal | 20 | 15.0s | AoE heal, 8.0 radius, 5 targets |
| Blessing of Strength | Buff | - | 20.0s | +25% damage for 15s |
| Purify | Buff | - | 8.0s | Removes debuffs |

### Nature Category
| Ability | Type | Damage | Cooldown | Special Effects |
|---------|------|--------|----------|-----------------|
| Entangling Roots | Debuff | 5 | 12.0s | Root 4s |
| Thorns | Buff | 5/hit | 30.0s | Reflect damage 20s |
| Nature's Wrath | AoE | 25 | 14.0s | 5.0 radius |

### Necromancer Category
| Ability | Type | Damage | Cooldown | Special Effects |
|---------|------|--------|----------|-----------------|
| Life Drain | Channeled | 6/tick | 10.0s | Heals 4/tick over 3s |
| Curse of Weakness | Debuff | - | 16.0s | -25% enemy damage for 10s |
| Fear | Debuff | - | 20.0s | Target flees 4s |
| Summon Skeleton | Summon | - | 25.0s | Creates ally for 30s |

### Elemental Category
| Ability | Type | Damage | Cooldown | Special Effects |
|---------|------|--------|----------|-----------------|
| Ice Lance | Ranged | 18 | 3.0s | Pierces through 3 targets |
| Flame Wave | AoE | 22 | 7.0s | Line AoE, burn 2s |
| Earthquake | Channeled | 10/tick | 25.0s | AoE stun 0.5s, 8.0 radius |

### Utility Category
| Ability | Type | Cooldown | Special Effects |
|---------|------|----------|-----------------|
| Sprint | Buff | 30.0s | +50% speed for 8s |
| Battle Shout | Buff | 45.0s | AoE +15% damage, 10.0 radius |

---

## Ability Types

| Type | Description |
|------|-------------|
| `melee` | Close-range physical attacks |
| `ranged` | Projectile-based attacks |
| `heal` | Health restoration |
| `buff` | Positive effects on self/allies |
| `debuff` | Negative effects on enemies |
| `aoe` | Area of effect damage |
| `dot` | Damage over time |
| `channeled` | Requires standing still to cast |
| `summon` | Creates temporary units |
| `utility` | Non-combat abilities (movement, vision) |

## Status Effects

| Effect | Description |
|--------|-------------|
| `burn` | Fire damage over time |
| `freeze` | Movement slow/stop |
| `poison` | Nature damage over time |
| `stun` | Cannot act |
| `slow` | Reduced movement speed |
| `bleed` | Physical damage over time |
| `blind` | Reduced accuracy/vision |
| `root` | Cannot move but can act |
| `silence` | Cannot use abilities |
| `haste` | Increased movement/attack speed |
| `shield` | Damage absorption |
| `regen` | Health over time |
| `strength` | Increased damage |
| `weakness` | Reduced damage output |

---

## How to Assign Abilities to Units

### Step 1: Define the Ability
All abilities are defined in `lib/game3d/state/abilities_config.dart`. To use an existing potential ability, reference it from `AbilitiesConfig`:

```dart
// Access a potential ability
final myAbility = AbilitiesConfig.frostBolt;
```

### Step 2: Update Unit Ability References

#### For Player Abilities
Edit `lib/game3d/systems/ability_system.dart`:

```dart
// In handleAbility2Input() for example:
static void handleAbility2Input(bool ability2KeyPressed, GameState gameState) {
  if (ability2KeyPressed && gameState.ability2Cooldown <= 0) {
    final ability = AbilitiesConfig.frostBolt; // Change ability here
    // ... create projectile with ability.projectileSpeed, ability.damage, etc.
  }
}
```

#### For Monster Abilities
Edit `lib/game3d/systems/ai_system.dart`:

```dart
// In updateMonsterSword() or similar:
final ability = AbilitiesConfig.monsterDarkStrike; // Change to new ability
```

#### For Ally Abilities
Edit `lib/game3d/systems/ai_system.dart`:

```dart
// In executeAllyDecision():
final ability = AbilitiesConfig.getAllyAbility(abilityIndex);
// Or reference directly:
final ability = AbilitiesConfig.frostBolt;
```

### Step 3: Update Cooldowns in GameState
If needed, update `lib/game3d/state/game_state.dart` to track new cooldowns:

```dart
double newAbilityCooldown = 0.0;
double newAbilityCooldownMax = AbilitiesConfig.frostBolt.cooldown;
```

---

## Unit Configuration Parameters

Unit parameters (non-ability) are defined in `lib/game3d/state/game_config.dart`:

### Player Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `playerSpeed` | 5.0 | Movement speed |
| `playerRotationSpeed` | 180.0 | Turn speed (deg/s) |
| `playerSize` | 0.5 | Mesh size |
| `playerStartPosition` | (10, 0.5, 2) | Spawn location |

### Monster Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `monsterMaxHealth` | 100.0 | Maximum HP |
| `monsterSize` | 1.2 | Mesh size |
| `monsterStartPosition` | (18, 0.6, 18) | Spawn location |
| `monsterAiInterval` | 2.0 | AI decision rate (s) |
| `monsterHealThreshold` | 50.0 | HP% to trigger heal |

### Ally Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `allyMaxHealth` | 50.0 | Maximum HP |
| `allySize` | 0.8 | Mesh size |
| `allyAiInterval` | 3.0 | AI decision rate (s) |
| `allyAbilityCooldownMax` | 5.0 | Default cooldown |

---

## Creating New Unit Types

To create a new unit type with custom abilities:

1. **Define abilities** in `abilities_config.dart` (or use existing potential abilities)
2. **Add unit parameters** to `game_config.dart` (health, size, position, etc.)
3. **Add state tracking** to `game_state.dart` (mesh, transform, cooldowns)
4. **Initialize the unit** in `game3d_widget.dart`
5. **Add AI behavior** in `ai_system.dart` (decision making, ability usage)
6. **Add rendering** in `render_system.dart`

---

## Research Sources

The ability system design was informed by research on third-person RPGs including:
- **World of Warcraft**: Tab-target combat, class roles (tank/healer/DPS), buff/debuff system
- **Dark Souls**: Slower-paced deliberate combat, stamina management
- **Diablo**: Fire/Ice/Lightning elemental system, DoT mechanics
- **Dragon's Dogma**: Class-based abilities with customizable builds

### Core Design Principles
- **Trinity System**: Tank, Healer, DPS roles
- **Elemental Damage**: Fire (burn), Ice (slow), Lightning (stun), Poison (DoT)
- **Status Effects**: Buffs enhance allies, debuffs hinder enemies
- **Ability Categories**: Melee, Ranged, AoE, Channeled, Utility
