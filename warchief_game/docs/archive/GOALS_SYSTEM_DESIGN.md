# Goals System Design

## Design Philosophy

The Warchief goals system is **deliberately anti-grind and anti-loot-box**. Instead of XP bars, daily login rewards, or random loot, goals emerge organically from the world and characters.

**Self-Determination Theory (SDT):**
- **Autonomy**: Player chooses which goals to pursue; no forced progression gates
- **Competence**: Goals track mastery of actual skills (combat, exploration, building) not arbitrary numbers
- **Relatedness**: Goals connect the player to world characters through narrative

**Research inspirations**: Hades (narrative cycles), Outer Wilds (knowledge-as-progression), Disco Elysium (internal voices as advisors), RimWorld (storyteller AI pacing), Kingdom Come (use-based skill growth), Monster Hunter (skill-gated challenges, not gear checks), Deep Rock Galactic (team play rewards)

## Goal Taxonomy

### Categories
| Category | Color | Description |
|----------|-------|-------------|
| `combat` | Red (0.9, 0.3, 0.3) | Fighting-related goals |
| `exploration` | Blue (0.3, 0.7, 0.9) | Discovering places/things |
| `mastery` | Gold (0.9, 0.7, 0.2) | Skill improvement |
| `community` | Green (0.4, 0.8, 0.4) | Building/ally/village related |
| `spirit` | Purple (0.7, 0.4, 0.9) | Warrior Spirit philosophical goals |

### Sources
- **warriorSpirit** — Internal advisor (Ollama-powered)
- **villageChief** — Named NPC leaders
- **villager** — Common folk requests
- **adversary** — Enemy taunts/challenges
- **selfDiscovery** — Player actions trigger awareness

### Tracking Types
- **counter** — "Defeat 5 gnolls" -> count kills
- **threshold** — "Reach 50 white mana" -> check max
- **discovery** — "Find the ley line nexus" -> visit location
- **mastery** — "Land 10 consecutive sword strikes" -> streak tracking
- **narrative** — "Speak with the Warrior Spirit about courage" -> flag

## Goal State Machine

```
available -> accepted -> active -> completed -> reflected
                                        |
                                        v
                                    abandoned
```

- **available**: Offered but not accepted (pending suggestion)
- **active**: Player accepted, tracking progress
- **completed**: Conditions met, awaiting reflection
- **reflected**: Player discussed with Warrior Spirit (optional)
- **abandoned**: Player chose to drop it

## Warrior Spirit Architecture

**Hybrid deterministic + LLM approach:**
- All goal tracking and completion logic is **deterministic** (no LLM in the loop)
- LLM only handles narrative: suggestions, reflections, free-form chat
- If Ollama is unavailable, static fallback text is used (no crashes)

### LLM touchpoints:
1. Narrative framing of goal suggestions
2. Reflective dialogue on goal completion
3. Free-form advice when the player asks

### Periodic check:
- Every `goalCheckInterval` seconds (default 120), the system checks if new goals should be suggested
- Deterministic selection based on game state (enemies present -> combat goals, etc.)
- LLM narrates the suggestion if available

## Data Flow

```
goals_config.json
    |
    v
GoalsConfig (global singleton) --> GoalDefinition (parsed from JSON)
    |
    v
GoalSystem.processEvent(gameState, eventId, metadata)
    |
    v
Goal instances in GameState.goals[]
    |
    v
GoalsPanel (G key) / WarriorSpiritPanel (V key)
```

### Event emission points:
- `combat_system.dart` -> `enemy_killed`, `kill_<type>`, `boss_killed`
- `game_state.dart` -> `building_upgraded`
- `game3d_widget.dart` -> `ally_command_issued`, `flight_duration`

## Integration Points

| System | Integration |
|--------|------------|
| CombatSystem | Emits `enemy_killed`, `kill_gnoll_marauder` etc. on kills |
| GameState | Tracks `consecutiveMeleeHits`, `visitedPowerNodes` |
| Game3DWidget | G/V key handlers, game loop Warrior Spirit update |
| OllamaClient | Used by WarriorSpirit for narrative generation |

## Config-Driven Design

All goal definitions live in `assets/data/goals_config.json`. Nothing is hardcoded in Dart — new goals are added by editing JSON only. The `GoalsConfig` class follows the same pattern as `ManaConfig` and `BuildingConfig`.

## Future Expansion (Phase 2+)

- Village NPCs offering location-specific goals
- Adversary system: defeated enemies taunt back via LLM
- Faction reputation tracked per NPC group
- Goal chains: completing one unlocks related follow-ups
- Seasonal/weather-triggered goals (derecho challenges)
- Warrior Spirit personality evolves based on player choices
