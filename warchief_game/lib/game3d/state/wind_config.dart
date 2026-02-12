import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Manages wind system configuration with JSON asset defaults.
///
/// Follows the same pattern as [ManaConfig]: JSON asset file provides
/// shipped defaults, with dot-notation getters for all values.
class WindConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/wind_config.json';

  /// Defaults loaded from JSON asset file
  Map<String, dynamic> _defaults = {};

  // ==================== WIND GETTERS ====================

  double get baseStrength => _resolve('wind.baseStrength', 0.3);
  double get maxStrength => _resolve('wind.maxStrength', 1.0);
  double get driftSpeed => _resolve('wind.driftSpeed', 0.1);
  double get gustFrequency => _resolve('wind.gustFrequency', 0.05);
  double get gustAmplitude => _resolve('wind.gustAmplitude', 0.4);
  double get directionDriftSpeed => _resolve('wind.directionDriftSpeed', 0.08);

  // ==================== WHITE MANA GETTERS ====================

  double get whiteMaxMana => _resolve('whiteMana.maxMana', 100.0);
  double get whiteBaseRegen => _resolve('whiteMana.baseRegen', 0.0);
  double get windExposureRegen => _resolve('whiteMana.windExposureRegen', 2.5);
  double get windStrengthMultiplier =>
      _resolve('whiteMana.windStrengthMultiplier', 1.0);
  double get decayRate => _resolve('whiteMana.decayRate', 0.5);
  double get shelterThreshold => _resolve('whiteMana.shelterThreshold', 0.1);

  // ==================== MOVEMENT GETTERS ====================

  double get headwindFactor => _resolve('movement.headwindFactor', 0.15);
  double get tailwindFactor => _resolve('movement.tailwindFactor', 0.10);
  double get crosswindFactor => _resolve('movement.crosswindFactor', 0.05);

  // ==================== PROJECTILE GETTERS ====================

  double get windForceMultiplier =>
      _resolve('projectile.windForceMultiplier', 0.8);

  // ==================== FLIGHT GETTERS ====================

  double get flightSpeed => _resolve('flight.flightSpeed', 7.0);
  double get pitchRate => _resolve('flight.pitchRate', 60.0);
  double get maxPitchAngle => _resolve('flight.maxPitchAngle', 45.0);
  double get boostMultiplier => _resolve('flight.boostMultiplier', 1.5);
  double get brakeMultiplier => _resolve('flight.brakeMultiplier', 0.6);
  double get brakeJumpForce => _resolve('flight.brakeJumpForce', 3.0);
  double get flightManaDrainRate => _resolve('flight.manaDrainRate', 3.0);
  double get lowManaThreshold => _resolve('flight.lowManaThreshold', 33.0);
  double get lowManaDescentRate => _resolve('flight.lowManaDescentRate', 2.0);
  double get minAltitudeForDescent =>
      _resolve('flight.minAltitudeForDescent', 10.0);
  double get initialManaCost => _resolve('flight.initialManaCost', 15.0);

  // ==================== TRAIL GETTERS ====================

  bool get trailsEnabled => _resolveBool('trails.enabled', true);
  double get trailLength => _resolve('trails.length', 1.2);
  double get trailWidth => _resolve('trails.width', 0.08);

  // ==================== DERECHO GETTERS ====================

  double get derechoAverageInterval =>
      _resolve('derecho.averageInterval', 300.0);
  double get derechoDurationMin => _resolve('derecho.durationMin', 30.0);
  double get derechoDurationMax => _resolve('derecho.durationMax', 60.0);
  double get derechoStrengthMultiplier =>
      _resolve('derecho.strengthMultiplier', 10.0);
  double get derechoManaRegenMultiplier =>
      _resolve('derecho.manaRegenMultiplier', 10.0);
  double get derechoVisualMultiplier =>
      _resolve('derecho.visualMultiplier', 10.0);
  double get derechoRampUpTime => _resolve('derecho.rampUpTime', 5.0);
  double get derechoRampDownTime => _resolve('derecho.rampDownTime', 5.0);

  List<double> get derechoColor {
    final val = _resolveFromNestedMap(_defaults, 'derecho.color');
    if (val is List) {
      return val.map((e) => (e as num).toDouble()).toList();
    }
    return [0.9, 0.95, 1.0, 0.85];
  }

  // ==================== PARTICLE GETTERS ====================

  int get particleCount => _resolveInt('particles.count', 60);
  double get particleSpeed => _resolve('particles.speed', 2.0);
  double get particleLifetime => _resolve('particles.lifetime', 3.0);
  double get fadeDistance => _resolve('particles.fadeDistance', 15.0);
  double get particleSize => _resolve('particles.size', 0.25);

  List<double> get particleColor {
    final val = _resolveFromNestedMap(_defaults, 'particles.color');
    if (val is List) {
      return val.map((e) => (e as num).toDouble()).toList();
    }
    return [1.0, 1.0, 1.0, 0.3];
  }

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
      print('[WindConfig] Loaded defaults from $_assetPath');
    } catch (e) {
      print('[WindConfig] Failed to load defaults: $e (using fallbacks)');
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

/// Global wind config instance (initialized in game3d_widget.dart)
WindConfig? globalWindConfig;
