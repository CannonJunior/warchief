import 'package:vector_math/vector_math.dart' hide Colors;
import '../state/game_state.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/mesh.dart';

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

    // Get target position and size
    Vector3? targetPosition;
    double targetSize = 1.5; // Default size

    if (gameState.currentTargetId == 'boss') {
      if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
        targetPosition = gameState.monsterTransform!.position;
        targetSize = 1.8; // Boss is larger
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

    // Check if target changed and we need to recreate the mesh with new size
    final needsNewMesh = gameState.targetIndicatorMesh == null ||
        gameState.lastTargetIndicatorSize != targetSize;

    if (needsNewMesh) {
      gameState.targetIndicatorMesh = Mesh.targetIndicator(
        size: targetSize,
        lineWidth: 0.06,
        color: Vector3(1.0, 0.9, 0.0), // Yellow
      );
      gameState.lastTargetIndicatorSize = targetSize;
    }

    // Update transform position
    gameState.targetIndicatorTransform ??= Transform3d();
    gameState.targetIndicatorTransform!.position = Vector3(
      targetPosition.x,
      targetPosition.y + 0.02, // Slightly above ground
      targetPosition.z,
    );

    // Render the indicator
    renderer.render(
      gameState.targetIndicatorMesh!,
      gameState.targetIndicatorTransform!,
      camera,
    );
  }
}
