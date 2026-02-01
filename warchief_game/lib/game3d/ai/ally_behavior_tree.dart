import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/abilities_config.dart';
import '../../models/ally.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/projectile.dart';
import '../systems/combat_system.dart';
import '../utils/bezier_path.dart';
import 'ally_strategy.dart';
import 'tactical_positioning.dart';

/// Behavior tree node status
enum NodeStatus {
  success, // Node completed successfully
  failure, // Node failed
  running, // Node is still executing
}

/// Context passed to behavior tree nodes for decision making
class AllyBehaviorContext {
  final Ally ally;
  final GameState gameState;
  final double distanceToPlayer;
  final double distanceToMonster;
  final bool monsterAlive;
  final bool playerAlive;
  final TacticalPosition? tacticalPosition;

  /// Current strategy for quick access
  AllyStrategy get strategy => ally.strategy;

  /// Health percentage (0-1)
  double get healthPercent => ally.health / ally.maxHealth;

  /// Player health percentage (0-1)
  double get playerHealthPercent =>
      gameState.playerHealth / gameState.playerMaxHealth;

  /// Combat role based on ability
  CombatRole get combatRole => TacticalPositioning.getAllyRole(ally);

  /// Distance to tactical position
  double get distanceToTacticalPosition {
    if (tacticalPosition == null) return double.infinity;
    return (ally.transform.position - tacticalPosition!.position).length;
  }

  AllyBehaviorContext({
    required this.ally,
    required this.gameState,
    required this.distanceToPlayer,
    required this.distanceToMonster,
    required this.monsterAlive,
    required this.playerAlive,
    this.tacticalPosition,
  });

  /// Create context from ally and game state
  factory AllyBehaviorContext.create(Ally ally, GameState gameState) {
    final playerPos = gameState.playerTransform?.position ?? Vector3.zero();
    final monsterPos = gameState.monsterTransform?.position ?? Vector3.zero();

    // Get tactical position for this ally
    final tacticalPositions = gameState.getTacticalPositions();
    final tacticalPos = tacticalPositions[ally];

    return AllyBehaviorContext(
      ally: ally,
      gameState: gameState,
      distanceToPlayer: (ally.transform.position - playerPos).length,
      distanceToMonster: (ally.transform.position - monsterPos).length,
      monsterAlive: gameState.monsterHealth > 0,
      playerAlive: gameState.playerHealth > 0,
      tacticalPosition: tacticalPos,
    );
  }
}

/// Base class for all behavior tree nodes
abstract class BehaviorNode {
  String get name;

  /// Evaluate this node and return its status
  NodeStatus evaluate(AllyBehaviorContext context);
}

/// Selector node - tries children in order until one succeeds
///
/// Returns success if any child succeeds, failure if all fail
class Selector extends BehaviorNode {
  @override
  final String name;
  final List<BehaviorNode> children;

  Selector({required this.name, required this.children});

  @override
  NodeStatus evaluate(AllyBehaviorContext context) {
    for (final child in children) {
      final status = child.evaluate(context);
      if (status == NodeStatus.success || status == NodeStatus.running) {
        return status;
      }
    }
    return NodeStatus.failure;
  }
}

/// Sequence node - runs all children in order
///
/// Returns failure if any child fails, success if all succeed
class Sequence extends BehaviorNode {
  @override
  final String name;
  final List<BehaviorNode> children;

  Sequence({required this.name, required this.children});

  @override
  NodeStatus evaluate(AllyBehaviorContext context) {
    for (final child in children) {
      final status = child.evaluate(context);
      if (status == NodeStatus.failure) {
        return NodeStatus.failure;
      }
      if (status == NodeStatus.running) {
        return NodeStatus.running;
      }
    }
    return NodeStatus.success;
  }
}

/// Condition node - checks a condition in the game state
class Condition extends BehaviorNode {
  @override
  final String name;
  final bool Function(AllyBehaviorContext) check;

  Condition({required this.name, required this.check});

  @override
  NodeStatus evaluate(AllyBehaviorContext context) {
    return check(context) ? NodeStatus.success : NodeStatus.failure;
  }
}

/// Action node - executes a behavior and returns result
class Action extends BehaviorNode {
  @override
  final String name;
  final NodeStatus Function(AllyBehaviorContext) execute;

  Action({required this.name, required this.execute});

  @override
  NodeStatus evaluate(AllyBehaviorContext context) {
    return execute(context);
  }
}

// ==================== ALLY BEHAVIOR TREE FACTORY ====================

/// Creates the ally behavior tree based on ally's ability type
class AllyBehaviorTreeFactory {
  /// Create behavior tree for an ally
  static BehaviorNode createTree(Ally ally) {
    return Selector(
      name: 'AllyRootSelector',
      children: [
        // Priority 0: Player commands override AI
        _createCommandBranch(),

        // Priority 1: Self-preservation (unless in attack mode)
        _createSelfPreservationBranch(),

        // Priority 2: Combat
        _createCombatBranch(ally.abilityIndex),

        // Priority 3: Follow player (default)
        _createFollowBranch(),
      ],
    );
  }

  /// Handle player commands
  static BehaviorNode _createCommandBranch() {
    return Selector(
      name: 'PlayerCommand',
      children: [
        // Follow command
        Sequence(
          name: 'FollowCommand',
          children: [
            Condition(
              name: 'HasFollowCommand',
              check: (ctx) => ctx.ally.currentCommand == AllyCommand.follow,
            ),
            Action(
              name: 'ExecuteFollow',
              execute: (ctx) {
                ctx.ally.movementMode = AllyMovementMode.followPlayer;
                ctx.ally.followBufferDistance = 2.0; // Stay closer when commanded
                return NodeStatus.success;
              },
            ),
          ],
        ),
        // Attack command
        Sequence(
          name: 'AttackCommand',
          children: [
            Condition(
              name: 'HasAttackCommand',
              check: (ctx) => ctx.ally.currentCommand == AllyCommand.attack,
            ),
            Condition(
              name: 'MonsterAlive',
              check: (ctx) => ctx.monsterAlive,
            ),
            Action(
              name: 'ExecuteAttack',
              execute: (ctx) => _executeAggressiveAttack(ctx),
            ),
          ],
        ),
        // Hold command
        Sequence(
          name: 'HoldCommand',
          children: [
            Condition(
              name: 'HasHoldCommand',
              check: (ctx) => ctx.ally.currentCommand == AllyCommand.hold,
            ),
            Action(
              name: 'ExecuteHold',
              execute: (ctx) {
                ctx.ally.movementMode = AllyMovementMode.stationary;
                ctx.ally.currentPath = null;
                ctx.ally.isMoving = false;
                // Can still attack from stationary position
                if (ctx.monsterAlive && ctx.ally.abilityCooldown <= 0) {
                  if (ctx.ally.abilityIndex == 0 && ctx.distanceToMonster <= 3.0) {
                    return _executeMeleeAttack(ctx);
                  } else if (ctx.ally.abilityIndex == 1 && ctx.distanceToMonster <= 15.0) {
                    return _executeRangedAttack(ctx);
                  }
                }
                return NodeStatus.success;
              },
            ),
          ],
        ),
        // Defensive command
        Sequence(
          name: 'DefensiveCommand',
          children: [
            Condition(
              name: 'HasDefensiveCommand',
              check: (ctx) => ctx.ally.currentCommand == AllyCommand.defensive,
            ),
            Action(
              name: 'ExecuteDefensive',
              execute: (ctx) {
                // Stay near player, only attack if safe
                ctx.ally.movementMode = AllyMovementMode.followPlayer;
                ctx.ally.followBufferDistance = 3.0;

                // Heal if possible and not full health
                if (ctx.ally.abilityIndex == 2 &&
                    ctx.ally.abilityCooldown <= 0 &&
                    ctx.ally.health < ctx.ally.maxHealth * 0.8) {
                  return _executeHeal(ctx);
                }
                return NodeStatus.success;
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Aggressive attack - move to and attack monster continuously
  static NodeStatus _executeAggressiveAttack(AllyBehaviorContext ctx) {
    if (ctx.gameState.monsterTransform == null) return NodeStatus.failure;

    final monsterPos = ctx.gameState.monsterTransform!.position;

    // Determine attack range based on ability
    final attackRange = ctx.ally.abilityIndex == 0 ? 2.5 : 10.0;

    if (ctx.distanceToMonster <= attackRange) {
      // In range - attack if able
      if (ctx.ally.abilityCooldown <= 0) {
        if (ctx.ally.abilityIndex == 0) {
          return _executeMeleeAttack(ctx);
        } else if (ctx.ally.abilityIndex == 1) {
          return _executeRangedAttack(ctx);
        } else if (ctx.ally.abilityIndex == 2) {
          // Healer in attack mode - still attack at range
          return _executeRangedAttack(ctx);
        }
      }
      return NodeStatus.running;
    } else {
      // Move closer to monster
      return _executeMoveToMonster(ctx);
    }
  }

  /// Self-preservation: heal when low health (uses strategy threshold)
  static BehaviorNode _createSelfPreservationBranch() {
    return Sequence(
      name: 'SelfPreservation',
      children: [
        // Condition: Health below strategy's heal threshold
        Condition(
          name: 'IsLowHealth',
          check: (ctx) => ctx.healthPercent < ctx.strategy.healThreshold,
        ),
        // Condition: Has heal ability
        Condition(
          name: 'HasHealAbility',
          check: (ctx) => ctx.ally.abilityIndex == 2,
        ),
        // Condition: Ability ready
        Condition(
          name: 'HealReady',
          check: (ctx) => ctx.ally.abilityCooldown <= 0,
        ),
        // Condition: Defense weight allows healing (berserker won't heal much)
        Condition(
          name: 'StrategyAllowsHeal',
          check: (ctx) => ctx.strategy.defenseWeight >= 0.3,
        ),
        // Action: Heal self
        Action(
          name: 'HealSelf',
          execute: (ctx) => _executeHeal(ctx),
        ),
      ],
    );
  }

  /// Combat: attack the monster
  static BehaviorNode _createCombatBranch(int abilityIndex) {
    return Selector(
      name: 'Combat',
      children: [
        // Melee attack if in range
        if (abilityIndex == 0)
          _createMeleeAttackBranch()
        else if (abilityIndex == 1)
          _createRangedAttackBranch()
        else
          _createSupportBranch(),

        // Move toward monster if too far
        _createApproachMonsterBranch(),
      ],
    );
  }

  /// Melee attack branch (sword users) - uses strategy's engage distance
  static BehaviorNode _createMeleeAttackBranch() {
    return Sequence(
      name: 'MeleeAttack',
      children: [
        Condition(
          name: 'MonsterAlive',
          check: (ctx) => ctx.monsterAlive,
        ),
        // Use strategy's preferred range for melee (closer for aggressive)
        Condition(
          name: 'InMeleeRange',
          check: (ctx) => ctx.distanceToMonster <= ctx.strategy.preferredRange + 1.0,
        ),
        Condition(
          name: 'AbilityReady',
          check: (ctx) => ctx.ally.abilityCooldown <= 0,
        ),
        // Check we're not retreating (unless berserker)
        Condition(
          name: 'NotRetreating',
          check: (ctx) =>
              ctx.healthPercent > ctx.strategy.retreatThreshold ||
              ctx.strategy.retreatThreshold == 0,
        ),
        Action(
          name: 'SwordAttack',
          execute: (ctx) => _executeMeleeAttack(ctx),
        ),
      ],
    );
  }

  /// Ranged attack branch (fireball users) - uses strategy's preferred range
  static BehaviorNode _createRangedAttackBranch() {
    return Sequence(
      name: 'RangedAttack',
      children: [
        Condition(
          name: 'MonsterAlive',
          check: (ctx) => ctx.monsterAlive,
        ),
        // Use strategy's engage distance and preferred range
        Condition(
          name: 'InRangedRange',
          check: (ctx) {
            final minRange = ctx.strategy.allowMeleeIfRanged ? 0.0 : 3.0;
            return ctx.distanceToMonster <= ctx.strategy.engageDistance &&
                   ctx.distanceToMonster >= minRange;
          },
        ),
        Condition(
          name: 'AbilityReady',
          check: (ctx) => ctx.ally.abilityCooldown <= 0,
        ),
        // Check we're not retreating
        Condition(
          name: 'NotRetreating',
          check: (ctx) =>
              ctx.healthPercent > ctx.strategy.retreatThreshold ||
              ctx.strategy.retreatThreshold == 0,
        ),
        Action(
          name: 'FireballAttack',
          execute: (ctx) => _executeRangedAttack(ctx),
        ),
      ],
    );
  }

  /// Support branch (healer allies - heal player or self) - uses strategy weights
  static BehaviorNode _createSupportBranch() {
    return Selector(
      name: 'Support',
      children: [
        // Heal self if needed (uses strategy heal threshold)
        Sequence(
          name: 'HealSelfIfNeeded',
          children: [
            Condition(
              name: 'SelfNeedsHealing',
              check: (ctx) => ctx.healthPercent < ctx.strategy.healThreshold + 0.2,
            ),
            Condition(
              name: 'AbilityReady',
              check: (ctx) => ctx.ally.abilityCooldown <= 0,
            ),
            Action(
              name: 'HealSelf',
              execute: (ctx) => _executeHeal(ctx),
            ),
          ],
        ),
        // Stay near player (support allies stay closer)
        Action(
          name: 'StayNearPlayer',
          execute: (ctx) {
            // Ensure following player at strategy's follow distance
            if (ctx.ally.movementMode != AllyMovementMode.followPlayer) {
              ctx.ally.movementMode = AllyMovementMode.followPlayer;
            }
            ctx.ally.followBufferDistance = ctx.strategy.followDistance;
            return NodeStatus.success;
          },
        ),
      ],
    );
  }

  /// Approach monster if too far for attack - uses tactical positioning
  static BehaviorNode _createApproachMonsterBranch() {
    return Selector(
      name: 'ApproachMonster',
      children: [
        // First try: Move to tactical position (formation-based)
        Sequence(
          name: 'MoveToTacticalPosition',
          children: [
            Condition(
              name: 'MonsterAlive',
              check: (ctx) => ctx.monsterAlive,
            ),
            Condition(
              name: 'StrategyAllowsChase',
              check: (ctx) => ctx.strategy.chaseEnemy,
            ),
            Condition(
              name: 'NotRetreating',
              check: (ctx) =>
                  ctx.healthPercent > ctx.strategy.retreatThreshold ||
                  ctx.strategy.retreatThreshold == 0,
            ),
            Condition(
              name: 'HasTacticalPosition',
              check: (ctx) => ctx.tacticalPosition != null,
            ),
            Condition(
              name: 'NotAtTacticalPosition',
              check: (ctx) => ctx.distanceToTacticalPosition > 1.5,
            ),
            Action(
              name: 'MoveToTacticalPos',
              execute: (ctx) => _executeMoveToTacticalPosition(ctx),
            ),
          ],
        ),
        // Fallback: Direct approach to monster
        Sequence(
          name: 'DirectApproach',
          children: [
            Condition(
              name: 'MonsterAlive',
              check: (ctx) => ctx.monsterAlive,
            ),
            Condition(
              name: 'StrategyAllowsChase',
              check: (ctx) => ctx.strategy.chaseEnemy,
            ),
            Condition(
              name: 'NotRetreating',
              check: (ctx) =>
                  ctx.healthPercent > ctx.strategy.retreatThreshold ||
                  ctx.strategy.retreatThreshold == 0,
            ),
            Condition(
              name: 'TooFarFromMonster',
              check: (ctx) {
                return ctx.distanceToMonster > ctx.strategy.preferredRange + 2.0;
              },
            ),
            Action(
              name: 'MoveToMonster',
              execute: (ctx) => _executeMoveToMonster(ctx),
            ),
          ],
        ),
      ],
    );
  }

  /// Default follow player behavior - uses strategy's follow distance
  static BehaviorNode _createFollowBranch() {
    return Action(
      name: 'FollowPlayer',
      execute: (ctx) {
        // Ensure ally is in follow mode when idle
        if (ctx.ally.movementMode != AllyMovementMode.followPlayer) {
          ctx.ally.movementMode = AllyMovementMode.followPlayer;
        }
        // Update follow distance based on strategy
        ctx.ally.followBufferDistance = ctx.strategy.followDistance;
        return NodeStatus.success;
      },
    );
  }

  // ==================== ACTION IMPLEMENTATIONS ====================

  /// Execute melee attack
  static NodeStatus _executeMeleeAttack(AllyBehaviorContext ctx) {
    final ability = AbilitiesConfig.getAllyAbility(0);
    ctx.ally.abilityCooldown = ctx.ally.abilityCooldownMax;

    if (ctx.gameState.monsterTransform != null) {
      final toMonster = ctx.gameState.monsterTransform!.position - ctx.ally.transform.position;
      final direction = toMonster.normalized();
      final attackPosition = ctx.ally.transform.position + direction * ability.range;

      // Update ally rotation to face monster
      ctx.ally.rotation = math.atan2(-direction.x, -direction.z) * (180 / math.pi);
      ctx.ally.directionIndicatorTransform?.rotation.y = ctx.ally.rotation;

      final hit = CombatSystem.checkAndDamageMonster(
        ctx.gameState,
        attackerPosition: attackPosition,
        damage: ability.damage,
        attackType: ability.name,
        impactColor: ability.impactColor,
        impactSize: ability.impactSize,
      );

      if (hit) {
        print('[BT] Ally sword hit monster for ${ability.damage} damage!');
      }
    }
    return NodeStatus.success;
  }

  /// Execute ranged attack with lead targeting
  static NodeStatus _executeRangedAttack(AllyBehaviorContext ctx) {
    final ability = AbilitiesConfig.getAllyAbility(1);
    ctx.ally.abilityCooldown = ctx.ally.abilityCooldownMax;

    if (ctx.gameState.monsterTransform != null && ctx.gameState.monsterHealth > 0) {
      final monsterPos = ctx.gameState.monsterTransform!.position;
      final allyPos = ctx.ally.transform.position;

      // Calculate travel time and lead target
      final distanceToMonster = (monsterPos - allyPos).length;
      final travelTime = distanceToMonster / ability.projectileSpeed;

      Vector3 predictedPos = monsterPos.clone();
      if (ctx.gameState.monsterCurrentPath != null) {
        final tangent = ctx.gameState.monsterCurrentPath!.getTangentAt(
          ctx.gameState.monsterCurrentPath!.progress
        );
        final monsterVelocity = tangent * ctx.gameState.monsterMoveSpeed;
        predictedPos = monsterPos + monsterVelocity * travelTime * 0.7;
      }

      final toTarget = predictedPos - allyPos;
      final direction = toTarget.normalized();

      // Update ally rotation to face target
      ctx.ally.rotation = math.atan2(-direction.x, -direction.z) * (180 / math.pi);
      ctx.ally.directionIndicatorTransform?.rotation.y = ctx.ally.rotation;

      final fireballMesh = Mesh.cube(
        size: ability.projectileSize,
        color: ability.color,
      );
      final fireballTransform = Transform3d(
        position: allyPos.clone() + direction * 0.5,
        scale: Vector3(1, 1, 1),
      );

      ctx.ally.projectiles.add(
        Projectile(
          mesh: fireballMesh,
          transform: fireballTransform,
          velocity: direction * ability.projectileSpeed,
        ),
      );
      print('[BT] Ally casts ${ability.name}!');
    }
    return NodeStatus.success;
  }

  /// Execute heal
  static NodeStatus _executeHeal(AllyBehaviorContext ctx) {
    final ability = AbilitiesConfig.getAllyAbility(2);
    ctx.ally.abilityCooldown = ctx.ally.abilityCooldownMax;

    final oldHealth = ctx.ally.health;
    ctx.ally.health = math.min(ctx.ally.maxHealth, ctx.ally.health + ability.healAmount);
    final healedAmount = ctx.ally.health - oldHealth;

    print('[BT] Ally heals for ${healedAmount.toStringAsFixed(1)} HP (${ctx.ally.health.toStringAsFixed(0)}/${ctx.ally.maxHealth})');
    return NodeStatus.success;
  }

  /// Execute move toward monster - uses tactical position if available
  static NodeStatus _executeMoveToMonster(AllyBehaviorContext ctx) {
    if (ctx.gameState.monsterTransform == null) return NodeStatus.failure;

    final allyPos = ctx.ally.transform.position;
    Vector3 targetPos;

    // Use tactical position if available, otherwise calculate direct approach
    if (ctx.tacticalPosition != null) {
      targetPos = TacticalPositioning.applyTerrainHeight(
        ctx.gameState,
        ctx.tacticalPosition!.position,
      );
    } else {
      // Fallback: move directly toward monster at preferred range
      final monsterPos = ctx.gameState.monsterTransform!.position;
      final idealRange = ctx.strategy.preferredRange;
      final toMonster = (monsterPos - allyPos).normalized();
      targetPos = monsterPos - toMonster * idealRange;
    }

    // Only move if we're not already at the position
    final distanceToTarget = (allyPos - targetPos).length;
    if (distanceToTarget < 0.5) {
      // Already at target position
      ctx.ally.isMoving = false;
      return NodeStatus.success;
    }

    // Create path to target
    ctx.ally.currentPath = BezierPath.interception(
      start: allyPos,
      target: targetPos,
      velocity: null,
    );
    ctx.ally.movementMode = AllyMovementMode.tactical;
    ctx.ally.isMoving = true;

    return NodeStatus.running; // Still moving
  }

  /// Execute move to tactical position (formation position)
  static NodeStatus _executeMoveToTacticalPosition(AllyBehaviorContext ctx) {
    if (ctx.tacticalPosition == null) return NodeStatus.failure;

    final allyPos = ctx.ally.transform.position;
    final targetPos = TacticalPositioning.applyTerrainHeight(
      ctx.gameState,
      ctx.tacticalPosition!.position,
    );

    final distanceToTarget = (allyPos - targetPos).length;

    // Already at tactical position
    if (distanceToTarget < 1.0) {
      ctx.ally.isMoving = false;
      // Face the correct direction based on tactical position
      ctx.ally.rotation = ctx.tacticalPosition!.facingAngle;
      ctx.ally.directionIndicatorTransform?.rotation.y = ctx.ally.rotation;
      return NodeStatus.success;
    }

    // Create path to tactical position
    ctx.ally.currentPath = BezierPath.interception(
      start: allyPos,
      target: targetPos,
      velocity: null,
    );
    ctx.ally.movementMode = AllyMovementMode.tactical;
    ctx.ally.isMoving = true;

    return NodeStatus.running;
  }

  /// Check if ally should retreat based on strategy
  static bool _shouldRetreat(AllyBehaviorContext ctx) {
    if (ctx.strategy.retreatThreshold == 0) return false;
    return ctx.healthPercent <= ctx.strategy.retreatThreshold;
  }
}

/// Evaluates the behavior tree for an ally
class AllyBehaviorEvaluator {
  static final Map<Ally, BehaviorNode> _trees = {};

  /// Get or create behavior tree for ally
  static BehaviorNode getTree(Ally ally) {
    return _trees.putIfAbsent(ally, () => AllyBehaviorTreeFactory.createTree(ally));
  }

  /// Evaluate ally's behavior tree
  static NodeStatus evaluate(Ally ally, GameState gameState) {
    final tree = getTree(ally);
    final context = AllyBehaviorContext.create(ally, gameState);
    return tree.evaluate(context);
  }

  /// Clear cached tree for ally (call when ally ability changes)
  static void clearTree(Ally ally) {
    _trees.remove(ally);
  }

  /// Clear all cached trees
  static void clearAll() {
    _trees.clear();
  }
}
