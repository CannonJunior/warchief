import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Nature/Druid abilities - Control and nature-based damage
class NatureAbilities {
  NatureAbilities._();

  /// Entangling Roots - Root enemies in place
  static final entanglingRoots = AbilityData(
    name: 'Entangling Roots',
    description: 'Roots enemy in place, preventing movement',
    type: AbilityType.debuff,
    damage: 5.0,
    cooldown: 12.0,
    duration: 4.0,
    range: 40.0,
    color: Vector3(0.4, 0.6, 0.2),
    impactColor: Vector3(0.5, 0.7, 0.3),
    impactSize: 0.8,
    statusEffect: StatusEffect.root,
    statusDuration: 4.0,
    category: 'nature',
  );

  /// Thorns - Reflect damage buff
  static final thorns = AbilityData(
    name: 'Thorns',
    description: 'Attackers take damage when hitting the target',
    type: AbilityType.buff,
    cooldown: 30.0,
    duration: 20.0,
    damage: 5.0,
    color: Vector3(0.3, 0.5, 0.2),
    impactColor: Vector3(0.4, 0.6, 0.3),
    impactSize: 1.0,
    category: 'nature',
  );

  /// Nature's Wrath - AoE nature damage
  static final naturesWrath = AbilityData(
    name: "Nature's Wrath",
    description: 'Unleashes the fury of nature on enemies',
    type: AbilityType.aoe,
    damage: 25.0,
    cooldown: 14.0,
    duration: 0.8,
    range: 40.0,
    color: Vector3(0.5, 0.8, 0.3),
    impactColor: Vector3(0.6, 0.9, 0.4),
    impactSize: 1.2,
    aoeRadius: 5.0,
    category: 'nature',
  );

  // ==================== MELEE ABILITIES ====================

  /// Briar Lash — Thorn whip strike with bleed
  static final briarLash = AbilityData(
    name: 'Briar Lash',
    description: 'Lash out with a thorned vine whip, causing bleeding wounds',
    type: AbilityType.melee,
    damage: 15.0,
    cooldown: 3.5,
    range: 3.0,
    color: Vector3(0.4, 0.6, 0.2),
    impactColor: Vector3(0.6, 0.3, 0.2),
    impactSize: 0.5,
    statusEffect: StatusEffect.bleed,
    statusDuration: 3.0,
    dotTicks: 2,
    category: 'nature',
  );

  /// Ironwood Smash — Bark-encased slam that roots the target
  static final ironwoodSmash = AbilityData(
    name: 'Ironwood Smash',
    description: 'Smash with an ironwood-hardened fist, rooting the target in place',
    type: AbilityType.melee,
    damage: 25.0,
    cooldown: 6.0,
    range: 2.5,
    color: Vector3(0.45, 0.55, 0.25),
    impactColor: Vector3(0.55, 0.65, 0.3),
    impactSize: 0.7,
    statusEffect: StatusEffect.root,
    statusDuration: 1.5,
    category: 'nature',
  );

  /// All nature abilities as a list
  static List<AbilityData> get all => [
    entanglingRoots, thorns, naturesWrath,
    briarLash, ironwoodSmash,
  ];
}
