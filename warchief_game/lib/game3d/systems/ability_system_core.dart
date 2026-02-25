part of 'ability_system.dart';

// ==================== MUTABLE STATE ====================

/// Accumulated time for channel tick damage/heal (1 tick per second).
double _channelTickAccum = 0.0;

// ==================== CORE HELPERS ====================

/// Apply user overrides (from the Codex editor) to a raw ability definition.
AbilityData _effective(AbilityData raw) =>
    globalAbilityOverrideManager?.getEffectiveAbility(raw) ?? raw;

// ==================== COOLDOWN UPDATE ====================

/// Decrement cooldown timers for Warchief and all allies each frame.
void _updateCooldowns(double dt, GameState gameState) {
  final wCds = gameState.abilityCooldowns;
  for (int i = 0; i < wCds.length; i++) {
    if (wCds[i] > 0) wCds[i] -= dt;
  }
  if (gameState.gcdRemaining > 0) gameState.gcdRemaining -= dt;
  for (final ally in gameState.allies) {
    final aCds = ally.abilityCooldowns;
    for (int i = 0; i < aCds.length; i++) {
      if (aCds[i] > 0) aCds[i] -= dt;
    }
    if (ally.gcdRemaining > 0) ally.gcdRemaining -= dt;
  }
}

// ==================== CAST STATE ====================

/// Advance the cast bar; fire the ability when fully cast.
void _updateCastingState(double dt, GameState gameState) {
  if (!gameState.isCasting) return;

  gameState.castProgress += dt;

  if (gameState.castProgress >= gameState.currentCastTime) {
    final slotIndex = gameState.castingSlotIndex;
    final abilityName = gameState.castingAbilityName;
    final configuredTime = gameState.currentCastTime;

    gameState.castProgress = configuredTime;
    gameState.isCasting = false;
    gameState.castProgress = 0.0;
    gameState.currentCastTime = 0.0;
    gameState.castingSlotIndex = null;
    gameState.castingAbilityName = '';

    gameState.combatLogMessages.add(CombatLogEntry(
      source: 'Player',
      action: '$abilityName cast (${configuredTime.toStringAsFixed(2)}s)',
      type: CombatLogType.ability,
    ));
    if (gameState.combatLogMessages.length > 250) {
      gameState.combatLogMessages.removeRange(0, gameState.combatLogMessages.length - 200);
    }

    print('[CAST] $abilityName cast complete! (${configuredTime.toStringAsFixed(2)}s)');
    if (slotIndex != null) {
      _finishCastTimeAbility(slotIndex, gameState);
    }
  }
}

// ==================== WINDUP STATE ====================

/// Advance the windup; fire the melee ability when windup completes.
void _updateWindupState(double dt, GameState gameState) {
  if (!gameState.isWindingUp) return;

  gameState.windupProgress += dt;

  if (gameState.windupProgress >= gameState.currentWindupTime) {
    final slotIndex = gameState.windupSlotIndex;
    final abilityName = gameState.windupAbilityName;
    final configuredTime = gameState.currentWindupTime;

    gameState.windupProgress = configuredTime;
    gameState.isWindingUp = false;
    gameState.windupProgress = 0.0;
    gameState.currentWindupTime = 0.0;
    gameState.windupSlotIndex = null;
    gameState.windupAbilityName = '';
    gameState.windupMovementSpeedModifier = 1.0;

    gameState.combatLogMessages.add(CombatLogEntry(
      source: 'Player',
      action: '$abilityName windup (${configuredTime.toStringAsFixed(2)}s)',
      type: CombatLogType.ability,
    ));
    if (gameState.combatLogMessages.length > 250) {
      gameState.combatLogMessages.removeRange(0, gameState.combatLogMessages.length - 200);
    }

    print('[WINDUP] $abilityName windup complete! (${configuredTime.toStringAsFixed(2)}s)');
    if (slotIndex != null) {
      _finishWindupAbility(slotIndex, gameState);
    }
  }
}

// ==================== CHANNEL STATE ====================

/// Advance the channel bar and apply periodic ticks; end when duration expires.
void _updateChannelingState(double dt, GameState gameState) {
  if (!gameState.isChanneling) return;

  gameState.channelProgress += dt;
  _channelTickAccum += dt;

  // Reason: Tick damage/heal once per second during the channel
  const tickInterval = 1.0;
  while (_channelTickAccum >= tickInterval && gameState.isChanneling) {
    _channelTickAccum -= tickInterval;
    _applyChannelTick(gameState);
  }

  if (gameState.channelProgress >= gameState.channelDuration) {
    final abilityName = gameState.channelingAbilityName;
    gameState.cancelChannel();
    _channelTickAccum = 0.0;
    gameState.addConsoleLog('$abilityName channel complete');
  }
}

/// Apply one tick of the channeled ability's effect (damage or heal).
void _applyChannelTick(GameState gameState) {
  final abilityName = gameState.channelingAbilityName;
  final abilityData = AbilityRegistry.findByName(abilityName);
  if (abilityData == null) return;
  final effective = _effective(abilityData);
  final duration = effective.duration > 0 ? effective.duration : 1.0;
  final ticks = duration.round();

  if (effective.damage > 0) {
    final tickDmg = effective.damage / ticks;
    _autoHitCurrentTarget(
      gameState,
      damage: tickDmg,
      attackType: '$abilityName tick',
      impactColor: effective.impactColor,
      impactSize: effective.impactSize,
    );
  }
  if (effective.healAmount > 0) {
    final tickHeal = effective.healAmount / ticks;
    final oldHealth = gameState.activeHealth;
    gameState.activeHealth = math.min(gameState.activeMaxHealth, gameState.activeHealth + tickHeal);
    final healed = gameState.activeHealth - oldHealth;
    if (healed > 0 && gameState.activeTransform != null) {
      final pos = gameState.activeTransform!.position.clone();
      pos.y += 2.0;
      gameState.damageIndicators.add(DamageIndicator(
        damage: healed,
        worldPosition: pos,
        isHeal: true,
      ));
    }
  }
}

/// Start a channeled ability — player is rooted for the duration while effects tick.
void _startChanneledAbility(AbilityData ability, int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  gameState.isChanneling = true;
  gameState.channelProgress = 0.0;
  gameState.channelDuration = ability.duration;
  gameState.channelingAbilityName = ability.name;
  gameState.channelingSlotIndex = slotIndex;
  _channelTickAccum = 0.0;
  gameState.addConsoleLog('Channeling ${ability.name} (${ability.duration.toStringAsFixed(0)}s)');
}

// ==================== CAST / WINDUP FINISH ====================

/// Execute the effect of a cast-time ability after the cast bar completes.
void _finishCastTimeAbility(int slotIndex, GameState gameState) {
  final config = globalActionBarConfig;
  final abilityName = config?.getSlotAbility(slotIndex) ?? '';
  final abilityData = config?.getSlotAbilityData(slotIndex);

  _spendPendingMana(gameState, abilityName);
  _setCooldownForSlot(slotIndex, abilityData?.cooldown ?? _getAbilityCooldown(abilityName), gameState);

  switch (abilityName) {
    case 'Lightning Bolt':
      _launchLightningBolt(slotIndex, gameState);
      break;
    case 'Pyroblast':
      _launchPyroblast(slotIndex, gameState);
      break;
    case 'Arcane Missile':
      _launchArcaneMissile(slotIndex, gameState);
      break;
    case 'Frost Nova':
      _executeFrostNovaEffect(slotIndex, gameState);
      break;
    case 'Greater Heal':
      _executeGreaterHealEffect(slotIndex, gameState);
      break;
    default:
      _executeGenericProjectileFromAbility(slotIndex, gameState, abilityName);
  }
}

/// Execute the effect of a windup melee ability after the windup completes.
void _finishWindupAbility(int slotIndex, GameState gameState) {
  final config = globalActionBarConfig;
  final abilityName = config?.getSlotAbility(slotIndex) ?? '';
  final abilityData = config?.getSlotAbilityData(slotIndex);

  _spendPendingMana(gameState, abilityName);
  _setCooldownForSlot(slotIndex, abilityData?.cooldown ?? _getAbilityCooldown(abilityName), gameState);

  switch (abilityName) {
    case 'Heavy Strike':
      _executeHeavyStrikeEffect(slotIndex, gameState);
      break;
    case 'Whirlwind':
      _executeWhirlwindEffect(slotIndex, gameState);
      break;
    case 'Crushing Blow':
      _executeCrushingBlowEffect(slotIndex, gameState);
      break;
    default:
      _executeGenericWindupMelee(slotIndex, gameState, abilityName);
  }
}

// ==================== CAST / WINDUP START ====================

/// Begin a cast-time ability (applies Haste and stance cast time multiplier).
void _startCastTimeAbility(AbilityData abilityData, int slotIndex, GameState gameState) {
  final haste = gameState.activeHaste;
  double castTime = haste > 0
      ? abilityData.castTime / (1 + haste / 100.0)
      : abilityData.castTime;
  castTime *= gameState.activeStance.castTimeMultiplier;

  gameState.isCasting = true;
  gameState.castProgress = 0.0;
  gameState.castPushbackCount = 0;
  gameState.currentCastTime = castTime;
  gameState.castingSlotIndex = slotIndex;
  gameState.castingAbilityName = abilityData.name;

  print('[CAST] Starting ${abilityData.name} (${castTime.toStringAsFixed(2)}s cast time${haste > 0 ? ', $haste% haste' : ''})');
}

/// Begin a windup melee ability (applies Haste and stance cast time multiplier).
void _startWindupAbility(AbilityData abilityData, int slotIndex, GameState gameState) {
  final haste = gameState.activeHaste;
  double windupTime = haste > 0
      ? abilityData.windupTime / (1 + haste / 100.0)
      : abilityData.windupTime;
  windupTime *= gameState.activeStance.castTimeMultiplier;

  gameState.isWindingUp = true;
  gameState.windupProgress = 0.0;
  gameState.currentWindupTime = windupTime;
  gameState.windupSlotIndex = slotIndex;
  gameState.windupAbilityName = abilityData.name;
  gameState.windupMovementSpeedModifier = abilityData.windupMovementSpeed;

  print('[WINDUP] Starting ${abilityData.name} (${windupTime.toStringAsFixed(2)}s windup${haste > 0 ? ', $haste% haste' : ''}, ${(abilityData.windupMovementSpeed * 100).toInt()}% movement)');
}
