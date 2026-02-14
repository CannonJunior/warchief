import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../state/abilities_config.dart';
import '../state/wind_state.dart';
import '../../models/ally.dart';
import '../../models/ai_chat_message.dart';
import '../../models/monster.dart';
import '../../models/monster_ontology.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/projectile.dart';
import 'combat_system.dart';
import '../ai/mcp_tools.dart';
import '../ai/ally_behavior_tree.dart';
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

  /// Small buffer to ensure units are visually above terrain surface
  static const double _terrainBuffer = 0.15;

  /// Apply terrain height to a unit's Y position
  /// The unitSize parameter is the size of the cube mesh (units are centered)
  static void _applyTerrainHeight(GameState gameState, Transform3d transform, {double unitSize = 0.8}) {
    final terrainHeight = _getTerrainHeight(
      gameState,
      transform.position.x,
      transform.position.z,
    );
    // Add half the unit size + buffer so the bottom of the mesh sits above terrain
    transform.position.y = terrainHeight + unitSize / 2 + _terrainBuffer;
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
    updateMinionMovement(dt, gameState); // Minion movement
    updateMinionAI(dt, gameState); // Minion AI
    updateMonsterProjectiles(dt, gameState);
    updateAllyProjectiles(dt, gameState);
    updateMinionProjectiles(dt, gameState); // Minion projectiles
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
      _applyTerrainHeight(gameState, gameState.monsterTransform!, unitSize: GameConfig.monsterSize);
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
      // Skip the active player-controlled ally
      if (!gameState.isWarchiefActive && ally == gameState.activeAlly) continue;

      const double allySize = 0.8; // Ally mesh size

      // Handle different movement modes
      switch (ally.movementMode) {
        case AllyMovementMode.stationary:
          // Still apply terrain height even when stationary
          _applyTerrainHeight(gameState, ally.transform, unitSize: allySize);
          break;

        case AllyMovementMode.followPlayer:
          _updateAllyFollowMode(dt, ally, gameState);
          break;

        case AllyMovementMode.commanded:
        case AllyMovementMode.tactical:
          // Follow current path if exists
          if (ally.currentPath != null) {
            // Apply wind modifier to ally movement speed
            double allySpeed = ally.moveSpeed;
            if (globalWindState != null && ally.currentPath!.progress < 1.0) {
              final tangent = ally.currentPath!.getTangentAt(ally.currentPath!.progress);
              final windMod = globalWindState!.getMovementModifier(tangent.x, tangent.z);
              allySpeed *= windMod;
            }
            final distance = allySpeed * dt;
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
          _applyTerrainHeight(gameState, ally.transform, unitSize: allySize);
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
    // Reduced from 1.3x to 1.1x for more responsive following
    if (playerIsMoving && distanceToPlayer > ally.followBufferDistance * 1.1) {
      // Calculate target position - predict where player will be
      final predictedPlayerPos = playerPos + playerVelocity * 0.5; // 0.5s prediction
      final toAlly = (ally.transform.position - predictedPlayerPos).normalized();
      final targetPos = predictedPlayerPos + toAlly * ally.followBufferDistance;

      // Create smooth path to target
      ally.currentPath = BezierPath.interception(
        start: ally.transform.position,
        target: targetPos,
        velocity: playerVelocity, // Use player velocity for better interception
      );
      ally.isMoving = true;
    }

    // If ally is very far from player (>2x buffer), immediately start following
    if (distanceToPlayer > ally.followBufferDistance * 2.0 && ally.currentPath == null) {
      final toPlayer = (playerPos - ally.transform.position).normalized();
      final targetPos = playerPos - toPlayer * ally.followBufferDistance;
      ally.currentPath = BezierPath.interception(
        start: ally.transform.position,
        target: targetPos,
        velocity: null,
      );
      ally.isMoving = true;
    }

    // If player stopped and ally is close enough, stop and re-randomize buffer
    if (!playerIsMoving && distanceToPlayer <= ally.followBufferDistance * 1.1) {
      ally.currentPath = null;
      ally.isMoving = false;
      // Re-randomize buffer distance for next movement (3-5 units)
      ally.followBufferDistance = math.Random().nextDouble() * 2.0 + 3.0;
    }

    // Continue moving along existing path if one exists
    if (ally.currentPath != null) {
      // Apply wind modifier to follow movement speed
      double followSpeed = ally.moveSpeed;
      if (globalWindState != null && ally.currentPath!.progress < 1.0) {
        final tangent = ally.currentPath!.getTangentAt(ally.currentPath!.progress);
        final windMod = globalWindState!.getMovementModifier(tangent.x, tangent.z);
        followSpeed *= windMod;
      }
      final distance = followSpeed * dt;
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

    // Apply terrain height (ally size is 0.8)
    _applyTerrainHeight(gameState, ally.transform, unitSize: 0.8);
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

  /// Updates ally AI using behavior tree (decision making and execution)
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateAllyAI(double dt, GameState gameState) {
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue; // Skip dead allies
      // Skip the active player-controlled ally
      if (!gameState.isWarchiefActive && ally == gameState.activeAlly) continue;

      ally.aiTimer += dt;

      // AI thinks on interval (reduced to 1 second for responsiveness)
      if (ally.aiTimer >= ally.aiInterval) {
        ally.aiTimer = 0.0;

        if (gameState.playerTransform != null) {
          // Use behavior tree for decision making
          AllyBehaviorEvaluator.evaluate(ally, gameState);
        }
      }

      // Update ally's direction indicator based on current state
      // Only auto-face monster if in combat (not following player)
      if (ally.directionIndicatorTransform != null) {
        if (ally.movementMode == AllyMovementMode.tactical &&
            gameState.monsterTransform != null &&
            gameState.monsterHealth > 0) {
          // In combat - face monster
          final toMonster = gameState.monsterTransform!.position - ally.transform.position;
          ally.rotation = math.atan2(-toMonster.x, -toMonster.z) * (180 / math.pi);
        }
        // Otherwise rotation is set by movement direction in updateAllyMovement
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
      // Apply terrain height (ally size is 0.8)
      _applyTerrainHeight(gameState, ally.transform, unitSize: 0.8);
      print('Ally moving toward monster');
    } else if (decision == 'ATTACK' && ally.abilityCooldown <= 0) {
      // Use ability based on ally's ability index
      final ability = AbilitiesConfig.getAllyAbility(ally.abilityIndex);
      ally.abilityCooldown = ally.abilityCooldownMax;

      if (ally.abilityIndex == 0) {
        // Sword (melee attack with collision detection)
        if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
          // Calculate attack direction toward monster
          final toMonster = gameState.monsterTransform!.position - ally.transform.position;
          final direction = toMonster.normalized();

          // Attack position is in front of ally at sword range
          final attackPosition = ally.transform.position + direction * ability.range;

          // Check collision and apply damage
          final hitRegistered = CombatSystem.checkAndDamageMonster(
            gameState,
            attackerPosition: attackPosition,
            damage: ability.damage,
            attackType: ability.name,
            impactColor: ability.impactColor,
            impactSize: ability.impactSize,
          );

          if (hitRegistered) {
            print('Ally ${ability.name} hit monster for ${ability.damage} damage!');
          } else {
            print('Ally ${ability.name} missed (out of range)');
          }
        }
      } else if (ally.abilityIndex == 1) {
        // Fireball (ranged projectile with lead targeting)
        if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
          final monsterPos = gameState.monsterTransform!.position;
          final allyPos = ally.transform.position;

          // Calculate distance and travel time
          final distanceToMonster = (monsterPos - allyPos).length;
          final travelTime = distanceToMonster / ability.projectileSpeed;

          // Predict monster position based on current movement path
          Vector3 predictedPos = monsterPos.clone();
          if (gameState.monsterCurrentPath != null) {
            // Monster is moving - lead the target
            final tangent = gameState.monsterCurrentPath!.getTangentAt(
              gameState.monsterCurrentPath!.progress
            );
            final monsterVelocity = tangent * gameState.monsterMoveSpeed;
            predictedPos = monsterPos + monsterVelocity * travelTime * 0.7; // 70% lead
          }

          // Aim at predicted position
          final toTarget = predictedPos - allyPos;
          final direction = toTarget.normalized();

          final fireballMesh = Mesh.cube(
            size: ability.projectileSize,
            color: ability.color,
          );
          final fireballTransform = Transform3d(
            position: allyPos.clone() + direction * 0.5,
            scale: Vector3(1, 1, 1),
          );

          ally.projectiles.add(
            Projectile(
              mesh: fireballMesh,
              transform: fireballTransform,
              velocity: direction * ability.projectileSpeed,
            ),
          );
          print('Ally casts ${ability.name}! (leading target)');
        }
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
      // Apply wind force to projectile velocity
      if (globalWindState != null) {
        final windForce = globalWindState!.getProjectileForce();
        projectile.velocity.x += windForce[0] * dt;
        projectile.velocity.z += windForce[1] * dt;
      }
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
        // Apply wind force to ally projectile velocity
        if (globalWindState != null) {
          final windForce = globalWindState!.getProjectileForce();
          projectile.velocity.x += windForce[0] * dt;
          projectile.velocity.z += windForce[1] * dt;
        }
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

  // ==================== MINION AI ====================

  /// Updates minion movement toward their targets
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateMinionMovement(double dt, GameState gameState) {
    if (gameState.playerTransform == null) return;

    for (final minion in gameState.aliveMinions) {
      // Move toward target position if set
      if (minion.targetPosition != null) {
        final toTarget = minion.targetPosition! - minion.transform.position;
        toTarget.y = 0; // Horizontal movement only
        final distance = toTarget.length;

        if (distance > 0.5) {
          // Move toward target with wind modifier
          final direction = toTarget.normalized();
          double minionSpeed = minion.definition.moveSpeed;
          if (globalWindState != null) {
            final windMod = globalWindState!.getMovementModifier(direction.x, direction.z);
            minionSpeed *= windMod;
          }
          final moveAmount = minionSpeed * dt;
          minion.transform.position.x += direction.x * moveAmount;
          minion.transform.position.z += direction.z * moveAmount;

          // Update rotation to face movement direction
          minion.rotation = math.atan2(-direction.x, -direction.z) * (180 / math.pi);
          if (minion.directionIndicatorTransform != null) {
            minion.directionIndicatorTransform!.rotation.y = minion.rotation + 180;
          }
        } else {
          // Reached target
          minion.targetPosition = null;
        }
      }

      // Apply terrain height (minion size varies by definition)
      _applyTerrainHeight(gameState, minion.transform, unitSize: minion.definition.effectiveScale);

      // Update direction indicator position (on top of mesh)
      if (minion.directionIndicatorTransform != null) {
        minion.directionIndicatorTransform!.position.x = minion.transform.position.x;
        // Direction indicator sits on top of the mesh
        minion.directionIndicatorTransform!.position.y =
            minion.transform.position.y + minion.definition.effectiveScale / 2 + 0.1;
        minion.directionIndicatorTransform!.position.z = minion.transform.position.z;
      }
    }
  }

  /// Updates minion AI decisions
  ///
  /// Each minion archetype has different behavior:
  /// - DPS: Aggressive, attacks player/allies directly
  /// - Support: Stays back, buffs allies, debuffs enemies
  /// - Healer: Stays back, heals wounded allies
  /// - Tank: Engages player, protects other minions
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateMinionAI(double dt, GameState gameState) {
    if (gameState.playerTransform == null) return;

    final playerPos = gameState.playerTransform!.position;

    for (final minion in gameState.aliveMinions) {
      // Update timers
      minion.updateTimers(dt);

      // Skip if dead
      if (!minion.isAlive) continue;

      // AI decision on interval
      if (minion.aiTimer >= minion.aiInterval) {
        minion.aiTimer = 0.0;

        // Get distance to player
        final distanceToPlayer = minion.distanceTo(playerPos);

        // Check if in aggro range
        if (distanceToPlayer <= minion.definition.aggroRange) {
          minion.isInCombat = true;

          // Execute archetype-specific behavior
          switch (minion.definition.archetype) {
            case MonsterArchetype.dps:
              _executeDPSMinionAI(minion, gameState, playerPos);
              break;
            case MonsterArchetype.support:
              _executeSupportMinionAI(minion, gameState, playerPos);
              break;
            case MonsterArchetype.healer:
              _executeHealerMinionAI(minion, gameState, playerPos);
              break;
            case MonsterArchetype.tank:
              _executeTankMinionAI(minion, gameState, playerPos);
              break;
            case MonsterArchetype.boss:
              // Boss uses separate AI
              break;
          }
        } else {
          // Out of aggro range - idle
          minion.aiState = MonsterAIState.idle;
          minion.isInCombat = false;
        }

        // Check for flee condition
        if (minion.definition.canFlee && minion.isLowHealth) {
          _executeFleeAI(minion, gameState, playerPos);
        }
      }
    }
  }

  /// DPS minion AI - aggressive damage dealer
  static void _executeDPSMinionAI(Monster minion, GameState gameState, Vector3 playerPos) {
    final distanceToPlayer = minion.distanceTo(playerPos);

    // Find nearest target (player or ally)
    Vector3 targetPos = playerPos;
    double nearestDist = distanceToPlayer;
    String targetId = 'player'; // Track who we're targeting

    // Check if any ally is closer
    for (int i = 0; i < gameState.allies.length; i++) {
      final ally = gameState.allies[i];
      if (ally.health <= 0) continue;
      final dist = minion.distanceTo(ally.transform.position);
      if (dist < nearestDist) {
        nearestDist = dist;
        targetPos = ally.transform.position;
        targetId = 'ally_$i';
      }
    }

    // Update minion's target tracking
    minion.targetId = targetId;

    if (nearestDist <= minion.definition.attackRange) {
      // In range - attack
      minion.aiState = MonsterAIState.attacking;
      _minionAttack(minion, gameState, targetPos, 0); // Use primary ability
    } else {
      // Move toward target
      minion.aiState = MonsterAIState.pursuing;
      minion.targetPosition = targetPos.clone();
    }
  }

  /// Support minion AI - buffs allies, debuffs enemies
  static void _executeSupportMinionAI(Monster minion, GameState gameState, Vector3 playerPos) {
    final distanceToPlayer = minion.distanceTo(playerPos);

    // Default to targeting player
    minion.targetId = 'player';

    // Find wounded allies to buff
    Monster? woundedAlly;
    for (final ally in gameState.aliveMinions) {
      if (ally == minion) continue;
      if (ally.health < ally.maxHealth * 0.7) {
        woundedAlly = ally;
        break;
      }
    }

    // Priority 1: Buff allies if available
    if (woundedAlly != null && minion.isAbilityReady(0)) {
      minion.aiState = MonsterAIState.supporting;
      minion.targetId = woundedAlly.instanceId; // Targeting ally minion
      // Apply buff (Bloodlust - damage increase)
      woundedAlly.applyBuff(damageMultiplier: 1.5, duration: 8.0);
      minion.useAbility(0);
    }
    // Priority 2: Debuff player if in range
    else if (distanceToPlayer <= minion.definition.attackRange && minion.isAbilityReady(1)) {
      minion.aiState = MonsterAIState.casting;
      minion.targetId = 'player';
      // Apply debuff (Curse of Weakness)
      // For now, just deal minor damage
      _minionAttack(minion, gameState, playerPos, 2);
    }
    // Priority 3: Stay at medium range
    else {
      minion.aiState = MonsterAIState.supporting;
      final optimalRange = 7.0;
      if (distanceToPlayer < optimalRange - 1) {
        // Too close - back up
        final awayFromPlayer = (minion.transform.position - playerPos).normalized();
        minion.targetPosition = minion.transform.position + awayFromPlayer * 2.0;
      } else if (distanceToPlayer > optimalRange + 1) {
        // Too far - move closer
        final toPlayer = (playerPos - minion.transform.position).normalized();
        minion.targetPosition = minion.transform.position + toPlayer * 2.0;
      }
    }
  }

  /// Healer minion AI - heals wounded allies
  static void _executeHealerMinionAI(Monster minion, GameState gameState, Vector3 playerPos) {
    final distanceToPlayer = minion.distanceTo(playerPos);

    // Find most wounded ally
    Monster? mostWounded;
    double lowestHealthPercent = 1.0;

    for (final ally in gameState.aliveMinions) {
      if (ally == minion) continue;
      final healthPercent = ally.health / ally.maxHealth;
      if (healthPercent < lowestHealthPercent) {
        lowestHealthPercent = healthPercent;
        mostWounded = ally;
      }
    }

    // Also check boss monster
    final bossHealthPercent = gameState.monsterHealth / gameState.monsterMaxHealth;
    if (bossHealthPercent < lowestHealthPercent) {
      lowestHealthPercent = bossHealthPercent;
      mostWounded = null; // Signal to heal boss
    }

    // Priority 1: Heal most wounded ally
    if (lowestHealthPercent < 0.7 && minion.isAbilityReady(0)) {
      minion.aiState = MonsterAIState.supporting;
      if (mostWounded != null) {
        // Heal minion ally
        minion.targetId = mostWounded.instanceId; // Targeting ally minion
        final healAmount = minion.definition.abilities[0].healing;
        mostWounded.heal(healAmount);
        minion.useAbility(0);
      } else {
        // Heal boss
        minion.targetId = 'boss'; // Targeting boss
        final healAmount = minion.definition.abilities[0].healing;
        gameState.monsterHealth = math.min(
          gameState.monsterMaxHealth.toDouble(),
          gameState.monsterHealth + healAmount,
        );
        minion.useAbility(0);
      }
    }
    // Priority 2: Mass heal if multiple wounded
    else if (minion.isAbilityReady(2)) {
      int woundedCount = 0;
      for (final ally in gameState.aliveMinions) {
        if (ally.health < ally.maxHealth * 0.8) woundedCount++;
      }
      if (woundedCount >= 2) {
        minion.aiState = MonsterAIState.casting;
        minion.targetId = 'allies'; // Targeting group
        // Mass heal
        final healAmount = minion.definition.abilities[2].healing;
        for (final ally in gameState.aliveMinions) {
          ally.heal(healAmount);
        }
        // Also heal boss
        gameState.monsterHealth = math.min(
          gameState.monsterMaxHealth.toDouble(),
          gameState.monsterHealth + healAmount,
        );
        minion.useAbility(2);
      }
    }
    // Priority 3: Stay far from combat
    else {
      minion.aiState = MonsterAIState.supporting;
      minion.targetId = 'none'; // No target while retreating
      final safeRange = 10.0;
      if (distanceToPlayer < safeRange) {
        // Too close - run away
        final awayFromPlayer = (minion.transform.position - playerPos).normalized();
        minion.targetPosition = minion.transform.position + awayFromPlayer * 3.0;
      }
    }
  }

  /// Tank minion AI - engages player, protects allies
  static void _executeTankMinionAI(Monster minion, GameState gameState, Vector3 playerPos) {
    final distanceToPlayer = minion.distanceTo(playerPos);

    // Tank always targets player
    minion.targetId = 'player';

    // Priority 1: Taunt if off cooldown
    if (minion.isAbilityReady(1)) {
      minion.aiState = MonsterAIState.attacking;
      minion.useAbility(1);
      // Taunt doesn't deal damage, just draws attention
    }
    // Priority 2: Use defensive ability if taking damage
    else if (minion.isInCombat && minion.health < minion.maxHealth * 0.5 && minion.isAbilityReady(2)) {
      minion.aiState = MonsterAIState.casting;
      minion.applyBuff(damageReduction: 0.5, duration: 8.0);
      minion.useAbility(2);
    }
    // Priority 3: Attack if in range
    else if (distanceToPlayer <= minion.definition.attackRange) {
      if (minion.isAbilityReady(0)) {
        // Shield Bash
        minion.aiState = MonsterAIState.attacking;
        _minionAttack(minion, gameState, playerPos, 0);
      } else if (minion.isAbilityReady(3)) {
        // Cleave (AoE)
        minion.aiState = MonsterAIState.attacking;
        _minionAttack(minion, gameState, playerPos, 3);
      }
    }
    // Priority 4: Move to intercept player
    else {
      minion.aiState = MonsterAIState.pursuing;
      minion.targetPosition = playerPos.clone();
    }
  }

  /// Flee AI - run away when low health
  static void _executeFleeAI(Monster minion, GameState gameState, Vector3 playerPos) {
    minion.aiState = MonsterAIState.fleeing;
    minion.targetId = 'none'; // No target while fleeing
    final awayFromPlayer = (minion.transform.position - playerPos).normalized();
    minion.targetPosition = minion.transform.position + awayFromPlayer * 5.0;
  }

  /// Execute minion attack
  static void _minionAttack(Monster minion, GameState gameState, Vector3 targetPos, int abilityIndex) {
    if (abilityIndex >= minion.definition.abilities.length) return;
    if (!minion.isAbilityReady(abilityIndex)) return;

    final ability = minion.definition.abilities[abilityIndex];
    minion.useAbility(abilityIndex);

    if (ability.isProjectile) {
      // Create projectile
      final direction = (targetPos - minion.transform.position).normalized();
      final projectileMesh = Mesh.cube(
        size: 0.3,
        color: Vector3(
          ability.effectColor.r / 255,
          ability.effectColor.g / 255,
          ability.effectColor.b / 255,
        ),
      );
      final projectileTransform = Transform3d(
        position: minion.transform.position.clone() + Vector3(0, 0.5, 0),
        scale: Vector3(1, 1, 1),
      );

      minion.projectiles.add(Projectile(
        mesh: projectileMesh,
        transform: projectileTransform,
        velocity: direction * (ability.projectileSpeed ?? 8.0),
        lifetime: 5.0,
      ));
    } else {
      // Melee attack - check range and deal damage
      final distToTarget = minion.distanceTo(targetPos);
      if (distToTarget <= ability.range) {
        // Damage player
        if ((targetPos - gameState.playerTransform!.position).length < 1.0) {
          gameState.playerHealth = math.max(0, gameState.playerHealth - ability.damage);
        }
        // Damage allies in AoE
        if (ability.targetType == AbilityTargetType.areaOfEffect) {
          for (final ally in gameState.allies) {
            if (ally.health <= 0) continue;
            final distToAlly = (ally.transform.position - minion.transform.position).length;
            if (distToAlly <= ability.range) {
              ally.health = math.max(0, ally.health - ability.damage);
            }
          }
        }
      }
    }
  }

  /// Update minion projectiles
  static void updateMinionProjectiles(double dt, GameState gameState) {
    for (final minion in gameState.aliveMinions) {
      minion.projectiles.removeWhere((projectile) {
        // Apply wind force to minion projectile velocity
        if (globalWindState != null) {
          final windForce = globalWindState!.getProjectileForce();
          projectile.velocity.x += windForce[0] * dt;
          projectile.velocity.z += windForce[1] * dt;
        }
        projectile.transform.position += projectile.velocity * dt;
        projectile.lifetime -= dt;

        // Check collision with player
        if (gameState.playerTransform != null) {
          final distToPlayer = (projectile.transform.position - gameState.playerTransform!.position).length;
          if (distToPlayer < 1.0) {
            // Hit player
            final damage = minion.definition.effectiveDamage;
            gameState.playerHealth = math.max(0, gameState.playerHealth - damage);
            return true;
          }
        }

        // Check collision with allies
        for (final ally in gameState.allies) {
          if (ally.health <= 0) continue;
          final distToAlly = (projectile.transform.position - ally.transform.position).length;
          if (distToAlly < 0.8) {
            // Hit ally
            final damage = minion.definition.effectiveDamage;
            ally.health = math.max(0, ally.health - damage);
            return true;
          }
        }

        return projectile.lifetime <= 0;
      });
    }
  }
}
