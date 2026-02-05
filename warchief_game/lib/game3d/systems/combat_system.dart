import 'package:vector_math/vector_math.dart';

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/impact_effect.dart';
import '../../models/monster.dart';

/// Target types for damage application
enum DamageTarget { player, monster, ally, minion }

/// Combat System - Unified damage and collision handling
///
/// Provides centralized functions for:
/// - Collision detection between attackers and targets
/// - Damage application to any unit (player, monster, ally)
/// - Impact effect creation
class CombatSystem {
  CombatSystem._(); // Private constructor to prevent instantiation

  /// Creates an impact effect at the specified position
  ///
  /// Parameters:
  /// - gameState: Current game state to add the effect to
  /// - position: World position for the impact effect
  /// - color: RGB color of the impact effect
  /// - size: Size of the impact effect
  static void createImpactEffect(
    GameState gameState, {
    required Vector3 position,
    required Vector3 color,
    required double size,
  }) {
    final impactMesh = Mesh.cube(
      size: size,
      color: color,
    );
    final impactTransform = Transform3d(
      position: position.clone(),
      scale: Vector3(1, 1, 1),
    );
    gameState.impactEffects.add(ImpactEffect(
      mesh: impactMesh,
      transform: impactTransform,
    ));
  }

  /// Checks collision and applies damage to the target if hit
  ///
  /// This is the main unified damage function used by all attacks.
  /// It checks if the attacker position is within collision threshold
  /// of the target, and if so, creates an impact effect and applies damage.
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - targetPosition: Position of the target unit
  /// - collisionThreshold: Distance threshold for collision detection
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - targetType: Type of target (player, monster, ally, or minion)
  /// - allyIndex: Index of the ally if targetType is ally (optional)
  /// - minionInstanceId: Instance ID of the minion if targetType is minion (optional)
  ///
  /// Returns:
  /// - true if hit was registered, false otherwise
  static bool checkAndApplyDamage(
    GameState gameState, {
    required Vector3 attackerPosition,
    required Vector3 targetPosition,
    required double collisionThreshold,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    required DamageTarget targetType,
    int? allyIndex,
    String? minionInstanceId,
  }) {
    final distance = (attackerPosition - targetPosition).length;

    if (distance < collisionThreshold) {
      // Create impact effect at collision point
      createImpactEffect(
        gameState,
        position: attackerPosition,
        color: impactColor,
        size: impactSize,
      );

      // Apply damage based on target type
      switch (targetType) {
        case DamageTarget.player:
          gameState.playerHealth = (gameState.playerHealth - damage)
              .clamp(0.0, gameState.playerMaxHealth);
          print('$attackType hit player for $damage damage! '
                'Player health: ${gameState.playerHealth.toStringAsFixed(1)}');
          break;

        case DamageTarget.monster:
          gameState.monsterHealth = (gameState.monsterHealth - damage)
              .clamp(0.0, gameState.monsterMaxHealth);
          print('$attackType hit monster for $damage damage! '
                'Monster health: ${gameState.monsterHealth.toStringAsFixed(1)}');
          break;

        case DamageTarget.ally:
          if (allyIndex != null && allyIndex < gameState.allies.length) {
            final ally = gameState.allies[allyIndex];
            ally.health = (ally.health - damage).clamp(0.0, ally.maxHealth);
            print('$attackType hit ally ${allyIndex + 1} for $damage damage! '
                  'Ally health: ${ally.health.toStringAsFixed(1)}');
          }
          break;

        case DamageTarget.minion:
          if (minionInstanceId != null) {
            final minion = gameState.minions.where(
              (m) => m.instanceId == minionInstanceId && m.isAlive
            ).firstOrNull;
            if (minion != null) {
              minion.takeDamage(damage);
              print('$attackType hit ${minion.definition.name} for $damage damage! '
                    'Minion health: ${minion.health.toStringAsFixed(1)}/${minion.maxHealth}');
            }
          }
          break;
      }

      return true;
    }

    return false;
  }

  /// Checks collision with player and applies damage if hit
  ///
  /// Convenience function for attacks targeting the player.
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - collisionThreshold: Distance threshold (defaults to GameConfig value)
  ///
  /// Returns:
  /// - true if hit was registered, false otherwise
  static bool checkAndDamagePlayer(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    if (gameState.playerTransform == null || gameState.playerHealth <= 0) {
      return false;
    }

    return checkAndApplyDamage(
      gameState,
      attackerPosition: attackerPosition,
      targetPosition: gameState.playerTransform!.position,
      collisionThreshold: collisionThreshold ?? GameConfig.collisionThreshold,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      targetType: DamageTarget.player,
    );
  }

  /// Checks collision with monster and applies damage if hit
  ///
  /// Convenience function for attacks targeting the monster.
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - collisionThreshold: Distance threshold (defaults to GameConfig value)
  ///
  /// Returns:
  /// - true if hit was registered, false otherwise
  static bool checkAndDamageMonster(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    if (gameState.monsterTransform == null || gameState.monsterHealth <= 0) {
      return false;
    }

    return checkAndApplyDamage(
      gameState,
      attackerPosition: attackerPosition,
      targetPosition: gameState.monsterTransform!.position,
      collisionThreshold: collisionThreshold ?? GameConfig.collisionThreshold,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      targetType: DamageTarget.monster,
    );
  }

  /// Checks collision with all allies and applies damage to the first hit
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - collisionThreshold: Distance threshold (defaults to GameConfig value)
  ///
  /// Returns:
  /// - true if any ally was hit, false otherwise
  static bool checkAndDamageAllies(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    for (int i = 0; i < gameState.allies.length; i++) {
      final ally = gameState.allies[i];
      if (ally.health <= 0) continue; // Skip dead allies

      final hit = checkAndApplyDamage(
        gameState,
        attackerPosition: attackerPosition,
        targetPosition: ally.transform.position,
        collisionThreshold: collisionThreshold ?? GameConfig.collisionThreshold,
        damage: damage,
        attackType: attackType,
        impactColor: impactColor,
        impactSize: impactSize,
        targetType: DamageTarget.ally,
        allyIndex: i,
      );

      if (hit) return true;
    }

    return false;
  }

  /// Checks collision with player and all allies, applying damage to the first hit
  ///
  /// Used for monster AoE or projectile attacks that can hit any friendly unit.
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - collisionThreshold: Distance threshold (defaults to GameConfig value)
  ///
  /// Returns:
  /// - true if any target was hit, false otherwise
  static bool checkAndDamagePlayerOrAllies(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    // Check player first
    if (checkAndDamagePlayer(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
    )) {
      return true;
    }

    // Then check allies
    return checkAndDamageAllies(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
    );
  }

  /// Checks collision with all minions and applies damage to the first hit
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - collisionThreshold: Distance threshold (defaults to GameConfig value)
  ///
  /// Returns:
  /// - true if any minion was hit, false otherwise
  /// Minimum collision threshold for minions to ensure they can be hit
  static const double _minMinionCollisionThreshold = 0.8;

  static bool checkAndDamageMinions(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    for (final minion in gameState.aliveMinions) {
      // Use larger of: provided threshold, scale-based threshold, or minimum threshold
      // This ensures even small minions can be reliably hit
      final scaleBasedThreshold = minion.definition.effectiveScale * 0.8;
      final effectiveThreshold = collisionThreshold ??
          (scaleBasedThreshold > _minMinionCollisionThreshold
              ? scaleBasedThreshold
              : _minMinionCollisionThreshold);

      final hit = checkAndApplyDamage(
        gameState,
        attackerPosition: attackerPosition,
        targetPosition: minion.transform.position,
        collisionThreshold: effectiveThreshold,
        damage: damage,
        attackType: attackType,
        impactColor: impactColor,
        impactSize: impactSize,
        targetType: DamageTarget.minion,
        minionInstanceId: minion.instanceId,
      );

      if (hit) return true;
    }

    return false;
  }

  /// Checks collision with monster and all minions, applying damage to the first hit
  ///
  /// Used for player/ally attacks that should hit any enemy.
  ///
  /// Returns:
  /// - true if any enemy was hit, false otherwise
  static bool checkAndDamageEnemies(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    // Check boss monster first
    if (checkAndDamageMonster(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
    )) {
      return true;
    }

    // Then check minions
    return checkAndDamageMinions(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
    );
  }

  /// Damage a specific minion by instance ID (for targeted attacks)
  static bool damageMinion(
    GameState gameState, {
    required String minionInstanceId,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
  }) {
    final minion = gameState.minions.where(
      (m) => m.instanceId == minionInstanceId && m.isAlive
    ).firstOrNull;

    if (minion == null) return false;

    createImpactEffect(
      gameState,
      position: minion.transform.position,
      color: impactColor,
      size: impactSize,
    );

    minion.takeDamage(damage);
    print('$attackType hit ${minion.definition.name} for $damage damage! '
          'Health: ${minion.health.toStringAsFixed(1)}/${minion.maxHealth}');

    return true;
  }
}
