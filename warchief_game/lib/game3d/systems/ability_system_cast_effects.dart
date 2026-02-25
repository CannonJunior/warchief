part of 'ability_system.dart';

// ==================== CAST-TIME ABILITY EFFECTS ====================

/// Launch Lightning Bolt projectile after cast completes.
void _launchLightningBolt(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  final playerPos = gameState.activeTransform!.position;
  final targetPos = _getTargetPositionOrForward(gameState, playerPos);
  final direction = (targetPos - playerPos).normalized();
  final startPos = playerPos.clone() + direction * 1.0;
  startPos.y = playerPos.y;
  gameState.fireballs.add(Projectile(
    mesh: Mesh.cube(size: 0.3, color: Vector3(0.8, 0.8, 1.0)),
    transform: Transform3d(position: startPos, scale: Vector3(1, 1, 1)),
    velocity: direction * 25.0,
    targetId: gameState.currentTargetId,
    speed: 25.0,
    isHoming: gameState.currentTargetId != null,
    damage: 40.0,
    abilityName: 'Lightning Bolt',
    impactColor: Vector3(0.9, 0.9, 1.0),
    impactSize: 0.8,
  ));
  print('Lightning Bolt launched!');
}

/// Launch Pyroblast projectile after cast completes.
void _launchPyroblast(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  final playerPos = gameState.activeTransform!.position;
  final targetPos = _getTargetPositionOrForward(gameState, playerPos);
  final direction = (targetPos - playerPos).normalized();
  final startPos = playerPos.clone() + direction * 1.0;
  startPos.y = playerPos.y;
  gameState.fireballs.add(Projectile(
    mesh: Mesh.cube(size: 0.8, color: Vector3(1.0, 0.3, 0.0)),
    transform: Transform3d(position: startPos, scale: Vector3(1, 1, 1)),
    velocity: direction * 8.0,
    targetId: gameState.currentTargetId,
    speed: 8.0,
    isHoming: gameState.currentTargetId != null,
    damage: 75.0,
    abilityName: 'Pyroblast',
    impactColor: Vector3(1.0, 0.5, 0.1),
    impactSize: 1.5,
  ));
  print('Pyroblast launched!');
}

/// Launch Arcane Missile projectile after cast completes.
void _launchArcaneMissile(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  final playerPos = gameState.activeTransform!.position;
  final targetPos = _getTargetPositionOrForward(gameState, playerPos);
  final direction = (targetPos - playerPos).normalized();
  final startPos = playerPos.clone() + direction * 1.0;
  startPos.y = playerPos.y;
  gameState.fireballs.add(Projectile(
    mesh: Mesh.cube(size: 0.4, color: Vector3(0.7, 0.3, 1.0)),
    transform: Transform3d(position: startPos, scale: Vector3(1, 1, 1)),
    velocity: direction * 18.0,
    targetId: gameState.currentTargetId,
    speed: 18.0,
    isHoming: gameState.currentTargetId != null,
    damage: 28.0,
    abilityName: 'Arcane Missile',
    impactColor: Vector3(0.8, 0.4, 1.0),
    impactSize: 0.7,
  ));
  print('Arcane Missile launched!');
}

/// Execute Frost Nova AoE effect after cast completes.
void _executeFrostNovaEffect(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  gameState.impactEffects.add(ImpactEffect(
    mesh: Mesh.cube(size: 8.0, color: Vector3(0.4, 0.7, 1.0)),
    transform: Transform3d(position: gameState.activeTransform!.position.clone(), scale: Vector3(1, 1, 1)),
    lifetime: 0.5,
  ));
  final frostNovaDmg = 20.0 * gameState.activeStance.damageMultiplier;
  final hit = CombatSystem.checkAndDamageEnemies(
    gameState,
    attackerPosition: gameState.activeTransform!.position,
    damage: frostNovaDmg,
    attackType: 'Frost Nova',
    impactColor: Vector3(0.5, 0.8, 1.0),
    impactSize: 0.5,
    collisionThreshold: 8.0,
  );
  if (hit) _applyLifesteal(gameState, frostNovaDmg);
  print('Frost Nova released!');
}

/// Execute Greater Heal effect after cast completes.
void _executeGreaterHealEffect(int slotIndex, GameState gameState) {
  final oldHealth = gameState.activeHealth;
  final effectiveHeal = 50.0 * gameState.activeStance.healingMultiplier;
  gameState.activeHealth = math.min(gameState.activeMaxHealth, gameState.activeHealth + effectiveHeal);
  final healedAmount = gameState.activeHealth - oldHealth;
  gameState.ability3Active = true;
  gameState.ability3ActiveTime = 0.0;
  _logHeal(gameState, 'Greater Heal', healedAmount);
  _showHealIndicator(gameState, healedAmount, gameState.activeTransform?.position);
  print('Greater Heal! Restored ${healedAmount.toStringAsFixed(1)} HP');
}

/// Generic projectile launch for unknown cast-time abilities.
void _executeGenericProjectileFromAbility(int slotIndex, GameState gameState, String abilityName) {
  if (gameState.activeTransform == null) return;
  final playerPos = gameState.activeTransform!.position;
  final targetPos = _getTargetPositionOrForward(gameState, playerPos);
  final direction = (targetPos - playerPos).normalized();
  final startPos = playerPos.clone() + direction * 1.0;
  startPos.y = playerPos.y;
  gameState.fireballs.add(Projectile(
    mesh: Mesh.cube(size: 0.4, color: Vector3(1.0, 1.0, 1.0)),
    transform: Transform3d(position: startPos, scale: Vector3(1, 1, 1)),
    velocity: direction * 12.0,
    targetId: gameState.currentTargetId,
    speed: 12.0,
    isHoming: gameState.currentTargetId != null,
    damage: 30.0,
    abilityName: abilityName,
    impactColor: Vector3(1.0, 1.0, 1.0),
    impactSize: 0.6,
  ));
  print('$abilityName launched!');
}

// ==================== WINDUP ABILITY EFFECTS ====================

/// Execute Heavy Strike melee hit after windup completes.
void _executeHeavyStrikeEffect(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  _faceCurrentTarget(gameState);
  final damage = 75.0 * gameState.activeStance.damageMultiplier;
  if (gameState.currentTargetId != null) {
    _autoHitCurrentTarget(gameState, damage: damage, attackType: 'Heavy Strike',
        impactColor: Vector3(1.0, 0.4, 0.2), impactSize: 1.0, isMelee: true);
  } else {
    final forward = Vector3(-math.sin(_radians(gameState.activeRotation)), 0, -math.cos(_radians(gameState.activeRotation)));
    CombatSystem.checkAndDamageEnemies(gameState,
        attackerPosition: gameState.activeTransform!.position + forward * 2.5,
        damage: damage, attackType: 'Heavy Strike',
        impactColor: Vector3(1.0, 0.4, 0.2), impactSize: 1.0,
        collisionThreshold: 4.0, isMeleeDamage: true);
  }
  print('Heavy Strike hit!');
}

/// Execute Whirlwind AoE after windup completes.
void _executeWhirlwindEffect(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  gameState.impactEffects.add(ImpactEffect(
    mesh: Mesh.cube(size: 5.0, color: Vector3(0.6, 0.6, 0.7)),
    transform: Transform3d(position: gameState.activeTransform!.position.clone(), scale: Vector3(1, 1, 1)),
    lifetime: 0.8,
  ));
  final whirlwindDmg = 48.0 * gameState.activeStance.damageMultiplier;
  final hit = CombatSystem.checkAndDamageEnemies(gameState,
      attackerPosition: gameState.activeTransform!.position,
      damage: whirlwindDmg, attackType: 'Whirlwind',
      impactColor: Vector3(0.7, 0.7, 0.8), impactSize: 0.6,
      collisionThreshold: 5.0, isMeleeDamage: true);
  if (hit) _applyLifesteal(gameState, whirlwindDmg);
  print('Whirlwind!');
}

/// Execute Crushing Blow heavy melee hit after windup completes.
void _executeCrushingBlowEffect(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  _faceCurrentTarget(gameState);
  final forward = Vector3(-math.sin(_radians(gameState.activeRotation)), 0, -math.cos(_radians(gameState.activeRotation)));
  final strikePosition = gameState.activeTransform!.position + forward * 2.0;
  gameState.impactEffects.add(ImpactEffect(
    mesh: Mesh.cube(size: 1.2, color: Vector3(0.7, 0.3, 0.1)),
    transform: Transform3d(position: strikePosition, scale: Vector3(1, 1, 1)),
    lifetime: 0.5,
  ));
  final damage = 110.0 * gameState.activeStance.damageMultiplier;
  if (gameState.currentTargetId != null) {
    _autoHitCurrentTarget(gameState, damage: damage, attackType: 'Crushing Blow',
        impactColor: Vector3(0.7, 0.3, 0.1), impactSize: 1.2, isMelee: true);
  } else {
    CombatSystem.checkAndDamageEnemies(gameState,
        attackerPosition: strikePosition, damage: damage, attackType: 'Crushing Blow',
        impactColor: Vector3(0.7, 0.3, 0.1), impactSize: 1.2,
        collisionThreshold: 3.5, isMeleeDamage: true);
  }
  print('Crushing Blow devastates the target!');
}

/// Generic windup melee for unknown windup abilities — reads damage/range from AbilityData.
void _executeGenericWindupMelee(int slotIndex, GameState gameState, String abilityName) {
  if (gameState.activeTransform == null) return;
  _faceCurrentTarget(gameState);
  final abilityData = globalActionBarConfig?.getSlotAbilityData(slotIndex);
  final ability = abilityData != null
      ? (globalAbilityOverrideManager?.getEffectiveAbility(abilityData) ?? abilityData)
      : null;
  final damage = (ability?.damage ?? 40.0) * gameState.activeStance.damageMultiplier;
  final impactColor = ability?.impactColor ?? Vector3(0.8, 0.8, 0.8);
  final impactSize = ability?.impactSize ?? 0.8;

  bool hitRegistered = false;
  if (gameState.currentTargetId != null) {
    hitRegistered = _autoHitCurrentTarget(gameState,
        damage: damage, attackType: abilityName,
        impactColor: impactColor, impactSize: impactSize, isMelee: true);
  } else {
    final forward = Vector3(-math.sin(_radians(gameState.activeRotation)), 0, -math.cos(_radians(gameState.activeRotation)));
    hitRegistered = CombatSystem.checkAndDamageEnemies(gameState,
        attackerPosition: gameState.activeTransform!.position + forward * (ability?.range ?? 2.5),
        damage: damage, attackType: abilityName,
        impactColor: impactColor, impactSize: impactSize,
        collisionThreshold: ability?.effectiveHitRadius ?? 3.5, isMeleeDamage: true);
  }
  if (hitRegistered && ability != null) {
    _applyMeleeStatusEffect(gameState, ability);
    _applyMeleeVulnerability(gameState, ability);
  }
  print('$abilityName!');
}

/// Get target position or a point 30 units ahead of the player (for untargeted projectiles).
Vector3 _getTargetPositionOrForward(GameState gameState, Vector3 playerPos) {
  if (gameState.currentTargetId != null) {
    final targetPos = _getTargetPosition(gameState, gameState.currentTargetId!);
    if (targetPos != null) return targetPos;
  }
  final forward = Vector3(-math.sin(_radians(gameState.activeRotation)), 0, -math.cos(_radians(gameState.activeRotation)));
  return playerPos + forward * 30.0;
}

// ==================== COMBAT LOG / INDICATOR HELPERS ====================

/// Log a heal event to the combat log.
void _logHeal(GameState gameState, String abilityName, double healedAmount) {
  gameState.combatLogMessages.add(CombatLogEntry(
    source: 'Player',
    action: abilityName,
    type: CombatLogType.heal,
    amount: healedAmount,
    target: 'Player',
  ));
  if (gameState.combatLogMessages.length > 250) {
    gameState.combatLogMessages.removeRange(0, gameState.combatLogMessages.length - 200);
  }
}

/// Show a green floating heal number above the healed unit.
void _showHealIndicator(GameState gameState, double healAmount, Vector3? position) {
  if (healAmount <= 0 || position == null) return;
  final pos = position.clone();
  pos.y += 2.0;
  gameState.damageIndicators.add(DamageIndicator(
    damage: healAmount,
    worldPosition: pos,
    isHeal: true,
  ));
}
