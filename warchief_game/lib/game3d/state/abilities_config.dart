/// Abilities Configuration - Backward Compatibility Layer
///
/// This file maintains backward compatibility with existing code.
/// New code should import from 'package:warchief_game/game3d/data/abilities/abilities.dart'
///
/// File structure has been split for token efficiency:
/// - Edit player abilities: data/abilities/player_abilities.dart (~75 lines)
/// - Edit monster abilities: data/abilities/monster_abilities.dart (~55 lines)
/// - Edit ally abilities: data/abilities/ally_abilities.dart (~55 lines)
/// - Edit warrior abilities: data/abilities/warrior_abilities.dart (~90 lines)
/// - Edit mage abilities: data/abilities/mage_abilities.dart (~130 lines)
/// - Edit rogue abilities: data/abilities/rogue_abilities.dart (~90 lines)
/// - Edit healer abilities: data/abilities/healer_abilities.dart (~90 lines)
/// - Add types/enums: data/abilities/ability_types.dart (~90 lines)
library abilities_config;

// Re-export all types for backward compatibility
export '../data/abilities/abilities.dart';

import '../data/abilities/abilities.dart';

/// Legacy AbilitiesConfig class - Provides backward-compatible access
///
/// @deprecated Use PlayerAbilities, MonsterAbilities, AllyAbilities directly
class AbilitiesConfig {
  AbilitiesConfig._();

  // ==================== PLAYER ABILITIES (Legacy Access) ====================

  static AbilityData get playerSword => PlayerAbilities.sword;
  static AbilityData get playerFireball => PlayerAbilities.fireball;
  static AbilityData get playerHeal => PlayerAbilities.heal;
  static AbilityData get playerDashAttack => PlayerAbilities.dashAttack;

  // ==================== MONSTER ABILITIES (Legacy Access) ====================

  static AbilityData get monsterDarkStrike => MonsterAbilities.darkStrike;
  static AbilityData get monsterShadowBolt => MonsterAbilities.shadowBolt;
  static AbilityData get monsterDarkHeal => MonsterAbilities.darkHeal;

  // ==================== ALLY ABILITIES (Legacy Access) ====================

  static AbilityData get allySword => AllyAbilities.sword;
  static AbilityData get allyFireball => AllyAbilities.fireball;
  static AbilityData get allyHeal => AllyAbilities.heal;

  // ==================== WARRIOR ABILITIES (Legacy Access) ====================

  static AbilityData get shieldBash => WarriorAbilities.shieldBash;
  static AbilityData get whirlwind => WarriorAbilities.whirlwind;
  static AbilityData get charge => WarriorAbilities.charge;
  static AbilityData get taunt => WarriorAbilities.taunt;
  static AbilityData get fortify => WarriorAbilities.fortify;

  // ==================== MAGE ABILITIES (Legacy Access) ====================

  static AbilityData get frostBolt => MageAbilities.frostBolt;
  static AbilityData get blizzard => MageAbilities.blizzard;
  static AbilityData get lightningBolt => MageAbilities.lightningBolt;
  static AbilityData get chainLightning => MageAbilities.chainLightning;
  static AbilityData get meteor => MageAbilities.meteor;
  static AbilityData get arcaneShield => MageAbilities.arcaneShield;
  static AbilityData get teleport => MageAbilities.teleport;

  // ==================== ROGUE ABILITIES (Legacy Access) ====================

  static AbilityData get backstab => RogueAbilities.backstab;
  static AbilityData get poisonBlade => RogueAbilities.poisonBlade;
  static AbilityData get smokeBomb => RogueAbilities.smokeBomb;
  static AbilityData get fanOfKnives => RogueAbilities.fanOfKnives;
  static AbilityData get shadowStep => RogueAbilities.shadowStep;

  // ==================== HEALER ABILITIES (Legacy Access) ====================

  static AbilityData get holyLight => HealerAbilities.holyLight;
  static AbilityData get rejuvenation => HealerAbilities.rejuvenation;
  static AbilityData get circleOfHealing => HealerAbilities.circleOfHealing;
  static AbilityData get blessingOfStrength => HealerAbilities.blessingOfStrength;
  static AbilityData get purify => HealerAbilities.purify;

  // ==================== NATURE ABILITIES (Legacy Access) ====================

  static AbilityData get entanglingRoots => NatureAbilities.entanglingRoots;
  static AbilityData get thorns => NatureAbilities.thorns;
  static AbilityData get naturesWrath => NatureAbilities.naturesWrath;

  // ==================== NECROMANCER ABILITIES (Legacy Access) ====================

  static AbilityData get lifeDrain => NecromancerAbilities.lifeDrain;
  static AbilityData get curseOfWeakness => NecromancerAbilities.curseOfWeakness;
  static AbilityData get fear => NecromancerAbilities.fear;
  static AbilityData get summonSkeleton => NecromancerAbilities.summonSkeleton;

  // ==================== ELEMENTAL ABILITIES (Legacy Access) ====================

  static AbilityData get iceLance => ElementalAbilities.iceLance;
  static AbilityData get flameWave => ElementalAbilities.flameWave;
  static AbilityData get earthquake => ElementalAbilities.earthquake;

  // ==================== UTILITY ABILITIES (Legacy Access) ====================

  static AbilityData get sprint => UtilityAbilities.sprint;
  static AbilityData get battleShout => UtilityAbilities.battleShout;

  // ==================== HELPER METHODS ====================

  /// Get player ability by index (0=Sword, 1=Fireball, 2=Heal, 3=DashAttack)
  static AbilityData getPlayerAbility(int index) => PlayerAbilities.getByIndex(index);

  /// Get monster ability by index (0=DarkStrike, 1=ShadowBolt, 2=DarkHeal)
  static AbilityData getMonsterAbility(int index) => MonsterAbilities.getByIndex(index);

  /// Get ally ability by index (0=Sword, 1=Fireball, 2=Heal)
  static AbilityData getAllyAbility(int index) => AllyAbilities.getByIndex(index);

  /// List of all player abilities for UI display
  static List<AbilityData> get playerAbilities => PlayerAbilities.all;

  /// List of all monster abilities
  static List<AbilityData> get monsterAbilities => MonsterAbilities.all;

  /// List of all ally abilities
  static List<AbilityData> get allyAbilities => AllyAbilities.all;

  /// All potential future abilities (not yet assigned)
  static List<AbilityData> get potentialAbilities => AbilityRegistry.potentialAbilities;

  /// Get abilities by category
  static List<AbilityData> getAbilitiesByCategory(String category) =>
      AbilityRegistry.getByCategory(category);

  /// All ability categories
  static List<String> get categories => AbilityRegistry.categories;
}
