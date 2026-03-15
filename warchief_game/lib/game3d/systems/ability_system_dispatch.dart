part of 'ability_system.dart';

// ==================== ABILITY QUEUE ====================

/// True while the queue drain is executing so queued abilities don't
/// re-enqueue themselves on a soft failure, which would be an infinite loop.
bool _isDrainingQueue = false;

/// Attempt to add [slotIndex] to the execution queue.
/// Rejects silently if draining, queue is full, or a hard requirement is unmet.
void _tryEnqueue(int slotIndex, GameState gameState) {
  if (_isDrainingQueue) return;
  if (gameState.abilityQueue.length >= 5) return;
  final config = globalActionBarConfig;
  final abilityName = config?.getSlotAbility(slotIndex) ?? '';
  if (abilityName.isEmpty) return;
  // Reason: targeted abilities with no current target can never resolve —
  // reject immediately rather than queuing something that will never fire.
  final data = config?.getSlotAbilityData(slotIndex);
  if (data != null && !data.isSelfCast && data.range > 0) {
    if (gameState.currentTargetId == null) {
      gameState.addConsoleLog('$abilityName requires a target', level: ConsoleLogLevel.warn);
      return;
    }
  }
  gameState.abilityQueue.add(AbilityQueueEntry(slotIndex, abilityName));
  _refreshQueuePrimedSlots(gameState);
}

/// Recomputes [GameState.abilityQueuePrimedSlots] from the last queued entry.
///
/// Called after every mutation of [abilityQueue] so the action bar's yellow
/// combo tint always reflects the current queue tail.
void _refreshQueuePrimedSlots(GameState gameState) {
  final slots = gameState.abilityQueuePrimedSlots;
  // Clear all first.
  for (int i = 0; i < slots.length; i++) slots[i] = false;

  if (gameState.abilityQueue.isEmpty) return;

  // Only the Warchief action bar is supported (same constraint as combo bonuses).
  if (!gameState.isWarchiefActive) return;

  final config = globalActionBarConfig;
  if (config == null) return;

  // Resolve the last queued ability's comboPrimes.
  final lastEntry = gameState.abilityQueue.last;
  final lastData = config.getSlotAbilityData(lastEntry.slotIndex);
  final primes = lastData.comboPrimes;
  if (primes.isEmpty) return;

  // Mark each action-bar slot whose assigned ability appears in primes.
  final assignments = config.slotAssignments;
  final primesSet = Set<String>.from(primes);
  for (int i = 0; i < assignments.length; i++) {
    if (primesSet.contains(assignments[i])) slots[i] = true;
  }
}

// ==================== COOLDOWN MANAGEMENT ====================

/// Set cooldown for a slot, applying Melt reduction and stance cooldown multiplier.
void _setCooldownForSlot(int slotIndex, double cooldown, GameState gameState) {
  final cds = gameState.activeAbilityCooldowns;
  final maxes = gameState.activeAbilityCooldownMaxes;
  if (slotIndex < 0 || slotIndex >= cds.length) return;
  final melt = gameState.activeMelt;
  if (melt > 0) cooldown = cooldown / (1 + melt / 100.0);
  cooldown *= gameState.activeStance.cooldownMultiplier;
  cds[slotIndex] = cooldown;
  // Reason: keep max in sync with actual cooldown so the ring animation sweeps
  // the full arc correctly (ring progress = remaining / max).
  maxes[slotIndex] = cooldown;
}

/// For each ability name in [primes], find its action-bar slot and apply a
/// 0.5s GCD bonus so that slot's countdown shows as reduced (and yellow).
void _applyComboGcdBonuses(List<String> primes, GameState gameState) {
  final config = globalActionBarConfig;
  if (config == null) return;
  final slots = config.slotAssignments;
  // Reason: only the Warchief action bar drives comboPrimes today;
  // ally combo primes would need per-ally bonus lists which don't exist yet.
  if (!gameState.isWarchiefActive) return;
  // Reason: convert to Set for O(1) lookup — slots.length × primes.length
  // linear scans (up to 10×5 = 50 comparisons) on every ability fire.
  final primesSet = primes.length <= 3 ? primes : Set<String>.from(primes);
  for (int i = 0; i < slots.length; i++) {
    if (primesSet.contains(slots[i])) {
      gameState.abilityComboGcdBonuses[i] = 0.5;
    }
  }
}

// ==================== SLOT DISPATCH ====================

/// Look up the configured ability for [slotIndex] and execute it.
void _executeSlotAbility(int slotIndex, GameState gameState) {
  final config = globalActionBarConfig;
  if (config == null) {
    _executeDefaultSlotAbility(slotIndex, gameState);
    return;
  }
  final abilityName = config.getSlotAbility(slotIndex);
  _executeAbilityByName(abilityName, slotIndex, gameState);
}

/// Fallback slot-to-ability mapping (used when no ActionBarConfig is loaded).
void _executeDefaultSlotAbility(int slotIndex, GameState gameState) {
  switch (slotIndex) {
    case 0: _executeSword(slotIndex, gameState); break;
    case 1: _executeFireball(slotIndex, gameState); break;
    case 2: _executeHeal(slotIndex, gameState); break;
    case 3: _executeDashAttack(slotIndex, gameState); break;
  }
}

// ==================== MAIN ABILITY DISPATCHER ====================

/// Validate and execute an ability by name, applying GCD, mana checks, and range checks.
///
/// Data-driven abilities (those backed only by AbilityData with no special-cased handler)
/// fall through to the `default` branch which calls [_executeGenericAbility].
void _executeAbilityByName(String abilityName, int slotIndex, GameState gameState) {
  // Cooldown check — soft failure, queue and wait
  final cooldown = AbilitySystem.getCooldownForSlot(slotIndex, gameState);
  if (cooldown > 0) {
    _tryEnqueue(slotIndex, gameState);
    return;
  }

  // Casting / windup gate — soft failure, queue and wait
  if (gameState.isCasting || gameState.isWindingUp) {
    _tryEnqueue(slotIndex, gameState);
    return;
  }

  // Capture combo state — whether this slot is inside an active combo window.
  // Must be read before the GCD gate so it's available for the range check too.
  final _comboBonus = (gameState.isWarchiefActive &&
          slotIndex >= 0 &&
          slotIndex < gameState.abilityComboGcdBonuses.length)
      ? gameState.abilityComboGcdBonuses[slotIndex]
      : 0.0;
  final _wasComboFired = _comboBonus > 0.0;

  // GCD gate — soft failure, queue and wait
  {
    final effectiveGcd = gameState.activeGcdRemaining - _comboBonus;
    if (effectiveGcd > 0) {
      _tryEnqueue(slotIndex, gameState);
      return;
    }
  }

  // Range check — soft failure, queue and wait for player to close gap
  final abilityData = globalActionBarConfig?.getSlotAbilityData(slotIndex);
  if (abilityData != null && !abilityData.isSelfCast && abilityData.range > 0 && gameState.currentTargetId != null) {
    final distance = gameState.getDistanceToCurrentTarget();
    final effectiveRange = abilityData.range *
        (_wasComboFired ? gameState.comboRangeMultiplier : 1.0);
    if (distance != null && distance > effectiveRange) {
      _tryEnqueue(slotIndex, gameState);
      return;
    }
  }

  // Determine mana cost and type (prefer AbilityData fields; fall back to legacy lookup)
  double manaCost;
  _ManaType manaType;
  if (abilityData != null && abilityData.requiresMana) {
    manaCost = abilityData.manaCost;
    manaType = _manaColorToType(abilityData.manaColor);
  } else {
    (manaCost, manaType) = _getManaCostAndType(abilityName);
  }

  // Secondary mana (dual-mana abilities)
  double secondaryManaCost = 0.0;
  _ManaType secondaryManaType = _ManaType.none;
  if (abilityData != null && abilityData.requiresDualMana) {
    secondaryManaCost = abilityData.secondaryManaCost;
    secondaryManaType = _manaColorToType(abilityData.secondaryManaColor);
  }

  // Attunement gate
  if (manaCost > 0 && manaType != _ManaType.none) {
    final requiredColor = _manaTypeToColor(manaType);
    if (!gameState.activeManaAttunements.contains(requiredColor)) {
      gameState.addConsoleLog('$abilityName: not attuned to $requiredColor mana', level: ConsoleLogLevel.warn);
      return;
    }
  }
  if (secondaryManaCost > 0 && secondaryManaType != _ManaType.none) {
    final requiredColor = _manaTypeToColor(secondaryManaType);
    if (!gameState.activeManaAttunements.contains(requiredColor)) {
      gameState.addConsoleLog('$abilityName: not attuned to $requiredColor mana (secondary)', level: ConsoleLogLevel.warn);
      return;
    }
  }

  // Stance mana cost multiplier
  final stance = gameState.activeStance;
  if (stance.manaCostMultiplier != 1.0 && !stance.usesHpForMana) {
    manaCost *= stance.manaCostMultiplier;
    secondaryManaCost *= stance.manaCostMultiplier;
  }

  // Silent Mind: next white mana ability is free
  if (gameState.silentMindActive && manaType == _ManaType.white && manaCost > 0) {
    debugPrint('[SILENT MIND] $abilityName mana cost overridden to 0 (was $manaCost)');
    manaCost = 0;
  }

  // Blood Weave: abilities cost HP instead of mana
  if (stance.usesHpForMana && manaCost > 0) {
    final hpCost = manaCost * stance.hpForManaRatio;
    if (gameState.activeHealth <= hpCost) {
      gameState.addConsoleLog('$abilityName: not enough HP (need ${hpCost.toStringAsFixed(1)}, have ${gameState.activeHealth.toStringAsFixed(1)})', level: ConsoleLogLevel.warn);
      return;
    }
  } else {
    if (manaCost > 0 && !_activeHasMana(gameState, manaType, manaCost, abilityName)) return;
  }
  if (secondaryManaCost > 0 && !stance.usesHpForMana &&
      !_activeHasMana(gameState, secondaryManaType, secondaryManaCost, abilityName)) {
    return;
  }

  // Cast-time abilities: defer mana until cast completes
  if (abilityData != null && abilityData.hasCastTime) {
    if (gameState.silentMindActive && manaType == _ManaType.white) {
      debugPrint('[SILENT MIND] $abilityName cast time skipped — instant cast!');
      // Fall through to instant execution
    } else {
      gameState.pendingManaCost = manaCost;
      gameState.pendingManaIsBlue = manaType == _ManaType.blue;
      gameState.pendingManaType = _manaTypeToIndex(manaType);
      _pendingSecondaryManaCost = secondaryManaCost;
      _pendingSecondaryManaType = _manaTypeToIndex(secondaryManaType);
      gameState.addConsoleLog('Begin casting $abilityName (${abilityData.castTime.toStringAsFixed(1)}s)');
      _startCastTimeAbility(abilityData, slotIndex, gameState);
      return;
    }
  }

  // Windup abilities: defer mana until windup completes
  if (abilityData != null && abilityData.hasWindup) {
    gameState.pendingManaCost = manaCost;
    gameState.pendingManaIsBlue = manaType == _ManaType.blue;
    gameState.pendingManaType = _manaTypeToIndex(manaType);
    _pendingSecondaryManaCost = secondaryManaCost;
    _pendingSecondaryManaType = _manaTypeToIndex(secondaryManaType);
    gameState.addConsoleLog('Winding up $abilityName');
    _startWindupAbility(abilityData, slotIndex, gameState);
    return;
  }

  // Reason: short-range generic melee abilities check ability1Active AFTER the GCD
  // trigger below, so without this guard the GCD fires (locking all slots for 1s)
  // even though no attack actually lands. Return early so mana and GCD are untouched.
  if (abilityData != null &&
      abilityData.type == AbilityType.melee &&
      abilityData.range < _gapCloserRangeThreshold &&
      gameState.ability1Active) {
    return;
  }

  // Spend mana (or HP for Blood Weave) for instant abilities
  if (stance.usesHpForMana && manaCost > 0) {
    final hpCost = manaCost * stance.hpForManaRatio;
    gameState.activeHealth = (gameState.activeHealth - hpCost).clamp(1.0, gameState.activeMaxHealth);
    debugPrint('[BLOOD WEAVE] $abilityName spent ${hpCost.toStringAsFixed(1)} HP instead of mana');
  } else {
    _spendManaByType(gameState, manaType, manaCost, abilityName);
  }
  if (!stance.usesHpForMana) {
    _spendManaByType(gameState, secondaryManaType, secondaryManaCost, abilityName);
  }

  // Consume Silent Mind buff after white mana ability
  if (gameState.silentMindActive && manaType == _ManaType.white) {
    gameState.silentMindActive = false;
    debugPrint('[SILENT MIND] Buff consumed by $abilityName');
  }

  gameState.addConsoleLog('$abilityName executed (slot $slotIndex)');
  // Reason: queue-fired abilities show a fading yellow entry in the queue line;
  // only direct hotkey presses use the separate floating dissolve label.
  if (!_isDrainingQueue) gameState.executingAbilityLabel = QueuedAbilityLabel(abilityName);

  // Trigger GCD — 1.0s base, reduced by haste and stance
  {
    final haste = gameState.activeHaste;
    double gcd = 1.0 / (1 + haste / 100.0);
    gcd *= gameState.activeStance.cooldownMultiplier;
    if (gameState.isWarchiefActive) {
      gameState.gcdRemaining = gcd;
      gameState.gcdMax = gcd;
    } else if (gameState.activeAlly != null) {
      gameState.activeAlly!.gcdRemaining = gcd;
      gameState.activeAlly!.gcdMax = gcd;
    }
  }

  // Consume this slot's combo bonus now that the ability has fired.
  if (gameState.isWarchiefActive &&
      slotIndex >= 0 &&
      slotIndex < gameState.abilityComboGcdBonuses.length) {
    gameState.abilityComboGcdBonuses[slotIndex] = 0.0;
  }

  // Update combo depth for the next ability's range multiplier.
  // Reason: depth 1 → +20%, depth 2 → +40% range on the next primed ability.
  // Any non-combo fire resets the chain; combo fires deepen it (max 2).
  if (gameState.isWarchiefActive) {
    gameState.comboDepth = _wasComboFired
        ? (gameState.comboDepth + 1).clamp(0, 2)
        : 0;
  }

  // Apply combo GCD bonuses to primed follow-up slots.
  if (abilityData != null && abilityData.comboPrimes.isNotEmpty) {
    _applyComboGcdBonuses(abilityData.comboPrimes, gameState);
  }

  // ---- Named ability dispatch ----
  // Data-driven abilities (those not listed here) fall through to `default`
  // which calls _executeGenericAbility — no need to list every ability name.
  switch (abilityName) {
    // Base player abilities
    case 'Sword': _executeSword(slotIndex, gameState); break;
    case 'Fireball': _executeFireball(slotIndex, gameState); break;
    case 'Heal': _executeHeal(slotIndex, gameState); break;
    case 'Dash Attack': _executeDashAttack(slotIndex, gameState); break;

    // Warrior
    case 'Shield Bash': _executeShieldBash(slotIndex, gameState); break;
    case 'Whirlwind': _executeWhirlwind(slotIndex, gameState); break;
    case 'Charge': _executeCharge(slotIndex, gameState); break;
    case 'Taunt': _executeTaunt(slotIndex, gameState); break;
    case 'Fortify': _executeFortify(slotIndex, gameState); break;

    // Mage
    case 'Frost Bolt': _executeFrostBolt(slotIndex, gameState); break;
    case 'Blizzard': _executeBlizzard(slotIndex, gameState); break;
    case 'Lightning Bolt': _executeLightningBolt(slotIndex, gameState); break;
    case 'Chain Lightning': _executeChainLightning(slotIndex, gameState); break;
    case 'Meteor': _executeMeteor(slotIndex, gameState); break;
    case 'Arcane Shield': _executeArcaneShield(slotIndex, gameState); break;
    case 'Teleport': _executeTeleport(slotIndex, gameState); break;

    // Rogue
    case 'Backstab': _executeBackstab(slotIndex, gameState); break;
    case 'Poison Blade': _executePoisonBlade(slotIndex, gameState); break;
    case 'Smoke Bomb': _executeSmokeBomb(slotIndex, gameState); break;
    case 'Fan of Knives': _executeFanOfKnives(slotIndex, gameState); break;
    case 'Shadow Step': _executeShadowStep(slotIndex, gameState); break;

    // Healer
    case 'Holy Light': _executeHolyLight(slotIndex, gameState); break;
    case 'Rejuvenation': _executeRejuvenation(slotIndex, gameState); break;
    case 'Circle of Healing': _executeCircleOfHealing(slotIndex, gameState); break;
    case 'Blessing of Strength': _executeBlessingOfStrength(slotIndex, gameState); break;
    case 'Purify': _executePurify(slotIndex, gameState); break;

    // Nature
    case 'Entangling Roots': _executeEntanglingRoots(slotIndex, gameState); break;
    case 'Thorns': _executeThorns(slotIndex, gameState); break;
    case 'Nature\'s Wrath': _executeNaturesWrath(slotIndex, gameState); break;

    // Stormheart channeled
    case 'Conduit': _executeConduit(slotIndex, gameState); break;

    // Spiritkin
    case 'Animal Spirit': _executeAnimalSpirit(slotIndex, gameState); break;

    // Necromancer
    case 'Life Drain': _executeLifeDrain(slotIndex, gameState); break;
    case 'Curse of Weakness': _executeCurseOfWeakness(slotIndex, gameState); break;
    case 'Fear': _executeFear(slotIndex, gameState); break;
    case 'Soul Rot': _executeSoulRot(slotIndex, gameState); break;
    case 'Summon Skeleton': _executeSummonSkeleton(slotIndex, gameState); break;
    case 'Summon Skeleton Mage': _executeSummonSkeletonMage(slotIndex, gameState); break;

    // Elemental
    case 'Ice Lance': _executeIceLance(slotIndex, gameState); break;
    case 'Flame Wave': _executeFlameWave(slotIndex, gameState); break;
    case 'Earthquake': _executeEarthquake(slotIndex, gameState); break;

    // Utility
    case 'Sprint': _executeSprint(slotIndex, gameState); break;
    case 'Battle Shout': _executeBattleShout(slotIndex, gameState); break;

    // Wind Walker
    case 'Gale Step': _executeGaleStep(slotIndex, gameState); break;
    case 'Zephyr Roll': _executeZephyrRoll(slotIndex, gameState); break;
    case 'Tailwind Retreat': _executeTailwindRetreat(slotIndex, gameState); break;
    case 'Flying Serpent Strike': _executeFlyingSerpentStrike(slotIndex, gameState); break;
    case 'Take Flight': _executeTakeFlight(slotIndex, gameState); break;
    case 'Cyclone Dive': _executeCycloneDive(slotIndex, gameState); break;
    case 'Wind Wall': _executeWindWall(slotIndex, gameState); break;
    case 'Tempest Charge': _executeTempestCharge(slotIndex, gameState); break;
    case 'Healing Gale': _executeHealingGale(slotIndex, gameState); break;
    case 'Sovereign of the Sky': _executeSovereignOfTheSky(slotIndex, gameState); break;
    case 'Wind Affinity': _executeWindAffinity(slotIndex, gameState); break;
    case 'Silent Mind': _executeSilentMind(slotIndex, gameState); break;
    case 'Windshear': _executeWindshear(slotIndex, gameState); break;
    case 'Wind Warp': _executeWindWarp(slotIndex, gameState); break;

    // ==================== CLASS LONG BUFFS ====================
    case 'Battle Presence': _executeBattlePresence(slotIndex, gameState); break;
    case 'Arcane Empowerment': _executeArcaneEmpowerment(slotIndex, gameState); break;
    case 'Shadow Form': _executeShadowForm(slotIndex, gameState); break;
    case 'Blessing of Kings': _executeBlessingOfKings(slotIndex, gameState); break;
    case 'Aether Flow': _executeAetherFlow(slotIndex, gameState); break;
    case 'Gale Stride': _executeGaleStride(slotIndex, gameState); break;
    case 'Storm Hardened': _executeStormHardened(slotIndex, gameState); break;
    case 'Nature\'s Resilience': _executeNaturesResilience(slotIndex, gameState); break;
    case 'Living Web': _executeLivingWeb(slotIndex, gameState); break;
    case 'Spirit Bond': _executeSpiritBond(slotIndex, gameState); break;
    case 'Death Shroud': _executeDeathShroud(slotIndex, gameState); break;
    case 'Void Resonance': _executeVoidResonance(slotIndex, gameState); break;
    case 'Elemental Attunement': _executeElementalAttunement(slotIndex, gameState); break;

    default:
      // Generic data-driven execution for all other abilities (custom, class combos, etc.)
      if (abilityData != null) {
        _executeGenericAbility(slotIndex, gameState, abilityData);
      } else {
        gameState.addConsoleLog('Unknown ability: $abilityName (no data found)', level: ConsoleLogLevel.error);
        _executeDefaultSlotAbility(slotIndex, gameState);
      }
  }
}
