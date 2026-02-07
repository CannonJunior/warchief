import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Healer/Support abilities - Healing and buff skills
class HealerAbilities {
  HealerAbilities._();

  /// Holy Light - Single target heal
  static final holyLight = AbilityData(
    name: 'Holy Light',
    description: 'Powerful healing spell for a single target',
    type: AbilityType.heal,
    cooldown: 4.0,
    duration: 0.5,
    range: 40.0,
    healAmount: 35.0,
    color: Vector3(1.0, 1.0, 0.6),
    impactColor: Vector3(1.0, 1.0, 0.8),
    impactSize: 1.0,
    castTime: 1.5,
    category: 'healer',
  );

  /// Rejuvenation - Heal over time
  static final rejuvenation = AbilityData(
    name: 'Rejuvenation',
    description: 'Restores health gradually over time',
    type: AbilityType.heal,
    cooldown: 6.0,
    duration: 8.0,
    range: 40.0,
    healAmount: 40.0,
    color: Vector3(0.4, 1.0, 0.4),
    impactColor: Vector3(0.5, 1.0, 0.5),
    impactSize: 0.8,
    statusEffect: StatusEffect.regen,
    dotTicks: 8,
    category: 'healer',
  );

  /// Circle of Healing - AoE heal
  static final circleOfHealing = AbilityData(
    name: 'Circle of Healing',
    description: 'Heals all allies in a radius',
    type: AbilityType.heal,
    cooldown: 15.0,
    duration: 0.5,
    range: 40.0,
    healAmount: 20.0,
    color: Vector3(0.8, 1.0, 0.5),
    impactColor: Vector3(0.9, 1.0, 0.6),
    impactSize: 1.8,
    aoeRadius: 8.0,
    maxTargets: 5,
    category: 'healer',
  );

  /// Blessing of Strength - Damage buff
  static final blessingOfStrength = AbilityData(
    name: 'Blessing of Strength',
    description: 'Increases ally damage output',
    type: AbilityType.buff,
    cooldown: 20.0,
    duration: 15.0,
    range: 40.0,
    color: Vector3(1.0, 0.6, 0.2),
    impactColor: Vector3(1.0, 0.7, 0.3),
    impactSize: 1.0,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.25,
    category: 'healer',
  );

  /// Purify - Removes debuffs
  static final purify = AbilityData(
    name: 'Purify',
    description: 'Removes harmful effects from ally',
    type: AbilityType.buff,
    cooldown: 8.0,
    range: 40.0,
    color: Vector3(1.0, 1.0, 1.0),
    impactColor: Vector3(1.0, 1.0, 0.9),
    impactSize: 1.0,
    category: 'healer',
  );

  /// All healer abilities as a list
  static List<AbilityData> get all => [
    holyLight, rejuvenation, circleOfHealing, blessingOfStrength, purify,
  ];
}
