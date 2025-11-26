/// Terrain configuration for infinite terrain with LOD
///
/// Centralized configuration for the terrain system.
class TerrainConfig {
  TerrainConfig._(); // Private constructor to prevent instantiation

  // ==================== CHUNK CONFIGURATION ====================

  /// Size of each terrain chunk (tiles per side)
  /// Smaller = more chunks, better culling, more overhead
  /// Larger = fewer chunks, less culling, less overhead
  /// Recommended: 16-32 for good balance
  static const int chunkSize = 16;

  /// Render distance (in chunks)
  /// 3 = 7x7 grid (49 chunks max)
  /// 4 = 9x9 grid (81 chunks max)
  /// Recommended: 3-4 for good balance
  static const int renderDistance = 3;

  // ==================== TILE CONFIGURATION ====================

  /// Size of each terrain tile (in world units)
  static const double tileSize = 1.0;

  // ==================== TERRAIN APPEARANCE ====================

  /// Maximum terrain height (reduced for rolling hills)
  /// Lower = gentler slopes, higher = steeper mountains
  /// Recommended: 2.0-4.0 for rolling hills
  static const double maxHeight = 3.0;

  /// Terrain noise scale (controls feature size)
  /// Lower = larger features, gentler slopes
  /// Higher = smaller features, more variation
  /// Recommended: 0.02-0.05 for rolling terrain
  static const double noiseScale = 0.03;

  /// Terrain noise octaves (detail layers)
  /// More octaves = more fine detail (but slower generation)
  /// Recommended: 2-3 for good balance
  static const int noiseOctaves = 2;

  /// Terrain noise persistence (octave contribution)
  /// Lower = smoother terrain
  /// Higher = more variation between scales
  /// Recommended: 0.4-0.6
  static const double noisePersistence = 0.5;

  /// Random seed for terrain generation
  /// Same seed = same terrain (deterministic)
  /// Different seed = different terrain
  static const int seed = 42;

  // ==================== LOD CONFIGURATION ====================

  /// LOD distance thresholds (in world units)
  /// Distance 0: 0 to lodDistance0 = LOD 0 (full detail)
  /// Distance 1: lodDistance0 to lodDistance1 = LOD 1 (half detail)
  /// Distance 2: lodDistance1+ = LOD 2 (quarter detail)

  static const double lodDistance0 = 20.0; // Full detail threshold
  static const double lodDistance1 = 50.0; // Medium detail threshold

  // ==================== PERFORMANCE TUNING ====================

  /// Enable/disable infinite terrain
  /// If false, uses old single-terrain system
  /// If true, uses new chunk-based infinite terrain with LOD
  static const bool useInfiniteTerrain = true;

  /// Enable/disable LOD system
  /// If false, always uses full detail (LOD 0)
  /// If true, switches LOD based on distance
  static const bool useLOD = true;

  /// Enable debug logging for terrain
  static const bool debugLogging = true;

  // ==================== CALCULATED VALUES ====================

  /// Maximum chunks that can be loaded
  /// = (2 * renderDistance + 1)^2
  static int get maxChunks => (2 * renderDistance + 1) * (2 * renderDistance + 1);

  /// Maximum vertices per chunk (LOD 0)
  static int get maxVerticesPerChunk => (chunkSize + 1) * (chunkSize + 1);

  /// Maximum triangles per chunk (LOD 0)
  static int get maxTrianglesPerChunk => chunkSize * chunkSize * 2;

  /// Maximum total vertices (all chunks at LOD 0)
  static int get maxTotalVertices => maxChunks * maxVerticesPerChunk;

  /// Maximum total triangles (all chunks at LOD 0)
  static int get maxTotalTriangles => maxChunks * maxTrianglesPerChunk;

  /// Chunk world size (in world units)
  static double get chunkWorldSize => chunkSize * tileSize;

  // ==================== INFO ====================

  /// Get configuration summary
  static String getSummary() {
    return '''
Terrain Configuration:
  Chunk Size: $chunkSize tiles
  Render Distance: $renderDistance chunks ($maxChunks chunks max)
  Tile Size: $tileSize units
  Max Height: $maxHeight units
  Noise Scale: $noiseScale
  Noise Octaves: $noiseOctaves

Performance:
  Max Vertices: $maxTotalVertices (LOD 0)
  Max Triangles: $maxTotalTriangles (LOD 0)
  LOD Enabled: $useLOD
  Infinite Terrain: $useInfiniteTerrain

LOD Distances:
  LOD 0 (Full): 0-$lodDistance0 units
  LOD 1 (Half): $lodDistance0-$lodDistance1 units
  LOD 2 (Quarter): $lodDistance1+ units
''';
  }
}
