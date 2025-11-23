import 'package:vector_math/vector_math.dart';
import 'terrain_chunk.dart';

/// ChunkManager - Manages loading and unloading of terrain chunks
///
/// Responsibilities:
/// - Generate chunks near the player
/// - Unload chunks far from the player
/// - Cache chunks for reuse
/// - Provide efficient chunk lookups
///
/// Performance benefits:
/// - Only render visible chunks (reduce GPU load)
/// - Only keep nearby chunks in memory (reduce RAM usage)
/// - Support infinite terrain (procedural generation)
class ChunkManager {
  /// Active chunks (currently loaded)
  final Map<String, TerrainChunk> _chunks = {};

  /// Chunk size (tiles per chunk side)
  final int chunkSize;

  /// Tile size (world units per tile)
  final double tileSize;

  /// Render distance (in chunks)
  final int renderDistance;

  /// Maximum terrain height
  final double maxHeight;

  /// Random seed for terrain generation
  final int seed;

  /// Terrain type ('perlin', 'hills', 'flat')
  final String terrainType;

  /// Last player chunk position (for detecting when player moves to new chunk)
  int _lastPlayerChunkX = 0;
  int _lastPlayerChunkZ = 0;

  /// Statistics
  int chunksGenerated = 0;
  int chunksUnloaded = 0;

  ChunkManager({
    this.chunkSize = 16,
    this.tileSize = 1.0,
    this.renderDistance = 3,
    this.maxHeight = 10.0,
    this.seed = 42,
    this.terrainType = 'perlin',
  });

  /// Update chunk loading based on player position
  ///
  /// Call this every frame or when player moves significantly.
  ///
  /// Parameters:
  /// - playerPosition: Current player world position
  void update(Vector3 playerPosition) {
    // Convert player world position to chunk coordinates
    final playerChunkX = _worldToChunkCoord(playerPosition.x);
    final playerChunkZ = _worldToChunkCoord(playerPosition.z);

    // Only update chunks if player moved to a new chunk
    if (playerChunkX == _lastPlayerChunkX && playerChunkZ == _lastPlayerChunkZ) {
      // Update distances but don't load/unload
      _updateChunkDistances(playerPosition);
      return;
    }

    _lastPlayerChunkX = playerChunkX;
    _lastPlayerChunkZ = playerChunkZ;

    // Load chunks in render distance
    _loadChunksAround(playerChunkX, playerChunkZ);

    // Unload chunks outside render distance
    _unloadDistantChunks(playerChunkX, playerChunkZ);

    // Update chunk distances from camera
    _updateChunkDistances(playerPosition);
  }

  /// Get all currently loaded chunks
  List<TerrainChunk> getLoadedChunks() {
    return _chunks.values.toList();
  }

  /// Get chunk at specific chunk coordinates
  TerrainChunk? getChunk(int chunkX, int chunkZ) {
    return _chunks[TerrainChunk.makeKey(chunkX, chunkZ)];
  }

  /// Get chunk containing a world position
  TerrainChunk? getChunkAtWorldPosition(double worldX, double worldZ) {
    final chunkX = _worldToChunkCoord(worldX);
    final chunkZ = _worldToChunkCoord(worldZ);
    return getChunk(chunkX, chunkZ);
  }

  /// Get terrain height at world position
  ///
  /// Queries the appropriate chunk's heightmap.
  ///
  /// Parameters:
  /// - worldX/worldZ: World coordinates
  ///
  /// Returns: Terrain height, or 0.0 if chunk not loaded
  double getTerrainHeight(double worldX, double worldZ) {
    final chunk = getChunkAtWorldPosition(worldX, worldZ);
    if (chunk == null) {
      return 0.0; // Chunk not loaded, return ground level
    }

    final height = chunk.getHeightAt(worldX, worldZ);
    return height ?? 0.0;
  }

  /// Load chunks in a square grid around player
  void _loadChunksAround(int centerChunkX, int centerChunkZ) {
    for (int dx = -renderDistance; dx <= renderDistance; dx++) {
      for (int dz = -renderDistance; dz <= renderDistance; dz++) {
        final chunkX = centerChunkX + dx;
        final chunkZ = centerChunkZ + dz;
        final key = TerrainChunk.makeKey(chunkX, chunkZ);

        // Skip if chunk already loaded
        if (_chunks.containsKey(key)) {
          continue;
        }

        // Generate new chunk
        final chunk = TerrainChunk.generate(
          chunkX: chunkX,
          chunkZ: chunkZ,
          size: chunkSize,
          tileSize: tileSize,
          maxHeight: maxHeight,
          seed: seed,
          terrainType: terrainType,
        );

        _chunks[key] = chunk;
        chunksGenerated++;
      }
    }
  }

  /// Unload chunks outside render distance
  void _unloadDistantChunks(int centerChunkX, int centerChunkZ) {
    final chunksToRemove = <String>[];

    for (final entry in _chunks.entries) {
      final chunk = entry.value;
      final dx = (chunk.chunkX - centerChunkX).abs();
      final dz = (chunk.chunkZ - centerChunkZ).abs();

      // Unload if outside render distance (with small buffer)
      if (dx > renderDistance + 1 || dz > renderDistance + 1) {
        chunksToRemove.add(entry.key);
      }
    }

    for (final key in chunksToRemove) {
      _chunks.remove(key);
      chunksUnloaded++;
    }
  }

  /// Update distance from camera for all chunks
  void _updateChunkDistances(Vector3 cameraPosition) {
    for (final chunk in _chunks.values) {
      chunk.updateDistanceFromCamera(cameraPosition);
    }
  }

  /// Convert world coordinate to chunk coordinate
  int _worldToChunkCoord(double worldCoord) {
    final chunkWorldSize = chunkSize * tileSize;
    return (worldCoord / chunkWorldSize).floor();
  }

  /// Get number of loaded chunks
  int get loadedChunkCount => _chunks.length;

  /// Get total vertices across all loaded chunks
  int get totalVertices {
    return loadedChunkCount * (chunkSize + 1) * (chunkSize + 1);
  }

  /// Get total triangles across all loaded chunks
  int get totalTriangles {
    return loadedChunkCount * chunkSize * chunkSize * 2;
  }

  /// Clear all chunks (useful for resetting world)
  void clear() {
    _chunks.clear();
    chunksGenerated = 0;
    chunksUnloaded = 0;
    _lastPlayerChunkX = 0;
    _lastPlayerChunkZ = 0;
  }

  /// Get statistics string for debugging
  String getStats() {
    return 'Chunks: ${loadedChunkCount} loaded, $chunksGenerated generated, $chunksUnloaded unloaded | '
        'Vertices: $totalVertices | Triangles: $totalTriangles';
  }

  @override
  String toString() {
    return 'ChunkManager(chunks: $loadedChunkCount, size: $chunkSize, render distance: $renderDistance)';
  }
}
