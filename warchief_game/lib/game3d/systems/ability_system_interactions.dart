part of 'ability_system.dart';

// ==================== TARGET FACING ====================

/// Rotate the active character toward the current target before striking.
void _faceCurrentTarget(GameState gameState) {
  if (gameState.currentTargetId == null || gameState.activeTransform == null) return;
  final targetPos = gameState.getCurrentTargetPosition();
  if (targetPos == null) return;
  final dx = targetPos.x - gameState.activeTransform!.position.x;
  final dz = targetPos.z - gameState.activeTransform!.position.z;
  if (dx * dx + dz * dz < 0.001) return;
  final targetYaw = -math.atan2(dx, dz) * (180.0 / math.pi);
  gameState.activeRotation = targetYaw;
  gameState.activeTransform!.rotation.y = targetYaw;
}

// ==================== GUARANTEED HIT ====================

/// Apply damage directly to the current target without collision checks.
///
/// Reason: Successfully cast or activated abilities should always hit their
/// intended target. Handles boss, minion, and dummy with all side effects
/// (red mana generation, goal events, damage indicators). Returns true if hit.
bool _autoHitCurrentTarget(
  GameState gameState, {
  required double damage,
  required String attackType,
  required Vector3 impactColor,
  required double impactSize,
  bool isMelee = false,
}) {
  final targetId = gameState.currentTargetId;
  if (targetId == null) return false;
  if (targetId.startsWith('ally_')) return false; // Never damage friendlies

  // Apply stance damage modifier (Cadence on-beat, Tempest chain, Momentum stacks, etc.)
  if (_activeStanceDamageMod != 1.0) damage *= _activeStanceDamageMod;

  // Apply weapon damage modifier and armor effectiveness (physical only)
  if (isMelee) {
    final weaponMods = WeaponSystem.getActiveModifiers(gameState);
    damage *= weaponMods.damageMultiplier;
    final targetArmor = _getTargetArmorCategory(gameState);
    damage *= WeaponSystem.getArmorEffectiveness(weaponMods.category, targetArmor);
    damage = WeaponSystem.applySpecialMechanicDamage(
      weaponMods, damage, targetArmor, gameState,
    );
  }

  bool hit = false;

  if (gameState.isTargetingDummy && gameState.targetDummy != null) {
    hit = CombatSystem.damageTargetDummy(
      gameState,
      damage: damage,
      abilityName: attackType,
      abilityColor: Color.fromRGBO(
        (impactColor.x * 255).clamp(0, 255).toInt(),
        (impactColor.y * 255).clamp(0, 255).toInt(),
        (impactColor.z * 255).clamp(0, 255).toInt(),
        1.0,
      ),
      impactColor: impactColor,
      impactSize: impactSize,
      isMelee: isMelee,
    );
  } else if (targetId == 'boss') {
    if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
      final bossHealthBefore = gameState.monsterHealth;
      hit = CombatSystem.checkAndDamageMonster(
        gameState,
        attackerPosition: gameState.monsterTransform!.position,
        damage: damage,
        attackType: attackType,
        impactColor: impactColor,
        impactSize: impactSize,
        collisionThreshold: 999.0,
        showDamageIndicator: true,
        isMelee: isMelee,
      );
      if (hit && bossHealthBefore > 0 && gameState.monsterHealth <= 0) {
        GoalSystem.processEvent(gameState, 'enemy_killed');
        GoalSystem.processEvent(gameState, 'boss_killed');
      }
    }
  } else {
    final aliveCountBefore = gameState.aliveMinions.length;
    hit = CombatSystem.damageMinion(
      gameState,
      minionInstanceId: targetId,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      showDamageIndicator: true,
      isMelee: isMelee,
    );
    if (hit) {
      gameState.refreshAliveMinions();
      if (gameState.aliveMinions.length < aliveCountBefore) {
        GoalSystem.processEvent(gameState, 'enemy_killed');
        for (final minion in gameState.minions) {
          if (!minion.isAlive && minion.health <= 0) {
            GoalSystem.processEvent(gameState, 'kill_${minion.definition.id}');
            break;
          }
        }
      }
    }
  }

  if (hit && isMelee) {
    gameState.generateRedManaFromMelee(damage);
    gameState.consecutiveMeleeHits++;
    GoalSystem.processEvent(gameState, 'consecutive_melee_hits',
        metadata: {'streak': gameState.consecutiveMeleeHits});
  }

  if (hit) _applyLifesteal(gameState, damage);

  // Notify stance system of the hit (Momentum stacks, Pressure gauge, Tempest chain, etc.)
  if (hit) {
    final hitAbility = _lastFiredAbilityData;
    if (hitAbility != null) {
      final entityId = targetId.hashCode;
      _notifyStanceOnHit(gameState, hitAbility, entityId, isDot: false, targetsHit: 1);

      // Momentum splash damage at max stacks
      final sm = gameState.activeStance.mechanics;
      if (gameState.playerStance == StanceId.momentum && sm != null) {
        final s = gameState.stanceRuntime;
        if (s.momentumStacks >= sm.momentumMaxStacks && sm.momentumSplashAtMax) {
          _applyMomentumSplash(
            gameState, damage, sm.momentumSplashRatio,
            sm.momentumSplashRadius, impactColor,
          );
        }
      }
    }
  }

  return hit;
}

// ==================== LIFESTEAL ====================

/// Heal the active character by [damage] * stance.lifestealRatio.
/// Not modified by healingMultiplier — separate sustain path.
void _applyLifesteal(GameState gameState, double damage) {
  final ratio = gameState.activeStance.lifestealRatio;
  if (ratio <= 0 || damage <= 0) return;
  final heal = damage * ratio;
  final oldHealth = gameState.activeHealth;
  gameState.activeHealth = math.min(gameState.activeMaxHealth, gameState.activeHealth + heal);
  final healed = gameState.activeHealth - oldHealth;
  if (healed > 0) {
    gameState.addCombatLog(CombatLogEntry(
      source: 'Player', action: 'Lifesteal', type: CombatLogType.heal,
      amount: healed, target: 'Player',
    ));
    _showHealIndicator(gameState, healed, gameState.activeTransform?.position);
  }
}

// ==================== DASH / GAP-CLOSER ====================

/// Melee abilities with range >= 4 units are treated as gap-closers.
const double _gapCloserRangeThreshold = 4.0;

/// Begin a dash toward the current target (or straight ahead if no target).
void _startDash(int slotIndex, GameState gameState, AbilityData ability, String message) {
  if (gameState.ability4Active) return;
  gameState.ability4Active = true;
  gameState.ability4ActiveTime = 0.0;
  gameState.ability4HitRegistered = false;
  gameState.activeDashAbility = ability;
  gameState.ability4Duration = ability.duration > 0 ? ability.duration : 0.4;
  // Reason: snapshot target position so the dash tracks even if enemy moves
  gameState.dashTargetPosition = gameState.getCurrentTargetPosition()?.clone();
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  debugPrint(message);
}

/// End a dash and reset dash state fields.
void _endDash(GameState gameState) {
  gameState.ability4Active = false;
  gameState.activeDashAbility = null;
  gameState.dashTargetPosition = null;
}

/// Apply knockback and status effects after a dash hit.
void _applyDashEffects(GameState gameState, AbilityData dashConfig) {
  if (dashConfig.knockbackForce > 0 && gameState.activeTransform != null) {
    final forward = Vector3(
      -math.sin(_radians(gameState.activeRotation)),
      0,
      -math.cos(_radians(gameState.activeRotation)),
    );
    if (gameState.currentTargetId == 'boss' && gameState.monsterTransform != null) {
      gameState.monsterTransform!.position += forward * dashConfig.knockbackForce;
    }
  }
  _applyMeleeStatusEffect(gameState, dashConfig);
  _applyMeleeVulnerability(gameState, dashConfig);
}

// ==================== GENERIC ABILITY EXECUTORS ====================

/// Returns the strength multiplier from active buffs on the active character.
double _activeStrengthMult(GameState gameState) {
  double mult = 1.0;
  for (final e in gameState.activeCharacterActiveEffects) {
    if (e.type == StatusEffect.strength && !e.isExpired) {
      // Reason: apply active strength buffs (from auras, self-buffs, party buffs) to outgoing damage
      mult += e.strength.clamp(0.0, 1.0);
    }
  }
  return mult;
}

/// Generic melee attack — gap-closer if range >= [_gapCloserRangeThreshold].
void _executeGenericMelee(int slotIndex, GameState gameState, AbilityData rawAbility, String message) {
  final ability = globalAbilityOverrideManager?.getEffectiveAbility(rawAbility) ?? rawAbility;
  if (ability.range >= _gapCloserRangeThreshold && ability.type != AbilityType.aoe) {
    _startDash(slotIndex, gameState, ability, message);
    return;
  }
  if (gameState.ability1Active) return;
  gameState.activeGenericMeleeAbility = ability.copyWith(
    damage: ability.damage * _activeStrengthMult(gameState),
  );
  gameState.ability1Active = true;
  gameState.ability1ActiveTime = 0.0;
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  gameState.ability1HitRegistered = false;
  debugPrint(message);
}

/// Generic homing projectile (uses ability data for speed, color, etc.).
void _executeGenericProjectile(int slotIndex, GameState gameState, AbilityData rawAbility, String message) {
  final ability = globalAbilityOverrideManager?.getEffectiveAbility(rawAbility) ?? rawAbility;
  if (gameState.activeTransform == null) return;
  final playerPos = gameState.activeTransform!.position;
  final projectileSpeed = ability.projectileSpeed > 0 ? ability.projectileSpeed : 10.0;
  final targetId = gameState.currentTargetId;
  final targetPos = targetId != null ? _getTargetPosition(gameState, targetId) : null;
  final direction = targetPos != null
      ? (targetPos - playerPos).normalized()
      : Vector3(-math.sin(_radians(gameState.activeRotation)), 0, -math.cos(_radians(gameState.activeRotation)));
  final startPos = playerPos.clone() + direction * 1.0;
  startPos.y = playerPos.y;
  gameState.fireballs.add(Projectile(
    mesh: Mesh.cube(size: ability.projectileSize > 0 ? ability.projectileSize : 0.4, color: ability.color),
    transform: Transform3d(position: startPos, scale: Vector3(1, 1, 1)),
    velocity: direction * projectileSpeed,
    targetId: targetId,
    speed: projectileSpeed,
    isHoming: targetId != null,
    damage: ability.damage,
    abilityName: ability.name,
    impactColor: ability.impactColor,
    impactSize: ability.impactSize,
    statusEffects: ability.allStatusEffects,
    dotTicks: ability.dotTicks,
  ));
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  debugPrint('$message${targetId != null ? " (targeting $targetId)" : ""}');
}

/// Generic AoE centered on the caster.
void _executeGenericAoE(int slotIndex, GameState gameState, AbilityData rawAbility, String message) {
  final ability = globalAbilityOverrideManager?.getEffectiveAbility(rawAbility) ?? rawAbility;
  if (gameState.activeTransform == null) return;
  gameState.impactEffects.add(ImpactEffect(
    mesh: Mesh.cube(size: ability.aoeRadius > 0 ? ability.aoeRadius : 2.0, color: ability.color),
    transform: Transform3d(position: gameState.activeTransform!.position.clone(), scale: Vector3(1, 1, 1)),
    lifetime: 0.5,
  ));
  final aoeDamage = ability.damage * gameState.activeStance.damageMultiplier * _activeStrengthMult(gameState);
  final hit = CombatSystem.checkAndDamageEnemies(
    gameState,
    attackerPosition: gameState.activeTransform!.position,
    damage: aoeDamage,
    attackType: ability.name,
    impactColor: ability.impactColor,
    impactSize: ability.impactSize,
  );
  if (hit) _applyLifesteal(gameState, aoeDamage);
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  debugPrint(message);
}

/// Generic heal — applies to the current friendly target (ally) or self if no friendly is targeted.
///
/// If the ability has a [statusEffect] (e.g. shield, regen) with a positive
/// [statusDuration], that buff is also applied to the healed target so that
/// heal+shield abilities work without needing a named dispatch case.
void _executeGenericHeal(int slotIndex, GameState gameState, AbilityData rawAbility, String message) {
  final ability = globalAbilityOverrideManager?.getEffectiveAbility(rawAbility) ?? rawAbility;
  if (gameState.ability3Active) return;
  gameState.ability3Active = true;
  gameState.ability3ActiveTime = 0.0;
  final effectiveHeal = ability.healAmount * gameState.activeStance.healingMultiplier;
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);

  // Heal targeted ally if one is selected
  final targetId = gameState.currentTargetId;
  if (targetId != null && targetId.startsWith('ally_')) {
    final index = int.tryParse(targetId.substring(5));
    if (index != null && index < gameState.allies.length && gameState.allies[index].health > 0) {
      final ally = gameState.allies[index];
      final oldHealth = ally.health;
      ally.health = math.min(ally.maxHealth, ally.health + effectiveHeal);
      final healedAmount = ally.health - oldHealth;
      _logHeal(gameState, ability.name, healedAmount);
      _showHealIndicator(gameState, healedAmount, ally.transform.position);
      _applyHealBuff(ally.activeEffects, ability);
      debugPrint('$message Restored ${healedAmount.toStringAsFixed(1)} HP to ${ally.name}');
      return;
    }
  }

  // Self-heal (no target, self-target, or invalid ally target)
  final oldHealth = gameState.activeHealth;
  gameState.activeHealth = math.min(gameState.activeMaxHealth, gameState.activeHealth + effectiveHeal);
  final healedAmount = gameState.activeHealth - oldHealth;
  _logHeal(gameState, ability.name, healedAmount);
  _showHealIndicator(gameState, healedAmount, gameState.activeTransform?.position);
  _applyHealBuff(gameState.activeCharacterActiveEffects, ability);
  debugPrint('$message Restored ${healedAmount.toStringAsFixed(1)} HP');
}

/// Apply supportive buffs from a heal ability to the given effect list.
///
/// Iterates all effects in [ability.allStatusEffects]. Re-applying the same
/// buff type refreshes the duration rather than stacking.
void _applyHealBuff(List<ActiveEffect> effects, AbilityData ability) {
  for (final fx in ability.allStatusEffects) {
    if (fx.duration <= 0) continue;
    // Reason: remove existing instance so recasting refreshes rather than stacks.
    effects.removeWhere((e) => e.type == fx.type && !e.isPermanent);
    effects.add(ActiveEffect(
      type: fx.type,
      remainingDuration: fx.duration,
      totalDuration: fx.duration,
      strength: fx.strength,
      sourceName: ability.name,
    ));
  }
}

/// Data-driven dispatcher: routes to the appropriate generic handler by ability type.
void _executeGenericAbility(int slotIndex, GameState gameState, AbilityData ability) {
  switch (ability.type) {
    case AbilityType.melee:
      _executeGenericMelee(slotIndex, gameState, ability, '${ability.name}!');
      break;
    case AbilityType.ranged:
    case AbilityType.dot:
      _executeGenericProjectile(slotIndex, gameState, ability, '${ability.name}!');
      break;
    case AbilityType.heal:
      _executeGenericHeal(slotIndex, gameState, ability, '${ability.name}!');
      break;
    case AbilityType.aoe:
      _executeGenericAoE(slotIndex, gameState, ability, '${ability.name}!');
      break;
    case AbilityType.buff:
    case AbilityType.debuff:
    case AbilityType.utility:
    case AbilityType.channeled:
    case AbilityType.summon:
      _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
      debugPrint('${ability.name} activated!');
      break;
  }
}

// ==================== STATUS EFFECTS ====================

/// Displace [targetId] by [displacement] in world space (instant, no ActiveEffect).
void _displaceTarget(GameState gameState, String targetId, Vector3 displacement) {
  Vector3? pos;
  if (targetId == 'boss' && gameState.monsterTransform != null) {
    pos = gameState.monsterTransform!.position;
  } else {
    final minion = gameState.minionById(targetId);
    if (minion != null && minion.isAlive) pos = minion.transform.position;
  }
  if (pos == null) return;

  // Reason: step along displacement path checking terrain height.
  // A steep rise = wall slam (bonus damage + stun).
  // A steep drop = cliff launch (convert to airborne).
  final terrain = gameState.infiniteTerrainManager;
  if (terrain != null) {
    final dispLen = displacement.length;
    if (dispLen > 0.1) {
      final steps = (dispLen / 1.0).ceil().clamp(1, 20);
      final stepDx = displacement.x / steps;
      final stepDz = displacement.z / steps;
      var prevH = terrain.getTerrainHeight(pos.x, pos.z);
      for (int i = 1; i <= steps; i++) {
        final nx = pos.x + stepDx * i;
        final nz = pos.z + stepDz * i;
        final h = terrain.getTerrainHeight(nx, nz);
        final dh = h - prevH;

        if (dh > 2.0) {
          // Wall slam: stop displacement, deal bonus damage, apply 1s stun
          final force = dispLen;
          final bonusDmg = force * 0.5;
          _applyDirectDamage(gameState, targetId, bonusDmg);
          _applyStunToTarget(gameState, targetId, 1.0, 'Wall Slam');
          return;
        }

        if (dh < -3.0) {
          // Cliff edge: convert to airborne with horizontal momentum
          pos.x = nx;
          pos.z = nz;
          _launchTargetAirborne(gameState, targetId, 2.0);
          return;
        }

        prevH = h;
      }
    }
  }

  pos.x += displacement.x;
  pos.z += displacement.z;
}

/// Apply direct damage to a target by ID (bypasses collision checks).
void _applyDirectDamage(GameState gameState, String targetId, double damage) {
  if (targetId == 'boss') {
    gameState.monsterHealth = (gameState.monsterHealth - damage).clamp(0.0, gameState.monsterMaxHealth);
  } else {
    final minion = gameState.minionById(targetId);
    if (minion != null && minion.isAlive) {
      minion.health = (minion.health - damage).clamp(0.0, minion.maxHealth);
    }
  }
}

/// Apply a stun ActiveEffect to a target by ID.
void _applyStunToTarget(GameState gameState, String targetId, double duration, String source) {
  final effect = ActiveEffect(
    type: StatusEffect.stun, remainingDuration: duration,
    totalDuration: duration, strength: 1.0, sourceName: source,
  );
  if (targetId == 'boss') {
    gameState.monsterActiveEffects.add(effect);
  } else {
    final minion = gameState.minionById(targetId);
    if (minion != null && minion.isAlive) minion.activeEffects.add(effect);
  }
}

/// Launch a target into airborne state with the given peak height.
void _launchTargetAirborne(GameState gameState, String targetId, double height) {
  final grav = globalCcConfig?.airborneGravityAccel ?? 12.0;
  final vel = math.sqrt(2.0 * grav * height);

  final minion = gameState.minionById(targetId);
  if (minion != null && minion.isAlive) {
    minion.airborneVelocityY = vel;
    minion.airborneHeight = math.max(minion.airborneHeight, 0.01);
  }
  // Boss doesn't go airborne
}

/// AoE knockback: push all enemies within [radius] of [centerX, centerZ]
/// radially outward. Strength falls off with distance from center.
void _executeScatter(
  GameState gameState,
  double centerX,
  double centerZ,
  double radius,
  double maxForce,
) {
  final r2 = radius * radius;

  void pushIfInRange(dynamic transform, String targetId) {
    final dx = transform.position.x - centerX;
    final dz = transform.position.z - centerZ;
    final distSq = dx * dx + dz * dz;
    if (distSq >= r2 || distSq < 0.01) return;
    final dist = math.sqrt(distSq);
    final falloff = 1.0 - (dist / radius);
    final force = maxForce * falloff;
    final nx = dx / dist;
    final nz = dz / dist;
    transform.position.x += nx * force;
    transform.position.z += nz * force;
  }

  // Push boss
  if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
    pushIfInRange(gameState.monsterTransform!, 'boss');
  }

  // Push minions
  for (final minion in gameState.aliveMinions) {
    pushIfInRange(minion.transform, minion.instanceId);
  }
}

/// Returns the juggle window timer for the given target (0 = no juggle window).
double _getJuggleTimer(GameState gameState, String targetId) {
  if (targetId == 'player') return gameState.juggleWindowTimer;
  final ally = gameState.allies.where((a) => a.name == targetId).firstOrNull;
  if (ally != null) return ally.juggleWindowTimer;
  final minion = gameState.minionById(targetId);
  if (minion != null) return minion.juggleWindowTimer;
  return 0.0;
}

/// Unit vector in the caster's current facing direction.
Vector3 _casterForward(GameState gameState) => Vector3(
  -math.sin(_radians(gameState.activeRotation)),
  0,
  -math.cos(_radians(gameState.activeRotation)),
);

/// Apply one [AbilityStatusEffect] entry to [targetId].
///
/// knockback/grip are instant positional changes.
/// knockdown creates both a stun and an interrupt ActiveEffect.
/// All other effects create a standard timed ActiveEffect.
void _applySingleStatusEffect(
  GameState gameState,
  String targetId,
  AbilityStatusEffect fx,
  String sourceName, {
  int dotTicks = 0,
  double dotDamage = 0.0,
}) {
  if (fx.type == StatusEffect.none) return;

  switch (fx.type) {
    // ── Instant positional effects (no ActiveEffect) ───────────────────
    case StatusEffect.knockback:
      // Reason: push target in caster's facing direction by strength world units
      if (gameState.activeTransform != null) {
        _displaceTarget(gameState, targetId, _casterForward(gameState) * fx.strength);
      }
      return;

    case StatusEffect.grip:
      // Reason: pull target toward caster by (strength * current distance);
      // strength is clamped to 0–1 so the target can never overshoot the caster.
      final casterPos = gameState.activeTransform?.position;
      if (casterPos == null) return;
      final targetPos = _getTargetPosition(gameState, targetId);
      if (targetPos == null) return;
      final toTarget = targetPos - casterPos;
      final pullFraction = fx.strength.clamp(0.0, 1.0);
      // Negative: move target toward caster
      _displaceTarget(gameState, targetId, toTarget * (-pullFraction));
      return;

    case StatusEffect.airborne:
      // Reason: launch target upward; strength = desired peak height.
      // v₀ = sqrt(2·g·h) gives the initial velocity for a ballistic arc.
      final ccCfg = globalCcConfig;
      final grav = ccCfg?.airborneGravityAccel ?? 12.0;
      var launchHeight = fx.strength;

      // Juggle bonus: if target just landed, grant +30% height
      final juggle = _getJuggleTimer(gameState, targetId);
      if (juggle > 0) launchHeight *= 1.3;

      final launchVel = math.sqrt(2.0 * grav * launchHeight);

      if (targetId == 'player') {
        if (gameState.isAirborne) {
          gameState.airborneVelocityY += launchVel;
        } else {
          gameState.airborneVelocityY = launchVel;
        }
        gameState.airborneHeight = math.max(gameState.airborneHeight, 0.01);
        gameState.juggleWindowTimer = 0.0;
      } else if (targetId == 'boss') {
        // Boss is too heavy to launch
      } else {
        // Ally or minion
        final ally = gameState.allies.where((a) => a.name == targetId).firstOrNull;
        if (ally != null) {
          if (ally.isAirborne) {
            ally.airborneVelocityY += launchVel;
          } else {
            ally.airborneVelocityY = launchVel;
          }
          ally.airborneHeight = math.max(ally.airborneHeight, 0.01);
          ally.juggleWindowTimer = 0.0;
        }
        final minion = gameState.minionById(targetId);
        if (minion != null && minion.isAlive) {
          if (minion.isAirborne) {
            minion.airborneVelocityY += launchVel;
          } else {
            minion.airborneVelocityY = launchVel;
          }
          minion.airborneHeight = math.max(minion.airborneHeight, 0.01);
          minion.juggleWindowTimer = 0.0;
        }
      }
      return;

    // ── Composite effect ───────────────────────────────────────────────
    case StatusEffect.knockdown:
      // Reason: knockdown = stun + spell-lockout; both re-use existing CC checks
      // in the AI and duel systems with zero additional changes there.
      var knockdownDur = fx.duration * gameState.activeStance.ccDurationInflicted;
      knockdownDur = _applyStanceCcModifier(gameState, knockdownDur, fx.type);
      knockdownDur = _applyDefensiveStanceCcModifier(gameState, targetId, knockdownDur, fx.type);
      final dur = knockdownDur.clamp(0.1, 30.0);
      for (final ccType in [StatusEffect.stun, StatusEffect.interrupt]) {
        final effect = ActiveEffect(
          type: ccType, remainingDuration: dur, totalDuration: dur,
          strength: 1.0, sourceName: sourceName,
        );
        if (targetId == 'boss') {
          gameState.monsterActiveEffects.add(effect);
        } else {
          final minion = gameState.minionById(targetId);
          if (minion != null && minion.isAlive) minion.activeEffects.add(effect);
        }
      }
      gameState.combatLogMessages.add(CombatLogEntry(
        source: sourceName, action: '$sourceName applied knockdown (${dur.toStringAsFixed(1)}s)',
        type: CombatLogType.debuff,
        target: targetId,
      ));
      return;

    // ── Standard timed effects ─────────────────────────────────────────
    default:
      if (fx.duration <= 0) return;
      var effectiveDuration = fx.duration * gameState.activeStance.ccDurationInflicted;
      // Reason: stance-specific offensive and defensive CC modifiers layer on top
      // of the base ccDurationInflicted multiplier from stance data.
      effectiveDuration = _applyStanceCcModifier(gameState, effectiveDuration, fx.type);
      effectiveDuration = _applyDefensiveStanceCcModifier(gameState, targetId, effectiveDuration, fx.type);
      double damagePerTick = 0;
      double tickInterval = 0;
      if (dotTicks > 0 && dotDamage > 0) {
        tickInterval = effectiveDuration / dotTicks;
        damagePerTick = dotDamage / dotTicks;
      }
      final effect = ActiveEffect(
        type: fx.type,
        remainingDuration: effectiveDuration,
        totalDuration: effectiveDuration,
        strength: fx.strength,
        damagePerTick: damagePerTick,
        tickInterval: tickInterval,
        sourceName: sourceName,
      );
      if (targetId == 'boss') {
        gameState.monsterActiveEffects.add(effect);
      } else {
        final minion = gameState.minionById(targetId);
        if (minion != null && minion.isAlive) minion.activeEffects.add(effect);
      }
      // Reason: CC effects get a detailed log entry with target and duration
      // so players can track CC application in the combat log.
      final isCcEffect = _isCcStatusEffect(fx.type);
      gameState.combatLogMessages.add(CombatLogEntry(
        source: sourceName,
        action: isCcEffect
            ? '$sourceName applied ${fx.type.name} (${effectiveDuration.toStringAsFixed(1)}s)'
            : '$sourceName applied ${fx.type.name}',
        type: isCcEffect ? CombatLogType.debuff : CombatLogType.ability,
        target: targetId,
      ));
  }
}

/// Apply CC, DoT, knockback, grip, or knockdown from a melee ability to the current target.
void _applyMeleeStatusEffect(GameState gameState, AbilityData ability) {
  final targetId = gameState.currentTargetId;
  if (targetId == null) return;

  // Reason: legacy knockbackForce field is honored when no explicit knockback
  // effect is present in statusEffects, preserving existing ability data.
  final hasExplicitKnockback = ability.allStatusEffects
      .any((e) => e.type == StatusEffect.knockback);
  if (ability.knockbackForce > 0 && !hasExplicitKnockback && gameState.activeTransform != null) {
    _displaceTarget(gameState, targetId, _casterForward(gameState) * ability.knockbackForce);
  }

  for (final fx in ability.allStatusEffects) {
    _applySingleStatusEffect(
      gameState, targetId, fx, ability.name,
      dotTicks: ability.dotTicks,
      dotDamage: ability.damage,
    );
  }
}

/// Apply a stacking vulnerability debuff to the current target.
void _applyVulnerability(
  GameState gameState,
  StatusEffect vulnType, {
  bool permanent = false,
  double duration = 6.0,
  String sourceName = '',
}) {
  final targetId = gameState.currentTargetId;
  if (targetId == null || targetId.startsWith('ally_')) return;

  List<ActiveEffect>? effects;
  if (targetId == 'boss') {
    effects = gameState.monsterActiveEffects;
  } else {
    final minion = gameState.minionById(targetId);
    effects = (minion != null && minion.isAlive) ? minion.activeEffects : null;
  }
  if (effects == null) return;

  final existing = effects.where((e) => e.type == vulnType).firstOrNull;
  if (existing != null) {
    if (existing.strength < 5.0) existing.strength += 1.0;
    if (!permanent && !existing.isPermanent) existing.remainingDuration = duration;
    if (permanent) existing.isPermanent = true;
  } else {
    effects.add(ActiveEffect(
      type: vulnType,
      strength: 1.0,
      remainingDuration: permanent ? 999999 : duration,
      totalDuration: permanent ? 999999 : duration,
      isPermanent: permanent,
      sourceName: sourceName,
    ));
  }
}

/// Apply vulnerability based on the ability's damageSchool.
void _applyMeleeVulnerability(GameState gameState, AbilityData ability) {
  if (ability.appliesPermanentVulnerability) {
    _applyVulnerability(gameState, vulnerabilityForSchool(ability.damageSchool),
        permanent: true, sourceName: ability.name);
  } else {
    _applyVulnerability(gameState, StatusEffect.vulnerablePhysical, duration: 6.0, sourceName: ability.name);
  }
}

// ==================== PROJECTILE HIT HELPERS ====================

/// Apply damage from a homing projectile directly to its locked target.
void _damageTargetWithProjectile(GameState gameState, String targetId, Projectile projectile) {
  final effectiveDamage = projectile.damage * gameState.activeStance.damageMultiplier;
  if (targetId == 'boss') {
    CombatSystem.checkAndDamageMonster(
      gameState,
      attackerPosition: gameState.monsterTransform!.position,
      damage: effectiveDamage,
      attackType: projectile.abilityName,
      impactColor: projectile.impactColor,
      impactSize: projectile.impactSize,
      collisionThreshold: 2.0,
      showDamageIndicator: true,
    );
  } else {
    CombatSystem.damageMinion(
      gameState,
      minionInstanceId: targetId,
      damage: effectiveDamage,
      attackType: projectile.abilityName,
      impactColor: projectile.impactColor,
      impactSize: projectile.impactSize,
      showDamageIndicator: true,
    );
  }
  _applyLifesteal(gameState, effectiveDamage);
  _applyDoTFromProjectile(gameState, targetId, projectile);
}

/// Apply status effects from a projectile hit to the target.
void _applyDoTFromProjectile(GameState gameState, String targetId, Projectile projectile) {
  if (projectile.dotTicks <= 0 && projectile.statusEffects.isEmpty) return;

  // Reason: if the projectile has explicit statusEffects entries, apply them all.
  // Legacy path: if dotTicks > 0 but no entries, synthesize a burn DoT (backward compat).
  if (projectile.statusEffects.isNotEmpty) {
    for (final fx in projectile.statusEffects) {
      _applySingleStatusEffect(
        gameState, targetId, fx, projectile.abilityName,
        dotTicks: projectile.dotTicks,
        dotDamage: projectile.damage,
      );
    }
  } else if (projectile.dotTicks > 0) {
    // Legacy single-effect fallback: assume burn DoT
    final burnFx = AbilityStatusEffect(
      type: StatusEffect.burn,
      duration: projectile.lifetime,
      strength: 1.0,
    );
    _applySingleStatusEffect(
      gameState, targetId, burnFx, projectile.abilityName,
      dotTicks: projectile.dotTicks,
      dotDamage: projectile.damage,
    );
  }
}

/// Whether a [StatusEffect] is a crowd-control type for combat log categorization.
/// Reason: CC effects are logged as debuffs with duration info so players can
/// track CC application, whereas non-CC effects (DoTs, buffs) use generic logging.
bool _isCcStatusEffect(StatusEffect type) {
  switch (type) {
    case StatusEffect.stun:
    case StatusEffect.root:
    case StatusEffect.slow:
    case StatusEffect.blind:
    case StatusEffect.fear:
    case StatusEffect.silence:
    case StatusEffect.interrupt:
    case StatusEffect.sleep:
    case StatusEffect.charm:
    case StatusEffect.polymorph:
    case StatusEffect.taunt:
    case StatusEffect.disorient:
    case StatusEffect.grounded:
    case StatusEffect.suppress:
    case StatusEffect.nearsight:
    case StatusEffect.banish:
    case StatusEffect.daze:
    case StatusEffect.freeze:
    case StatusEffect.knockdown:
      return true;
    default:
      return false;
  }
}

/// Whether a [StatusEffect] is a hard CC type (full loss of control).
/// Reason: Tempest defensive modifier only reduces hard CC, not soft CC
/// like slow/blind/nearsight/weakness.
bool _isHardCc(StatusEffect type) {
  switch (type) {
    case StatusEffect.stun:
    case StatusEffect.sleep:
    case StatusEffect.charm:
    case StatusEffect.polymorph:
    case StatusEffect.suppress:
    case StatusEffect.banish:
    case StatusEffect.airborne:
    case StatusEffect.freeze:
    case StatusEffect.knockdown:
    case StatusEffect.fear:
      return true;
    default:
      return false;
  }
}

/// Apply the caster's stance-specific CC duration modifier (offensive).
/// Reason: Each stance rewards different playstyle conditions with CC bonus/penalty.
double _applyStanceCcModifier(GameState gameState, double baseDuration, StatusEffect type) {
  final ccCfg = globalCcConfig;
  final stance = gameState.activeStance;
  final rt = gameState.stanceRuntime;
  var dur = baseDuration;

  switch (stance.id) {
    case StanceId.cadence:
      // Reason: on-beat casts reward timing skill with longer CC
      if (rt.cadenceLastCastOnBeat) {
        dur *= 1.0 + (ccCfg?.cadenceOnBeatCcDurationBonus ?? 0.25);
      }
    case StanceId.tempest:
      // Reason: Tempest rewards cancel chains; solo casts get a penalty
      if (rt.tempestChainDepth < 1) {
        dur *= 1.0 - (ccCfg?.tempestNonChainCcDurationPenalty ?? 0.15);
      }
    case StanceId.warden:
      // Reason: Predator's Eye rewards patient setup with stronger CC
      final activationTime = stance.mechanics?.predatorActivationTime ?? 0.0;
      if (activationTime > 0 && rt.wardenPredatorTimer >= activationTime) {
        dur *= 1.0 + (ccCfg?.wardenPredatorCcDurationBonus ?? 0.40);
      }
    case StanceId.crucible:
      // Reason: 0-heat payoff rewards disciplined heat management
      if (rt.crucibleHeatStacks == 0) {
        dur *= 1.0 + (ccCfg?.crucibleZeroheatCcDurationBonus ?? 0.50);
      }
    case StanceId.flux:
      // Reason: transition bonus rewards active stance-switching
      if (rt.fluxTransitionBonusAvailable) {
        dur *= 1.0 + (ccCfg?.fluxTransitionCcDurationBonus ?? 0.30);
      }
    default:
      break;
  }
  return dur;
}

/// Apply the target's stance-specific defensive CC modifier.
/// Reason: Certain stances reduce (or increase) incoming CC on the player.
/// Only applies when the target is the player (boss/minions have no stance).
double _applyDefensiveStanceCcModifier(
    GameState gameState, String targetId, double baseDuration, StatusEffect type) {
  // Reason: Only the player has stance state; boss/minions skip this.
  if (targetId != 'player') return baseDuration;

  final ccCfg = globalCcConfig;
  final stance = gameState.activeStance;
  final rt = gameState.stanceRuntime;
  var dur = baseDuration;

  // Tempest defender: reduce incoming hard CC
  if (stance.id == StanceId.tempest && _isHardCc(type)) {
    dur *= 1.0 - (ccCfg?.tempestIncomingHardCcReduction ?? 0.20);
  }

  // Flux stagnation: increased incoming CC when stagnant
  if (stance.id == StanceId.flux && rt.fluxStagnationTimer > 5.0) {
    dur *= 1.0 + (ccCfg?.fluxStagnationCcDurationPenalty ?? 0.25);
  }

  return dur;
}

/// Resolve the current target's armor category for weapon effectiveness.
ArmorCategory _getTargetArmorCategory(GameState gameState) {
  final targetId = gameState.currentTargetId;
  if (targetId == null) return ArmorCategory.unarmored;
  if (targetId == 'boss') {
    return gameState.monsterArmorCategory;
  }
  for (final minion in gameState.aliveMinions) {
    if (minion.instanceId == targetId) {
      return minion.definition.armorCategory ?? ArmorCategory.unarmored;
    }
  }
  return ArmorCategory.unarmored;
}
