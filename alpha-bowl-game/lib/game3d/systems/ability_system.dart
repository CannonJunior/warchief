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
  /// Activates spin evasion move if cooldown is ready.
  /// Spin direction is determined by current movement:
  /// - Clockwise (E key): Spins around right edge
  /// - Counter-clockwise (Q key or default): Spins around left edge
  ///
  /// Parameters:
  /// - ability3KeyPressed: Whether the ability 3 key is currently pressed
  /// - spinClockwise: True for clockwise (E), false for counter-clockwise (Q or default)
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

      // Store initial position and rotation
      gameState.ability3StartPosition = gameState.playerTransform!.position.clone();
      gameState.ability3StartRotation = gameState.playerRotation;

      // Calculate pivot point based on spin direction
      // Player size is 0.5, so edge is 0.25 units from center
      final playerRadius = GameConfig.playerSize / 2.0;

      // Get perpendicular direction (90 degrees from facing direction)
      // For counter-clockwise: pivot on LEFT edge (add 90 degrees)
      // For clockwise: pivot on RIGHT edge (subtract 90 degrees)
      final pivotAngle = spinClockwise
          ? gameState.playerRotation - 90  // Right edge
          : gameState.playerRotation + 90; // Left edge

      final pivotAngleRad = _radians(pivotAngle);
      final pivotOffset = Vector3(
        -math.sin(pivotAngleRad) * playerRadius,
        0,
        -math.cos(pivotAngleRad) * playerRadius,
      );

      gameState.ability3PivotPoint = gameState.ability3StartPosition! + pivotOffset;

      final direction = spinClockwise ? 'clockwise around right edge' : 'counter-clockwise around left edge';
      print('${spinMove.name} activated! Spinning $direction to evade tacklers...');
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
      gameState.ability3Active = false;
      print('${spinMove.name} completed!');
    } else if (gameState.playerTransform != null &&
               gameState.ability3PivotPoint != null &&
               gameState.ability3StartPosition != null) {
      // Calculate spin progress (0 to 1)
      final spinProgress = gameState.ability3ActiveTime / spinMove.duration;

      // Player rotates 360 degrees but only orbits 180 degrees around pivot
      // This creates the football spin move where player ends up displaced by their width
      final rotationAngle = spinProgress * 360; // Full 360° rotation
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

      // Rotate player by full 360 degrees (independent of orbital motion)
      gameState.playerRotation = gameState.ability3StartRotation +
                                  (gameState.ability3SpinClockwise ? rotationAngle : -rotationAngle);
      gameState.playerRotation = gameState.playerRotation % 360;

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
