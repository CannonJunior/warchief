/// Monster - Runtime instance of a monster in the game
///
/// This class represents an active monster entity with:
/// - Reference to its MonsterDefinition (type/stats)
/// - Current state (health, position, cooldowns)
/// - AI state (target, current action)

import 'package:vector_math/vector_math.dart' hide Colors;
import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';
import 'monster_ontology.dart';
import 'projectile.dart';

/// AI State for monster behavior
enum MonsterAIState {
  idle,         // Standing still, no target
  patrol,       // Moving along patrol path
  pursuing,     // Moving toward target
  attacking,    // Executing attack
  casting,      // Casting ability
  fleeing,      // Running away
  supporting,   // Buffing/healing allies
  dead,         // Defeated
}

/// Monster - Active monster instance
class Monster {
  /// Unique instance ID
  final String instanceId;

  /// Reference to the monster definition (type/stats)
  final MonsterDefinition definition;

  /// Visual representation
  Mesh mesh;
  Transform3d transform;
  Transform3d? directionIndicatorTransform;
  double rotation;

  /// Current stats
  double health;
  double maxHealth;
  double mana;      // Resource for abilities (casters use this)
  double maxMana;

  /// Ability cooldowns (indexed by ability definition order)
  List<double> abilityCooldowns;

  /// AI State
  MonsterAIState aiState;
  double aiTimer;
  double aiInterval;
  String? targetId;           // ID of current target (player or ally)
  Vector3? targetPosition;    // Position to move toward

  /// Combat state
  bool isInCombat;
  double combatTimer;         // Time in combat
  double lastDamageTime;      // Time since last took damage

  /// Buff/debuff state
  double damageMultiplier;    // 1.0 = normal, >1 = buffed, <1 = debuffed
  double damageReduction;     // 0.0 = none, 0.5 = 50% reduction
  double buffTimer;           // Time remaining on current buff

  /// Projectiles fired by this monster
  List<Projectile> projectiles;

  /// Active ability state
  bool isAbilityActive;
  int activeAbilityIndex;
  double abilityActiveTime;

  Monster({
    required this.instanceId,
    required this.definition,
    required this.mesh,
    required this.transform,
    this.directionIndicatorTransform,
    this.rotation = 0.0,
    double? initialHealth,
  })  : health = initialHealth ?? definition.effectiveHealth,
        maxHealth = definition.effectiveHealth,
        mana = 100.0,  // Default mana pool
        maxMana = 100.0,
        abilityCooldowns = List.filled(definition.abilities.length, 0.0),
        aiState = MonsterAIState.idle,
        aiTimer = 0.0,
        aiInterval = 1.0,
        isInCombat = false,
        combatTimer = 0.0,
        lastDamageTime = 0.0,
        damageMultiplier = 1.0,
        damageReduction = 0.0,
        buffTimer = 0.0,
        projectiles = [],
        isAbilityActive = false,
        activeAbilityIndex = -1,
        abilityActiveTime = 0.0;

  /// Check if monster is alive
  bool get isAlive => health > 0;

  /// Check if monster is at low health (for flee check)
  bool get isLowHealth => health / maxHealth <= definition.fleeHealthThreshold;

  /// Get effective damage (with buffs/debuffs applied)
  double get effectiveDamage => definition.effectiveDamage * damageMultiplier;

  /// Apply damage to this monster
  void takeDamage(double amount) {
    final reducedAmount = amount * (1.0 - damageReduction);
    health = (health - reducedAmount).clamp(0.0, maxHealth);
    lastDamageTime = 0.0;
    isInCombat = true;
    combatTimer = 0.0;

    if (health <= 0) {
      aiState = MonsterAIState.dead;
    }
  }

  /// Heal this monster
  void heal(double amount) {
    health = (health + amount).clamp(0.0, maxHealth);
  }

  /// Apply a buff to this monster
  void applyBuff({
    double? damageMultiplier,
    double? damageReduction,
    required double duration,
  }) {
    if (damageMultiplier != null) {
      this.damageMultiplier = damageMultiplier;
    }
    if (damageReduction != null) {
      this.damageReduction = damageReduction;
    }
    buffTimer = duration;
  }

  /// Update cooldowns and timers
  void updateTimers(double dt) {
    // Update ability cooldowns
    for (int i = 0; i < abilityCooldowns.length; i++) {
      if (abilityCooldowns[i] > 0) {
        abilityCooldowns[i] = (abilityCooldowns[i] - dt).clamp(0.0, double.infinity);
      }
    }

    // Update AI timer
    aiTimer += dt;

    // Update combat timer
    if (isInCombat) {
      combatTimer += dt;
      lastDamageTime += dt;

      // Exit combat after 5 seconds of no damage
      if (lastDamageTime > 5.0) {
        isInCombat = false;
      }
    }

    // Update buff timer
    if (buffTimer > 0) {
      buffTimer -= dt;
      if (buffTimer <= 0) {
        // Reset buffs
        damageMultiplier = 1.0;
        damageReduction = 0.0;
      }
    }

    // Update active ability
    if (isAbilityActive) {
      abilityActiveTime += dt;
    }
  }

  /// Check if an ability is ready to use
  bool isAbilityReady(int index) {
    if (index < 0 || index >= abilityCooldowns.length) return false;
    return abilityCooldowns[index] <= 0;
  }

  /// Use an ability (starts cooldown)
  void useAbility(int index) {
    if (index < 0 || index >= definition.abilities.length) return;
    abilityCooldowns[index] = definition.abilities[index].cooldown;
    isAbilityActive = true;
    activeAbilityIndex = index;
    abilityActiveTime = 0.0;
  }

  /// Get the primary ability (first in list)
  MonsterAbilityDefinition? get primaryAbility =>
      definition.abilities.isNotEmpty ? definition.abilities[0] : null;

  /// Get distance to a position
  double distanceTo(Vector3 position) {
    return (transform.position - position).length;
  }

  /// Check if target is in range for an ability
  bool isInRange(Vector3 targetPos, int abilityIndex) {
    if (abilityIndex < 0 || abilityIndex >= definition.abilities.length) {
      return distanceTo(targetPos) <= definition.attackRange;
    }
    return distanceTo(targetPos) <= definition.abilities[abilityIndex].range;
  }

  /// Get color for UI health bar based on archetype
  int get healthBarColor {
    switch (definition.archetype) {
      case MonsterArchetype.dps:
        return 0xFFFF6B6B;  // Red
      case MonsterArchetype.support:
        return 0xFF9933FF;  // Purple
      case MonsterArchetype.healer:
        return 0xFF66CC66;  // Green
      case MonsterArchetype.tank:
        return 0xFFFFAA33;  // Orange
      case MonsterArchetype.boss:
        return 0xFFFF0000;  // Bright red
    }
  }

  /// Create a summary string for debugging
  @override
  String toString() {
    return 'Monster[${definition.name}] HP: ${health.toStringAsFixed(0)}/${maxHealth.toStringAsFixed(0)} '
        'State: ${aiState.name} Power: ${definition.monsterPower}';
  }
}

/// Factory for creating Monster instances from definitions
class MonsterFactory {
  static int _instanceCounter = 0;

  /// Create a monster from a definition at a position
  static Monster create({
    required MonsterDefinition definition,
    required Vector3 position,
    double rotation = 0.0,
  }) {
    final instanceId = '${definition.id}_${_instanceCounter++}';

    // Create mesh based on definition
    final mesh = Mesh.cube(
      size: definition.effectiveScale,
      color: definition.modelColor,
    );

    // Create transform
    final transform = Transform3d(
      position: position.clone(),
      rotation: Vector3(0, rotation, 0),
      scale: Vector3(1, 1, 1),
    );

    // Create direction indicator
    final indicatorTransform = Transform3d(
      position: Vector3(position.x, position.y + definition.effectiveScale * 0.6, position.z),
      rotation: Vector3(0, rotation + 180, 0),
      scale: Vector3(1, 1, 1),
    );

    return Monster(
      instanceId: instanceId,
      definition: definition,
      mesh: mesh,
      transform: transform,
      directionIndicatorTransform: indicatorTransform,
      rotation: rotation,
    );
  }

  /// Create multiple monsters spread around a center point
  static List<Monster> createGroup({
    required MonsterDefinition definition,
    required Vector3 centerPosition,
    required int count,
    double spreadRadius = 3.0,
  }) {
    final monsters = <Monster>[];

    for (int i = 0; i < count; i++) {
      // Calculate position in a circle/spiral pattern
      final angle = (i / count) * 2 * 3.14159;
      final radius = spreadRadius * (0.5 + (i % 2) * 0.5); // Vary radius slightly
      final offsetX = radius * cos(angle);
      final offsetZ = radius * sin(angle);

      final position = Vector3(
        centerPosition.x + offsetX,
        centerPosition.y,
        centerPosition.z + offsetZ,
      );

      // Face toward center
      final rotation = -angle * (180 / 3.14159) + 180;

      monsters.add(create(
        definition: definition,
        position: position,
        rotation: rotation,
      ));
    }

    return monsters;
  }

  // Math helpers
  static double cos(double radians) => radians.abs() < 0.0001 ? 1.0 :
      _cosApprox(radians);
  static double sin(double radians) => radians.abs() < 0.0001 ? 0.0 :
      _sinApprox(radians);

  static double _cosApprox(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.14159) x -= 2 * 3.14159;
    while (x < -3.14159) x += 2 * 3.14159;
    // Taylor series approximation
    final x2 = x * x;
    return 1 - x2/2 + x2*x2/24 - x2*x2*x2/720;
  }

  static double _sinApprox(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.14159) x -= 2 * 3.14159;
    while (x < -3.14159) x += 2 * 3.14159;
    // Taylor series approximation
    final x2 = x * x;
    return x - x*x2/6 + x*x2*x2/120 - x*x2*x2*x2/5040;
  }
}
