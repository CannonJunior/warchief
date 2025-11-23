import 'package:vector_math/vector_math.dart';
import 'terrain_lod.dart';
import 'game_config_terrain.dart';
import '../game3d/state/game_config.dart';

/// InfiniteTerrainManager - Manages infinite terrain with LOD and chunk loading
///
/// Creates the illusion of infinite terrain by:
/// - Dynamically loading chunks around the player
/// - Unloading distant chunks to save memory
/// - Using LOD to optimize rendering
/// - Generating seamless terrain using world coordinates
///
/// Performance:
/// - Only renders visible chunks
/// - Reduces detail for distant chunks (LOD)
/// - Keeps memory usage constant regardless of travel distance
class InfiniteTerrainManager {
  /// Active chunks (currently loaded)
  final Map<String, TerrainChunkWithLOD> _chunks = {};

  /// Chunk configuration
  final int chunkSize;
  final double tileSize;
  final int renderDistance;
  final double maxHeight;
  final int seed;
  final double noiseScale;
  final int noiseOctaves;
  final double noisePersistence;

  /// Last player chunk position
  int _lastPlayerChunkX = 0;
  int _lastPlayerChunkZ = 0;

  /// Statistics
  int chunksGenerated = 0;
  int chunksUnloaded = 0;
  int totalLOD0 = 0; // High detail chunks
  int totalLOD1 = 0; // Medium detail chunks
  int totalLOD2 = 0; // Low detail chunks

  InfiniteTerrainManager({
    this.chunkSize = 16,
    this.tileSize = 1.0,
    this.renderDistance = 3,
    this.maxHeight = 3.0,
    this.seed = 42,
    this.noiseScale = 0.03,
    this.noiseOctaves = 2,
    this.noisePersistence = 0.5,
  });

  /// Factory constructor from game config
  factory InfiniteTerrainManager.fromConfig() {
    return InfiniteTerrainManager(
      chunkSize: TerrainConfig.chunkSize,
      tileSize: TerrainConfig.tileSize,
      renderDistance: TerrainConfig.renderDistance,
      maxHeight: TerrainConfig.maxHeight,
      seed: TerrainConfig.seed,
      noiseScale: TerrainConfig.noiseScale,
      noiseOctaves: TerrainConfig.noiseOctaves,
      noisePersistence: TerrainConfig.noisePersistence,
    );
  }

  /// Update chunk loading based on player/camera position
  ///
  /// Call this every frame to ensure chunks are loaded around the player.
  ///
  /// Parameters:
  /// - playerPosition: Current player world position
  /// - cameraPosition: Current camera world position (for LOD calculation)
  void update(Vector3 playerPosition, Vector3 cameraPosition) {
    // Convert player position to chunk coordinates
    final playerChunkX = _worldToChunkCoord(playerPosition.x);
    final playerChunkZ = _worldToChunkCoord(playerPosition.z);

    // Update LOD for all chunks based on camera distance
    _updateAllLODs(cameraPosition);

    // Only load/unload chunks if player moved to a new chunk
    if (playerChunkX != _lastPlayerChunkX || playerChunkZ != _lastPlayerChunkZ) {
      _lastPlayerChunkX = playerChunkX;
      _lastPlayerChunkZ = playerChunkZ;

      // Load chunks in render distance
      _loadChunksAround(playerChunkX, playerChunkZ);

      // Unload chunks outside render distance
      _unloadDistantChunks(playerChunkX, playerChunkZ);

      print('[TERRAIN] Player at chunk [$playerChunkX, $playerChunkZ] | '
          'Chunks loaded: ${_chunks.length} | Generated: $chunksGenerated | Unloaded: $chunksUnloaded');
    }
  }

  /// Get all currently loaded chunks
  List<TerrainChunkWithLOD> getLoadedChunks() {
    return _chunks.values.toList();
  }

  /// Get chunk at specific chunk coordinates
  TerrainChunkWithLOD? getChunk(int chunkX, int chunkZ) {
    return _chunks['$chunkX,$chunkZ'];
  }

  /// Get chunk containing a world position
  TerrainChunkWithLOD? getChunkAtWorldPosition(double worldX, double worldZ) {
    final chunkX = _worldToChunkCoord(worldX);
    final chunkZ = _worldToChunkCoord(worldZ);
    return getChunk(chunkX, chunkZ);
  }

  /// Get terrain height at world position
  ///
  /// Queries the appropriate chunk's heightmap.
  /// Returns 0.0 if chunk not loaded (safe fallback).
  ///
  /// Parameters:
  /// - worldX/worldZ: World coordinates
  ///
  /// Returns: Terrain height at position
  double getTerrainHeight(double worldX, double worldZ) {
    final chunk = getChunkAtWorldPosition(worldX, worldZ);
    if (chunk == null) {
      print('[TERRAIN WARNING] Chunk not loaded at ($worldX, $worldZ), returning groundLevel ${GameConfig.groundLevel}');
      return GameConfig.groundLevel; // Chunk not loaded, return proper ground level
    }

    final height = chunk.getHeightAt(worldX, worldZ);
    if (height == null) {
      print('[TERRAIN WARNING] Height null at ($worldX, $worldZ) in chunk, returning groundLevel ${GameConfig.groundLevel}');
      return GameConfig.groundLevel;
    }
    return height;
  }

  /// Load chunks in a square grid around player
  void _loadChunksAround(int centerChunkX, int centerChunkZ) {
    for (int dx = -renderDistance; dx <= renderDistance; dx++) {
      for (int dz = -renderDistance; dz <= renderDistance; dz++) {
        final chunkX = centerChunkX + dx;
        final chunkZ = centerChunkZ + dz;
        final key = '$chunkX,$chunkZ';

        // Skip if chunk already loaded
        if (_chunks.containsKey(key)) {
          continue;
        }

        // Generate new chunk with all LOD levels
        final chunk = TerrainChunkWithLOD.generate(
          chunkX: chunkX,
          chunkZ: chunkZ,
          size: chunkSize,
          tileSize: tileSize,
          maxHeight: maxHeight,
          seed: seed,
          noiseScale: noiseScale,
          noiseOctaves: noiseOctaves,
          noisePersistence: noisePersistence,
        );

        _chunks[key] = chunk;
        chunksGenerated++;
      }
    }
  }

  /// Unload chunks outside render distance (with buffer)
  void _unloadDistantChunks(int centerChunkX, int centerChunkZ) {
    final chunksToRemove = <String>[];

    for (final entry in _chunks.entries) {
      final chunk = entry.value;
      final dx = (chunk.chunkX - centerChunkX).abs();
      final dz = (chunk.chunkZ - centerChunkZ).abs();

      // Unload if outside render distance (with small buffer to avoid thrashing)
      if (dx > renderDistance + 1 || dz > renderDistance + 1) {
        chunksToRemove.add(entry.key);
      }
    }

    for (final key in chunksToRemove) {
      _chunks.remove(key);
      chunksUnloaded++;
    }
  }

  /// Update LOD for all chunks based on camera distance
  void _updateAllLODs(Vector3 cameraPosition) {
    totalLOD0 = 0;
    totalLOD1 = 0;
    totalLOD2 = 0;

    for (final chunk in _chunks.values) {
      chunk.updateLOD(cameraPosition);

      // Count LOD distribution
      switch (chunk.currentLOD) {
        case 0:
          totalLOD0++;
          break;
        case 1:
          totalLOD1++;
          break;
        case 2:
          totalLOD2++;
          break;
      }
    }
  }

  /// Convert world coordinate to chunk coordinate
  int _worldToChunkCoord(double worldCoord) {
    final chunkWorldSize = chunkSize * tileSize;
    return (worldCoord / chunkWorldSize).floor();
  }

  /// Get number of loaded chunks
  int get loadedChunkCount => _chunks.length;

  /// Get total vertices across all loaded chunks (accounting for LOD)
  int get totalVertices {
    int total = 0;
    for (final chunk in _chunks.values) {
      total += TerrainLOD.getVertexCount(chunkSize, chunkSize, chunk.currentLOD);
    }
    return total;
  }

  /// Get total triangles across all loaded chunks (accounting for LOD)
  int get totalTriangles {
    int total = 0;
    for (final chunk in _chunks.values) {
      total += TerrainLOD.getTriangleCount(chunkSize, chunkSize, chunk.currentLOD);
    }
    return total;
  }

  /// Clear all chunks (useful for resetting world)
  void clear() {
    _chunks.clear();
    chunksGenerated = 0;
    chunksUnloaded = 0;
    totalLOD0 = 0;
    totalLOD1 = 0;
    totalLOD2 = 0;
    _lastPlayerChunkX = 0;
    _lastPlayerChunkZ = 0;
  }

  /// Get statistics string for debugging
  String getStats() {
    return 'Chunks: ${loadedChunkCount} (LOD0: $totalLOD0, LOD1: $totalLOD1, LOD2: $totalLOD2) | '
        'Vertices: $totalVertices | Triangles: $totalTriangles | '
        'Generated: $chunksGenerated | Unloaded: $chunksUnloaded';
  }

  @override
  String toString() {
    return 'InfiniteTerrainManager(chunks: $loadedChunkCount, size: $chunkSize, render distance: $renderDistance)';
  }
}
