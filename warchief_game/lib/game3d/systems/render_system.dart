import '../state/game_state.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';

/// Render System - Handles 3D scene rendering
///
/// Orchestrates rendering of all game objects in the correct order:
/// 1. Terrain
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

    // Render terrain tiles
    if (gameState.terrainTiles != null) {
      for (final tile in gameState.terrainTiles!) {
        renderer.render(tile.mesh, tile.transform, camera);
      }
    }

    // Render shadow (before player so it appears underneath)
    if (gameState.shadowMesh != null && gameState.shadowTransform != null) {
      renderer.render(gameState.shadowMesh!, gameState.shadowTransform!, camera);
    }

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
}
