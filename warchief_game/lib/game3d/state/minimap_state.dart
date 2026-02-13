import 'dart:ui';
import 'minimap_config.dart';

/// Ping type categories for different communication intent.
enum PingType { general, danger, assist, onMyWay }

/// A single ping placed on the minimap at a world position.
///
/// Pings decay over time (configurable via minimap_config.json).
/// They render as expanding concentric rings on the minimap and
/// as a diamond icon in the 3D world view.
class MinimapPing {
  /// World-space X coordinate of the ping.
  final double worldX;

  /// World-space Z coordinate of the ping.
  final double worldZ;

  /// Time (elapsed seconds) when this ping was created.
  final double createTime;

  /// Color of the ping rings.
  final Color color;

  /// Type of ping for visual differentiation.
  final PingType type;

  MinimapPing({
    required this.worldX,
    required this.worldZ,
    required this.createTime,
    required this.color,
    this.type = PingType.general,
  });

  /// Check if this ping has exceeded its decay duration.
  bool isExpired(double now) {
    final decay = globalMinimapConfig?.pingDecayDuration ?? 5.0;
    return (now - createTime) > decay;
  }

  /// Get normalized age (0.0 = just created, 1.0 = about to expire).
  double normalizedAge(double now) {
    final decay = globalMinimapConfig?.pingDecayDuration ?? 5.0;
    return ((now - createTime) / decay).clamp(0.0, 1.0);
  }
}

/// Minimap state: zoom level, active pings, elapsed time, terrain cache.
///
/// Updated every frame from the game loop via [update(dt)].
/// Manages ping lifecycle (creation, decay, removal) and zoom controls.
class MinimapState {
  /// Total elapsed time in seconds (drives sun orbital positions).
  double elapsedTime = 0.0;

  /// Current zoom level index into config's zoom.levels array.
  int zoomLevel = 1;

  /// Active pings on the minimap.
  List<MinimapPing> pings = [];

  /// Whether the clock is in "Warchief time" mode (stub).
  bool warchiefTimeMode = false;

  /// Whether the minimap rotates with the player (true) or is fixed-north (false).
  bool isRotatingMode = true;

  // ==================== TERRAIN CACHE ====================

  /// Cached terrain image (regenerated when player moves too far).
  // Reason: using dynamic type to avoid importing dart:ui Image
  // in game_state.dart; the actual painter handles the typed image.
  double cacheWorldX = 0.0;
  double cacheWorldZ = 0.0;
  double cacheRadius = 50.0;
  bool terrainDirty = true;

  // ==================== UPDATE ====================

  /// Advance time and remove expired pings.
  ///
  /// Called every frame from game3d_widget._update().
  void update(double dt) {
    elapsedTime += dt;
    pings.removeWhere((p) => p.isExpired(elapsedTime));
  }

  // ==================== PINGS ====================

  /// Add a ping at the given world position.
  ///
  /// Removes the oldest ping if the maximum active count is exceeded.
  void addPing(MinimapPing ping) {
    final maxPings = globalMinimapConfig?.maxActivePings ?? 5;
    if (pings.length >= maxPings) pings.removeAt(0);
    pings.add(ping);
  }

  // ==================== ZOOM ====================

  /// Get the current view radius in world units.
  double get viewRadius {
    final levels = globalMinimapConfig?.zoomLevels ?? [25.0, 50.0, 100.0, 150.0];
    if (zoomLevel >= 0 && zoomLevel < levels.length) {
      return levels[zoomLevel];
    }
    return 50.0;
  }

  /// Zoom in (decrease view radius).
  void zoomIn() {
    if (zoomLevel > 0) {
      zoomLevel--;
      terrainDirty = true;
    }
  }

  /// Zoom out (increase view radius).
  void zoomOut() {
    final levels = globalMinimapConfig?.zoomLevels ?? [25.0, 50.0, 100.0, 150.0];
    if (zoomLevel < levels.length - 1) {
      zoomLevel++;
      terrainDirty = true;
    }
  }

  /// Initialize zoom level from config default.
  void initZoomFromConfig() {
    zoomLevel = globalMinimapConfig?.defaultZoomLevel ?? 1;
  }
}
