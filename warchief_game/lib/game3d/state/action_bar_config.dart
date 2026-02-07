import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/abilities/abilities.dart';
import 'ability_override_manager.dart';

/// Configuration for the player's action bar slots
///
/// Tracks which abilities are assigned to which action bar slots (1-4).
/// Supports persistence via SharedPreferences.
class ActionBarConfig extends ChangeNotifier {
  /// Current ability assignments by slot index (0-3)
  /// Stores the ability name as the identifier
  List<String> _slotAssignments = [
    'Sword',       // Slot 1 (key 1)
    'Fireball',    // Slot 2 (key 2)
    'Heal',        // Slot 3 (key 3)
    'Dash Attack', // Slot 4 (key 4)
  ];

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

  /// Get ability by name from all available abilities
  AbilityData _getAbilityByName(String name) {
    // Search through all ability categories
    final allAbilities = [
      ...PlayerAbilities.all,
      ...WarriorAbilities.all,
      ...MageAbilities.all,
      ...RogueAbilities.all,
      ...HealerAbilities.all,
      ...NatureAbilities.all,
      ...NecromancerAbilities.all,
      ...ElementalAbilities.all,
      ...UtilityAbilities.all,
    ];

    for (final ability in allAbilities) {
      if (ability.name == name) {
        // Apply any user overrides to the ability
        return globalAbilityOverrideManager?.getEffectiveAbility(ability) ?? ability;
      }
    }

    // Default fallback
    return PlayerAbilities.sword;
  }

  /// Save configuration to SharedPreferences
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('action_bar_config', jsonEncode(_slotAssignments));
    } catch (e) {
      print('[ActionBarConfig] Failed to save: $e');
    }
  }

  /// Load configuration from SharedPreferences
  Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('action_bar_config');
      if (configJson != null) {
        final List<dynamic> loaded = jsonDecode(configJson);
        _slotAssignments = loaded.cast<String>();
        notifyListeners();
      }
    } catch (e) {
      print('[ActionBarConfig] Failed to load: $e');
    }
  }

  /// Reset to default configuration
  void resetToDefaults() {
    _slotAssignments = [
      'Sword',
      'Fireball',
      'Heal',
      'Dash Attack',
    ];
    notifyListeners();
    _saveConfig();
  }
}

/// Global action bar config instance
ActionBarConfig? globalActionBarConfig;
