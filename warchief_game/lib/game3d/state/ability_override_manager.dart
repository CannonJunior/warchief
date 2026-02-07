import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../data/abilities/ability_types.dart';

/// Manages ability overrides that persist via SharedPreferences
///
/// Stores only changed fields (sparse map) for each ability.
/// The original static ability definitions serve as defaults and are never modified.
/// Overrides are merged at lookup time via AbilityData.applyOverrides.
///
/// Follows the ActionBarConfig pattern (ChangeNotifier + SharedPreferences + global).
class AbilityOverrideManager extends ChangeNotifier {
  static const String _storageKey = 'ability_overrides';

  /// Sparse override maps keyed by ability name
  /// Each value is a Map<String, dynamic> containing only changed fields
  Map<String, Map<String, dynamic>> _overrides = {};

  /// Returns the effective ability with overrides applied
  ///
  /// If no overrides exist for this ability, returns the original unchanged.
  AbilityData getEffectiveAbility(AbilityData original) {
    final overrideMap = _overrides[original.name];
    if (overrideMap == null || overrideMap.isEmpty) return original;
    return original.applyOverrides(overrideMap);
  }

  /// Save overrides for a specific ability
  ///
  /// Only stores fields that differ from the original.
  /// [abilityName] is the ability's unique name identifier.
  /// [fields] contains only the changed field key-value pairs.
  void setOverrides(String abilityName, Map<String, dynamic> fields) {
    if (fields.isEmpty) {
      _overrides.remove(abilityName);
    } else {
      _overrides[abilityName] = Map<String, dynamic>.from(fields);
    }
    notifyListeners();
    _saveOverrides();
  }

  /// Clear all overrides for a specific ability (restore defaults)
  void clearOverrides(String abilityName) {
    _overrides.remove(abilityName);
    notifyListeners();
    _saveOverrides();
  }

  /// Check if an ability has any overrides
  bool hasOverrides(String abilityName) {
    final overrideMap = _overrides[abilityName];
    return overrideMap != null && overrideMap.isNotEmpty;
  }

  /// Get the current override map for an ability (for pre-populating editor)
  Map<String, dynamic>? getOverrides(String abilityName) {
    return _overrides[abilityName];
  }

  /// Load overrides from SharedPreferences
  Future<void> loadOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final Map<String, dynamic> decoded = jsonDecode(json);
        _overrides = decoded.map((key, value) =>
            MapEntry(key, Map<String, dynamic>.from(value as Map)));
        notifyListeners();
        print('[AbilityOverrides] Loaded ${_overrides.length} ability overrides');
      }
    } catch (e) {
      print('[AbilityOverrides] Failed to load: $e');
    }
  }

  /// Save overrides to SharedPreferences
  Future<void> _saveOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_overrides));
    } catch (e) {
      print('[AbilityOverrides] Failed to save: $e');
    }
  }
}

/// Global ability override manager instance
AbilityOverrideManager? globalAbilityOverrideManager;
