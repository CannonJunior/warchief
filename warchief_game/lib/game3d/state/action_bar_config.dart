import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/abilities/abilities.dart';
import 'ability_override_manager.dart';
import 'custom_ability_manager.dart';

/// Configuration for a character's action bar slots
///
/// Tracks which abilities are assigned to which action bar slots (1-10).
/// Supports per-character persistence via SharedPreferences.
class ActionBarConfig extends ChangeNotifier {
  /// Character index this config belongs to (0 = Warchief, 1+ = ally)
  final int _characterIndex;

  /// Current ability assignments by slot index (0-9)
  /// Stores the ability name as the identifier
  List<String> _slotAssignments = [
    'Sword',       // Slot 1 (key 1)
    'Fireball',    // Slot 2 (key 2)
    'Heal',        // Slot 3 (key 3)
    'Dash Attack', // Slot 4 (key 4)
    'Sword',       // Slot 5 (key 5)
    'Sword',       // Slot 6 (key 6)
    'Sword',       // Slot 7 (key 7)
    'Sword',       // Slot 8 (key 8)
    'Sword',       // Slot 9 (key 9)
    'Sword',       // Slot 10 (key 0)
  ];

  ActionBarConfig({int characterIndex = 0}) : _characterIndex = characterIndex;

  /// Get persistence key for this character index.
  /// 0 = Warchief (uses existing 'action_bar_config' for backward compatibility)
  /// 1+ = ally (uses 'action_bar_config_ally_0', etc.)
  String get _storageKey {
    if (_characterIndex == 0) return 'action_bar_config';
    return 'action_bar_config_ally_${_characterIndex - 1}';
  }

  /// Get the ability assigned to a slot (0-indexed)
  String getSlotAbility(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slotAssignments.length) {
      return 'Sword'; // Default fallback
    }
    return _slotAssignments[slotIndex];
  }

  /// Get the AbilityData for a slot
  AbilityData getSlotAbilityData(int slotIndex) {
    final abilityName = getSlotAbility(slotIndex);
    return _getAbilityByName(abilityName);
  }

  /// Set the ability for a slot (0-indexed)
  void setSlotAbility(int slotIndex, String abilityName) {
    if (slotIndex < 0 || slotIndex >= _slotAssignments.length) return;

    _slotAssignments[slotIndex] = abilityName;
    notifyListeners();
    _saveConfig();
  }

  /// Get all slot assignments
  List<String> get slotAssignments => List.unmodifiable(_slotAssignments);

  /// Get ability color for a slot (for UI display)
  Color getSlotColor(int slotIndex) {
    final ability = getSlotAbilityData(slotIndex);
    // Convert Vector3 color to Flutter Color
    return Color.fromRGBO(
      (ability.color.x * 255).round(),
      (ability.color.y * 255).round(),
      (ability.color.z * 255).round(),
      1.0,
    );
  }

  /// Get ability by name from all available abilities (built-in + custom)
  AbilityData _getAbilityByName(String name) {
    // Search through all built-in ability categories
    final allAbilities = [
      ...PlayerAbilities.all,
      ...WarriorAbilities.all,
      ...MageAbilities.all,
      ...RogueAbilities.all,
      ...NecromancerAbilities.all,
      ...ElementalAbilities.all,
      ...UtilityAbilities.all,
      ...WindWalkerAbilities.all,
      ...SpiritkinAbilities.all,
      ...StormheartAbilities.all,
      ...GreenseerAbilities.all,
      ...HealerAbilities.all,
      ...NatureAbilities.all,
    ];

    for (final ability in allAbilities) {
      if (ability.name == name) {
        // Apply any user overrides to the ability
        return globalAbilityOverrideManager?.getEffectiveAbility(ability) ?? ability;
      }
    }

    // Search custom abilities
    final custom = globalCustomAbilityManager?.findByName(name);
    if (custom != null) return custom;

    // Default fallback
    return PlayerAbilities.sword;
  }

  /// Save configuration to SharedPreferences
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_slotAssignments));
    } catch (e) {
      print('[ActionBarConfig] Failed to save ($_storageKey): $e');
    }
  }

  /// Load configuration from SharedPreferences
  Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_storageKey);
      if (configJson != null) {
        final List<dynamic> loaded = jsonDecode(configJson);
        final assignments = loaded.cast<String>();
        // Pad to 10 slots if saved config has fewer (upgrade from older versions)
        while (assignments.length < 10) {
          assignments.add('Sword');
        }
        _slotAssignments = assignments;
        notifyListeners();
      }
    } catch (e) {
      print('[ActionBarConfig] Failed to load ($_storageKey): $e');
    }
  }

  /// Reset to default configuration
  void resetToDefaults() {
    _slotAssignments = [
      'Sword',
      'Fireball',
      'Heal',
      'Dash Attack',
      'Sword',
      'Sword',
      'Sword',
      'Sword',
      'Sword',
      'Sword',
    ];
    notifyListeners();
    _saveConfig();
  }
}

/// Manages per-character action bar configs
///
/// Each party member (Warchief + allies) gets their own ActionBarConfig
/// with independent persistence via SharedPreferences.
class ActionBarConfigManager {
  final Map<int, ActionBarConfig> _configs = {};
  int _activeIndex = 0;

  /// Get the config for the currently active character
  ActionBarConfig get activeConfig => getConfig(_activeIndex);

  /// Get or create the config for a specific character index
  ActionBarConfig getConfig(int characterIndex) {
    return _configs.putIfAbsent(characterIndex, () {
      final config = ActionBarConfig(characterIndex: characterIndex);
      config.loadConfig();
      return config;
    });
  }

  /// Set the active character index and return the active config
  void setActiveIndex(int index) {
    _activeIndex = index;
  }
}

/// Global action bar config manager instance
ActionBarConfigManager? globalActionBarConfigManager;

/// Global action bar config instance (backward-compatible alias)
/// Returns the active character's config from the manager, or null
ActionBarConfig? get globalActionBarConfig =>
    globalActionBarConfigManager?.activeConfig;
