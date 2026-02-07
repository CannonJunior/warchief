import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Warrior/Tank abilities - Melee combat and defensive skills
class WarriorAbilities {
  WarriorAbilities._();

  /// Shield Bash - Melee stun attack
  static final shieldBash = AbilityData(
    name: 'Shield Bash',
    description: 'Strikes enemy with shield, stunning them briefly',
    type: AbilityType.melee,
    damage: 15.0,
    cooldown: 6.0,
    duration: 0.3,
    range: 1.5,
    color: Vector3(0.6, 0.6, 0.7),
    impactColor: Vector3(1.0, 1.0, 0.5),
    impactSize: 0.6,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.5,
    category: 'warrior',
  );

  /// Whirlwind - Spinning AoE attack
  static final whirlwind = AbilityData(
    name: 'Whirlwind',
    description: 'Spins with weapon extended, damaging all nearby enemies',
    type: AbilityType.aoe,
    damage: 25.0,
    cooldown: 8.0,
    duration: 1.0,
    range: 3.0,
    color: Vector3(0.8, 0.8, 0.8),
    impactColor: Vector3(0.9, 0.9, 0.9),
    impactSize: 0.4,
    aoeRadius: 3.0,
    maxTargets: 5,
    category: 'warrior',
  );

  /// Charge - Rush forward and knockback
  static final charge = AbilityData(
    name: 'Charge',
    description: 'Rushes toward enemy, knocking them back on impact',
    type: AbilityType.melee,
    damage: 20.0,
    cooldown: 10.0,
    duration: 0.5,
    range: 8.0,
    color: Vector3(0.9, 0.7, 0.3),
    impactColor: Vector3(1.0, 0.8, 0.4),
    impactSize: 0.8,
    knockbackForce: 5.0,
    category: 'warrior',
  );

  /// Taunt - Forces enemies to attack you
  static final taunt = AbilityData(
    name: 'Taunt',
    description: 'Forces nearby enemies to focus attacks on you',
    type: AbilityType.debuff,
    cooldown: 12.0,
    duration: 4.0,
    range: 40.0,
    color: Vector3(1.0, 0.3, 0.3),
    impactColor: Vector3(1.0, 0.2, 0.2),
    impactSize: 1.0,
    aoeRadius: 6.0,
    maxTargets: 3,
    category: 'warrior',
  );

  /// Fortify - Defensive shield buff
  static final fortify = AbilityData(
    name: 'Fortify',
    description: 'Raises shield to absorb incoming damage',
    type: AbilityType.buff,
    cooldown: 15.0,
    duration: 5.0,
    color: Vector3(0.4, 0.6, 0.9),
    impactColor: Vector3(0.5, 0.7, 1.0),
    impactSize: 1.2,
    statusEffect: StatusEffect.shield,
    statusStrength: 50.0,
    category: 'warrior',
  );

  /// All warrior abilities as a list
  static List<AbilityData> get all => [
    shieldBash, whirlwind, charge, taunt, fortify,
  ];
}
