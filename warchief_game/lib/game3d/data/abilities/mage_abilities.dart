import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Mage/Elemental abilities - Ranged magical attacks and utility
class MageAbilities {
  MageAbilities._();

  /// Frost Bolt - Ice projectile with slow
  static final frostBolt = AbilityData(
    name: 'Frost Bolt',
    description: 'Launches icy projectile that slows enemies',
    type: AbilityType.ranged,
    damage: 15.0,
    cooldown: 2.5,
    range: 40.0,
    color: Vector3(0.5, 0.8, 1.0),
    impactColor: Vector3(0.7, 0.9, 1.0),
    impactSize: 0.5,
    projectileSpeed: 12.0,
    projectileSize: 0.3,
    statusEffect: StatusEffect.slow,
    statusDuration: 3.0,
    statusStrength: 0.5,
    category: 'mage',
    damageSchool: DamageSchool.frost,
  );

  /// Blizzard - Channeled AoE ice storm
  static final blizzard = AbilityData(
    name: 'Blizzard',
    description: 'Summons ice storm that damages and slows enemies in area',
    type: AbilityType.channeled,
    damage: 8.0,
    cooldown: 20.0,
    duration: 4.0,
    range: 40.0,
    color: Vector3(0.6, 0.8, 1.0),
    impactColor: Vector3(0.8, 0.9, 1.0),
    impactSize: 0.3,
    aoeRadius: 5.0,
    dotTicks: 8,
    statusEffect: StatusEffect.slow,
    statusDuration: 1.0,
    castTime: 1.0,
    channelEffect: ChannelEffect.blizzard,
    category: 'mage',
    damageSchool: DamageSchool.frost,
  );

  /// Lightning Bolt - Fast high damage projectile
  static final lightningBolt = AbilityData(
    name: 'Lightning Bolt',
    description: 'Hurls a bolt of lightning at the target',
    type: AbilityType.ranged,
    damage: 30.0,
    cooldown: 4.0,
    range: 40.0,
    color: Vector3(1.0, 1.0, 0.3),
    impactColor: Vector3(1.0, 1.0, 0.5),
    impactSize: 0.6,
    projectileSpeed: 25.0,
    projectileSize: 0.2,
    castTime: 1.5,
    category: 'mage',
    damageSchool: DamageSchool.lightning,
  );

  /// Chain Lightning - Bounces between targets
  static final chainLightning = AbilityData(
    name: 'Chain Lightning',
    description: 'Lightning that jumps between multiple enemies',
    type: AbilityType.ranged,
    damage: 20.0,
    cooldown: 8.0,
    range: 40.0,
    color: Vector3(0.8, 0.8, 1.0),
    impactColor: Vector3(0.9, 0.9, 1.0),
    impactSize: 0.4,
    projectileSpeed: 30.0,
    projectileSize: 0.15,
    maxTargets: 4,
    category: 'mage',
    damageSchool: DamageSchool.lightning,
  );

  /// Meteor - Massive AoE fire damage
  static final meteor = AbilityData(
    name: 'Meteor',
    description: 'Calls down a meteor dealing massive AoE fire damage',
    type: AbilityType.aoe,
    damage: 50.0,
    cooldown: 30.0,
    duration: 0.5,
    range: 40.0,
    color: Vector3(1.0, 0.3, 0.0),
    impactColor: Vector3(1.0, 0.5, 0.2),
    impactSize: 2.0,
    aoeRadius: 4.0,
    statusEffect: StatusEffect.burn,
    statusDuration: 3.0,
    castTime: 2.0,
    category: 'mage',
    damageSchool: DamageSchool.fire,
  );

  /// Arcane Shield - Magic damage absorption
  static final arcaneShield = AbilityData(
    name: 'Arcane Shield',
    description: 'Creates a magical barrier absorbing damage',
    type: AbilityType.buff,
    cooldown: 25.0,
    duration: 8.0,
    color: Vector3(0.6, 0.3, 0.9),
    impactColor: Vector3(0.7, 0.4, 1.0),
    impactSize: 1.5,
    statusEffect: StatusEffect.shield,
    statusStrength: 40.0,
    category: 'mage',
    damageSchool: DamageSchool.arcane,
  );

  /// Teleport - Short range blink
  static final teleport = AbilityData(
    name: 'Teleport',
    description: 'Instantly teleports short distance',
    type: AbilityType.utility,
    cooldown: 15.0,
    range: 10.0,
    color: Vector3(0.5, 0.2, 0.8),
    impactColor: Vector3(0.6, 0.3, 0.9),
    impactSize: 0.8,
    category: 'mage',
  );

  // ==================== MELEE ABILITIES ====================

  /// Arcane Pulse — Close-range arcane energy burst
  static final arcanePulse = AbilityData(
    name: 'Arcane Pulse',
    description: 'Release a burst of arcane energy at close range',
    type: AbilityType.melee,
    damage: 15.0,
    cooldown: 1.0,
    range: 2.5,
    color: Vector3(0.6, 0.3, 0.9),
    impactColor: Vector3(0.7, 0.4, 1.0),
    impactSize: 0.5,
    category: 'mage',
    damageSchool: DamageSchool.arcane,
  );

  /// Rift Blade — Dimensional slash that slows
  static final riftBlade = AbilityData(
    name: 'Rift Blade',
    description: 'Slash through dimensional space, slowing the target as reality warps around them',
    type: AbilityType.melee,
    damage: 22.0,
    cooldown: 5.5,
    range: 3.0,
    color: Vector3(0.5, 0.2, 0.8),
    impactColor: Vector3(0.6, 0.3, 0.9),
    impactSize: 0.6,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.0,
    category: 'mage',
    damageSchool: DamageSchool.arcane,
  );

  /// Arcane Breach — Focused arcane strike that applies permanent vulnerability
  static final arcaneBreach = AbilityData(
    name: 'Arcane Breach',
    description: 'A focused arcane strike that permanently exposes the target to arcane damage.',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(0.6, 0.3, 0.9),
    impactColor: Vector3(0.7, 0.4, 1.0),
    impactSize: 0.6,
    category: 'mage',
    damageSchool: DamageSchool.arcane,
    appliesPermanentVulnerability: true,
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Arcane Focus — Activates chain-combo mode for mages.
  /// Land 7 consecutive mage strikes within 7 seconds to fire the chain combo.
  static final arcaneFocus = AbilityData(
    name: 'Arcane Focus',
    description: 'Focus arcane energy into every strike — activate chain-combo mode. '
        'Land 7 mage hits within 7 seconds to trigger a strength buff and arcane AoE burst.',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 10.0,
    range: 2.5,
    color: Vector3(0.55, 0.28, 0.88),
    impactColor: Vector3(0.68, 0.4, 1.0),
    impactSize: 0.6,
    manaColor: ManaColor.blue,
    manaCost: 20.0,
    damageSchool: DamageSchool.arcane,
    category: 'mage',
    enablesComboChain: true,
  );

  /// All mage abilities as a list
  static List<AbilityData> get all => [
    frostBolt, blizzard, lightningBolt, chainLightning,
    meteor, arcaneShield, teleport,
    arcanePulse, riftBlade, arcaneBreach, arcaneFocus,
  ];
}
