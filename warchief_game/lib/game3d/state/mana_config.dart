import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Manages mana configuration with JSON asset defaults and SharedPreferences overrides.
///
/// Architecture:
/// - JSON asset file (`assets/data/mana_config.json`) = shipped defaults (immutable)
/// - SharedPreferences = sparse user overrides (only changed fields)
/// - Runtime = overrides merged on top of defaults via dot-notation getters
///
/// Follows the same pattern as [AbilityOverrideManager].
class ManaConfig extends ChangeNotifier {
  static const String _storageKey = 'mana_config_overrides';
  static const String _assetPath = 'assets/data/mana_config.json';

  /// Defaults loaded from JSON asset file
  Map<String, dynamic> _defaults = {};

  /// Sparse user overrides stored in SharedPreferences
  /// Keys use dot-notation (e.g. 'red_mana.decay_rate')
  Map<String, dynamic> _overrides = {};

  // ==================== BLUE MANA GETTERS ====================

  double get maxBlueMana =>
      _resolve('blue_mana.max', 100.0);

  double get leyLineMaxRegenDistance =>
      _resolve('blue_mana.ley_line_max_regen_distance', 8.0);

  double get leyLineOptimalDistance =>
      _resolve('blue_mana.ley_line_optimal_distance', 2.0);

  double get baseRegenRate =>
      _resolve('blue_mana.base_regen_rate', 0.0);

  double get maxRegenRate =>
      _resolve('blue_mana.max_regen_rate', 15.0);

  double get powerNodeRadius =>
      _resolve('blue_mana.power_node_radius', 3.0);

  double get powerNodeFraction =>
      _resolve('blue_mana.power_node_fraction', 0.33);

  // ==================== RED MANA GETTERS ====================

  double get maxRedMana =>
      _resolve('red_mana.max', 100.0);

  double get manaPerDamage =>
      _resolve('red_mana.mana_per_damage', 0.2);

  double get redManaDecayRate =>
      _resolve('red_mana.decay_rate', 3.0);

  double get redManaDecayDelay =>
      _resolve('red_mana.decay_delay', 5.0);

  // ==================== INITIALIZATION ====================

  /// Load defaults from JSON asset, then overrides from SharedPreferences.
  Future<void> initialize() async {
    await _loadDefaults();
    await _loadOverrides();
  }

  /// Load default values from the bundled JSON asset file.
  Future<void> _loadDefaults() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _defaults = jsonDecode(jsonString) as Map<String, dynamic>;
      print('[ManaConfig] Loaded defaults from $_assetPath');
    } catch (e) {
      print('[ManaConfig] Failed to load defaults: $e (using hardcoded fallbacks)');
      _defaults = {};
    }
  }

  /// Load user overrides from SharedPreferences.
  Future<void> _loadOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        _overrides = Map<String, dynamic>.from(
          jsonDecode(json) as Map<String, dynamic>,
        );
        notifyListeners();
        print('[ManaConfig] Loaded ${_overrides.length} overrides');
      }
    } catch (e) {
      print('[ManaConfig] Failed to load overrides: $e');
    }
  }

  /// Save overrides to SharedPreferences.
  Future<void> _saveOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_overrides));
    } catch (e) {
      print('[ManaConfig] Failed to save overrides: $e');
    }
  }

  // ==================== OVERRIDE MANAGEMENT ====================

  /// Set a single override value using dot-notation key.
  ///
  /// Example: `setOverride('red_mana.decay_rate', 10.0)`
  void setOverride(String key, dynamic value) {
    _overrides[key] = value;
    notifyListeners();
    _saveOverrides();
  }

  /// Remove a single override (reverts to default).
  void clearOverride(String key) {
    _overrides.remove(key);
    notifyListeners();
    _saveOverrides();
  }

  /// Remove all overrides (revert everything to defaults).
  void clearAllOverrides() {
    _overrides.clear();
    notifyListeners();
    _saveOverrides();
  }

  /// Check if a specific key has an override.
  bool hasOverride(String key) => _overrides.containsKey(key);

  /// Get the full overrides map (for future editor UI).
  Map<String, dynamic> get overrides => Map.unmodifiable(_overrides);

  /// Get the default value for a dot-notation key.
  dynamic getDefault(String key) => _resolveFromNestedMap(_defaults, key);

  // ==================== RESOLUTION HELPERS ====================

  /// Resolve a value: override -> default -> hardcoded fallback.
  double _resolve(String dotKey, double fallback) {
    // Check override first
    if (_overrides.containsKey(dotKey)) {
      final val = _overrides[dotKey];
      if (val is num) return val.toDouble();
    }

    // Check JSON defaults
    final defaultVal = _resolveFromNestedMap(_defaults, dotKey);
    if (defaultVal is num) return defaultVal.toDouble();

    // Hardcoded fallback
    return fallback;
  }

  /// Resolve a dot-notation key from a nested map.
  ///
  /// Example: `_resolveFromNestedMap(map, 'red_mana.decay_rate')`
  /// looks up `map['red_mana']['decay_rate']`.
  static dynamic _resolveFromNestedMap(Map<String, dynamic> map, String dotKey) {
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

/// Global mana config instance (initialized in game3d_widget.dart)
ManaConfig? globalManaConfig;
