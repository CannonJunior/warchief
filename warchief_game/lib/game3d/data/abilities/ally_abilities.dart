import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Ally abilities - Currently active abilities for allied units
class AllyAbilities {
  AllyAbilities._();

  /// Ally Sword Attack
  static final sword = AbilityData(
    name: 'Ally Sword',
    description: 'Ally melee attack',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 5.0,
    duration: 0.3,
    range: 2.0,
    color: Vector3(0.6, 0.8, 1.0),
    impactColor: Vector3(0.7, 0.9, 1.0),
    impactSize: 0.5,
  );

  /// Ally Fireball
  static final fireball = AbilityData(
    name: 'Ally Fireball',
    description: 'Ally ranged projectile',
    type: AbilityType.ranged,
    damage: 15.0,
    cooldown: 5.0,
    range: 50.0,
    color: Vector3(1.0, 0.4, 0.0),
    impactColor: Vector3(1.0, 0.4, 0.0),
    impactSize: 0.6,
    projectileSpeed: 8.0,
    projectileSize: 0.3,
  );

  /// Ally Self Heal
  static final heal = AbilityData(
    name: 'Ally Heal',
    description: 'Ally self-healing ability',
    type: AbilityType.heal,
    cooldown: 5.0,
    duration: 0.5,
    healAmount: 15.0,
    color: Vector3(0.5, 1.0, 0.3),
    impactColor: Vector3(0.3, 1.0, 0.5),
    impactSize: 1.0,
  );

  /// Get ability by index (0=Sword, 1=Fireball, 2=Heal)
  static AbilityData getByIndex(int index) {
    switch (index) {
      case 0: return sword;
      case 1: return fireball;
      case 2: return heal;
      default: return sword;
    }
  }

  /// All ally abilities as a list
  static List<AbilityData> get all => [sword, fireball, heal];
}
