part of 'ability_system.dart';

// ==================== UTILITY ====================

/// Degrees to radians conversion.
double _radians(double degrees) => degrees * (math.pi / 180);

// ==================== ABILITY 1: MELEE SWING ====================

/// Per-frame update for the melee swing animation and hit detection.
void _updateAbility1(double dt, GameState gameState) {
  if (!gameState.ability1Active) return;

  gameState.ability1ActiveTime += dt;

  if (gameState.ability1ActiveTime >= gameState.ability1Duration) {
    gameState.ability1Active = false;
    gameState.activeGenericMeleeAbility = null;
  } else if (gameState.swordTransform != null && gameState.activeTransform != null) {
    if (gameState.currentTargetId != null) _faceCurrentTarget(gameState);

    final forward = Vector3(
      -math.sin(_radians(gameState.activeRotation)),
      0,
      -math.cos(_radians(gameState.activeRotation)),
    );
    final swingProgress = gameState.ability1ActiveTime / gameState.ability1Duration;
    final swingAngle = swingProgress * 180;

    gameState.swordTransform!.position = gameState.activeTransform!.position + forward * 0.8;
    gameState.swordTransform!.position.y = gameState.activeTransform!.position.y;
    gameState.swordTransform!.rotation.y = gameState.activeRotation + swingAngle - 90;

    if (!gameState.ability1HitRegistered) {
      final melee = gameState.activeGenericMeleeAbility ?? _effective(AbilitiesConfig.playerSword);
      final stanceDmg = melee.damage * gameState.activeStance.damageMultiplier;

      bool hitRegistered;
      if (gameState.currentTargetId != null) {
        hitRegistered = _autoHitCurrentTarget(
          gameState,
          damage: stanceDmg,
          attackType: melee.name,
          impactColor: melee.impactColor,
          impactSize: melee.impactSize,
          isMelee: true,
        );
      } else {
        final swordTipPosition = gameState.activeTransform!.position + forward * melee.range;
        hitRegistered = CombatSystem.checkAndDamageEnemies(
          gameState,
          attackerPosition: swordTipPosition,
          damage: stanceDmg,
          attackType: melee.name,
          impactColor: melee.impactColor,
          impactSize: melee.impactSize,
          isMeleeDamage: true,
        );
      }

      if (hitRegistered) {
        gameState.ability1HitRegistered = true;
        if (gameState.activeGenericMeleeAbility != null) {
          _applyMeleeStatusEffect(gameState, melee);
        }
        _applyMeleeVulnerability(gameState, melee);
      }
    }
  }
}

// ==================== ABILITY 2: PROJECTILES ====================

/// Per-frame update for all in-flight projectiles — homing, wind, collision.
void _updateAbility2(double dt, GameState gameState) {
  final hasWind = globalWindState != null;
  final windForceX = hasWind ? globalWindState!.getProjectileForce()[0] : 0.0;
  final windForceZ = hasWind ? globalWindState!.getProjectileForce()[1] : 0.0;

  gameState.fireballs.removeWhere((projectile) {
    Vector3? targetPos;
    if (projectile.targetId != null) {
      targetPos = _getTargetPosition(gameState, projectile.targetId!);
    }

    // Homing: steer toward target each frame
    if (projectile.isHoming && projectile.targetId != null) {
      if (targetPos != null) {
        projectile.velocity = (targetPos - projectile.transform.position).normalized() * projectile.speed;
      } else {
        projectile.isHoming = false; // Target dead/gone — fly straight
      }
    }

    // Wind deflection
    if (hasWind) {
      projectile.velocity.x += windForceX * dt;
      projectile.velocity.z += windForceZ * dt;
    }

    projectile.transform.position += projectile.velocity * dt;
    projectile.lifetime -= dt;

    // Homing projectiles auto-hit at 2.5-unit threshold
    if (projectile.isHoming && targetPos != null) {
      final dx = projectile.transform.position.x - targetPos.x;
      final dy = projectile.transform.position.y - targetPos.y;
      final dz = projectile.transform.position.z - targetPos.z;
      if (dx * dx + dy * dy + dz * dz < 6.25) {
        _damageTargetWithProjectile(gameState, projectile.targetId!, projectile);
        return true;
      }
      return projectile.lifetime <= 0;
    }

    // Non-homing: collision-based hit detection
    final hitRegistered = CombatSystem.checkAndDamageEnemies(
      gameState,
      attackerPosition: projectile.transform.position,
      damage: projectile.damage * gameState.activeStance.damageMultiplier,
      attackType: projectile.abilityName,
      impactColor: projectile.impactColor,
      impactSize: projectile.impactSize,
    );

    if (hitRegistered) {
      _applyLifesteal(gameState, projectile.damage * gameState.activeStance.damageMultiplier);
      if (projectile.dotTicks > 0 && projectile.statusDuration > 0) {
        _applyDoTFromProjectile(gameState, 'boss', projectile);
      }
      return true;
    }

    return projectile.lifetime <= 0;
  });
}

// ==================== ABILITY 3: HEAL PULSE ====================

/// Per-frame update for the heal pulse visual effect.
void _updateAbility3(double dt, GameState gameState) {
  if (!gameState.ability3Active) return;

  gameState.ability3ActiveTime += dt;

  if (gameState.ability3ActiveTime >= gameState.ability3Duration) {
    gameState.ability3Active = false;
  } else if (gameState.healEffectTransform != null && gameState.activeTransform != null) {
    gameState.healEffectTransform!.position = gameState.activeTransform!.position.clone();
    final pulseScale = 1.0 + (math.sin(gameState.ability3ActiveTime * 10) * 0.2);
    gameState.healEffectTransform!.scale = Vector3(pulseScale, pulseScale, pulseScale);
  }
}

// ==================== ABILITY 4: DASH ====================

/// Per-frame update for the dash/gap-closer movement and guaranteed hit.
void _updateAbility4(double dt, GameState gameState) {
  if (!gameState.ability4Active) return;

  gameState.ability4ActiveTime += dt;

  if (gameState.ability4ActiveTime >= gameState.ability4Duration) {
    _endDash(gameState);
  } else if (gameState.activeTransform != null) {
    final dashConfig = gameState.activeDashAbility ?? _effective(AbilitiesConfig.playerDashAttack);
    final dashSpeed = (dashConfig.range / dashConfig.duration) * gameState.activeStance.movementSpeedMultiplier;
    final targetPos = gameState.dashTargetPosition;

    if (targetPos != null) {
      // Targeted dash: move toward enemy
      final dx = targetPos.x - gameState.activeTransform!.position.x;
      final dz = targetPos.z - gameState.activeTransform!.position.z;
      final distSq = dx * dx + dz * dz;
      const arrivalThreshold = 1.5;

      if (distSq > arrivalThreshold * arrivalThreshold) {
        final dist = math.sqrt(distSq);
        final dirX = dx / dist;
        final dirZ = dz / dist;
        gameState.activeTransform!.position.x += dirX * dashSpeed * dt;
        gameState.activeTransform!.position.z += dirZ * dashSpeed * dt;
        final targetYaw = -math.atan2(dirX, dirZ) * (180.0 / math.pi);
        gameState.activeRotation = targetYaw;
        gameState.activeTransform!.rotation.y = targetYaw;
      }

      if (!gameState.ability4HitRegistered) {
        final arrived = distSq <= arrivalThreshold * arrivalThreshold;
        if (arrived || gameState.ability4ActiveTime >= gameState.ability4Duration * 0.9) {
          final stanceDmg = dashConfig.damage * gameState.activeStance.damageMultiplier;
          CombatSystem.checkAndDamageEnemies(
            gameState,
            attackerPosition: targetPos,
            damage: stanceDmg,
            attackType: dashConfig.name,
            impactColor: dashConfig.impactColor,
            impactSize: dashConfig.impactSize,
            isMeleeDamage: true,
            collisionThreshold: 999.0, // Reason: guaranteed hit
          );
          gameState.ability4HitRegistered = true;
          _applyDashEffects(gameState, dashConfig);
          if (arrived) _endDash(gameState);
        }
      }
    } else {
      // No target: dash straight forward (legacy behavior)
      final forward = Vector3(
        -math.sin(_radians(gameState.activeRotation)), 0,
        -math.cos(_radians(gameState.activeRotation)),
      );
      gameState.activeTransform!.position += forward * dashSpeed * dt;

      if (!gameState.ability4HitRegistered) {
        final stanceDmg = dashConfig.damage * gameState.activeStance.damageMultiplier;
        final hitRegistered = CombatSystem.checkAndDamageEnemies(
          gameState,
          attackerPosition: gameState.activeTransform!.position,
          damage: stanceDmg,
          attackType: dashConfig.name,
          impactColor: dashConfig.impactColor,
          impactSize: dashConfig.impactSize,
          isMeleeDamage: true,
        );
        if (hitRegistered) {
          gameState.ability4HitRegistered = true;
          _applyDashEffects(gameState, dashConfig);
        }
      }
    }

    // Snap to terrain height
    if (gameState.infiniteTerrainManager != null) {
      gameState.activeTransform!.position.y = gameState.infiniteTerrainManager!.getTerrainHeight(
        gameState.activeTransform!.position.x,
        gameState.activeTransform!.position.z,
      );
    }

    // Update dash trail visual
    if (gameState.dashTrailTransform != null) {
      gameState.dashTrailTransform!.position = gameState.activeTransform!.position.clone();
      gameState.dashTrailTransform!.rotation.y = gameState.activeRotation;
    }
  }
}

// ==================== IMPACT EFFECTS ====================

/// Per-frame update for impact effect lifetime and scale growth.
void _updateImpactEffects(double dt, GameState gameState) {
  gameState.impactEffects.removeWhere((impact) {
    impact.lifetime -= dt;
    final scale = 1.0 + (impact.progress * GameConfig.impactEffectGrowthScale);
    impact.transform.scale = Vector3(scale, scale, scale);
    return impact.lifetime <= 0;
  });
}
