import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Manages building configuration with JSON asset defaults.
///
/// Architecture:
/// - JSON asset file (`assets/data/building_config.json`) = shipped defaults
/// - Runtime getters resolve values from the loaded defaults
///
/// Follows the same pattern as [ManaConfig] and [WindConfig].
class BuildingConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/building_config.json';

  /// Defaults loaded from JSON asset file.
  Map<String, dynamic> _defaults = {};

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

  /// Load defaults from JSON asset.
  Future<void> initialize() async {
    await _loadDefaults();
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

  // ==================== RESOLUTION HELPERS ====================

  /// Resolve a value from defaults with hardcoded fallback.
  double _resolve(String key, double fallback) {
    final val = _defaults[key];
    if (val is num) return val.toDouble();
    return fallback;
  }
}

/// Global building config instance (initialized in game3d_widget.dart).
BuildingConfig? globalBuildingConfig;
