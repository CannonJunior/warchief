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
import '../../models/active_effect.dart';
import '../ai/mcp_tools.dart';
import '../ai/ally_behavior_tree.dart';
import '../utils/bezier_path.dart';

part 'ai_system_monster.dart';
part 'ai_system_ally.dart';
part 'ai_system_minions.dart';

// ==================== TERRAIN HELPERS ====================

/// Get terrain height at position, with fallback to groundLevel
double _getTerrainHeight(GameState gameState, double x, double z) {
  if (gameState.infiniteTerrainManager != null) {
    return gameState.infiniteTerrainManager!.getTerrainHeight(x, z);
  }
  return gameState.groundLevel;
}

/// Small buffer to ensure units are visually above terrain surface
const double _terrainBuffer = 0.15;

/// Apply terrain height to a unit's Y position
/// The unitSize parameter is the size of the cube mesh (units are centered)
void _applyTerrainHeight(GameState gameState, Transform3d transform, {double unitSize = 0.8}) {
  final terrainHeight = _getTerrainHeight(
    gameState,
    transform.position.x,
    transform.position.z,
  );
  // Add half the unit size + buffer so the bottom of the mesh sits above terrain
  transform.position.y = terrainHeight + unitSize / 2 + _terrainBuffer;
}

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
    _MonsterAI.updateMonsterMovement(dt, gameState);
    _MonsterAI.updateMonsterAI(dt, gameState, logMonsterAI, activateMonsterAbility1, activateMonsterAbility2, activateMonsterAbility3);
    _MonsterAI.updateMonsterSword(dt, gameState);
    _AllyAI.updateAllyMovement(dt, gameState);
    _AllyAI.updateAllyAI(dt, gameState);
    _MinionAI.updateMinionMovement(dt, gameState);
    _MinionAI.updateMinionAI(dt, gameState);
    _MonsterAI.updateMonsterProjectiles(dt, gameState);
    _AllyAI.updateAllyProjectiles(dt, gameState);
    _MinionAI.updateMinionProjectiles(dt, gameState);
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
