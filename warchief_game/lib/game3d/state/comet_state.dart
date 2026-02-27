import 'dart:math' as math;
import 'comet_config.dart';

/// Public snapshot of one active impact crater, consumed by [MeteorCraterRenderer].
class ImpactCraterData {
  final double x;

  /// Terrain Y height at the impact point (for 3D debris placement).
  final double y;
  final double z;

  /// How old the crater is [0.0 = just landed, 1.0 = about to expire].
  final double ageFraction;

  /// Glow intensity [1.0 = scorching hot, 0.0 = cold ash]. High for first 40% of life.
  final double glowIntensity;

  const ImpactCraterData({
    required this.x,
    required this.y,
    required this.z,
    required this.ageFraction,
    required this.glowIntensity,
  });
}

/// A meteor impact crater — emits black mana regen while fresh.
class _ImpactCrater {
  final double x;

  /// Terrain height at the impact site (static — set on impact, never changes).
  final double y;
  final double z;
  double remainingLife; // seconds
  final double maxLife; // seconds at creation

  _ImpactCrater({
    required this.x,
    required this.y,
    required this.z,
    required this.remainingLife,
  }) : maxLife = remainingLife;

  double get ageFraction => 1.0 - (remainingLife / maxLife).clamp(0.0, 1.0);

  /// Hot glow fades over first 40% of lifetime, then goes cold ash.
  double get glowIntensity => (1.0 - ageFraction / 0.4).clamp(0.0, 1.0);

  ImpactCraterData toData() => ImpactCraterData(
        x: x,
        y: y,
        z: z,
        ageFraction: ageFraction,
        glowIntensity: glowIntensity,
      );
}

/// Runtime orbital and environmental state for the comet system.
///
/// Follows the [WindState] pattern: pure Dart, no Flutter, no JSON.
/// Updated every frame by [game3d_widget_update.dart].
///
/// Phase 0.0 / 1.0 = aphelion (comet far away).
/// Phase 0.5 = perihelion (closest flyby, max intensity).
class CometState {
  // ==================== ORBITAL STATE ====================

  /// Current orbital phase in [0.0, 1.0).
  /// Wraps continuously; phase 0.5 = perihelion peak.
  /// Reason: start at 0.45 (just before perihelion) so effects are visible on first load.
  double _orbitalPhase = 0.45;

  /// Current orbit period in seconds (read from config on each update).
  double orbitalPeriod = 3600.0;

  // ==================== DERIVED STATE ====================

  /// Comet intensity [0.0, 1.0] — bell curve peaking at perihelion (phase=0.5).
  double cometIntensity = 0.0;

  /// Whether the meteor shower window is currently active.
  bool isMeteorShowerActive = false;

  /// Shower intensity [0.0, 1.0] — scales spawn rate inside shower window.
  double meteorShowerIntensity = 0.0;

  /// Composite black mana regen rate (ambient + surge). Does not include crater bonuses.
  double blackManaRegenRate = 0.0;

  /// Horizontal position of the comet in the sky [0.0, 1.0] (wraps with orbit).
  double skyAzimuthFraction = 0.0;

  /// Elevation of the comet in the sky [0.0, 1.0] (peaks at perihelion).
  double skyElevationFraction = 0.0;

  // ==================== IMPACT CRATERS ====================

  final List<_ImpactCrater> _activeCraters = [];

  // ==================== PUBLIC API ====================

  /// World-space XYZ position of the comet [x, y, z].
  ///
  /// Matches the transform used by [SkyRenderer._updateCometTransform] so
  /// the particle tail spawns exactly at the comet's rendered location.
  List<double> get cometWorldPosition {
    final azimuth = skyAzimuthFraction * 2.0 * math.pi;
    const orbitRadius = 450.0;
    const minAlt = 150.0;
    const maxAlt = 220.0;
    return [
      math.cos(azimuth) * orbitRadius,
      minAlt + (maxAlt - minAlt) * skyElevationFraction,
      math.sin(azimuth) * orbitRadius,
    ];
  }

  /// Normalised direction the comet is travelling [dx, dy, dz].
  ///
  /// Derivative of position w.r.t. azimuth, projected onto the XZ plane.
  /// Reversed (anti-tangent) gives the tail streaming direction.
  List<double> get orbitalTangent {
    final azimuth = skyAzimuthFraction * 2.0 * math.pi;
    return [-math.sin(azimuth), 0.0, math.cos(azimuth)];
  }

  /// Snapshots of all active craters for the meteor crater renderer.
  List<ImpactCraterData> get craterDataForRendering =>
      _activeCraters.map((c) => c.toData()).toList(growable: false);

  /// Advance orbital mechanics by [dt] seconds and recompute all derived values.
  void update(double dt) {
    final config = globalCometConfig;
    orbitalPeriod = config?.periodSeconds ?? 3600.0;

    // Advance phase proportionally to elapsed time
    _orbitalPhase = (_orbitalPhase + dt / orbitalPeriod) % 1.0;

    // Recompute derived values
    cometIntensity = _computeIntensity();
    _computeMeteorShower(config);
    _computeBlackManaRegenRate(config);
    _computeSkyPosition();
    _decayCraters(dt);
  }

  /// Register a new impact crater at world position (x, y, z).
  ///
  /// [y] is the terrain height at (x, z) for 3D debris placement.
  /// Craters decay over [impactCraterDecayTime] seconds, providing a bonus
  /// black mana regen source to players standing within [impactCraterRadius].
  void addImpactCrater(double x, double y, double z) {
    final decayTime = globalCometConfig?.impactCraterDecayTime ?? 60.0;
    _activeCraters.add(_ImpactCrater(x: x, y: y, z: z, remainingLife: decayTime));
    // Reason: cap to 20 simultaneous craters to prevent unbounded list growth
    if (_activeCraters.length > 20) {
      _activeCraters.removeAt(0);
    }
  }

  /// Sum of crater bonus regen rates for a player at (playerX, playerZ).
  ///
  /// Returns 0.0 when no craters are nearby.
  double getImpactCraterBonus(double playerX, double playerZ) {
    final config = globalCometConfig;
    final radius = config?.impactCraterRadius ?? 8.0;
    final bonusPerCrater = config?.impactCraterBonus ?? 8.0;

    double total = 0.0;
    for (final crater in _activeCraters) {
      final dx = playerX - crater.x;
      final dz = playerZ - crater.z;
      final dist = math.sqrt(dx * dx + dz * dz);
      if (dist <= radius) {
        // Reason: use per-crater maxLife for age fraction (config may change at runtime)
        final ageFraction = crater.remainingLife / crater.maxLife;
        total += bonusPerCrater * ageFraction;
      }
    }
    return total;
  }

  /// Compute total black mana regen rate for a player at (playerX, playerZ).
  ///
  /// Three layers:
  /// 1. Ambient (always active)
  /// 2. Comet surge (scales with intensity)
  /// 3. Crater bonuses (proximity-gated)
  double computeBlackManaRegen(double playerX, double playerZ) {
    return blackManaRegenRate + getImpactCraterBonus(playerX, playerZ);
  }

  /// Orbital phase (read-only, for diagnostics).
  double get orbitalPhase => _orbitalPhase;

  /// Active crater count (for diagnostics / UI display).
  int get activeCraterCount => _activeCraters.length;

  // ==================== PRIVATE HELPERS ====================

  /// Gaussian bell curve centered at perihelionFraction, with width tuned so
  /// the comet is at >50% intensity for ~30% of its orbit.
  double _computeIntensity() {
    final perihelion = globalCometConfig?.perihelionFraction ?? 0.5;
    // Reason: wrap-aware distance so phase 0.0 and 1.0 are both near aphelion
    double delta = (_orbitalPhase - perihelion).abs();
    if (delta > 0.5) delta = 1.0 - delta;
    // k controls bell curve width: higher k = narrower peak
    const double k = 50.0;
    return math.exp(-k * delta * delta);
  }

  void _computeMeteorShower(CometConfig? config) {
    final perihelion = config?.perihelionFraction ?? 0.5;
    final window = config?.meteorShowerWindow ?? 0.15;

    double delta = (_orbitalPhase - perihelion).abs();
    if (delta > 0.5) delta = 1.0 - delta;

    if (delta <= window / 2.0) {
      isMeteorShowerActive = true;
      // Intensity peaks at center of window, falls to 0 at edges
      meteorShowerIntensity =
          (1.0 - (delta / (window / 2.0))).clamp(0.0, 1.0);
    } else {
      isMeteorShowerActive = false;
      meteorShowerIntensity = 0.0;
    }
  }

  void _computeBlackManaRegenRate(CometConfig? config) {
    final ambient = config?.ambientRegenRate ?? 0.5;
    final perihelionRate = config?.perihelionRegenRate ?? 15.0;
    blackManaRegenRate = ambient + perihelionRate * cometIntensity;
  }

  void _computeSkyPosition() {
    // Azimuth tracks orbital phase (comet sweeps across sky over full orbit)
    skyAzimuthFraction = _orbitalPhase;
    // Elevation: sine arch peaking at perihelion (phase 0.5 → elevation = 1.0)
    skyElevationFraction =
        math.max(0.0, math.sin(_orbitalPhase * math.pi));
  }

  void _decayCraters(double dt) {
    for (int i = _activeCraters.length - 1; i >= 0; i--) {
      _activeCraters[i].remainingLife -= dt;
      if (_activeCraters[i].remainingLife <= 0) {
        _activeCraters.removeAt(i);
      }
    }
  }
}

/// Global comet state instance (initialized in game3d_widget_init.dart)
CometState? globalCometState;
