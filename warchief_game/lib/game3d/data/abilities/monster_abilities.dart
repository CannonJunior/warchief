import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Monster abilities - Currently active abilities for enemy monsters
class MonsterAbilities {
  MonsterAbilities._();

  /// Monster Ability 1: Dark Strike (Melee Sword Attack)
  static final darkStrike = AbilityData(
    name: 'Dark Strike',
    description: 'A devastating melee attack with a giant shadow sword',
    type: AbilityType.melee,
    damage: 15.0,
    cooldown: 1.0,
    duration: 0.4,
    range: 3.0,
    color: Vector3(0.4, 0.1, 0.5),
    impactColor: Vector3(0.6, 0.2, 0.8),
    impactSize: 0.6,
  );

  /// Monster Ability 2: Shadow Bolt (Ranged Projectile)
  static final shadowBolt = AbilityData(
    name: 'Shadow Bolt',
    description: 'Fires a bolt of dark energy',
    type: AbilityType.ranged,
    damage: 12.0,
    cooldown: 4.0,
    range: 50.0,
    color: Vector3(0.5, 0.0, 0.5),
    impactColor: Vector3(0.5, 0.0, 0.5),
    impactSize: 0.5,
    projectileSpeed: 6.0,
    projectileSize: 0.5,
  );

  /// Monster Ability 3: Dark Healing
  static final darkHeal = AbilityData(
    name: 'Dark Heal',
    description: 'Channels dark energy to restore health',
    type: AbilityType.heal,
    cooldown: 8.0,
    duration: 0.5,
    healAmount: 25.0,
    color: Vector3(0.3, 0.0, 0.3),
    impactColor: Vector3(0.5, 0.1, 0.5),
    impactSize: 1.2,
  );

  /// Monster Ability 4: Claw Swipe (Quick Melee)
  static final clawSwipe = AbilityData(
    name: 'Claw Swipe',
    description: 'A quick claw attack.',
    type: AbilityType.melee,
    damage: 12.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(0.5, 0.3, 0.3),
    impactColor: Vector3(0.6, 0.4, 0.4),
    impactSize: 0.4,
    category: 'monster',
  );

  /// Get ability by index (0=DarkStrike, 1=ShadowBolt, 2=DarkHeal)
  static AbilityData getByIndex(int index) {
    switch (index) {
      case 0: return darkStrike;
      case 1: return shadowBolt;
      case 2: return darkHeal;
      default: return darkStrike;
    }
  }

  /// All monster abilities as a list
  static List<AbilityData> get all => [darkStrike, shadowBolt, darkHeal, clawSwipe];
}
