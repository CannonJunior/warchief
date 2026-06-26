# Quests & Progression System Summary

## Overview

Warchief uses a **Goals System** instead of traditional quests/XP. The design is explicitly anti-grind and anti-loot-box, inspired by Self-Determination Theory (SDT). There is **no XP, no leveling, no experience points** — progression is narrative and skill-based.

---

## What Exists

### Goals System (Fully Implemented)

The goals system is the primary quest-like feature. It is config-driven, deterministic, and integrated with an LLM-powered narrative advisor.

#### Core Files

| File | Purpose |
|------|---------|
| `lib/models/goal.dart` | Data models: `Goal`, `GoalDefinition`, enums for source/tracking/status/category |
| `lib/game3d/systems/goal_system.dart` | Event processing, progress tracking, completion detection, goal acceptance |
| `lib/game3d/state/goals_config.dart` | JSON config loader with override support (`GoalsConfig`) |
| `assets/data/goals_config.json` | All goal definitions, Warrior Spirit config, category colors |
| `lib/game3d/ui/goals_panel.dart` | In-game UI panel (toggled with G key) |
| `lib/game3d/ui/warrior_spirit_panel.dart` | Chat panel for LLM-powered Spirit conversations (V key) |
| `lib/game3d/ai/warrior_spirit.dart` | Ollama-powered narrative advisor, goal suggestion logic |
| `docs/archive/GOALS_SYSTEM_DESIGN.md` | Original design document |

#### Goal Categories

| Category | Color | Description |
|----------|-------|-------------|
| `combat` | Red | Fighting-related (e.g., kill enemies) |
| `exploration` | Blue | Discovering places/things (e.g., visit ley nodes) |
| `mastery` | Gold | Skill improvement (e.g., consecutive hit streaks) |
| `community` | Green | Building/ally/village related |
| `spirit` | Purple | Warrior Spirit philosophical goals |

#### Goal Sources

Goals can originate from five sources, each with different narrative framing:
- **warriorSpirit** — Internal advisor (Ollama-powered)
- **villageChief** — Named NPC leaders
- **villager** — Common folk requests
- **adversary** — Enemy taunts/challenges
- **selfDiscovery** — Player actions trigger awareness

#### Tracking Types

| Type | Example | Mechanic |
|------|---------|----------|
| `counter` | "Defeat 5 gnolls" | Increment on each event |
| `threshold` | "Reach 50 white mana" | Track high-water mark |
| `discovery` | "Find the ley line nexus" | Visit location flag |
| `mastery` | "10 consecutive sword strikes" | Streak tracking |
| `narrative` | "Survive a derecho" | Boolean flag |

#### Goal Lifecycle

```
available -> accepted -> active -> completed -> reflected
                                       |
                                       v
                                   abandoned
```

#### Defined Goals (8 total in config)

1. **First Blood** — Kill first enemy (combat/counter)
2. **Gnoll Hunter** — Kill 5 Gnoll Marauders (combat/counter)
3. **Wind Walker** — Maintain flight for 30 seconds (mastery/threshold)
4. **Ley Pilgrim** — Visit 3 power nodes (exploration/counter)
5. **Builder's Pride** — Upgrade Longhouse to Tier 2 (community/counter)
6. **Derecho Survivor** — Survive a full derecho (mastery/narrative)
7. **Way of the Blade** — 10 consecutive sword strikes (mastery/mastery)
8. **Commander's Voice** — Issue 20 ally commands (community/counter)

#### Event Emission Points

Goals are progressed via `GoalSystem.processEvent()` calls from:
- **combat_system_enemies.dart** — `enemy_killed`, `boss_killed`, `kill_<type>`, `consecutive_melee_hits`
- **game3d_widget_update.dart** — `flight_duration`, `visit_power_node`
- **game3d_widget.dart** — `ally_command_issued`

### Warrior Spirit (LLM Advisor)

- Ollama-powered NPC that suggests goals narratively
- Periodic check every 120s for new goal suggestions
- Deterministic goal selection (combat if enemies present, mastery if flying, etc.)
- LLM frames suggestions in character; static fallback if Ollama unavailable
- Chat interface via V key; streaming responses via `/api/chat`
- Persistent conversation history (capped at 20 messages)
- Project documentation injected into system prompt via `SpiritKnowledgeBase`

### Item System — Quest Item Type

The `ItemType` enum includes a `quest` variant, used for item categorization in the bag panel. Quest items have no equip slot and are displayed in a distinct category. No quest-item-specific logic exists beyond categorization.

---

## What Does NOT Exist

| Feature | Status |
|---------|--------|
| **XP / Experience Points** | Not implemented, deliberately excluded by design |
| **Player Levels** | No leveling system |
| **NPC Progression / Leveling** | Listed as future TODO in PLATFORM_DESIGN.md |
| **Quest Chains** | Listed as future expansion in goals design doc |
| **Faction Reputation** | Listed as future expansion |
| **Reward System** | Goals have a `rewards` map in config but it's narrative-only (no mechanical rewards are granted on completion) |
| **Quest Log / Journal** | Goals panel serves this role |
| **Quest Givers** | Warrior Spirit suggests goals; no interactive NPC quest givers |
| **Daily/Weekly Quests** | Deliberately excluded by design philosophy |
| **Skill Trees / Progression Gates** | Not present |

---

## Design Philosophy (from GOALS_SYSTEM_DESIGN.md)

> The Warchief goals system is deliberately anti-grind and anti-loot-box. Instead of XP bars, daily login rewards, or random loot, goals emerge organically from the world and characters.

Inspirations: Hades (narrative cycles), Outer Wilds (knowledge-as-progression), Disco Elysium (internal voices), Kingdom Come (use-based skill growth), Monster Hunter (skill-gated challenges).

---

## Future Expansion (Documented but Unbuilt)

From the goals design doc and PLATFORM_DESIGN.md:
- Village NPCs offering location-specific goals
- Adversary system: defeated enemies taunt back via LLM
- Faction reputation tracked per NPC group
- Goal chains: completing one unlocks related follow-ups
- Seasonal/weather-triggered goals (derecho challenges)
- Warrior Spirit personality evolves based on player choices
- NPC progression (leveling, new abilities)
- Quest/objective system (separate from goals — mentioned in PLATFORM_DESIGN.md TODO)
