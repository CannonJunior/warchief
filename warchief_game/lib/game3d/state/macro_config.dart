import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Manages macro system configuration with JSON asset defaults and
/// SharedPreferences overrides.
///
/// Follows the same pattern as [ManaConfig]: JSON asset file provides
/// shipped defaults, user overrides stored sparsely in SharedPreferences.
class MacroConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/macro_config.json';
  static const String _storageKey = 'macro_config_overrides';

  /// Defaults loaded from JSON asset file
  Map<String, dynamic> _defaults = {};

  /// Sparse user overrides stored in SharedPreferences
  Map<String, dynamic> _overrides = {};

  // ==================== GCD GETTERS ====================

  double get gcdBase => _resolve('gcd.base', 1.5);
  double get gcdMinimum => _resolve('gcd.minimum', 0.75);

  // ==================== ALERT GETTERS ====================

  double get lowManaThreshold => _resolve('alerts.lowManaThreshold', 0.2);
  double get lowHealthThreshold => _resolve('alerts.lowHealthThreshold', 0.3);
  double get alertCooldownSeconds =>
      _resolve('alerts.alertCooldownSeconds', 5.0);
  double get underAttackDamageWindow =>
      _resolve('alerts.underAttackDamageWindow', 3.0);

  // ==================== EXECUTION GETTERS ====================

  int get maxActiveMacros => _resolveInt('execution.maxActiveMacros', 5);
  bool get retryOnCooldown =>
      _resolveBool('execution.retryOnCooldown', true);
  double get retryIntervalSeconds =>
      _resolve('execution.retryIntervalSeconds', 0.25);
  bool get skipOnConditionFail =>
      _resolveBool('execution.skipOnConditionFail', false);

  // ==================== INITIALIZATION ====================

  /// Load defaults from JSON asset, then overrides from SharedPreferences.
  Future<void> initialize() async {
    await _loadDefaults();
    await _loadOverrides();
  }

  Future<void> _loadDefaults() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _defaults = jsonDecode(jsonString) as Map<String, dynamic>;
      notifyListeners();
      print('[MacroConfig] Loaded defaults from $_assetPath');
    } catch (e) {
      print('[MacroConfig] Failed to load defaults: $e (using fallbacks)');
      _defaults = {};
    }
  }

  Future<void> _loadOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        _overrides = Map<String, dynamic>.from(
          jsonDecode(json) as Map<String, dynamic>,
        );
        notifyListeners();
        print('[MacroConfig] Loaded ${_overrides.length} overrides');
      }
    } catch (e) {
      print('[MacroConfig] Failed to load overrides: $e');
    }
  }

  Future<void> _saveOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_overrides));
    } catch (e) {
      print('[MacroConfig] Failed to save overrides: $e');
    }
  }

  // ==================== OVERRIDE MANAGEMENT ====================

  void setOverride(String key, dynamic value) {
    _overrides[key] = value;
    notifyListeners();
    _saveOverrides();
  }

  void clearOverride(String key) {
    _overrides.remove(key);
    notifyListeners();
    _saveOverrides();
  }

  void clearAllOverrides() {
    _overrides.clear();
    notifyListeners();
    _saveOverrides();
  }

  bool hasOverride(String key) => _overrides.containsKey(key);

  Map<String, dynamic> get overrides => Map.unmodifiable(_overrides);

  dynamic getDefault(String key) => _resolveFromNestedMap(_defaults, key);

  // ==================== RESOLUTION HELPERS ====================

  /// Resolve a double: override -> default -> hardcoded fallback.
  double _resolve(String dotKey, double fallback) {
    if (_overrides.containsKey(dotKey)) {
      final val = _overrides[dotKey];
      if (val is num) return val.toDouble();
    }
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toDouble();
    return fallback;
  }

  /// Resolve a bool: override -> default -> hardcoded fallback.
  bool _resolveBool(String dotKey, bool fallback) {
    if (_overrides.containsKey(dotKey)) {
      final val = _overrides[dotKey];
      if (val is bool) return val;
    }
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is bool) return val;
    return fallback;
  }

  /// Resolve an int: override -> default -> hardcoded fallback.
  int _resolveInt(String dotKey, int fallback) {
    if (_overrides.containsKey(dotKey)) {
      final val = _overrides[dotKey];
      if (val is num) return val.toInt();
    }
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toInt();
    return fallback;
  }

  /// Resolve a dot-notation key from a nested map.
  static dynamic _resolveFromNestedMap(
      Map<String, dynamic> map, String dotKey) {
    final parts = dotKey.split('.');
    dynamic current = map;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}

/// Global macro config instance (initialized in game3d_widget.dart)
MacroConfig? globalMacroConfig;
