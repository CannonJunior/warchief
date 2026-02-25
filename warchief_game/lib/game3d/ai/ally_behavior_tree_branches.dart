part of 'ally_behavior_tree.dart';

/// Tree-building logic for the ally behavior tree.
/// Kept separate from action implementations (see ally_behavior_tree_actions.dart)
/// and from the main types/evaluator to stay within the 500-line limit.
class _AllyBranches {
  _AllyBranches._();

  // ==================== PUBLIC BRANCH BUILDERS ====================

  /// Handle player commands
  static BehaviorNode createCommandBranch() {
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
                    return _AllyActions.executeMeleeAttack(ctx);
                  } else if (ctx.ally.abilityIndex == 1 && ctx.distanceToMonster <= 15.0) {
                    return _AllyActions.executeRangedAttack(ctx);
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
                  return _AllyActions.executeHeal(ctx);
                }
                return NodeStatus.success;
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Self-preservation: heal when low health (uses strategy threshold)
  static BehaviorNode createSelfPreservationBranch() {
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
          execute: (ctx) => _AllyActions.executeHeal(ctx),
        ),
      ],
    );
  }

  /// Combat: attack the monster
  static BehaviorNode createCombatBranch(int abilityIndex) {
    return Selector(
      name: 'Combat',
      children: [
        // Attack based on ability type
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

  /// Default follow player behavior - uses strategy's follow distance
  static BehaviorNode createFollowBranch() {
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

  // ==================== PRIVATE BRANCH BUILDERS ====================

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
          execute: (ctx) => _AllyActions.executeMeleeAttack(ctx),
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
          execute: (ctx) => _AllyActions.executeRangedAttack(ctx),
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
              execute: (ctx) => _AllyActions.executeHeal(ctx),
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
              execute: (ctx) => _AllyActions.executeMoveToTacticalPosition(ctx),
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
              execute: (ctx) => _AllyActions.executeMoveToMonster(ctx),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== COMMAND BRANCH HELPERS ====================

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
          return _AllyActions.executeMeleeAttack(ctx);
        } else if (ctx.ally.abilityIndex == 1) {
          return _AllyActions.executeRangedAttack(ctx);
        } else if (ctx.ally.abilityIndex == 2) {
          // Healer in attack mode - still attack at range
          return _AllyActions.executeRangedAttack(ctx);
        }
      }
      return NodeStatus.running;
    } else {
      // Move closer to monster
      return _AllyActions.executeMoveToMonster(ctx);
    }
  }
}
