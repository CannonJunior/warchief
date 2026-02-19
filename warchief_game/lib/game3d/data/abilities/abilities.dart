/// Abilities Data Module
///
/// This file exports all ability-related types and data.
/// Import this single file to access all abilities.
///
/// File Structure (for token-efficient editing):
/// - ability_types.dart     - Enums and AbilityData class (~90 lines)
/// - player_abilities.dart  - Player abilities (4 abilities, ~75 lines)
/// - monster_abilities.dart - Monster abilities (3 abilities, ~55 lines)
/// - ally_abilities.dart    - Ally abilities (3 abilities, ~55 lines)
/// - warrior_abilities.dart - Warrior category (5 abilities, ~90 lines)
/// - mage_abilities.dart    - Mage category (7 abilities, ~130 lines)
/// - rogue_abilities.dart   - Rogue category (5 abilities, ~90 lines)
/// - healer_abilities.dart  - Healer category (5 abilities, ~90 lines)
/// - nature_abilities.dart  - Nature category (3 abilities, ~55 lines)
/// - necromancer_abilities.dart - Necromancer category (4 abilities, ~75 lines)
/// - elemental_abilities.dart - Elemental category (3 abilities, ~65 lines)
/// - utility_abilities.dart - Utility category (2 abilities, ~45 lines)
library abilities;

// Export all ability files
export 'ability_types.dart';
export 'player_abilities.dart';
export 'monster_abilities.dart';
export 'ally_abilities.dart';
export 'warrior_abilities.dart';
export 'mage_abilities.dart';
export 'rogue_abilities.dart';
export 'healer_abilities.dart';
export 'nature_abilities.dart';
export 'necromancer_abilities.dart';
export 'elemental_abilities.dart';
export 'utility_abilities.dart';
export 'windwalker_abilities.dart';
export 'spiritkin_abilities.dart';
export 'stormheart_abilities.dart';
export 'greenseer_abilities.dart';
export 'ability_balance.dart';

import 'ability_types.dart';
import '../../state/custom_ability_manager.dart';
import 'player_abilities.dart';
import 'monster_abilities.dart';
import 'ally_abilities.dart';
import 'warrior_abilities.dart';
import 'mage_abilities.dart';
import 'rogue_abilities.dart';
import 'healer_abilities.dart';
import 'nature_abilities.dart';
import 'necromancer_abilities.dart';
import 'elemental_abilities.dart';
import 'utility_abilities.dart';
import 'windwalker_abilities.dart';
import 'spiritkin_abilities.dart';
import 'stormheart_abilities.dart';
import 'greenseer_abilities.dart';

/// Ability Registry - Central access point for all abilities
///
/// Provides methods to query abilities by category, type, or name.
/// Use this for agentic access and runtime ability lookups.
class AbilityRegistry {
  AbilityRegistry._();

  /// All ability categories
  static const List<String> categories = [
    'player',
    'monster',
    'ally',
    'warrior',
    'mage',
    'rogue',
    'healer',
    'nature',
    'necromancer',
    'elemental',
    'utility',
    'windwalker',
    'spiritkin',
    'stormheart',
    'greenseer',
  ];

  /// Get all abilities for a category
  static List<AbilityData> getByCategory(String category) {
    switch (category) {
      case 'player': return PlayerAbilities.all;
      case 'monster': return MonsterAbilities.all;
      case 'ally': return AllyAbilities.all;
      case 'warrior': return WarriorAbilities.all;
      case 'mage': return MageAbilities.all;
      case 'rogue': return RogueAbilities.all;
      case 'healer': return HealerAbilities.all;
      case 'nature': return NatureAbilities.all;
      case 'necromancer': return NecromancerAbilities.all;
      case 'elemental': return ElementalAbilities.all;
      case 'utility': return UtilityAbilities.all;
      case 'windwalker': return WindWalkerAbilities.all;
      case 'spiritkin': return SpiritkinAbilities.all;
      case 'stormheart': return StormheartAbilities.all;
      case 'greenseer': return GreenseerAbilities.all;
      default: return [];
    }
  }

  /// Get all potential (future) abilities
  static List<AbilityData> get potentialAbilities => [
    ...WarriorAbilities.all,
    ...MageAbilities.all,
    ...RogueAbilities.all,
    ...HealerAbilities.all,
    ...NatureAbilities.all,
    ...NecromancerAbilities.all,
    ...ElementalAbilities.all,
    ...UtilityAbilities.all,
    ...WindWalkerAbilities.all,
    ...SpiritkinAbilities.all,
    ...StormheartAbilities.all,
    ...GreenseerAbilities.all,
  ];

  /// Get all abilities of a specific type
  static List<AbilityData> getByType(AbilityType type) {
    return potentialAbilities.where((a) => a.type == type).toList();
  }

  /// Cache for findByName to avoid repeated linear scans.
  static final Map<String, AbilityData?> _nameCache = {};

  /// Clear the name cache (call after custom abilities change).
  static void clearNameCache() => _nameCache.clear();

  /// Find ability by name (case-insensitive), searching built-in and custom.
  /// Results are cached for O(1) subsequent lookups.
  static AbilityData? findByName(String name) {
    if (_nameCache.containsKey(name)) return _nameCache[name];

    final lowerName = name.toLowerCase();
    // Search player abilities first (Sword, Fireball, Heal, Dash Attack)
    for (final ability in PlayerAbilities.all) {
      if (ability.name.toLowerCase() == lowerName) {
        _nameCache[name] = ability;
        return ability;
      }
    }
    // Search all potential abilities (warrior, mage, rogue, etc.)
    for (final ability in potentialAbilities) {
      if (ability.name.toLowerCase() == lowerName) {
        _nameCache[name] = ability;
        return ability;
      }
    }
    // Search custom abilities
    final custom = globalCustomAbilityManager?.findByName(name);
    _nameCache[name] = custom;
    return custom;
  }

  /// Get count of abilities per category
  static Map<String, int> get categoryCounts => {
    'player': PlayerAbilities.all.length,
    'monster': MonsterAbilities.all.length,
    'ally': AllyAbilities.all.length,
    'warrior': WarriorAbilities.all.length,
    'mage': MageAbilities.all.length,
    'rogue': RogueAbilities.all.length,
    'healer': HealerAbilities.all.length,
    'nature': NatureAbilities.all.length,
    'necromancer': NecromancerAbilities.all.length,
    'elemental': ElementalAbilities.all.length,
    'utility': UtilityAbilities.all.length,
    'windwalker': WindWalkerAbilities.all.length,
    'spiritkin': SpiritkinAbilities.all.length,
    'stormheart': StormheartAbilities.all.length,
    'greenseer': GreenseerAbilities.all.length,
  };
}
