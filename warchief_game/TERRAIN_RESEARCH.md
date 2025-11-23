# Terrain System Research - Third-Person Games & Globe Implementation

## Executive Summary

This document outlines research findings for implementing a continuous, elevation-based terrain system on a spherical globe for the Warchief game. The goal is to replace the current flat rectangle terrain with a proper 3D heightmap-based terrain system that supports elevation changes, collision detection, and eventual globe circumnavigation.

## Current Issues to Address

1. **Limited flat terrain** - Only a small rectangle is rendered
2. **No elevation system** - Terrain is completely flat
3. **Monster collision bugs** - Monster moves above/below terrain, ignoring elevation
4. **No obstacles** - Need walls, hills, and jumpable/flyable structures
5. **No globe curvature** - Want spherical world for circumnavigation

---

## Part 1: Heightmap-Based Terrain System

### What is a Heightmap?

A **heightmap** is a 2D grid where each cell stores a height value, typically represented as:
- **Grayscale image** - Brighter pixels = higher elevation, darker = lower
- **2D array of floats** - Direct height values at grid positions
- **Texture on GPU** - Efficient storage for real-time access

### Implementation Architecture

```
Heightmap System:
├─ Terrain Grid (e.g., 512x512 vertices)
├─ Height Lookup (bilinear interpolation)
├─ Collision Detection (player/entity height queries)
├─ LOD System (Level of Detail for performance)
└─ Procedural Generation (Perlin/Simplex noise)
```

### Collision Detection with Heightmaps

**Key Finding**: Heightmap terrain collision is one of the EASIEST collision types to implement.

**Method 1: Direct Height Query**
```dart
double getTerrainHeight(Vector2 position) {
  // Convert world position to heightmap coordinates
  final gridX = (position.x / tileSize).floor();
  final gridZ = (position.y / tileSize).floor();

  // Get surrounding height samples
  final h00 = heightmap[gridX][gridZ];
  final h10 = heightmap[gridX + 1][gridZ];
  final h01 = heightmap[gridX][gridZ + 1];
  final h11 = heightmap[gridX + 1][gridZ + 1];

  // Bilinear interpolation for smooth height
  final fx = (position.x / tileSize) - gridX;
  final fz = (position.y / tileSize) - gridZ;

  final h0 = h00 * (1 - fx) + h10 * fx;
  final h1 = h01 * (1 - fx) + h11 * fx;

  return h0 * (1 - fz) + h1 * fz;
}

// Apply to player/monster every frame
void updateEntityPosition(Entity entity, double dt) {
  // Move entity horizontally
  entity.position.x += velocity.x * dt;
  entity.position.z += velocity.z * dt;

  // Snap to terrain height (or apply gravity)
  final terrainHeight = getTerrainHeight(Vector2(entity.position.x, entity.position.z));
  entity.position.y = terrainHeight + entity.heightOffset;
}
```

**Method 2: Physics Raycasting**
- Cast ray downward from entity position
- Detect intersection with terrain mesh
- More accurate for complex terrain but slower

**Recommendation**: Use direct height query (Method 1) - faster, simpler, and sufficient for most cases.

---

## Part 2: Continuous Terrain with LOD

### Chunk-Based System

**Architecture:**
```
Player at (0, 0)
Render Distance: 3 chunks

 [3][3][3][3][3]
 [3][2][2][2][3]
 [3][2][1][2][3]  ← Numbers = LOD level
 [3][2][2][2][3]     1 = Highest detail
 [3][3][3][3][3]     3 = Lowest detail
```

**Key Concepts:**

1. **Chunk Size**: 64x64 or 128x128 tiles per chunk
2. **Render Distance**: Load 5x5 or 7x7 chunk grid around player
3. **Dynamic Loading**: Generate/load chunks as player moves
4. **Unload Distance**: Remove chunks >render distance to save memory

### LOD (Level of Detail) System

**Clipmap Technique** (Recommended for Terrain):
- Nested grids centered on camera
- Higher detail near player, lower detail far away
- Smooth transitions prevent "popping"
- GPU-friendly with vertex buffers

**CDLOD (Continuous Distance LOD)**:
- Quadtree-based approach
- Smooth geomorphing between LOD levels
- Used in modern open-world games

**Implementation Example:**
```dart
class TerrainLOD {
  static const levels = [
    LODLevel(distance: 50, vertexSpacing: 0.5),   // High detail
    LODLevel(distance: 150, vertexSpacing: 1.0),  // Medium
    LODLevel(distance: 300, vertexSpacing: 2.0),  // Low
    LODLevel(distance: 500, vertexSpacing: 4.0),  // Very low
  ];

  LODLevel selectLOD(double distanceFromCamera) {
    for (final level in levels) {
      if (distanceFromCamera < level.distance) {
        return level;
      }
    }
    return levels.last;
  }
}
```

### Procedural Generation with Perlin Noise

**Why Perlin Noise?**
- Generates organic, natural-looking terrain
- **Deterministic** - Same seed always produces same terrain
- **Infinite** - Can generate unlimited terrain chunks
- **Seamless** - Chunks blend perfectly at edges

**Implementation:**
```dart
import 'package:fast_noise/fast_noise.dart';

class TerrainGenerator {
  final int seed;
  late PerlinNoise noise;

  TerrainGenerator(this.seed) {
    noise = PerlinNoise(seed: seed);
  }

  List<List<double>> generateChunk(int chunkX, int chunkZ, int size) {
    final heights = List.generate(size, (_) => List<double>.filled(size, 0));

    for (int x = 0; x < size; x++) {
      for (int z = 0; z < size; z++) {
        // World position
        final worldX = chunkX * size + x;
        final worldZ = chunkZ * size + z;

        // Multiple octaves for detail
        double height = 0;
        height += noise.getPerlin2(worldX * 0.01, worldZ * 0.01) * 20;  // Large features
        height += noise.getPerlin2(worldX * 0.05, worldZ * 0.05) * 5;   // Medium features
        height += noise.getPerlin2(worldX * 0.1, worldZ * 0.1) * 1;     // Fine detail

        heights[x][z] = height;
      }
    }

    return heights;
  }
}
```

**Edge Handling**: Since Perlin noise is a continuous function, adjacent chunks automatically have matching edges when using the same seed and world coordinates.

---

## Part 3: Spherical Globe Terrain

### The Challenge

**Key Finding**: There is no perfect way to map a 2D plane to a 3D sphere without distortion.

**Problems:**
- No continuous 2D coordinate system on sphere (always has poles)
- Distance/angle calculations become complex
- Collision detection more difficult
- Tile-based systems don't map cleanly

### Recommended Approaches

#### Option 1: Quad Sphere (Recommended)

**Description**: Divide sphere into 6 cube faces, project onto sphere

```
      [North]
[West][Equator][East]
      [South]
```

**How It Works:**
1. Create 6 terrain chunks (like cube faces)
2. Position each face on sphere
3. Subdivide each face into grid
4. Project vertices onto sphere surface
5. Apply heightmap to each face

**Advantages:**
✓ Minimal distortion near face centers
✓ Works with existing heightmap system
✓ Used successfully in many games
✓ Good for circumnavigation

**Implementation Sketch:**
```dart
class QuadSphere {
  static const faces = [
    'north', 'south', 'east', 'west', 'top', 'bottom'
  ];

  Vector3 projectToSphere(int face, double u, double v, double radius) {
    // Start with cube face position
    Vector3 point = getCubeFacePoint(face, u, v);

    // Normalize and scale to sphere radius
    point = point.normalized() * radius;

    return point;
  }

  double getTerrainHeight(Vector3 worldPos) {
    // Determine which face we're on
    final face = getFaceFromPosition(worldPos);

    // Convert to UV coordinates on that face
    final uv = worldPosToFaceUV(worldPos, face);

    // Query heightmap for that face
    return getHeightmapValue(face, uv);
  }
}
```

#### Option 2: Local Flat Approximation (Easier Alternative)

**Description**: Keep terrain flat locally, but wrap at edges

**How It Works:**
1. Use regular heightmap terrain (flat)
2. When player reaches edge, teleport to opposite side
3. Simulate globe without actual curvature
4. Add visual horizon curve (shader effect)

**Advantages:**
✓ Much simpler to implement
✓ Reuses existing flat terrain code
✓ Still allows circumnavigation
✓ Performance friendly

**Disadvantages:**
✗ Not true spherical curvature
✗ Less realistic at large scales

#### Option 3: Full Spherical Coordinates (Advanced)

**Description**: True spherical coordinate system (latitude/longitude)

**Advantages:**
✓ Mathematically accurate
✓ True planet curvature

**Disadvantages:**
✗ Very complex collision/movement
✗ Requires rewriting most systems
✗ Performance intensive
✗ NOT recommended for this project

---

## Part 4: Obstacles and Jump/Fly Mechanics

### Adding Walls and Hills

**Approach 1: Heightmap-Based Obstacles**
- Simply make heightmap values very high at wall locations
- Works automatically with collision system
- Example: Mountains, hills, cliffs

**Approach 2: Separate Collision Meshes**
- Create explicit 3D meshes for structures
- Use traditional 3D collision detection
- Example: Buildings, bridges, arches

**Approach 3: Hybrid System** (Recommended)
```dart
class TerrainCollision {
  double getGroundHeight(Vector2 pos) {
    final terrainHeight = heightmap.getHeight(pos);
    final structureHeight = structures.getHeight(pos);

    // Use higher of the two
    return max(terrainHeight, structureHeight);
  }

  bool canStandAt(Vector3 pos) {
    final groundHeight = getGroundHeight(Vector2(pos.x, pos.z));

    // Can stand if close to ground
    return abs(pos.y - groundHeight) < 0.1;
  }
}
```

### Jump Mechanics with Terrain

**Already Implemented**: You have a jump system in `physics_system.dart`

**Enhancement Needed**: Ensure landing respects terrain height

```dart
// In physics update
void updatePhysics(double dt, GameState gameState) {
  // Apply gravity
  gameState.verticalVelocity -= GameConfig.gravity * dt;
  gameState.playerTransform.position.y += gameState.verticalVelocity * dt;

  // Get terrain height at player position
  final terrainHeight = getTerrainHeight(
    Vector2(
      gameState.playerTransform.position.x,
      gameState.playerTransform.position.z,
    )
  );

  // Land on terrain
  if (gameState.playerTransform.position.y <= terrainHeight) {
    gameState.playerTransform.position.y = terrainHeight;
    gameState.verticalVelocity = 0;
    gameState.isJumping = false;
  }
}
```

### Flying Mechanics

**Approach**: Allow Y-axis movement when flying enabled

```dart
if (gameState.isFlying) {
  // Space = Up, Shift = Down
  if (inputManager.isKeyPressed(LogicalKeyboardKey.space)) {
    gameState.playerTransform.position.y += flySpeed * dt;
  }
  if (inputManager.isKeyPressed(LogicalKeyboardKey.shift)) {
    gameState.playerTransform.position.y -= flySpeed * dt;
  }

  // Don't apply gravity when flying
} else {
  // Normal gravity/collision
  applyGravity(dt);
  snapToTerrain();
}
```

---

## Part 5: Implementation Recommendations

### Phase 1: Basic Heightmap Terrain (Start Here)

**Goal**: Replace flat terrain with heightmap-based elevation

**Tasks:**
1. Create heightmap data structure (2D array or texture)
2. Generate simple terrain with Perlin noise
3. Modify terrain renderer to use heightmap for vertex heights
4. Implement `getTerrainHeight()` function with bilinear interpolation
5. Update player collision to snap to terrain height
6. Fix monster collision to use same system

**Files to Modify:**
- `lib/rendering3d/terrain_generator.dart` - Add heightmap generation
- `lib/game3d/state/game_state.dart` - Store heightmap data
- `lib/game3d/systems/physics_system.dart` - Add terrain collision
- `lib/game3d/systems/ai_system.dart` - Fix monster terrain collision

**Estimated Effort**: 2-3 days

### Phase 2: Chunk-Based Infinite Terrain

**Goal**: Extend terrain beyond initial rectangle

**Tasks:**
1. Implement chunk system (chunk class, chunk manager)
2. Load/unload chunks based on player position
3. Add LOD system for distant chunks
4. Procedurally generate chunks with consistent seed

**Estimated Effort**: 3-5 days

### Phase 3: Obstacles and Enhanced Collision

**Goal**: Add walls, hills, and jumpable structures

**Tasks:**
1. Add structure placement system
2. Enhance collision to handle overhangs/tunnels
3. Implement climb detection for jumpable surfaces
4. Add flying mode toggle

**Estimated Effort**: 2-3 days

### Phase 4: Spherical Globe (Advanced)

**Goal**: Implement globe curvature and circumnavigation

**Options:**
- **Easy**: Local flat approximation with edge wrapping (1-2 days)
- **Medium**: Quad sphere with 6 heightmap faces (1-2 weeks)
- **Hard**: Full spherical coordinates (NOT recommended)

---

## Part 6: WebGL/Three.js Specific Resources

Since your game uses WebGL rendering, here are relevant implementation patterns:

### Loading Heightmap from Image

```dart
import 'dart:html' as html;
import 'dart:typed_data';

Future<List<List<double>>> loadHeightmapFromImage(String imageUrl) async {
  // Load image
  final img = html.ImageElement()..src = imageUrl;
  await img.onLoad.first;

  // Draw to canvas to read pixels
  final canvas = html.CanvasElement(width: img.width, height: img.height);
  final ctx = canvas.context2D;
  ctx.drawImage(img, 0, 0);

  // Get pixel data
  final imageData = ctx.getImageData(0, 0, img.width!, img.height!);
  final pixels = imageData.data;

  // Extract heights from red channel
  final heights = List.generate(img.height!, (y) {
    return List.generate(img.width!, (x) {
      final i = (y * img.width! + x) * 4;
      return pixels[i] / 255.0 * maxHeight; // R channel as height
    });
  });

  return heights;
}
```

### Vertex Shader for Heightmap

```glsl
// Vertex Shader
attribute vec3 position;
attribute vec2 uv;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform sampler2D heightmap;
uniform float heightScale;

void main() {
  vec3 pos = position;

  // Sample heightmap
  float height = texture2D(heightmap, uv).r;
  pos.y = height * heightScale;

  gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}
```

---

## Part 7: Key Takeaways

### Immediate Priorities

1. **Fix Monster Collision**: Implement `getTerrainHeight()` and apply to monster position every frame
2. **Add Heightmap System**: Generate simple Perlin noise terrain
3. **Implement Terrain Collision**: Bilinear interpolation for smooth height queries
4. **Test Jumping**: Ensure jump system lands on variable terrain

### Best Practices

✓ Start with flat heightmap terrain before attempting globe
✓ Use Perlin noise for natural-looking elevation
✓ Implement bilinear interpolation for smooth collision
✓ Add LOD system early to handle performance
✓ Use chunks for infinite terrain expansion
✓ Test collision thoroughly before adding complexity

### What NOT to Do

✗ Don't implement full spherical coordinates (too complex)
✗ Don't try to create globe before basic heightmap works
✗ Don't skip LOD system for large terrains
✗ Don't use physics raycasting for terrain (too slow)

---

## Resources and References

### Tutorials
- **LWJGL 3D Game Development - Terrain Collisions**: https://lwjglgamedev.gitbooks.io/3d-game-development-with-lwjgl/content/chapter15/chapter15.html
- **Three.js Heightmap Tutorial**: http://danni-three.blogspot.com/2013/09/threejs-heightmaps.html
- **Building Infinite Procedural World**: https://spin.atomicobject.com/2015/05/03/infinite-procedurally-generated-world/

### Code Examples
- **WebGL Terrain with Heightmap**: https://github.com/wybral/terrain
- **Three.js Cookbook - Heightmap**: https://github.com/josdirksen/threejs-cookbook
- **Infinite World Chunks**: https://github.com/ToberoCat/InfiniteWorld

### Academic Papers
- "Procedural Generation and Rendering of Large-Scale Open-World Environments" (ResearchGate)
- "Terrain LOD Published Papers": http://vterrain.org/LOD/Papers/

### Dart/Flutter Libraries
- `fast_noise` - Perlin/Simplex noise generation for Dart
- `vector_math` - Already in use for 3D math

---

## Conclusion

The path forward is clear:

1. **Start Simple**: Implement basic heightmap terrain with Perlin noise
2. **Fix Collision**: Apply terrain height to all entities (player, monster, allies)
3. **Add Chunks**: Extend to infinite terrain with chunk loading
4. **Enhance Obstacles**: Add structures and jumpable features
5. **Consider Globe**: Only after above systems are solid and tested

The heightmap approach is proven, well-documented, and perfect for your WebGL-based game. Spherical globe is achievable but should be treated as a later enhancement, not an initial requirement.
