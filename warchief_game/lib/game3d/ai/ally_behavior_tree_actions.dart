part of 'ally_behavior_tree.dart';

/// Action implementations for the ally behavior tree.
/// Called by _AllyBranches closures; separated to keep branch builders
/// and action execution logic within the 500-line limit.
class _AllyActions {
  _AllyActions._();

  // ==================== ACTION IMPLEMENTATIONS ====================

  /// Execute melee attack
  static NodeStatus executeMeleeAttack(AllyBehaviorContext ctx) {
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
  static NodeStatus executeRangedAttack(AllyBehaviorContext ctx) {
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
  static NodeStatus executeHeal(AllyBehaviorContext ctx) {
    final ability = AbilitiesConfig.getAllyAbility(2);
    ctx.ally.abilityCooldown = ctx.ally.abilityCooldownMax;

    final oldHealth = ctx.ally.health;
    ctx.ally.health = math.min(ctx.ally.maxHealth, ctx.ally.health + ability.healAmount);
    final healedAmount = ctx.ally.health - oldHealth;

    print('[BT] Ally heals for ${healedAmount.toStringAsFixed(1)} HP '
        '(${ctx.ally.health.toStringAsFixed(0)}/${ctx.ally.maxHealth})');
    return NodeStatus.success;
  }

  /// Execute move toward monster - uses tactical position if available
  static NodeStatus executeMoveToMonster(AllyBehaviorContext ctx) {
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
  static NodeStatus executeMoveToTacticalPosition(AllyBehaviorContext ctx) {
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
  static bool shouldRetreat(AllyBehaviorContext ctx) {
    if (ctx.strategy.retreatThreshold == 0) return false;
    return ctx.healthPercent <= ctx.strategy.retreatThreshold;
  }
}
