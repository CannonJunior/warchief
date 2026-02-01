import 'package:vector_math/vector_math.dart' hide SimplexNoise;
import 'dart:typed_data';
import 'dart:math' as math;
import 'mesh.dart';
import 'heightmap.dart' show Heightmap, SimplexNoise;
import 'splat_map_generator.dart';

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

  /// Create a LOD mesh from heightmap with UV coordinates and proper normals
  ///
  /// Generates a mesh with reduced vertex count based on LOD level.
  /// Includes UV coordinates for texture splatting and calculated normals
  /// from heightmap gradients.
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
    final color = Vector3(0.4, 0.6, 0.3); // Grass green (fallback color)

    // Calculate reduced vertex count
    final lodWidth = (width / spacing).ceil();
    final lodHeight = (height / spacing).ceil();
    final vertexCount = (lodWidth + 1) * (lodHeight + 1);
    final triangleCount = lodWidth * lodHeight * 2;

    // Allocate arrays
    final vertices = Float32List(vertexCount * 3);
    final normals = Float32List(vertexCount * 3);
    final colors = Float32List(vertexCount * 4);
    final texCoords = Float32List(vertexCount * 2);
    final indices = Uint16List(triangleCount * 3);

    // First pass: Generate vertices and UV coordinates
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

        // UV coordinates: 0.0 to 1.0 across the chunk for splat map sampling
        // These coordinates are seamless at chunk borders
        texCoords[vertIdx * 2 + 0] = x / width.toDouble();
        texCoords[vertIdx * 2 + 1] = z / height.toDouble();

        // Color based on height for visual variety (fallback when textures disabled)
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

    // Second pass: Calculate normals from heightmap gradients
    _calculateTerrainNormals(
      normals: normals,
      heightmap: heightmap,
      width: width,
      height: height,
      spacing: spacing,
      tileSize: tileSize,
    );

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
      texCoords: texCoords,
      colors: colors,
    );
  }

  /// Calculate terrain normals from heightmap gradients
  ///
  /// Uses central difference method to calculate surface normals
  /// based on the slope of the terrain at each vertex.
  static void _calculateTerrainNormals({
    required Float32List normals,
    required Heightmap heightmap,
    required int width,
    required int height,
    required int spacing,
    required double tileSize,
  }) {
    int vertIdx = 0;

    for (int z = 0; z <= height; z += spacing) {
      for (int x = 0; x <= width; x += spacing) {
        // Sample heights at neighboring points for gradient calculation
        // Use central differences where possible
        final xLeft = (x - spacing).clamp(0, width);
        final xRight = (x + spacing).clamp(0, width);
        final zUp = (z - spacing).clamp(0, height);
        final zDown = (z + spacing).clamp(0, height);

        final heightLeft = heightmap.getHeightAt(xLeft, z);
        final heightRight = heightmap.getHeightAt(xRight, z);
        final heightUp = heightmap.getHeightAt(x, zUp);
        final heightDown = heightmap.getHeightAt(x, zDown);

        // Calculate gradient (rate of height change)
        // Divide by actual distance to get proper slope
        final dx = (xRight - xLeft) * tileSize;
        final dz = (zDown - zUp) * tileSize;

        double gradX = 0.0;
        double gradZ = 0.0;

        if (dx > 0) {
          gradX = (heightRight - heightLeft) / dx;
        }
        if (dz > 0) {
          gradZ = (heightDown - heightUp) / dz;
        }

        // Create normal vector from gradient
        // Normal = normalize((-gradX, 1, -gradZ))
        // The negative gradients point "uphill", and we want the normal to point "up"
        var nx = -gradX;
        var ny = 1.0;
        var nz = -gradZ;

        // Normalize
        final len = math.sqrt(nx * nx + ny * ny + nz * nz);
        if (len > 0.0001) {
          nx /= len;
          ny /= len;
          nz /= len;
        } else {
          // Flat surface, normal points straight up
          nx = 0.0;
          ny = 1.0;
          nz = 0.0;
        }

        normals[vertIdx * 3 + 0] = nx;
        normals[vertIdx * 3 + 1] = ny;
        normals[vertIdx * 3 + 2] = nz;

        vertIdx++;
      }
    }
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
/// distance from camera. Includes splat map data for texture splatting.
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

  /// Splat map data for this chunk (RGBA: grass, dirt, rock, sand)
  /// Stored as Float32List for precision, converted to texture when rendering
  Float32List? splatMapData;

  /// Resolution of splat map (width = height = splatMapResolution)
  int splatMapResolution;

  /// WebGL texture for splat map (created by renderer)
  dynamic splatMapTexture;

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
    this.splatMapData,
    this.splatMapResolution = 16,
    this.splatMapTexture,
  });

  /// Generate all LOD levels for a terrain chunk with splat map
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
    bool generateSplatMap = true,
    int splatMapResolution = 16,
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

    // Generate splat map if enabled
    Float32List? splatMapData;
    if (generateSplatMap) {
      splatMapData = SplatMapGenerator.generateSplatMap(
        heightmap: heightmap,
        resolution: splatMapResolution,
        maxHeight: maxHeight,
        seed: seed + chunkX * 1000 + chunkZ, // Vary by chunk for natural look
      );
    }

    return TerrainChunkWithLOD(
      chunkX: chunkX,
      chunkZ: chunkZ,
      size: size,
      worldPosition: worldPosition,
      lodMeshes: lodMeshes,
      heightmap: heightmap,
      tileSize: tileSize,
      splatMapData: splatMapData,
      splatMapResolution: splatMapResolution,
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

  /// Check if this chunk has splat map data
  bool get hasSplatMap => splatMapData != null;

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

  /// Get slope at world position (0 = vertical cliff, 1 = flat ground)
  ///
  /// Returns null if position is outside chunk bounds.
  double? getSlopeAt(double worldX, double worldZ) {
    final localX = worldX - worldPosition.x;
    final localZ = worldZ - worldPosition.z;

    final halfSize = (size * tileSize) / 2;
    if (localX < -halfSize || localX > halfSize ||
        localZ < -halfSize || localZ > halfSize) {
      return null;
    }

    // Convert to grid coordinates
    final gridX = ((localX / tileSize) + size / 2.0).toInt().clamp(0, size - 1);
    final gridZ = ((localZ / tileSize) + size / 2.0).toInt().clamp(0, size - 1);

    // Calculate slope from neighboring heights
    final heightLeft = heightmap.getHeightAt((gridX - 1).clamp(0, size), gridZ);
    final heightRight = heightmap.getHeightAt((gridX + 1).clamp(0, size), gridZ);
    final heightUp = heightmap.getHeightAt(gridX, (gridZ - 1).clamp(0, size));
    final heightDown = heightmap.getHeightAt(gridX, (gridZ + 1).clamp(0, size));

    // Calculate gradient magnitude
    final gradX = (heightRight - heightLeft) / (2 * tileSize);
    final gradZ = (heightDown - heightUp) / (2 * tileSize);
    final gradMagnitude = math.sqrt(gradX * gradX + gradZ * gradZ);

    // Convert to slope (1 = flat, 0 = vertical)
    // slope = cos(atan(gradMagnitude)) = 1 / sqrt(1 + gradMagnitude^2)
    return 1.0 / math.sqrt(1.0 + gradMagnitude * gradMagnitude);
  }

  /// Dispose splat map texture (call when unloading chunk)
  void disposeSplatMapTexture(dynamic gl) {
    if (splatMapTexture != null && gl != null) {
      gl.deleteTexture(splatMapTexture);
      splatMapTexture = null;
    }
  }

  /// Get chunk key
  String get key => '$chunkX,$chunkZ';

  /// Get stats
  String getStats() {
    final splatInfo = hasSplatMap ? ' | SplatMap: ${splatMapResolution}x${splatMapResolution}' : '';
    return 'Chunk[$chunkX,$chunkZ] | Distance: ${distanceFromCamera.toStringAsFixed(1)} | ${TerrainLOD.getStats(size, size, currentLOD)}$splatInfo';
  }

  @override
  String toString() {
    return 'TerrainChunkWithLOD(chunk: [$chunkX, $chunkZ], LOD: $currentLOD, distance: ${distanceFromCamera.toStringAsFixed(1)})';
  }
}
