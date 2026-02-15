import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Manages macro system configuration with JSON asset defaults.
///
/// Follows the same pattern as [WindConfig]: JSON asset file provides
/// shipped defaults, with dot-notation getters for all values.
class MacroConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/macro_config.json';

  /// Defaults loaded from JSON asset file
  Map<String, dynamic> _defaults = {};

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

  /// Load defaults from JSON asset.
  Future<void> initialize() async {
    await _loadDefaults();
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

  // ==================== RESOLUTION HELPERS ====================

  /// Resolve a double value from nested map with fallback.
  double _resolve(String dotKey, double fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toDouble();
    return fallback;
  }

  /// Resolve a bool value from nested map with fallback.
  bool _resolveBool(String dotKey, bool fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is bool) return val;
    return fallback;
  }

  /// Resolve an int value from nested map with fallback.
  int _resolveInt(String dotKey, int fallback) {
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
