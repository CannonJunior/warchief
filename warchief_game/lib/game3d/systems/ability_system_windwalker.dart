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
  debugPrint('Zephyr Roll! Brief invulnerability.');
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
  debugPrint('Cyclone Dive! AoE slam!');
}

/// Wind Wall — blocks projectiles (visual + cooldown; blocking logic is deferred).
void _executeWindWall(int slotIndex, GameState gameState) {
  final ability = _effective(WindWalkerAbilities.windWall);
  _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  debugPrint('Wind Wall deployed! Blocking projectiles for ${ability.duration}s.');
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
  debugPrint('Sovereign of the Sky! Enhanced flight for ${ability.duration}s.');
}

/// Wind Warp — ground dash or double flight speed for 5s when flying.
void _executeWindWarp(int slotIndex, GameState gameState) {
  final ability = _effective(WindWalkerAbilities.windWarp);
  if (gameState.isFlying) {
    gameState.windWarpSpeedActive = true;
    gameState.windWarpSpeedTimer = 5.0;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    debugPrint('Wind Warp! Flight speed doubled for 5s.');
  } else {
    _startDash(slotIndex, gameState, ability, 'Wind Warp! Dashing forward.');
  }
}

