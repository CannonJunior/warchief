# Warchief 3D Rendering Pipeline Reference

## Overview

Warchief uses a custom WebGL rendering pipeline built on Flutter for web. The pipeline is **not** Flame-based for 3D — it bypasses Flame's 2D renderer entirely and uses raw WebGL via `dart:html` canvas. All 3D objects are rendered as triangle meshes with vertex colors and per-vertex normals for basic directional lighting.

## Architecture Diagram

```
Game3DWidget (Flutter Widget, game3d_widget.dart)
  ├── WebGLRenderer (webgl_renderer.dart)
  │     ├── ShaderProgram (default vertex/fragment shaders)
  │     ├── ShaderProgram (terrain shaders with texture splatting)
  │     ├── TextureManager (terrain textures: grass, dirt, rock, sand)
  │     └── _MeshBuffers cache (Map<Mesh, GPU buffers>)
  ├── Camera3D (camera3d.dart)
  │     ├── Static orbit mode
  │     └── Third-person follow mode
  └── RenderSystem (systems/render_system.dart)
        └── Static render() orchestrates draw order
```

## Core Classes

### Mesh (`lib/rendering3d/mesh.dart`, 503 lines)

The fundamental geometry container. All 3D objects — player, monsters, allies, buildings, effects — are `Mesh` instances.

**Data layout:**
- `vertices: Float32List` — Packed `[x1,y1,z1, x2,y2,z2, ...]` (3 floats per vertex)
- `indices: Uint16List` — Triangle indices, 3 per triangle
- `normals: Float32List?` — Per-vertex normals `[nx,ny,nz, ...]` for lighting
- `texCoords: Float32List?` — Per-vertex UVs `[u,v, ...]` (terrain only)
- `colors: Float32List?` — Per-vertex RGBA `[r,g,b,a, ...]` in 0.0-1.0 range

**Factory constructors:**
| Factory | Use Case | Details |
|---------|----------|---------|
| `Mesh.cube(size, color)` | Entities, buildings, placeholder geometry | 8 vertices, 12 triangles, single color |
| `Mesh.plane(width, height, color)` | Floors, walls, terrain tiles | Double-sided (8 vertices), includes UVs |
| `Mesh.triangle(size, color)` | Direction indicators, arrows | Double-sided, tip points +Z |
| `Mesh.targetIndicator(size, lineWidth, color)` | Target selection rectangle | 8 dashed quads, lies on Y plane |
| `Mesh.fromVerticesAndIndices(vertices, indices, vertexStride)` | Procedural geometry (ley lines, particles) | Stride=6: `[x,y,z,r,g,b]` per vertex |

**Static helpers:**
- `Mesh.computeNormals(vertices, indices)` — Generates smooth normals from geometry
- `mesh.withComputedNormals()` — Returns copy with auto-computed normals
- `mesh.vertexCount`, `mesh.triangleCount` — Quick counts

**How to create a new mesh type:**
```dart
// Simple colored cube entity
final mesh = Mesh.cube(size: 1.0, color: Vector3(0.5, 0.3, 0.2));

// Procedural geometry with per-vertex colors
final vertices = <double>[]; // [x,y,z,r,g,b, x,y,z,r,g,b, ...]
final indices = <int>[];     // [0,1,2, 0,2,3, ...]
final mesh = Mesh.fromVerticesAndIndices(
  vertices: vertices,
  indices: indices,
  vertexStride: 6,
);
```

### Transform3d (`lib/rendering3d/math/transform3d.dart`, 155 lines)

Position, rotation, and scale for any 3D object.

**Fields:**
- `position: Vector3` — World position (x, y, z)
- `rotation: Vector3` — Euler angles in **degrees** (pitch=X, yaw=Y, roll=Z)
- `scale: Vector3` — Scale factors (default 1,1,1)

**Matrix generation:**
`toMatrix()` applies: **Translate → RotateY → RotateX → RotateZ → Scale**

**Direction vectors:**
- `forward` — `-sin(yaw)*cos(pitch), sin(pitch), -cos(yaw)*cos(pitch)` (normalized)
- `right` — `cos(yaw), 0, -sin(yaw)` (normalized)
- `up` — `forward × right` (normalized)

**Coordinate system:**
- Y is up
- Forward default is -Z
- Rotation 0° = facing -Z (south). Rotation 180° = facing +Z (north)
- The game's `rotateY()` convention mirrors X relative to standard compass

**Key methods:**
- `clone()`, `lerp(other, t)`, `translate(delta)`, `rotate(deltaRotation)`, `scaleUniform(factor)`

### Camera3D (`lib/rendering3d/camera3d.dart`, 313 lines)

Perspective camera with orbit and third-person modes.

**Modes:**
- `CameraMode.static` — Orbit camera, yaw/pitch controlled by J/L/N/M keys, FOV 60°
- `CameraMode.thirdPerson` — Follow camera behind player, auto-yaw matches player rotation, FOV 90°

**Key methods:**
- `getViewMatrix()` — lookAt matrix from camera position to target
- `getProjectionMatrix()` — perspective matrix from FOV, aspect, near/far
- `pitchBy(degrees)`, `yawBy(degrees)` — Orbit rotation (clamped -89° to 89° pitch)
- `zoom(delta)` — Adjust orbit distance (clamped 1-100 units)
- `updateThirdPersonFollow(targetPos, targetRotation, dt)` — Smooth follow with lerp

**Clipping planes:** near=0.1, far=1000.0

### WebGLRenderer (`lib/rendering3d/webgl_renderer.dart`, 434 lines)

Core WebGL rendering engine.

**Initialization:**
```dart
final canvas = html.CanvasElement(width: 800, height: 600);
final renderer = WebGLRenderer(canvas);
```

**WebGL state:**
- Depth testing enabled (LESS)
- Backface culling enabled (BACK)
- Clear color: (0.1, 0.1, 0.1, 1.0)

**Two render paths:**

1. **`render(mesh, transform, camera)`** — Default shader for all non-terrain objects
   - Uniforms: `uProjection`, `uView`, `uModel` (matrices), `uLightPos`, `uLightColor`, `uAmbientColor`
   - Attributes: `aPosition` (vec3), `aNormal` (vec3), `aColor` (vec4)
   - If mesh has no colors → default white (1,1,1,1)

2. **`renderTerrain(chunk, transform, camera)`** — Terrain shader with texture splatting
   - Additional uniforms: `uCameraPos`, `uTextureScale`, `uChunkSize`, `uDetailDistance`, `uMaxHeight`, height/slope thresholds
   - Additional attribute: `aTexCoord` (vec2)
   - Binds 10 texture slots: grass/dirt/rock/sand (diffuse + normal) + detail + splat map
   - Falls back to `render()` if texturing not initialized

**Buffer caching:**
- `Map<Mesh, _MeshBuffers>` — GPU buffers cached per mesh instance
- `deleteMeshBuffers(mesh)` — Manual cleanup when mesh is no longer needed
- Buffers created with `STATIC_DRAW` (not updated after creation)

**Lighting:**
- `lightPosition = Vector3(10, 20, 10)` — Directional light source
- `lightColor = Vector3(1.0, 1.0, 1.0)` — White light
- `ambientColor = Vector3(0.3, 0.3, 0.3)` — Ambient fill

### ShaderProgram (`lib/rendering3d/shader_program.dart`)

Wraps WebGL shader compilation and uniform management.

**Key methods:**
- `ShaderProgram.fromSource(gl, vertexSource, fragmentSource)` — Compile + link
- `shader.use()` — Activate this shader for subsequent draw calls
- `setUniformMatrix4(name, Matrix4)`, `setUniformVector3(name, Vector3)`, `setUniformFloat(name, double)`, `setUniformSampler2D(name, int)`
- Caches uniform/attribute locations for performance

**Default shaders** (in `shader_program.dart`):
- Vertex: transforms by model/view/projection, passes normal + color to fragment
- Fragment: Phong lighting with ambient + diffuse from directional light

**Terrain shaders** (in `shaders/terrain_shaders.dart`):
- Multi-texture blending based on height and slope
- Splat map support for artist-controlled blending

### RenderSystem (`lib/game3d/systems/render_system.dart`, 384 lines)

Static orchestrator that calls `renderer.render()` in the correct order.

**Draw order (back to front for transparent objects):**
1. **Terrain** — Infinite chunks with LOD (`renderTerrain`)
2. **Ley Lines** — Magical energy lines on terrain (batched `Mesh.fromVerticesAndIndices`)
3. **Shadows** — Player shadow mesh
4. **Target Indicator** — Dashed rectangle around selected target
5. **Player** — `playerMesh` + `playerTransform`
6. **Direction Indicator** — Player facing arrow
7. **Monster (Boss)** — Single boss entity
8. **Monster Direction Indicator**
9. **Allies** — Loop: `ally.mesh` + `ally.transform`, then ally projectiles
10. **Minions** — Loop: `minion.mesh` + `minion.transform`, direction indicators, projectiles
11. **Target Dummy** — DPS practice target
12. **Ability Effects** — Player sword, monster sword
13. **Fireballs** — Player projectiles
14. **Monster Projectiles**
15. **Impact Effects** — Explosion particles
16. **Heal Effect** — Green glow mesh
17. **Wind Particles** — Batched wind streaks

**Adding a new renderable entity type:**
```dart
// In render_system.dart, add after existing entity rendering:
for (final building in gameState.buildings) {
  renderer.render(building.mesh, building.transform, camera);
}
```

### Ley Line Rendering Pattern

Ley lines use a **batched procedural mesh** pattern (useful reference for buildings/effects):
1. Build vertex/index lists in CPU: `vertices = <double>[]`, `indices = <int>[]`
2. For each segment, compute quad corners with perpendicular offset for width
3. Create mesh: `Mesh.fromVerticesAndIndices(vertices: vertices, indices: indices, vertexStride: 6)`
4. Render at world origin: `renderer.render(mesh, Transform3d(position: Vector3.zero()), camera)`
5. Cache mesh, only rebuild when data changes (hash comparison)

### Wind Particle System (`lib/game3d/rendering/wind_particles.dart`)

Uses the same batched mesh approach:
- Pool of `_WindParticle` objects with position/life
- Each frame: update positions, rebuild vertex list as elongated quads aligned to wind direction
- Single `renderer.render(mesh, transform, camera)` call for all particles

## Terrain System

### Infinite Terrain (`lib/rendering3d/infinite_terrain_manager.dart`)

Chunk-based infinite terrain with LOD.

**Architecture:**
- Chunks: 16x16 tiles, 1.0 unit tile size (configurable via `TerrainConfig`)
- Loading: Chunks within `renderDistance` (default 3) of player are loaded
- Unloading: Chunks outside render distance are unloaded (GPU buffers cleaned up)
- Generation: Simplex noise (`seed=42`, `noiseScale=0.03`, `octaves=2`, `persistence=0.5`)

**LOD System (`lib/rendering3d/terrain_lod.dart`):**
| Distance | LOD | Vertex Spacing | Triangle Reduction |
|----------|-----|----------------|-------------------|
| 0-20 units | 0 (Full) | Every vertex | 0% |
| 20-50 units | 1 (Medium) | Every 2nd vertex | 75% |
| 50+ units | 2 (Low) | Every 4th vertex | 93% |

**Texture Splatting:**
- 4 terrain types: grass, dirt, rock, sand
- Blending controlled by height thresholds and slope:
  - Sand: below `sandMaxHeight`
  - Grass: between sand and `grassMaxHeight`
  - Rock: above `rockMinSlope` or high altitude
- Splat maps generated per-chunk for fine control
- Normal maps for surface detail

**Height sampling:**
- `getTerrainHeight(worldX, worldZ)` — Returns height at any world position
- Used for entity placement (add entity half-height for bottom-on-ground)
- Returns `GameConfig.groundLevel` (0.5) if chunk not loaded

### TerrainConfig (`lib/rendering3d/game_config_terrain.dart`)

Static constants for terrain generation:
- `chunkSize = 16`, `tileSize = 1.0`, `renderDistance = 3`
- `maxHeight = 3.0` (gentle rolling hills)
- `seed = 42`, `noiseScale = 0.03`, `noiseOctaves = 2`
- `textureScale = 8.0`, `detailDistance = 30.0`

## Mesh Factory Patterns

### Entity Creation Pattern (used by Monster, Ally, TargetDummy)

```dart
// 1. Create mesh
final mesh = Mesh.cube(
  size: definition.effectiveScale,
  color: definition.modelColor,
);

// 2. Create transform at world position
final transform = Transform3d(
  position: position.clone(),
  rotation: Vector3(0, rotation, 0),
  scale: Vector3(1, 1, 1),
);

// 3. Adjust Y for terrain height
final terrainY = terrainManager.getTerrainHeight(position.x, position.z);
transform.position.y = terrainY + size / 2 + 0.15; // Half-height + buffer
```

### Multi-Part Entity Pattern (PlayerMesh)

```dart
class PlayerMesh {
  static List<BodyPart> createHumanoidCharacter() {
    return [
      BodyPart(mesh: Mesh.cube(size: 0.4, color: skinColor),
               transform: Transform3d(position: Vector3(0, 1.0, 0)),
               name: 'head'),
      BodyPart(mesh: Mesh.cube(size: 0.6, color: bodyColor),
               transform: Transform3d(position: Vector3(0, 0.5, 0),
                          scale: Vector3(1.0, 1.2, 0.5)),
               name: 'torso'),
      // ... arms, legs
    ];
  }
}

class BodyPart {
  final Mesh mesh;
  final Transform3d transform;
  final String name;
  // getWorldTransform(parentTransform) combines parent + local transforms
}
```

**Note:** Currently the player is rendered as a single `Mesh.cube`. The `BodyPart` system exists but is not yet wired into the render pipeline for multi-part rendering.

## Key File Index

| File | Lines | Purpose |
|------|-------|---------|
| `lib/rendering3d/mesh.dart` | 503 | Mesh data structure + factory constructors |
| `lib/rendering3d/math/transform3d.dart` | 155 | Position/rotation/scale + matrix generation |
| `lib/rendering3d/camera3d.dart` | 313 | Perspective camera with orbit/follow modes |
| `lib/rendering3d/webgl_renderer.dart` | 434 | WebGL context, shaders, buffer management |
| `lib/rendering3d/shader_program.dart` | ~200 | Shader compilation + uniform management |
| `lib/rendering3d/player_mesh.dart` | 125 | Player mesh factories (cube + humanoid) |
| `lib/rendering3d/infinite_terrain_manager.dart` | ~300 | Chunk loading/unloading/LOD around player |
| `lib/rendering3d/terrain_lod.dart` | ~250 | LOD mesh generation from heightmap |
| `lib/rendering3d/heightmap.dart` | ~200 | Simplex noise height generation |
| `lib/rendering3d/game_config_terrain.dart` | ~80 | Terrain config constants |
| `lib/rendering3d/texture_manager.dart` | ~150 | Terrain texture loading + binding |
| `lib/rendering3d/splat_map_generator.dart` | ~100 | Height/slope-based texture blending maps |
| `lib/rendering3d/shaders/terrain_shaders.dart` | ~200 | GLSL vertex/fragment for terrain |
| `lib/rendering3d/ley_lines.dart` | ~300 | Voronoi-based ley line generation + mana regen |
| `lib/game3d/systems/render_system.dart` | 384 | Render orchestration (draw order) |
| `lib/game3d/rendering/wind_particles.dart` | ~200 | Batched wind particle system |
