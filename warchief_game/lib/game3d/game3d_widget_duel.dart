part of 'game3d_widget.dart';

mixin _WidgetDuelMixin on _GameStateBase {
  // ==================== DUEL ARENA COMMANDS ====================

  /// Start a multi-party duel from a [DuelSetupConfig] built by the Setup tab.
  void _startDuel(DuelSetupConfig setup) {
    final cfg         = globalDuelConfig;
    final sep         = cfg?.separationDistance ?? 20.0;
    final baseHealth  = cfg?.challengerHealth    ?? 100.0;
    final baseMana    = cfg?.challengerManaPool  ?? 100.0;
    final enemyHealth = cfg?.enemyFactionHealth  ?? 100.0;
    final enemyMana   = cfg?.enemyFactionManaPool ?? 60.0;
    final healthMults = cfg?.gearTierHealthMultipliers ?? const [1.0, 1.2, 1.5, 1.85, 2.3];
    final manaMults   = cfg?.gearTierManaMultipliers   ?? const [1.0, 1.2, 1.5, 1.85, 2.3];
    final damageMults = cfg?.gearTierDamageMultipliers ?? const [1.0, 1.1, 1.25, 1.45, 1.70];

    double hm(int tier) => tier < healthMults.length ? healthMults[tier] : 1.0;
    double mm(int tier) => tier < manaMults.length   ? manaMults[tier]   : 1.0;
    double dm(int tier) => tier < damageMults.length ? damageMults[tier] : 1.0;

    // Reason: place the arena directly in front of the active character so it's
    // immediately visible, rather than at a fixed world offset.
    final playerPos    = gameState.activeTransform?.position;
    final yawRad       = gameState.activeRotation * math.pi / 180.0;
    final fwdX         = -math.sin(yawRad);
    final fwdZ         = -math.cos(yawRad);
    final rgtX         =  math.cos(yawRad);
    final rgtZ         = -math.sin(yawRad);
    const arenaForward = 15.0; // metres ahead of active character
    final baseX        = (playerPos?.x ?? 0.0) + fwdX * arenaForward;
    final baseZ        = (playerPos?.z ?? 0.0) + fwdZ * arenaForward;

    // Reason: combatants are placed at Y=0 by default but the terrain surface
    // is rarely at Y=0 on hilly maps. Sample the terrain height at the arena
    // centre so combatants and the banner pole land on the actual ground.
    final terrainY = gameState.infiniteTerrainManager?.getTerrainHeight(baseX, baseZ) ?? 0.0;

    final chalSize  = setup.challengerClasses.length;
    final enemySize = setup.enemyTypes.length;

    // Build combatants: challengers on the left (−right), enemies on the right (+right).
    // Multiple combatants on the same side are spread along the forward axis.
    final combatants = <Ally>[];
    for (int i = 0; i < chalSize; i++) {
      final fwdOff = chalSize == 1 ? 0.0 : (i - (chalSize - 1) / 2.0) * 3.0;
      final tier   = setup.challengerGearTiers[i];
      combatants.add(DuelDefinitions.createCombatant(
        setup.challengerClasses[i],
        Vector3(baseX - rgtX * (sep / 2) + fwdX * fwdOff,
                terrainY,
                baseZ - rgtZ * (sep / 2) + fwdZ * fwdOff),
        facingLeft: false,
        health: baseHealth * hm(tier), manaPool: baseMana * mm(tier),
      ));
    }
    for (int i = 0; i < enemySize; i++) {
      final fwdOff = enemySize == 1 ? 0.0 : (i - (enemySize - 1) / 2.0) * 3.0;
      final tier   = setup.enemyGearTiers[i];
      combatants.add(DuelDefinitions.createCombatant(
        setup.enemyTypes[i],
        Vector3(baseX + rgtX * (sep / 2) + fwdX * fwdOff,
                terrainY,
                baseZ + rgtZ * (sep / 2) + fwdZ * fwdOff),
        facingLeft: true,
        health: enemyHealth * hm(tier), manaPool: enemyMana * mm(tier),
      ));
    }

    setState(() {
      gameState.duelCombatants = combatants;
      final mgr = gameState.duelManager!;
      mgr.reset();
      mgr.selectedChallengerClass  = setup.challengerClasses.first;
      mgr.selectedEnemyType        = setup.enemyTypes.first;
      mgr.challengerPartySize      = chalSize;
      mgr.enemyPartySize           = enemySize;
      mgr.challengerPartyClasses   = List.from(setup.challengerClasses);
      mgr.enemyPartyTypes          = List.from(setup.enemyTypes);
      mgr.challengerGearTiers      = List.from(setup.challengerGearTiers);
      mgr.enemyGearTiers           = List.from(setup.enemyGearTiers);
      mgr.challengerStrategy       = setup.challengerStrategy;
      mgr.enemyStrategy            = setup.enemyStrategy;
      mgr.endCondition             = setup.endCondition;
      mgr.challengerPartyAbilities = setup.challengerClasses
          .map(DuelDefinitions.getAbilities).toList();
      mgr.enemyPartyAbilities = setup.enemyTypes
          .map(DuelDefinitions.getAbilities).toList();
      // Reason: cache slices + pre-computed mults so DuelSystem.update() has
      // zero allocations per frame (no sublist(), no config map lookup).
      mgr.challengerParty      = combatants.sublist(0, chalSize);
      mgr.enemyParty           = combatants.sublist(chalSize);
      mgr.challengerDamageMults = [for (final t in setup.challengerGearTiers) dm(t)];
      mgr.enemyDamageMults      = [for (final t in setup.enemyGearTiers)      dm(t)];
      // Reason: initialize GCD + combo-window timers to zero for every combatant
      // so DuelSystem.update() has valid indices from the first frame.
      final totalCombatants = chalSize + enemySize;
      mgr.combatantGcds         = List.filled(totalCombatants, 0.0, growable: true);
      mgr.combatantComboWindows = List.filled(totalCombatants, 0.0, growable: true);
      mgr.phase = DuelPhase.active;

      // Drop the banner from the sky at the arena centre (on terrain surface).
      (gameState.duelBannerState ??= DuelBannerState()).start(baseX, baseZ, terrainY: terrainY);
    });
  }

  /// Reset all ability cooldowns and GCDs for every active combatant without stopping the duel.
  void _duelResetCooldowns() {
    DuelSystem.resetCooldowns(gameState.duelCombatants);
    // Reason: also clear GCDs and combo windows so the reset feels immediate —
    // otherwise combatants would still wait out their current GCD even with
    // ability cooldowns zeroed.
    final mgr = gameState.duelManager;
    if (mgr != null) {
      for (int i = 0; i < mgr.combatantGcds.length; i++) {
        mgr.combatantGcds[i]         = 0.0;
        mgr.combatantComboWindows[i] = 0.0;
      }
    }
  }

  /// Cancel the current duel and remove arena combatants.
  void _cancelDuel() {
    setState(() {
      gameState.duelCombatants.clear();
      gameState.duelManager?.reset();
      gameState.duelBannerState?.reset();
    });
  }
}
