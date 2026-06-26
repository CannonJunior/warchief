import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Crowd-control system configuration loaded from JSON asset.
///
/// Follows the same pattern as [CometConfig] / [WindConfig]:
/// JSON asset provides shipped defaults, dot-notation getters for all values.
class CcConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/cc_config.json';

  Map<String, dynamic> _defaults = {};

  // ==================== DIMINISHING RETURNS ====================

  bool get drEnabled => _resolveBool('diminishingReturns.enabled', true);
  double get drWindow => _resolve('diminishingReturns.window', 18.0);

  List<double> get drReductions {
    final val = _resolveList('diminishingReturns.reductions');
    return val ?? [1.0, 0.5, 0.25, 0.0];
  }

  Map<String, List<String>> get drCategories {
    final val = _resolveFromNestedMap(_defaults, 'diminishingReturns.categories');
    if (val is Map<String, dynamic>) {
      return val.map((k, v) =>
          MapEntry(k, (v as List).map((e) => e.toString()).toList()));
    }
    return {
      'stun': ['stun', 'knockdown', 'airborne'],
      'incapacitate': ['sleep', 'polymorph', 'banish', 'charm'],
      'root': ['root', 'grounded'],
      'silence': ['silence', 'suppress'],
      'disorient': ['fear', 'disorient', 'daze'],
    };
  }

  // ==================== AIRBORNE ====================

  double get airborneLaunchHeightBase => _resolve('airborne.launchHeightBase', 4.0);
  double get airborneGravityAccel => _resolve('airborne.gravityAccel', 12.0);
  double get airborneWindDurationBonus => _resolve('airborne.windDurationBonus', 0.3);
  double get airborneFallDamagePerUnit => _resolve('airborne.fallDamagePerUnit', 5.0);
  double get airborneJuggleWindow => _resolve('airborne.juggleWindowAfterLand', 0.5);

  // ==================== SLEEP ====================

  double get sleepRegenPercent => _resolve('sleep.regenPerSecondPercent', 1.0);
  double get sleepCasterManaBonus => _resolve('sleep.casterManaRegenBonus', 0.5);

  // ==================== CHARM ====================

  double get charmWalkSpeed => _resolve('charm.walkSpeedPercent', 0.6);
  double get charmAllySlowRadius => _resolve('charm.allySlowRadius', 3.0);
  double get charmAllySlowDuration => _resolve('charm.allySlowDuration', 1.0);
  double get charmAllySlowStrength => _resolve('charm.allySlowStrength', 0.3);

  // ==================== POLYMORPH ====================

  double get polymorphMoveSpeed => _resolve('polymorph.moveSpeedPercent', 0.7);
  double get polymorphTrailDuration => _resolve('polymorph.trailDuration', 3.0);
  double get polymorphTrailVisRadius => _resolve('polymorph.trailVisibilityRadius', 15.0);

  // ==================== TAUNT ====================

  double get tauntDamageReduction => _resolve('taunt.damageReduction', 0.25);
  double get tauntIndignationDuration => _resolve('taunt.indignationDuration', 2.0);
  double get tauntIndignationHaste => _resolve('taunt.indignationHaste', 0.3);

  // ==================== DISORIENT ====================

  double get disorientRemapInterval => _resolve('disorient.remapRotateInterval', 1.5);
  double get disorientCameraSway => _resolve('disorient.cameraSway', 15.0);
  double get disorientInputDelay => _resolve('disorient.inputDelay', 0.3);

  // ==================== GROUNDED ====================

  double get groundedNatureDamageBonus => _resolve('grounded.natureDamageBonus', 0.2);

  // ==================== SUPPRESS ====================

  bool get suppressCasterBreakOnDamage => _resolveBool('suppress.casterBreakOnDamage', true);

  // ==================== NEARSIGHT ====================

  double get nearsightFogRadius => _resolve('nearsight.fogRadius', 8.0);
  double get nearsightNameplateRadius => _resolve('nearsight.nameplateRadius', 10.0);
  bool get nearsightHidesCcOverlay => _resolveBool('nearsight.hidesCcOverlay', true);

  // ==================== BANISH ====================

  double get banishCooldownTickRate => _resolve('banish.cooldownTickRate', 3.0);

  // ==================== GRAVITY WELL ====================

  double get gravityWellPullSpeed => _resolve('gravityWell.pullSpeed', 2.0);
  double get gravityWellMoveReduction => _resolve('gravityWell.moveSpeedReduction', 0.4);
  double get gravityWellBendRadius => _resolve('gravityWell.projectileBendRadius', 8.0);
  double get gravityWellBendStrength => _resolve('gravityWell.projectileBendStrength', 0.5);

  // ==================== STANCE INTERACTIONS ====================

  // Cadence
  double get cadenceOnBeatCcDurationBonus =>
      _resolve('stanceInteractions.cadence.onBeatCcDurationBonus', 0.25);

  // Tempest
  double get tempestNonChainCcDurationPenalty =>
      _resolve('stanceInteractions.tempest.nonChainCcDurationPenalty', 0.15);
  double get tempestIncomingHardCcReduction =>
      _resolve('stanceInteractions.tempest.incomingHardCcReduction', 0.20);

  // Warden
  double get wardenPredatorCcDurationBonus =>
      _resolve('stanceInteractions.warden.predatorCcDurationBonus', 0.40);

  // Crucible
  double get crucibleZeroheatCcDurationBonus =>
      _resolve('stanceInteractions.crucible.zeroheatCcDurationBonus', 0.50);

  // Flux
  double get fluxTransitionCcDurationBonus =>
      _resolve('stanceInteractions.flux.transitionCcDurationBonus', 0.30);
  double get fluxStagnationCcDurationPenalty =>
      _resolve('stanceInteractions.flux.stagnationCcDurationPenalty', 0.25);

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _defaults = jsonDecode(jsonString) as Map<String, dynamic>;
      notifyListeners();
      debugPrint('[CcConfig] Loaded defaults from $_assetPath');
    } catch (e) {
      debugPrint('[CcConfig] Failed to load: $e (using fallbacks)');
      _defaults = {};
    }
  }

  // ==================== RESOLUTION HELPERS ====================

  double _resolve(String dotKey, double fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toDouble();
    return fallback;
  }

  bool _resolveBool(String dotKey, bool fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is bool) return val;
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

/// Global CC config instance (initialized in game3d_widget_init.dart)
CcConfig? globalCcConfig;
