import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../data/abilities/ability_types.dart';

/// Manages user-created custom abilities that persist via SharedPreferences.
///
/// Stores complete AbilityData objects serialized as JSON (not sparse overrides,
/// since custom abilities have no base definition to override).
/// Follows the AbilityOverrideManager pattern (ChangeNotifier + SharedPreferences + global).
class CustomAbilityManager extends ChangeNotifier {
  static const String _storageKey = 'custom_abilities';

  /// All user-created abilities keyed by name
  Map<String, Map<String, dynamic>> _customAbilities = {};

  /// Get all custom abilities as AbilityData
  List<AbilityData> getAll() {
    return _customAbilities.values
        .map((json) => AbilityData.fromJson(json))
        .toList();
  }

  /// Get custom abilities filtered by category
  List<AbilityData> getByCategory(String category) {
    return getAll().where((a) => a.category == category).toList();
  }

  /// Find a custom ability by name (case-insensitive)
  AbilityData? findByName(String name) {
    final lowerName = name.toLowerCase();
    for (final json in _customAbilities.values) {
      if ((json['name'] as String).toLowerCase() == lowerName) {
        return AbilityData.fromJson(json);
      }
    }
    return null;
  }

  /// Check if a custom ability exists with this name
  bool hasAbility(String name) => _customAbilities.containsKey(name);

  /// Get all category names that have custom abilities
  Set<String> get usedCategories {
    return getAll().map((a) => a.category).toSet();
  }

  /// Add or update a custom ability
  void saveAbility(AbilityData ability) {
    _customAbilities[ability.name] = ability.toJson();
    notifyListeners();
    _save();
    print('[CustomAbilities] Saved custom ability: ${ability.name}');
  }

  /// Remove a custom ability by name
  void removeAbility(String name) {
    _customAbilities.remove(name);
    notifyListeners();
    _save();
    print('[CustomAbilities] Removed custom ability: $name');
  }

  /// Get the raw JSON for a custom ability (for editor pre-population)
  Map<String, dynamic>? getRawJson(String name) => _customAbilities[name];

  /// Total number of custom abilities
  int get count => _customAbilities.length;

  // ==================== PERSISTENCE ====================

  /// Load custom abilities from SharedPreferences
  Future<void> loadAbilities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        _customAbilities = decoded.map((key, value) =>
            MapEntry(key, Map<String, dynamic>.from(value as Map)));
        notifyListeners();
        print('[CustomAbilities] Loaded ${_customAbilities.length} custom abilities');
      }
    } catch (e) {
      print('[CustomAbilities] Failed to load: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_customAbilities));
    } catch (e) {
      print('[CustomAbilities] Failed to save: $e');
    }
  }
}

/// Global custom ability manager instance
CustomAbilityManager? globalCustomAbilityManager;
