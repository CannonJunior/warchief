import 'package:vector_math/vector_math.dart';
import '../../../rendering3d/mesh.dart';
import '../../../rendering3d/math/transform3d.dart';
import '../../../models/ally.dart';
import '../abilities/ability_types.dart';
import '../abilities/warrior_abilities.dart';
import '../abilities/rogue_abilities.dart';
import '../abilities/windwalker_abilities.dart';
import '../abilities/starbreaker_abilities.dart';
import '../abilities/stormheart_abilities.dart';
import '../abilities/healer_abilities.dart';
import '../abilities/necromancer_abilities.dart';
import '../abilities/nature_abilities.dart';
import '../abilities/greenseer_abilities.dart';
import '../abilities/mage_abilities.dart';
import '../abilities/spiritkin_abilities.dart';
import '../abilities/elemental_abilities.dart';

/// Builds Ally instances and ability lists for both duel factions.
///
/// Challengers are the 12 player classes; enemy faction are the 4 arena
/// monster archetypes. Both sides are represented as Ally objects and stored
/// in [GameState.duelCombatants] (never in [GameState.allies]).
class DuelDefinitions {
  DuelDefinitions._();

  // ==================== CONSTANTS ====================

  static const List<String> challengerClasses = [
    'warrior', 'rogue', 'windwalker', 'starbreaker', 'stormheart',
    'healer', 'necromancer', 'nature', 'greenseer', 'mage',
    'spiritkin', 'elemental',
  ];

  static const List<String> enemyFactionTypes = [
    'gnoll_marauder', 'satyr_hexblade', 'dryad_lifebinder', 'minotaur_bulwark',
  ];

  /// All selectable combatant types: player classes followed by enemy archetypes.
  /// Reason: both duel sides may now pick any type, enabling warrior-vs-warrior etc.
  static const List<String> allCombatantTypes = [
    ...challengerClasses,
    ...enemyFactionTypes,
  ];

  /// Human-readable display names for challenger classes.
  static const Map<String, String> challengerDisplayNames = {
    'warrior':     'Warrior',
    'rogue':       'Rogue',
    'windwalker':  'Windwalker',
    'starbreaker': 'Starbreaker',
    'stormheart':  'Stormheart',
    'healer':      'Healer',
    'necromancer': 'Necromancer',
    'nature':      'Nature',
    'greenseer':   'Greenseer',
    'mage':        'Mage',
    'spiritkin':   'Spiritkin',
    'elemental':   'Elemental',
  };

  /// Human-readable display names for enemy faction types.
  static const Map<String, String> enemyDisplayNames = {
    'gnoll_marauder':    'Gnoll Marauder',
    'satyr_hexblade':    'Satyr Hexblade',
    'dryad_lifebinder':  'Dryad Lifebinder',
    'minotaur_bulwark':  'Minotaur Bulwark',
  };

  /// Unified display names for all combatant types.
  static const Map<String, String> allDisplayNames = {
    ...challengerDisplayNames,
    ...enemyDisplayNames,
  };

  // ==================== CHALLENGER FACTORY ====================

  /// Create a challenger Ally at the given arena position.
  static Ally createChallenger(String className, Vector3 position, {
    double health = 100.0,
    double manaPool = 100.0,
  }) {
    final color = _challengerColor(className);
    final mesh = Mesh.cube(size: 0.8, color: color);
    final transform = Transform3d(
      position: position.clone(),
      rotation: Vector3(0, 0, 0),
      scale: Vector3(1, 1, 1),
    );
    final primary = _challengerPrimaryMana(className);
    final secondary = _challengerSecondaryMana(className);
    return Ally(
      mesh: mesh,
      transform: transform,
      rotation: 0.0,
      health: health,
      maxHealth: health,
      blueMana:   primary == ManaColor.blue   ? manaPool : 0,
      maxBlueMana:  primary == ManaColor.blue   ? manaPool : (secondary == ManaColor.blue   ? manaPool * 0.5 : 0),
      redMana:    primary == ManaColor.red    ? manaPool : 0,
      maxRedMana:   primary == ManaColor.red    ? manaPool : (secondary == ManaColor.red    ? manaPool * 0.5 : 0),
      whiteMana:  primary == ManaColor.white  ? manaPool : 0,
      maxWhiteMana: primary == ManaColor.white  ? manaPool : (secondary == ManaColor.white  ? manaPool * 0.5 : 0),
      greenMana:  primary == ManaColor.green  ? manaPool : 0,
      maxGreenMana: primary == ManaColor.green  ? manaPool : (secondary == ManaColor.green  ? manaPool * 0.5 : 0),
      blackMana:  primary == ManaColor.black  ? manaPool : 0,
      maxBlackMana: primary == ManaColor.black  ? manaPool : (secondary == ManaColor.black  ? manaPool * 0.5 : 0),
      abilityIndex: 0,
      moveSpeed: 3.0,
      name: challengerDisplayNames[className] ?? className,
    )..temporaryAttunements.addAll(_challengerAttunements(className));
  }

  /// Return the ability list the DuelSystem will cycle for a challenger.
  static List<AbilityData> getChallengerAbilities(String className) {
    switch (className) {
      case 'warrior':
        return [WarriorAbilities.gauntletJab, WarriorAbilities.shieldBash,
                WarriorAbilities.charge, WarriorAbilities.whirlwind];
      case 'rogue':
        return [RogueAbilities.backstab, RogueAbilities.poisonBlade,
                RogueAbilities.smokeBomb, RogueAbilities.fanOfKnives];
      case 'windwalker':
        return [WindWalkerAbilities.galeStep, WindWalkerAbilities.zephyrRoll,
                WindWalkerAbilities.tailwindRetreat];
      case 'starbreaker':
        return [StarbreakerAbilities.voidStrike, StarbreakerAbilities.soulRend];
      case 'stormheart':
        return [StormheartAbilities.thunderStrike, StormheartAbilities.stormBolt,
                StormheartAbilities.tempestFury, StormheartAbilities.lightningDash];
      case 'healer':
        return [HealerAbilities.holyLight, HealerAbilities.rejuvenation,
                HealerAbilities.circleOfHealing];
      case 'necromancer':
        return [NecromancerAbilities.lifeDrain, NecromancerAbilities.curseOfWeakness,
                NecromancerAbilities.soulRot];
      case 'nature':
        return [NatureAbilities.entanglingRoots, NatureAbilities.naturesWrath,
                NatureAbilities.thorns];
      case 'greenseer':
        return [GreenseerAbilities.thornLash, GreenseerAbilities.lifeThread,
                GreenseerAbilities.verdantEmbrace, GreenseerAbilities.spiritBloom];
      case 'mage':
        return [MageAbilities.frostBolt, MageAbilities.lightningBolt,
                MageAbilities.chainLightning];
      case 'spiritkin':
        return [SpiritkinAbilities.swipe, SpiritkinAbilities.feralStrike];
      case 'elemental':
        return [ElementalAbilities.iceLance, ElementalAbilities.flameWave,
                ElementalAbilities.earthquake];
      default:
        return [WarriorAbilities.gauntletJab];
    }
  }

  // ==================== ENEMY FACTION FACTORY ====================

  /// Create an enemy faction Ally at the given arena position.
  static Ally createEnemyCombatant(String enemyType, Vector3 position, {
    double health = 100.0,
    double manaPool = 60.0,
  }) {
    final color = _enemyColor(enemyType);
    final mesh = Mesh.cube(size: 0.8, color: color);
    final transform = Transform3d(
      position: position.clone(),
      rotation: Vector3(0, 180, 0),
      scale: Vector3(1, 1, 1),
    );
    final primary = _enemyPrimaryMana(enemyType);
    return Ally(
      mesh: mesh,
      transform: transform,
      rotation: 180.0,
      health: health,
      maxHealth: health,
      blueMana:   primary == ManaColor.blue   ? manaPool : 0,
      maxBlueMana:  manaPool,
      redMana:    primary == ManaColor.red    ? manaPool : 0,
      maxRedMana:   manaPool,
      whiteMana:  primary == ManaColor.white  ? manaPool : 0,
      maxWhiteMana: manaPool,
      greenMana:  primary == ManaColor.green  ? manaPool : 0,
      maxGreenMana: manaPool,
      blackMana:  0,
      maxBlackMana: 0,
      abilityIndex: 0,
      moveSpeed: 3.0,
      name: enemyDisplayNames[enemyType] ?? enemyType,
    )..temporaryAttunements.add(primary);
  }

  /// Return the ability list the DuelSystem will cycle for an enemy faction.
  static List<AbilityData> getEnemyAbilities(String enemyType) {
    switch (enemyType) {
      case 'gnoll_marauder':
        // Melee brawler: quick jab, shield bash, charge finisher
        return [WarriorAbilities.gauntletJab, WarriorAbilities.shieldBash,
                WarriorAbilities.charge];
      case 'satyr_hexblade':
        // Ranged caster: frost slow, fast bolt, chain AoE
        return [MageAbilities.frostBolt, MageAbilities.lightningBolt,
                MageAbilities.chainLightning];
      case 'dryad_lifebinder':
        // Healer: fast melee filler + two heals
        return [GreenseerAbilities.thornLash, GreenseerAbilities.lifeThread,
                GreenseerAbilities.verdantEmbrace];
      case 'minotaur_bulwark':
        // Tanky melee + shield
        return [StormheartAbilities.thunderStrike, StormheartAbilities.tempestFury,
                StormheartAbilities.eyeOfTheStorm];
      default:
        return [WarriorAbilities.gauntletJab];
    }
  }

  // ==================== UNIFIED FACTORY ====================

  /// Create a combatant Ally for any type on either duel side.
  ///
  /// Delegates to [createChallenger] or [createEnemyCombatant] based on type,
  /// then normalises the rotation so the unit faces inward regardless of which
  /// side it is placed on.  [facingLeft] = true → red side (rotation 180°).
  static Ally createCombatant(
    String type,
    Vector3 position, {
    required bool facingLeft,
    double health = 100.0,
    double manaPool = 100.0,
  }) {
    final Ally ally = enemyFactionTypes.contains(type)
        ? createEnemyCombatant(type, position, health: health, manaPool: manaPool)
        : createChallenger(type, position, health: health, manaPool: manaPool);
    // Override rotation: both factory methods have hardcoded defaults that are
    // only correct for their original side.
    final yaw = facingLeft ? 180.0 : 0.0;
    ally.transform.rotation.y = yaw;
    ally.rotation = yaw;
    return ally;
  }

  /// Return the ability list for any combatant type (class or enemy archetype).
  static List<AbilityData> getAbilities(String type) =>
      enemyFactionTypes.contains(type)
          ? getEnemyAbilities(type)
          : getChallengerAbilities(type);

  // ==================== PRIVATE HELPERS ====================

  static Vector3 _challengerColor(String className) {
    switch (className) {
      case 'warrior':     return Vector3(0.6, 0.6, 0.7);
      case 'rogue':       return Vector3(0.3, 0.3, 0.3);
      case 'windwalker':  return Vector3(0.85, 0.9, 1.0);
      case 'starbreaker': return Vector3(0.4, 0.0, 0.6);
      case 'stormheart':  return Vector3(0.5, 0.6, 1.0);
      case 'healer':      return Vector3(1.0, 1.0, 0.5);
      case 'necromancer': return Vector3(0.3, 0.0, 0.4);
      case 'nature':      return Vector3(0.3, 0.7, 0.2);
      case 'greenseer':   return Vector3(0.2, 0.6, 0.3);
      case 'mage':        return Vector3(0.4, 0.5, 1.0);
      case 'spiritkin':   return Vector3(0.5, 0.75, 0.25);
      case 'elemental':   return Vector3(0.8, 0.4, 0.1);
      default:            return Vector3(0.6, 0.6, 0.6);
    }
  }

  static Vector3 _enemyColor(String enemyType) {
    switch (enemyType) {
      case 'gnoll_marauder':   return Vector3(0.6, 0.45, 0.25);
      case 'satyr_hexblade':   return Vector3(0.3, 0.5, 0.7);
      case 'dryad_lifebinder': return Vector3(0.2, 0.5, 0.2);
      case 'minotaur_bulwark': return Vector3(0.5, 0.5, 0.3);
      default:                 return Vector3(0.5, 0.3, 0.3);
    }
  }

  static ManaColor _challengerPrimaryMana(String className) {
    switch (className) {
      case 'warrior':     return ManaColor.red;
      case 'rogue':       return ManaColor.red;
      case 'windwalker':  return ManaColor.white;
      case 'starbreaker': return ManaColor.black;
      case 'stormheart':  return ManaColor.white;
      case 'healer':      return ManaColor.blue;
      case 'necromancer': return ManaColor.black;
      case 'nature':      return ManaColor.green;
      case 'greenseer':   return ManaColor.green;
      case 'mage':        return ManaColor.blue;
      case 'spiritkin':   return ManaColor.green;
      case 'elemental':   return ManaColor.red;
      default:            return ManaColor.none;
    }
  }

  static ManaColor _challengerSecondaryMana(String className) {
    switch (className) {
      case 'starbreaker': return ManaColor.red;
      case 'stormheart':  return ManaColor.red;
      case 'spiritkin':   return ManaColor.blue;
      default:            return ManaColor.none;
    }
  }

  static Set<ManaColor> _challengerAttunements(String className) {
    final primary = _challengerPrimaryMana(className);
    final secondary = _challengerSecondaryMana(className);
    final set = <ManaColor>{};
    if (primary != ManaColor.none) set.add(primary);
    if (secondary != ManaColor.none) set.add(secondary);
    return set;
  }

  static ManaColor _enemyPrimaryMana(String enemyType) {
    switch (enemyType) {
      case 'gnoll_marauder':   return ManaColor.red;
      case 'satyr_hexblade':   return ManaColor.blue;
      case 'dryad_lifebinder': return ManaColor.green;
      case 'minotaur_bulwark': return ManaColor.white;
      default:                 return ManaColor.red;
    }
  }
}
