import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../state/abilities_config.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/camera3d.dart';
import '../../models/projectile.dart';
import 'combat_system.dart';
import '../utils/culling_system.dart';

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

  // ==================== ABILITY 1: BULLET PASS ====================

  /// Handles Ability 1 (Bullet Pass) input
  ///
  /// Throws a football forward if cooldown is ready.
  ///
  /// Parameters:
  /// - ability1KeyPressed: Whether the ability 1 key is currently pressed
  /// - gameState: Current game state to update
  static void handleAbility1Input(bool ability1KeyPressed, GameState gameState) {
    if (ability1KeyPressed &&
        gameState.ability1Cooldown <= 0 &&
        gameState.playerTransform != null) {
      final pass = AbilitiesConfig.bulletPass;

      // Calculate throw direction
      final forward = Vector3(
        -math.sin(_radians(gameState.playerRotation)),
        0,
        -math.cos(_radians(gameState.playerRotation)),
      );

      // Create football projectile
      final footballMesh = gameState.getFireballMesh(); // Reuse mesh (will appear as football)

      final startPos = gameState.playerTransform!.position.clone() + forward * 1.0;
      startPos.y = gameState.playerTransform!.position.y + 0.5; // Throw from chest height

      final footballTransform = Transform3d(
        position: startPos,
        scale: Vector3(pass.projectileSize, pass.projectileSize, pass.projectileSize),
      );

      gameState.fireballs.add(Projectile(
        mesh: footballMesh,
        transform: footballTransform,
        velocity: forward * pass.projectileSpeed,
      ));

      gameState.ability1Cooldown = gameState.ability1CooldownMax;
      print('${pass.name} thrown!');
    }
  }

  /// Updates Ability 1 (Bullet Pass) - Football projectiles
  ///
  /// Football projectiles are handled in updateAbility2() with other projectiles.
  /// This method is kept for backwards compatibility but does nothing for passes.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateAbility1(double dt, GameState gameState) {
    // Bullet Pass is instant - no ongoing animation needed
    // Football projectiles are updated in updateAbility2()
  }

  // ==================== ABILITY 2: SPRINT ====================

  /// Handles Ability 2 (Sprint) input
  ///
  /// Activates speed boost if cooldown is ready.
  ///
  /// Parameters:
  /// - ability2KeyPressed: Whether the ability 2 key is currently pressed
  /// - gameState: Current game state to update
  static void handleAbility2Input(bool ability2KeyPressed, GameState gameState) {
    if (ability2KeyPressed &&
        gameState.ability2Cooldown <= 0 &&
        !gameState.ability2Active) {
      final sprint = AbilitiesConfig.sprint;

      gameState.ability2Active = true;
      gameState.ability2ActiveTime = 0.0;
      gameState.ability2Cooldown = gameState.ability2CooldownMax;

      // Apply speed boost
      gameState.playerSpeed *= (1.0 + sprint.statusStrength); // +75% speed

      print('${sprint.name} activated! Speed boosted for ${sprint.duration}s');
    }
  }

  /// Updates Ability 2 (Sprint) timer and speed restoration
  ///
  /// Manages sprint duration and restores normal speed when sprint ends.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateAbility2(double dt, GameState gameState) {
    // Update sprint timer
    if (gameState.ability2Active) {
      gameState.ability2ActiveTime += dt;
      final sprint = AbilitiesConfig.sprint;

      // Check if sprint duration expired
      if (gameState.ability2ActiveTime >= sprint.duration) {
        // Restore normal speed
        gameState.playerSpeed = GameConfig.playerSpeed;
        gameState.ability2Active = false;
        print('${sprint.name} ended - speed restored');
      }
    }

    // Also update football projectiles (from Bullet Pass ability 1)
    final passConfig = AbilitiesConfig.bulletPass;

    gameState.fireballs.removeWhere((projectile) {
      // Move projectile
      projectile.transform.position += projectile.velocity * dt;
      projectile.lifetime -= dt;

      // PERFORMANCE: Cull projectiles that leave the field
      if (!CullingSystem.isWithinFieldBounds(projectile.transform.position)) {
        return true; // Remove off-field projectile
      }

      // Check collision with monster using unified combat system
      final hitRegistered = CombatSystem.checkAndDamageMonster(
        gameState,
        attackerPosition: projectile.transform.position,
        damage: passConfig.damage,
        attackType: passConfig.name,
        impactColor: passConfig.impactColor,
        impactSize: passConfig.impactSize,
      );

      if (hitRegistered) return true;

      // Remove if lifetime expired
      return projectile.lifetime <= 0;
    });
  }

  // ==================== ABILITY 3: SPIN-OUT ====================

  /// Handles Ability 3 (Spin-out) input
  ///
  /// Activates lateral evasion move if cooldown is ready.
  /// Movement direction is determined by strafe input:
  /// - E key: Displace right
  /// - Q key: Displace left
  ///
  /// Parameters:
  /// - ability3KeyPressed: Whether the ability 3 key is currently pressed
  /// - spinClockwise: True for right displacement (E), false for left displacement (Q)
  /// - gameState: Current game state to update
  static void handleAbility3Input(bool ability3KeyPressed, bool spinClockwise, GameState gameState) {
    if (ability3KeyPressed &&
        gameState.ability3Cooldown <= 0 &&
        !gameState.ability3Active &&
        gameState.playerTransform != null) {
      final spinMove = AbilitiesConfig.spinMove;

      gameState.ability3Active = true;
      gameState.ability3ActiveTime = 0.0;
      gameState.ability3Cooldown = gameState.ability3CooldownMax;
      gameState.ability3SpinClockwise = spinClockwise;

      // Store initial position
      gameState.ability3StartPosition = gameState.playerTransform!.position.clone();

      final direction = spinClockwise ? 'right' : 'left';
      print('${spinMove.name} activated! Evading $direction...');
    }
  }

  /// Updates Ability 3 (Spin-out) animation and rotation
  ///
  /// Orbits the player around the pivot point (left or right edge) while rotating.
  /// Direction is determined when ability is activated based on movement keys.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateAbility3(double dt, GameState gameState) {
    if (!gameState.ability3Active) return;

    gameState.ability3ActiveTime += dt;
    final spinMove = AbilitiesConfig.spinMove;

    if (gameState.ability3ActiveTime >= spinMove.duration) {
      // Spin complete - lock in final position at 180° orbit
      if (gameState.playerTransform != null &&
          gameState.ability3PivotPoint != null &&
          gameState.ability3StartPosition != null) {

        final toPlayer = gameState.ability3StartPosition! - gameState.ability3PivotPoint!;
        final radius = math.sqrt(toPlayer.x * toPlayer.x + toPlayer.z * toPlayer.z);
        final initialAngle = math.atan2(toPlayer.x, toPlayer.z) * (180 / math.pi);

        // Final position at 180° orbit
        final finalAngle = gameState.ability3SpinClockwise
            ? initialAngle + 180
            : initialAngle - 180;

        final finalAngleRad = _radians(finalAngle);

        // Lock player at final orbital position
        gameState.playerTransform!.position.x =
            gameState.ability3PivotPoint!.x + (radius * math.sin(finalAngleRad));
        gameState.playerTransform!.position.z =
            gameState.ability3PivotPoint!.z + (radius * math.cos(finalAngleRad));

        // Restore original facing direction (player ends facing forward)
        gameState.playerRotation = gameState.ability3StartRotation;

        // Reset scale
        if (gameState.playerMesh != null) {
          gameState.playerTransform!.scale = Vector3(1.0, 1.0, 1.0);
        }
      }

      gameState.ability3Active = false;
      print('${spinMove.name} completed!');
    } else if (gameState.playerTransform != null &&
               gameState.ability3PivotPoint != null &&
               gameState.ability3StartPosition != null) {
      // Calculate spin progress (0 to 1)
      final spinProgress = gameState.ability3ActiveTime / spinMove.duration;

      // Player orbits 180 degrees around pivot for lateral displacement
      // Rotation stays at start angle to maintain forward facing direction
      final orbitalAngle = spinProgress * 180;  // Half 180° orbit (displacement)

      // Get initial angle from pivot to player
      final toPlayer = gameState.ability3StartPosition! - gameState.ability3PivotPoint!;
      final radius = math.sqrt(toPlayer.x * toPlayer.x + toPlayer.z * toPlayer.z);
      final initialAngle = math.atan2(toPlayer.x, toPlayer.z) * (180 / math.pi);

      // Calculate current orbital position based on spin direction
      // Counter-clockwise: orbit counter-clockwise (subtract angle)
      // Clockwise: orbit clockwise (add angle)
      final currentAngle = gameState.ability3SpinClockwise
          ? initialAngle + orbitalAngle  // Clockwise: add angle
          : initialAngle - orbitalAngle; // Counter-clockwise: subtract angle

      final currentAngleRad = _radians(currentAngle);

      // Position player at current angle around pivot
      final newX = gameState.ability3PivotPoint!.x + (radius * math.sin(currentAngleRad));
      final newZ = gameState.ability3PivotPoint!.z + (radius * math.cos(currentAngleRad));

      gameState.playerTransform!.position.x = newX;
      gameState.playerTransform!.position.z = newZ;

      // Maintain forward facing direction throughout spin
      // Add a subtle rotation wobble for visual effect (360° spin that returns to start)
      final visualSpinAngle = math.sin(spinProgress * 2 * math.pi) * 30; // ±30° wobble
      gameState.playerRotation = gameState.ability3StartRotation + visualSpinAngle;

      // Visual effect: slightly increase player size during spin
      final spinScale = 1.0 + (math.sin(spinProgress * math.pi) * 0.15); // Pulse during spin
      if (gameState.playerMesh != null) {
        gameState.playerTransform!.scale = Vector3(spinScale, spinScale, spinScale);
      }
    }
  }

  // ==================== VISUAL EFFECTS ====================

  /// Updates all impact effects
  ///
  /// Handles the lifecycle and animation of visual impact effects,
  /// including scaling and removal when expired.
  ///
  /// PERFORMANCE OPTIMIZATION: Removes effects that leave field boundaries
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateImpactEffects(double dt, GameState gameState) {
    gameState.impactEffects.removeWhere((impact) {
      impact.lifetime -= dt;

      // PERFORMANCE: Cull impact effects that are off-field
      if (!CullingSystem.isWithinFieldBounds(impact.transform.position)) {
        return true; // Remove off-field effect
      }

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
  static double _radians(double degrees) => degrees * (math.pi / 180);
}
