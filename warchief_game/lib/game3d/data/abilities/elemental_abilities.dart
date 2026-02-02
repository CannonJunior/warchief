import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Elemental abilities - Advanced elemental attacks
class ElementalAbilities {
  ElementalAbilities._();

  /// Ice Lance - Piercing ice projectile
  static final iceLance = AbilityData(
    name: 'Ice Lance',
    description: 'Sharp ice projectile that pierces through enemies',
    type: AbilityType.ranged,
    damage: 18.0,
    cooldown: 3.0,
    range: 45.0,
    color: Vector3(0.7, 0.9, 1.0),
    impactColor: Vector3(0.8, 1.0, 1.0),
    impactSize: 0.4,
    projectileSpeed: 18.0,
    projectileSize: 0.2,
    piercing: true,
    maxTargets: 3,
    category: 'elemental',
  );

  /// Flame Wave - Line AoE fire attack
  static final flameWave = AbilityData(
    name: 'Flame Wave',
    description: 'Sends a wave of fire in a line',
    type: AbilityType.aoe,
    damage: 22.0,
    cooldown: 7.0,
    duration: 0.6,
    range: 12.0,
    color: Vector3(1.0, 0.5, 0.1),
    impactColor: Vector3(1.0, 0.6, 0.2),
    impactSize: 0.8,
    aoeRadius: 2.0,
    statusEffect: StatusEffect.burn,
    statusDuration: 2.0,
    category: 'elemental',
  );

  /// Earthquake - Ground AoE with stun
  static final earthquake = AbilityData(
    name: 'Earthquake',
    description: 'Shakes the ground, damaging and stunning enemies',
    type: AbilityType.channeled,
    damage: 10.0,
    cooldown: 25.0,
    duration: 3.0,
    range: 15.0,
    color: Vector3(0.6, 0.4, 0.2),
    impactColor: Vector3(0.7, 0.5, 0.3),
    impactSize: 1.5,
    aoeRadius: 8.0,
    dotTicks: 6,
    statusEffect: StatusEffect.stun,
    statusDuration: 0.5,
    castTime: 1.0,
    category: 'elemental',
  );

  /// All elemental abilities as a list
  static List<AbilityData> get all => [
    iceLance, flameWave, earthquake,
  ];
}
