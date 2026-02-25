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

  // ==================== MELEE COMBO ABILITIES ====================
  // Combo: Gauntlet Jab -> Iron Sweep -> Rending Chains -> Warcry Uppercut -> Execution Strike

  /// Gauntlet Jab — Fast combo starter, short cooldown
  static final gauntletJab = AbilityData(
    name: 'Gauntlet Jab',
    description: 'Quick armored fist jab — fast combo starter',
    type: AbilityType.melee,
    damage: 12.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(0.7, 0.7, 0.7),
    impactColor: Vector3(0.8, 0.8, 0.8),
    impactSize: 0.4,
    category: 'warrior',
  );

  /// Iron Sweep — Low sweep that slows the target
  static final ironSweep = AbilityData(
    name: 'Iron Sweep',
    description: 'Low sweeping kick with iron greaves, slowing the target',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 1.0,
    range: 2.5,
    color: Vector3(0.6, 0.6, 0.65),
    impactColor: Vector3(0.7, 0.7, 0.75),
    impactSize: 0.5,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.0,
    category: 'warrior',
  );

  /// Rending Chains — Chain whip with extended reach and bleed DoT
  static final rendingChains = AbilityData(
    name: 'Rending Chains',
    description: 'Lash out with spiked chains, rending flesh and causing bleed',
    type: AbilityType.melee,
    damage: 22.0,
    cooldown: 6.0,
    range: 3.5,
    color: Vector3(0.5, 0.5, 0.55),
    impactColor: Vector3(0.8, 0.3, 0.2),
    impactSize: 0.6,
    statusEffect: StatusEffect.bleed,
    statusDuration: 4.0,
    dotTicks: 2,
    category: 'warrior',
  );

  /// Warcry Uppercut — Launcher with stun and knockback, moves forward
  static final warcryUppercut = AbilityData(
    name: 'Warcry Uppercut',
    description: 'Bellowing war cry followed by a devastating uppercut that launches the target',
    type: AbilityType.melee,
    damage: 28.0,
    cooldown: 7.0,
    range: 2.0,
    color: Vector3(0.9, 0.7, 0.3),
    impactColor: Vector3(1.0, 0.8, 0.4),
    impactSize: 0.7,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.0,
    knockbackForce: 2.0,
    category: 'warrior',
  );

  /// Execution Strike — Heavy windup combo finisher
  static final executionStrike = AbilityData(
    name: 'Execution Strike',
    description: 'Wind up a devastating overhead strike to finish the combo',
    type: AbilityType.melee,
    damage: 45.0,
    cooldown: 10.0,
    range: 2.5,
    color: Vector3(0.8, 0.2, 0.2),
    impactColor: Vector3(1.0, 0.3, 0.1),
    impactSize: 0.9,
    windupTime: 0.8,
    windupMovementSpeed: 0.3,
    category: 'warrior',
  );

  /// Sunder Armor — Crushing strike that permanently exposes physical weakness
  static final sunderArmor = AbilityData(
    name: 'Sunder Armor',
    description: 'A crushing strike that permanently exposes the target\'s weakness to physical damage.',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(0.7, 0.5, 0.3),
    impactColor: Vector3(0.8, 0.6, 0.4),
    impactSize: 0.6,
    category: 'warrior',
    appliesPermanentVulnerability: true,
  );

  /// All warrior abilities as a list
  static List<AbilityData> get all => [
    shieldBash, whirlwind, charge, taunt, fortify,
    gauntletJab, ironSweep, rendingChains, warcryUppercut, executionStrike,
    sunderArmor,
  ];
}
