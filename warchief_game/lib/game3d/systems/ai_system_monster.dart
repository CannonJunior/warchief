part of 'ai_system.dart';

/// Monster AI - movement, decision-making, sword, and projectiles
class _MonsterAI {
  _MonsterAI._(); // Private constructor to prevent instantiation

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

  // ==================== MONSTER AI ====================

  /// Updates monster AI (decision making using MCP tools)
  ///
  /// Uses layered decision-making:
  /// - Fast tactical tools every frame for threat response
  /// - Strategic planning on AI interval for movement/combat strategy
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

      // Single pass to check stun + fear (avoids two separate .any() scans)
      bool isStunned = false;
      bool isFeared = false;
      for (final e in gameState.monsterActiveEffects) {
        if (e.type == StatusEffect.stun) { isStunned = true; break; }
        if (e.type == StatusEffect.fear) { isFeared = true; }
      }
      if (isStunned) {
        gameState.monsterCurrentPath = null;
        return;
      }

      if (isFeared) {
        // Regenerate flee path if current one completed
        if (gameState.monsterCurrentPath == null) {
          final awayFromPlayer = (gameState.monsterTransform!.position -
                  gameState.playerTransform!.position)
              .normalized();
          final escapeTarget =
              gameState.monsterTransform!.position + awayFromPlayer * 8.0;
          gameState.monsterCurrentPath = BezierPath.interception(
            start: gameState.monsterTransform!.position,
            target: escapeTarget,
            velocity: null,
          );
        }
        return;
      }

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
    final monsterPos = gameState.monsterTransform!.position;
    final playerPos = gameState.playerTransform!.position;
    final mdx = monsterPos.x - playerPos.x;
    final mdz = monsterPos.z - playerPos.z;
    final distanceToPlayer = math.sqrt(mdx * mdx + mdz * mdz);
    final playerVelocity = gameState.playerMovementTracker.getVelocity();

    // Build ally context list
    final allyContexts = gameState.allies.map((ally) {
      final adx = ally.transform.position.x - monsterPos.x;
      final adz = ally.transform.position.z - monsterPos.z;
      return AllyContext(
        position: ally.transform.position,
        health: ally.health,
        distanceToSelf: math.sqrt(adx * adx + adz * adz),
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

  // ==================== MONSTER PROJECTILES ====================

  /// Updates monster projectiles
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
}
