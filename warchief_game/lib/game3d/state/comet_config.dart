import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Manages comet system configuration with JSON asset defaults.
///
/// Follows the same pattern as [ManaConfig] / [WindConfig]:
/// JSON asset provides shipped defaults, dot-notation getters for all values.
/// No SharedPreferences overrides (comet config is not user-tunable at runtime).
class CometConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/comet_config.json';

  /// Defaults loaded from JSON asset file
  Map<String, dynamic> _defaults = {};

  // ==================== ORBITAL GETTERS ====================

  /// Full orbit duration in real seconds (default ~1 hour)
  double get periodSeconds => _resolve('orbital.periodSeconds', 3600.0);

  /// Orbital phase fraction where perihelion occurs (0.5 = midpoint)
  double get perihelionFraction => _resolve('orbital.perihelionFraction', 0.5);

  /// Fraction of orbit during which meteor shower is active (centered on perihelion)
  double get meteorShowerWindow => _resolve('orbital.meteorShowerWindow', 0.15);

  /// Starting orbital phase [0.0, 1.0] at game initialisation.
  /// 0.45 = just before perihelion so comet effects are immediately visible.
  double get startPhase => _resolve('orbital.startPhase', 0.45);

  // ==================== BLACK MANA GETTERS ====================

  double get maxBlackMana => _resolve('blackMana.maxMana', 100.0);

  /// Always-on ambient regen rate (residual void energy between flybys)
  double get ambientRegenRate => _resolve('blackMana.ambientRegenRate', 0.5);

  /// Additional regen at peak perihelion intensity
  double get perihelionRegenRate => _resolve('blackMana.perihelionRegenRate', 15.0);

  /// Radius in world units within which a crater grants bonus regen
  double get impactCraterRadius => _resolve('blackMana.impactCraterRadius', 8.0);

  /// Bonus regen per crater when standing inside its radius
  double get impactCraterBonus => _resolve('blackMana.impactCraterBonus', 8.0);

  /// Seconds before a crater expires and loses its regen bonus
  double get impactCraterDecayTime =>
      _resolve('blackMana.impactCraterDecayTime', 60.0);

  /// Decay rate when no regen source is active
  double get blackManaDecayRate => _resolve('blackMana.decayRate', 1.0);

  // ==================== SKY GETTERS ====================

  List<double> get zenithColor {
    final v = _resolveList('sky.zenithColor');
    return v ?? [0.05, 0.01, 0.10];
  }

  List<double> get horizonColorDay {
    final v = _resolveList('sky.horizonColorDay');
    return v ?? [0.12, 0.06, 0.04];
  }

  List<double> get horizonColorNight {
    final v = _resolveList('sky.horizonColorNight');
    return v ?? [0.07, 0.02, 0.10];
  }

  double get cometTintStrength => _resolve('sky.cometTintStrength', 0.6);

  // ==================== COMET VISUAL GETTERS ====================

  List<double> get comaColor {
    final v = _resolveList('comet.comaColor');
    return v ?? [0.85, 0.70, 1.00];
  }

  List<double> get ionTailColor {
    final v = _resolveList('comet.ionTailColor');
    return v ?? [0.50, 0.30, 1.00];
  }

  List<double> get dustTailColor {
    final v = _resolveList('comet.dustTailColor');
    return v ?? [0.70, 0.55, 0.90];
  }

  double get comaMinSize => _resolve('comet.comaMinSize', 0.02);
  double get comaMaxSize => _resolve('comet.comaMaxSize', 0.15);
  double get ionTailMaxLength => _resolve('comet.ionTailMaxLength', 0.5);
  double get dustTailMaxLength => _resolve('comet.dustTailMaxLength', 0.35);

  // ==================== METEOR GETTERS ====================

  double get meteorBaseRate => _resolve('meteors.baseRate', 0.5);
  double get meteorShowerRate => _resolve('meteors.showerRate', 5.0);
  double get meteorStormRate => _resolve('meteors.stormRate', 20.0);
  double get meteorLifetime => _resolve('meteors.lifetime', 3.0);
  double get meteorSpeed => _resolve('meteors.speed', 80.0);
  double get meteorTrailLength => _resolve('meteors.trailLength', 4.0);
  double get meteorImpactFlashDuration =>
      _resolve('meteors.impactFlashDuration', 0.4);
  double get meteorSpawnRadius => _resolve('meteors.spawnRadius', 80.0);
  double get meteorSpawnHeight => _resolve('meteors.spawnHeight', 200.0);

  List<double> get meteorHeadColor {
    final v = _resolveList('meteors.headColor');
    return v ?? [0.90, 0.80, 1.00];
  }

  List<double> get meteorTailColor {
    final v = _resolveList('meteors.tailColor');
    return v ?? [0.10, 0.00, 0.20];
  }

  // ==================== INITIALIZATION ====================

  /// Load defaults from JSON asset.
  Future<void> initialize() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _defaults = jsonDecode(jsonString) as Map<String, dynamic>;
      notifyListeners();
      print('[CometConfig] Loaded defaults from $_assetPath');
    } catch (e) {
      print('[CometConfig] Failed to load: $e (using fallbacks)');
      _defaults = {};
    }
  }

  // ==================== RESOLUTION HELPERS ====================

  double _resolve(String dotKey, double fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toDouble();
    return fallback;
  }

  List<double>? _resolveList(String dotKey) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is List) return val.map((e) => (e as num).toDouble()).toList();
    return null;
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

/// Global comet config instance (initialized in game3d_widget_init.dart)
CometConfig? globalCometConfig;
