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
    damageSchool: DamageSchool.holy,
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
    damageSchool: DamageSchool.holy,
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
    damageSchool: DamageSchool.holy,
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
    damageSchool: DamageSchool.holy,
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
    damageSchool: DamageSchool.holy,
  );

  // ==================== MELEE ABILITIES ====================

  /// Holy Smite — Divine palm strike
  static final holySmite = AbilityData(
    name: 'Holy Smite',
    description: 'Strike with divine radiance at close range',
    type: AbilityType.melee,
    damage: 12.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(1.0, 1.0, 0.6),
    impactColor: Vector3(1.0, 1.0, 0.8),
    impactSize: 0.5,
    category: 'healer',
    damageSchool: DamageSchool.holy,
  );

  /// Judgment Hammer — Holy mace slam with stun
  static final judgmentHammer = AbilityData(
    name: 'Judgment Hammer',
    description: 'Slam down a hammer of divine judgment, stunning the target',
    type: AbilityType.melee,
    damage: 24.0,
    cooldown: 6.0,
    range: 2.5,
    color: Vector3(1.0, 0.9, 0.4),
    impactColor: Vector3(1.0, 0.95, 0.6),
    impactSize: 0.7,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.0,
    category: 'healer',
    damageSchool: DamageSchool.holy,
  );

  /// Judgment Mark — Divine strike that applies permanent vulnerability
  static final judgmentMark = AbilityData(
    name: 'Judgment Mark',
    description: 'A divine strike that permanently exposes the target to holy damage.',
    type: AbilityType.melee,
    damage: 8.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(1.0, 1.0, 0.7),
    impactColor: Vector3(1.0, 1.0, 0.8),
    impactSize: 0.6,
    category: 'healer',
    damageSchool: DamageSchool.holy,
    appliesPermanentVulnerability: true,
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Battle Blessing — Activates chain-combo mode for healers.
  /// Land 7 consecutive healer strikes within 7 seconds to fire the chain combo.
  static final battleBlessing = AbilityData(
    name: 'Battle Blessing',
    description: 'Bless your strikes with battle-light — activate chain-combo mode. '
        'Land 7 healer hits within 7 seconds to trigger a massive heal and regeneration burst.',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 10.0,
    range: 2.0,
    color: Vector3(1.0, 0.95, 0.5),
    impactColor: Vector3(1.0, 1.0, 0.7),
    impactSize: 0.7,
    manaColor: ManaColor.blue,
    manaCost: 20.0,
    damageSchool: DamageSchool.holy,
    category: 'healer',
    enablesComboChain: true,
  );

  /// All healer abilities as a list
  static List<AbilityData> get all => [
    holyLight, rejuvenation, circleOfHealing, blessingOfStrength, purify,
    holySmite, judgmentHammer, judgmentMark, battleBlessing,
  ];
}
