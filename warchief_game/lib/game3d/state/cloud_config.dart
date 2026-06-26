import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Cloud system configuration loaded from JSON asset.
///
/// Follows the same pattern as [CometConfig] / [WindConfig]:
/// JSON asset provides shipped defaults, dot-notation getters for all values.
class CloudConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/cloud_config.json';

  Map<String, dynamic> _defaults = {};

  int get cloudCount => _resolveInt('clouds.count', 18);
  double get spawnRadius => _resolve('clouds.spawnRadius', 300.0);
  double get altitudeMin => _resolve('clouds.altitudeMin', 55.0);
  double get altitudeMax => _resolve('clouds.altitudeMax', 90.0);
  int get puffsPerCloudMin => _resolveInt('clouds.puffsPerCloudMin', 5);
  int get puffsPerCloudMax => _resolveInt('clouds.puffsPerCloudMax', 12);
  double get puffSizeMin => _resolve('clouds.puffSizeMin', 8.0);
  double get puffSizeMax => _resolve('clouds.puffSizeMax', 22.0);
  double get driftSpeed => _resolve('clouds.driftSpeed', 0.4);

  Future<void> initialize() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _defaults = jsonDecode(jsonString) as Map<String, dynamic>;
      notifyListeners();
      debugPrint('[CloudConfig] Loaded defaults from $_assetPath');
    } catch (e) {
      debugPrint('[CloudConfig] Failed to load: $e (using fallbacks)');
      _defaults = {};
    }
  }

  double _resolve(String dotKey, double fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toDouble();
    return fallback;
  }

  int _resolveInt(String dotKey, int fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toInt();
    return fallback;
  }

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

/// Global cloud config instance (initialized in game3d_widget_init.dart)
CloudConfig? globalCloudConfig;
