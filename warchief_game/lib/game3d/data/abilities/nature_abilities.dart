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
    range: 25.0,
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
    range: 20.0,
    color: Vector3(0.5, 0.8, 0.3),
    impactColor: Vector3(0.6, 0.9, 0.4),
    impactSize: 1.2,
    aoeRadius: 5.0,
    category: 'nature',
  );

  /// All nature abilities as a list
  static List<AbilityData> get all => [
    entanglingRoots, thorns, naturesWrath,
  ];
}
