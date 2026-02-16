import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Necromancer/Dark abilities - Life drain, curses, and summoning
class NecromancerAbilities {
  NecromancerAbilities._();

  /// Life Drain - Damage and heal
  static final lifeDrain = AbilityData(
    name: 'Life Drain',
    description: 'Drains life from enemy, healing self',
    type: AbilityType.channeled,
    damage: 6.0,
    cooldown: 10.0,
    duration: 3.0,
    range: 40.0,
    healAmount: 4.0,
    color: Vector3(0.5, 0.0, 0.2),
    impactColor: Vector3(0.6, 0.1, 0.3),
    impactSize: 0.5,
    dotTicks: 6,
    category: 'necromancer',
  );

  /// Curse of Weakness - Reduce enemy damage
  static final curseOfWeakness = AbilityData(
    name: 'Curse of Weakness',
    description: 'Curses enemy, reducing their damage output',
    type: AbilityType.debuff,
    cooldown: 16.0,
    duration: 10.0,
    range: 40.0,
    color: Vector3(0.3, 0.0, 0.3),
    impactColor: Vector3(0.4, 0.1, 0.4),
    impactSize: 0.8,
    statusEffect: StatusEffect.weakness,
    statusStrength: 0.75,
    category: 'necromancer',
  );

  /// Fear - Makes enemy flee
  static final fear = AbilityData(
    name: 'Fear',
    description: 'Terrifies enemy, causing them to flee',
    type: AbilityType.debuff,
    cooldown: 20.0,
    duration: 4.0,
    range: 40.0,
    color: Vector3(0.2, 0.0, 0.2),
    impactColor: Vector3(0.3, 0.0, 0.3),
    impactSize: 0.7,
    statusEffect: StatusEffect.fear,
    statusDuration: 4.0,
    category: 'necromancer',
  );

  /// Soul Rot - Dark projectile that applies a damage-over-time curse
  static final soulRot = AbilityData(
    name: 'Soul Rot',
    description: 'Launches a bolt of necrotic energy that rots the target\'s soul, dealing damage over time',
    type: AbilityType.dot,
    damage: 60.0,
    cooldown: 12.0,
    duration: 10.0,
    range: 40.0,
    color: Vector3(0.4, 0.1, 0.5),
    impactColor: Vector3(0.5, 0.2, 0.6),
    impactSize: 0.6,
    projectileSpeed: 10.0,
    projectileSize: 0.35,
    statusEffect: StatusEffect.poison,
    statusDuration: 10.0,
    dotTicks: 5,
    category: 'necromancer',
  );

  /// Summon Skeleton - Creates temporary ally
  static final summonSkeleton = AbilityData(
    name: 'Summon Skeleton',
    description: 'Raises a skeleton warrior to fight for you',
    type: AbilityType.summon,
    cooldown: 25.0,
    duration: 30.0,
    color: Vector3(0.8, 0.8, 0.7),
    impactColor: Vector3(0.9, 0.9, 0.8),
    impactSize: 1.0,
    category: 'necromancer',
  );

  /// All necromancer abilities as a list
  static List<AbilityData> get all => [
    lifeDrain, curseOfWeakness, fear, soulRot, summonSkeleton,
  ];
}
