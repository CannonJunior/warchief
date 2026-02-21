import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Manages building configuration with JSON asset defaults and
/// SharedPreferences overrides.
///
/// Architecture:
/// - JSON asset file (`assets/data/building_config.json`) = shipped defaults
/// - SharedPreferences = sparse user overrides (only changed fields)
/// - Runtime = overrides merged on top of defaults
///
/// Follows the same pattern as [ManaConfig] and [WindConfig].
class BuildingConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/building_config.json';
  static const String _storageKey = 'building_config_overrides';

  /// Defaults loaded from JSON asset file.
  Map<String, dynamic> _defaults = {};

  /// Sparse user overrides stored in SharedPreferences.
  Map<String, dynamic> _overrides = {};

  // ==================== TOP-LEVEL GETTERS ====================

  /// Range within which player can interact with a building.
  double get interactionRange => _resolve('interaction_range', 5.0);

  /// Grid size for snapping building placement.
  double get placementGridSize => _resolve('placement_grid_size', 1.0);

  /// Bonus radius for ley line proximity effects on buildings.
  double get leyLineBonusRadius => _resolve('ley_line_bonus_radius', 10.0);

  /// Multiplier applied to building auras when near a ley line.
  double get leyLineBonusMultiplier =>
      _resolve('ley_line_bonus_multiplier', 1.5);

  // ==================== BUILDING TYPE ACCESS ====================

  /// Get the raw JSON definition for a building type by ID.
  ///
  /// Returns null if the building type is not found.
  Map<String, dynamic>? getBuildingType(String typeId) {
    final types = _defaults['building_types'];
    if (types is Map<String, dynamic> && types.containsKey(typeId)) {
      return Map<String, dynamic>.from(types[typeId] as Map);
    }
    return null;
  }

  /// Get all available building type IDs.
  List<String> get buildingTypeIds {
    final types = _defaults['building_types'];
    if (types is Map<String, dynamic>) {
      return types.keys.toList();
    }
    return [];
  }

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
      print('[BuildingConfig] Loaded defaults from $_assetPath');
    } catch (e) {
      print(
          '[BuildingConfig] Failed to load defaults: $e (using hardcoded fallbacks)');
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
        print('[BuildingConfig] Loaded ${_overrides.length} overrides');
      }
    } catch (e) {
      print('[BuildingConfig] Failed to load overrides: $e');
    }
  }

  /// Save overrides to SharedPreferences.
  Future<void> _saveOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_overrides));
    } catch (e) {
      print('[BuildingConfig] Failed to save overrides: $e');
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

  dynamic getDefault(String key) => _defaults[key];

  // ==================== RESOLUTION HELPERS ====================

  /// Resolve a value: override -> default -> hardcoded fallback.
  double _resolve(String key, double fallback) {
    if (_overrides.containsKey(key)) {
      final val = _overrides[key];
      if (val is num) return val.toDouble();
    }
    final val = _defaults[key];
    if (val is num) return val.toDouble();
    return fallback;
  }
}

/// Global building config instance (initialized in game3d_widget.dart).
BuildingConfig? globalBuildingConfig;
