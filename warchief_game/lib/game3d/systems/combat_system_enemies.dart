part of 'combat_system.dart';

// ==================== TOP-LEVEL HELPERS ====================

/// Shared RNG for dodge rolls (avoids repeated instantiation in hot path)
final _csRng = math.Random();

/// Log a damage event to the combat log.
void _csLogCombat(GameState gs, String attackType, double damage,
    DamageTarget targetType, int? allyIndex, String? minionInstanceId) {
  String target;
  switch (targetType) {
    case DamageTarget.player:
      target = 'Player';
      break;
    case DamageTarget.monster:
      target = 'Monster';
      break;
    case DamageTarget.ally:
      target = 'Ally ${(allyIndex ?? 0) + 1}';
      break;
    case DamageTarget.minion:
      target = 'Minion';
      break;
    case DamageTarget.dummy:
      target = 'Dummy';
      break;
  }
  gs.combatLogMessages.add(CombatLogEntry(
    source: attackType.split(' ').first,
    action: attackType,
    type: CombatLogType.damage,
    amount: damage,
    target: target,
  ));
  // Cap at 250 entries, batch-trim to 200 to amortize removeRange cost
  if (gs.combatLogMessages.length > 250) {
    gs.combatLogMessages.removeRange(0, gs.combatLogMessages.length - 200);
  }
}

/// Convert Vector3 color to Flutter Color
Color _csVectorToColor(Vector3 v) {
  return Color.fromRGBO(
    (v.x * 255).clamp(0, 255).toInt(),
    (v.y * 255).clamp(0, 255).toInt(),
    (v.z * 255).clamp(0, 255).toInt(),
    1.0,
  );
}

// ==================== ADVANCED COMBAT LOGIC ====================

/// Implements the more complex combat methods that would push combat_system.dart
/// over the 500-line limit. Public API is exposed via thin delegates on CombatSystem.
class _CombatAdvanced {
  _CombatAdvanced._(); // Prevent instantiation

  /// Checks collision with monster and all minions, applying damage to the first hit.
  /// Also checks the target dummy when it is the current target.
  ///
  /// - isMeleeDamage: If true, generates red mana for the player when damage is dealt
  static bool checkAndDamageEnemies(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
    Color? abilityColor,
    bool isMeleeDamage = false,
  }) {
    // Check target dummy first if it's the current target
    if (gameState.isTargetingDummy && gameState.targetDummy != null) {
      final dummy = gameState.targetDummy!;
      final threshold = collisionThreshold ?? 1.8;
      final ddx = attackerPosition.x - dummy.position.x;
      final ddy = attackerPosition.y - dummy.position.y;
      final ddz = attackerPosition.z - dummy.position.z;

      if (ddx * ddx + ddy * ddy + ddz * ddz < threshold * threshold) {
        // Use ability color if provided, otherwise derive from impact color
        final trackingColor = abilityColor ?? _csVectorToColor(impactColor);
        return damageTargetDummy(
          gameState,
          damage: damage,
          abilityName: attackType,
          abilityColor: trackingColor,
          impactColor: impactColor,
          impactSize: impactSize,
          isCritical: false,
          isHit: true,
          isMelee: isMeleeDamage,
        );
      }
    }

    // Check boss monster first
    final bossHealthBefore = gameState.monsterHealth;
    if (CombatSystem.checkAndDamageMonster(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
      showDamageIndicator: true,
      isMelee: isMeleeDamage,
    )) {
      if (isMeleeDamage) {
        gameState.generateRedManaFromMelee(damage);
        gameState.consecutiveMeleeHits++;
        GoalSystem.processEvent(gameState, 'consecutive_melee_hits',
            metadata: {'streak': gameState.consecutiveMeleeHits});
      }
      // Emit goal events on boss kill
      if (bossHealthBefore > 0 && gameState.monsterHealth <= 0) {
        GoalSystem.processEvent(gameState, 'enemy_killed');
        GoalSystem.processEvent(gameState, 'boss_killed');
      }
      return true;
    }

    // Then check minions — snapshot alive count before damage
    final aliveCountBefore = gameState.aliveMinions.length;
    final minionHit = CombatSystem.checkAndDamageMinions(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
      showDamageIndicator: true,
      isMelee: isMeleeDamage,
    );

    if (minionHit) {
      if (isMeleeDamage) {
        gameState.generateRedManaFromMelee(damage);
        // Track melee streaks for mastery goals
        gameState.consecutiveMeleeHits++;
        GoalSystem.processEvent(gameState, 'consecutive_melee_hits',
            metadata: {'streak': gameState.consecutiveMeleeHits});
      }
      // Check for minion kills — checkAndDamageMinions hits at most one per call
      gameState.refreshAliveMinions();
      if (gameState.aliveMinions.length < aliveCountBefore) {
        GoalSystem.processEvent(gameState, 'enemy_killed');
        for (final minion in gameState.minions) {
          if (!minion.isAlive && minion.health <= 0) {
            // Heuristic: recently killed minion (health exactly 0 or below)
            GoalSystem.processEvent(gameState, 'kill_${minion.definition.id}');
            break;
          }
        }
      }
    }

    return minionHit;
  }

  /// Damages a specific minion by instance ID (for targeted ability hits).
  static bool damageMinion(
    GameState gameState, {
    required String minionInstanceId,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    bool showDamageIndicator = false,
    bool isMelee = false,
    DamageSchool damageSchool = DamageSchool.physical,
  }) {
    Monster? foundMinion;
    for (final m in gameState.minions) {
      if (m.instanceId == minionInstanceId && m.isAlive) {
        foundMinion = m;
        break;
      }
    }
    if (foundMinion == null) return false;
    final minion = foundMinion;

    // Reason: Apply vulnerability bonus consistent with checkAndApplyDamage pipeline
    final matchingVuln = vulnerabilityForSchool(damageSchool);
    for (final e in minion.activeEffects) {
      if (e.type == matchingVuln) {
        damage *= 1.0 + e.strength * 0.10;
        break;
      }
    }

    final healthBefore = minion.health;
    CombatSystem.createImpactEffect(gameState,
        position: minion.transform.position, color: impactColor, size: impactSize);

    minion.takeDamage(damage);
    assert(() {
      print('$attackType hit ${minion.definition.name} for $damage damage! '
          'Health: ${minion.health.toStringAsFixed(1)}/${minion.maxHealth}');
      return true;
    }());

    if (showDamageIndicator && damage > 0) {
      final indicatorPos = minion.transform.position.clone();
      indicatorPos.y += 2.0;
      gameState.damageIndicators.add(DamageIndicator(
        damage: damage,
        worldPosition: indicatorPos,
        isMelee: isMelee,
        isKillingBlow: healthBefore > 0 && !minion.isAlive,
      ));
    }

    return true;
  }

  /// Damages the target dummy and records the hit for DPS tracking.
  static bool damageTargetDummy(
    GameState gameState, {
    required double damage,
    required String abilityName,
    required Color abilityColor,
    required Vector3 impactColor,
    required double impactSize,
    bool isCritical = false,
    bool isHit = true,
    bool isMelee = false,
  }) {
    final dummy = gameState.targetDummy;
    if (dummy == null || !dummy.isSpawned) return false;

    // Record to DPS tracker (even misses for hit rate calculation)
    gameState.dpsTracker.recordDamage(
      abilityName: abilityName,
      damage: isHit ? damage : 0,
      isCritical: isCritical,
      isHit: isHit,
      abilityColor: abilityColor,
    );

    if (isHit) {
      dummy.takeDamage(damage);
      CombatSystem.createImpactEffect(gameState,
          position: dummy.position, color: impactColor, size: impactSize);

      if (damage > 0) {
        final indicatorPos = dummy.position.clone();
        indicatorPos.y += 2.0;
        gameState.damageIndicators.add(DamageIndicator(
          damage: damage,
          worldPosition: indicatorPos,
          isMelee: isMelee,
          isKillingBlow: false, // Dummy can't die
        ));
      }
      assert(() {
        print('[DPS] $abilityName hit Target Dummy for $damage damage'
            '${isCritical ? " (CRIT!)" : ""}');
        return true;
      }());
    } else {
      assert(() { print('[DPS] $abilityName missed Target Dummy'); return true; }());
    }

    return true;
  }

  /// Checks if the attacker is within range of the target dummy and applies damage.
  static bool checkAndDamageTargetDummy(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String abilityName,
    required Color abilityColor,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
    bool isCritical = false,
    bool isMelee = false,
  }) {
    final dummy = gameState.targetDummy;
    if (dummy == null || !dummy.isSpawned) return false;

    final threshold = collisionThreshold ?? 1.5;
    final tdx = attackerPosition.x - dummy.position.x;
    final tdy = attackerPosition.y - dummy.position.y;
    final tdz = attackerPosition.z - dummy.position.z;

    if (tdx * tdx + tdy * tdy + tdz * tdz < threshold * threshold) {
      return damageTargetDummy(
        gameState,
        damage: damage,
        abilityName: abilityName,
        abilityColor: abilityColor,
        impactColor: impactColor,
        impactSize: impactSize,
        isCritical: isCritical,
        isHit: true,
        isMelee: isMelee,
      );
    }

    return false;
  }

  /// Damages the current target — routes to dummy or enemies based on targeting.
  static bool damageCurrentTarget(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String abilityName,
    required Color abilityColor,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
    bool isCritical = false,
  }) {
    if (gameState.isTargetingDummy) {
      return checkAndDamageTargetDummy(
        gameState,
        attackerPosition: attackerPosition,
        damage: damage,
        abilityName: abilityName,
        abilityColor: abilityColor,
        impactColor: impactColor,
        impactSize: impactSize,
        collisionThreshold: collisionThreshold,
        isCritical: isCritical,
      );
    }

    // Otherwise damage enemies normally
    return checkAndDamageEnemies(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: abilityName,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
    );
  }
}
