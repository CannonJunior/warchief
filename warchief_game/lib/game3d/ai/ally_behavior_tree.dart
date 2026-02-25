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

part 'ally_behavior_tree_branches.dart';
part 'ally_behavior_tree_actions.dart';

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

/// Creates the ally behavior tree based on ally's ability type.
/// Branch building is implemented in _AllyBranches (part file).
class AllyBehaviorTreeFactory {
  AllyBehaviorTreeFactory._();

  /// Create behavior tree for an ally
  static BehaviorNode createTree(Ally ally) {
    return Selector(
      name: 'AllyRootSelector',
      children: [
        // Priority 0: Player commands override AI
        _AllyBranches.createCommandBranch(),

        // Priority 1: Self-preservation (unless in attack mode)
        _AllyBranches.createSelfPreservationBranch(),

        // Priority 2: Combat
        _AllyBranches.createCombatBranch(ally.abilityIndex),

        // Priority 3: Follow player (default)
        _AllyBranches.createFollowBranch(),
      ],
    );
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
