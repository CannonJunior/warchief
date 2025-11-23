# Performance Mitigation Plan - Terrain System

## Problem Summary

The current terrain system is causing severe performance issues and system freezes due to:

1. **Excessive terrain size**: 200×200 grid = 40,401 vertices, 2.5MB geometry data
2. **Blocking noise generation**: 400,000+ operations on main thread during init
3. **No LOD system**: Full terrain rendered regardless of distance
4. **Excessive height queries**: Multiple bilinear interpolation calls per frame

## Critical Metrics (Current State)

- **Vertices**: 40,401 (201×201 grid)
- **Triangles**: 80,000 (40,000 tiles × 2)
- **Geometry Data**: ~2.5MB per frame
- **Initialization Time**: Estimated 3-10 seconds (blocking)
- **Frame Rate**: Likely <10 FPS on average hardware

## Mitigation Strategy - Phased Approach

### Phase 1: Immediate Relief (EMERGENCY FIX)
**Goal**: Get the game running without freezing
**Time**: 15-30 minutes

#### Action Items:

1. **Reduce Terrain Grid Size** (game_config.dart:13)
   ```dart
   // BEFORE:
   static const int terrainGridSize = 200;

   // AFTER (Temporary):
   static const int terrainGridSize = 50;  // 75% reduction
   ```

   **Impact**:
   - Vertices: 40,401 → 2,601 (94% reduction)
   - Triangles: 80,000 → 5,000 (94% reduction)
   - Geometry: 2.5MB → 160KB (94% reduction)
   - **Expected result**: Should run smoothly at 30-60 FPS

2. **Simplify Noise Generation** (heightmap.dart:99-132)
   ```dart
   // BEFORE:
   octaves: 4,
   persistence: 0.5,

   // AFTER (Temporary):
   octaves: 2,  // Reduce detail levels
   persistence: 0.5,
   ```

   **Impact**: 50% reduction in noise calculations

3. **Add Progress Logging** (game3d_widget.dart:124-146)
   Add console logging to track initialization progress:
   ```dart
   print('Generating terrain heightmap...');
   final terrainData = TerrainGenerator.createHeightmapTerrain(...);
   print('Heightmap generation complete!');
   ```

**Success Criteria**: Game starts within 2 seconds, runs at 30+ FPS

---

### Phase 2: Short-term Optimization
**Goal**: Improve quality while maintaining performance
**Time**: 2-4 hours

#### Action Items:

1. **Implement Chunk-Based Terrain**
   - Replace single 50×50 grid with 5×5 chunks of 10×10 tiles each
   - Only render chunks within camera view distance
   - Unload distant chunks to save memory

   **Files to modify**:
   - `lib/rendering3d/terrain_chunk.dart` (new file)
   - `lib/game3d/state/game_state.dart`
   - `lib/rendering3d/terrain_generator.dart`

2. **Add View Frustum Culling**
   - Calculate camera view frustum
   - Skip rendering chunks outside visible area
   - Reduce triangle count by 50-70% in typical gameplay

   **Files to modify**:
   - `lib/rendering3d/camera3d.dart`
   - `lib/game3d/systems/render_system.dart`

3. **Cache Heightmap Lookups**
   - Add LRU cache for recent height queries
   - Reduce duplicate calculations for stationary entities

   **Files to modify**:
   - `lib/rendering3d/heightmap.dart`

**Success Criteria**: 60 FPS with improved visual quality

---

### Phase 3: Medium-term Performance (Recommended)
**Goal**: Implement industry-standard LOD system
**Time**: 1-2 days

#### Action Items:

1. **Level of Detail (LOD) System**

   Implement 3 detail levels:
   - **LOD 0** (0-20 units): Full detail (1.0 unit per vertex)
   - **LOD 1** (20-50 units): Medium detail (2.0 units per vertex)
   - **LOD 2** (50+ units): Low detail (4.0 units per vertex)

   **Implementation approach**:
   ```dart
   class TerrainChunk {
     Mesh? lodMesh0;  // High detail
     Mesh? lodMesh1;  // Medium detail
     Mesh? lodMesh2;  // Low detail

     Mesh getCurrentLOD(double distanceFromCamera) {
       if (distanceFromCamera < 20) return lodMesh0!;
       if (distanceFromCamera < 50) return lodMesh1!;
       return lodMesh2!;
     }
   }
   ```

   **Expected impact**:
   - 60-80% reduction in rendered triangles
   - Constant 60 FPS regardless of terrain size

2. **Progressive Terrain Loading**
   - Generate terrain in background
   - Show low-res placeholder during generation
   - Swap to high-res when ready

3. **GPU-Based Height Queries** (Advanced)
   - Upload heightmap as texture to GPU
   - Use vertex shader for height displacement
   - Eliminate CPU-side height queries for rendering

**Success Criteria**: Stable 60 FPS with 100×100 terrain

---

### Phase 4: Long-term Scalability (Optional)
**Goal**: Support massive terrains (500×500+)
**Time**: 3-5 days

#### Action Items:

1. **Web Worker for Terrain Generation**
   - Move Perlin noise generation off main thread
   - Use Dart Isolates for parallel processing
   - Non-blocking terrain creation

2. **Quadtree-Based LOD** (CDLOD)
   - Continuous distance LOD with smooth transitions
   - Hierarchical culling for massive terrains
   - Industry-standard approach (used in AAA games)

3. **Texture-Based Heightmap**
   - Store heightmap as WebGL texture
   - Sample in vertex shader (GPU-side)
   - Eliminate all CPU heightmap queries

4. **Terrain Streaming**
   - Load/unload chunks dynamically
   - Support infinite terrain generation
   - Minimal memory footprint

**Success Criteria**: Support 500×500 terrain at 60 FPS

---

## Recommended Configuration Values

### Conservative (Guaranteed Performance)
```dart
static const int terrainGridSize = 50;      // 2,601 vertices
static const int terrainChunkSize = 10;     // 10×10 tiles per chunk
static const int renderDistance = 3;        // Render 3×3 = 9 chunks
static const int noiseOctaves = 2;          // Simple terrain
static const double maxHeight = 5.0;        // Moderate hills
```

**Vertices rendered**: ~2,600
**Expected FPS**: 60+

### Balanced (Good Quality + Performance)
```dart
static const int terrainGridSize = 100;     // 10,201 vertices
static const int terrainChunkSize = 20;     // 20×20 tiles per chunk
static const int renderDistance = 5;        // Render 5×5 = 25 chunks
static const int noiseOctaves = 3;          // Good detail
static const double maxHeight = 10.0;       // Full elevation range
```

**Vertices rendered**: ~10,000 (with culling)
**Expected FPS**: 45-60

### High Quality (Requires LOD System)
```dart
static const int terrainGridSize = 200;     // 40,401 vertices
static const int terrainChunkSize = 32;     // 32×32 tiles per chunk
static const int renderDistance = 6;        // Render 6×6 = 36 chunks
static const int noiseOctaves = 4;          // Maximum detail
static const double maxHeight = 15.0;       // Dramatic elevation
static const bool useLOD = true;            // REQUIRED
static const int lodLevels = 3;             // 3 detail levels
```

**Vertices rendered**: ~15,000 (with LOD + culling)
**Expected FPS**: 60 (requires Phase 3 implementation)

---

## Performance Testing Procedure

### 1. Run Performance Test
```bash
cd /home/junior/src/warchief
./test_performance.sh
```

This will:
- Run game for exactly 10 seconds
- Log CPU and memory usage every 500ms
- Capture initialization time
- Automatically kill process to prevent freeze

### 2. Analyze Results
Check the log file in `performance_logs/` for:
- Peak memory usage (RSS)
- CPU utilization
- Initialization time
- Any error messages

### 3. Performance Targets

| Metric | Current | Target (Phase 1) | Target (Phase 3) |
|--------|---------|------------------|------------------|
| Init Time | 3-10s | <2s | <1s |
| Peak RSS | ~500MB+ | <200MB | <150MB |
| CPU Usage | 100% | <60% | <40% |
| FPS | <10 | 30+ | 60 |
| Vertices | 40,401 | 2,601 | 10,000 (LOD) |

---

## Monitoring & Debugging

### Key Metrics to Track

1. **Initialization Time**
   - Time from `_initializeGame()` start to first frame
   - Should be <2 seconds

2. **Frame Time**
   - Time per `_update()` + `_render()` cycle
   - Should be <16.67ms for 60 FPS

3. **Memory Usage**
   - RSS (Resident Set Size) in MB
   - Should remain stable, not grow over time

4. **Triangle Count**
   - Total triangles sent to GPU per frame
   - Lower is better (target: <10,000)

### Debug Logging

Add these to `game3d_widget.dart` for performance tracking:

```dart
// In _initializeGame()
final initStartTime = DateTime.now();
print('[PERF] Terrain generation started...');

// After terrain generation
final terrainGenTime = DateTime.now().difference(initStartTime);
print('[PERF] Terrain generated in ${terrainGenTime.inMilliseconds}ms');
print('[PERF] Vertices: ${vertexCount}, Triangles: ${triangleCount}');

// In _update()
if (gameState.frameCount % 60 == 0) {
  final fps = 60000 / (dt * 60 * 1000);
  print('[PERF] FPS: ${fps.toStringAsFixed(1)}, Frame time: ${(dt * 1000).toStringAsFixed(2)}ms');
}
```

---

## Risk Assessment

### Phase 1 (Emergency Fix)
- **Risk**: Low
- **Breaking Changes**: None
- **Rollback**: Change config value back
- **Testing Required**: 10 minute playtest

### Phase 2 (Short-term)
- **Risk**: Medium
- **Breaking Changes**: Terrain generation API changes
- **Rollback**: Keep old generator as fallback
- **Testing Required**: 1-2 hour playtest

### Phase 3 (LOD System)
- **Risk**: Medium-High
- **Breaking Changes**: Major rendering system changes
- **Rollback**: Feature flag to disable LOD
- **Testing Required**: Full regression test

### Phase 4 (Advanced)
- **Risk**: High
- **Breaking Changes**: Complete terrain rewrite
- **Rollback**: Separate branch, merge when stable
- **Testing Required**: Extensive testing across browsers

---

## Implementation Priority

### Immediate (Do Now):
1. ✅ Create performance test script (`test_performance.sh`)
2. 🔴 **Reduce terrainGridSize to 50** (5-minute fix)
3. 🔴 **Reduce noise octaves to 2** (1-minute fix)
4. 🟡 Run performance test and verify FPS >30

### This Week:
1. Implement chunk-based terrain (2-3 hours)
2. Add view frustum culling (1-2 hours)
3. Add heightmap query caching (1 hour)
4. Performance testing and tuning (1 hour)

### This Month:
1. Full LOD system implementation
2. Progressive loading
3. GPU-based heightmap sampling

### Future (Optional):
1. Web Worker terrain generation
2. Quadtree LOD (CDLOD)
3. Infinite terrain streaming

---

## Success Metrics

### Phase 1 Success Criteria
- ✅ Game initializes in <2 seconds
- ✅ Runs at 30+ FPS consistently
- ✅ No system freezes or crashes
- ✅ Playable on average hardware

### Phase 3 Success Criteria
- ✅ Supports 100×100 terrain at 60 FPS
- ✅ Smooth LOD transitions (no popping)
- ✅ Memory usage <200MB
- ✅ Professional-quality terrain appearance

---

## References

- TERRAIN_RESEARCH.md - Detailed terrain system research
- game_config.dart - Configuration constants
- heightmap.dart - Heightmap implementation
- terrain_generator.dart - Mesh generation

---

## Questions to Consider

1. **Do we need 200×200 terrain immediately?**
   - No. Start with 50×50, scale up with LOD system.

2. **Can we generate terrain on a background thread?**
   - Yes, but requires Dart Isolates (complex). Phase 4 feature.

3. **Should we cache terrain meshes?**
   - Yes! Regenerating every frame is wasteful.

4. **What's the minimum viable terrain size?**
   - 50×50 for testing, 100×100 for release (with LOD).

---

**Last Updated**: 2025-11-23
**Status**: Phase 1 tools created, awaiting implementation
