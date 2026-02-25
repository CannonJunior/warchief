import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Player abilities - Currently active abilities for the player character
class PlayerAbilities {
  PlayerAbilities._();

  // ============================================
  // INSTANT MELEE ABILITIES (No mana cost)
  // ============================================

  /// Player Ability 1: Sword (Melee Attack) - Instant, physical
  static final sword = AbilityData(
    name: 'Sword',
    description: 'A swift melee attack that damages nearby enemies',
    type: AbilityType.melee,
    damage: 35.0,
    cooldown: 1.0,
    duration: 0.3,
    range: 2.0,
    color: Vector3(0.7, 0.7, 0.8),
    impactColor: Vector3(0.8, 0.8, 0.9),
    impactSize: 0.5,
    // No mana cost - physical ability
  );

  /// Dash Attack (Dash Forward + Melee) - Instant, physical
  static final dashAttack = AbilityData(
    name: 'Dash Attack',
    description: 'Dash forward and strike enemies in your path',
    type: AbilityType.melee,
    damage: 40.0,
    cooldown: 6.0,
    duration: 0.4,
    range: 6.0,
    color: Vector3(0.9, 0.7, 0.3),
    impactColor: Vector3(1.0, 0.8, 0.4),
    impactSize: 0.7,
    knockbackForce: 3.0,
    category: 'warrior',
    // No mana cost - physical ability
  );

  // ============================================
  // WINDUP MELEE ABILITIES (Red mana cost)
  // ============================================

  /// Heavy Strike - Powerful melee with windup
  static final heavyStrike = AbilityData(
    name: 'Heavy Strike',
    description: 'Wind up a devastating blow. Reduced movement during charge. Costs 20 red mana.',
    type: AbilityType.melee,
    damage: 75.0,
    cooldown: 4.0,
    duration: 0.4,
    range: 2.5,
    hitRadius: 4.0,
    windupTime: 1.2,
    windupMovementSpeed: 0.3,
    color: Vector3(0.9, 0.3, 0.1),
    impactColor: Vector3(1.0, 0.4, 0.2),
    impactSize: 1.0,
    knockbackForce: 2.0,
    category: 'warrior',
    manaColor: ManaColor.red,
    manaCost: 20.0,
  );

  /// Whirlwind - Spinning AOE melee with windup
  static final whirlwind = AbilityData(
    name: 'Whirlwind',
    description: 'Spin with your weapon, hitting all nearby enemies. Costs 30 red mana.',
    type: AbilityType.melee,
    damage: 48.0,
    cooldown: 8.0,
    duration: 0.8,
    range: 3.0,
    hitRadius: 5.0,
    windupTime: 0.8,
    windupMovementSpeed: 0.2,
    aoeRadius: 5.0,
    maxTargets: 5,
    color: Vector3(0.6, 0.6, 0.7),
    impactColor: Vector3(0.7, 0.7, 0.8),
    impactSize: 0.6,
    category: 'warrior',
    manaColor: ManaColor.red,
    manaCost: 30.0,
  );

  /// Crushing Blow - Slow but massive damage
  static final crushingBlow = AbilityData(
    name: 'Crushing Blow',
    description: 'A slow, powerful overhead strike that crushes armor. Costs 45 red mana.',
    type: AbilityType.melee,
    damage: 110.0,
    cooldown: 10.0,
    duration: 0.5,
    range: 2.0,
    hitRadius: 3.5,
    windupTime: 2.0,
    windupMovementSpeed: 0.15,
    color: Vector3(0.5, 0.2, 0.1),
    impactColor: Vector3(0.7, 0.3, 0.1),
    impactSize: 1.2,
    knockbackForce: 4.0,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.0,
    category: 'warrior',
    manaColor: ManaColor.red,
    manaCost: 45.0,
  );

  // ============================================
  // INSTANT RANGED ABILITIES (Blue mana cost)
  // ============================================

  /// Fireball (Ranged Projectile) - Instant, magical
  static final fireball = AbilityData(
    name: 'Fireball',
    description: 'Launches a blazing projectile at enemies. Costs 15 mana.',
    type: AbilityType.ranged,
    damage: 12.0,
    cooldown: 2.5,
    range: 40.0,
    color: Vector3(1.0, 0.4, 0.0),
    impactColor: Vector3(1.0, 0.5, 0.0),
    impactSize: 0.6,
    projectileSpeed: 12.0,
    projectileSize: 0.35,
    manaColor: ManaColor.blue,
    manaCost: 15.0,
  );

  /// Ice Shard - Fast instant ranged attack
  static final iceShard = AbilityData(
    name: 'Ice Shard',
    description: 'Hurls a quick shard of ice at the target. Costs 10 mana.',
    type: AbilityType.ranged,
    damage: 8.0,
    cooldown: 1.8,
    range: 40.0,
    color: Vector3(0.5, 0.8, 1.0),
    impactColor: Vector3(0.6, 0.9, 1.0),
    impactSize: 0.4,
    projectileSpeed: 15.0,
    projectileSize: 0.25,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.0,
    statusStrength: 0.3,
    category: 'mage',
    manaColor: ManaColor.blue,
    manaCost: 10.0,
  );

  // ============================================
  // CAST-TIME RANGED ABILITIES (Blue mana cost)
  // ============================================

  /// Lightning Bolt - Moderate cast time, high damage
  static final lightningBolt = AbilityData(
    name: 'Lightning Bolt',
    description: 'Channel lightning energy. Must stand still. Costs 35 mana.',
    type: AbilityType.ranged,
    damage: 40.0,
    cooldown: 5.0,
    range: 40.0,
    castTime: 1.5,
    requiresStationary: true,
    color: Vector3(0.8, 0.8, 1.0),
    impactColor: Vector3(0.9, 0.9, 1.0),
    impactSize: 0.8,
    projectileSpeed: 25.0,
    projectileSize: 0.3,
    category: 'mage',
    manaColor: ManaColor.blue,
    manaCost: 35.0,
  );

  /// Pyroblast - Long cast time, massive damage
  static final pyroblast = AbilityData(
    name: 'Pyroblast',
    description: 'Conjure a massive fireball. Long cast. Costs 60 mana.',
    type: AbilityType.ranged,
    damage: 75.0,
    cooldown: 12.0,
    range: 40.0,
    castTime: 2.5,
    requiresStationary: true,
    color: Vector3(1.0, 0.3, 0.0),
    impactColor: Vector3(1.0, 0.5, 0.1),
    impactSize: 1.5,
    projectileSpeed: 8.0,
    projectileSize: 0.8,
    statusEffect: StatusEffect.burn,
    statusDuration: 4.0,
    dotTicks: 4,
    category: 'mage',
    manaColor: ManaColor.blue,
    manaCost: 60.0,
  );

  /// Arcane Missile - Short cast, moderate damage
  static final arcaneMissile = AbilityData(
    name: 'Arcane Missile',
    description: 'Focus arcane energy into a seeking missile. Costs 25 mana.',
    type: AbilityType.ranged,
    damage: 28.0,
    cooldown: 3.5,
    range: 40.0,
    castTime: 1.0,
    requiresStationary: true,
    color: Vector3(0.7, 0.3, 1.0),
    impactColor: Vector3(0.8, 0.4, 1.0),
    impactSize: 0.7,
    projectileSpeed: 18.0,
    projectileSize: 0.4,
    category: 'mage',
    manaColor: ManaColor.blue,
    manaCost: 25.0,
  );

  /// Frost Nova - Cast-time AOE around caster
  static final frostNova = AbilityData(
    name: 'Frost Nova',
    description: 'Channel frost energy, then release an icy blast. Costs 40 mana.',
    type: AbilityType.aoe,
    damage: 20.0,
    cooldown: 15.0,
    range: 0.0,
    aoeRadius: 8.0,
    castTime: 1.8,
    requiresStationary: true,
    maxTargets: 8,
    color: Vector3(0.4, 0.7, 1.0),
    impactColor: Vector3(0.5, 0.8, 1.0),
    impactSize: 0.5,
    statusEffect: StatusEffect.freeze,
    statusDuration: 3.0,
    category: 'mage',
    manaColor: ManaColor.blue,
    manaCost: 40.0,
  );

  // ============================================
  // HEALING ABILITIES (Blue mana cost)
  // ============================================

  /// Heal (Self Heal) - Magical healing
  static final heal = AbilityData(
    name: 'Heal',
    description: 'Restores health over time. Costs 20 mana.',
    type: AbilityType.heal,
    cooldown: 10.0,
    duration: 1.0,
    range: 40.0,
    healAmount: 20.0,
    color: Vector3(0.5, 1.0, 0.3),
    impactColor: Vector3(0.3, 1.0, 0.5),
    impactSize: 1.5,
    manaColor: ManaColor.blue,
    manaCost: 20.0,
  );

  /// Greater Heal - Cast time heal for more health
  static final greaterHeal = AbilityData(
    name: 'Greater Heal',
    description: 'Channel healing energy. Must stand still. Costs 45 mana.',
    type: AbilityType.heal,
    cooldown: 15.0,
    duration: 0.5,
    range: 40.0,
    healAmount: 50.0,
    castTime: 2.0,
    requiresStationary: true,
    color: Vector3(0.3, 1.0, 0.5),
    impactColor: Vector3(0.4, 1.0, 0.6),
    impactSize: 2.0,
    category: 'healer',
    manaColor: ManaColor.blue,
    manaCost: 45.0,
  );

  // ============================================
  // MAGICAL MELEE ABILITIES (Blue mana cost)
  // ============================================

  /// Arcane Strike - Melee attack infused with arcane energy
  static final arcaneStrike = AbilityData(
    name: 'Arcane Strike',
    description: 'Infuse your weapon with arcane energy. Costs 12 mana.',
    type: AbilityType.melee,
    damage: 42.0,
    cooldown: 2.0,
    duration: 0.3,
    range: 2.5,
    color: Vector3(0.6, 0.4, 1.0),
    impactColor: Vector3(0.7, 0.5, 1.0),
    impactSize: 0.6,
    category: 'spellblade',
    manaColor: ManaColor.blue,
    manaCost: 12.0,
  );

  /// Frost Strike - Melee attack with frost damage
  static final frostStrike = AbilityData(
    name: 'Frost Strike',
    description: 'Strike with frost-enchanted weapon. Costs 18 mana.',
    type: AbilityType.melee,
    damage: 30.0,
    cooldown: 3.0,
    duration: 0.35,
    range: 2.0,
    color: Vector3(0.4, 0.8, 1.0),
    impactColor: Vector3(0.5, 0.9, 1.0),
    impactSize: 0.5,
    statusEffect: StatusEffect.slow,
    statusDuration: 3.0,
    statusStrength: 0.4,
    category: 'spellblade',
    manaColor: ManaColor.blue,
    manaCost: 18.0,
  );

  /// Get ability by index
  static AbilityData getByIndex(int index) {
    switch (index) {
      case 0: return sword;
      case 1: return fireball;
      case 2: return heal;
      case 3: return dashAttack;
      case 4: return heavyStrike;
      case 5: return whirlwind;
      case 6: return crushingBlow;
      case 7: return iceShard;
      case 8: return lightningBolt;
      case 9: return pyroblast;
      case 10: return arcaneMissile;
      case 11: return frostNova;
      case 12: return greaterHeal;
      case 13: return arcaneStrike;
      case 14: return frostStrike;
      default: return sword;
    }
  }

  /// All player abilities as a list
  static List<AbilityData> get all => [
    // Physical melee (no mana)
    sword,
    dashAttack,
    heavyStrike,
    whirlwind,
    crushingBlow,
    // Magical ranged (blue mana)
    fireball,
    iceShard,
    lightningBolt,
    pyroblast,
    arcaneMissile,
    frostNova,
    // Healing (blue mana)
    heal,
    greaterHeal,
    // Magical melee (blue mana)
    arcaneStrike,
    frostStrike,
  ];

  /// Get all physical abilities (no mana cost)
  static List<AbilityData> get physicalAbilities =>
      all.where((a) => !a.requiresMana).toList();

  /// Get all magical abilities (require mana)
  static List<AbilityData> get magicalAbilities =>
      all.where((a) => a.requiresMana).toList();

  /// Get all blue mana abilities
  static List<AbilityData> get blueManaAbilities =>
      all.where((a) => a.requiresBlueMana).toList();

  /// Get all red mana abilities
  static List<AbilityData> get redManaAbilities =>
      all.where((a) => a.requiresRedMana).toList();

  /// Get all instant abilities (no cast/windup)
  static List<AbilityData> get instantAbilities =>
      all.where((a) => a.isInstant).toList();

  /// Get all abilities with cast time
  static List<AbilityData> get castTimeAbilities =>
      all.where((a) => a.hasCastTime).toList();

  /// Get all abilities with windup
  static List<AbilityData> get windupAbilities =>
      all.where((a) => a.hasWindup).toList();

  /// Get all melee abilities
  static List<AbilityData> get meleeAbilities =>
      all.where((a) => a.type == AbilityType.melee).toList();

  /// Get all ranged abilities
  static List<AbilityData> get rangedAbilities =>
      all.where((a) => a.type == AbilityType.ranged).toList();
}
