part of 'game_state.dart';

extension GameStateStanceExt on GameState {
  /// Switch the active character to a new stance.
  ///
  /// Proportionally scales current HP when maxHealth changes.
  /// Respects switch cooldown (cannot switch during cooldown).
  void switchStance(StanceId newStance) {
    if (stanceSwitchCooldown > 0) {
      print('[STANCE] Cannot switch yet — ${stanceSwitchCooldown.toStringAsFixed(1)}s remaining');
      return;
    }

    final oldMaxHealth = activeMaxHealth;
    if (isWarchiefActive) {
      playerStance = newStance;
    } else if (activeAlly != null) {
      activeAlly!.currentStance = newStance;
    }
    final newMaxHealth = activeMaxHealth;

    // Proportionally scale current HP so switching doesn't instakill or overheal
    if (oldMaxHealth > 0 && newMaxHealth != oldMaxHealth) {
      final ratio = activeHealth / oldMaxHealth;
      activeHealth = (ratio * newMaxHealth).clamp(1.0, newMaxHealth);
    }

    // Set switch cooldown from the new stance
    stanceSwitchCooldown = activeStance.switchCooldown;
    stanceActiveTime = 0.0;

    // Reset Drunken Master accumulators if switching to it
    if (activeStance.hasRandomModifiers) {
      stanceRerollAccumulator = 0.0;
      drunkenDamageRoll = 1.0;
      drunkenDamageTakenRoll = 1.0;
    }

    // Combat log
    combatLogMessages.add(CombatLogEntry(
      source: 'Player',
      action: 'Switched to ${activeStance.name} stance',
      type: CombatLogType.ability,
    ));
    if (combatLogMessages.length > 250) {
      combatLogMessages.removeRange(0, combatLogMessages.length - 200);
    }

    // Console log
    addConsoleLog('Stance switched to ${activeStance.name}');

    print('[STANCE] Switched to ${activeStance.name}');
    saveStanceConfig();
  }

  /// Cycle to the next selectable stance (for Shift+X).
  void cycleStance() {
    final registry = globalStanceRegistry;
    if (registry == null) return;
    final stances = [StanceId.none, ...registry.selectableStances.map((s) => s.id)];
    final currentId = isWarchiefActive ? playerStance : (activeAlly?.currentStance ?? StanceId.none);
    final idx = stances.indexOf(currentId);
    // Skip stances that are on switch cooldown — try each one
    for (int i = 1; i <= stances.length; i++) {
      final nextIdx = (idx + i) % stances.length;
      final nextId = stances[nextIdx];
      // Reason: switching resets cooldown, so we only check if cooldown blocks us
      if (stanceSwitchCooldown <= 0 || nextId == currentId) {
        switchStance(nextId);
        return;
      }
    }
  }

  /// Update stance timers each frame: Fury drain, Drunken re-rolls, switch cooldown.
  void updateStanceTimers(double dt) {
    // Tick switch cooldown
    if (stanceSwitchCooldown > 0) {
      stanceSwitchCooldown = (stanceSwitchCooldown - dt).clamp(0.0, double.infinity);
    }

    final stance = activeStance;
    stanceActiveTime += dt;

    // Fury of the Ancestors: health drain
    if (stance.healthDrainPerSecond > 0) {
      final maxHp = activeMaxHealth;
      final drain = maxHp * stance.healthDrainPerSecond * dt;
      activeHealth = (activeHealth - drain).clamp(1.0, maxHp);

      // Log when HP reaches critical (<20%)
      final hpPct = activeHealth / maxHp;
      // Reason: only log once when crossing the 20% threshold
      if (hpPct < 0.20 && (activeHealth + drain) / maxHp >= 0.20) {
        combatLogMessages.add(CombatLogEntry(
          source: stance.name,
          action: '${stance.name}: HP critical!',
          type: CombatLogType.damage,
          amount: activeHealth,
        ));
        if (combatLogMessages.length > 250) {
          combatLogMessages.removeRange(0, combatLogMessages.length - 200);
        }
      }
    }

    // Drunken Master: periodic re-rolls
    if (stance.hasRandomModifiers && stance.rerollInterval > 0) {
      stanceRerollAccumulator += dt;
      if (stanceRerollAccumulator >= stance.rerollInterval) {
        stanceRerollAccumulator -= stance.rerollInterval;
        final range = stance.rerollDamageMax - stance.rerollDamageMin;
        drunkenDamageRoll = stance.rerollDamageMin + _stanceRng.nextDouble() * range;
        final takenRange = stance.rerollDamageTakenMax - stance.rerollDamageTakenMin;
        drunkenDamageTakenRoll = stance.rerollDamageTakenMin + _stanceRng.nextDouble() * takenRange;

        final dmgPct = ((drunkenDamageRoll - 1.0) * 100).round();
        final takenPct = ((drunkenDamageTakenRoll - 1.0) * 100).round();
        final dmgSign = dmgPct >= 0 ? '+' : '';
        final takenSign = takenPct >= 0 ? '+' : '';

        combatLogMessages.add(CombatLogEntry(
          source: stance.name,
          action: '${stance.name}: Power surges! ($dmgSign$dmgPct% damage, $takenSign$takenPct% damage taken)',
          type: CombatLogType.ability,
        ));
        if (combatLogMessages.length > 250) {
          combatLogMessages.removeRange(0, combatLogMessages.length - 200);
        }

        // Trigger visual pulse for UI overlay
        drunkenRerollPulseTimer = 0.4;
      }
    }

    // Tick down the Drunken re-roll visual pulse
    if (drunkenRerollPulseTimer > 0) {
      drunkenRerollPulseTimer = (drunkenRerollPulseTimer - dt).clamp(0.0, double.infinity);
    }
  }

  /// Generate mana from damage taken (Tide stance passive).
  ///
  /// Adds mana to the primary attuned color of the active character.
  void generateManaFromDamageTaken(double manaAmount) {
    if (manaAmount <= 0) return;
    final attunements = activeManaAttunements;
    // Reason: pick the first attuned color as "primary"
    if (attunements.contains(ManaColor.red)) {
      if (isWarchiefActive) {
        redMana = (redMana + manaAmount).clamp(0.0, maxRedMana);
      } else if (activeAlly != null) {
        activeAlly!.redMana = (activeAlly!.redMana + manaAmount).clamp(0.0, activeAlly!.maxRedMana);
      }
    } else if (attunements.contains(ManaColor.blue)) {
      if (isWarchiefActive) {
        blueMana = (blueMana + manaAmount).clamp(0.0, maxBlueMana);
      } else if (activeAlly != null) {
        activeAlly!.blueMana = (activeAlly!.blueMana + manaAmount).clamp(0.0, activeAlly!.maxBlueMana);
      }
    } else if (attunements.contains(ManaColor.green)) {
      if (isWarchiefActive) {
        greenMana = (greenMana + manaAmount).clamp(0.0, maxGreenMana);
      } else if (activeAlly != null) {
        activeAlly!.greenMana = (activeAlly!.greenMana + manaAmount).clamp(0.0, activeAlly!.maxGreenMana);
      }
    } else if (attunements.contains(ManaColor.white)) {
      if (isWarchiefActive) {
        whiteMana = (whiteMana + manaAmount).clamp(0.0, maxWhiteMana);
      } else if (activeAlly != null) {
        activeAlly!.whiteMana = (activeAlly!.whiteMana + manaAmount).clamp(0.0, activeAlly!.maxWhiteMana);
      }
    }
    print('[TIDE] Converted damage to ${manaAmount.toStringAsFixed(1)} mana');
  }

  /// Save current stance selections to SharedPreferences.
  Future<void> saveStanceConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stance_player', playerStance.name);
      for (int i = 0; i < allies.length; i++) {
        await prefs.setString('stance_ally_$i', allies[i].currentStance.name);
      }
    } catch (e) {
      print('[STANCE] Failed to save stance config: $e');
    }
  }

  /// Load saved stance selections from SharedPreferences.
  ///
  /// If no saved preference exists, applies the registry's [defaultStance].
  Future<void> loadStanceConfig() async {
    final registry = globalStanceRegistry;
    final fallback = registry?.defaultStance ?? StanceId.none;
    try {
      final prefs = await SharedPreferences.getInstance();
      final playerStanceName = prefs.getString('stance_player');
      if (playerStanceName != null) {
        final id = _parseStanceIdFromName(playerStanceName);
        playerStance = id ?? fallback;
      } else {
        playerStance = fallback;
      }
      for (int i = 0; i < allies.length; i++) {
        final allyStanceName = prefs.getString('stance_ally_$i');
        if (allyStanceName != null) {
          final id = _parseStanceIdFromName(allyStanceName);
          allies[i].currentStance = id ?? fallback;
        } else {
          allies[i].currentStance = fallback;
        }
      }
    } catch (e) {
      print('[STANCE] Failed to load stance config: $e');
      // Still apply default on failure
      playerStance = fallback;
      for (final ally in allies) {
        ally.currentStance = fallback;
      }
    }
  }

  /// Parse a StanceId from its enum name string.
  StanceId? _parseStanceIdFromName(String name) {
    for (final id in StanceId.values) {
      if (id.name == name) return id;
    }
    return null;
  }

  /// Tick and expire all active effects on all entities, applying DoT damage.
  void updateActiveEffects(double dt) {
    // Player effects
    for (final effect in playerActiveEffects) {
      effect.tick(dt);
      if (effect.isDoT) {
        effect.tickAccumulator += dt;
        while (effect.tickAccumulator >= effect.tickInterval) {
          effect.tickAccumulator -= effect.tickInterval;
          playerHealth = (playerHealth - effect.damagePerTick).clamp(0.0, playerMaxHealth);
          _logDoTTick(effect, 'Player', playerTransform?.position);
        }
      }
    }
    playerActiveEffects.removeWhere((e) => e.isExpired);

    // Boss monster effects
    for (final effect in monsterActiveEffects) {
      effect.tick(dt);
      if (effect.isDoT) {
        effect.tickAccumulator += dt;
        while (effect.tickAccumulator >= effect.tickInterval) {
          effect.tickAccumulator -= effect.tickInterval;
          monsterHealth = (monsterHealth - effect.damagePerTick).clamp(0.0, monsterMaxHealth);
          _logDoTTick(effect, 'Monster', monsterTransform?.position);
        }
      }
    }
    monsterActiveEffects.removeWhere((e) => e.isExpired);

    // Ally effects
    for (int i = 0; i < allies.length; i++) {
      final ally = allies[i];
      for (final effect in ally.activeEffects) {
        effect.tick(dt);
        if (effect.isDoT) {
          effect.tickAccumulator += dt;
          while (effect.tickAccumulator >= effect.tickInterval) {
            effect.tickAccumulator -= effect.tickInterval;
            ally.health = (ally.health - effect.damagePerTick).clamp(0.0, ally.maxHealth);
            _logDoTTick(effect, 'Ally ${i + 1}', ally.transform.position);
          }
        }
      }
      ally.activeEffects.removeWhere((e) => e.isExpired);
    }

    // Minion effects
    for (final minion in minions) {
      for (final effect in minion.activeEffects) {
        effect.tick(dt);
        if (effect.isDoT) {
          effect.tickAccumulator += dt;
          while (effect.tickAccumulator >= effect.tickInterval) {
            effect.tickAccumulator -= effect.tickInterval;
            minion.takeDamage(effect.damagePerTick);
            _logDoTTick(effect, 'Minion', minion.transform.position);
          }
        }
      }
      minion.activeEffects.removeWhere((e) => e.isExpired);
    }
  }

  /// Log a DoT tick as a floating damage number and a combat log entry.
  void _logDoTTick(ActiveEffect effect, String target, Vector3? worldPos) {
    final label = effect.sourceName.isNotEmpty
        ? effect.sourceName
        : effect.type.name;

    // Floating damage number
    if (worldPos != null) {
      final indicatorPos = worldPos.clone();
      indicatorPos.y += 2.0;
      damageIndicators.add(DamageIndicator(
        damage: effect.damagePerTick,
        worldPosition: indicatorPos,
      ));
    }

    // Combat log entry
    combatLogMessages.add(CombatLogEntry(
      source: label,
      action: '$label (${effect.type.name})',
      type: CombatLogType.damage,
      amount: effect.damagePerTick,
      target: target,
    ));
    if (combatLogMessages.length > 250) {
      combatLogMessages.removeRange(0, combatLogMessages.length - 200);
    }
  }

  /// Cycle active character forward (] key)
  void cycleActiveCharacterNext() {
    final total = 1 + allies.length;
    activeCharacterIndex = (activeCharacterIndex + 1) % total;
    _resetPhysicsForSwitch();
  }

  /// Cycle active character backward ([ key)
  void cycleActiveCharacterPrev() {
    final total = 1 + allies.length;
    activeCharacterIndex = (activeCharacterIndex - 1 + total) % total;
    _resetPhysicsForSwitch();
  }

  /// Reset physics state when switching active character
  /// Prevents carried velocity / jump state from bleeding across characters
  void _resetPhysicsForSwitch() {
    verticalVelocity = 0.0;
    isJumping = false;
    isGrounded = true;
    jumpsRemaining = maxJumps;
    cancelCast();
    cancelWindup();
    cancelChannel();
    // End flight if switching away from Warchief
    if (!isWarchiefActive && isFlying) {
      endFlight();
    }
  }

  /// Cancel any active cast (called when player moves during stationary cast)
  void cancelCast() {
    if (isCasting) {
      print('[CAST] $castingAbilityName cast cancelled — mana and cooldown preserved');
      isCasting = false;
      castProgress = 0.0;
      currentCastTime = 0.0;
      castingSlotIndex = null;
      castingAbilityName = '';
      pendingManaCost = 0.0;
    }
  }

  /// Cancel any active windup
  void cancelWindup() {
    if (isWindingUp) {
      print('[WINDUP] $windupAbilityName windup cancelled — mana and cooldown preserved');
      isWindingUp = false;
      windupProgress = 0.0;
      currentWindupTime = 0.0;
      windupSlotIndex = null;
      windupAbilityName = '';
      windupMovementSpeedModifier = 1.0;
      pendingManaCost = 0.0;
    }
  }

  /// Cancel any active channel
  void cancelChannel() {
    if (isChanneling) {
      print('[CHANNEL] $channelingAbilityName channel cancelled');
      isChanneling = false;
      channelProgress = 0.0;
      channelDuration = 0.0;
      channelingSlotIndex = null;
      channelingAbilityName = '';
      channelAoeCenter = null;
    }
  }
}
