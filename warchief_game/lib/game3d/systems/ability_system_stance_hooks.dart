part of 'ability_system.dart';

// ==================== STANCE MECHANIC HOOKS ====================
//
// These functions are called from the ability dispatch pipeline to apply
// the effects of advanced stances (Cadence, Tempest, Warden, Crucible,
// Momentum, Pressure, Flux). See STANCE_REVAMP.md for full design docs.

/// Apply all pre-execution stance modifications to an ability.
///
/// Called from [_executeAbilityByName] after mana checks pass but before
/// the ability actually fires. Returns a modified [_StanceAbilityMods]
/// containing adjustments to mana cost, cooldown, damage, cast time, etc.
_StanceAbilityMods _computeStanceMods(
  GameState gameState,
  AbilityData? abilityData,
  String abilityName,
  int slotIndex,
  double baseMana,
) {
  final stance = gameState.activeStance;
  final m = stance.mechanics;
  final s = gameState.stanceRuntime;
  final mods = _StanceAbilityMods();
  if (m == null) return mods;

  switch (gameState.playerStance) {
    case StanceId.cadence:
      _applyCadenceMods(m, s, mods, baseMana);
    case StanceId.tempest:
      _applyTempestMods(m, s, mods);
    case StanceId.warden:
      _applyWardenMods(m, s, mods);
    case StanceId.crucible:
      _applyCrucibleMods(m, s, mods, baseMana, gameState);
    case StanceId.momentum:
      _applyMomentumMods(m, s, mods);
    case StanceId.flux:
      _applyFluxMods(m, s, mods, baseMana);
    default:
      break;
  }
  return mods;
}

/// Notify stance system that an ability hit a target.
///
/// Called from damage application in [_autoHitCurrentTarget] and AoE paths.
void _notifyStanceOnHit(
  GameState gameState,
  AbilityData ability,
  int targetEntityId, {
  bool isDot = false,
  int targetsHit = 1,
  bool isCrit = false,
  bool isComboPrimed = false,
}) {
  final m = gameState.activeStance.mechanics;
  final s = gameState.stanceRuntime;
  if (m == null) return;

  switch (gameState.playerStance) {
    case StanceId.tempest:
      StanceRuntimeSystem.onTempestHit(m, s);
    case StanceId.momentum:
      StanceRuntimeSystem.onMomentumHit(
        m, s, ability.type,
        isAoeMultiHit: targetsHit >= 3,
        isComboPrimed: isComboPrimed,
      );
    case StanceId.pressure:
      final isMelee = ability.type == AbilityType.melee;
      final dominantSchool = s.getDominantSchool(targetEntityId);
      final broke = StanceRuntimeSystem.onPressureHit(
        m, s, targetEntityId, ability.damageSchool,
        isMelee: isMelee,
        isDot: isDot,
        hasWindup: ability.hasWindup,
      );
      if (broke) {
        _applyPressureBreak(gameState, m, dominantSchool);
      }
    case StanceId.crucible:
      if (isCrit) StanceRuntimeSystem.onCrucibleCrit(s);
    case StanceId.flux:
      StanceRuntimeSystem.recordFluxMemory(m, s, ability.name);
    default:
      break;
  }
}

/// Notify stance system that an ability was cast (for Crucible heat tracking).
///
/// Called right after the ability fires in the dispatch pipeline.
/// Returns true if the ability should be silenced (Crucible Overheat).
bool _notifyStanceOnCast(GameState gameState) {
  final m = gameState.activeStance.mechanics;
  final s = gameState.stanceRuntime;
  if (m == null) return false;

  if (gameState.playerStance == StanceId.crucible) {
    return StanceRuntimeSystem.onCrucibleCast(m, s);
  }
  return false;
}

// ==================== PER-STANCE MOD COMPUTATION ====================

void _applyCadenceMods(
  StanceMechanics m,
  StanceRuntimeState s,
  _StanceAbilityMods mods,
  double baseMana,
) {
  final onBeat = StanceRuntimeSystem.checkCadenceBeat(m, s);
  if (onBeat) {
    mods.damageMultiplier *= 1.0 + m.rhythmDamageBonus;
    mods.cooldownMultiplier *= 1.0 - m.rhythmCooldownRefund;
    mods.manaRefund = baseMana * m.rhythmManaRefund;
    devLog(() => '[CADENCE] On-beat! +${(m.rhythmDamageBonus * 100).round()}% dmg, '
        'Groove: ${s.cadenceGrooveStacks}');
  }
  // Groove haste stacks applied additively to effective haste
  if (s.cadenceGrooveStacks > 0) {
    mods.bonusHaste += s.cadenceGrooveStacks * m.grooveHastePerStack * 100;
  }
}

void _applyTempestMods(
  StanceMechanics m,
  StanceRuntimeState s,
  _StanceAbilityMods mods,
) {
  // Cancel window: if in cancel window, skip GCD
  if (s.tempestInCancelWindow) {
    mods.skipGcd = StanceRuntimeSystem.consumeTempestCancel(m, s);
    if (mods.skipGcd) {
      devLog(() => '[TEMPEST] Cancel chain! Depth: ${s.tempestChainDepth}');
    }
  }
  // Chain damage scale
  final chainScale = StanceRuntimeSystem.getTempestChainScale(m, s);
  if (chainScale != 1.0) {
    mods.damageMultiplier *= chainScale;
  }
  // Windup/cast time reduction
  mods.windupReduction = m.windupReduction;
  mods.castTimeReduction = m.castTimeReduction;
}

void _applyWardenMods(
  StanceMechanics m,
  StanceRuntimeState s,
  _StanceAbilityMods mods,
) {
  final dir = s.wardenInputTimer > 0
      ? s.wardenLastDirection
      : WardenDirection.stationary;

  // Predator's Eye: all bonuses at once
  if (s.wardenInPredatorMode) {
    mods.damageMultiplier *= 1.0 + m.movementForwardDamageBonus +
        m.movementStationaryDamageBonus;
    mods.rangeMultiplier *= 1.0 + m.movementForwardRangeBonus;
    mods.aoeRadiusMultiplier *= 1.0 + m.movementStationaryAoeBonus;
    mods.bonusDodge += m.movementStrafeDodgeBonus;
    mods.piercing = m.movementStrafePiercing;
    mods.applyExposed = true;
    mods.exposedDuration = m.predatorExposedDuration;
    mods.exposedDamageBonus = m.predatorExposedDamageBonus;
    s.wardenInPredatorMode = false;
    s.wardenInCombat = true;
    s.wardenCombatTimer = 0.0;
    devLog(() => '[WARDEN] Predator\'s Eye STRIKE! All bonuses applied');
    return;
  }

  s.wardenInCombat = true;
  s.wardenCombatTimer = 0.0;

  switch (dir) {
    case WardenDirection.forward:
      mods.rangeMultiplier *= 1.0 + m.movementForwardRangeBonus;
      mods.damageMultiplier *= 1.0 + m.movementForwardDamageBonus;
    case WardenDirection.backward:
      mods.damageReductionWindow = m.movementBackwardDamageReduction;
      mods.knockbackMultiplier *= 1.0 + m.movementBackwardKnockbackBonus;
    case WardenDirection.strafeLeft || WardenDirection.strafeRight:
      mods.bonusDodge += m.movementStrafeDodgeBonus;
      mods.piercing = m.movementStrafePiercing;
    case WardenDirection.stationary:
      mods.damageMultiplier *= 1.0 + m.movementStationaryDamageBonus;
      mods.aoeRadiusMultiplier *= 1.0 + m.movementStationaryAoeBonus;
    case WardenDirection.sprint:
      mods.knockbackMultiplier *= 2.0;
      mods.rangeMultiplier *= 1.0 + m.movementForwardRangeBonus;
    case WardenDirection.none:
      break;
  }
}

void _applyCrucibleMods(
  StanceMechanics m,
  StanceRuntimeState s,
  _StanceAbilityMods mods,
  double baseMana,
  GameState gameState,
) {
  if (s.crucibleOverheated) {
    mods.silenced = true;
    return;
  }

  // 0-Heat payoff bonus
  if (s.crucibleAtZeroHeat) {
    mods.damageMultiplier *= 1.0 + m.coolDownPayoffDamageBonus;
    devLog(() => '[CRUCIBLE] 0-Heat opener! +${(m.coolDownPayoffDamageBonus * 100).round()}% damage');
  }

  // Heat mana cost escalation
  if (s.crucibleHeatStacks > 0) {
    mods.manaCostMultiplier *= 1.0 + (s.crucibleHeatStacks * m.heatManaCostPerStack);
  }
}

void _applyMomentumMods(
  StanceMechanics m,
  StanceRuntimeState s,
  _StanceAbilityMods mods,
) {
  if (s.momentumStacks <= 0) return;
  final stacks = s.momentumStacks;
  mods.damageMultiplier *= 1.0 + (stacks * m.momentumDamagePerStack);
  mods.cooldownMultiplier *= 1.0 - (stacks * m.momentumCooldownPerStack);
  mods.aoeRadiusMultiplier *= 1.0 + (stacks * m.momentumAoePerStack);
  mods.bonusHaste += stacks * m.momentumCastPerStack * 100;

  // Max-stack splash
  if (stacks >= m.momentumMaxStacks && m.momentumSplashAtMax) {
    mods.splashDamageRatio = m.momentumSplashRatio;
    mods.splashRadius = m.momentumSplashRadius;
  }

  // Kinetic Overflow: cross-domain bonus at max stacks
  if (stacks >= m.momentumMaxStacks && m.kineticOverflowBonus > 0) {
    mods.kineticOverflowBonus = m.kineticOverflowBonus;
    mods.kineticLastType = s.momentumLastAbilityType;
  }
}

void _applyFluxMods(
  StanceMechanics m,
  StanceRuntimeState s,
  _StanceAbilityMods mods,
  double baseMana,
) {
  // Transition bonus
  if (s.fluxTransitionBonusAvailable) {
    final consumed = StanceRuntimeSystem.consumeFluxTransition(m, s);
    if (consumed) {
      mods.damageMultiplier *= 1.0 + m.transitionBonusDamage;
      if (m.transitionInstantCast) mods.forceInstant = true;
      if (m.transitionNoManaCost) mods.manaRefund = baseMana;
      devLog(() => '[FLUX] Transition bonus consumed! +${(m.transitionBonusDamage * 100).round()}% dmg');
    }
  }

  // Stagnation penalty
  if (s.fluxStagnant) {
    mods.damageMultiplier *= 1.0 - m.stagnationDamageReduction;
  }

  // Weave State bonus
  if (s.fluxWeaveActive) {
    mods.damageMultiplier *= 1.0 + m.weaveBonusMultiplier;
    mods.cooldownMultiplier *= 1.0 - m.weaveBonusMultiplier;
    mods.aoeRadiusMultiplier *= 1.0 + m.weaveBonusMultiplier;
  }
}

// ==================== STANCE MODS DATA CLASS ====================

/// Aggregated modifications from the active stance for a single ability cast.
class _StanceAbilityMods {
  double damageMultiplier = 1.0;
  double cooldownMultiplier = 1.0;
  double manaCostMultiplier = 1.0;
  double rangeMultiplier = 1.0;
  double aoeRadiusMultiplier = 1.0;
  double knockbackMultiplier = 1.0;
  double manaRefund = 0.0;
  double bonusHaste = 0.0;
  double bonusDodge = 0.0;
  bool skipGcd = false;
  bool silenced = false;
  bool piercing = false;
  bool forceInstant = false;

  // Warden Predator's Eye
  bool applyExposed = false;
  double exposedDuration = 0.0;
  double exposedDamageBonus = 0.0;

  // Warden backward
  double damageReductionWindow = 0.0;

  // Tempest
  double windupReduction = 0.0;
  double castTimeReduction = 0.0;

  // Momentum splash
  double splashDamageRatio = 0.0;
  double splashRadius = 0.0;

  // Momentum kinetic overflow
  double kineticOverflowBonus = 0.0;
  AbilityType? kineticLastType;
}

// ==================== EFFECT APPLICATION ====================

/// Apply Pressure Break effects to the current target.
void _applyPressureBreak(
  GameState gameState,
  StanceMechanics m,
  DamageSchool? dominantSchool,
) {
  final targetId = gameState.currentTargetId;
  if (targetId == null) return;

  final school = dominantSchool ?? DamageSchool.physical;

  // Determine break type and apply stun/CC
  double stunDuration = m.pressureBreakStunDuration;
  String breakName;
  switch (school) {
    case DamageSchool.frost:
      breakName = 'Deep Freeze';
      stunDuration = 3.0;
      _applyEffectToTarget(gameState, targetId, StatusEffect.freeze, stunDuration, 'Pressure Break');
      _applyEffectToTarget(gameState, targetId, StatusEffect.slow, 5.0, 'Pressure Break', strength: 0.4);
    case DamageSchool.shadow:
      breakName = 'Void Collapse';
      _applyEffectToTarget(gameState, targetId, StatusEffect.stun, stunDuration, 'Pressure Break');
      _applyEffectToTarget(gameState, targetId, StatusEffect.silence, 4.0, 'Pressure Break');
    default:
      breakName = school == DamageSchool.fire ? 'Ignition'
          : school == DamageSchool.lightning ? 'Overload'
          : 'Shatter';
      _applyEffectToTarget(gameState, targetId, StatusEffect.stun, stunDuration, 'Pressure Break');
  }

  // Damage amp: apply vulnerability for the dominant school
  _applyEffectToTarget(
    gameState, targetId,
    vulnerabilityForSchool(school),
    stunDuration,
    'Pressure Break',
    strength: m.pressureBreakDamageBonus,
  );

  // Reset all cooldowns
  if (m.pressureBreakResetsAllCooldowns) {
    final cds = gameState.activeAbilityCooldowns;
    for (int i = 0; i < cds.length; i++) {
      cds[i] = 0.0;
    }
    gameState.gcdRemaining = 0.0;
  }

  gameState.addCombatLog(CombatLogEntry(
    source: 'Pressure',
    action: '$breakName BREAK! (${school.name} dominant)',
    type: CombatLogType.ability,
  ));
  gameState.addConsoleLog('PRESSURE BREAK: $breakName!');
  devLog(() => '[PRESSURE] $breakName break applied to $targetId');
}

/// Apply a StatusEffect to a target entity by string ID.
void _applyEffectToTarget(
  GameState gameState,
  String targetId,
  StatusEffect type,
  double duration,
  String source, {
  double strength = 1.0,
}) {
  final effect = ActiveEffect(
    type: type,
    remainingDuration: duration,
    totalDuration: duration,
    strength: strength,
    sourceName: source,
  );
  if (targetId == 'boss') {
    gameState.monsterActiveEffects.add(effect);
  } else {
    final minion = gameState.minionById(targetId);
    if (minion != null && minion.isAlive) minion.activeEffects.add(effect);
  }
}

/// Apply Warden Exposed debuff after Predator's Eye first strike.
void _applyWardenExposed(GameState gameState, _StanceAbilityMods mods) {
  if (!mods.applyExposed) return;
  final targetId = gameState.currentTargetId;
  if (targetId == null) return;
  _applyEffectToTarget(
    gameState, targetId,
    StatusEffect.vulnerablePhysical,
    mods.exposedDuration,
    'Predator\'s Eye',
    strength: mods.exposedDamageBonus,
  );
  gameState.addConsoleLog('Predator\'s Eye: target Exposed!');
}

/// Apply Crucible Overheat — interrupt active casts/channels and apply silence.
void _applyCrucibleOverheat(GameState gameState, double duration) {
  if (gameState.isCasting) gameState.cancelCast();
  if (gameState.isChanneling) gameState.cancelChannel();
  gameState.playerActiveEffects.add(ActiveEffect(
    type: StatusEffect.silence,
    remainingDuration: duration,
    totalDuration: duration,
    strength: 1.0,
    sourceName: 'Crucible Overheat',
  ));
}

/// Apply Momentum splash damage to nearby enemies (at max stacks).
void _applyMomentumSplash(
  GameState gameState,
  double baseDamage,
  double splashRatio,
  double splashRadius,
  Vector3 impactColor,
) {
  if (splashRatio <= 0 || splashRadius <= 0) return;
  final playerPos = gameState.activeTransform?.position;
  if (playerPos == null) return;
  final splashDmg = baseDamage * splashRatio;

  // Splash to nearby minions
  for (final minion in gameState.aliveMinions) {
    final dist = (minion.transform.position - playerPos).length;
    if (dist <= splashRadius && minion.instanceId != gameState.currentTargetId) {
      CombatSystem.damageMinion(
        gameState,
        minionInstanceId: minion.instanceId,
        damage: splashDmg,
        attackType: 'Momentum splash',
        impactColor: impactColor,
        impactSize: 0.3,
        showDamageIndicator: true,
      );
    }
  }

  // Splash to boss if nearby and not primary target
  if (gameState.currentTargetId != 'boss' &&
      gameState.monsterHealth > 0 &&
      gameState.monsterTransform != null) {
    final dist = (gameState.monsterTransform!.position - playerPos).length;
    if (dist <= splashRadius) {
      CombatSystem.checkAndDamageMonster(
        gameState,
        attackerPosition: playerPos,
        damage: splashDmg,
        attackType: 'Momentum splash',
        impactColor: impactColor,
        impactSize: 0.3,
        collisionThreshold: 999.0,
        showDamageIndicator: true,
      );
    }
  }
}

/// Apply Momentum Kinetic Overflow cross-domain bonus.
/// Returns the bonus damage multiplier if the ability type crosses domains.
double _computeKineticOverflow(_StanceAbilityMods mods, AbilityType currentType) {
  if (mods.kineticOverflowBonus <= 0 || mods.kineticLastType == null) return 1.0;
  final last = mods.kineticLastType!;
  final isMelee = currentType == AbilityType.melee;
  final lastWasMelee = last == AbilityType.melee;
  final isHeal = currentType == AbilityType.heal;

  // Cross-domain: melee after ranged, ranged after melee, or heal after anything
  if ((isMelee && !lastWasMelee) || (!isMelee && !isHeal && lastWasMelee) || isHeal) {
    devLog(() => '[MOMENTUM] Kinetic Overflow! ${last.name} -> ${currentType.name}');
    return 1.0 + mods.kineticOverflowBonus;
  }
  return 1.0;
}

