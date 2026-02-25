part of 'ability_system.dart';

// ==================== BASE PLAYER ABILITIES ====================

/// Sword melee swing — activates swing animation in updateAbility1.
void _executeSword(int slotIndex, GameState gameState) {
  if (gameState.ability1Active) return;
  gameState.ability1Active = true;
  gameState.ability1ActiveTime = 0.0;
  _setCooldownForSlot(slotIndex, _effective(AbilitiesConfig.playerSword).cooldown, gameState);
  gameState.ability1HitRegistered = false;
  print('Sword attack activated!');
}

/// Fireball ranged projectile — homing if target selected.
void _executeFireball(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  final fireball = _effective(AbilitiesConfig.playerFireball);
  final playerPos = gameState.activeTransform!.position;
  final targetId = gameState.currentTargetId;
  final targetPos = targetId != null ? _getTargetPosition(gameState, targetId) : null;
  final direction = targetPos != null
      ? (targetPos - playerPos).normalized()
      : Vector3(-math.sin(_radians(gameState.activeRotation)), 0, -math.cos(_radians(gameState.activeRotation)));
  final startPos = playerPos.clone() + direction * 1.0;
  startPos.y = playerPos.y;
  gameState.fireballs.add(Projectile(
    mesh: Mesh.cube(size: fireball.projectileSize, color: fireball.color),
    transform: Transform3d(position: startPos, scale: Vector3(1, 1, 1)),
    velocity: direction * fireball.projectileSpeed,
    targetId: targetId,
    speed: fireball.projectileSpeed,
    isHoming: targetId != null,
    damage: fireball.damage,
    abilityName: fireball.name,
    impactColor: fireball.impactColor,
    impactSize: fireball.impactSize,
  ));
  _setCooldownForSlot(slotIndex, fireball.cooldown, gameState);
  print('${fireball.name} launched${targetId != null ? " at $targetId" : ""}!');
}

/// Look up the world position of a target by its ID string.
Vector3? _getTargetPosition(GameState gameState, String targetId) {
  if (targetId == 'boss') {
    if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
      return gameState.monsterTransform!.position;
    }
  } else {
    for (final minion in gameState.aliveMinions) {
      if (minion.instanceId == targetId) return minion.transform.position;
    }
  }
  return null;
}

/// Self-heal ability — triggers heal animation in updateAbility3.
void _executeHeal(int slotIndex, GameState gameState) {
  if (gameState.ability3Active) return;
  gameState.ability3Active = true;
  gameState.ability3ActiveTime = 0.0;
  final healAbility = _effective(AbilitiesConfig.playerHeal);
  final effectiveHeal = healAbility.healAmount * gameState.activeStance.healingMultiplier;
  final oldHealth = gameState.activeHealth;
  gameState.activeHealth = math.min(gameState.activeMaxHealth, gameState.activeHealth + effectiveHeal);
  final healedAmount = gameState.activeHealth - oldHealth;
  _setCooldownForSlot(slotIndex, healAbility.cooldown, gameState);
  _logHeal(gameState, 'Heal', healedAmount);
  _showHealIndicator(gameState, healedAmount, gameState.activeTransform?.position);
  print('[HEAL] Player heal activated! Restored ${healedAmount.toStringAsFixed(1)} HP');
}

/// Dash Attack gap-closer — handled by _startDash and updateAbility4.
void _executeDashAttack(int slotIndex, GameState gameState) {
  _startDash(slotIndex, gameState, _effective(AbilitiesConfig.playerDashAttack), 'Dash Attack activated!');
}

// ==================== WARRIOR ABILITIES ====================

void _executeShieldBash(int slotIndex, GameState gameState) =>
    _executeGenericMelee(slotIndex, gameState, _effective(WarriorAbilities.shieldBash), 'Shield Bash activated!');

void _executeWhirlwind(int slotIndex, GameState gameState) =>
    _executeGenericAoE(slotIndex, gameState, _effective(WarriorAbilities.whirlwind), 'Whirlwind activated!');

void _executeCharge(int slotIndex, GameState gameState) =>
    _startDash(slotIndex, gameState, _effective(WarriorAbilities.charge), 'Charge activated!');

void _executeTaunt(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(WarriorAbilities.taunt).cooldown, gameState);
  gameState.addConsoleLog('Taunt: STUB — cooldown set but no aggro mechanic', level: ConsoleLogLevel.error);
}

void _executeFortify(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(WarriorAbilities.fortify).cooldown, gameState);
  gameState.addConsoleLog('Fortify: STUB — cooldown set but no defense buff applied', level: ConsoleLogLevel.error);
}

// ==================== MAGE ABILITIES ====================

void _executeFrostBolt(int slotIndex, GameState gameState) =>
    _executeGenericProjectile(slotIndex, gameState, _effective(MageAbilities.frostBolt), 'Frost Bolt launched!');

void _executeBlizzard(int slotIndex, GameState gameState) {
  final ability = _effective(MageAbilities.blizzard);
  final targetPos = gameState.getCurrentTargetPosition();
  gameState.channelAoeCenter = targetPos?.clone() ?? gameState.activeTransform?.position.clone();
  _startChanneledAbility(ability, slotIndex, gameState);
}

void _executeLightningBolt(int slotIndex, GameState gameState) =>
    _executeGenericProjectile(slotIndex, gameState, _effective(MageAbilities.lightningBolt), 'Lightning Bolt launched!');

void _executeChainLightning(int slotIndex, GameState gameState) =>
    _executeGenericProjectile(slotIndex, gameState, _effective(MageAbilities.chainLightning), 'Chain Lightning launched!');

void _executeMeteor(int slotIndex, GameState gameState) =>
    _executeGenericAoE(slotIndex, gameState, _effective(MageAbilities.meteor), 'Meteor incoming!');

void _executeArcaneShield(int slotIndex, GameState gameState) {
  gameState.ability3Active = true;
  gameState.ability3ActiveTime = 0.0;
  _setCooldownForSlot(slotIndex, _effective(MageAbilities.arcaneShield).cooldown, gameState);
  print('Arcane Shield activated!');
}

void _executeTeleport(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  final ability = _effective(MageAbilities.teleport);
  final forward = Vector3(-math.sin(_radians(gameState.activeRotation)), 0, -math.cos(_radians(gameState.activeRotation)));
  gameState.activeTransform!.position += forward * ability.range;
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  print('Teleport!');
}

// ==================== ROGUE ABILITIES ====================

void _executeBackstab(int slotIndex, GameState gameState) =>
    _executeGenericMelee(slotIndex, gameState, _effective(RogueAbilities.backstab), 'Backstab!');

void _executePoisonBlade(int slotIndex, GameState gameState) =>
    _executeGenericMelee(slotIndex, gameState, _effective(RogueAbilities.poisonBlade), 'Poison Blade!');

void _executeSmokeBomb(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(RogueAbilities.smokeBomb).cooldown, gameState);
  gameState.addConsoleLog('Smoke Bomb: STUB — cooldown set but no stealth/concealment effect', level: ConsoleLogLevel.error);
}

void _executeFanOfKnives(int slotIndex, GameState gameState) =>
    _executeGenericAoE(slotIndex, gameState, _effective(RogueAbilities.fanOfKnives), 'Fan of Knives!');

void _executeShadowStep(int slotIndex, GameState gameState) {
  _executeTeleport(slotIndex, gameState);
  print('Shadow Step!');
}

// ==================== HEALER ABILITIES ====================

void _executeHolyLight(int slotIndex, GameState gameState) =>
    _executeGenericHeal(slotIndex, gameState, _effective(HealerAbilities.holyLight), 'Holy Light!');

void _executeRejuvenation(int slotIndex, GameState gameState) =>
    _executeGenericHeal(slotIndex, gameState, _effective(HealerAbilities.rejuvenation), 'Rejuvenation!');

void _executeCircleOfHealing(int slotIndex, GameState gameState) =>
    _executeGenericHeal(slotIndex, gameState, _effective(HealerAbilities.circleOfHealing), 'Circle of Healing!');

void _executeBlessingOfStrength(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(HealerAbilities.blessingOfStrength).cooldown, gameState);
  print('Blessing of Strength! Damage increased.');
}

void _executePurify(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(HealerAbilities.purify).cooldown, gameState);
  print('Purify! Debuffs removed.');
}

// ==================== NATURE ABILITIES ====================

void _executeEntanglingRoots(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(NatureAbilities.entanglingRoots).cooldown, gameState);
  print('Entangling Roots! Enemy immobilized.');
}

void _executeThorns(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(NatureAbilities.thorns).cooldown, gameState);
  print('Thorns activated! Attackers take damage.');
}

void _executeNaturesWrath(int slotIndex, GameState gameState) =>
    _executeGenericProjectile(slotIndex, gameState, _effective(NatureAbilities.naturesWrath), 'Nature\'s Wrath!');

// ==================== STORMHEART ABILITIES ====================

void _executeConduit(int slotIndex, GameState gameState) {
  _startChanneledAbility(_effective(StormheartAbilities.conduit), slotIndex, gameState);
}

// ==================== NECROMANCER ABILITIES ====================

void _executeLifeDrain(int slotIndex, GameState gameState) {
  _startChanneledAbility(_effective(NecromancerAbilities.lifeDrain), slotIndex, gameState);
}

void _executeCurseOfWeakness(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(NecromancerAbilities.curseOfWeakness).cooldown, gameState);
  print('Curse of Weakness! Enemy damage reduced.');
}

void _executeFear(int slotIndex, GameState gameState) {
  final ability = _effective(NecromancerAbilities.fear);
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);

  if (gameState.monsterHealth > 0) {
    final fearDuration = ability.statusDuration * gameState.activeStance.ccDurationInflicted;
    gameState.monsterActiveEffects.add(ActiveEffect(
      type: StatusEffect.fear,
      remainingDuration: fearDuration,
      totalDuration: fearDuration,
    ));
    if (gameState.monsterTransform != null && gameState.playerTransform != null) {
      final awayFromPlayer = (gameState.monsterTransform!.position - gameState.playerTransform!.position).normalized();
      final escapeTarget = gameState.monsterTransform!.position + awayFromPlayer * 8.0;
      gameState.monsterCurrentPath = BezierPath.interception(
        start: gameState.monsterTransform!.position,
        target: escapeTarget,
        velocity: null,
      );
    }
    gameState.combatLogMessages.add(CombatLogEntry(
      source: 'Player', action: 'Fear', type: CombatLogType.debuff, target: 'Monster',
    ));
  }
}

void _executeSoulRot(int slotIndex, GameState gameState) =>
    _executeGenericProjectile(slotIndex, gameState, _effective(NecromancerAbilities.soulRot), 'Soul Rot!');

void _executeSummonSkeleton(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(NecromancerAbilities.summonSkeleton).cooldown, gameState);
  final casterTransform = gameState.activeTransform;
  if (casterTransform == null) return;
  gameState.spawnSummonedSkeleton(casterTransform);
}

void _executeSummonSkeletonMage(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(NecromancerAbilities.summonSkeletonMage).cooldown, gameState);
  final casterTransform = gameState.activeTransform;
  if (casterTransform == null) return;
  gameState.spawnSummonedSkeletonMage(casterTransform);
}

// ==================== ELEMENTAL ABILITIES ====================

void _executeIceLance(int slotIndex, GameState gameState) =>
    _executeGenericProjectile(slotIndex, gameState, _effective(ElementalAbilities.iceLance), 'Ice Lance!');

void _executeFlameWave(int slotIndex, GameState gameState) =>
    _executeGenericAoE(slotIndex, gameState, _effective(ElementalAbilities.flameWave), 'Flame Wave!');

void _executeEarthquake(int slotIndex, GameState gameState) {
  final ability = _effective(ElementalAbilities.earthquake);
  gameState.channelAoeCenter = gameState.activeTransform?.position.clone();
  _startChanneledAbility(ability, slotIndex, gameState);
}

// ==================== UTILITY ABILITIES ====================

void _executeSprint(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(UtilityAbilities.sprint).cooldown, gameState);
  gameState.addConsoleLog('Sprint: STUB — cooldown set but no speed buff applied', level: ConsoleLogLevel.error);
}

void _executeBattleShout(int slotIndex, GameState gameState) {
  _setCooldownForSlot(slotIndex, _effective(UtilityAbilities.battleShout).cooldown, gameState);
  gameState.addConsoleLog('Battle Shout: STUB — cooldown set but no ally buff applied', level: ConsoleLogLevel.error);
}
