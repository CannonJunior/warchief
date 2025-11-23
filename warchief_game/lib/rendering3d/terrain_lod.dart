import 'package:vector_math/vector_math.dart' hide SimplexNoise;
import 'dart:typed_data';
import 'mesh.dart';
import 'heightmap.dart' show Heightmap, SimplexNoise;

/// TerrainLOD - Level of Detail system for terrain rendering
///
/// Generates multiple detail levels of terrain and switches between them
/// based on distance from camera to optimize performance.
///
/// LOD Levels:
/// - LOD 0 (Highest): Full detail, every vertex (1x spacing)
/// - LOD 1 (Medium): Half detail, every 2nd vertex (2x spacing)
/// - LOD 2 (Lowest): Quarter detail, every 4th vertex (4x spacing)
///
/// Performance benefit: Reduces triangle count by 75-93% for distant terrain.
class TerrainLOD {
  /// LOD distance thresholds (in world units)
  static const double lodDistance0 = 20.0;  // 0-20 units: LOD 0 (full detail)
  static const double lodDistance1 = 50.0;  // 20-50 units: LOD 1 (medium)
  // 50+ units: LOD 2 (low detail)

  /// Calculate LOD level based on distance from camera
  ///
  /// Parameters:
  /// - distance: Distance from camera to terrain chunk center
  ///
  /// Returns: LOD level (0 = highest detail, 2 = lowest detail)
  static int calculateLODLevel(double distance) {
    if (distance < lodDistance0) {
      return 0; // Full detail
    } else if (distance < lodDistance1) {
      return 1; // Medium detail
    } else {
      return 2; // Low detail
    }
  }

  /// Get vertex spacing for LOD level
  ///
  /// Parameters:
  /// - lodLevel: LOD level (0, 1, or 2)
  ///
  /// Returns: Vertex spacing multiplier
  static int getVertexSpacing(int lodLevel) {
    switch (lodLevel) {
      case 0:
        return 1; // Every vertex
      case 1:
        return 2; // Every 2nd vertex
      case 2:
        return 4; // Every 4th vertex
      default:
        return 1;
    }
  }

  /// Create a LOD mesh from heightmap
  ///
  /// Generates a mesh with reduced vertex count based on LOD level.
  ///
  /// Parameters:
  /// - heightmap: Source heightmap data
  /// - width: Terrain width in tiles
  /// - height: Terrain height in tiles
  /// - tileSize: Size of each tile in world units
  /// - lodLevel: LOD level (0 = full, 1 = half, 2 = quarter)
  ///
  /// Returns: Mesh with appropriate detail level
  static Mesh createLODMesh({
    required Heightmap heightmap,
    required int width,
    required int height,
    required double tileSize,
    required int lodLevel,
  }) {
    final spacing = getVertexSpacing(lodLevel);
    final color = Vector3(0.4, 0.6, 0.3); // Grass green

    // Calculate reduced vertex count
    final lodWidth = (width / spacing).ceil();
    final lodHeight = (height / spacing).ceil();
    final vertexCount = (lodWidth + 1) * (lodHeight + 1);
    final triangleCount = lodWidth * lodHeight * 2;

    // Allocate arrays
    final vertices = Float32List(vertexCount * 3);
    final normals = Float32List(vertexCount * 3);
    final colors = Float32List(vertexCount * 4);
    final indices = Uint16List(triangleCount * 3);

    // Generate vertices (skip vertices based on LOD spacing)
    int vertIdx = 0;
    for (int z = 0; z <= height; z += spacing) {
      for (int x = 0; x <= width; x += spacing) {
        // Center grid around origin
        final posX = (x - width / 2.0) * tileSize;
        final posZ = (z - height / 2.0) * tileSize;

        // Get height from heightmap (clamp to bounds)
        final heightX = x.clamp(0, width);
        final heightZ = z.clamp(0, height);
        final terrainHeight = heightmap.getHeightAt(heightX, heightZ);

        vertices[vertIdx * 3 + 0] = posX;
        vertices[vertIdx * 3 + 1] = terrainHeight;
        vertices[vertIdx * 3 + 2] = posZ;

        // Normal points up (could be improved with proper normal calculation)
        normals[vertIdx * 3 + 0] = 0.0;
        normals[vertIdx * 3 + 1] = 1.0;
        normals[vertIdx * 3 + 2] = 0.0;

        // Color based on height for visual variety
        final heightFactor = terrainHeight / heightmap.maxHeight;
        final r = color.x * (0.7 + heightFactor * 0.3);
        final g = color.y * (0.7 + heightFactor * 0.3);
        final b = color.z * (0.7 + heightFactor * 0.3);

        colors[vertIdx * 4 + 0] = r;
        colors[vertIdx * 4 + 1] = g;
        colors[vertIdx * 4 + 2] = b;
        colors[vertIdx * 4 + 3] = 1.0;

        vertIdx++;
      }
    }

    // Generate indices (two triangles per tile)
    int idxIdx = 0;
    for (int z = 0; z < lodHeight; z++) {
      for (int x = 0; x < lodWidth; x++) {
        // Vertex indices for this tile's corners
        final topLeft = z * (lodWidth + 1) + x;
        final topRight = topLeft + 1;
        final bottomLeft = (z + 1) * (lodWidth + 1) + x;
        final bottomRight = bottomLeft + 1;

        // First triangle (top-left, bottom-left, bottom-right)
        indices[idxIdx++] = topLeft;
        indices[idxIdx++] = bottomLeft;
        indices[idxIdx++] = bottomRight;

        // Second triangle (top-left, bottom-right, top-right)
        indices[idxIdx++] = topLeft;
        indices[idxIdx++] = bottomRight;
        indices[idxIdx++] = topRight;
      }
    }

    return Mesh(
      vertices: vertices,
      indices: indices,
      normals: normals,
      colors: colors,
    );
  }

  /// Get vertex count for LOD level
  static int getVertexCount(int width, int height, int lodLevel) {
    final spacing = getVertexSpacing(lodLevel);
    final lodWidth = (width / spacing).ceil();
    final lodHeight = (height / spacing).ceil();
    return (lodWidth + 1) * (lodHeight + 1);
  }

  /// Get triangle count for LOD level
  static int getTriangleCount(int width, int height, int lodLevel) {
    final spacing = getVertexSpacing(lodLevel);
    final lodWidth = (width / spacing).ceil();
    final lodHeight = (height / spacing).ceil();
    return lodWidth * lodHeight * 2;
  }

  /// Get statistics string for LOD level
  static String getStats(int width, int height, int lodLevel) {
    final vertices = getVertexCount(width, height, lodLevel);
    final triangles = getTriangleCount(width, height, lodLevel);
    final spacing = getVertexSpacing(lodLevel);
    return 'LOD $lodLevel (${spacing}x spacing) | Vertices: $vertices | Triangles: $triangles';
  }
}

/// TerrainChunkWithLOD - Terrain chunk with multiple LOD meshes
///
/// Stores 3 meshes (LOD 0, 1, 2) and switches between them based on
/// distance from camera.
class TerrainChunkWithLOD {
  /// Chunk grid coordinates
  final int chunkX;
  final int chunkZ;

  /// Size of chunk (tiles per side)
  final int size;

  /// World position of chunk center
  final Vector3 worldPosition;

  /// LOD meshes (indexed by LOD level)
  final List<Mesh> lodMeshes;

  /// Heightmap for collision detection
  final Heightmap heightmap;

  /// Tile size
  final double tileSize;

  /// Current distance from camera
  double distanceFromCamera = 0.0;

  /// Current LOD level being rendered
  int currentLOD = 0;

  TerrainChunkWithLOD({
    required this.chunkX,
    required this.chunkZ,
    required this.size,
    required this.worldPosition,
    required this.lodMeshes,
    required this.heightmap,
    required this.tileSize,
  });

  /// Generate all LOD levels for a terrain chunk
  static TerrainChunkWithLOD generate({
    required int chunkX,
    required int chunkZ,
    int size = 16,
    double tileSize = 1.0,
    double maxHeight = 3.0,
    required int seed,
    double noiseScale = 0.03,
    int noiseOctaves = 2,
    double noisePersistence = 0.5,
  }) {
    // Calculate world position
    final worldX = chunkX * size * tileSize;
    final worldZ = chunkZ * size * tileSize;
    final worldPosition = Vector3(worldX, 0, worldZ);

    // Generate heightmap
    final heightmap = Heightmap(
      width: size + 1,
      height: size + 1,
      tileSize: tileSize,
      maxHeight: maxHeight,
    );

    // Generate Perlin noise using world coordinates for seamless edges
    _generateChunkPerlinNoise(
      heightmap,
      chunkX: chunkX,
      chunkZ: chunkZ,
      size: size,
      seed: seed,
      scale: noiseScale,
      octaves: noiseOctaves,
      persistence: noisePersistence,
    );

    // Generate 3 LOD meshes
    final lodMeshes = <Mesh>[];
    for (int lodLevel = 0; lodLevel < 3; lodLevel++) {
      final mesh = TerrainLOD.createLODMesh(
        heightmap: heightmap,
        width: size,
        height: size,
        tileSize: tileSize,
        lodLevel: lodLevel,
      );
      lodMeshes.add(mesh);
    }

    return TerrainChunkWithLOD(
      chunkX: chunkX,
      chunkZ: chunkZ,
      size: size,
      worldPosition: worldPosition,
      lodMeshes: lodMeshes,
      heightmap: heightmap,
      tileSize: tileSize,
    );
  }

  /// Generate Perlin noise for chunk (same as TerrainChunk)
  static void _generateChunkPerlinNoise(
    Heightmap heightmap, {
    required int chunkX,
    required int chunkZ,
    required int size,
    required int seed,
    required double scale,
    required int octaves,
    required double persistence,
  }) {
    final noise = SimplexNoise(seed: seed);

    for (int z = 0; z <= size; z++) {
      for (int x = 0; x <= size; x++) {
        final worldX = (chunkX * size + x);
        final worldZ = (chunkZ * size + z);

        double amplitude = 1.0;
        double frequency = scale;
        double noiseValue = 0.0;
        double maxValue = 0.0;

        for (int i = 0; i < octaves; i++) {
          final sampleX = worldX * frequency;
          final sampleZ = worldZ * frequency;

          final noise2D = noise.noise2D(sampleX, sampleZ);
          noiseValue += noise2D * amplitude;
          maxValue += amplitude;

          amplitude *= persistence;
          frequency *= 2.0;
        }

        noiseValue = (noiseValue / maxValue + 1.0) / 2.0;
        heightmap.setHeightAt(x, z, noiseValue * heightmap.maxHeight);
      }
    }
  }

  /// Update distance from camera and select appropriate LOD
  void updateLOD(Vector3 cameraPosition) {
    distanceFromCamera = (worldPosition - cameraPosition).length;
    currentLOD = TerrainLOD.calculateLODLevel(distanceFromCamera);
  }

  /// Get current LOD mesh
  Mesh get currentMesh => lodMeshes[currentLOD];

  /// Get terrain height at world position
  double? getHeightAt(double worldX, double worldZ) {
    final localX = worldX - worldPosition.x;
    final localZ = worldZ - worldPosition.z;

    final halfSize = (size * tileSize) / 2;
    if (localX < -halfSize || localX > halfSize ||
        localZ < -halfSize || localZ > halfSize) {
      return null;
    }

    return heightmap.getTerrainHeight(localX, localZ);
  }

  /// Get chunk key
  String get key => '$chunkX,$chunkZ';

  /// Get stats
  String getStats() {
    return 'Chunk[$chunkX,$chunkZ] | Distance: ${distanceFromCamera.toStringAsFixed(1)} | ${TerrainLOD.getStats(size, size, currentLOD)}';
  }

  @override
  String toString() {
    return 'TerrainChunkWithLOD(chunk: [$chunkX, $chunkZ], LOD: $currentLOD, distance: ${distanceFromCamera.toStringAsFixed(1)})';
  }
}
