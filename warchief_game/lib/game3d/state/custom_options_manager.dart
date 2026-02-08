import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Manages custom dropdown options and effect descriptions for the ability editor.
///
/// Stores user-created dropdown values (categories, types, mana colors, effects)
/// via SharedPreferences. Loads default effect descriptions from a JSON asset.
/// Follows the AbilityOverrideManager pattern (ChangeNotifier + SharedPreferences).
class CustomOptionsManager extends ChangeNotifier {
  static const String _storageKey = 'custom_dropdown_options';
  static const String _effectDescAssetPath = 'assets/data/effect_descriptions.json';

  /// Custom values added by the user, keyed by dropdown name
  Map<String, List<String>> _customOptions = {
    'category': [],
    'type': [],
    'manaColor': [],
    'statusEffect': [],
  };

  /// Default effect descriptions loaded from JSON asset
  Map<String, String> _effectDescriptions = {};

  // ==================== CUSTOM OPTIONS ====================

  /// Get custom values for a dropdown
  List<String> getCustomValues(String dropdownKey) =>
      List.unmodifiable(_customOptions[dropdownKey] ?? []);

  /// Add a custom value to a dropdown
  void addCustomValue(String dropdownKey, String value) {
    final list = _customOptions[dropdownKey] ?? [];
    if (!list.contains(value)) {
      list.add(value);
      _customOptions[dropdownKey] = list;
      notifyListeners();
      _saveOptions();
      print('[CustomOptions] Added "$value" to $dropdownKey');
    }
  }

  /// Remove a custom value from a dropdown
  void removeCustomValue(String dropdownKey, String value) {
    _customOptions[dropdownKey]?.remove(value);
    notifyListeners();
    _saveOptions();
  }

  /// Check if a value is a user-created custom option
  bool isCustomValue(String dropdownKey, String value) =>
      _customOptions[dropdownKey]?.contains(value) ?? false;

  // ==================== EFFECT DESCRIPTIONS ====================

  /// Get default effect description for an ability
  String getEffectDescription(String abilityName) =>
      _effectDescriptions[abilityName] ?? '';

  /// Check if an ability has a default effect description
  bool hasEffectDescription(String abilityName) =>
      _effectDescriptions.containsKey(abilityName);

  // ==================== INITIALIZATION ====================

  /// Load custom options from SharedPreferences and effect descriptions from JSON
  Future<void> initialize() async {
    await _loadOptions();
    await _loadEffectDescriptions();
  }

  Future<void> _loadOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        _customOptions = decoded.map((key, value) =>
            MapEntry(key, List<String>.from(value as List)));
        notifyListeners();
        print('[CustomOptions] Loaded custom options');
      }
    } catch (e) {
      print('[CustomOptions] Failed to load: $e');
    }
  }

  Future<void> _loadEffectDescriptions() async {
    try {
      final jsonString = await rootBundle.loadString(_effectDescAssetPath);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      _effectDescriptions = decoded.map((key, value) =>
          MapEntry(key, value as String));
      print('[CustomOptions] Loaded ${_effectDescriptions.length} effect descriptions');
    } catch (e) {
      print('[CustomOptions] Failed to load effect descriptions: $e');
    }
  }

  Future<void> _saveOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_customOptions));
    } catch (e) {
      print('[CustomOptions] Failed to save: $e');
    }
  }

  // ==================== SECONDARY EFFECTS INFO ====================

  /// Get secondary effects text for a dropdown type (shown in "+ Add New" dialog)
  static String getSecondaryEffectsInfo(String dropdownKey) {
    switch (dropdownKey) {
      case 'category':
        return 'Adding a new category will:\n'
            '  1. Create a new section in the Abilities Codex\n'
            '  2. Assign a display color (white by default)\n'
            '  3. Allow abilities to be grouped under this class\n\n'
            'This takes effect immediately.';
      case 'type':
        return 'Adding a new ability type will require:\n'
            '  1. Icon mapping in the Abilities Codex\n'
            '  2. Type badge color assignment\n'
            '  3. Combat system delivery mechanics\n'
            '  4. Animation and visual effect handling\n\n'
            'The type will appear in the dropdown but\n'
            'game behavior requires code integration.';
      case 'manaColor':
        return 'Adding a new mana color will require:\n'
            '  1. A new mana pool in GameState\n'
            '  2. Mana bar UI display\n'
            '  3. Regeneration/generation mechanics\n'
            '  4. Mana config entries in mana_config.json\n\n'
            'The color will appear in the dropdown but\n'
            'a functional mana pool requires code updates.';
      case 'statusEffect':
        return 'Adding a new status effect will require:\n'
            '  1. Combat system apply/remove logic\n'
            '  2. Visual indicator on affected units\n'
            '  3. Duration and strength tick handling\n'
            '  4. Interaction rules with other effects\n\n'
            'The effect will appear in the dropdown but\n'
            'in-game behavior requires code integration.';
      default:
        return 'Custom value will be added to the dropdown.';
    }
  }
}

/// Global custom options manager instance
CustomOptionsManager? globalCustomOptionsManager;
