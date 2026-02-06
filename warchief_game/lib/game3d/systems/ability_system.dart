import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../state/abilities_config.dart';
import '../state/action_bar_config.dart' show globalActionBarConfig;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/projectile.dart';
import '../../models/impact_effect.dart';
import 'combat_system.dart';

/// Ability System - Handles all player ability logic
///
/// Manages player abilities including:
/// - Ability cooldown updates
/// - Dynamic ability execution based on ActionBarConfig
/// - Ability implementations: Sword, Fireball, Heal, Dash Attack, and more
/// - Impact effects (visual feedback for hits)
class AbilitySystem {
  AbilitySystem._(); // Private constructor to prevent instantiation

  /// Updates all ability systems
  ///
  /// This is the main entry point for the ability system. It updates cooldowns,
  /// active abilities, projectiles, and visual effects.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void update(double dt, GameState gameState) {
    updateCooldowns(dt, gameState);
    updateAbility1(dt, gameState);
    updateAbility2(dt, gameState);
    updateAbility3(dt, gameState);
    updateAbility4(dt, gameState);
    updateImpactEffects(dt, gameState);
  }

  /// Updates all ability cooldowns
  ///
  /// Decrements cooldown timers for all abilities.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void updateCooldowns(double dt, GameState gameState) {
    if (gameState.ability1Cooldown > 0) gameState.ability1Cooldown -= dt;
    if (gameState.ability2Cooldown > 0) gameState.ability2Cooldown -= dt;
    if (gameState.ability3Cooldown > 0) gameState.ability3Cooldown -= dt;
    if (gameState.ability4Cooldown > 0) gameState.ability4Cooldown -= dt;
  }

  // ==================== DYNAMIC ABILITY EXECUTION ====================

  /// Execute ability in slot based on configured ability name
  ///
  /// This method looks up the ability configured for the slot and
  /// executes the appropriate ability logic.
  static void executeSlotAbility(int slotIndex, GameState gameState) {
    final config = globalActionBarConfig;
    if (config == null) {
      // Fallback to default behavior
      _executeDefaultSlotAbility(slotIndex, gameState);
      return;
    }

    final abilityName = config.getSlotAbility(slotIndex);
    _executeAbilityByName(abilityName, slotIndex, gameState);
  }

  /// Execute ability by name
  static void _executeAbilityByName(String abilityName, int slotIndex, GameState gameState) {
    // Get cooldown for this slot
    final cooldown = _getCooldownForSlot(slotIndex, gameState);
    if (cooldown > 0) return;

    // Map ability names to their execution logic
    switch (abilityName) {
      // Player abilities
      case 'Sword':
        _executeSword(slotIndex, gameState);
        break;
      case 'Fireball':
        _executeFireball(slotIndex, gameState);
        break;
      case 'Heal':
        _executeHeal(slotIndex, gameState);
        break;
      case 'Dash Attack':
        _executeDashAttack(slotIndex, gameState);
        break;

      // Warrior abilities
      case 'Shield Bash':
        _executeShieldBash(slotIndex, gameState);
        break;
      case 'Whirlwind':
        _executeWhirlwind(slotIndex, gameState);
        break;
      case 'Charge':
        _executeCharge(slotIndex, gameState);
        break;
      case 'Taunt':
        _executeTaunt(slotIndex, gameState);
        break;
      case 'Fortify':
        _executeFortify(slotIndex, gameState);
        break;

      // Mage abilities
      case 'Frost Bolt':
        _executeFrostBolt(slotIndex, gameState);
        break;
      case 'Blizzard':
        _executeBlizzard(slotIndex, gameState);
        break;
      case 'Lightning Bolt':
        _executeLightningBolt(slotIndex, gameState);
        break;
      case 'Chain Lightning':
        _executeChainLightning(slotIndex, gameState);
        break;
      case 'Meteor':
        _executeMeteor(slotIndex, gameState);
        break;
      case 'Arcane Shield':
        _executeArcaneShield(slotIndex, gameState);
        break;
      case 'Teleport':
        _executeTeleport(slotIndex, gameState);
        break;

      // Rogue abilities
      case 'Backstab':
        _executeBackstab(slotIndex, gameState);
        break;
      case 'Poison Blade':
        _executePoisonBlade(slotIndex, gameState);
        break;
      case 'Smoke Bomb':
        _executeSmokeBomb(slotIndex, gameState);
        break;
      case 'Fan of Knives':
        _executeFanOfKnives(slotIndex, gameState);
        break;
      case 'Shadow Step':
        _executeShadowStep(slotIndex, gameState);
        break;

      // Healer abilities
      case 'Holy Light':
        _executeHolyLight(slotIndex, gameState);
        break;
      case 'Rejuvenation':
        _executeRejuvenation(slotIndex, gameState);
        break;
      case 'Circle of Healing':
        _executeCircleOfHealing(slotIndex, gameState);
        break;
      case 'Blessing of Strength':
        _executeBlessingOfStrength(slotIndex, gameState);
        break;
      case 'Purify':
        _executePurify(slotIndex, gameState);
        break;

      // Nature abilities
      case 'Entangling Roots':
        _executeEntanglingRoots(slotIndex, gameState);
        break;
      case 'Thorns':
        _executeThorns(slotIndex, gameState);
        break;
      case 'Nature\'s Wrath':
        _executeNaturesWrath(slotIndex, gameState);
        break;

      // Necromancer abilities
      case 'Life Drain':
        _executeLifeDrain(slotIndex, gameState);
        break;
      case 'Curse of Weakness':
        _executeCurseOfWeakness(slotIndex, gameState);
        break;
      case 'Fear':
        _executeFear(slotIndex, gameState);
        break;
      case 'Summon Skeleton':
        _executeSummonSkeleton(slotIndex, gameState);
        break;

      // Elemental abilities
      case 'Ice Lance':
        _executeIceLance(slotIndex, gameState);
        break;
      case 'Flame Wave':
        _executeFlameWave(slotIndex, gameState);
        break;
      case 'Earthquake':
        _executeEarthquake(slotIndex, gameState);
        break;

      // Utility abilities
      case 'Sprint':
        _executeSprint(slotIndex, gameState);
        break;
      case 'Battle Shout':
        _executeBattleShout(slotIndex, gameState);
        break;

      default:
        print('[ABILITY] Unknown ability: $abilityName');
        _executeDefaultSlotAbility(slotIndex, gameState);
    }
  }

  /// Execute default ability for slot (fallback)
  static void _executeDefaultSlotAbility(int slotIndex, GameState gameState) {
    switch (slotIndex) {
      case 0:
        _executeSword(slotIndex, gameState);
        break;
      case 1:
        _executeFireball(slotIndex, gameState);
        break;
      case 2:
        _executeHeal(slotIndex, gameState);
        break;
      case 3:
        _executeDashAttack(slotIndex, gameState);
        break;
    }
  }

  /// Get cooldown for a slot
  static double _getCooldownForSlot(int slotIndex, GameState gameState) {
    switch (slotIndex) {
      case 0: return gameState.ability1Cooldown;
      case 1: return gameState.ability2Cooldown;
      case 2: return gameState.ability3Cooldown;
      case 3: return gameState.ability4Cooldown;
      default: return 0;
    }
  }

  /// Set cooldown for a slot
  static void _setCooldownForSlot(int slotIndex, double cooldown, GameState gameState) {
    switch (slotIndex) {
      case 0:
        gameState.ability1Cooldown = cooldown;
        break;
      case 1:
        gameState.ability2Cooldown = cooldown;
        break;
      case 2:
        gameState.ability3Cooldown = cooldown;
        break;
      case 3:
        gameState.ability4Cooldown = cooldown;
        break;
    }
  }

  // ==================== ABILITY IMPLEMENTATIONS ====================

  /// Execute Sword (melee attack)
  static void _executeSword(int slotIndex, GameState gameState) {
    if (gameState.ability1Active) return; // Prevent if already active

    gameState.ability1Active = true;
    gameState.ability1ActiveTime = 0.0;
    _setCooldownForSlot(slotIndex, AbilitiesConfig.playerSword.cooldown, gameState);
    gameState.ability1HitRegistered = false;
    print('Sword attack activated!');
  }

  /// Execute Fireball (ranged projectile)
  static void _executeFireball(int slotIndex, GameState gameState) {
    if (gameState.playerTransform == null) return;

    final fireball = AbilitiesConfig.playerFireball;
    final playerPos = gameState.playerTransform!.position;

    // Get target position for homing
    Vector3? targetPos;
    String? targetId = gameState.currentTargetId;

    if (targetId != null) {
      targetPos = _getTargetPosition(gameState, targetId);
    }

    // Calculate initial direction - toward target if available, otherwise forward
    Vector3 direction;
    if (targetPos != null) {
      direction = (targetPos - playerPos).normalized();
    } else {
      // Fallback to player facing direction
      direction = Vector3(
        -math.sin(_radians(gameState.playerRotation)),
        0,
        -math.cos(_radians(gameState.playerRotation)),
      );
    }

    final fireballMesh = Mesh.cube(
      size: fireball.projectileSize,
      color: fireball.color,
    );

    final startPos = playerPos.clone() + direction * 1.0;
    startPos.y = playerPos.y;

    final fireballTransform = Transform3d(
      position: startPos,
      scale: Vector3(1, 1, 1),
    );

    gameState.fireballs.add(Projectile(
      mesh: fireballMesh,
      transform: fireballTransform,
      velocity: direction * fireball.projectileSpeed,
      targetId: targetId,
      speed: fireball.projectileSpeed,
      isHoming: targetId != null, // Only home if we have a target
      damage: fireball.damage,
      abilityName: fireball.name,
      impactColor: fireball.impactColor,
      impactSize: fireball.impactSize,
    ));

    _setCooldownForSlot(slotIndex, fireball.cooldown, gameState);
    print('${fireball.name} launched${targetId != null ? " at $targetId" : ""}!');
  }

  /// Get position of a target by ID
  static Vector3? _getTargetPosition(GameState gameState, String targetId) {
    if (targetId == 'boss') {
      if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
        return gameState.monsterTransform!.position;
      }
    } else {
      // Find minion by instance ID
      for (final minion in gameState.aliveMinions) {
        if (minion.instanceId == targetId) {
          return minion.transform.position;
        }
      }
    }
    return null;
  }

  /// Execute Heal (self heal)
  static void _executeHeal(int slotIndex, GameState gameState) {
    if (gameState.ability3Active) return;

    gameState.ability3Active = true;
    gameState.ability3ActiveTime = 0.0;

    final healAbility = AbilitiesConfig.playerHeal;
    final oldHealth = gameState.playerHealth;
    gameState.playerHealth = math.min(gameState.playerMaxHealth, gameState.playerHealth + healAbility.healAmount);
    final healedAmount = gameState.playerHealth - oldHealth;

    _setCooldownForSlot(slotIndex, healAbility.cooldown, gameState);
    print('[HEAL] Player heal activated! Restored ${healedAmount.toStringAsFixed(1)} HP');
  }

  /// Execute Dash Attack (movement + damage)
  static void _executeDashAttack(int slotIndex, GameState gameState) {
    if (gameState.ability4Active) return;

    gameState.ability4Active = true;
    gameState.ability4ActiveTime = 0.0;
    _setCooldownForSlot(slotIndex, AbilitiesConfig.playerDashAttack.cooldown, gameState);
    gameState.ability4HitRegistered = false;
    print('Dash Attack activated!');
  }

  // ==================== WARRIOR ABILITIES ====================

  static void _executeShieldBash(int slotIndex, GameState gameState) {
    final ability = WarriorAbilities.shieldBash;
    _executeGenericMelee(slotIndex, gameState, ability, 'Shield Bash activated!');
  }

  static void _executeWhirlwind(int slotIndex, GameState gameState) {
    final ability = WarriorAbilities.whirlwind;
    _executeGenericAoE(slotIndex, gameState, ability, 'Whirlwind activated!');
  }

  static void _executeCharge(int slotIndex, GameState gameState) {
    // Similar to dash attack
    if (gameState.ability4Active) return;
    gameState.ability4Active = true;
    gameState.ability4ActiveTime = 0.0;
    _setCooldownForSlot(slotIndex, WarriorAbilities.charge.cooldown, gameState);
    gameState.ability4HitRegistered = false;
    print('Charge activated!');
  }

  static void _executeTaunt(int slotIndex, GameState gameState) {
    final ability = WarriorAbilities.taunt;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Taunt activated! Enemies now focus you.');
  }

  static void _executeFortify(int slotIndex, GameState gameState) {
    final ability = WarriorAbilities.fortify;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Fortify activated! Defense increased.');
  }

  // ==================== MAGE ABILITIES ====================

  static void _executeFrostBolt(int slotIndex, GameState gameState) {
    final ability = MageAbilities.frostBolt;
    _executeGenericProjectile(slotIndex, gameState, ability, 'Frost Bolt launched!');
  }

  static void _executeBlizzard(int slotIndex, GameState gameState) {
    final ability = MageAbilities.blizzard;
    _executeGenericAoE(slotIndex, gameState, ability, 'Blizzard activated!');
  }

  static void _executeLightningBolt(int slotIndex, GameState gameState) {
    final ability = MageAbilities.lightningBolt;
    _executeGenericProjectile(slotIndex, gameState, ability, 'Lightning Bolt launched!');
  }

  static void _executeChainLightning(int slotIndex, GameState gameState) {
    final ability = MageAbilities.chainLightning;
    _executeGenericProjectile(slotIndex, gameState, ability, 'Chain Lightning launched!');
  }

  static void _executeMeteor(int slotIndex, GameState gameState) {
    final ability = MageAbilities.meteor;
    _executeGenericAoE(slotIndex, gameState, ability, 'Meteor incoming!');
  }

  static void _executeArcaneShield(int slotIndex, GameState gameState) {
    final ability = MageAbilities.arcaneShield;
    gameState.ability3Active = true;
    gameState.ability3ActiveTime = 0.0;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Arcane Shield activated!');
  }

  static void _executeTeleport(int slotIndex, GameState gameState) {
    if (gameState.playerTransform == null) return;
    final ability = MageAbilities.teleport;

    // Teleport forward
    final forward = Vector3(
      -math.sin(_radians(gameState.playerRotation)),
      0,
      -math.cos(_radians(gameState.playerRotation)),
    );
    gameState.playerTransform!.position += forward * ability.range;

    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Teleport!');
  }

  // ==================== ROGUE ABILITIES ====================

  static void _executeBackstab(int slotIndex, GameState gameState) {
    final ability = RogueAbilities.backstab;
    _executeGenericMelee(slotIndex, gameState, ability, 'Backstab!');
  }

  static void _executePoisonBlade(int slotIndex, GameState gameState) {
    final ability = RogueAbilities.poisonBlade;
    _executeGenericMelee(slotIndex, gameState, ability, 'Poison Blade!');
  }

  static void _executeSmokeBomb(int slotIndex, GameState gameState) {
    final ability = RogueAbilities.smokeBomb;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Smoke Bomb deployed!');
  }

  static void _executeFanOfKnives(int slotIndex, GameState gameState) {
    final ability = RogueAbilities.fanOfKnives;
    _executeGenericAoE(slotIndex, gameState, ability, 'Fan of Knives!');
  }

  static void _executeShadowStep(int slotIndex, GameState gameState) {
    _executeTeleport(slotIndex, gameState);
    print('Shadow Step!');
  }

  // ==================== HEALER ABILITIES ====================

  static void _executeHolyLight(int slotIndex, GameState gameState) {
    final ability = HealerAbilities.holyLight;
    _executeGenericHeal(slotIndex, gameState, ability, 'Holy Light!');
  }

  static void _executeRejuvenation(int slotIndex, GameState gameState) {
    final ability = HealerAbilities.rejuvenation;
    _executeGenericHeal(slotIndex, gameState, ability, 'Rejuvenation!');
  }

  static void _executeCircleOfHealing(int slotIndex, GameState gameState) {
    final ability = HealerAbilities.circleOfHealing;
    _executeGenericHeal(slotIndex, gameState, ability, 'Circle of Healing!');
  }

  static void _executeBlessingOfStrength(int slotIndex, GameState gameState) {
    final ability = HealerAbilities.blessingOfStrength;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Blessing of Strength! Damage increased.');
  }

  static void _executePurify(int slotIndex, GameState gameState) {
    final ability = HealerAbilities.purify;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Purify! Debuffs removed.');
  }

  // ==================== NATURE ABILITIES ====================

  static void _executeEntanglingRoots(int slotIndex, GameState gameState) {
    final ability = NatureAbilities.entanglingRoots;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Entangling Roots! Enemy immobilized.');
  }

  static void _executeThorns(int slotIndex, GameState gameState) {
    final ability = NatureAbilities.thorns;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Thorns activated! Attackers take damage.');
  }

  static void _executeNaturesWrath(int slotIndex, GameState gameState) {
    final ability = NatureAbilities.naturesWrath;
    _executeGenericProjectile(slotIndex, gameState, ability, 'Nature\'s Wrath!');
  }

  // ==================== NECROMANCER ABILITIES ====================

  static void _executeLifeDrain(int slotIndex, GameState gameState) {
    final ability = NecromancerAbilities.lifeDrain;
    // Damage enemy and heal self
    _executeGenericProjectile(slotIndex, gameState, ability, 'Life Drain!');
    gameState.playerHealth = math.min(gameState.playerMaxHealth, gameState.playerHealth + ability.healAmount);
  }

  static void _executeCurseOfWeakness(int slotIndex, GameState gameState) {
    final ability = NecromancerAbilities.curseOfWeakness;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Curse of Weakness! Enemy damage reduced.');
  }

  static void _executeFear(int slotIndex, GameState gameState) {
    final ability = NecromancerAbilities.fear;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Fear! Enemy flees.');
  }

  static void _executeSummonSkeleton(int slotIndex, GameState gameState) {
    final ability = NecromancerAbilities.summonSkeleton;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Summon Skeleton! A skeleton rises to aid you.');
  }

  // ==================== ELEMENTAL ABILITIES ====================

  static void _executeIceLance(int slotIndex, GameState gameState) {
    final ability = ElementalAbilities.iceLance;
    _executeGenericProjectile(slotIndex, gameState, ability, 'Ice Lance!');
  }

  static void _executeFlameWave(int slotIndex, GameState gameState) {
    final ability = ElementalAbilities.flameWave;
    _executeGenericAoE(slotIndex, gameState, ability, 'Flame Wave!');
  }

  static void _executeEarthquake(int slotIndex, GameState gameState) {
    final ability = ElementalAbilities.earthquake;
    _executeGenericAoE(slotIndex, gameState, ability, 'Earthquake!');
  }

  // ==================== UTILITY ABILITIES ====================

  static void _executeSprint(int slotIndex, GameState gameState) {
    final ability = UtilityAbilities.sprint;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Sprint! Movement speed increased.');
  }

  static void _executeBattleShout(int slotIndex, GameState gameState) {
    final ability = UtilityAbilities.battleShout;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Battle Shout! Allies empowered.');
  }

  // ==================== GENERIC ABILITY HELPERS ====================

  /// Generic melee attack execution
  static void _executeGenericMelee(int slotIndex, GameState gameState, AbilityData ability, String message) {
    if (gameState.ability1Active) return;

    gameState.ability1Active = true;
    gameState.ability1ActiveTime = 0.0;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    gameState.ability1HitRegistered = false;
    print(message);
  }

  /// Generic projectile attack execution (with homing toward current target)
  static void _executeGenericProjectile(int slotIndex, GameState gameState, AbilityData ability, String message) {
    if (gameState.playerTransform == null) return;

    final playerPos = gameState.playerTransform!.position;
    final projectileSpeed = ability.projectileSpeed > 0 ? ability.projectileSpeed : 10.0;

    // Get target position for homing
    Vector3? targetPos;
    String? targetId = gameState.currentTargetId;

    if (targetId != null) {
      targetPos = _getTargetPosition(gameState, targetId);
    }

    // Calculate initial direction - toward target if available, otherwise forward
    Vector3 direction;
    if (targetPos != null) {
      direction = (targetPos - playerPos).normalized();
    } else {
      // Fallback to player facing direction
      direction = Vector3(
        -math.sin(_radians(gameState.playerRotation)),
        0,
        -math.cos(_radians(gameState.playerRotation)),
      );
    }

    final projectileMesh = Mesh.cube(
      size: ability.projectileSize > 0 ? ability.projectileSize : 0.4,
      color: ability.color,
    );

    final startPos = playerPos.clone() + direction * 1.0;
    startPos.y = playerPos.y;

    final projectileTransform = Transform3d(
      position: startPos,
      scale: Vector3(1, 1, 1),
    );

    gameState.fireballs.add(Projectile(
      mesh: projectileMesh,
      transform: projectileTransform,
      velocity: direction * projectileSpeed,
      targetId: targetId,
      speed: projectileSpeed,
      isHoming: targetId != null, // Only home if we have a target
      damage: ability.damage,
      abilityName: ability.name,
      impactColor: ability.impactColor,
      impactSize: ability.impactSize,
    ));

    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('$message${targetId != null ? " (targeting $targetId)" : ""}');
  }

  /// Generic AoE attack execution
  static void _executeGenericAoE(int slotIndex, GameState gameState, AbilityData ability, String message) {
    if (gameState.playerTransform == null) return;

    // Create impact effect at player location
    final impactMesh = Mesh.cube(
      size: ability.aoeRadius > 0 ? ability.aoeRadius : 2.0,
      color: ability.color,
    );
    final impactTransform = Transform3d(
      position: gameState.playerTransform!.position.clone(),
      scale: Vector3(1, 1, 1),
    );
    gameState.impactEffects.add(ImpactEffect(
      mesh: impactMesh,
      transform: impactTransform,
      lifetime: 0.5,
    ));

    // Damage nearby enemies
    CombatSystem.checkAndDamageEnemies(
      gameState,
      attackerPosition: gameState.playerTransform!.position,
      damage: ability.damage,
      attackType: ability.name,
      impactColor: ability.impactColor,
      impactSize: ability.impactSize,
    );

    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print(message);
  }

  /// Generic heal execution
  static void _executeGenericHeal(int slotIndex, GameState gameState, AbilityData ability, String message) {
    if (gameState.ability3Active) return;

    gameState.ability3Active = true;
    gameState.ability3ActiveTime = 0.0;

    final oldHealth = gameState.playerHealth;
    gameState.playerHealth = math.min(gameState.playerMaxHealth, gameState.playerHealth + ability.healAmount);
    final healedAmount = gameState.playerHealth - oldHealth;

    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('$message Restored ${healedAmount.toStringAsFixed(1)} HP');
  }

  // ==================== ABILITY 1: SWORD ====================

  /// Handles Ability 1 (Sword) input
  ///
  /// Activates the sword attack if cooldown is ready and ability is not already active.
  static void handleAbility1Input(bool ability1KeyPressed, GameState gameState) {
    if (ability1KeyPressed &&
        gameState.ability1Cooldown <= 0 &&
        !gameState.ability1Active) {
      executeSlotAbility(0, gameState);
    }
  }

  /// Updates Ability 1 (Sword) animation and collision detection
  static void updateAbility1(double dt, GameState gameState) {
    if (!gameState.ability1Active) return;

    gameState.ability1ActiveTime += dt;

    if (gameState.ability1ActiveTime >= gameState.ability1Duration) {
      gameState.ability1Active = false;
    } else if (gameState.swordTransform != null && gameState.playerTransform != null) {
      // Position sword in front of player, rotating during swing
      final forward = Vector3(
        -math.sin(_radians(gameState.playerRotation)),
        0,
        -math.cos(_radians(gameState.playerRotation)),
      );
      final swingProgress = gameState.ability1ActiveTime / gameState.ability1Duration;
      final swingAngle = swingProgress * 180; // 0 to 180 degrees

      gameState.swordTransform!.position = gameState.playerTransform!.position + forward * 0.8;
      gameState.swordTransform!.position.y = gameState.playerTransform!.position.y;
      gameState.swordTransform!.rotation.y = gameState.playerRotation + swingAngle - 90;

      // Check collision with monster (only once per swing)
      if (!gameState.ability1HitRegistered) {
        final sword = AbilitiesConfig.playerSword;
        final swordTipPosition = gameState.playerTransform!.position + forward * sword.range;

        final hitRegistered = CombatSystem.checkAndDamageEnemies(
          gameState,
          attackerPosition: swordTipPosition,
          damage: sword.damage,
          attackType: sword.name,
          impactColor: sword.impactColor,
          impactSize: sword.impactSize,
        );

        if (hitRegistered) {
          gameState.ability1HitRegistered = true;
        }
      }
    }
  }

  // ==================== ABILITY 2: FIREBALL ====================

  /// Handles Ability 2 (Fireball) input
  static void handleAbility2Input(bool ability2KeyPressed, GameState gameState) {
    if (ability2KeyPressed &&
        gameState.ability2Cooldown <= 0 &&
        gameState.playerTransform != null) {
      executeSlotAbility(1, gameState);
    }
  }

  /// Updates all ranged projectiles (fireballs, frost bolts, etc.) with homing and collision
  static void updateAbility2(double dt, GameState gameState) {
    gameState.fireballs.removeWhere((projectile) {
      // Update homing behavior if projectile is tracking a target
      if (projectile.isHoming && projectile.targetId != null) {
        final targetPos = _getTargetPosition(gameState, projectile.targetId!);
        if (targetPos != null) {
          // Recalculate velocity toward target
          final direction = (targetPos - projectile.transform.position).normalized();
          projectile.velocity = direction * projectile.speed;
        } else {
          // Target is dead/gone - stop homing, continue in current direction
          projectile.isHoming = false;
        }
      }

      // Move projectile
      projectile.transform.position += projectile.velocity * dt;
      projectile.lifetime -= dt;

      // Check collision with the specific target first (for homing projectiles)
      if (projectile.targetId != null) {
        final targetPos = _getTargetPosition(gameState, projectile.targetId!);
        if (targetPos != null) {
          final distance = (projectile.transform.position - targetPos).length;
          // Use a generous collision threshold for homing projectiles
          if (distance < 1.0) {
            // Direct hit on target - use projectile's stored damage data
            _damageTargetWithProjectile(gameState, projectile.targetId!, projectile);
            return true;
          }
        }
      }

      // Also check collision with any enemy (in case projectile passes near others)
      final hitRegistered = CombatSystem.checkAndDamageEnemies(
        gameState,
        attackerPosition: projectile.transform.position,
        damage: projectile.damage,
        attackType: projectile.abilityName,
        impactColor: projectile.impactColor,
        impactSize: projectile.impactSize,
      );

      if (hitRegistered) return true;

      // Remove if lifetime expired
      return projectile.lifetime <= 0;
    });
  }

  /// Apply damage to a specific target by ID using projectile's damage data
  static void _damageTargetWithProjectile(GameState gameState, String targetId, Projectile projectile) {
    if (targetId == 'boss') {
      CombatSystem.checkAndDamageMonster(
        gameState,
        attackerPosition: gameState.monsterTransform!.position,
        damage: projectile.damage,
        attackType: projectile.abilityName,
        impactColor: projectile.impactColor,
        impactSize: projectile.impactSize,
        collisionThreshold: 2.0, // Guaranteed hit
      );
    } else {
      CombatSystem.damageMinion(
        gameState,
        minionInstanceId: targetId,
        damage: projectile.damage,
        attackType: projectile.abilityName,
        impactColor: projectile.impactColor,
        impactSize: projectile.impactSize,
      );
    }
  }

  // ==================== ABILITY 3: HEAL ====================

  /// Handles Ability 3 (Heal) input
  static void handleAbility3Input(bool ability3KeyPressed, GameState gameState) {
    if (ability3KeyPressed &&
        gameState.ability3Cooldown <= 0 &&
        !gameState.ability3Active) {
      executeSlotAbility(2, gameState);
    }
  }

  /// Updates Ability 3 (Heal) visual effect
  static void updateAbility3(double dt, GameState gameState) {
    if (!gameState.ability3Active) return;

    gameState.ability3ActiveTime += dt;

    if (gameState.ability3ActiveTime >= gameState.ability3Duration) {
      gameState.ability3Active = false;
    } else if (gameState.healEffectTransform != null && gameState.playerTransform != null) {
      // Position heal effect around player with pulsing animation
      gameState.healEffectTransform!.position = gameState.playerTransform!.position.clone();
      final pulseScale = 1.0 + (math.sin(gameState.ability3ActiveTime * 10) * 0.2);
      gameState.healEffectTransform!.scale = Vector3(pulseScale, pulseScale, pulseScale);
    }
  }

  // ==================== ABILITY 4: DASH ATTACK ====================

  /// Handles Ability 4 (Dash Attack) input
  static void handleAbility4Input(bool ability4KeyPressed, GameState gameState) {
    if (ability4KeyPressed &&
        gameState.ability4Cooldown <= 0 &&
        !gameState.ability4Active) {
      executeSlotAbility(3, gameState);
    }
  }

  /// Updates Ability 4 (Dash Attack) movement and collision detection
  static void updateAbility4(double dt, GameState gameState) {
    if (!gameState.ability4Active) return;

    gameState.ability4ActiveTime += dt;

    if (gameState.ability4ActiveTime >= gameState.ability4Duration) {
      gameState.ability4Active = false;
    } else if (gameState.playerTransform != null) {
      final dashConfig = AbilitiesConfig.playerDashAttack;

      // Calculate forward direction based on player rotation
      final forward = Vector3(
        -math.sin(_radians(gameState.playerRotation)),
        0,
        -math.cos(_radians(gameState.playerRotation)),
      );

      // Calculate dash speed (total distance / duration)
      final dashSpeed = dashConfig.range / dashConfig.duration;

      // Move player forward at dash speed
      gameState.playerTransform!.position += forward * dashSpeed * dt;

      // Get terrain height at new position and apply it
      if (gameState.infiniteTerrainManager != null) {
        final terrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(
          gameState.playerTransform!.position.x,
          gameState.playerTransform!.position.z,
        );
        gameState.playerTransform!.position.y = terrainHeight;
      }

      // Check collision with monster during dash
      if (!gameState.ability4HitRegistered) {
        final hitRegistered = CombatSystem.checkAndDamageEnemies(
          gameState,
          attackerPosition: gameState.playerTransform!.position,
          damage: dashConfig.damage,
          attackType: dashConfig.name,
          impactColor: dashConfig.impactColor,
          impactSize: dashConfig.impactSize,
        );

        if (hitRegistered) {
          gameState.ability4HitRegistered = true;
          // Apply knockback to monster
          if (gameState.monsterTransform != null && dashConfig.knockbackForce > 0) {
            gameState.monsterTransform!.position += forward * dashConfig.knockbackForce;
          }
        }
      }

      // Update dash trail visual effect if it exists
      if (gameState.dashTrailTransform != null) {
        gameState.dashTrailTransform!.position = gameState.playerTransform!.position.clone();
        gameState.dashTrailTransform!.rotation.y = gameState.playerRotation;
      }
    }
  }

  // ==================== VISUAL EFFECTS ====================

  /// Updates all impact effects
  static void updateImpactEffects(double dt, GameState gameState) {
    gameState.impactEffects.removeWhere((impact) {
      impact.lifetime -= dt;

      // Scale effect (expand and fade)
      final scale = 1.0 + (impact.progress * GameConfig.impactEffectGrowthScale);
      impact.transform.scale = Vector3(scale, scale, scale);

      return impact.lifetime <= 0;
    });
  }

  // ==================== UTILITY FUNCTIONS ====================

  /// Converts degrees to radians
  static double _radians(double degrees) => degrees * (math.pi / 180);
}
