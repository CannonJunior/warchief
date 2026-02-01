import 'package:vector_math/vector_math.dart';
import 'terrain_lod.dart';
import 'game_config_terrain.dart';
import '../game3d/state/game_config.dart';

/// InfiniteTerrainManager - Manages infinite terrain with LOD, chunk loading,
/// and texture splatting
///
/// Creates the illusion of infinite terrain by:
/// - Dynamically loading chunks around the player
/// - Unloading distant chunks to save memory
/// - Using LOD to optimize rendering
/// - Generating seamless terrain using world coordinates
/// - Generating splat maps for texture blending
///
/// Performance:
/// - Only renders visible chunks
/// - Reduces detail for distant chunks (LOD)
/// - Keeps memory usage constant regardless of travel distance
/// - Lazy-creates splat map textures when chunks are rendered
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

  /// Texture splatting configuration
  final bool generateSplatMaps;
  final int splatMapResolution;

  /// WebGL context reference for texture cleanup (set by renderer)
  dynamic _gl;

  /// Last player chunk position (initialized to impossible value to force first load)
  int _lastPlayerChunkX = -999999;
  int _lastPlayerChunkZ = -999999;

  /// Statistics
  int chunksGenerated = 0;
  int chunksUnloaded = 0;
  int totalLOD0 = 0; // High detail chunks
  int totalLOD1 = 0; // Medium detail chunks
  int totalLOD2 = 0; // Low detail chunks
  int splatMapsGenerated = 0;

  InfiniteTerrainManager({
    this.chunkSize = 16,
    this.tileSize = 1.0,
    this.renderDistance = 3,
    this.maxHeight = 3.0,
    this.seed = 42,
    this.noiseScale = 0.03,
    this.noiseOctaves = 2,
    this.noisePersistence = 0.5,
    this.generateSplatMaps = true,
    this.splatMapResolution = 16,
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
      generateSplatMaps: TerrainConfig.useTextureSplatting,
      splatMapResolution: TerrainConfig.splatMapResolution,
    );
  }

  /// Set WebGL context reference for texture cleanup
  ///
  /// Call this after creating the renderer to enable proper
  /// texture cleanup when chunks are unloaded.
  void setGLContext(dynamic gl) {
    _gl = gl;
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

      if (TerrainConfig.debugLogging) {
        print('[TERRAIN] Player at chunk [$playerChunkX, $playerChunkZ] | '
            'Chunks loaded: ${_chunks.length} | Generated: $chunksGenerated | '
            'Unloaded: $chunksUnloaded | SplatMaps: $splatMapsGenerated');
      }
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
  /// Returns ground level if chunk not loaded (safe fallback).
  ///
  /// Parameters:
  /// - worldX/worldZ: World coordinates
  ///
  /// Returns: Terrain height at position
  double getTerrainHeight(double worldX, double worldZ) {
    final chunk = getChunkAtWorldPosition(worldX, worldZ);
    if (chunk == null) {
      if (TerrainConfig.debugLogging) {
        print('[TERRAIN WARNING] Chunk not loaded at ($worldX, $worldZ), returning groundLevel ${GameConfig.groundLevel}');
      }
      return GameConfig.groundLevel;
    }

    final height = chunk.getHeightAt(worldX, worldZ);
    if (height == null) {
      if (TerrainConfig.debugLogging) {
        print('[TERRAIN WARNING] Height null at ($worldX, $worldZ) in chunk, returning groundLevel ${GameConfig.groundLevel}');
      }
      return GameConfig.groundLevel;
    }
    return height;
  }

  /// Get terrain slope at world position
  ///
  /// Returns 1.0 for flat terrain, 0.0 for vertical cliffs.
  /// Returns 1.0 if chunk not loaded (safe fallback).
  double getTerrainSlope(double worldX, double worldZ) {
    final chunk = getChunkAtWorldPosition(worldX, worldZ);
    if (chunk == null) {
      return 1.0; // Default to flat
    }

    final slope = chunk.getSlopeAt(worldX, worldZ);
    return slope ?? 1.0;
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

        // Generate new chunk with all LOD levels and optional splat map
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
          generateSplatMap: generateSplatMaps,
          splatMapResolution: splatMapResolution,
        );

        _chunks[key] = chunk;
        chunksGenerated++;

        if (chunk.hasSplatMap) {
          splatMapsGenerated++;
        }
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
      final chunk = _chunks.remove(key);
      if (chunk != null) {
        // Clean up splat map texture if GL context available
        if (_gl != null) {
          chunk.disposeSplatMapTexture(_gl);
        }
        chunksUnloaded++;
      }
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

  /// Get count of chunks with splat maps
  int get chunksWithSplatMaps {
    int count = 0;
    for (final chunk in _chunks.values) {
      if (chunk.hasSplatMap) count++;
    }
    return count;
  }

  /// Get count of chunks with splat map textures uploaded to GPU
  int get chunksWithSplatMapTextures {
    int count = 0;
    for (final chunk in _chunks.values) {
      if (chunk.splatMapTexture != null) count++;
    }
    return count;
  }

  /// Clear all chunks (useful for resetting world)
  void clear() {
    // Clean up all splat map textures
    if (_gl != null) {
      for (final chunk in _chunks.values) {
        chunk.disposeSplatMapTexture(_gl);
      }
    }

    _chunks.clear();
    chunksGenerated = 0;
    chunksUnloaded = 0;
    totalLOD0 = 0;
    totalLOD1 = 0;
    totalLOD2 = 0;
    splatMapsGenerated = 0;
    _lastPlayerChunkX = -999999;
    _lastPlayerChunkZ = -999999;
  }

  /// Get statistics string for debugging
  String getStats() {
    final splatInfo = generateSplatMaps
        ? ' | SplatMaps: $chunksWithSplatMaps (GPU: $chunksWithSplatMapTextures)'
        : '';
    return 'Chunks: $loadedChunkCount (LOD0: $totalLOD0, LOD1: $totalLOD1, LOD2: $totalLOD2) | '
        'Vertices: $totalVertices | Triangles: $totalTriangles | '
        'Generated: $chunksGenerated | Unloaded: $chunksUnloaded$splatInfo';
  }

  @override
  String toString() {
    return 'InfiniteTerrainManager(chunks: $loadedChunkCount, size: $chunkSize, '
        'render distance: $renderDistance, splatMaps: $generateSplatMaps)';
  }
}
