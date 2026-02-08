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
  ];

  /// Get all abilities of a specific type
  static List<AbilityData> getByType(AbilityType type) {
    return potentialAbilities.where((a) => a.type == type).toList();
  }

  /// Find ability by name (case-insensitive), searching built-in and custom
  static AbilityData? findByName(String name) {
    final lowerName = name.toLowerCase();
    for (final ability in potentialAbilities) {
      if (ability.name.toLowerCase() == lowerName) {
        return ability;
      }
    }
    // Search custom abilities
    return globalCustomAbilityManager?.findByName(name);
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
  };
}
