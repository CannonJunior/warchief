import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../state/game_state.dart';
import '../state/game_config.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/ley_lines.dart';

/// Render System - Handles 3D scene rendering
///
/// Orchestrates rendering of all game objects in the correct order:
/// 1. Terrain (with LOD)
/// 2. Shadows
/// 3. Characters (player, monster, allies)
/// 4. Effects (abilities, projectiles, impacts)
class RenderSystem {
  RenderSystem._(); // Private constructor

  /// Renders the entire 3D scene
  ///
  /// Parameters:
  /// - renderer: WebGL renderer to use
  /// - camera: Camera for view/projection
  /// - gameState: Current game state with all renderable objects
  static void render(
    WebGLRenderer renderer,
    Camera3D camera,
    GameState gameState,
  ) {
    // Clear screen
    renderer.clear();

    // Render infinite terrain chunks with LOD and texture splatting
    if (gameState.infiniteTerrainManager != null) {
      final chunks = gameState.infiniteTerrainManager!.getLoadedChunks();
      for (final chunk in chunks) {
        // Create transform for chunk
        final chunkTransform = Transform3d(
          position: chunk.worldPosition,
        );

        // Render terrain with texture splatting (if enabled)
        // Falls back to regular rendering if texturing not initialized
        renderer.renderTerrain(chunk, chunkTransform, camera);
      }
    }
    // Fallback to old terrain system (backwards compatibility)
    else if (gameState.terrainTiles != null) {
      for (final tile in gameState.terrainTiles!) {
        renderer.render(tile.mesh, tile.transform, camera);
      }
    }

    // Render Ley Lines (magical energy lines on terrain)
    _renderLeyLines(renderer, camera, gameState);

    // Render shadow (before player so it appears underneath)
    if (gameState.shadowMesh != null && gameState.shadowTransform != null) {
      renderer.render(gameState.shadowMesh!, gameState.shadowTransform!, camera);
    }

    // Render target indicator (yellow dashed rectangle around target's base)
    _renderTargetIndicator(renderer, camera, gameState);

    // Render player
    if (gameState.playerMesh != null && gameState.playerTransform != null) {
      renderer.render(gameState.playerMesh!, gameState.playerTransform!, camera);
    }

    // Render direction indicator
    if (gameState.directionIndicator != null && gameState.directionIndicatorTransform != null) {
      renderer.render(gameState.directionIndicator!, gameState.directionIndicatorTransform!, camera);
    }

    // Render monster
    if (gameState.monsterMesh != null && gameState.monsterTransform != null) {
      renderer.render(gameState.monsterMesh!, gameState.monsterTransform!, camera);
    }

    // Render monster direction indicator
    if (gameState.monsterDirectionIndicator != null && gameState.monsterDirectionIndicatorTransform != null) {
      renderer.render(gameState.monsterDirectionIndicator!, gameState.monsterDirectionIndicatorTransform!, camera);
    }

    // Render allies
    for (final ally in gameState.allies) {
      // Render ally mesh
      renderer.render(ally.mesh, ally.transform, camera);

      // Render ally projectiles
      for (final projectile in ally.projectiles) {
        renderer.render(projectile.mesh, projectile.transform, camera);
      }
    }

    // Render minions
    for (final minion in gameState.aliveMinions) {
      // Render minion mesh
      renderer.render(minion.mesh, minion.transform, camera);

      // Render minion direction indicator
      if (minion.directionIndicatorTransform != null) {
        final indicator = gameState.getMinionDirectionIndicator(minion.definition);
        renderer.render(indicator, minion.directionIndicatorTransform!, camera);
      }

      // Render minion projectiles
      for (final projectile in minion.projectiles) {
        renderer.render(projectile.mesh, projectile.transform, camera);
      }
    }

    // Render target dummy (for DPS testing)
    if (gameState.targetDummy != null && gameState.targetDummy!.isSpawned) {
      final dummy = gameState.targetDummy!;
      renderer.render(dummy.mesh, dummy.transform, camera);
      // Render dummy direction indicator
      if (dummy.directionIndicator != null && dummy.directionIndicatorTransform != null) {
        renderer.render(dummy.directionIndicator!, dummy.directionIndicatorTransform!, camera);
      }
    }

    // Render ability effects
    // Render player sword attack
    if (gameState.ability1Active && gameState.swordMesh != null && gameState.swordTransform != null) {
      renderer.render(gameState.swordMesh!, gameState.swordTransform!, camera);
    }

    // Render monster sword attack
    if (gameState.monsterAbility1Active && gameState.monsterSwordMesh != null && gameState.monsterSwordTransform != null) {
      renderer.render(gameState.monsterSwordMesh!, gameState.monsterSwordTransform!, camera);
    }

    // Render fireballs
    for (final fireball in gameState.fireballs) {
      renderer.render(fireball.mesh, fireball.transform, camera);
    }

    // Render monster projectiles
    for (final projectile in gameState.monsterProjectiles) {
      renderer.render(projectile.mesh, projectile.transform, camera);
    }

    // Render impact effects
    for (final impact in gameState.impactEffects) {
      renderer.render(impact.mesh, impact.transform, camera);
    }

    // Render heal effect
    if (gameState.ability3Active && gameState.healEffectMesh != null && gameState.healEffectTransform != null) {
      renderer.render(gameState.healEffectMesh!, gameState.healEffectTransform!, camera);
    }
  }

  /// Render target indicator around the current target
  static void _renderTargetIndicator(
    WebGLRenderer renderer,
    Camera3D camera,
    GameState gameState,
  ) {
    if (gameState.currentTargetId == null) return;

    // Get target position, size, and indicator color
    Vector3? targetPosition;
    double targetSize = 1.5; // Default size
    Vector3 indicatorColor = Vector3(1.0, 0.2, 0.2); // Red default (enemies)

    if (gameState.currentTargetId == 'boss') {
      if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
        targetPosition = gameState.monsterTransform!.position;
        targetSize = 1.8; // Boss is larger
      }
    } else if (gameState.currentTargetId == 'target_dummy') {
      // Target dummy for DPS testing
      if (gameState.targetDummy != null && gameState.targetDummy!.isSpawned) {
        targetPosition = gameState.targetDummy!.position;
        targetSize = 1.5 * 1.5; // Dummy size * indicator scale
      }
    } else if (gameState.currentTargetId!.startsWith('ally_')) {
      // Ally target - green indicator
      final index = int.tryParse(gameState.currentTargetId!.substring(5));
      if (index != null && index < gameState.allies.length && gameState.allies[index].health > 0) {
        targetPosition = gameState.allies[index].transform.position;
        targetSize = GameConfig.allySize * 1.5;
        indicatorColor = Vector3(0.2, 1.0, 0.2); // Green for allies
      }
    } else {
      // Find minion by instance ID
      for (final minion in gameState.aliveMinions) {
        if (minion.instanceId == gameState.currentTargetId) {
          targetPosition = minion.transform.position;
          targetSize = minion.definition.effectiveScale * 1.5;
          break;
        }
      }
    }

    if (targetPosition == null) return;

    // Recreate mesh when target changes size or ID (color may differ)
    // Reason: Ally targets use green, enemies use red, so we must regenerate
    // when switching between entity types, not just sizes.
    final needsNewMesh = gameState.targetIndicatorMesh == null ||
        gameState.lastTargetIndicatorSize != targetSize ||
        gameState.lastTargetIndicatorId != gameState.currentTargetId;

    if (needsNewMesh) {
      gameState.targetIndicatorMesh = Mesh.targetIndicator(
        size: targetSize,
        lineWidth: 0.10,
        color: indicatorColor,
      );
      gameState.lastTargetIndicatorSize = targetSize;
      gameState.lastTargetIndicatorId = gameState.currentTargetId;
    }

    // Update transform position - place at unit's center height for visibility
    gameState.targetIndicatorTransform ??= Transform3d();
    gameState.targetIndicatorTransform!.position = Vector3(
      targetPosition.x,
      targetPosition.y, // At unit's center (halfway up)
      targetPosition.z,
    );

    // Render the indicator
    renderer.render(
      gameState.targetIndicatorMesh!,
      gameState.targetIndicatorTransform!,
      camera,
    );
  }

  /// Cached Ley Line meshes to avoid regenerating every frame
  static final Map<int, Mesh> _leyLineMeshCache = {};
  static int _lastLeyLineHash = 0;

  /// Render Ley Lines on the terrain
  static void _renderLeyLines(
    WebGLRenderer renderer,
    Camera3D camera,
    GameState gameState,
  ) {
    if (gameState.leyLineManager == null) return;
    if (gameState.playerTransform == null) return;

    final playerPos = gameState.playerTransform!.position;
    final viewRadius = 100.0; // Only render Ley Lines within this radius

    // Get visible segments
    final segments = gameState.leyLineManager!.getVisibleSegments(
      playerPos.x,
      playerPos.z,
      viewRadius,
    );

    if (segments.isEmpty) return;

    // Create a hash to detect changes
    final hash = segments.length.hashCode;

    // Regenerate mesh if segments changed
    if (hash != _lastLeyLineHash || !_leyLineMeshCache.containsKey(hash)) {
      _leyLineMeshCache.clear();
      _leyLineMeshCache[hash] = _createLeyLineMesh(segments, gameState);
      _lastLeyLineHash = hash;
    }

    final mesh = _leyLineMeshCache[hash];
    if (mesh == null) return;

    // Render at world origin (positions are absolute)
    final transform = Transform3d(position: Vector3(0, 0, 0));
    renderer.render(mesh, transform, camera);
  }

  /// Create a mesh for the visible Ley Line segments
  static Mesh _createLeyLineMesh(
    List<LeyLineSegment> segments,
    GameState gameState,
  ) {
    final vertices = <double>[];
    final indices = <int>[];
    var vertexCount = 0;

    for (final seg in segments) {
      // Get terrain height at segment endpoints
      double y1 = 0.15;
      double y2 = 0.15;
      if (gameState.infiniteTerrainManager != null) {
        y1 = gameState.infiniteTerrainManager!.getTerrainHeight(seg.x1, seg.z1) + 0.15;
        y2 = gameState.infiniteTerrainManager!.getTerrainHeight(seg.x2, seg.z2) + 0.15;
      }

      // Calculate perpendicular direction for width
      final dx = seg.x2 - seg.x1;
      final dz = seg.z2 - seg.z1;
      final len = seg.length;
      if (len < 0.1) continue;

      final perpX = -dz / len;
      final perpZ = dx / len;

      // Create multiple quads with varying widths for wispy effect
      for (int layer = 0; layer < 3; layer++) {
        final layerWidth = seg.thickness * (1.0 - layer * 0.25);
        final alpha = 0.8 - layer * 0.2;

        final halfWidth = layerWidth / 2;

        // Corner positions
        final p1x = seg.x1 - perpX * halfWidth;
        final p1z = seg.z1 - perpZ * halfWidth;
        final p2x = seg.x1 + perpX * halfWidth;
        final p2z = seg.z1 + perpZ * halfWidth;
        final p3x = seg.x2 + perpX * halfWidth;
        final p3z = seg.z2 + perpZ * halfWidth;
        final p4x = seg.x2 - perpX * halfWidth;
        final p4z = seg.z2 - perpZ * halfWidth;

        // Blue color with varying intensity
        final r = 0.2 * alpha;
        final g = 0.5 * alpha;
        final b = 1.0 * alpha;

        // Add 4 vertices for this layer's quad
        // Vertex format: x, y, z, r, g, b
        vertices.addAll([p1x, y1, p1z, r, g, b]);
        vertices.addAll([p2x, y1, p2z, r, g, b]);
        vertices.addAll([p3x, y2, p3z, r, g, b]);
        vertices.addAll([p4x, y2, p4z, r, g, b]);

        // Add indices for 2 triangles
        final base = vertexCount;
        indices.addAll([base, base + 1, base + 2]); // Triangle 1
        indices.addAll([base, base + 2, base + 3]); // Triangle 2

        vertexCount += 4;
      }
    }

    if (vertices.isEmpty) {
      return Mesh.cube(size: 0.01, color: Vector3(0, 0, 0)); // Dummy mesh
    }

    return Mesh.fromVerticesAndIndices(
      vertices: vertices,
      indices: indices,
      vertexStride: 6, // x, y, z, r, g, b
    );
  }
}
