part of 'ai_system.dart';

/// Minion AI - movement, archetype behaviors, attacks, and projectiles
class _MinionAI {
  _MinionAI._(); // Private constructor to prevent instantiation

  // ==================== MINION MOVEMENT ====================

  /// Updates minion movement toward their targets
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

  // ==================== MINION AI ====================

  /// Updates minion AI decisions
  ///
  /// Each minion archetype has different behavior:
  /// - DPS: Aggressive, attacks player/allies directly
  /// - Support: Stays back, buffs allies, debuffs enemies
  /// - Healer: Stays back, heals wounded allies
  /// - Tank: Engages player, protects other minions
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

        // Get squared distance to player (avoid sqrt for threshold check)
        final distSqToPlayer = minion.distanceToSq(playerPos);
        final aggroRange = minion.definition.aggroRange;

        // Check if in aggro range
        if (distSqToPlayer <= aggroRange * aggroRange) {
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
    final distSqToPlayer = minion.distanceToSq(playerPos);

    // Find nearest target (player or ally) using squared distance
    Vector3 targetPos = playerPos;
    double nearestDistSq = distSqToPlayer;
    String targetId = 'player'; // Track who we're targeting

    // Check if any ally is closer
    for (int i = 0; i < gameState.allies.length; i++) {
      final ally = gameState.allies[i];
      if (ally.health <= 0) continue;
      final distSq = minion.distanceToSq(ally.transform.position);
      if (distSq < nearestDistSq) {
        nearestDistSq = distSq;
        targetPos = ally.transform.position;
        targetId = 'ally_$i';
      }
    }

    // Update minion's target tracking
    minion.targetId = targetId;

    final attackRange = minion.definition.attackRange;
    if (nearestDistSq <= attackRange * attackRange) {
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
    final distSqToPlayer = minion.distanceToSq(playerPos);

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
    else if (distSqToPlayer <= minion.definition.attackRange * minion.definition.attackRange && minion.isAbilityReady(1)) {
      minion.aiState = MonsterAIState.casting;
      minion.targetId = 'player';
      // Apply debuff (Curse of Weakness)
      // For now, just deal minor damage
      _minionAttack(minion, gameState, playerPos, 2);
    }
    // Priority 3: Stay at medium range
    else {
      minion.aiState = MonsterAIState.supporting;
      const optimalRange = 7.0;
      final distanceToPlayer = math.sqrt(distSqToPlayer);
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
    final distSqToPlayer = minion.distanceToSq(playerPos);

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
      const safeRange = 10.0;
      if (distSqToPlayer < safeRange * safeRange) {
        // Too close - run away
        final awayFromPlayer = (minion.transform.position - playerPos).normalized();
        minion.targetPosition = minion.transform.position + awayFromPlayer * 3.0;
      }
    }
  }

  /// Tank minion AI - engages player, protects allies
  static void _executeTankMinionAI(Monster minion, GameState gameState, Vector3 playerPos) {
    final distSqToPlayer = minion.distanceToSq(playerPos);

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
    else if (distSqToPlayer <= minion.definition.attackRange * minion.definition.attackRange) {
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
          final rangeSq = ability.range * ability.range;
          for (final ally in gameState.allies) {
            if (ally.health <= 0) continue;
            final adx = ally.transform.position.x - minion.transform.position.x;
            final adz = ally.transform.position.z - minion.transform.position.z;
            if (adx * adx + adz * adz <= rangeSq) {
              ally.health = math.max(0, ally.health - ability.damage);
            }
          }
        }
      }
    }
  }

  // ==================== MINION PROJECTILES ====================

  /// Update minion projectiles
  static void updateMinionProjectiles(double dt, GameState gameState) {
    // Cache wind force once per frame
    final hasWind = globalWindState != null;
    final windForceX = hasWind ? globalWindState!.getProjectileForce()[0] : 0.0;
    final windForceZ = hasWind ? globalWindState!.getProjectileForce()[1] : 0.0;
    final playerPos = gameState.playerTransform?.position;

    for (final minion in gameState.aliveMinions) {
      minion.projectiles.removeWhere((projectile) {
        // Apply cached wind force to minion projectile velocity
        if (hasWind) {
          projectile.velocity.x += windForceX * dt;
          projectile.velocity.z += windForceZ * dt;
        }
        projectile.transform.position += projectile.velocity * dt;
        projectile.lifetime -= dt;

        final projPos = projectile.transform.position;

        // Check collision with player (squared distance, threshold 1.0^2 = 1.0)
        if (playerPos != null) {
          final pdx = projPos.x - playerPos.x;
          final pdy = projPos.y - playerPos.y;
          final pdz = projPos.z - playerPos.z;
          if (pdx * pdx + pdy * pdy + pdz * pdz < 1.0) {
            final damage = minion.definition.effectiveDamage;
            gameState.playerHealth = math.max(0, gameState.playerHealth - damage);
            return true;
          }
        }

        // Check collision with allies (squared distance, threshold 0.8^2 = 0.64)
        for (final ally in gameState.allies) {
          if (ally.health <= 0) continue;
          final adx = projPos.x - ally.transform.position.x;
          final ady = projPos.y - ally.transform.position.y;
          final adz = projPos.z - ally.transform.position.z;
          if (adx * adx + ady * ady + adz * adz < 0.64) {
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
