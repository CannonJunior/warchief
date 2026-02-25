import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Rogue/Assassin abilities - Stealth, poison, and burst damage
class RogueAbilities {
  RogueAbilities._();

  /// Backstab - High damage from behind
  static final backstab = AbilityData(
    name: 'Backstab',
    description: 'Devastating attack from behind dealing extra damage',
    type: AbilityType.melee,
    damage: 55.0,
    cooldown: 6.0,
    duration: 0.2,
    range: 1.5,
    color: Vector3(0.3, 0.3, 0.3),
    impactColor: Vector3(0.8, 0.2, 0.2),
    impactSize: 0.5,
    category: 'rogue',
  );

  /// Poison Blade - Attack that applies poison DoT
  static final poisonBlade = AbilityData(
    name: 'Poison Blade',
    description: 'Coats weapon in poison, dealing damage over time',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 8.0,
    duration: 0.25,
    range: 2.0,
    color: Vector3(0.2, 0.8, 0.2),
    impactColor: Vector3(0.3, 0.9, 0.3),
    impactSize: 0.4,
    statusEffect: StatusEffect.poison,
    statusDuration: 6.0,
    dotTicks: 6,
    category: 'rogue',
  );

  /// Smoke Bomb - AoE blind effect
  static final smokeBomb = AbilityData(
    name: 'Smoke Bomb',
    description: 'Throws smoke bomb blinding enemies in area',
    type: AbilityType.debuff,
    cooldown: 18.0,
    duration: 3.0,
    range: 15.0,
    color: Vector3(0.4, 0.4, 0.4),
    impactColor: Vector3(0.5, 0.5, 0.5),
    impactSize: 1.5,
    aoeRadius: 4.0,
    statusEffect: StatusEffect.blind,
    statusDuration: 3.0,
    category: 'rogue',
  );

  /// Fan of Knives - Throws daggers in all directions
  static final fanOfKnives = AbilityData(
    name: 'Fan of Knives',
    description: 'Throws daggers in all directions hitting nearby enemies',
    type: AbilityType.aoe,
    damage: 22.0,
    cooldown: 10.0,
    duration: 0.3,
    range: 6.0,
    color: Vector3(0.7, 0.7, 0.7),
    impactColor: Vector3(0.8, 0.8, 0.8),
    impactSize: 0.3,
    aoeRadius: 6.0,
    maxTargets: 8,
    category: 'rogue',
  );

  /// Shadow Step - Teleport behind target
  static final shadowStep = AbilityData(
    name: 'Shadow Step',
    description: 'Teleports behind the target enemy',
    type: AbilityType.utility,
    cooldown: 20.0,
    range: 40.0,
    color: Vector3(0.2, 0.1, 0.3),
    impactColor: Vector3(0.3, 0.2, 0.4),
    impactSize: 0.6,
    category: 'rogue',
  );

  // ==================== MELEE COMBO ABILITIES ====================
  // Combo: Shiv -> Shadowfang Rake -> Shadow Spike -> Umbral Lunge -> Death Mark

  /// Shiv — Fastest attack, combo starter
  static final shiv = AbilityData(
    name: 'Shiv',
    description: 'Lightning-quick dagger stab — the fastest combo opener',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 1.0,
    range: 1.5,
    color: Vector3(0.4, 0.4, 0.45),
    impactColor: Vector3(0.6, 0.6, 0.65),
    impactSize: 0.3,
    category: 'rogue',
  );

  /// Shadowfang Rake — Claw swipe with bleed DoT
  static final shadowfangRake = AbilityData(
    name: 'Shadowfang Rake',
    description: 'Shadow-infused claw rake that leaves deep bleeding wounds',
    type: AbilityType.melee,
    damage: 16.0,
    cooldown: 1.0,
    range: 2.5,
    color: Vector3(0.3, 0.2, 0.4),
    impactColor: Vector3(0.6, 0.1, 0.2),
    impactSize: 0.5,
    statusEffect: StatusEffect.bleed,
    statusDuration: 4.0,
    dotTicks: 2,
    category: 'rogue',
  );

  /// Shadow Spike — Shadow-infused piercing stab
  static final shadowSpike = AbilityData(
    name: 'Shadow Spike',
    description: 'Thrust a shadow-wreathed blade through the target',
    type: AbilityType.melee,
    damage: 25.0,
    cooldown: 5.0,
    range: 2.0,
    color: Vector3(0.2, 0.1, 0.3),
    impactColor: Vector3(0.4, 0.2, 0.5),
    impactSize: 0.5,
    piercing: true,
    category: 'rogue',
  );

  /// Umbral Lunge — Gap-closer dash with extended range
  static final umbralLunge = AbilityData(
    name: 'Umbral Lunge',
    description: 'Dash through shadow to close the gap on a distant target',
    type: AbilityType.melee,
    damage: 20.0,
    cooldown: 6.0,
    range: 6.0,
    color: Vector3(0.15, 0.05, 0.25),
    impactColor: Vector3(0.3, 0.15, 0.4),
    impactSize: 0.5,
    category: 'rogue',
  );

  /// Death Mark — Combo finisher with weakness debuff
  static final deathMark = AbilityData(
    name: 'Death Mark',
    description: 'Mark the target for death, reducing their damage output',
    type: AbilityType.melee,
    damage: 35.0,
    cooldown: 8.0,
    range: 2.0,
    color: Vector3(0.1, 0.0, 0.15),
    impactColor: Vector3(0.4, 0.0, 0.3),
    impactSize: 0.6,
    statusEffect: StatusEffect.weakness,
    statusStrength: 0.85,
    statusDuration: 4.0,
    category: 'rogue',
  );

  /// Expose Weakness — Precise strike that permanently reveals physical vulnerability
  static final exposeWeakness = AbilityData(
    name: 'Expose Weakness',
    description: 'A precise strike that permanently reveals the target\'s vulnerability to physical damage.',
    type: AbilityType.melee,
    damage: 8.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(0.5, 0.3, 0.5),
    impactColor: Vector3(0.6, 0.4, 0.6),
    impactSize: 0.5,
    category: 'rogue',
    appliesPermanentVulnerability: true,
  );

  /// All rogue abilities as a list
  static List<AbilityData> get all => [
    backstab, poisonBlade, smokeBomb, fanOfKnives, shadowStep,
    shiv, shadowfangRake, shadowSpike, umbralLunge, deathMark,
    exposeWeakness,
  ];
}
