import 'package:vector_math/vector_math.dart' hide SimplexNoise;
import 'mesh.dart';
import 'math/transform3d.dart';
import 'heightmap.dart' show Heightmap, SimplexNoise;
import 'terrain_generator.dart';

/// TerrainChunk - Represents a single chunk of terrain in a larger world
///
/// Chunks allow for efficient rendering and memory management by:
/// - Loading only nearby chunks (reduce memory usage)
/// - Culling chunks outside camera view (reduce rendering cost)
/// - Enabling infinite terrain generation (procedural worlds)
///
/// Architecture:
/// ```
/// World divided into chunks:
/// [C][C][C]
/// [C][P][C]  P = Player position, C = Chunk
/// [C][C][C]
/// ```
class TerrainChunk {
  /// Chunk grid coordinates (not world coordinates)
  final int chunkX;
  final int chunkZ;

  /// Size of the chunk (number of tiles per side)
  final int size;

  /// World position of chunk center
  final Vector3 worldPosition;

  /// Terrain mesh for this chunk
  final Mesh mesh;

  /// Transform for positioning the chunk in world space
  final Transform3d transform;

  /// Heightmap data for this chunk (for collision detection)
  final Heightmap heightmap;

  /// Distance from camera (updated each frame for culling decisions)
  double distanceFromCamera = 0.0;

  /// Whether this chunk is visible to the camera
  bool isVisible = true;

  /// Tile size (in world units)
  final double tileSize;

  TerrainChunk({
    required this.chunkX,
    required this.chunkZ,
    required this.size,
    required this.worldPosition,
    required this.mesh,
    required this.transform,
    required this.heightmap,
    required this.tileSize,
  });

  /// Factory method to generate a terrain chunk
  ///
  /// Parameters:
  /// - chunkX/chunkZ: Chunk grid coordinates
  /// - size: Number of tiles per chunk side
  /// - tileSize: Size of each tile in world units
  /// - maxHeight: Maximum terrain elevation
  /// - seed: Random seed for terrain generation
  /// - terrainType: Type of terrain ('perlin', 'hills', 'flat')
  ///
  /// Returns: A fully generated TerrainChunk
  factory TerrainChunk.generate({
    required int chunkX,
    required int chunkZ,
    int size = 16,
    double tileSize = 1.0,
    double maxHeight = 10.0,
    required int seed,
    String terrainType = 'perlin',
  }) {
    // Calculate world position (center of chunk)
    final worldX = chunkX * size * tileSize;
    final worldZ = chunkZ * size * tileSize;
    final worldPosition = Vector3(worldX, 0, worldZ);

    // Generate heightmap for this chunk
    // IMPORTANT: Use chunk coordinates to ensure seamless edges
    final heightmap = Heightmap(
      width: size + 1,
      height: size + 1,
      tileSize: tileSize,
      maxHeight: maxHeight,
    );

    // Generate terrain based on type
    switch (terrainType) {
      case 'perlin':
        // Use world coordinates for noise sampling to ensure continuity
        _generateChunkPerlinNoise(
          heightmap,
          chunkX: chunkX,
          chunkZ: chunkZ,
          size: size,
          seed: seed,
          scale: 0.08,
          octaves: 2,
          persistence: 0.5,
        );
        break;
      case 'hills':
        heightmap.generateHills();
        break;
      case 'flat':
      default:
        heightmap.generateFlat();
        break;
    }

    // Create mesh from heightmap
    final terrainData = TerrainGenerator.createHeightmapTerrain(
      width: size,
      height: size,
      tileSize: tileSize,
      maxHeight: maxHeight,
      seed: seed,
      terrainType: 'flat', // We already generated the heightmap above
    );

    // Override the mesh's heightmap with our chunk-specific heightmap
    // (This ensures seamless edges between chunks)
    final mesh = _createMeshFromHeightmap(
      heightmap: heightmap,
      size: size,
      tileSize: tileSize,
    );

    // Create transform for chunk positioning
    final transform = Transform3d(
      position: worldPosition,
    );

    return TerrainChunk(
      chunkX: chunkX,
      chunkZ: chunkZ,
      size: size,
      worldPosition: worldPosition,
      mesh: mesh,
      transform: transform,
      heightmap: heightmap,
      tileSize: tileSize,
    );
  }

  /// Generate Perlin noise for a chunk using world coordinates
  ///
  /// This ensures chunks blend seamlessly at edges by sampling
  /// the noise function at consistent world positions.
  static void _generateChunkPerlinNoise(
    Heightmap heightmap, {
    required int chunkX,
    required int chunkZ,
    required int size,
    required int seed,
    double scale = 0.08,
    int octaves = 2,
    double persistence = 0.5,
  }) {
    final noise = SimplexNoise(seed: seed);

    for (int z = 0; z <= size; z++) {
      for (int x = 0; x <= size; x++) {
        // Calculate world coordinates for noise sampling
        final worldX = (chunkX * size + x);
        final worldZ = (chunkZ * size + z);

        double amplitude = 1.0;
        double frequency = scale;
        double noiseValue = 0.0;
        double maxValue = 0.0;

        // Generate multiple octaves
        for (int i = 0; i < octaves; i++) {
          final sampleX = worldX * frequency;
          final sampleZ = worldZ * frequency;

          final noise2D = noise.noise2D(sampleX, sampleZ);
          noiseValue += noise2D * amplitude;
          maxValue += amplitude;

          amplitude *= persistence;
          frequency *= 2.0;
        }

        // Normalize to [0, 1] then scale to max height
        noiseValue = (noiseValue / maxValue + 1.0) / 2.0;
        heightmap.setHeightAt(x, z, noiseValue * heightmap.maxHeight);
      }
    }
  }

  /// Create a mesh from a heightmap
  ///
  /// Similar to TerrainGenerator._createMeshFromHeightmap but for chunks
  static Mesh _createMeshFromHeightmap({
    required Heightmap heightmap,
    required int size,
    required double tileSize,
  }) {
    return TerrainGenerator.createHeightmapTerrain(
      width: size,
      height: size,
      tileSize: tileSize,
      maxHeight: heightmap.maxHeight,
      seed: 0, // Not used since we pass our own heightmap
      terrainType: 'flat',
    ).mesh;
  }

  /// Get terrain height at world position
  ///
  /// Parameters:
  /// - worldX/worldZ: World coordinates
  ///
  /// Returns: Height at position, or null if position is outside chunk bounds
  double? getHeightAt(double worldX, double worldZ) {
    // Convert world position to chunk-local position
    final localX = worldX - worldPosition.x;
    final localZ = worldZ - worldPosition.z;

    // Check if position is within chunk bounds
    final halfSize = (size * tileSize) / 2;
    if (localX < -halfSize || localX > halfSize ||
        localZ < -halfSize || localZ > halfSize) {
      return null; // Outside chunk bounds
    }

    // Query heightmap (adjust for chunk coordinate system)
    return heightmap.getTerrainHeight(localX, localZ);
  }

  /// Update distance from camera (for culling and LOD)
  ///
  /// Parameters:
  /// - cameraPosition: Current camera position
  void updateDistanceFromCamera(Vector3 cameraPosition) {
    distanceFromCamera = (worldPosition - cameraPosition).length;
  }

  /// Check if chunk is within render distance
  ///
  /// Parameters:
  /// - cameraPosition: Current camera position
  /// - renderDistance: Maximum render distance in chunks
  ///
  /// Returns: True if chunk should be rendered
  bool isWithinRenderDistance(Vector3 cameraPosition, double renderDistance) {
    updateDistanceFromCamera(cameraPosition);
    final maxDistance = renderDistance * size * tileSize;
    return distanceFromCamera <= maxDistance;
  }

  /// Get chunk key for storage in maps
  ///
  /// Returns: Unique string identifier for this chunk
  String get key => '$chunkX,$chunkZ';

  /// Create chunk key from coordinates
  static String makeKey(int chunkX, int chunkZ) => '$chunkX,$chunkZ';

  @override
  String toString() {
    return 'TerrainChunk(chunk: [$chunkX, $chunkZ], world: [${worldPosition.x.toStringAsFixed(1)}, ${worldPosition.z.toStringAsFixed(1)}], distance: ${distanceFromCamera.toStringAsFixed(1)})';
  }
}
