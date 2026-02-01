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
import '../ai/mcp_tools.dart';
import '../utils/bezier_path.dart';

/// AI System - Handles all NPC AI logic
///
/// Manages AI for both enemies and allies including:
/// - Monster AI (decision making, movement, ability usage)
/// - Ally AI (decision making, execution)
/// - Projectile updates (monster and ally projectiles)
/// - AI cooldown management
/// - Terrain-aware unit positioning
class AISystem {
  AISystem._(); // Private constructor to prevent instantiation

  /// Get terrain height at position, with fallback to groundLevel
  static double _getTerrainHeight(GameState gameState, double x, double z) {
    if (gameState.infiniteTerrainManager != null) {
      return gameState.infiniteTerrainManager!.getTerrainHeight(x, z);
    }
    return gameState.groundLevel;
  }

  /// Apply terrain height to a unit's Y position
  static void _applyTerrainHeight(GameState gameState, Transform3d transform) {
    final terrainHeight = _getTerrainHeight(
      gameState,
      transform.position.x,
      transform.position.z,
    );
    transform.position.y = terrainHeight;
  }

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
    updateMonsterMovement(dt, gameState); // Smooth continuous movement
    updateMonsterAI(dt, gameState, logMonsterAI, activateMonsterAbility1, activateMonsterAbility2, activateMonsterAbility3);
    updateMonsterSword(dt, gameState);
    updateAllyMovement(dt, gameState); // Smooth ally movement
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

  // ==================== MONSTER MOVEMENT ====================

  /// Updates monster movement along current path (every frame)
  ///
  /// This provides smooth continuous movement instead of jerky AI-interval updates.
  /// Monster Y position is set to terrain height for proper terrain following.
  static void updateMonsterMovement(double dt, GameState gameState) {
    if (gameState.monsterTransform == null || gameState.monsterHealth <= 0) return;

    // Follow current path if one exists
    if (gameState.monsterCurrentPath != null) {
      final distance = gameState.monsterMoveSpeed * dt;
      final newPos = gameState.monsterCurrentPath!.advance(distance);

      if (newPos != null) {
        // Update horizontal position from path
        gameState.monsterTransform!.position.x = newPos.x;
        gameState.monsterTransform!.position.z = newPos.z;

        // Update rotation to face movement direction
        final tangent = gameState.monsterCurrentPath!.getTangentAt(
          gameState.monsterCurrentPath!.progress
        );
        gameState.monsterRotation = math.atan2(-tangent.x, -tangent.z) * (180 / math.pi);
        gameState.monsterDirectionIndicatorTransform?.rotation.y = gameState.monsterRotation;
      } else {
        // Path completed
        gameState.monsterCurrentPath = null;
      }
    }

    // Set monster Y to terrain height (terrain following)
    if (gameState.monsterTransform != null) {
      _applyTerrainHeight(gameState, gameState.monsterTransform!);
    }
  }

  // ==================== ALLY MOVEMENT ====================

  /// Updates ally movement along current paths (every frame)
  ///
  /// Ally Y position is set to terrain height for proper terrain following.
  static void updateAllyMovement(double dt, GameState gameState) {
    if (gameState.playerTransform == null) return;

    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;

      // Handle different movement modes
      switch (ally.movementMode) {
        case AllyMovementMode.stationary:
          // Still apply terrain height even when stationary
          _applyTerrainHeight(gameState, ally.transform);
          break;

        case AllyMovementMode.followPlayer:
          _updateAllyFollowMode(dt, ally, gameState);
          break;

        case AllyMovementMode.commanded:
        case AllyMovementMode.tactical:
          // Follow current path if exists
          if (ally.currentPath != null) {
            final distance = ally.moveSpeed * dt;
            final newPos = ally.currentPath!.advance(distance);

            if (newPos != null) {
              ally.transform.position.x = newPos.x;
              ally.transform.position.z = newPos.z;
              ally.isMoving = true;

              // Update rotation to face movement direction
              final tangent = ally.currentPath!.getTangentAt(ally.currentPath!.progress);
              ally.rotation = math.atan2(-tangent.x, -tangent.z) * (180 / math.pi);
              ally.directionIndicatorTransform?.rotation.y = ally.rotation;
            } else {
              // Path completed
              ally.currentPath = null;
              ally.isMoving = false;
            }
          }
          // Apply terrain height
          _applyTerrainHeight(gameState, ally.transform);
          break;
      }
    }
  }

  /// Helper to update ally in follow mode
  ///
  /// Ally Y position is set to terrain height for proper terrain following.
  static void _updateAllyFollowMode(double dt, Ally ally, GameState gameState) {
    final playerPos = gameState.playerTransform!.position;
    final distanceToPlayer = (ally.transform.position - playerPos).length;
    final playerVelocity = gameState.playerMovementTracker.getVelocity();
    final playerIsMoving = playerVelocity.length > 0.1;

    // If player is moving and ally is too far, create follow path
    if (playerIsMoving && distanceToPlayer > ally.followBufferDistance * 1.3) {
      // Calculate target position at buffer distance from player
      final toAlly = (ally.transform.position - playerPos).normalized();
      final targetPos = playerPos + toAlly * ally.followBufferDistance;

      // Create smooth path to target
      ally.currentPath = BezierPath.interception(
        start: ally.transform.position,
        target: targetPos,
        velocity: null, // Ally's current velocity could be tracked
      );
      ally.isMoving = true;
    }

    // If player stopped and ally is close enough, stop and re-randomize buffer
    if (!playerIsMoving && distanceToPlayer <= ally.followBufferDistance * 1.2) {
      ally.currentPath = null;
      ally.isMoving = false;
      // Re-randomize buffer distance for next movement (3-5 units)
      ally.followBufferDistance = math.Random().nextDouble() * 2.0 + 3.0;
    }

    // Continue moving along existing path if one exists
    if (ally.currentPath != null) {
      final distance = ally.moveSpeed * dt;
      final newPos = ally.currentPath!.advance(distance);

      if (newPos != null) {
        ally.transform.position.x = newPos.x;
        ally.transform.position.z = newPos.z;

        // Update rotation
        final tangent = ally.currentPath!.getTangentAt(ally.currentPath!.progress);
        ally.rotation = math.atan2(-tangent.x, -tangent.z) * (180 / math.pi);
        ally.directionIndicatorTransform?.rotation.y = ally.rotation;
      } else {
        ally.currentPath = null;
        ally.isMoving = false;
      }
    }

    // Apply terrain height
    _applyTerrainHeight(gameState, ally.transform);
  }

  // ==================== MONSTER AI ====================

  /// Updates monster AI (decision making using MCP tools)
  ///
  /// Uses layered decision-making:
  /// - Fast tactical tools every frame for threat response
  /// - Strategic planning on AI interval for movement/combat strategy
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

      // Create AI context
      final context = _createMonsterAIContext(gameState);

      // Fast tactical assessment (every frame for immediate threats)
      final threatResponse = MCPTools.assessThreat(context);
      if (threatResponse.action == 'RETREAT_URGENT' && threatResponse.confidence > 0.8) {
        // Emergency retreat - create immediate escape path
        final awayFromPlayer = (gameState.monsterTransform!.position - gameState.playerTransform!.position).normalized();
        final escapeTarget = gameState.monsterTransform!.position + awayFromPlayer * 5.0;
        gameState.monsterCurrentPath = BezierPath.interception(
          start: gameState.monsterTransform!.position,
          target: escapeTarget,
          velocity: null,
        );
      }

      gameState.monsterAiTimer += dt;

      // Strategic planning on AI interval (every 2 seconds)
      if (gameState.monsterAiTimer >= gameState.monsterAiInterval) {
        gameState.monsterAiTimer = 0.0;

        final distanceToPlayer = context.distanceToPlayer;

        // Log AI input
        logMonsterAI('Health: ${context.selfHealth.toStringAsFixed(0)} | Dist: ${distanceToPlayer.toStringAsFixed(1)} | Vel: ${context.playerVelocity?.length.toStringAsFixed(1) ?? "0"}', isInput: true);

        // Get strategic plan
        final strategy = MCPTools.planCombatStrategy(context);
        gameState.monsterCurrentStrategy = strategy.action;

        // Create movement path based on strategy
        _executeMonsterMovementStrategy(strategy, gameState, context);

        // Select and execute abilities
        final abilityDecision = MCPTools.selectQuickAbility(context);
        String decision = _executeMonsterAbilities(
          abilityDecision,
          gameState,
          activateMonsterAbility1,
          activateMonsterAbility2,
          activateMonsterAbility3,
        );

        // Log decision
        logMonsterAI('${strategy.action}: $decision (${strategy.reasoning})', isInput: false);
      }
    }
  }

  /// Creates AI context from game state
  static AIContext _createMonsterAIContext(GameState gameState) {
    final distanceToPlayer = (gameState.monsterTransform!.position - gameState.playerTransform!.position).length;
    final playerVelocity = gameState.playerMovementTracker.getVelocity();

    // Build ally context list
    final allyContexts = gameState.allies.map((ally) {
      return AllyContext(
        position: ally.transform.position,
        health: ally.health,
        distanceToSelf: (ally.transform.position - gameState.monsterTransform!.position).length,
      );
    }).toList();

    return AIContext(
      selfPosition: gameState.monsterTransform!.position,
      playerPosition: gameState.playerTransform!.position,
      playerVelocity: playerVelocity,
      distanceToPlayer: distanceToPlayer,
      selfHealth: gameState.monsterHealth,
      selfMaxHealth: gameState.monsterMaxHealth,
      playerHealth: gameState.playerHealth,
      allies: allyContexts,
      abilityCooldowns: {
        'ability1': gameState.monsterAbility1Cooldown,
        'ability2': gameState.monsterAbility2Cooldown,
        'ability3': gameState.monsterAbility3Cooldown,
      },
    );
  }

  /// Executes movement strategy using Bezier paths
  static void _executeMonsterMovementStrategy(
    MCPToolResponse strategy,
    GameState gameState,
    AIContext context,
  ) {
    final playerPos = gameState.playerTransform!.position;
    final monsterPos = gameState.monsterTransform!.position;
    final playerVelocity = context.playerVelocity ?? Vector3.zero();

    // Determine target position based on strategy
    Vector3 targetPos;

    if (strategy.action == 'AGGRESSIVE_STRATEGY') {
      // Intercept player's predicted position
      final predictedPlayerPos = gameState.playerMovementTracker.predictPosition(1.5);
      targetPos = predictedPlayerPos;
    } else if (strategy.action == 'DEFENSIVE_STRATEGY') {
      // Maintain distance
      final toMonster = (monsterPos - playerPos).normalized();
      targetPos = playerPos + toMonster * 8.0; // Stay at 8 units
    } else {
      // Balanced - optimal range from strategy parameters
      final optimalRange = (strategy.parameters['preferredRange'] == 'close') ? 4.0 :
                          (strategy.parameters['preferredRange'] == 'medium') ? 6.0 : 8.0;
      final toMonster = (monsterPos - playerPos).normalized();
      targetPos = playerPos + toMonster * optimalRange;
    }

    // Create smooth intercept path
    gameState.monsterCurrentPath = MCPTools.calculateInterceptPath(
      currentPosition: monsterPos,
      targetPosition: targetPos,
      targetVelocity: playerVelocity,
      currentVelocity: null,
      interceptorSpeed: gameState.monsterMoveSpeed,
    );
  }

  /// Executes ability decisions
  static String _executeMonsterAbilities(
    MCPToolResponse abilityDecision,
    GameState gameState,
    void Function() activateAbility1,
    void Function() activateAbility2,
    void Function() activateAbility3,
  ) {
    if (abilityDecision.action == 'USE_ABILITY') {
      final ability = abilityDecision.parameters['ability'];
      if (ability == 'ability1') {
        activateAbility1();
        return 'Using Melee Attack';
      } else if (ability == 'ability2') {
        activateAbility2();
        return 'Casting Shadow Bolt';
      } else if (ability == 'ability3') {
        activateAbility3();
        return 'Using Ability 3';
      }
    }
    return abilityDecision.action;
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
      // Move toward monster (horizontal only, terrain height applied separately)
      final toMonster = gameState.monsterTransform!.position - ally.transform.position;
      toMonster.y = 0; // Only move horizontally
      final moveDirection = toMonster.normalized();
      ally.transform.position.x += moveDirection.x * 0.3;
      ally.transform.position.z += moveDirection.z * 0.3;
      // Apply terrain height
      _applyTerrainHeight(gameState, ally.transform);
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
        final oldHealth = ally.health;
        if (ally.health < ally.maxHealth) {
          ally.health = math.min(ally.maxHealth, ally.health + ability.healAmount);
        }
        final healedAmount = ally.health - oldHealth;
        print('[HEAL] Ally uses ${ability.name}! Restored ${healedAmount.toStringAsFixed(1)} HP (${ally.health.toStringAsFixed(0)}/${ally.maxHealth})');
      }
    } else if (decision == 'HEAL' && ally.abilityCooldown <= 0) {
      // Execute heal
      final healAbility = AbilitiesConfig.allyHeal;
      ally.abilityCooldown = ally.abilityCooldownMax;
      final oldHealth = ally.health;
      ally.health = math.min(ally.maxHealth, ally.health + healAbility.healAmount);
      final healedAmount = ally.health - oldHealth;
      print('[HEAL] Ally uses ${healAbility.name}! Restored ${healedAmount.toStringAsFixed(1)} HP (${ally.health.toStringAsFixed(0)}/${ally.maxHealth})');
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
