import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../state/abilities_config.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/projectile.dart';
import 'combat_system.dart';

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
    updateAbility4(dt, gameState);
    updateImpactEffects(dt, gameState);
  }

  /// Updates all ability cooldowns
  ///
  /// Decrements cooldown timers for all abilities.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateCooldowns(double dt, GameState gameState) {
    if (gameState.ability1Cooldown > 0) gameState.ability1Cooldown -= dt;
    if (gameState.ability2Cooldown > 0) gameState.ability2Cooldown -= dt;
    if (gameState.ability3Cooldown > 0) gameState.ability3Cooldown -= dt;
    if (gameState.ability4Cooldown > 0) gameState.ability4Cooldown -= dt;
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
      gameState.ability1HitRegistered = false; // Reset hit tracker for new swing
      print('Sword attack activated!');
    }
  }

  /// Updates Ability 1 (Sword) animation and collision detection
  ///
  /// Updates the sword position and swing animation during the active duration.
  /// Checks for collision with the monster and applies damage.
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
        -math.sin(_radians(gameState.playerRotation)),
        0,
        -math.cos(_radians(gameState.playerRotation)),
      );
      final swingProgress = gameState.ability1ActiveTime / gameState.ability1Duration;
      final swingAngle = swingProgress * 180; // 0 to 180 degrees

      gameState.swordTransform!.position = gameState.playerTransform!.position + forward * 0.8;
      gameState.swordTransform!.position.y = gameState.playerTransform!.position.y;
      gameState.swordTransform!.rotation.y = gameState.playerRotation + swingAngle - 90;

      // Check collision with monster (only once per swing)
      if (!gameState.ability1HitRegistered) {
        final sword = AbilitiesConfig.playerSword;
        final swordTipPosition = gameState.playerTransform!.position + forward * sword.range;

        final hitRegistered = CombatSystem.checkAndDamageMonster(
          gameState,
          attackerPosition: swordTipPosition,
          damage: sword.damage,
          attackType: sword.name,
          impactColor: sword.impactColor,
          impactSize: sword.impactSize,
        );

        if (hitRegistered) {
          gameState.ability1HitRegistered = true;
        }
      }
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
      final fireball = AbilitiesConfig.playerFireball;

      // Create fireball projectile
      final forward = Vector3(
        -math.sin(_radians(gameState.playerRotation)),
        0,
        -math.cos(_radians(gameState.playerRotation)),
      );

      final fireballMesh = Mesh.cube(
        size: fireball.projectileSize,
        color: fireball.color,
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
        velocity: forward * fireball.projectileSpeed,
      ));

      gameState.ability2Cooldown = gameState.ability2CooldownMax;
      print('${fireball.name} launched!');
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
    final fireballConfig = AbilitiesConfig.playerFireball;

    gameState.fireballs.removeWhere((fireball) {
      // Move fireball
      fireball.transform.position += fireball.velocity * dt;
      fireball.lifetime -= dt;

      // Check collision with monster using unified combat system
      final hitRegistered = CombatSystem.checkAndDamageMonster(
        gameState,
        attackerPosition: fireball.transform.position,
        damage: fireballConfig.damage,
        attackType: fireballConfig.name,
        impactColor: fireballConfig.impactColor,
        impactSize: fireballConfig.impactSize,
      );

      if (hitRegistered) return true;

      // Remove if lifetime expired
      return fireball.lifetime <= 0;
    });
  }

  // ==================== ABILITY 3: HEAL ====================

  /// Handles Ability 3 (Heal) input
  ///
  /// Activates the heal effect if cooldown is ready and ability is not already active.
  /// Immediately restores health to the player.
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

      // Actually heal the player
      final healAbility = AbilitiesConfig.playerHeal;
      final oldHealth = gameState.playerHealth;
      gameState.playerHealth = math.min(gameState.playerMaxHealth, gameState.playerHealth + healAbility.healAmount);
      final healedAmount = gameState.playerHealth - oldHealth;

      print('[HEAL] Player heal activated! Restored ${healedAmount.toStringAsFixed(1)} HP (${gameState.playerHealth.toStringAsFixed(0)}/${gameState.playerMaxHealth})');
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
      final pulseScale = 1.0 + (math.sin(gameState.ability3ActiveTime * 10) * 0.2);
      gameState.healEffectTransform!.scale = Vector3(pulseScale, pulseScale, pulseScale);
    }
  }

  // ==================== ABILITY 4: DASH ATTACK ====================

  /// Handles Ability 4 (Dash Attack) input
  ///
  /// Activates the dash attack if cooldown is ready and ability is not already active.
  /// The player will dash forward and damage enemies in their path.
  ///
  /// Parameters:
  /// - ability4KeyPressed: Whether the ability 4 key is currently pressed
  /// - gameState: Current game state to update
  static void handleAbility4Input(bool ability4KeyPressed, GameState gameState) {
    if (ability4KeyPressed &&
        gameState.ability4Cooldown <= 0 &&
        !gameState.ability4Active) {
      gameState.ability4Active = true;
      gameState.ability4ActiveTime = 0.0;
      gameState.ability4Cooldown = gameState.ability4CooldownMax;
      gameState.ability4HitRegistered = false; // Reset hit tracker for new dash
      print('Dash Attack activated!');
    }
  }

  /// Updates Ability 4 (Dash Attack) movement and collision detection
  ///
  /// Moves the player forward rapidly during the dash duration and checks
  /// for collision with enemies, applying damage on hit.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateAbility4(double dt, GameState gameState) {
    if (!gameState.ability4Active) return;

    gameState.ability4ActiveTime += dt;

    if (gameState.ability4ActiveTime >= gameState.ability4Duration) {
      gameState.ability4Active = false;
    } else if (gameState.playerTransform != null) {
      final dashConfig = AbilitiesConfig.playerDashAttack;

      // Calculate forward direction based on player rotation
      final forward = Vector3(
        -math.sin(_radians(gameState.playerRotation)),
        0,
        -math.cos(_radians(gameState.playerRotation)),
      );

      // Calculate dash speed (total distance / duration)
      final dashSpeed = dashConfig.range / dashConfig.duration;

      // Move player forward at dash speed
      gameState.playerTransform!.position += forward * dashSpeed * dt;

      // Get terrain height at new position and apply it
      if (gameState.infiniteTerrainManager != null) {
        final terrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(
          gameState.playerTransform!.position.x,
          gameState.playerTransform!.position.z,
        );
        gameState.playerTransform!.position.y = terrainHeight;
      }

      // Check collision with monster during dash
      if (!gameState.ability4HitRegistered) {
        final hitRegistered = CombatSystem.checkAndDamageMonster(
          gameState,
          attackerPosition: gameState.playerTransform!.position,
          damage: dashConfig.damage,
          attackType: dashConfig.name,
          impactColor: dashConfig.impactColor,
          impactSize: dashConfig.impactSize,
        );

        if (hitRegistered) {
          gameState.ability4HitRegistered = true;
          // Apply knockback to monster
          if (gameState.monsterTransform != null && dashConfig.knockbackForce > 0) {
            gameState.monsterTransform!.position += forward * dashConfig.knockbackForce;
          }
        }
      }

      // Update dash trail visual effect if it exists
      if (gameState.dashTrailTransform != null) {
        gameState.dashTrailTransform!.position = gameState.playerTransform!.position.clone();
        gameState.dashTrailTransform!.rotation.y = gameState.playerRotation;
      }
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
  static double _radians(double degrees) => degrees * (math.pi / 180);
}
