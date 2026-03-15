enum MapMode { world, dungeon }

/// Map panel state — zoom level, view mode, pan offset, and floor selection.
///
/// Shared between [MapPanel], [WorldMapPainter], and [DungeonMapPainter].
class MapState {
  // ==================== STATE ====================

  MapMode mode = MapMode.world;

  /// Index into [worldZoomLevels] (0 = closest, 4 = farthest).
  int zoomLevel = 2;

  /// Dungeon floor currently displayed in floor-plan mode (0-indexed).
  int selectedFloor = 0;

  /// World map pan offset in world units (allows dragging the map view).
  double panX = 0.0;
  double panZ = 0.0;

  /// Dirty flag — set true whenever zoom or pan changes so painters can
  /// rebuild their terrain cache.
  bool terrainDirty = true;

  // ==================== ZOOM TABLE ====================

  /// Ordered list of view radii (world units) for each zoom level.
  static const List<double> worldZoomLevels = [
    200.0,     // 0 — Street
    1000.0,    // 1 — District
    5000.0,    // 2 — Regional (default)
    25000.0,   // 3 — Territory
    100000.0,  // 4 — Continent
  ];

  /// Human-readable label for each zoom level.
  static const List<String> worldZoomLabels = [
    'Street', 'District', 'Regional', 'Territory', 'Continent',
  ];

  /// Painter resolution (samples per side) for each zoom level.
  static const List<int> worldZoomResolutions = [64, 80, 96, 112, 128];

  double get viewRadius => worldZoomLevels[zoomLevel];
  String get zoomLabel  => worldZoomLabels[zoomLevel];
  int    get resolution => worldZoomResolutions[zoomLevel];

  // ==================== ACTIONS ====================

  void zoomIn() {
    if (zoomLevel > 0) { zoomLevel--; terrainDirty = true; }
  }

  void zoomOut() {
    if (zoomLevel < worldZoomLevels.length - 1) { zoomLevel++; terrainDirty = true; }
  }

  void pan(double dx, double dz) {
    panX += dx;
    panZ += dz;
    terrainDirty = true;
  }

  void resetPan() {
    panX = 0.0;
    panZ = 0.0;
    terrainDirty = true;
  }
}
