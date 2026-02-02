import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Utility abilities - Movement and team buffs
class UtilityAbilities {
  UtilityAbilities._();

  /// Sprint - Movement speed buff
  static final sprint = AbilityData(
    name: 'Sprint',
    description: 'Greatly increases movement speed temporarily',
    type: AbilityType.buff,
    cooldown: 30.0,
    duration: 8.0,
    color: Vector3(0.9, 0.9, 0.3),
    impactColor: Vector3(1.0, 1.0, 0.5),
    impactSize: 0.6,
    statusEffect: StatusEffect.haste,
    statusStrength: 1.5,
    category: 'utility',
  );

  /// Battle Shout - AoE damage buff for allies
  static final battleShout = AbilityData(
    name: 'Battle Shout',
    description: 'Boosts damage of all nearby allies',
    type: AbilityType.buff,
    cooldown: 45.0,
    duration: 20.0,
    color: Vector3(1.0, 0.4, 0.2),
    impactColor: Vector3(1.0, 0.5, 0.3),
    impactSize: 1.5,
    aoeRadius: 10.0,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.15,
    maxTargets: 5,
    category: 'utility',
  );

  /// All utility abilities as a list
  static List<AbilityData> get all => [sprint, battleShout];
}
