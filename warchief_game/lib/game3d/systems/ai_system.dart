import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../state/abilities_config.dart';
import '../../models/ally.dart';
import '../../models/ai_chat_message.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/projectile.dart';
import 'combat_system.dart';

/// AI System - Handles all NPC AI logic
///
/// Manages AI for both enemies and allies including:
/// - Monster AI (decision making, movement, ability usage)
/// - Ally AI (decision making, execution)
/// - Projectile updates (monster and ally projectiles)
/// - AI cooldown management
class AISystem {
  AISystem._(); // Private constructor to prevent instantiation

  /// Updates all AI systems
  ///
  /// This is the main entry point for the AI system. It updates cooldowns,
  /// monster AI, ally AI, and projectile movements.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  /// - logMonsterAI: Callback function to log monster AI decisions
  /// - activateMonsterAbility1: Callback to activate monster ability 1
  /// - activateMonsterAbility2: Callback to activate monster ability 2
  /// - activateMonsterAbility3: Callback to activate monster ability 3
  static void update(
    double dt,
    GameState gameState, {
    required void Function(String, {required bool isInput}) logMonsterAI,
    required void Function() activateMonsterAbility1,
    required void Function() activateMonsterAbility2,
    required void Function() activateMonsterAbility3,
  }) {
    updateCooldowns(dt, gameState);
    updateMonsterAI(dt, gameState, logMonsterAI, activateMonsterAbility1, activateMonsterAbility2, activateMonsterAbility3);
    updateMonsterSword(dt, gameState);
    updateAllyAI(dt, gameState);
    updateMonsterProjectiles(dt, gameState);
    updateAllyProjectiles(dt, gameState);
  }

  /// Updates all ability cooldowns for monster and allies
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateCooldowns(double dt, GameState gameState) {
    // Update monster ability cooldowns
    if (gameState.monsterAbility1Cooldown > 0) gameState.monsterAbility1Cooldown -= dt;
    if (gameState.monsterAbility2Cooldown > 0) gameState.monsterAbility2Cooldown -= dt;
    if (gameState.monsterAbility3Cooldown > 0) gameState.monsterAbility3Cooldown -= dt;

    // Update ally cooldowns
    for (final ally in gameState.allies) {
      if (ally.abilityCooldown > 0) ally.abilityCooldown -= dt;
    }
  }

  // ==================== MONSTER AI ====================

  /// Updates monster AI (decision making, movement, ability usage)
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  /// - logMonsterAI: Callback function to log monster AI decisions
  /// - activateMonsterAbility1: Callback to activate monster ability 1
  /// - activateMonsterAbility2: Callback to activate monster ability 2
  /// - activateMonsterAbility3: Callback to activate monster ability 3
  static void updateMonsterAI(
    double dt,
    GameState gameState,
    void Function(String, {required bool isInput}) logMonsterAI,
    void Function() activateMonsterAbility1,
    void Function() activateMonsterAbility2,
    void Function() activateMonsterAbility3,
  ) {
    if (!gameState.monsterPaused &&
        gameState.monsterHealth > 0 &&
        gameState.monsterTransform != null &&
        gameState.playerTransform != null) {
      gameState.monsterAiTimer += dt;

      // AI thinks every 2 seconds
      if (gameState.monsterAiTimer >= gameState.monsterAiInterval) {
        gameState.monsterAiTimer = 0.0;

        // Calculate distance to player
        final distanceToPlayer = (gameState.monsterTransform!.position - gameState.playerTransform!.position).length;

        // Log AI input (game state)
        logMonsterAI('Health: ${gameState.monsterHealth.toStringAsFixed(0)} | Dist: ${distanceToPlayer.toStringAsFixed(1)}', isInput: true);

        // Always face the player
        final toPlayer = gameState.playerTransform!.position - gameState.monsterTransform!.position;
        gameState.monsterRotation = math.atan2(-toPlayer.x, -toPlayer.z) * (180 / math.pi);
        gameState.monsterDirectionIndicatorTransform?.rotation.y = gameState.monsterRotation;

        // Decision making
        String decision = _makeMonsterMovementDecision(distanceToPlayer, toPlayer, gameState);

        // Use abilities based on distance and cooldown
        decision = _makeMonsterAbilityDecision(
          distanceToPlayer,
          decision,
          gameState,
          activateMonsterAbility1,
          activateMonsterAbility2,
          activateMonsterAbility3,
        );

        // Log AI output (decision)
        logMonsterAI(decision, isInput: false);
      }
    }
  }

  /// Makes monster movement decision based on distance to player
  ///
  /// Parameters:
  /// - distanceToPlayer: Distance from monster to player
  /// - toPlayer: Vector from monster to player
  /// - gameState: Current game state
  ///
  /// Returns:
  /// - Decision string describing the movement action
  static String _makeMonsterMovementDecision(double distanceToPlayer, Vector3 toPlayer, GameState gameState) {
    String decision = '';
    if (distanceToPlayer > GameConfig.monsterMoveThresholdMax) {
      // Move toward player if too far
      final moveDirection = toPlayer.normalized();
      gameState.monsterTransform!.position += moveDirection * 0.5;
      decision = 'MOVE_FORWARD';
    } else if (distanceToPlayer < GameConfig.monsterMoveThresholdMin) {
      // Move away if too close
      final moveDirection = toPlayer.normalized();
      gameState.monsterTransform!.position -= moveDirection * 0.3;
      decision = 'RETREAT';
    } else {
      decision = 'HOLD';
    }
    return decision;
  }

  /// Makes monster ability decision and activates abilities
  ///
  /// Parameters:
  /// - distanceToPlayer: Distance from monster to player
  /// - decision: Current decision string
  /// - gameState: Current game state
  /// - activateMonsterAbility1: Callback to activate ability 1
  /// - activateMonsterAbility2: Callback to activate ability 2
  /// - activateMonsterAbility3: Callback to activate ability 3
  ///
  /// Returns:
  /// - Updated decision string with ability actions
  static String _makeMonsterAbilityDecision(
    double distanceToPlayer,
    String decision,
    GameState gameState,
    void Function() activateMonsterAbility1,
    void Function() activateMonsterAbility2,
    void Function() activateMonsterAbility3,
  ) {
    // Use abilities based on distance and cooldown
    if (distanceToPlayer < 5.0 && gameState.monsterAbility1Cooldown <= 0) {
      activateMonsterAbility1(); // Dark strike
      decision += ' + DARK_STRIKE';
    } else if (distanceToPlayer > 4.0 && distanceToPlayer < 12.0 && gameState.monsterAbility2Cooldown <= 0) {
      activateMonsterAbility2(); // Shadow bolt
      decision += ' + SHADOW_BOLT';
    } else if (gameState.monsterHealth < GameConfig.monsterHealThreshold && gameState.monsterAbility3Cooldown <= 0) {
      activateMonsterAbility3(); // Healing
      decision += ' + HEAL';
    }
    return decision;
  }

  // ==================== MONSTER SWORD ====================

  /// Updates monster sword animation and collision detection
  ///
  /// Handles the monster's melee sword swing, positioning, and damage
  /// to player and allies within range.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateMonsterSword(double dt, GameState gameState) {
    if (!gameState.monsterAbility1Active) return;
    if (gameState.monsterTransform == null || gameState.monsterSwordTransform == null) return;

    final darkStrike = AbilitiesConfig.monsterDarkStrike;
    gameState.monsterAbility1ActiveTime += dt;

    if (gameState.monsterAbility1ActiveTime >= darkStrike.duration) {
      // Sword swing finished
      gameState.monsterAbility1Active = false;
    } else {
      // Position sword in front of monster, rotating during swing
      final forward = Vector3(
        -math.sin(gameState.monsterRotation * (math.pi / 180)),
        0,
        -math.cos(gameState.monsterRotation * (math.pi / 180)),
      );
      final swingProgress = gameState.monsterAbility1ActiveTime / darkStrike.duration;
      final swingAngle = swingProgress * 180; // 0 to 180 degrees

      gameState.monsterSwordTransform!.position = gameState.monsterTransform!.position + forward * 1.2;
      gameState.monsterSwordTransform!.position.y = gameState.monsterTransform!.position.y;
      gameState.monsterSwordTransform!.rotation.y = gameState.monsterRotation + swingAngle - 90;

      // Check collision with player and allies (only once per swing)
      if (!gameState.monsterAbility1HitRegistered) {
        final swordTipPosition = gameState.monsterTransform!.position + forward * darkStrike.range;

        final hitRegistered = CombatSystem.checkAndDamagePlayerOrAllies(
          gameState,
          attackerPosition: swordTipPosition,
          damage: darkStrike.damage,
          attackType: darkStrike.name,
          impactColor: darkStrike.impactColor,
          impactSize: darkStrike.impactSize,
        );

        if (hitRegistered) {
          gameState.monsterAbility1HitRegistered = true;
        }
      }
    }
  }

  // ==================== ALLY AI ====================

  /// Updates ally AI (decision making and execution)
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateAllyAI(double dt, GameState gameState) {
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue; // Skip dead allies

      ally.aiTimer += dt;

      // AI thinks every 3 seconds
      if (ally.aiTimer >= ally.aiInterval) {
        ally.aiTimer = 0.0;

        if (gameState.playerTransform != null && gameState.monsterTransform != null) {
          // Calculate distances
          final distanceToPlayer = (ally.transform.position - gameState.playerTransform!.position).length;
          final distanceToMonster = (ally.transform.position - gameState.monsterTransform!.position).length;

          // Fallback rule-based AI (when Ollama unavailable)
          String decision = makeAllyDecision(ally, distanceToPlayer, distanceToMonster, gameState);

          // Execute decision
          executeAllyDecision(ally, decision, gameState);
        }
      }

      // Update ally's direction indicator to face monster
      if (ally.directionIndicatorTransform != null && gameState.monsterTransform != null) {
        final toMonster = gameState.monsterTransform!.position - ally.transform.position;
        ally.rotation = math.atan2(-toMonster.x, -toMonster.z) * (180 / math.pi);
        ally.directionIndicatorTransform!.rotation.y = ally.rotation;
      }
    }
  }

  /// Makes AI decision for an ally (fallback rule-based AI)
  ///
  /// Parameters:
  /// - ally: The ally to make a decision for
  /// - distanceToPlayer: Distance from ally to player
  /// - distanceToMonster: Distance from ally to monster
  /// - gameState: Current game state
  ///
  /// Returns:
  /// - Decision string (e.g., "ATTACK", "MOVE_TO_MONSTER", "HEAL")
  static String makeAllyDecision(Ally ally, double distanceToPlayer, double distanceToMonster, GameState gameState) {
    // Simple rule-based AI
    if (ally.health < 20 && ally.abilityIndex == 2) {
      return 'HEAL'; // Heal if low health and has heal ability
    } else if (distanceToMonster > GameConfig.allyMoveThreshold) {
      return 'MOVE_TO_MONSTER'; // Move closer to monster
    } else if (ally.abilityCooldown <= 0) {
      return 'ATTACK'; // Attack if close enough and ability ready
    } else {
      return 'HOLD'; // Wait for cooldown
    }
  }

  /// Executes ally's AI decision
  ///
  /// Parameters:
  /// - ally: The ally executing the decision
  /// - decision: The decision to execute
  /// - gameState: Current game state
  static void executeAllyDecision(Ally ally, String decision, GameState gameState) {
    if (decision == 'MOVE_TO_MONSTER' && gameState.monsterTransform != null) {
      // Move toward monster
      final toMonster = gameState.monsterTransform!.position - ally.transform.position;
      final moveDirection = toMonster.normalized();
      ally.transform.position += moveDirection * 0.3;
      print('Ally moving toward monster');
    } else if (decision == 'ATTACK' && ally.abilityCooldown <= 0) {
      // Use ability based on ally's ability index
      final ability = AbilitiesConfig.getAllyAbility(ally.abilityIndex);
      ally.abilityCooldown = ally.abilityCooldownMax;

      if (ally.abilityIndex == 0) {
        // Sword (melee attack - collision handled elsewhere)
        print('Ally attacks with ${ability.name}!');
      } else if (ally.abilityIndex == 1) {
        // Fireball (ranged projectile)
        final toMonster = gameState.monsterTransform!.position - ally.transform.position;
        final direction = toMonster.normalized();

        final fireballMesh = Mesh.cube(
          size: ability.projectileSize,
          color: ability.color,
        );
        final fireballTransform = Transform3d(
          position: ally.transform.position.clone() + direction * 0.5,
          scale: Vector3(1, 1, 1),
        );

        ally.projectiles.add(
          Projectile(
            mesh: fireballMesh,
            transform: fireballTransform,
            velocity: direction * ability.projectileSpeed,
          ),
        );
        print('Ally casts ${ability.name}!');
      } else if (ally.abilityIndex == 2) {
        // Heal (restore ally's own health)
        if (ally.health < ally.maxHealth) {
          ally.health = math.min(ally.maxHealth, ally.health + ability.healAmount);
        }
        print('Ally uses ${ability.name}! Health: ${ally.health}/${ally.maxHealth}');
      }
    } else if (decision == 'HEAL' && ally.abilityCooldown <= 0) {
      // Execute heal
      final healAbility = AbilitiesConfig.allyHeal;
      ally.abilityCooldown = ally.abilityCooldownMax;
      ally.health = math.min(ally.maxHealth, ally.health + healAbility.healAmount);
      print('Ally uses ${healAbility.name}! Health: ${ally.health}/${ally.maxHealth}');
    }
  }

  // ==================== PROJECTILE UPDATES ====================

  /// Updates monster projectiles
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateMonsterProjectiles(double dt, GameState gameState) {
    final shadowBolt = AbilitiesConfig.monsterShadowBolt;

    gameState.monsterProjectiles.removeWhere((projectile) {
      projectile.transform.position += projectile.velocity * dt;
      projectile.lifetime -= dt;

      // Check collision with player and allies using unified combat system
      final hitRegistered = CombatSystem.checkAndDamagePlayerOrAllies(
        gameState,
        attackerPosition: projectile.transform.position,
        damage: shadowBolt.damage,
        attackType: shadowBolt.name,
        impactColor: shadowBolt.impactColor,
        impactSize: shadowBolt.impactSize,
      );

      if (hitRegistered) return true;

      return projectile.lifetime <= 0;
    });
  }

  /// Updates ally projectiles
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateAllyProjectiles(double dt, GameState gameState) {
    final allyFireball = AbilitiesConfig.allyFireball;

    for (final ally in gameState.allies) {
      ally.projectiles.removeWhere((projectile) {
        projectile.transform.position += projectile.velocity * dt;
        projectile.lifetime -= dt;

        // Check collision with monster using unified combat system
        final hitRegistered = CombatSystem.checkAndDamageMonster(
          gameState,
          attackerPosition: projectile.transform.position,
          damage: allyFireball.damage,
          attackType: allyFireball.name,
          impactColor: allyFireball.impactColor,
          impactSize: allyFireball.impactSize,
        );

        if (hitRegistered) return true;

        return projectile.lifetime <= 0;
      });
    }
  }

  // ==================== UTILITY FUNCTIONS ====================

  /// Adds a message to the Monster AI chat log
  ///
  /// Parameters:
  /// - gameState: Current game state
  /// - text: Message text
  /// - isInput: Whether this is input (true) or output (false)
  static void logMonsterAI(GameState gameState, String text, {required bool isInput}) {
    if (text.isNotEmpty) {
      gameState.monsterAIChat.add(AIChatMessage(
        text: text,
        isInput: isInput,
        timestamp: DateTime.now(),
      ));
      // Keep chat log from growing too large
      if (gameState.monsterAIChat.length > 50) {
        gameState.monsterAIChat.removeAt(0);
      }
    }
  }
}
