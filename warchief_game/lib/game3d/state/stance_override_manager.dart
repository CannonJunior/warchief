import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../data/stances/stance_types.dart';

/// Manages stance overrides that persist via SharedPreferences.
///
/// Stores only changed fields (sparse map) for each stance.
/// The original JSON-loaded stance definitions serve as defaults and are
/// never modified. Overrides are merged at lookup time via
/// StanceData.applyOverrides.
///
/// Follows the AbilityOverrideManager pattern
/// (ChangeNotifier + SharedPreferences + global).
class StanceOverrideManager extends ChangeNotifier {
  static const String _storageKey = 'stance_overrides';

  /// Sparse override maps keyed by stance ID name (e.g. 'drunkenMaster')
  /// Each value is a Map<String, dynamic> containing only changed fields.
  Map<String, Map<String, dynamic>> _overrides = {};

  /// Returns the effective stance with overrides applied.
  ///
  /// If no overrides exist for this stance, returns the original unchanged.
  StanceData getEffectiveStance(StanceData original) {
    final overrideMap = _overrides[original.id.name];
    if (overrideMap == null || overrideMap.isEmpty) return original;
    return original.applyOverrides(overrideMap);
  }

  /// Save overrides for a specific stance.
  ///
  /// Only stores fields that differ from the original.
  /// [stanceIdName] is the stance's StanceId enum name (e.g. 'drunkenMaster').
  /// [fields] contains only the changed field key-value pairs.
  void setOverrides(String stanceIdName, Map<String, dynamic> fields) {
    if (fields.isEmpty) {
      _overrides.remove(stanceIdName);
    } else {
      _overrides[stanceIdName] = Map<String, dynamic>.from(fields);
    }
    notifyListeners();
    _saveOverrides();
  }

  /// Clear all overrides for a specific stance (restore defaults).
  void clearOverrides(String stanceIdName) {
    _overrides.remove(stanceIdName);
    notifyListeners();
    _saveOverrides();
  }

  /// Check if a stance has any overrides.
  bool hasOverrides(String stanceIdName) {
    final overrideMap = _overrides[stanceIdName];
    return overrideMap != null && overrideMap.isNotEmpty;
  }

  /// Get the current override map for a stance (for pre-populating editor).
  Map<String, dynamic>? getOverrides(String stanceIdName) {
    return _overrides[stanceIdName];
  }

  /// Load overrides from SharedPreferences.
  Future<void> loadOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final Map<String, dynamic> decoded = jsonDecode(json);
        _overrides = decoded.map((key, value) =>
            MapEntry(key, Map<String, dynamic>.from(value as Map)));
        notifyListeners();
        print('[StanceOverrides] Loaded ${_overrides.length} stance overrides');
      }
    } catch (e) {
      print('[StanceOverrides] Failed to load: $e');
    }
  }

  /// Save overrides to SharedPreferences.
  Future<void> _saveOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_overrides));
    } catch (e) {
      print('[StanceOverrides] Failed to save: $e');
    }
  }
}

/// Global stance override manager instance.
StanceOverrideManager? globalStanceOverrideManager;
