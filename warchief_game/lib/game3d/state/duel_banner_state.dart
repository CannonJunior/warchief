import 'dart:math' as math;
import 'wind_state.dart';

/// Animation phases for the duel arena banner.
enum DuelBannerPhase { idle, dropping, fluttering, flagRising, complete }

/// Drives the pole drop-in animation, wind flutter, and victory flag ascent
/// for the banner that marks the centre of a duel arena.
///
/// [DuelBannerRenderer] reads the computed display fields each frame.
class DuelBannerState {
  DuelBannerPhase phase = DuelBannerPhase.idle;

  /// World-space centre of the arena (between the two sides).
  double centerX = 0.0;
  double centerZ = 0.0;

  /// Terrain height at the arena centre. The pole lands here instead of Y=0
  /// so it sits on the actual ground surface even on hilly terrain.
  double groundY = 0.0;

  static const double poleHeight       = 12.0;
  static const double _dropDuration    = 2.0;  // seconds for pole to reach ground
  static const double _flagRiseDuration = 1.5; // seconds for victory flag to rise

  double _dropProgress = 0.0;
  double _wavePhase    = 0.0;
  double _flagProgress = 0.0;

  /// ID of the winning side ('challenger' | 'enemy' | 'draw') once duel ends.
  String? winnerId;

  // ── Display fields (read by DuelBannerRenderer) ──────────────────────────

  /// Y coordinate of the bottom of the pole. Starts above the sky and drops to groundY.
  double poleBaseY = 80.0;

  /// Yaw (degrees) the banner cloth faces — into the wind.
  double bannerYawDeg = 0.0;

  /// Roll oscillation (degrees) for cloth flutter.
  double bannerRollDeg = 0.0;

  /// How high the victory flag has risen along the pole (0 at base).
  double flagHeightY = 0.0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Begin a new drop-in animation centred at world position (x, z).
  ///
  /// [terrainY] is the terrain height at (x, z) — the pole lands here rather
  /// than at the world origin so it sits on the actual ground.
  void start(double x, double z, {double terrainY = 0.0}) {
    centerX       = x;
    centerZ       = z;
    groundY       = terrainY;
    phase         = DuelBannerPhase.dropping;
    _dropProgress = 0.0;
    _wavePhase    = 0.0;
    _flagProgress = 0.0;
    winnerId      = null;
    poleBaseY     = terrainY + 80.0; // start 80 units above terrain
    bannerYawDeg  = 0.0;
    bannerRollDeg = 0.0;
    flagHeightY   = 0.0;
  }

  /// Called by DuelSystem when the duel concludes. Begins flag-rise animation.
  void notifyWinner(String id) {
    if (phase != DuelBannerPhase.fluttering) return;
    winnerId      = id;
    phase         = DuelBannerPhase.flagRising;
    _flagProgress = 0.0;
    flagHeightY   = 0.0;
  }

  /// Hide banner (called on duel cancel or before a new duel start).
  void reset() {
    phase    = DuelBannerPhase.idle;
    winnerId = null;
  }

  // ── Per-frame update ──────────────────────────────────────────────────────

  void update(double dt, WindState? windState) {
    switch (phase) {
      case DuelBannerPhase.idle:
      case DuelBannerPhase.complete:
        return;
      case DuelBannerPhase.dropping:
        _dropProgress = (_dropProgress + dt / _dropDuration).clamp(0.0, 1.0);
        // Drop from (groundY + 80) down to groundY using ease-out
        poleBaseY = groundY + 80.0 * (1.0 - _easeOut(_dropProgress));
        if (_dropProgress >= 1.0) {
          poleBaseY = groundY;
          phase     = DuelBannerPhase.fluttering;
        }
        _updateWave(dt, windState);
      case DuelBannerPhase.fluttering:
        poleBaseY = groundY;
        _updateWave(dt, windState);
      case DuelBannerPhase.flagRising:
        _flagProgress = (_flagProgress + dt / _flagRiseDuration).clamp(0.0, 1.0);
        flagHeightY   = _flagProgress * (poleHeight - 1.5);
        if (_flagProgress >= 1.0) phase = DuelBannerPhase.complete;
        _updateWave(dt, windState);
    }
  }

  void _updateWave(double dt, WindState? windState) {
    final windStr  = windState?.effectiveWindStrength ?? 0.0;
    _wavePhase    += dt * (1.5 + windStr * 2.0);

    // Banner faces in the direction the wind is blowing
    final windRad  = windState?.windAngle ?? 0.0;
    bannerYawDeg   = windRad * 180.0 / math.pi;

    // Roll amplitude scales with wind strength; sinusoidal oscillation
    bannerRollDeg  = math.sin(_wavePhase) * (5.0 + windStr * 20.0);
  }

  /// Cubic ease-out for a natural pole-drop deceleration.
  double _easeOut(double t) {
    final inv = 1.0 - t;
    return 1.0 - inv * inv * inv;
  }
}
