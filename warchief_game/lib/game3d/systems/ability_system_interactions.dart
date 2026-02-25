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
    gameState.combatLogMessages.add(CombatLogEntry(
      source: 'Player', action: 'Lifesteal', type: CombatLogType.heal,
      amount: healed, target: 'Player',
    ));
    if (gameState.combatLogMessages.length > 250) {
      gameState.combatLogMessages.removeRange(0, gameState.combatLogMessages.length - 200);
    }
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
  print(message);
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

/// Generic melee attack — gap-closer if range >= [_gapCloserRangeThreshold].
void _executeGenericMelee(int slotIndex, GameState gameState, AbilityData rawAbility, String message) {
  final ability = globalAbilityOverrideManager?.getEffectiveAbility(rawAbility) ?? rawAbility;
  if (ability.range >= _gapCloserRangeThreshold && ability.type != AbilityType.aoe) {
    _startDash(slotIndex, gameState, ability, message);
    return;
  }
  if (gameState.ability1Active) return;
  gameState.activeGenericMeleeAbility = ability;
  gameState.ability1Active = true;
  gameState.ability1ActiveTime = 0.0;
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  gameState.ability1HitRegistered = false;
  print(message);
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
    statusEffect: ability.statusEffect,
    statusDuration: ability.statusDuration > 0 ? ability.statusDuration : ability.duration,
    dotTicks: ability.dotTicks,
  ));
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  print('$message${targetId != null ? " (targeting $targetId)" : ""}');
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
  final aoeDamage = ability.damage * gameState.activeStance.damageMultiplier;
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
  print(message);
}

/// Generic heal — applies to the current friendly target (ally) or self if no friendly is targeted.
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
      print('$message Restored ${healedAmount.toStringAsFixed(1)} HP to ${ally.name}');
      return;
    }
  }

  // Self-heal (no target, self-target, or invalid ally target)
  final oldHealth = gameState.activeHealth;
  gameState.activeHealth = math.min(gameState.activeMaxHealth, gameState.activeHealth + effectiveHeal);
  final healedAmount = gameState.activeHealth - oldHealth;
  _logHeal(gameState, ability.name, healedAmount);
  _showHealIndicator(gameState, healedAmount, gameState.activeTransform?.position);
  print('$message Restored ${healedAmount.toStringAsFixed(1)} HP');
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
      print('${ability.name} activated!');
      break;
  }
}

// ==================== STATUS EFFECTS ====================

/// Apply CC, DoT, and knockback from a melee ability to the current target.
void _applyMeleeStatusEffect(GameState gameState, AbilityData ability) {
  if (ability.statusEffect == StatusEffect.none && ability.knockbackForce <= 0) return;
  final targetId = gameState.currentTargetId;
  if (targetId == null) return;

  // Knockback
  if (ability.knockbackForce > 0 && gameState.activeTransform != null) {
    final forward = Vector3(
      -math.sin(_radians(gameState.activeRotation)), 0,
      -math.cos(_radians(gameState.activeRotation)),
    );
    if (targetId == 'boss' && gameState.monsterTransform != null) {
      gameState.monsterTransform!.position += forward * ability.knockbackForce;
    } else {
      final minion = gameState.minions.where((m) => m.instanceId == targetId && m.isAlive).firstOrNull;
      if (minion != null) minion.transform.position += forward * ability.knockbackForce;
    }
  }

  // Status effect
  if (ability.statusEffect != StatusEffect.none && ability.statusDuration > 0) {
    final effectiveDuration = ability.statusDuration * gameState.activeStance.ccDurationInflicted;
    double damagePerTick = 0;
    double tickInterval = 0;
    if (ability.dotTicks > 0) {
      tickInterval = effectiveDuration / ability.dotTicks;
      damagePerTick = ability.damage / ability.dotTicks;
    }
    final effect = ActiveEffect(
      type: ability.statusEffect,
      remainingDuration: effectiveDuration,
      totalDuration: effectiveDuration,
      strength: ability.statusStrength > 0 ? ability.statusStrength : 1.0,
      damagePerTick: damagePerTick,
      tickInterval: tickInterval,
      sourceName: ability.name,
    );
    if (targetId == 'boss') {
      gameState.monsterActiveEffects.add(effect);
    } else {
      final minion = gameState.minions.where((m) => m.instanceId == targetId && m.isAlive).firstOrNull;
      if (minion != null) minion.activeEffects.add(effect);
    }
    gameState.combatLogMessages.add(CombatLogEntry(
      source: ability.name,
      action: '${ability.name} applied ${ability.statusEffect.name}',
      type: CombatLogType.ability,
    ));
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
    final minion = gameState.minions.where((m) => m.instanceId == targetId && m.isAlive).firstOrNull;
    effects = minion?.activeEffects;
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

/// Create a DoT ActiveEffect on the target from a projectile's DoT data.
void _applyDoTFromProjectile(GameState gameState, String targetId, Projectile projectile) {
  if (projectile.dotTicks <= 0 || projectile.statusDuration <= 0) return;
  final statusType = projectile.statusEffect != StatusEffect.none
      ? projectile.statusEffect
      : StatusEffect.burn;
  final effectiveDuration = projectile.statusDuration * gameState.activeStance.ccDurationInflicted;
  final tickInterval = effectiveDuration / projectile.dotTicks;
  final damagePerTick = projectile.damage / projectile.dotTicks;
  final effect = ActiveEffect(
    type: statusType,
    remainingDuration: effectiveDuration,
    totalDuration: effectiveDuration,
    damagePerTick: damagePerTick,
    tickInterval: tickInterval,
    sourceName: projectile.abilityName,
  );
  if (targetId == 'boss') {
    gameState.monsterActiveEffects.add(effect);
  } else {
    final minion = gameState.minions.where((m) => m.instanceId == targetId).firstOrNull;
    if (minion != null) minion.activeEffects.add(effect);
  }
}
