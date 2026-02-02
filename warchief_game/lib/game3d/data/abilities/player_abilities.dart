import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Player abilities - Currently active abilities for the player character
class PlayerAbilities {
  PlayerAbilities._();

  /// Player Ability 1: Sword (Melee Attack)
  static final sword = AbilityData(
    name: 'Sword',
    description: 'A swift melee attack that damages nearby enemies',
    type: AbilityType.melee,
    damage: 25.0,
    cooldown: 1.5,
    duration: 0.3,
    range: 2.0,
    color: Vector3(0.7, 0.7, 0.8),
    impactColor: Vector3(0.8, 0.8, 0.9),
    impactSize: 0.5,
  );

  /// Player Ability 2: Fireball (Ranged Projectile)
  static final fireball = AbilityData(
    name: 'Fireball',
    description: 'Launches a blazing projectile at enemies',
    type: AbilityType.ranged,
    damage: 20.0,
    cooldown: 3.0,
    range: 50.0,
    color: Vector3(1.0, 0.4, 0.0),
    impactColor: Vector3(1.0, 0.5, 0.0),
    impactSize: 0.8,
    projectileSpeed: 10.0,
    projectileSize: 0.4,
  );

  /// Player Ability 3: Heal (Self Heal)
  static final heal = AbilityData(
    name: 'Heal',
    description: 'Restores health over time',
    type: AbilityType.heal,
    cooldown: 10.0,
    duration: 1.0,
    healAmount: 20.0,
    color: Vector3(0.5, 1.0, 0.3),
    impactColor: Vector3(0.3, 1.0, 0.5),
    impactSize: 1.5,
  );

  /// Player Ability 4: Dash Attack (Dash Forward + Melee)
  static final dashAttack = AbilityData(
    name: 'Dash Attack',
    description: 'Dash forward and strike enemies in your path',
    type: AbilityType.melee,
    damage: 30.0,
    cooldown: 6.0,
    duration: 0.4,
    range: 6.0,
    color: Vector3(0.9, 0.7, 0.3),
    impactColor: Vector3(1.0, 0.8, 0.4),
    impactSize: 0.7,
    knockbackForce: 3.0,
    category: 'warrior',
  );

  /// Get ability by index (0=Sword, 1=Fireball, 2=Heal, 3=DashAttack)
  static AbilityData getByIndex(int index) {
    switch (index) {
      case 0: return sword;
      case 1: return fireball;
      case 2: return heal;
      case 3: return dashAttack;
      default: return sword;
    }
  }

  /// All player abilities as a list
  static List<AbilityData> get all => [sword, fireball, heal, dashAttack];
}
