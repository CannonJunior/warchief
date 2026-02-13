import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Manages minimap configuration with JSON asset defaults.
///
/// Follows the same pattern as [WindConfig]: JSON asset file provides
/// shipped defaults, with dot-notation getters for all values.
class MinimapConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/minimap_config.json';

  /// Defaults loaded from JSON asset file
  Map<String, dynamic> _defaults = {};

  // ==================== MINIMAP GETTERS ====================

  int get minimapSize => _resolveInt('minimap.size', 160);
  int get borderWidth => _resolveInt('minimap.borderWidth', 2);

  List<double> get borderColor =>
      _resolveColorList('minimap.borderColor', [0.15, 0.15, 0.26, 1.0]);
  List<double> get backgroundColor =>
      _resolveColorList('minimap.backgroundColor', [0.04, 0.04, 0.10, 0.85]);

  // ==================== TERRAIN GETTERS ====================

  int get cacheResolution => _resolveInt('terrain.cacheResolution', 128);
  double get refreshThresholdFraction =>
      _resolve('terrain.refreshThresholdFraction', 0.3);

  List<double> get sandColor =>
      _resolveColorList('terrain.sandColor', [0.76, 0.70, 0.50, 1.0]);
  List<double> get grassColor =>
      _resolveColorList('terrain.grassColor', [0.29, 0.49, 0.25, 1.0]);
  List<double> get rockColor =>
      _resolveColorList('terrain.rockColor', [0.42, 0.42, 0.42, 1.0]);

  double get sandThreshold => _resolve('terrain.sandThreshold', 0.15);
  double get rockThreshold => _resolve('terrain.rockThreshold', 0.70);

  // ==================== LEY LINE GETTERS ====================

  bool get showLeyLines => _resolveBool('leyLines.show', true);

  List<double> get leyLineColor =>
      _resolveColorList('leyLines.lineColor', [0.27, 0.53, 0.80, 0.6]);
  List<double> get powerNodeColor =>
      _resolveColorList('leyLines.powerNodeColor', [0.40, 0.27, 0.80, 0.8]);

  double get leyLineWidth => _resolve('leyLines.lineWidth', 1.0);
  double get nodeRadius => _resolve('leyLines.nodeRadius', 3.0);

  // ==================== ENTITY GETTERS ====================

  List<double> get playerColor =>
      _resolveColorList('entities.playerColor', [0.75, 0.75, 0.75, 1.0]);
  int get playerSize => _resolveInt('entities.playerSize', 8);

  List<double> get allyColor =>
      _resolveColorList('entities.allyColor', [0.40, 0.80, 0.40, 1.0]);
  int get allySize => _resolveInt('entities.allySize', 5);

  List<double> get enemyColor =>
      _resolveColorList('entities.enemyColor', [1.0, 0.27, 0.27, 1.0]);
  int get enemySize => _resolveInt('entities.enemySize', 4);

  List<double> get bossColor =>
      _resolveColorList('entities.bossColor', [1.0, 0.0, 0.0, 1.0]);
  int get bossSize => _resolveInt('entities.bossSize', 8);

  // ==================== ZOOM GETTERS ====================

  List<double> get zoomLevels {
    final val = _resolveFromNestedMap(_defaults, 'zoom.levels');
    if (val is List) {
      return val.map((e) => (e as num).toDouble()).toList();
    }
    return [25.0, 50.0, 100.0, 150.0];
  }

  int get defaultZoomLevel => _resolveInt('zoom.defaultLevel', 1);

  // ==================== SUN GETTERS ====================

  List<Map<String, dynamic>> get suns {
    final val = _resolveFromNestedMap(_defaults, 'suns');
    if (val is List) {
      return val.cast<Map<String, dynamic>>();
    }
    return [
      {
        'name': 'Solara',
        'color': [1.0, 0.95, 0.6, 1.0],
        'orbitalPeriod': 600.0,
        'startAngle': 0.0,
        'iconSize': 14,
      },
      {
        'name': 'Kethis',
        'color': [1.0, 0.6, 0.3, 1.0],
        'orbitalPeriod': 900.0,
        'startAngle': 120.0,
        'iconSize': 12,
      },
      {
        'name': 'Umbris',
        'color': [0.7, 0.5, 0.9, 1.0],
        'orbitalPeriod': 1200.0,
        'startAngle': 240.0,
        'iconSize': 10,
      },
    ];
  }

  // ==================== PING GETTERS ====================

  double get pingDecayDuration => _resolve('ping.decayDuration', 5.0);
  int get pingRingCount => _resolveInt('ping.ringCount', 3);
  double get pingMaxRingRadius => _resolve('ping.maxRingRadius', 20.0);

  List<double> get pingDefaultColor =>
      _resolveColorList('ping.defaultColor', [1.0, 0.9, 0.3, 1.0]);

  int get pingWorldIndicatorSize =>
      _resolveInt('ping.worldIndicatorSize', 32);
  int get maxActivePings => _resolveInt('ping.maxActivePings', 5);

  // ==================== CLOCK GETTERS ====================

  bool get clockShowByDefault => _resolveBool('clock.showByDefault', true);
  String get clockDefaultMode {
    final val = _resolveFromNestedMap(_defaults, 'clock.defaultMode');
    if (val is String) return val;
    return 'real';
  }

  int get clockFontSize => _resolveInt('clock.fontSize', 9);
  bool get warchiefTimeEnabled =>
      _resolveBool('clock.warchiefTimeEnabled', false);

  // ==================== WIND GETTERS ====================

  bool get showWindOnBorder => _resolveBool('wind.showOnBorder', true);
  int get windArrowSize => _resolveInt('wind.arrowSize', 10);

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
      print('[MinimapConfig] Loaded defaults from $_assetPath');
    } catch (e) {
      print('[MinimapConfig] Failed to load defaults: $e (using fallbacks)');
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

  /// Resolve a color list [r, g, b, a] from nested map with fallback.
  List<double> _resolveColorList(String dotKey, List<double> fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is List) {
      return val.map((e) => (e as num).toDouble()).toList();
    }
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

/// Global minimap config instance (initialized in game3d_widget.dart)
MinimapConfig? globalMinimapConfig;
