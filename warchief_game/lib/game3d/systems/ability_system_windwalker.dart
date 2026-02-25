part of 'ability_system.dart';

// ==================== WIND WALKER ABILITIES ====================

/// Gale Step — forward dash through enemies dealing damage.
void _executeGaleStep(int slotIndex, GameState gameState) =>
    _startDash(slotIndex, gameState, _effective(WindWalkerAbilities.galeStep), 'Gale Step activated!');

/// Zephyr Roll — forward dodge-roll with brief invulnerability.
void _executeZephyrRoll(int slotIndex, GameState gameState) {
  if (gameState.ability4Active) return;
  final ability = _effective(WindWalkerAbilities.zephyrRoll);
  gameState.ability4Active = true;
  gameState.ability4ActiveTime = 0.0;
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  gameState.ability4HitRegistered = false;
  print('Zephyr Roll! Brief invulnerability.');
}

/// Tailwind Retreat — move backward and knockback nearby enemies.
void _executeTailwindRetreat(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  final ability = _effective(WindWalkerAbilities.tailwindRetreat);
  final backward = Vector3(
    math.sin(_radians(gameState.activeRotation)),
    0,
    math.cos(_radians(gameState.activeRotation)),
  );
  gameState.activeTransform!.position += backward * ability.range;
  if (ability.knockbackForce > 0) {
    CombatSystem.checkAndDamageEnemies(
      gameState,
      attackerPosition: gameState.activeTransform!.position - backward * 3.0,
      damage: 0.0,
      attackType: ability.name,
      impactColor: ability.impactColor,
      impactSize: ability.impactSize,
      collisionThreshold: 4.0,
    );
  }
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  print('Tailwind Retreat! Backflipped away.');
}

/// Flying Serpent Strike — long dash with damage.
void _executeFlyingSerpentStrike(int slotIndex, GameState gameState) =>
    _startDash(slotIndex, gameState, _effective(WindWalkerAbilities.flyingSerpentStrike), 'Flying Serpent Strike activated!');

/// Take Flight — toggle flight mode on/off.
void _executeTakeFlight(int slotIndex, GameState gameState) {
  gameState.toggleFlight();
  _setCooldownForSlot(slotIndex, _effective(WindWalkerAbilities.takeFlight).cooldown, gameState);
}

/// Cyclone Dive — leap and AoE slam dealing damage.
void _executeCycloneDive(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  final ability = _effective(WindWalkerAbilities.cycloneDive);
  gameState.impactEffects.add(ImpactEffect(
    mesh: Mesh.cube(size: ability.aoeRadius > 0 ? ability.aoeRadius : 3.0, color: ability.color),
    transform: Transform3d(position: gameState.activeTransform!.position.clone(), scale: Vector3(1, 1, 1)),
    lifetime: 0.8,
  ));
  CombatSystem.checkAndDamageEnemies(
    gameState,
    attackerPosition: gameState.activeTransform!.position,
    damage: ability.damage * gameState.activeStance.damageMultiplier,
    attackType: ability.name,
    impactColor: ability.impactColor,
    impactSize: ability.impactSize,
    collisionThreshold: ability.aoeRadius,
    isMeleeDamage: true,
  );
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  print('Cyclone Dive! AoE slam!');
}

/// Wind Wall — blocks projectiles (visual + cooldown; blocking logic is deferred).
void _executeWindWall(int slotIndex, GameState gameState) {
  final ability = _effective(WindWalkerAbilities.windWall);
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  print('Wind Wall deployed! Blocking projectiles for ${ability.duration}s.');
}

/// Tempest Charge — charge to target with knockback.
void _executeTempestCharge(int slotIndex, GameState gameState) =>
    _executeGenericMelee(slotIndex, gameState, _effective(WindWalkerAbilities.tempestCharge), 'Tempest Charge!');

/// Healing Gale — heal self over time.
void _executeHealingGale(int slotIndex, GameState gameState) =>
    _executeGenericHeal(slotIndex, gameState, _effective(WindWalkerAbilities.healingGale), 'Healing Gale!');

/// Sovereign of the Sky — 12s buff: enhanced flight speed and reduced mana costs.
void _executeSovereignOfTheSky(int slotIndex, GameState gameState) {
  final ability = _effective(WindWalkerAbilities.sovereignOfTheSky);
  gameState.sovereignBuffActive = true;
  gameState.sovereignBuffTimer = ability.duration;
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  print('Sovereign of the Sky! Enhanced flight for ${ability.duration}s.');
}

/// Wind Affinity — double white mana regen rate for 15 seconds.
void _executeWindAffinity(int slotIndex, GameState gameState) {
  final ability = _effective(WindWalkerAbilities.windAffinity);
  gameState.windAffinityActive = true;
  gameState.windAffinityTimer = ability.duration;
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  print('Wind Affinity! White mana regen doubled for ${ability.duration}s.');
}

/// Silent Mind — fully restore white mana; next white ability is free and instant.
void _executeSilentMind(int slotIndex, GameState gameState) {
  final ability = _effective(WindWalkerAbilities.silentMind);
  gameState.activeWhiteMana = gameState.activeMaxWhiteMana;
  gameState.silentMindActive = true;
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  print('Silent Mind! White mana fully restored. Next white ability is free and instant.');
}

/// Windshear — 90-degree cone AoE: enemies take damage, allies are healed.
void _executeWindshear(int slotIndex, GameState gameState) {
  if (gameState.activeTransform == null) return;
  final ability = _effective(WindWalkerAbilities.windshear);
  final playerPos = gameState.activeTransform!.position;
  final facingRad = gameState.activeRotation * math.pi / 180.0;
  final facingX = -math.sin(facingRad);
  final facingZ = -math.cos(facingRad);
  const coneHalfAngle = 45.0;
  final coneRange = ability.aoeRadius;

  if (gameState.monsterHealth > 0 && gameState.monsterTransform != null) {
    if (_isInCone(playerPos, facingX, facingZ, gameState.monsterTransform!.position, coneHalfAngle, coneRange)) {
      CombatSystem.checkAndDamageMonster(
        gameState,
        attackerPosition: gameState.monsterTransform!.position,
        damage: ability.damage,
        attackType: ability.name,
        impactColor: ability.impactColor,
        impactSize: ability.impactSize,
        collisionThreshold: 5.0,
        showDamageIndicator: true,
      );
    }
  }

  for (final minion in gameState.aliveMinions) {
    if (_isInCone(playerPos, facingX, facingZ, minion.transform.position, coneHalfAngle, coneRange)) {
      CombatSystem.damageMinion(
        gameState,
        minionInstanceId: minion.instanceId,
        damage: ability.damage,
        attackType: ability.name,
        impactColor: ability.impactColor,
        impactSize: ability.impactSize,
        showDamageIndicator: true,
      );
    }
  }

  for (final ally in gameState.allies) {
    if (ally.health <= 0) continue;
    if (_isInCone(playerPos, facingX, facingZ, ally.transform.position, coneHalfAngle, coneRange)) {
      final oldAllyHealth = ally.health;
      ally.health = math.min(ally.maxHealth, ally.health + ability.healAmount);
      _showHealIndicator(gameState, ally.health - oldAllyHealth, ally.transform.position);
    }
  }

  gameState.impactEffects.add(ImpactEffect(
    mesh: Mesh.cube(size: 4.0, color: ability.color),
    transform: Transform3d(position: playerPos.clone(), scale: Vector3(1, 1, 1)),
    lifetime: 0.8,
  ));
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  print('Windshear! Cone AoE — enemies damaged, allies healed.');
}

/// Wind Warp — ground dash or double flight speed for 5s when flying.
void _executeWindWarp(int slotIndex, GameState gameState) {
  final ability = _effective(WindWalkerAbilities.windWarp);
  if (gameState.isFlying) {
    gameState.windWarpSpeedActive = true;
    gameState.windWarpSpeedTimer = 5.0;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Wind Warp! Flight speed doubled for 5s.');
  } else {
    _startDash(slotIndex, gameState, ability, 'Wind Warp! Dashing forward.');
  }
}

// ==================== CONE DETECTION HELPER ====================

/// True if [target] lies within a cone defined by [origin], facing direction
/// ([facingX], [facingZ]), [halfAngleDeg], and [range].
bool _isInCone(Vector3 origin, double facingX, double facingZ, Vector3 target, double halfAngleDeg, double range) {
  final dx = target.x - origin.x;
  final dz = target.z - origin.z;
  final distSq = dx * dx + dz * dz;
  if (distSq > range * range || distSq < 0.000001) return false;
  final dist = math.sqrt(distSq);
  final dot = (facingX * (dx / dist) + facingZ * (dz / dist)).clamp(-1.0, 1.0);
  return dot >= math.cos(halfAngleDeg * math.pi / 180.0);
}
