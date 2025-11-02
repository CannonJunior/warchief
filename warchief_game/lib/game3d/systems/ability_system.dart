import 'package:vector_math/vector_math.dart';
import 'dart:math' as Math;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/projectile.dart';
import '../../models/impact_effect.dart';

/// Ability System - Handles all player ability logic
///
/// Manages player abilities including:
/// - Ability cooldown updates
/// - Ability 1: Sword (melee attack with animation)
/// - Ability 2: Fireball (ranged projectile with collision)
/// - Ability 3: Heal (self-heal with visual effect)
/// - Impact effects (visual feedback for hits)
class AbilitySystem {
  AbilitySystem._(); // Private constructor to prevent instantiation

  /// Updates all ability systems
  ///
  /// This is the main entry point for the ability system. It updates cooldowns,
  /// active abilities, projectiles, and visual effects.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void update(double dt, GameState gameState) {
    updateCooldowns(dt, gameState);
    updateAbility1(dt, gameState);
    updateAbility2(dt, gameState);
    updateAbility3(dt, gameState);
    updateImpactEffects(dt, gameState);
  }

  /// Updates all ability cooldowns
  ///
  /// Decrements cooldown timers for all three abilities.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateCooldowns(double dt, GameState gameState) {
    if (gameState.ability1Cooldown > 0) gameState.ability1Cooldown -= dt;
    if (gameState.ability2Cooldown > 0) gameState.ability2Cooldown -= dt;
    if (gameState.ability3Cooldown > 0) gameState.ability3Cooldown -= dt;
  }

  // ==================== ABILITY 1: SWORD ====================

  /// Handles Ability 1 (Sword) input
  ///
  /// Activates the sword attack if cooldown is ready and ability is not already active.
  ///
  /// Parameters:
  /// - ability1KeyPressed: Whether the ability 1 key is currently pressed
  /// - gameState: Current game state to update
  static void handleAbility1Input(bool ability1KeyPressed, GameState gameState) {
    if (ability1KeyPressed &&
        gameState.ability1Cooldown <= 0 &&
        !gameState.ability1Active) {
      gameState.ability1Active = true;
      gameState.ability1ActiveTime = 0.0;
      gameState.ability1Cooldown = gameState.ability1CooldownMax;
      print('Sword attack activated!');
    }
  }

  /// Updates Ability 1 (Sword) animation
  ///
  /// Updates the sword position and swing animation during the active duration.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateAbility1(double dt, GameState gameState) {
    if (!gameState.ability1Active) return;

    gameState.ability1ActiveTime += dt;

    if (gameState.ability1ActiveTime >= gameState.ability1Duration) {
      gameState.ability1Active = false;
    } else if (gameState.swordTransform != null && gameState.playerTransform != null) {
      // Position sword in front of player, rotating during swing
      final forward = Vector3(
        -Math.sin(_radians(gameState.playerRotation)),
        0,
        -Math.cos(_radians(gameState.playerRotation)),
      );
      final swingProgress = gameState.ability1ActiveTime / gameState.ability1Duration;
      final swingAngle = swingProgress * 180; // 0 to 180 degrees

      gameState.swordTransform!.position = gameState.playerTransform!.position + forward * 0.8;
      gameState.swordTransform!.position.y = gameState.playerTransform!.position.y;
      gameState.swordTransform!.rotation.y = gameState.playerRotation + swingAngle - 90;
    }
  }

  // ==================== ABILITY 2: FIREBALL ====================

  /// Handles Ability 2 (Fireball) input
  ///
  /// Creates a new fireball projectile if cooldown is ready.
  ///
  /// Parameters:
  /// - ability2KeyPressed: Whether the ability 2 key is currently pressed
  /// - gameState: Current game state to update
  static void handleAbility2Input(bool ability2KeyPressed, GameState gameState) {
    if (ability2KeyPressed &&
        gameState.ability2Cooldown <= 0 &&
        gameState.playerTransform != null) {
      // Create fireball projectile
      final forward = Vector3(
        -Math.sin(_radians(gameState.playerRotation)),
        0,
        -Math.cos(_radians(gameState.playerRotation)),
      );

      final fireballMesh = Mesh.cube(
        size: GameConfig.ability2ProjectileSize,
        color: GameConfig.ability2ProjectileColor,
      );

      final startPos = gameState.playerTransform!.position.clone() + forward * 1.0;
      startPos.y = gameState.playerTransform!.position.y;

      final fireballTransform = Transform3d(
        position: startPos,
        scale: Vector3(1, 1, 1),
      );

      gameState.fireballs.add(Projectile(
        mesh: fireballMesh,
        transform: fireballTransform,
        velocity: forward * GameConfig.ability2ProjectileSpeed,
      ));

      gameState.ability2Cooldown = gameState.ability2CooldownMax;
      print('Fireball launched!');
    }
  }

  /// Updates Ability 2 (Fireball) projectiles and collision detection
  ///
  /// Moves all active fireballs, checks for collisions with the monster,
  /// and creates impact effects on hit.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateAbility2(double dt, GameState gameState) {
    gameState.fireballs.removeWhere((fireball) {
      // Move fireball
      fireball.transform.position += fireball.velocity * dt;
      fireball.lifetime -= dt;

      // Check collision with monster
      if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
        final distance = (fireball.transform.position - gameState.monsterTransform!.position).length;

        if (distance < GameConfig.collisionThreshold) {
          // Create impact effect at collision point
          final impactMesh = Mesh.cube(
            size: GameConfig.fireballImpactSize,
            color: GameConfig.fireballImpactColor,
          );
          final impactTransform = Transform3d(
            position: fireball.transform.position.clone(),
            scale: Vector3(1, 1, 1),
          );
          gameState.impactEffects.add(ImpactEffect(
            mesh: impactMesh,
            transform: impactTransform,
          ));

          // Deal damage to monster
          gameState.monsterHealth = (gameState.monsterHealth - GameConfig.ability2Damage)
              .clamp(0.0, gameState.monsterMaxHealth);
          print('Fireball hit monster for ${GameConfig.ability2Damage} damage! '
                'Monster health: ${gameState.monsterHealth.toStringAsFixed(1)}');

          // Remove fireball
          return true;
        }
      }

      // Remove if lifetime expired
      return fireball.lifetime <= 0;
    });
  }

  // ==================== ABILITY 3: HEAL ====================

  /// Handles Ability 3 (Heal) input
  ///
  /// Activates the heal effect if cooldown is ready and ability is not already active.
  ///
  /// Parameters:
  /// - ability3KeyPressed: Whether the ability 3 key is currently pressed
  /// - gameState: Current game state to update
  static void handleAbility3Input(bool ability3KeyPressed, GameState gameState) {
    if (ability3KeyPressed &&
        gameState.ability3Cooldown <= 0 &&
        !gameState.ability3Active) {
      gameState.ability3Active = true;
      gameState.ability3ActiveTime = 0.0;
      gameState.ability3Cooldown = gameState.ability3CooldownMax;
      print('Heal activated!');
    }
  }

  /// Updates Ability 3 (Heal) visual effect
  ///
  /// Updates the heal effect position and pulsing animation during the active duration.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateAbility3(double dt, GameState gameState) {
    if (!gameState.ability3Active) return;

    gameState.ability3ActiveTime += dt;

    if (gameState.ability3ActiveTime >= gameState.ability3Duration) {
      gameState.ability3Active = false;
    } else if (gameState.healEffectTransform != null && gameState.playerTransform != null) {
      // Position heal effect around player with pulsing animation
      gameState.healEffectTransform!.position = gameState.playerTransform!.position.clone();
      final pulseScale = 1.0 + (Math.sin(gameState.ability3ActiveTime * 10) * 0.2);
      gameState.healEffectTransform!.scale = Vector3(pulseScale, pulseScale, pulseScale);
    }
  }

  // ==================== VISUAL EFFECTS ====================

  /// Updates all impact effects
  ///
  /// Handles the lifecycle and animation of visual impact effects,
  /// including scaling and removal when expired.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateImpactEffects(double dt, GameState gameState) {
    gameState.impactEffects.removeWhere((impact) {
      impact.lifetime -= dt;

      // Scale effect (expand and fade)
      final scale = 1.0 + (impact.progress * GameConfig.impactEffectGrowthScale);
      impact.transform.scale = Vector3(scale, scale, scale);

      return impact.lifetime <= 0;
    });
  }

  // ==================== UTILITY FUNCTIONS ====================

  /// Converts degrees to radians
  ///
  /// Parameters:
  /// - degrees: Angle in degrees
  ///
  /// Returns:
  /// - Angle in radians
  static double _radians(double degrees) => degrees * (Math.pi / 180);
}
