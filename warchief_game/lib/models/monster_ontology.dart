/// Monster Ontology - Defines the type system for all monsters in the game
///
/// This ontology provides:
/// - Monster archetypes (DPS, Support, Healer, Tank)
/// - Monster types with complete definitions
/// - Monster Power rating system for difficulty estimation
/// - Asset/model references
/// - Ability definitions

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

/// Monster archetype - the combat role a monster fulfills
enum MonsterArchetype {
  dps,      // High damage, low survivability
  support,  // Buffs allies, debuffs enemies
  healer,   // Restores health to allies
  tank,     // High survivability, protects allies
  boss,     // Special boss-type monsters
}

/// Monster faction - grouping for AI coordination
enum MonsterFaction {
  undead,     // Skeletons, zombies, liches
  goblinoid,  // Goblins, hobgoblins, bugbears
  orcish,     // Orcs, ogres
  cultist,    // Human cultists, dark priests
  demonic,    // Demons, imps
  beast,      // Animals, magical beasts
  elemental,  // Fire, ice, earth elementals
  boss,       // Unique boss monsters
}

/// Monster size category - affects hitbox, model scale, and some abilities
enum MonsterSize {
  tiny,    // 0.4x scale - imps, small creatures
  small,   // 0.6x scale - goblins
  medium,  // 0.8x scale - orcs, humans
  large,   // 1.2x scale - ogres, champions
  huge,    // 1.6x scale - bosses
  colossal, // 2.0x+ scale - raid bosses
}

/// Ability target type
enum AbilityTargetType {
  self,           // Targets self only
  singleEnemy,    // Single enemy target
  singleAlly,     // Single ally target
  allEnemies,     // All enemies in range
  allAllies,      // All allies in range
  areaOfEffect,   // Area damage/effect
}

/// Monster ability definition
class MonsterAbilityDefinition {
  final String id;
  final String name;
  final String description;
  final double damage;          // Base damage (0 for non-damage abilities)
  final double healing;         // Base healing (0 for non-healing abilities)
  final double cooldown;        // Seconds between uses
  final double range;           // Max range in world units
  final double castTime;        // Time to cast (0 for instant)
  final AbilityTargetType targetType;
  final Color effectColor;      // Visual effect color
  final double? buffAmount;     // For buff/debuff abilities
  final double? buffDuration;   // Duration of buff/debuff
  final bool isProjectile;      // Whether it fires a projectile
  final double? projectileSpeed;

  const MonsterAbilityDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.damage = 0,
    this.healing = 0,
    required this.cooldown,
    required this.range,
    this.castTime = 0,
    required this.targetType,
    required this.effectColor,
    this.buffAmount,
    this.buffDuration,
    this.isProjectile = false,
    this.projectileSpeed,
  });
}

/// Complete monster type definition
class MonsterDefinition {
  final String id;
  final String name;
  final String description;
  final MonsterArchetype archetype;
  final MonsterFaction faction;
  final MonsterSize size;

  // Stats
  final double baseHealth;
  final double baseDamage;
  final double moveSpeed;
  final double attackRange;
  final double aggroRange;      // Range at which monster notices player

  // Monster Power rating (difficulty scale 1-10)
  final int monsterPower;

  // Visual properties
  final Vector3 modelColor;     // Primary color for cube model
  final Vector3 accentColor;    // Secondary/accent color
  final double modelScale;      // Multiplier on base size
  final String? modelAsset;     // Future: path to 3D model asset
  final String portraitEmoji;   // Fallback emoji for UI

  // Abilities
  final List<MonsterAbilityDefinition> abilities;

  // AI behavior modifiers
  final double aggressiveness;  // 0-1, how likely to attack vs flee
  final double groupTendency;   // 0-1, how likely to stay with allies
  final bool canFlee;           // Whether monster will flee at low health
  final double fleeHealthThreshold; // Health % to trigger flee

  const MonsterDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.archetype,
    required this.faction,
    required this.size,
    required this.baseHealth,
    required this.baseDamage,
    required this.moveSpeed,
    required this.attackRange,
    required this.aggroRange,
    required this.monsterPower,
    required this.modelColor,
    required this.accentColor,
    required this.modelScale,
    this.modelAsset,
    required this.portraitEmoji,
    required this.abilities,
    this.aggressiveness = 0.7,
    this.groupTendency = 0.5,
    this.canFlee = true,
    this.fleeHealthThreshold = 0.2,
  });

  /// Calculate effective stats based on Monster Power
  double get effectiveHealth => baseHealth * (1 + (monsterPower - 1) * 0.15);
  double get effectiveDamage => baseDamage * (1 + (monsterPower - 1) * 0.1);

  /// Get model scale based on size category
  double get effectiveScale {
    double baseScale;
    switch (size) {
      case MonsterSize.tiny:
        baseScale = 0.4;
        break;
      case MonsterSize.small:
        baseScale = 0.6;
        break;
      case MonsterSize.medium:
        baseScale = 0.8;
        break;
      case MonsterSize.large:
        baseScale = 1.2;
        break;
      case MonsterSize.huge:
        baseScale = 1.6;
        break;
      case MonsterSize.colossal:
        baseScale = 2.0;
        break;
    }
    return baseScale * modelScale;
  }
}

/// Monster Power Calculator
///
/// The Monster Power (MP) rating estimates difficulty on a linear scale 1-10:
/// - MP 1-2: Trivial enemies (critters, basic minions)
/// - MP 3-4: Easy enemies (standard DPS minions)
/// - MP 5-6: Moderate enemies (support, healers)
/// - MP 7-8: Challenging enemies (tanks, elite minions)
/// - MP 9-10: Boss-tier enemies
///
/// Factors considered:
/// - Base health pool
/// - Damage output
/// - Healing/support capabilities
/// - Defensive abilities
/// - AI complexity
class MonsterPowerCalculator {
  /// Calculate Monster Power from stats
  static int calculatePower({
    required double health,
    required double damage,
    required double healing,
    required bool hasTaunt,
    required bool hasBuffs,
    required bool hasDebuffs,
    required int abilityCount,
  }) {
    double power = 1.0;

    // Health contribution (20-100 HP maps to ~1-3 power)
    power += (health / 50.0).clamp(0.0, 3.0);

    // Damage contribution (5-25 damage maps to ~0.5-2.5 power)
    power += (damage / 10.0).clamp(0.0, 2.5);

    // Healing adds significant power
    if (healing > 0) {
      power += 1.5 + (healing / 20.0).clamp(0.0, 1.0);
    }

    // Special abilities add power
    if (hasTaunt) power += 1.0;
    if (hasBuffs) power += 0.75;
    if (hasDebuffs) power += 0.5;

    // More abilities = higher power
    power += (abilityCount - 1) * 0.25;

    return power.round().clamp(1, 10);
  }

  /// Get difficulty description from Monster Power
  static String getDifficultyLabel(int monsterPower) {
    if (monsterPower <= 2) return 'Trivial';
    if (monsterPower <= 4) return 'Easy';
    if (monsterPower <= 6) return 'Moderate';
    if (monsterPower <= 8) return 'Challenging';
    return 'Boss';
  }

  /// Get suggested party size for a group of monsters
  static int suggestedPartySize(List<int> monsterPowers) {
    final totalPower = monsterPowers.fold(0, (sum, mp) => sum + mp);
    // Assume average player + ally power is ~8
    return (totalPower / 8.0).ceil().clamp(1, 5);
  }
}
