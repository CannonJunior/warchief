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
    category: 'mage',
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

  /// All mage abilities as a list
  static List<AbilityData> get all => [
    frostBolt, blizzard, lightningBolt, chainLightning,
    meteor, arcaneShield, teleport,
  ];
}
