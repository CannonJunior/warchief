# Warchief Game State & Entity System Reference

## Overview

All game state lives in a single `GameState` class (~1228 lines). Entities (player, monsters, allies, projectiles, effects) follow a consistent pattern: each has a `Mesh` for rendering and a `Transform3d` for positioning. The game loop in `Game3DWidget` calls system methods (physics, AI, combat, render) each frame, passing `GameState` as the shared context.

## Architecture Diagram

```
GameState (game3d/state/game_state.dart)
  ├── Player: playerMesh, playerTransform, playerRotation, playerHealth
  ├── Monster (Boss): monsterMesh, monsterTransform, monsterHealth
  ├── Allies: List<Ally> (models/ally.dart)
  ├── Minions: List<Monster> (models/monster.dart)
  ├── TargetDummy: targetDummy (models/target_dummy.dart)
  ├── Projectiles: fireballs, monsterProjectiles, ally.projectiles
  ├── Effects: impactEffects, damageIndicators, swordMesh, healEffectMesh
  ├── Terrain: infiniteTerrainManager, leyLineManager
  ├── Inventory: playerInventory (models/inventory.dart)
  ├── Mana: blueMana, redMana, whiteMana (+ regen systems)
  ├── Wind: WindState (game3d/state/wind_state.dart)
  ├── Minimap: MinimapState (game3d/state/minimap_state.dart)
  ├── UI State: abilitiesModalOpen, characterPanelOpen, bagPanelOpen, etc.
  └── Game Loop: animationFrameId, lastTimestamp, frameCount

Systems (game3d/systems/)
  ├── RenderSystem.render(renderer, camera, gameState)
  ├── PhysicsSystem — gravity, jumping, flight, terrain collision
  ├── CombatSystem — damage calculation, hit detection
  ├── AbilitySystem — cooldowns, cast bars, windups
  ├── AISystem — monster/minion AI decisions
  ├── InputSystem — keyboard/mouse handling
  └── EntityPickingSystem — click-to-target (screen→world projection)
```

## Entity Pattern

Every renderable entity in the game follows this pattern:

```dart
// Required for rendering
Mesh mesh;              // Geometry + vertex colors
Transform3d transform;  // World position, rotation, scale

// Optional
Mesh? directionIndicator;           // Triangle arrow showing facing
Transform3d? directionIndicatorTransform;
double rotation;                     // Yaw in degrees
double health;
double maxHealth;
```

**To add a new entity type:**
1. Create a model class in `lib/models/` with `Mesh` + `Transform3d` fields
2. Add a list/field to `GameState`
3. Add rendering in `RenderSystem.render()` (draw order matters)
4. Add to terrain height adjustment if placed on ground
5. Add to minimap rendering if it should appear on minimap

## GameState Sections

### Player State

```dart
// Rendering
Mesh? playerMesh;                    // Currently: Mesh.cube(size: 0.5, color: blue)
Transform3d? playerTransform;        // World position
Mesh? directionIndicator;            // Triangle arrow at feet
Mesh? shadowMesh;                    // Shadow blob under player

// Movement
double playerRotation = 180.0;       // Degrees. 180 = facing north (+Z)
double playerSpeed = 5.0;            // Units/second (from GameConfig)

// Health
double playerHealth = 100.0;
double get playerMaxHealth =>        // Base 100 + gear bonuses
    basePlayerMaxHealth + playerInventory.totalEquippedStats.health;
```

**Rotation convention:**
- `rotation.y` in Transform3d uses `rotateY()` which mirrors X vs standard compass
- Rotation 0° = facing south (-Z), 180° = facing north (+Z)
- A key (left) increases rotation, D key (right) decreases rotation
- Forward vector: `(-sin(rot), 0, -cos(rot))`

### Mana System

Three mana types, each with different regeneration mechanics:

| Mana | Regen Source | Decay | Config |
|------|-------------|-------|--------|
| Blue | Proximity to Ley Lines | None (stops regen) | `mana_config.dart` / `mana_config.json` |
| Red | Melee damage dealt + Power Nodes | After 5s grace period | `mana_config.dart` / `mana_config.json` |
| White | Wind exposure | When sheltered (below threshold) | `wind_config.dart` / `wind_config.json` |

```dart
double blueMana = 100.0;
double get maxBlueMana => (config.maxBlueMana) + gear.maxBlueMana;

double redMana = 0.0;  // Starts at 0
double get maxRedMana => (config.maxRedMana) + gear.maxRedMana;

double whiteMana = 0.0; // Starts at 0
double get maxWhiteMana => (config.whiteMaxMana) + gear.maxWhiteMana;
```

**Key methods:**
- `spendBlueMana(amount)`, `hasBlueMana(amount)` — spend/check
- `spendRedMana(amount)`, `hasRedMana(amount)` — spend/check (resets decay timer)
- `spendWhiteMana(amount)`, `hasWhiteMana(amount)` — spend/check
- `generateRedManaFromMelee(damageDealt)` — 20% of damage → red mana
- `updateManaRegen(dt)` — Called each frame, handles blue/red regen from ley lines
- `updateWindAndWhiteMana(dt)` — Called each frame, handles white mana + flight drain

### Monster (Boss) State

Single boss monster managed directly in GameState:

```dart
Mesh? monsterMesh;                    // Mesh.cube(size: 1.2, color: red)
Transform3d? monsterTransform;
double monsterRotation = 180.0;
double monsterHealth = 100.0;         // From GameConfig.monsterMaxHealth
double monsterAbility1Cooldown = 0.0; // Dark Strike (melee)
double monsterAbility2Cooldown = 0.0; // Shadow Bolt (ranged)
double monsterAbility3Cooldown = 0.0; // Dark Healing
bool monsterPaused = false;
List<Projectile> monsterProjectiles = [];
BezierPath? monsterCurrentPath;       // AI pathfinding
String monsterCurrentStrategy = 'BALANCED';
```

### Ally System

```dart
List<Ally> allies = [];
FormationType currentFormation = FormationType.scattered;
```

**Ally model** (`lib/models/ally.dart`, 76 lines):

```dart
class Ally {
  Mesh mesh;                          // Mesh.cube (colored by ability type)
  Transform3d transform;
  double rotation;
  double health = 50.0;
  double maxHealth = 50.0;
  int abilityIndex;                   // 0=Fighter, 1=Mage, 2=Healer
  double abilityCooldown;
  double abilityCooldownMax = 5.0;

  // Movement
  AllyMovementMode movementMode;      // stationary, followPlayer, commanded, tactical
  BezierPath? currentPath;
  double moveSpeed = 2.5;
  double followBufferDistance = 4.0;
  bool isMoving;

  // Commands
  AllyCommand currentCommand;         // none, follow, attack, hold, defensive
  double commandTimer;

  // Strategy
  AllyStrategyType strategyType;      // balanced, aggressive, defensive, support
  AllyStrategy get strategy => AllyStrategies.getStrategy(strategyType);

  List<Projectile> projectiles;
}
```

**Enums:**
- `AllyMovementMode`: stationary, followPlayer, commanded, tactical
- `AllyCommand`: none, follow, attack, hold, defensive
- `AllyStrategyType`: balanced, aggressive, defensive, support

### Minion System

```dart
List<Monster> minions = [];
bool minionsSpawned = false;
```

**Monster model** (`lib/models/monster.dart`, 339 lines):

```dart
class Monster {
  final String instanceId;            // "goblin_rogue_0", "goblin_rogue_1", etc.
  final MonsterDefinition definition; // Type reference (stats, abilities, visual)

  Mesh mesh;                          // Mesh.cube(size: definition.effectiveScale)
  Transform3d transform;
  double rotation;

  double health;                      // From definition.effectiveHealth
  double maxHealth;
  double mana = 100.0;
  List<double> abilityCooldowns;

  // AI
  MonsterAIState aiState;             // idle, patrol, pursuing, attacking, etc.
  String? targetId;
  Vector3? targetPosition;

  // Combat
  bool isInCombat;
  double damageMultiplier = 1.0;      // Buff/debuff modifier
  double damageReduction = 0.0;

  List<Projectile> projectiles;
}
```

**AI States:** `idle`, `patrol`, `pursuing`, `attacking`, `casting`, `fleeing`, `supporting`, `dead`

**MonsterFactory** (`lib/models/monster.dart`):
```dart
MonsterFactory.create(definition: def, position: pos, rotation: rot)
MonsterFactory.createGroup(definition: def, centerPosition: pos, count: n, spreadRadius: r)
```

### Monster Ontology (`lib/models/monster_ontology.dart`)

Type system for monster definitions:

```dart
class MonsterDefinition {
  String id, name, description;
  MonsterArchetype archetype;    // dps, support, healer, tank, boss
  MonsterFaction faction;        // undead, goblinoid, orcish, cultist, demonic, beast, elemental
  MonsterSize size;              // tiny(0.4x), small(0.6x), medium(0.8x), large(1.2x), huge(1.6x), colossal(2.0x+)
  double baseHealth, baseDamage, attackRange, moveSpeed;
  Vector3 modelColor;            // RGB for Mesh.cube color
  Vector3 accentColor;           // For direction indicator
  List<MonsterAbilityDefinition> abilities;
  double fleeHealthThreshold;    // % HP to start fleeing
  int monsterPower;              // Difficulty rating
}

class MonsterAbilityDefinition {
  String id, name, description;
  double damage, healing, cooldown, range, castTime;
  AbilityTargetType targetType;  // self, singleEnemy, singleAlly, allEnemies, etc.
  Color effectColor;
  bool isProjectile;
  double? projectileSpeed, buffAmount, buffDuration;
}
```

**Predefined minions** in `lib/game3d/data/monsters/minion_definitions.dart`:
- 8x Goblin Rogues (DPS, goblinoid, small)
- 4x Orc Warlocks (Support, orcish, medium)
- 2x Cultist Priests (Healer, cultist, medium)
- 1x Skeleton Champion (Tank, undead, large)

### Target Dummy (`lib/models/target_dummy.dart`, 117 lines)

DPS testing practice target:

```dart
class TargetDummy {
  static const String instanceId = 'target_dummy';
  static const double size = 1.5;

  Mesh mesh;                    // Mesh.cube(size: 1.5, color: burlywood)
  Transform3d transform;
  double displayHealth = 100000; // Infinite effective health
  double totalDamageTaken = 0;
  bool isSpawned = false;
}
```

Spawned 40 units in front of player when SHIFT+D opens DPS panel.

### Targeting System

WoW-style tab targeting + click targeting:

```dart
String? currentTargetId;         // 'boss', 'target_dummy', 'ally_0', or minion instanceId
Mesh? targetIndicatorMesh;       // Yellow/green/red dashed rectangle
```

**Key methods:**
- `setTarget(id)`, `clearTarget()`, `isTargeted(id)`
- `tabToNextTarget(playerX, playerZ, playerRotation, reverse: bool)` — Tab/Shift+Tab cycling
- `getTargetableEnemies(...)` — Sorted by angle from facing (60° cone priority), then distance
- `getCurrentTarget()` — Returns `{'type': 'boss'|'minion'|'dummy'|'ally', 'entity': ...}`
- `getDistanceToCurrentTarget()` — XZ-plane distance
- `validateTarget()` — Clear if dead

### Inventory System

```dart
final Inventory playerInventory = Inventory();
bool inventoryInitialized = false;
```

**Inventory model** (`lib/models/inventory.dart`):
```dart
class Inventory {
  Map<EquipmentSlot, Item?> _equipment;  // 10 slots
  List<Item?> _bag;                       // 24 slots
  ItemStats get totalEquippedStats;       // Sum of all equipped item stats
}
```

**Equipment slots** (`lib/models/item.dart`):
`helm`, `armor`, `back`, `gloves`, `legs`, `boots`, `mainHand`, `offHand`, `ring1`, `ring2`

**Item rarities** (with colors):
- Common (Gray: 0xFF9d9d9d)
- Uncommon (Green: 0xFF1eff00)
- Rare (Blue: 0xFF0070dd)
- Epic (Purple: 0xFFa335ee)
- Legendary (Orange: 0xFFff8000)

**ItemStats:**
```dart
class ItemStats {
  int strength, agility, intelligence, stamina, spirit;
  int armor, damage, critChance, health, mana;
  int maxBlueMana, maxRedMana, maxWhiteMana;    // Bonus mana pool
  int blueManaRegen, redManaRegen, whiteManaRegen; // Bonus regen rates
}
```

Items defined in `assets/data/items.json`, loaded by `lib/data/item_database.dart`.

### Ability System

10 ability slots, abilities 1-4 are implemented:

| Slot | Name | Type | Cooldown | Key Mechanic |
|------|------|------|----------|-------------|
| 1 | Sword Strike | Melee | 1.5s | Windup → swing, hit detection in range |
| 2 | Fireball | Ranged | 3.0s | Cast time → projectile, homing optional |
| 3 | Heal | Self | 10.0s | Cast time → instant heal |
| 4 | Dash Attack | Melee | 6.0s | 0.4s dash forward, hit on contact |
| 5-10 | Extended | Various | 5.0s | Placeholder cooldowns |

**Cast/Windup state:**
```dart
bool isCasting;            // Stationary cast (fireball, heal)
double castProgress;       // 0 → currentCastTime
bool isWindingUp;          // Mobile windup (melee)
double windupProgress;     // 0 → currentWindupTime
double windupMovementSpeedModifier; // 0.0-1.0 during windup
int pendingManaType;       // 0=blue, 1=red, 2=white
double pendingManaCost;    // Spent on completion, refunded on cancel
```

### Flight System

```dart
bool isFlying = false;
double flightPitchAngle = 0.0;    // -45 to +45 degrees
double flightSpeed = 7.0;
double flightAltitude = 0.0;       // Height above terrain
```

Costs white mana to initiate, drains white mana per second. Forced landing at 0 mana.

**Buffs:**
- `sovereignBuffActive` — Post-flight buff
- `windAffinityActive` — 2x white mana regen
- `windWarpSpeedActive` — 2x flight speed

### Wind System

```dart
final WindState _windState = WindState();
WindState get windState => _windState;
```

Wind simulation drives white mana regen, wind particles, and projectile deflection.
Config: `wind_config.dart` / `assets/data/wind_config.json`

### Minimap State

```dart
final MinimapState minimapState = MinimapState();
bool minimapOpen = true;  // M key toggle
```

MinimapState tracks zoom level, pings, elapsed time, rotation mode (rotating vs fixed-north).

### UI State Flags

```dart
bool abilitiesModalOpen = false;    // P key
bool characterPanelOpen = false;    // C key
bool bagPanelOpen = false;          // B key
bool dpsPanelOpen = false;          // SHIFT+D
bool allyCommandPanelOpen = false;  // F key
bool minimapOpen = true;            // M key
```

### Physics State

```dart
bool isJumping = false;
double verticalVelocity = 0.0;
bool isGrounded = true;
int jumpsRemaining = 2;        // Double jump
double jumpForce = 10.0;       // From GameConfig
double gravity = 20.0;         // From GameConfig
double groundLevel = 0.5;      // Y coordinate
```

### Game Loop

```dart
int? animationFrameId;
double? lastTimestamp;   // From requestAnimationFrame (monotonic, sub-ms)
int frameCount = 0;
```

## Configuration System

All config follows the same pattern:

### Config Class Pattern (`lib/game3d/state/`)

```dart
class ManaConfig extends ChangeNotifier {
  static const String _storageKey = 'mana_config_overrides';
  static const String _assetPath = 'assets/data/mana_config.json';

  Map<String, dynamic> _defaults = {};   // From JSON asset (immutable)
  Map<String, dynamic> _overrides = {};  // From SharedPreferences (user changes)

  double get maxBlueMana => _resolve('blue_mana.max', 100.0);

  T _resolve<T>(String key, T fallback) {
    // 1. Check overrides first
    // 2. Fall back to defaults
    // 3. Fall back to hardcoded fallback
  }

  Future<void> loadFromAsset() async { /* rootBundle.loadString(_assetPath) */ }
  Future<void> loadOverrides() async { /* SharedPreferences.getInstance() */ }
  Future<void> saveOverride(String key, dynamic value) async { /* ... */ }
}

ManaConfig? globalManaConfig; // Global accessor, loaded at startup
```

### Static Config (`lib/game3d/state/game_config.dart`, 207 lines)

Hardcoded constants (no JSON, no overrides):

```dart
class GameConfig {
  // Terrain
  static const int terrainGridSize = 50;
  static const double terrainMaxHeight = 3.0;

  // Player
  static const double playerSpeed = 5.0;
  static const double playerSize = 0.5;
  static final Vector3 playerStartPosition = Vector3(10, 0.5, 2);
  static const double playerStartRotation = 180.0; // Facing north

  // Monster
  static const double monsterMaxHealth = 100.0;
  static const double monsterSize = 1.2;
  static final Vector3 monsterStartPosition = Vector3(18, groundLevel, 18);

  // Ally
  static const double allyMaxHealth = 50.0;
  static const double allySize = 0.8;

  // Abilities (cooldowns, damage, ranges, durations)
  // Physics (gravity=20, jumpVelocity=10, groundLevel=0.5)
}
```

### Config Files

| JSON File | Config Class | Global Accessor |
|-----------|-------------|----------------|
| `assets/data/mana_config.json` | `ManaConfig` | `globalManaConfig` |
| `assets/data/wind_config.json` | `WindConfig` | `globalWindConfig` |
| `assets/data/minimap_config.json` | `MinimapConfig` | `globalMinimapConfig` |
| `assets/data/items.json` | `ItemDatabase` | `ItemDatabase.instance` |
| `assets/data/item_config.json` | `ItemConfig` | `globalItemConfig` |

## Systems (`lib/game3d/systems/`)

| System | File | Purpose |
|--------|------|---------|
| `RenderSystem` | `render_system.dart` | Draw order orchestration (see RENDERING_PIPELINE.md) |
| `PhysicsSystem` | `physics_system.dart` | Gravity, jumping, flight physics, terrain collision |
| `CombatSystem` | `combat_system.dart` | Damage calculation, hit detection, death handling |
| `AbilitySystem` | `ability_system.dart` | Cooldown management, cast bars, windups, mana costs |
| `AISystem` | `ai_system.dart` | Monster/minion AI decision trees |
| `InputSystem` | `input_system.dart` | Keyboard/mouse input processing |
| `EntityPickingSystem` | `entity_picking_system.dart` | Click-to-target (screen→world ray cast) |

## Model File Index

| File | Lines | Class | Purpose |
|------|-------|-------|---------|
| `lib/models/ally.dart` | 76 | `Ally` | Allied NPC with mesh, movement, commands, strategy |
| `lib/models/monster.dart` | 339 | `Monster`, `MonsterFactory` | Monster instance with AI state, combat, buffs |
| `lib/models/monster_ontology.dart` | ~200 | `MonsterDefinition`, `MonsterAbilityDefinition` | Type system: archetypes, factions, sizes, abilities |
| `lib/models/target_dummy.dart` | 117 | `TargetDummy` | Infinite-health DPS testing target |
| `lib/models/projectile.dart` | 47 | `Projectile` | Moving projectile with mesh, velocity, damage |
| `lib/models/impact_effect.dart` | ~40 | `ImpactEffect` | Expanding/fading explosion effect |
| `lib/models/inventory.dart` | ~150 | `Inventory` | Equipment slots + bag management |
| `lib/models/item.dart` | ~200 | `Item`, `ItemStats`, enums | Item data with rarity, stats, equipment slots |
| `lib/models/damage_event.dart` | ~30 | `DamageEvent` | Damage tracking for DPS calculation |
| `lib/models/ai_chat_message.dart` | ~20 | `AIChatMessage` | AI chat dialog messages |
| `lib/models/game_action.dart` | ~30 | `GameAction` | Player action representation |

## State File Index

| File | Lines | Purpose |
|------|-------|---------|
| `lib/game3d/state/game_state.dart` | 1228 | Central state: all entities, mana, targeting, UI flags |
| `lib/game3d/state/game_config.dart` | 207 | Static constants (terrain, player, monster, abilities, physics) |
| `lib/game3d/state/mana_config.dart` | ~150 | Blue/Red mana config with JSON defaults + overrides |
| `lib/game3d/state/wind_config.dart` | ~200 | Wind simulation + white mana + flight config |
| `lib/game3d/state/wind_state.dart` | ~150 | Runtime wind simulation state |
| `lib/game3d/state/minimap_config.dart` | ~200 | Minimap visual config |
| `lib/game3d/state/minimap_state.dart` | ~130 | Minimap runtime state (zoom, pings, mode) |
| `lib/game3d/state/item_config.dart` | ~100 | Item system config |
| `lib/game3d/state/action_bar_config.dart` | ~100 | Action bar layout config |
| `lib/game3d/state/abilities_config.dart` | ~200 | Ability definitions + overrides |

## How to Add a New Entity Type (Checklist)

1. **Model class** in `lib/models/new_entity.dart`:
   - Fields: `Mesh mesh`, `Transform3d transform`, `double health`, etc.
   - Factory constructor that creates mesh + sets up transform

2. **Add to GameState** in `lib/game3d/state/game_state.dart`:
   - `List<NewEntity> newEntities = [];`
   - Spawn/despawn methods
   - Any interaction state

3. **Rendering** in `lib/game3d/systems/render_system.dart`:
   - Add render loop in correct draw order position
   - `for (final entity in gameState.newEntities) { renderer.render(entity.mesh, entity.transform, camera); }`

4. **Terrain placement**:
   - `terrainY = terrainManager.getTerrainHeight(x, z);`
   - `transform.position.y = terrainY + entityHeight/2 + 0.15;`

5. **Minimap** (optional) in `lib/game3d/ui/minimap/minimap_entity_painter.dart`:
   - Add blip rendering using `_worldToMinimap()` coordinate conversion

6. **Targeting** (optional) in GameState:
   - Add to `getTargetableEnemies()` if targetable
   - Add to `getCurrentTarget()` switch
   - Add to `_renderTargetIndicator()` in RenderSystem

7. **Config** (if configurable) in `lib/game3d/state/` + `assets/data/`:
   - JSON file with defaults
   - Config class with `_resolve()` getters
   - Global accessor
