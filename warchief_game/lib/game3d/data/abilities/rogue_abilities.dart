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

  /// All rogue abilities as a list
  static List<AbilityData> get all => [
    backstab, poisonBlade, smokeBomb, fanOfKnives, shadowStep,
  ];
}
