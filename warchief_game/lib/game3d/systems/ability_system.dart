import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../state/abilities_config.dart';
import '../state/action_bar_config.dart' show globalActionBarConfig;
import '../state/ability_override_manager.dart';
import '../state/wind_state.dart';
import '../state/wind_config.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/projectile.dart';
import '../../models/impact_effect.dart';
import 'combat_system.dart';
import 'physics_system.dart';
import '../../models/combat_log_entry.dart';

/// Mana type enumeration for abilities
enum _ManaType { none, blue, red, white }

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
    updateCastingState(dt, gameState);
    updateWindupState(dt, gameState);
    updateAbility1(dt, gameState);
    updateAbility2(dt, gameState);
    updateAbility3(dt, gameState);
    updateAbility4(dt, gameState);
    updateImpactEffects(dt, gameState);
  }

  /// Updates the casting state for abilities with cast time
  static void updateCastingState(double dt, GameState gameState) {
    if (!gameState.isCasting) return;

    gameState.castProgress += dt;

    // Check if cast is complete
    if (gameState.castProgress >= gameState.currentCastTime) {
      // Cast complete - execute the ability
      final slotIndex = gameState.castingSlotIndex;
      final abilityName = gameState.castingAbilityName;
      final configuredTime = gameState.currentCastTime;
      final actualProgress = gameState.castProgress;

      // Reset casting state
      gameState.isCasting = false;
      gameState.castProgress = 0.0;
      gameState.currentCastTime = 0.0;
      gameState.castingSlotIndex = null;
      gameState.castingAbilityName = '';

      // Execute the ability now
      print('[CAST] $abilityName cast complete! (configured: ${configuredTime.toStringAsFixed(2)}s, actual: ${actualProgress.toStringAsFixed(3)}s)');
      if (slotIndex != null) {
        _finishCastTimeAbility(slotIndex, gameState);
      }
    }
  }

  /// Updates the windup state for melee abilities with windup
  static void updateWindupState(double dt, GameState gameState) {
    if (!gameState.isWindingUp) return;

    gameState.windupProgress += dt;

    // Check if windup is complete
    if (gameState.windupProgress >= gameState.currentWindupTime) {
      // Windup complete - execute the ability
      final slotIndex = gameState.windupSlotIndex;
      final abilityName = gameState.windupAbilityName;
      final configuredTime = gameState.currentWindupTime;
      final actualProgress = gameState.windupProgress;

      // Reset windup state
      gameState.isWindingUp = false;
      gameState.windupProgress = 0.0;
      gameState.currentWindupTime = 0.0;
      gameState.windupSlotIndex = null;
      gameState.windupAbilityName = '';
      gameState.windupMovementSpeedModifier = 1.0;

      // Execute the ability now
      print('[WINDUP] $abilityName windup complete! (configured: ${configuredTime.toStringAsFixed(2)}s, actual: ${actualProgress.toStringAsFixed(3)}s)');
      if (slotIndex != null) {
        _finishWindupAbility(slotIndex, gameState);
      }
    }
  }

  /// Finish executing a cast-time ability after the cast completes
  static void _finishCastTimeAbility(int slotIndex, GameState gameState) {
    final config = globalActionBarConfig;
    final abilityName = config?.getSlotAbility(slotIndex) ?? '';
    final abilityData = config?.getSlotAbilityData(slotIndex);

    // Spend the deferred mana now that the cast succeeded
    _spendPendingMana(gameState, abilityName);

    // Set cooldown now that the cast has successfully completed
    _setCooldownForSlot(slotIndex, abilityData?.cooldown ?? _getAbilityCooldown(abilityName), gameState);

    // Execute the ability's effect (projectile launch, damage, etc.)
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
        // Fall back to generic projectile for other cast-time abilities
        _executeGenericProjectileFromAbility(slotIndex, gameState, abilityName);
    }
  }

  /// Finish executing a windup ability after the windup completes
  static void _finishWindupAbility(int slotIndex, GameState gameState) {
    final config = globalActionBarConfig;
    final abilityName = config?.getSlotAbility(slotIndex) ?? '';
    final abilityData = config?.getSlotAbilityData(slotIndex);

    // Spend the deferred mana now that the windup succeeded
    _spendPendingMana(gameState, abilityName);

    // Set cooldown now that the windup has successfully completed
    _setCooldownForSlot(slotIndex, abilityData?.cooldown ?? _getAbilityCooldown(abilityName), gameState);

    // Execute the ability's effect (damage in area, etc.)
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
        // Fall back to generic melee for other windup abilities
        _executeGenericWindupMelee(slotIndex, gameState, abilityName);
    }
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
    if (gameState.ability5Cooldown > 0) gameState.ability5Cooldown -= dt;
    if (gameState.ability6Cooldown > 0) gameState.ability6Cooldown -= dt;
    if (gameState.ability7Cooldown > 0) gameState.ability7Cooldown -= dt;
    if (gameState.ability8Cooldown > 0) gameState.ability8Cooldown -= dt;
    if (gameState.ability9Cooldown > 0) gameState.ability9Cooldown -= dt;
    if (gameState.ability10Cooldown > 0) gameState.ability10Cooldown -= dt;
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
    final cooldown = getCooldownForSlot(slotIndex, gameState);
    if (cooldown > 0) return;

    // Check if already casting or winding up
    if (gameState.isCasting || gameState.isWindingUp) return;

    // Range check: prevent firing if target is out of range
    final abilityData = globalActionBarConfig?.getSlotAbilityData(slotIndex);
    if (abilityData != null &&
        !abilityData.isSelfCast &&
        abilityData.range > 0 &&
        gameState.currentTargetId != null) {
      final distance = gameState.getDistanceToCurrentTarget();
      if (distance != null && distance > abilityData.range) {
        print('[RANGE] $abilityName out of range (${distance.toStringAsFixed(1)} > ${abilityData.range})');
        return;
      }
    }

    // Determine mana cost and type.  Prefer the AbilityData fields (works
    // for custom abilities and respects overrides); fall back to the legacy
    // hardcoded lookup only for built-in abilities that haven't been
    // migrated to manaColor/manaCost fields yet.
    double manaCost;
    _ManaType manaType;
    if (abilityData != null && abilityData.requiresMana) {
      manaCost = abilityData.manaCost;
      manaType = abilityData.manaColor == ManaColor.red
          ? _ManaType.red
          : abilityData.manaColor == ManaColor.white
              ? _ManaType.white
              : _ManaType.blue;
    } else {
      (manaCost, manaType) = _getManaCostAndType(abilityName);
    }

    // Silent Mind: next white mana ability is free
    if (gameState.silentMindActive && manaType == _ManaType.white && manaCost > 0) {
      print('[SILENT MIND] $abilityName mana cost overridden to 0 (was $manaCost)');
      manaCost = 0;
    }

    if (manaCost > 0) {
      if (manaType == _ManaType.blue) {
        if (!gameState.activeHasBlueMana(manaCost)) {
          print('[MANA] Not enough blue mana for $abilityName (need $manaCost, have ${gameState.activeBlueMana.toStringAsFixed(0)})');
          return;
        }
      } else if (manaType == _ManaType.red) {
        if (!gameState.activeHasRedMana(manaCost)) {
          print('[MANA] Not enough red mana for $abilityName (need $manaCost, have ${gameState.activeRedMana.toStringAsFixed(0)})');
          return;
        }
      } else if (manaType == _ManaType.white) {
        if (!gameState.activeHasWhiteMana(manaCost)) {
          print('[MANA] Not enough white mana for $abilityName (need $manaCost, have ${gameState.activeWhiteMana.toStringAsFixed(0)})');
          return;
        }
      }
    }

    // Check for cast-time abilities (must be stationary)
    // Silent Mind: skip cast time for white mana abilities, execute instantly
    if (abilityData != null && abilityData.hasCastTime) {
      if (gameState.silentMindActive && manaType == _ManaType.white) {
        print('[SILENT MIND] $abilityName cast time skipped — instant cast!');
        // Fall through to instant execution below instead of starting cast
      } else {
        // Defer mana spending until the cast completes. If interrupted,
        // the mana is never spent and the ability remains available.
        gameState.pendingManaCost = manaCost;
        gameState.pendingManaIsBlue = manaType == _ManaType.blue;
        gameState.pendingManaType = manaType == _ManaType.blue ? 0 : manaType == _ManaType.red ? 1 : 2;
        _startCastTimeAbility(abilityData, slotIndex, gameState);
        return;
      }
    }

    // Check for windup abilities (reduced movement, red mana)
    if (abilityData != null && abilityData.hasWindup) {
      // Defer mana spending until the windup completes.
      gameState.pendingManaCost = manaCost;
      gameState.pendingManaIsBlue = manaType == _ManaType.blue;
      gameState.pendingManaType = manaType == _ManaType.blue ? 0 : manaType == _ManaType.red ? 1 : 2;
      _startWindupAbility(abilityData, slotIndex, gameState);
      return;
    }

    // Spend mana for instant abilities
    if (manaCost > 0) {
      if (manaType == _ManaType.blue) {
        gameState.activeSpendBlueMana(manaCost);
        print('[MANA] Spent $manaCost blue mana for $abilityName');
      } else if (manaType == _ManaType.red) {
        gameState.activeSpendRedMana(manaCost);
        print('[MANA] Spent $manaCost red mana for $abilityName');
      } else if (manaType == _ManaType.white) {
        gameState.activeSpendWhiteMana(manaCost);
        print('[MANA] Spent $manaCost white mana for $abilityName');
      }
    }

    // Consume Silent Mind after a white mana ability is used
    if (gameState.silentMindActive && manaType == _ManaType.white) {
      gameState.silentMindActive = false;
      print('[SILENT MIND] Buff consumed by $abilityName');
    }

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

      // Wind Walker abilities
      case 'Gale Step':
        _executeGaleStep(slotIndex, gameState);
        break;
      case 'Zephyr Roll':
        _executeZephyrRoll(slotIndex, gameState);
        break;
      case 'Tailwind Retreat':
        _executeTailwindRetreat(slotIndex, gameState);
        break;
      case 'Flying Serpent Strike':
        _executeFlyingSerpentStrike(slotIndex, gameState);
        break;
      case 'Take Flight':
        _executeTakeFlight(slotIndex, gameState);
        break;
      case 'Cyclone Dive':
        _executeCycloneDive(slotIndex, gameState);
        break;
      case 'Wind Wall':
        _executeWindWall(slotIndex, gameState);
        break;
      case 'Tempest Charge':
        _executeTempestCharge(slotIndex, gameState);
        break;
      case 'Healing Gale':
        _executeHealingGale(slotIndex, gameState);
        break;
      case 'Sovereign of the Sky':
        _executeSovereignOfTheSky(slotIndex, gameState);
        break;
      case 'Wind Affinity':
        _executeWindAffinity(slotIndex, gameState);
        break;
      case 'Silent Mind':
        _executeSilentMind(slotIndex, gameState);
        break;
      case 'Windshear':
        _executeWindshear(slotIndex, gameState);
        break;
      case 'Wind Warp':
        _executeWindWarp(slotIndex, gameState);
        break;

      default:
        // Generic data-driven execution for custom / unrecognized abilities.
        // Dispatch based on AbilityType so user-created abilities work
        // without a dedicated switch case.
        if (abilityData != null) {
          _executeGenericAbility(slotIndex, gameState, abilityData);
        } else {
          print('[ABILITY] Unknown ability with no data: $abilityName');
          _executeDefaultSlotAbility(slotIndex, gameState);
        }
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

  /// Get cooldown for a slot (public for macro pre-checks)
  static double getCooldownForSlot(int slotIndex, GameState gameState) {
    switch (slotIndex) {
      case 0: return gameState.ability1Cooldown;
      case 1: return gameState.ability2Cooldown;
      case 2: return gameState.ability3Cooldown;
      case 3: return gameState.ability4Cooldown;
      case 4: return gameState.ability5Cooldown;
      case 5: return gameState.ability6Cooldown;
      case 6: return gameState.ability7Cooldown;
      case 7: return gameState.ability8Cooldown;
      case 8: return gameState.ability9Cooldown;
      case 9: return gameState.ability10Cooldown;
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
      case 4:
        gameState.ability5Cooldown = cooldown;
        break;
      case 5:
        gameState.ability6Cooldown = cooldown;
        break;
      case 6:
        gameState.ability7Cooldown = cooldown;
        break;
      case 7:
        gameState.ability8Cooldown = cooldown;
        break;
      case 8:
        gameState.ability9Cooldown = cooldown;
        break;
      case 9:
        gameState.ability10Cooldown = cooldown;
        break;
    }
  }

  // ==================== CAST TIME / WINDUP HANDLING ====================

  /// Start a cast-time ability — reads castTime from AbilityData (respects overrides)
  static void _startCastTimeAbility(AbilityData abilityData, int slotIndex, GameState gameState) {
    final castTime = abilityData.castTime;

    gameState.isCasting = true;
    gameState.castProgress = 0.0;
    gameState.currentCastTime = castTime;
    gameState.castingSlotIndex = slotIndex;
    gameState.castingAbilityName = abilityData.name;

    // Cooldown is NOT set here — it is set when the cast completes in
    // _finishCastTimeAbility. If the cast is interrupted, the ability
    // remains available.

    print('[CAST] Starting ${abilityData.name} (${castTime}s cast time)');
  }

  /// Start a windup ability — reads windupTime/movementSpeed from AbilityData (respects overrides)
  static void _startWindupAbility(AbilityData abilityData, int slotIndex, GameState gameState) {
    final windupTime = abilityData.windupTime;
    final movementSpeed = abilityData.windupMovementSpeed;

    gameState.isWindingUp = true;
    gameState.windupProgress = 0.0;
    gameState.currentWindupTime = windupTime;
    gameState.windupSlotIndex = slotIndex;
    gameState.windupAbilityName = abilityData.name;
    gameState.windupMovementSpeedModifier = movementSpeed;

    // Cooldown is NOT set here — it is set when the windup completes in
    // _finishWindupAbility. If the windup is interrupted, the ability
    // remains available.

    print('[WINDUP] Starting ${abilityData.name} (${windupTime}s windup, ${(movementSpeed * 100).toInt()}% movement)');
  }

  /// Get the cooldown for an ability by name
  static double _getAbilityCooldown(String abilityName) {
    switch (abilityName) {
      case 'Lightning Bolt': return 5.0;
      case 'Pyroblast': return 12.0;
      case 'Arcane Missile': return 3.5;
      case 'Frost Nova': return 15.0;
      case 'Greater Heal': return 15.0;
      case 'Meteor': return 30.0;
      case 'Heavy Strike': return 4.0;
      case 'Whirlwind': return 8.0;
      case 'Crushing Blow': return 10.0;
      default: return 5.0;
    }
  }

  /// Get the mana cost and type for an ability by name
  /// Returns (cost, type) tuple where type indicates which mana pool
  static (double, _ManaType) _getManaCostAndType(String abilityName) {
    switch (abilityName) {
      // Instant ranged (blue mana)
      case 'Fireball': return (15.0, _ManaType.blue);
      case 'Ice Shard': return (10.0, _ManaType.blue);
      case 'Frost Bolt': return (12.0, _ManaType.blue);

      // Cast-time ranged (blue mana)
      case 'Lightning Bolt': return (35.0, _ManaType.blue);
      case 'Pyroblast': return (60.0, _ManaType.blue);
      case 'Arcane Missile': return (25.0, _ManaType.blue);
      case 'Meteor': return (80.0, _ManaType.blue);
      case 'Chain Lightning': return (40.0, _ManaType.blue);
      case 'Blizzard': return (50.0, _ManaType.blue);

      // AOE (blue mana)
      case 'Frost Nova': return (40.0, _ManaType.blue);
      case 'Flame Wave': return (35.0, _ManaType.blue);
      case 'Earthquake': return (45.0, _ManaType.blue);

      // Healing (blue mana)
      case 'Heal': return (20.0, _ManaType.blue);
      case 'Greater Heal': return (45.0, _ManaType.blue);
      case 'Holy Light': return (30.0, _ManaType.blue);
      case 'Rejuvenation': return (25.0, _ManaType.blue);
      case 'Circle of Healing': return (55.0, _ManaType.blue);

      // Magical melee (blue mana)
      case 'Arcane Strike': return (12.0, _ManaType.blue);
      case 'Frost Strike': return (18.0, _ManaType.blue);
      case 'Life Drain': return (25.0, _ManaType.blue);

      // Buffs/Debuffs (blue mana)
      case 'Arcane Shield': return (30.0, _ManaType.blue);
      case 'Blessing of Strength': return (20.0, _ManaType.blue);
      case 'Curse of Weakness': return (20.0, _ManaType.blue);
      case 'Thorns': return (15.0, _ManaType.blue);
      case 'Fear': return (35.0, _ManaType.blue);
      case 'Purify': return (15.0, _ManaType.blue);

      // Utility (blue mana)
      case 'Teleport': return (25.0, _ManaType.blue);
      case 'Shadow Step': return (20.0, _ManaType.blue);
      case 'Summon Skeleton': return (50.0, _ManaType.blue);

      // Windup melee (RED mana)
      case 'Heavy Strike': return (20.0, _ManaType.red);
      case 'Whirlwind': return (30.0, _ManaType.red);
      case 'Crushing Blow': return (45.0, _ManaType.red);

      // Physical abilities - no mana cost
      case 'Sword':
      case 'Dash Attack':
      case 'Shield Bash':
      case 'Charge':
      case 'Backstab':
      case 'Poison Blade':
      case 'Fan of Knives':
      case 'Taunt':
      case 'Fortify':
      case 'Sprint':
      case 'Battle Shout':
      case 'Smoke Bomb':
      case 'Entangling Roots':
      case 'Nature\'s Wrath':
        return (0.0, _ManaType.none);

      default: return (0.0, _ManaType.none);
    }
  }

  /// Legacy method for backward compatibility - returns blue mana cost only
  static double _getManaCost(String abilityName) {
    final (cost, type) = _getManaCostAndType(abilityName);
    return type == _ManaType.blue ? cost : 0.0;
  }

  /// Get red mana cost for an ability
  static double _getRedManaCost(String abilityName) {
    final (cost, type) = _getManaCostAndType(abilityName);
    return type == _ManaType.red ? cost : 0.0;
  }

  /// Spend the pending mana stored in gameState (deferred from cast/windup start)
  static void _spendPendingMana(GameState gameState, String abilityName) {
    final cost = gameState.pendingManaCost;
    if (cost <= 0) return;

    // Reason: pendingManaType distinguishes blue(0), red(1), white(2)
    switch (gameState.pendingManaType) {
      case 2:
        gameState.activeSpendWhiteMana(cost);
        print('[MANA] Spent $cost white mana for $abilityName');
        break;
      case 1:
        gameState.activeSpendRedMana(cost);
        print('[MANA] Spent $cost red mana for $abilityName');
        break;
      default:
        gameState.activeSpendBlueMana(cost);
        print('[MANA] Spent $cost blue mana for $abilityName');
        break;
    }
    gameState.pendingManaCost = 0.0;
  }

  // ==================== CAST TIME ABILITY EFFECTS ====================

  /// Launch Lightning Bolt after cast completes
  static void _launchLightningBolt(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;

    final playerPos = gameState.activeTransform!.position;
    final targetPos = _getTargetPositionOrForward(gameState, playerPos);
    final direction = (targetPos - playerPos).normalized();

    final projectileMesh = Mesh.cube(
      size: 0.3,
      color: Vector3(0.8, 0.8, 1.0),
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
      velocity: direction * 25.0, // Very fast
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

  /// Launch Pyroblast after cast completes
  static void _launchPyroblast(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;

    final playerPos = gameState.activeTransform!.position;
    final targetPos = _getTargetPositionOrForward(gameState, playerPos);
    final direction = (targetPos - playerPos).normalized();

    final projectileMesh = Mesh.cube(
      size: 0.8,
      color: Vector3(1.0, 0.3, 0.0),
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
      velocity: direction * 8.0, // Slow but powerful
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

  /// Launch Arcane Missile after cast completes
  static void _launchArcaneMissile(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;

    final playerPos = gameState.activeTransform!.position;
    final targetPos = _getTargetPositionOrForward(gameState, playerPos);
    final direction = (targetPos - playerPos).normalized();

    final projectileMesh = Mesh.cube(
      size: 0.4,
      color: Vector3(0.7, 0.3, 1.0),
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

  /// Execute Frost Nova effect after cast completes
  static void _executeFrostNovaEffect(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;

    // Create impact effect around player
    final impactMesh = Mesh.cube(
      size: 8.0,
      color: Vector3(0.4, 0.7, 1.0),
    );
    final impactTransform = Transform3d(
      position: gameState.activeTransform!.position.clone(),
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
      attackerPosition: gameState.activeTransform!.position,
      damage: 20.0,
      attackType: 'Frost Nova',
      impactColor: Vector3(0.5, 0.8, 1.0),
      impactSize: 0.5,
      collisionThreshold: 8.0,
    );

    print('Frost Nova released!');
  }

  /// Execute Greater Heal effect after cast completes
  static void _executeGreaterHealEffect(int slotIndex, GameState gameState) {
    final oldHealth = gameState.activeHealth;
    gameState.activeHealth = math.min(gameState.activeMaxHealth, gameState.activeHealth + 50.0);
    final healedAmount = gameState.activeHealth - oldHealth;

    gameState.ability3Active = true;
    gameState.ability3ActiveTime = 0.0;

    _logHeal(gameState, 'Greater Heal', healedAmount);
    print('Greater Heal! Restored ${healedAmount.toStringAsFixed(1)} HP');
  }

  /// Generic projectile launch for unknown cast-time abilities
  static void _executeGenericProjectileFromAbility(int slotIndex, GameState gameState, String abilityName) {
    if (gameState.activeTransform == null) return;

    final playerPos = gameState.activeTransform!.position;
    final targetPos = _getTargetPositionOrForward(gameState, playerPos);
    final direction = (targetPos - playerPos).normalized();

    final projectileMesh = Mesh.cube(
      size: 0.4,
      color: Vector3(1.0, 1.0, 1.0),
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

  /// Execute Heavy Strike effect after windup completes
  static void _executeHeavyStrikeEffect(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;

    final forward = Vector3(
      -math.sin(_radians(gameState.activeRotation)),
      0,
      -math.cos(_radians(gameState.activeRotation)),
    );
    final strikePosition = gameState.activeTransform!.position + forward * 2.5;

    // Large hit radius
    final hitRegistered = CombatSystem.checkAndDamageEnemies(
      gameState,
      attackerPosition: strikePosition,
      damage: 75.0,
      attackType: 'Heavy Strike',
      impactColor: Vector3(1.0, 0.4, 0.2),
      impactSize: 1.0,
      collisionThreshold: 4.0, // Large hit radius
      isMeleeDamage: true, // Generate red mana
    );

    if (hitRegistered) {
      print('Heavy Strike hit!');
    }
  }

  /// Execute Whirlwind effect after windup completes
  static void _executeWhirlwindEffect(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;

    // Create spinning visual effect
    final impactMesh = Mesh.cube(
      size: 5.0,
      color: Vector3(0.6, 0.6, 0.7),
    );
    final impactTransform = Transform3d(
      position: gameState.activeTransform!.position.clone(),
      scale: Vector3(1, 1, 1),
    );
    gameState.impactEffects.add(ImpactEffect(
      mesh: impactMesh,
      transform: impactTransform,
      lifetime: 0.8,
    ));

    // Damage all nearby enemies with large radius
    CombatSystem.checkAndDamageEnemies(
      gameState,
      attackerPosition: gameState.activeTransform!.position,
      damage: 48.0,
      attackType: 'Whirlwind',
      impactColor: Vector3(0.7, 0.7, 0.8),
      impactSize: 0.6,
      collisionThreshold: 5.0, // Wide AOE
      isMeleeDamage: true, // Generate red mana
    );

    print('Whirlwind!');
  }

  /// Execute Crushing Blow effect after windup completes
  static void _executeCrushingBlowEffect(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;

    final forward = Vector3(
      -math.sin(_radians(gameState.activeRotation)),
      0,
      -math.cos(_radians(gameState.activeRotation)),
    );
    final strikePosition = gameState.activeTransform!.position + forward * 2.0;

    // Create powerful impact visual
    final impactMesh = Mesh.cube(
      size: 1.2,
      color: Vector3(0.7, 0.3, 0.1),
    );
    final impactTransform = Transform3d(
      position: strikePosition,
      scale: Vector3(1, 1, 1),
    );
    gameState.impactEffects.add(ImpactEffect(
      mesh: impactMesh,
      transform: impactTransform,
      lifetime: 0.5,
    ));

    // Heavy damage with moderate hit radius
    final hitRegistered = CombatSystem.checkAndDamageEnemies(
      gameState,
      attackerPosition: strikePosition,
      damage: 110.0,
      attackType: 'Crushing Blow',
      impactColor: Vector3(0.7, 0.3, 0.1),
      impactSize: 1.2,
      collisionThreshold: 3.5, // Moderate hit radius
      isMeleeDamage: true, // Generate red mana
    );

    if (hitRegistered) {
      print('Crushing Blow devastates the target!');
    }
  }

  /// Generic windup melee for unknown windup abilities
  static void _executeGenericWindupMelee(int slotIndex, GameState gameState, String abilityName) {
    if (gameState.activeTransform == null) return;

    final forward = Vector3(
      -math.sin(_radians(gameState.activeRotation)),
      0,
      -math.cos(_radians(gameState.activeRotation)),
    );
    final strikePosition = gameState.activeTransform!.position + forward * 2.5;

    CombatSystem.checkAndDamageEnemies(
      gameState,
      attackerPosition: strikePosition,
      damage: 40.0,
      attackType: abilityName,
      impactColor: Vector3(0.8, 0.8, 0.8),
      impactSize: 0.8,
      collisionThreshold: 3.5,
    );

    print('$abilityName!');
  }

  /// Get target position or a position forward from player
  static Vector3 _getTargetPositionOrForward(GameState gameState, Vector3 playerPos) {
    // Try to get target position
    if (gameState.currentTargetId != null) {
      final targetPos = _getTargetPosition(gameState, gameState.currentTargetId!);
      if (targetPos != null) return targetPos;
    }

    // Fall back to position ahead of player
    final forward = Vector3(
      -math.sin(_radians(gameState.activeRotation)),
      0,
      -math.cos(_radians(gameState.activeRotation)),
    );
    return playerPos + forward * 30.0;
  }

  // ==================== ABILITY IMPLEMENTATIONS ====================

  /// Execute Sword (melee attack)
  static void _executeSword(int slotIndex, GameState gameState) {
    if (gameState.ability1Active) return; // Prevent if already active

    gameState.ability1Active = true;
    gameState.ability1ActiveTime = 0.0;
    _setCooldownForSlot(slotIndex, _effective(AbilitiesConfig.playerSword).cooldown, gameState);
    gameState.ability1HitRegistered = false;
    print('Sword attack activated!');
  }

  /// Execute Fireball (ranged projectile)
  static void _executeFireball(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;

    final fireball = _effective(AbilitiesConfig.playerFireball);
    final playerPos = gameState.activeTransform!.position;

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
        -math.sin(_radians(gameState.activeRotation)),
        0,
        -math.cos(_radians(gameState.activeRotation)),
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

    final healAbility = _effective(AbilitiesConfig.playerHeal);
    final oldHealth = gameState.activeHealth;
    gameState.activeHealth = math.min(gameState.activeMaxHealth, gameState.activeHealth + healAbility.healAmount);
    final healedAmount = gameState.activeHealth - oldHealth;

    _setCooldownForSlot(slotIndex, healAbility.cooldown, gameState);
    _logHeal(gameState, 'Heal', healedAmount);
    print('[HEAL] Player heal activated! Restored ${healedAmount.toStringAsFixed(1)} HP');
  }

  /// Execute Dash Attack (movement + damage)
  static void _executeDashAttack(int slotIndex, GameState gameState) {
    if (gameState.ability4Active) return;

    gameState.ability4Active = true;
    gameState.ability4ActiveTime = 0.0;
    _setCooldownForSlot(slotIndex, _effective(AbilitiesConfig.playerDashAttack).cooldown, gameState);
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
    if (gameState.activeTransform == null) return;
    final ability = MageAbilities.teleport;

    // Teleport forward
    final forward = Vector3(
      -math.sin(_radians(gameState.activeRotation)),
      0,
      -math.cos(_radians(gameState.activeRotation)),
    );
    gameState.activeTransform!.position += forward * ability.range;

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
    gameState.activeHealth = math.min(gameState.activeMaxHealth, gameState.activeHealth + ability.healAmount);
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

  // ==================== WIND WALKER ABILITIES ====================

  /// Gale Step — forward dash through enemies dealing damage (reuses Dash pattern)
  static void _executeGaleStep(int slotIndex, GameState gameState) {
    if (gameState.ability4Active) return;
    final ability = WindWalkerAbilities.galeStep;
    gameState.ability4Active = true;
    gameState.ability4ActiveTime = 0.0;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    gameState.ability4HitRegistered = false;
    print('Gale Step activated!');
  }

  /// Zephyr Roll — forward dodge-roll with brief invulnerability
  static void _executeZephyrRoll(int slotIndex, GameState gameState) {
    if (gameState.ability4Active) return;
    final ability = WindWalkerAbilities.zephyrRoll;
    gameState.ability4Active = true;
    gameState.ability4ActiveTime = 0.0;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    gameState.ability4HitRegistered = false;
    print('Zephyr Roll! Brief invulnerability.');
  }

  /// Tailwind Retreat — backward movement + knockback nearby enemies
  static void _executeTailwindRetreat(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;
    final ability = WindWalkerAbilities.tailwindRetreat;

    // Move player backward
    final backward = Vector3(
      math.sin(_radians(gameState.activeRotation)),
      0,
      math.cos(_radians(gameState.activeRotation)),
    );
    gameState.activeTransform!.position += backward * ability.range;

    // Knockback nearby enemies
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

  /// Flying Serpent Strike — long dash with damage (longer range than Gale Step)
  static void _executeFlyingSerpentStrike(int slotIndex, GameState gameState) {
    if (gameState.ability4Active) return;
    final ability = WindWalkerAbilities.flyingSerpentStrike;
    gameState.ability4Active = true;
    gameState.ability4ActiveTime = 0.0;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    gameState.ability4HitRegistered = false;
    print('Flying Serpent Strike activated!');
  }

  /// Take Flight — toggle flight mode on/off
  static void _executeTakeFlight(int slotIndex, GameState gameState) {
    final ability = WindWalkerAbilities.takeFlight;
    gameState.toggleFlight();
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
  }

  /// Cyclone Dive — leap up then AoE slam dealing damage + stun
  static void _executeCycloneDive(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;
    final ability = WindWalkerAbilities.cycloneDive;

    // Create impact effect at player location
    final impactMesh = Mesh.cube(
      size: ability.aoeRadius > 0 ? ability.aoeRadius : 3.0,
      color: ability.color,
    );
    final impactTransform = Transform3d(
      position: gameState.activeTransform!.position.clone(),
      scale: Vector3(1, 1, 1),
    );
    gameState.impactEffects.add(ImpactEffect(
      mesh: impactMesh,
      transform: impactTransform,
      lifetime: 0.8,
    ));

    // Damage nearby enemies
    CombatSystem.checkAndDamageEnemies(
      gameState,
      attackerPosition: gameState.activeTransform!.position,
      damage: ability.damage,
      attackType: ability.name,
      impactColor: ability.impactColor,
      impactSize: ability.impactSize,
      collisionThreshold: ability.aoeRadius,
      isMeleeDamage: true,
    );

    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Cyclone Dive! AoE slam!');
  }

  /// Wind Wall — blocks projectiles (visual + cooldown; blocking deferred)
  static void _executeWindWall(int slotIndex, GameState gameState) {
    final ability = WindWalkerAbilities.windWall;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Wind Wall deployed! Blocking projectiles for ${ability.duration}s.');
  }

  /// Tempest Charge — charge to target with knockback (reuses generic melee)
  static void _executeTempestCharge(int slotIndex, GameState gameState) {
    final ability = WindWalkerAbilities.tempestCharge;
    _executeGenericMelee(slotIndex, gameState, ability, 'Tempest Charge!');
  }

  /// Healing Gale — heal self over time
  static void _executeHealingGale(int slotIndex, GameState gameState) {
    final ability = WindWalkerAbilities.healingGale;
    _executeGenericHeal(slotIndex, gameState, ability, 'Healing Gale!');
  }

  /// Sovereign of the Sky — 12s buff: enhanced flight speed, reduced mana costs
  static void _executeSovereignOfTheSky(int slotIndex, GameState gameState) {
    final ability = WindWalkerAbilities.sovereignOfTheSky;
    gameState.sovereignBuffActive = true;
    gameState.sovereignBuffTimer = ability.duration;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Sovereign of the Sky! Enhanced flight for ${ability.duration}s.');
  }

  /// Wind Affinity — doubles white mana regen rate for 15 seconds
  static void _executeWindAffinity(int slotIndex, GameState gameState) {
    final ability = WindWalkerAbilities.windAffinity;
    gameState.windAffinityActive = true;
    gameState.windAffinityTimer = ability.duration;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Wind Affinity! White mana regen doubled for ${ability.duration}s.');
  }

  /// Silent Mind — fully restores white mana; next white ability is free + instant
  static void _executeSilentMind(int slotIndex, GameState gameState) {
    final ability = WindWalkerAbilities.silentMind;
    gameState.activeWhiteMana = gameState.activeMaxWhiteMana;
    gameState.silentMindActive = true;
    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Silent Mind! White mana fully restored. Next white ability is free and instant.');
  }

  /// Windshear — 90-degree cone AoE: enemies take damage + knockdown,
  /// allies are healed
  static void _executeWindshear(int slotIndex, GameState gameState) {
    if (gameState.activeTransform == null) return;
    final ability = WindWalkerAbilities.windshear;

    final playerPos = gameState.activeTransform!.position;
    final facingRad = gameState.activeRotation * math.pi / 180.0;
    final facingX = -math.sin(facingRad);
    final facingZ = -math.cos(facingRad);
    final coneHalfAngle = 45.0; // 90-degree cone = 45 half-angle
    final coneRange = ability.aoeRadius; // 40 yards

    // Check boss
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

    // Check minions
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

    // Check allies — heal friendlies in cone
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      if (_isInCone(playerPos, facingX, facingZ, ally.transform.position, coneHalfAngle, coneRange)) {
        ally.health = math.min(ally.maxHealth, ally.health + ability.healAmount);
        print('[WINDSHEAR] Healed ally for ${ability.healAmount} HP');
      }
    }

    // Visual effect
    final impactMesh = Mesh.cube(
      size: 4.0,
      color: ability.color,
    );
    final impactTransform = Transform3d(
      position: playerPos.clone(),
      scale: Vector3(1, 1, 1),
    );
    gameState.impactEffects.add(ImpactEffect(
      mesh: impactMesh,
      transform: impactTransform,
      lifetime: 0.8,
    ));

    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    print('Windshear! Cone AoE — enemies damaged, allies healed.');
  }

  /// Wind Warp — dash forward on ground; if flying, double flight speed for 5s
  static void _executeWindWarp(int slotIndex, GameState gameState) {
    final ability = WindWalkerAbilities.windWarp;

    if (gameState.isFlying) {
      // Flying: activate speed buff instead of dash
      gameState.windWarpSpeedActive = true;
      gameState.windWarpSpeedTimer = 5.0;
      _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
      print('Wind Warp! Flight speed doubled for 5s.');
    } else {
      // Ground: use dash pattern (same as Gale Step / ability4)
      if (gameState.ability4Active) return;
      gameState.ability4Active = true;
      gameState.ability4ActiveTime = 0.0;
      _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
      gameState.ability4HitRegistered = false;
      print('Wind Warp! Dashing forward.');
    }
  }

  /// Check if a target position is within a cone defined by origin, facing
  /// direction, half-angle (degrees), and range.
  static bool _isInCone(Vector3 origin, double facingX, double facingZ, Vector3 target, double halfAngleDeg, double range) {
    final dx = target.x - origin.x;
    final dz = target.z - origin.z;
    final dist = math.sqrt(dx * dx + dz * dz);
    if (dist > range || dist < 0.001) return false;

    // Dot product for angle check
    final dirX = dx / dist;
    final dirZ = dz / dist;
    final dot = (facingX * dirX + facingZ * dirZ).clamp(-1.0, 1.0);
    final angleDeg = math.acos(dot) * 180.0 / math.pi;
    return angleDeg <= halfAngleDeg;
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
    if (gameState.activeTransform == null) return;

    final playerPos = gameState.activeTransform!.position;
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
        -math.sin(_radians(gameState.activeRotation)),
        0,
        -math.cos(_radians(gameState.activeRotation)),
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
    if (gameState.activeTransform == null) return;

    // Create impact effect at player location
    final impactMesh = Mesh.cube(
      size: ability.aoeRadius > 0 ? ability.aoeRadius : 2.0,
      color: ability.color,
    );
    final impactTransform = Transform3d(
      position: gameState.activeTransform!.position.clone(),
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
      attackerPosition: gameState.activeTransform!.position,
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

    final oldHealth = gameState.activeHealth;
    gameState.activeHealth = math.min(gameState.activeMaxHealth, gameState.activeHealth + ability.healAmount);
    final healedAmount = gameState.activeHealth - oldHealth;

    _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
    _logHeal(gameState, ability.name, healedAmount);
    print('$message Restored ${healedAmount.toStringAsFixed(1)} HP');
  }

  /// Data-driven ability execution for custom and unrecognized abilities.
  ///
  /// Dispatches to the appropriate generic handler based on [AbilityData.type]
  /// so that user-created abilities (from the ability editor) work without
  /// a dedicated switch case.
  static void _executeGenericAbility(int slotIndex, GameState gameState, AbilityData ability) {
    switch (ability.type) {
      case AbilityType.melee:
        _executeGenericMelee(slotIndex, gameState, ability, '${ability.name}!');
        break;
      case AbilityType.ranged:
      case AbilityType.dot:
        // Ranged and DoT abilities both fire a projectile toward the target
        _executeGenericProjectile(slotIndex, gameState, ability, '${ability.name}!');
        break;
      case AbilityType.heal:
        _executeGenericHeal(slotIndex, gameState, ability, '${ability.name}!');
        break;
      case AbilityType.aoe:
        _executeGenericAoE(slotIndex, gameState, ability, '${ability.name}!');
        break;
      case AbilityType.buff:
      case AbilityType.debuff:
      case AbilityType.utility:
      case AbilityType.channeled:
      case AbilityType.summon:
        // For types without a projectile/melee effect, just apply cooldown
        _setCooldownForSlot(slotIndex, ability.cooldown, gameState);
        print('${ability.name} activated!');
        break;
    }
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
    } else if (gameState.swordTransform != null && gameState.activeTransform != null) {
      // Position sword in front of player, rotating during swing
      final forward = Vector3(
        -math.sin(_radians(gameState.activeRotation)),
        0,
        -math.cos(_radians(gameState.activeRotation)),
      );
      final swingProgress = gameState.ability1ActiveTime / gameState.ability1Duration;
      final swingAngle = swingProgress * 180; // 0 to 180 degrees

      gameState.swordTransform!.position = gameState.activeTransform!.position + forward * 0.8;
      gameState.swordTransform!.position.y = gameState.activeTransform!.position.y;
      gameState.swordTransform!.rotation.y = gameState.activeRotation + swingAngle - 90;

      // Check collision with monster (only once per swing)
      if (!gameState.ability1HitRegistered) {
        final sword = _effective(AbilitiesConfig.playerSword);
        final swordTipPosition = gameState.activeTransform!.position + forward * sword.range;

        final hitRegistered = CombatSystem.checkAndDamageEnemies(
          gameState,
          attackerPosition: swordTipPosition,
          damage: sword.damage,
          attackType: sword.name,
          impactColor: sword.impactColor,
          impactSize: sword.impactSize,
          isMeleeDamage: true, // Generate red mana from sword attacks
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
        gameState.activeTransform != null) {
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

      // Apply wind force to projectile trajectory
      if (globalWindState != null) {
        final windForce = globalWindState!.getProjectileForce();
        projectile.velocity.x += windForce[0] * dt;
        projectile.velocity.z += windForce[1] * dt;
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
        showDamageIndicator: true,
      );
    } else {
      CombatSystem.damageMinion(
        gameState,
        minionInstanceId: targetId,
        damage: projectile.damage,
        attackType: projectile.abilityName,
        impactColor: projectile.impactColor,
        impactSize: projectile.impactSize,
        showDamageIndicator: true,
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
    } else if (gameState.healEffectTransform != null && gameState.activeTransform != null) {
      // Position heal effect around player with pulsing animation
      gameState.healEffectTransform!.position = gameState.activeTransform!.position.clone();
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
    } else if (gameState.activeTransform != null) {
      final dashConfig = _effective(AbilitiesConfig.playerDashAttack);

      // Calculate forward direction based on player rotation
      final forward = Vector3(
        -math.sin(_radians(gameState.activeRotation)),
        0,
        -math.cos(_radians(gameState.activeRotation)),
      );

      // Calculate dash speed (total distance / duration)
      final dashSpeed = dashConfig.range / dashConfig.duration;

      // Move player forward at dash speed
      gameState.activeTransform!.position += forward * dashSpeed * dt;

      // Get terrain height at new position and apply it
      if (gameState.infiniteTerrainManager != null) {
        final terrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(
          gameState.activeTransform!.position.x,
          gameState.activeTransform!.position.z,
        );
        gameState.activeTransform!.position.y = terrainHeight;
      }

      // Check collision with monster during dash
      if (!gameState.ability4HitRegistered) {
        final hitRegistered = CombatSystem.checkAndDamageEnemies(
          gameState,
          attackerPosition: gameState.activeTransform!.position,
          damage: dashConfig.damage,
          attackType: dashConfig.name,
          impactColor: dashConfig.impactColor,
          impactSize: dashConfig.impactSize,
          isMeleeDamage: true, // Generate red mana from dash attack
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
        gameState.dashTrailTransform!.position = gameState.activeTransform!.position.clone();
        gameState.dashTrailTransform!.rotation.y = gameState.activeRotation;
      }
    }
  }

  // ==================== ABILITIES 5-10 INPUT HANDLERS ====================

  /// Handles Ability 5 input
  static void handleAbility5Input(bool keyPressed, GameState gameState) {
    if (keyPressed && gameState.ability5Cooldown <= 0) {
      executeSlotAbility(4, gameState);
    }
  }

  /// Handles Ability 6 input
  static void handleAbility6Input(bool keyPressed, GameState gameState) {
    if (keyPressed && gameState.ability6Cooldown <= 0) {
      executeSlotAbility(5, gameState);
    }
  }

  /// Handles Ability 7 input
  static void handleAbility7Input(bool keyPressed, GameState gameState) {
    if (keyPressed && gameState.ability7Cooldown <= 0) {
      executeSlotAbility(6, gameState);
    }
  }

  /// Handles Ability 8 input
  static void handleAbility8Input(bool keyPressed, GameState gameState) {
    if (keyPressed && gameState.ability8Cooldown <= 0) {
      executeSlotAbility(7, gameState);
    }
  }

  /// Handles Ability 9 input
  static void handleAbility9Input(bool keyPressed, GameState gameState) {
    if (keyPressed && gameState.ability9Cooldown <= 0) {
      executeSlotAbility(8, gameState);
    }
  }

  /// Handles Ability 10 input
  static void handleAbility10Input(bool keyPressed, GameState gameState) {
    if (keyPressed && gameState.ability10Cooldown <= 0) {
      executeSlotAbility(9, gameState);
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

  // ==================== COMBAT LOG HELPERS ====================

  /// Log a heal event to the combat log.
  static void _logHeal(GameState gameState, String abilityName, double healedAmount) {
    gameState.combatLogMessages.add(CombatLogEntry(
      source: 'Player',
      action: abilityName,
      type: CombatLogType.heal,
      amount: healedAmount,
      target: 'Player',
    ));
    if (gameState.combatLogMessages.length > 200) {
      gameState.combatLogMessages.removeAt(0);
    }
  }

  // ==================== UTILITY FUNCTIONS ====================

  /// Converts degrees to radians
  static double _radians(double degrees) => degrees * (math.pi / 180);

  /// Returns the effective ability with user overrides applied
  static AbilityData _effective(AbilityData original) {
    return globalAbilityOverrideManager?.getEffectiveAbility(original) ?? original;
  }
}
