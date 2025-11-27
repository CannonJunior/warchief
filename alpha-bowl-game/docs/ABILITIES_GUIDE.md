# Alpha Bowl - Football Abilities & Player Configuration Guide

This document describes all football abilities, their locations, and how to configure players.

## File Locations

| File | Purpose |
|------|---------|
| `lib/game3d/state/abilities_config.dart` | All ability definitions (speed, cooldown, effects) |
| `lib/game3d/state/game_config.dart` | Player parameters (health, size, speed, positions) |
| `lib/game3d/state/game_state.dart` | Runtime state and cooldown tracking |
| `lib/game3d/systems/ability_system.dart` | Ball carrier ability logic |
| `lib/game3d/systems/ai_system.dart` | Defensive and AI ability logic |
| `lib/game3d/systems/combat_system.dart` | Collision detection and tackle mechanics |

---

## Currently Assigned Abilities

### Ball Carrier Abilities (Quarterback/Running Back)
| Slot | Ability | Type | Effect | Cooldown | Description |
|------|---------|------|--------|----------|-------------|
| 1 | Bullet Pass | Pass | Fast, short range | 0.5s | Quick throw, high velocity, 15-yard range |
| 2 | Sprint | Movement | +75% speed | 3.0s | Explosive burst of speed for 2 seconds |
| 3 | Spin Move | Evasion | Break tackle | 2.5s | 360° spin to evade defenders |

---

## Football Abilities Codex

Based on research from [Madden NFL games](https://www.operationsports.com/all-ball-carrier-moves-in-madden-26-how-to-perform-them/) and [football defensive techniques](https://www.viqtorysports.com/pass-rush-moves/), these abilities represent authentic football maneuvers.

### 🏈 Offensive / Ball Carrier Abilities

#### Ball Carrier Movement
| Ability | Type | Effect | Cooldown | Description | Research Source |
|---------|------|--------|----------|-------------|-----------------|
| **Juke** | Evasion | Sharp cut | 1.5s | Quick lateral cut to avoid defender | [Madden 25 Juke Guide](https://www.dexerto.com/madden/how-to-juke-in-madden-25-every-skill-move-and-setup-state-explained-2863098/) |
| **Spin Move** | Evasion | 360° rotation | 2.5s | Full spin to evade tackle attempt | [Madden Rush Moves](https://www.vgr.com/madden-20-running-game-how-to-stiff-arm-hurdle-spin-juke-dive/) |
| **Hurdle** | Evasion | Jump over | 4.0s | Leap over diving/low defender | [Madden Ball Carrier Moves](https://www.madden-school.com/madden-17-ball-carrier-special-moves-details/) |
| **Stiff Arm** | Power | Push defender | 2.0s | Extend arm to push off tackler | [Madden Stiff Arm](https://www.vgr.com/madden-21-rush-moves-hurdle-juke-stiff-arm-jurdle/) |
| **Truck** | Power | Run through | 3.5s | Lower shoulder, break weak tackles | [Madden Superstar Abilities](https://www.thegamer.com/madden-24-best-superstar-abilities-running-backs/) |
| **Dive Forward** | Utility | Lunge | 1.0s | Dive for extra 2 yards, vulnerable to fumble | Standard football technique |
| **Slide** | Protection | Safe down | 5.0s | QB slide, avoid contact, end play | Standard QB technique |

#### Passing Abilities
| Ability | Type | Range | Cooldown | Description |
|---------|------|-------|----------|-------------|
| **Bullet Pass** | Pass | 15 yards | 0.5s | Fast, low trajectory, high velocity |
| **Touch Pass** | Pass | 25 yards | 0.8s | Medium velocity, arc trajectory |
| **Lob Pass** | Pass | 40 yards | 1.2s | High arc, deep throw, slower velocity |
| **Rocket Throw** | Pass | 50 yards | 2.5s | Maximum power deep ball |
| **Shovel Pass** | Pass | 5 yards | 0.3s | Underhand toss to nearby receiver |

#### Blocking Abilities (Offensive Line)
| Ability | Type | Effect | Cooldown | Description |
|---------|------|--------|----------|-------------|
| **Pass Block** | Defensive | Hold position | - | Standard pass protection stance |
| **Run Block** | Offensive | Push forward | - | Drive block for running lanes |
| **Pancake Block** | Power | Knockdown | 5.0s | Explosive block, flatten defender |
| **Pull Block** | Movement | Sprint to gap | 3.0s | OL pulls to lead block on run |
| **Chip Block** | Quick | Delay rusher | 2.0s | Quick contact then release to route |

---

### 🛡️ Defensive Abilities

#### Pass Rush Moves (Defensive Line)
| Ability | Type | Effect | Cooldown | Description | Research Source |
|---------|------|--------|----------|-------------|-----------------|
| **Bull Rush** | Power | Drive forward | 2.5s | Use power to push blocker backward | [Pass Rush Moves](https://www.viqtorysports.com/pass-rush-moves/) |
| **Speed Rush** | Speed | Sprint outside | 2.0s | Use speed to beat tackle around edge | [DL Pass Rush](http://breakdownsports.blogspot.com/2015/07/lets-speak-technique-defensive-line-pass-rush-moves-football.html) |
| **Swim Move** | Finesse | Swim over | 3.0s | Swim arm over blocker's shoulder | [Madden Pass Rush](https://www.aoeah.com/news/430--madden-21-defensive-tips--how--when-to-use-each-pass-rush-move-to-dominate-your-opponent) |
| **Rip Move** | Finesse | Uppercut under | 2.5s | Rip arm under blocker's arm | [Rip Technique Guide](https://blog.kokasports.com/what-is-a-rip-move-in-football/) |
| **Club Move** | Power | Knock away | 3.0s | Club blocker's hands down | [Pass Rush Handbook](https://dlineexamples.substack.com/p/pass-rush-moves-handbook) |
| **Spin Move** | Finesse | 360° rotation | 4.0s | Spin away from blocker | [DL Techniques](https://www.shakinthesouthland.com/2011/2/28/2003172/defensive-line-pass-rush-techniques) |

#### Defensive Coverage
| Ability | Type | Effect | Cooldown | Description |
|---------|------|--------|----------|-------------|
| **Press Coverage** | Defensive | Jam receiver | - | Physical contact at line of scrimmage |
| **Zone Drop** | Defensive | Cover area | - | Drop to assigned zone coverage |
| **Man Coverage** | Defensive | Shadow receiver | - | Follow assigned receiver |
| **Ball Hawk** | Interception | Jump route | 8.0s | Break on ball for INT attempt |
| **Strip Ball** | Forced Fumble | Punch ball | 5.0s | Punch at ball to cause fumble |

#### Tackling
| Ability | Type | Effect | Cooldown | Description |
|---------|------|--------|----------|-------------|
| **Wrap Tackle** | Tackle | Secure | 1.0s | Fundamental wrap-up tackle |
| **Dive Tackle** | Tackle | Dive at legs | 1.5s | Desperation diving tackle |
| **Hit Stick** | Tackle | Big hit | 4.0s | Devastating contact, risk/reward |
| **Block Shed** | Disengage | Break block | 2.0s | Shed blocker to make play |

---

### ⭐ Special Teams Abilities

#### Kicking
| Ability | Type | Range | Cooldown | Description |
|---------|------|-------|----------|-------------|
| **Field Goal** | Kick | 50 yards | 1.0s | Standard field goal attempt |
| **Extra Point** | Kick | 15 yards | 0.5s | Point after touchdown |
| **Kickoff** | Kick | 65 yards | 1.0s | Standard kickoff |
| **Deep Kick** | Kick | 75 yards | 1.5s | Maximum distance kickoff |
| **Squib Kick** | Kick | 40 yards | 1.0s | Low, bouncing kick, hard to return |
| **Onside Kick** | Kick | 15 yards | 2.0s | Short kick, attempt to recover |
| **Punt** | Kick | 45 yards | 1.0s | Standard punt |
| **Coffin Corner** | Kick | 50 yards | 2.0s | Punt near sideline, pin deep |

#### Kick Return
| Ability | Type | Effect | Cooldown | Description |
|---------|------|--------|----------|-------------|
| **Fair Catch** | Safety | No return | 0.5s | Signal fair catch, no contact allowed |
| **Punt Return** | Return | Field position | - | Attempt to return punt |
| **Kick Return** | Return | Field position | - | Attempt to return kickoff |

---

### 🏃 Universal Abilities (All Players)

| Ability | Type | Effect | Cooldown | Description |
|---------|------|--------|----------|-------------|
| **Sprint** | Movement | +75% speed | 3.0s | Burst of speed for 2 seconds |
| **Turbo** | Movement | +50% speed | 5.0s | Sustained speed boost for 4 seconds |
| **Change Direction** | Movement | Quick cut | 0.5s | Sharp directional change |
| **Celebrate** | Taunt | Animation | 10.0s | Touchdown celebration (risk fumble!) |
| **Audible** | Strategy | Change play | 8.0s | QB calls new play at line |
| **Timeout** | Strategy | Stop clock | - | Call timeout (limited per half) |

---

## Ability Types

| Type | Description |
|------|-------------|
| `pass` | Throwing the football |
| `evasion` | Avoid tackles and defenders |
| `power` | Physical, strength-based moves |
| `tackle` | Defensive takedown maneuvers |
| `pass_rush` | Defensive line pressure techniques |
| `kick` | Special teams kicking |
| `movement` | Speed and agility abilities |
| `protection` | Blocking and ball security |

---

## Player Positions & Suggested Abilities

### Offense

#### **Quarterback (QB)**
- Slot 1: Bullet Pass / Touch Pass / Lob Pass
- Slot 2: Sprint
- Slot 3: Slide (protection)

#### **Running Back (RB)**
- Slot 1: Juke / Spin Move
- Slot 2: Sprint / Turbo
- Slot 3: Stiff Arm / Truck

#### **Wide Receiver (WR)**
- Slot 1: Sprint
- Slot 2: Juke
- Slot 3: Spin Move

#### **Offensive Line (OL)**
- Slot 1: Pass Block / Run Block
- Slot 2: Pancake Block
- Slot 3: Pull Block

### Defense

#### **Defensive Line (DL)**
- Slot 1: Bull Rush / Speed Rush
- Slot 2: Swim Move / Rip Move
- Slot 3: Block Shed

#### **Linebacker (LB)**
- Slot 1: Wrap Tackle
- Slot 2: Sprint
- Slot 3: Strip Ball

#### **Defensive Back (DB)**
- Slot 1: Press Coverage / Zone Drop
- Slot 2: Ball Hawk
- Slot 3: Hit Stick

### Special Teams

#### **Kicker (K)**
- Slot 1: Field Goal
- Slot 2: Kickoff
- Slot 3: Deep Kick / Squib Kick

#### **Punter (P)**
- Slot 1: Punt
- Slot 2: Coffin Corner
- Slot 3: -

---

## How to Assign Abilities to Players

### Step 1: Define the Ability
All abilities are defined in `lib/game3d/state/abilities_config.dart`. Reference them from `AbilitiesConfig`:

```dart
// Access a football ability
final myAbility = AbilitiesConfig.bulletPass;
final evasive = AbilitiesConfig.spinMove;
final defensive = AbilitiesConfig.bullRush;
```

### Step 2: Update Player Ability References

#### For Ball Carrier Abilities
Edit `lib/game3d/systems/ability_system.dart`:

```dart
// In handleAbility1Input() for passing:
static void handleAbility1Input(bool ability1KeyPressed, GameState gameState) {
  if (ability1KeyPressed && gameState.ability1Cooldown <= 0) {
    final ability = AbilitiesConfig.bulletPass; // Throw ability
    // ... create pass trajectory with ability.velocity, ability.range, etc.
  }
}

// In handleAbility2Input() for sprint:
static void handleAbility2Input(bool ability2KeyPressed, GameState gameState) {
  if (ability2KeyPressed && gameState.ability2Cooldown <= 0) {
    final ability = AbilitiesConfig.sprint;
    gameState.playerSpeed *= 1.75; // 75% speed boost
    // ... start sprint timer
  }
}

// In handleAbility3Input() for spin:
static void handleAbility3Input(bool ability3KeyPressed, GameState gameState) {
  if (ability3KeyPressed && gameState.ability3Cooldown <= 0) {
    final ability = AbilitiesConfig.spinMove;
    // ... trigger spin animation and evasion logic
  }
}
```

#### For Defensive Players
Edit `lib/game3d/systems/ai_system.dart`:

```dart
// In updateDefensivePlayer():
final ability = AbilitiesConfig.bullRush; // Change to defensive move
```

### Step 3: Update Cooldowns in GameState
Update `lib/game3d/state/game_state.dart` to track football ability cooldowns:

```dart
// Ball carrier abilities
double ability1Cooldown = 0.0; // Throw
double ability2Cooldown = 0.0; // Sprint
double ability3Cooldown = 0.0; // Spin/Evasion

// Update max cooldowns from config
double ability1CooldownMax = AbilitiesConfig.bulletPass.cooldown;
double ability2CooldownMax = AbilitiesConfig.sprint.cooldown;
double ability3CooldownMax = AbilitiesConfig.spinMove.cooldown;
```

---

## Player Configuration Parameters

Player parameters (non-ability) are defined in `lib/game3d/state/game_config.dart`:

### Ball Carrier Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `ballCarrierSpeed` | 5.0 | Base movement speed |
| `ballCarrierSprintSpeed` | 8.75 | Speed during sprint (+75%) |
| `ballCarrierAgility` | 180.0 | Turn speed (deg/s) |
| `ballCarrierSize` | 0.5 | Mesh size |

### Defensive Player Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `defenderSpeed` | 5.5 | Base movement speed |
| `defenderPowerRating` | 85.0 | Bull rush effectiveness |
| `defenderFinesseRating` | 75.0 | Swim/rip effectiveness |
| `defenderSize` | 0.6 | Mesh size |

### Football Physics
| Parameter | Default | Description |
|-----------|---------|-------------|
| `footballWeight` | 0.9 | Ball physics weight |
| `passVelocity` | 15.0 | Standard pass speed |
| `passArc` | 0.5 | Pass trajectory curve |
| `fumbleChance` | 0.05 | Base fumble probability |

---

## Creating New Football Abilities

To create a new football ability:

1. **Research the real move** - Study actual football techniques
2. **Define ability** in `abilities_config.dart` with appropriate values
3. **Add parameters** to `game_config.dart` if needed
4. **Add state tracking** to `game_state.dart` for cooldowns
5. **Implement logic** in appropriate system file
6. **Add to this codex** under the correct category

---

## Football Mechanics Design

The ability system is based on authentic football techniques researched from:

### Offensive Techniques
- **[Madden NFL Ball Carrier Moves](https://www.operationsports.com/all-ball-carrier-moves-in-madden-26-how-to-perform-them/)** - Juke, spin, hurdle, stiff-arm
- **[Madden Rush Guide](https://www.vgr.com/madden-20-running-game-how-to-stiff-arm-hurdle-spin-juke-dive/)** - Detailed move mechanics
- **[Madden Superstar Abilities](https://www.thegamer.com/madden-24-best-superstar-abilities-running-backs/)** - Elite player moves

### Defensive Techniques
- **[Pass Rush Moves Explained](https://www.viqtorysports.com/pass-rush-moves/)** - Bull rush, swim, rip techniques
- **[DL Pass Rush Techniques](http://breakdownsports.blogspot.com/2015/07/lets-speak-technique-defensive-line-pass-rush-moves-football.html)** - Detailed defensive line moves
- **[Madden Defensive Tips](https://www.aoeah.com/news/430--madden-21-defensive-tips--how--when-to-use-each-pass-rush-move-to-dominate-your-opponent)** - When to use each move
- **[Pass Rush Handbook](https://dlineexamples.substack.com/p/pass-rush-moves-handbook)** - Comprehensive guide

### Core Design Principles
- **Position-Specific Abilities**: QB, RB, WR, OL, DL, LB, DB, K/P each have unique movesets
- **Evasion vs Power**: Ball carriers choose finesse (juke/spin) or power (truck/stiff-arm)
- **Pass Rush Variety**: Defensive linemen have finesse (swim/rip) and power (bull/club) options
- **Risk/Reward**: High-impact moves (hurdle, hit stick) have longer cooldowns
- **Authentic Football**: All abilities based on real NFL techniques and video game implementations

---

## Sources

- [Madden 26 Ball Carrier Moves Guide - Operation Sports](https://www.operationsports.com/all-ball-carrier-moves-in-madden-26-how-to-perform-them/)
- [Madden 20 Running Game Guide - VGR](https://www.vgr.com/madden-20-running-game-how-to-stiff-arm-hurdle-spin-juke-dive/)
- [Madden 24 Best Running Back Abilities - TheGamer](https://www.thegamer.com/madden-24-best-superstar-abilities-running-backs/)
- [Defensive Pass Rush Moves Explained - vIQtory Sports](https://www.viqtorysports.com/pass-rush-moves/)
- [DL Pass Rush Moves - Breakdown Sports](http://breakdownsports.blogspot.com/2015/07/lets-speak-technique-defensive-line-pass-rush-moves-football.html)
- [Madden 21 Defensive Tips - AOEAH](https://www.aoeah.com/news/430--madden-21-defensive-tips--how--when-to-use-each-pass-rush-move-to-dominate-your-opponent)
- [Pass Rush Moves Handbook - D-Line Examples](https://dlineexamples.substack.com/p/pass-rush-moves-handbook)
- [Rip Move Technique Guide - Koka Sports](https://blog.kokasports.com/what-is-a-rip-move-in-football/)
