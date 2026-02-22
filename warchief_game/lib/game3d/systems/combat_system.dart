import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../ui/damage_indicators.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/impact_effect.dart';
import '../../models/combat_log_entry.dart';
import '../../models/monster.dart';
import 'goal_system.dart';
import '../data/stances/stances.dart';

/// Target types for damage application
enum DamageTarget { player, monster, ally, minion, dummy }

/// Combat System - Unified damage and collision handling
///
/// Provides centralized functions for:
/// - Collision detection between attackers and targets
/// - Damage application to any unit (player, monster, ally)
/// - Impact effect creation
class CombatSystem {
  CombatSystem._(); // Private constructor to prevent instantiation

  /// Shared RNG for dodge rolls (avoids repeated instantiation in hot path)
  static final math.Random _rng = math.Random();

  /// Creates an impact effect at the specified position
  ///
  /// Parameters:
  /// - gameState: Current game state to add the effect to
  /// - position: World position for the impact effect
  /// - color: RGB color of the impact effect
  /// - size: Size of the impact effect
  static void createImpactEffect(
    GameState gameState, {
    required Vector3 position,
    required Vector3 color,
    required double size,
  }) {
    final impactMesh = Mesh.cube(
      size: size,
      color: color,
    );
    final impactTransform = Transform3d(
      position: position.clone(),
      scale: Vector3(1, 1, 1),
    );
    gameState.impactEffects.add(ImpactEffect(
      mesh: impactMesh,
      transform: impactTransform,
    ));
  }

  /// Checks collision and applies damage to the target if hit
  ///
  /// This is the main unified damage function used by all attacks.
  /// It checks if the attacker position is within collision threshold
  /// of the target, and if so, creates an impact effect and applies damage.
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - targetPosition: Position of the target unit
  /// - collisionThreshold: Distance threshold for collision detection
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - targetType: Type of target (player, monster, ally, or minion)
  /// - allyIndex: Index of the ally if targetType is ally (optional)
  /// - minionInstanceId: Instance ID of the minion if targetType is minion (optional)
  ///
  /// Returns:
  /// - true if hit was registered, false otherwise
  static bool checkAndApplyDamage(
    GameState gameState, {
    required Vector3 attackerPosition,
    required Vector3 targetPosition,
    required double collisionThreshold,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    required DamageTarget targetType,
    int? allyIndex,
    String? minionInstanceId,
    bool showDamageIndicator = false,
    bool isMelee = false,
  }) {
    final dx = attackerPosition.x - targetPosition.x;
    final dy = attackerPosition.y - targetPosition.y;
    final dz = attackerPosition.z - targetPosition.z;
    final distSq = dx * dx + dy * dy + dz * dz;

    if (distSq < collisionThreshold * collisionThreshold) {
      // Reason: Cache activeStance once — the getter does registry lookup +
      // override merge + potential copyWith on every call.
      final stance = targetType == DamageTarget.player ? gameState.activeStance : null;

      // Dodge check: player stance dodgeChance (skip for target dummy)
      if (targetType == DamageTarget.player) {
        final dodgeChance = stance!.dodgeChance;
        if (dodgeChance > 0 && _rng.nextDouble() < dodgeChance) {
          gameState.combatLogMessages.add(CombatLogEntry(
            source: attackType.split(' ').first,
            action: '$attackType DODGED',
            type: CombatLogType.damage,
            amount: 0,
            target: 'Player',
          ));
          if (gameState.combatLogMessages.length > 250) {
            gameState.combatLogMessages.removeRange(0, gameState.combatLogMessages.length - 200);
          }
          return false;
        }
      }

      // Create impact effect at collision point
      createImpactEffect(
        gameState,
        position: attackerPosition,
        color: impactColor,
        size: impactSize,
      );

      // Track health before damage to detect killing blows
      double healthBefore = 0.0;
      if (showDamageIndicator) {
        switch (targetType) {
          case DamageTarget.monster:
            healthBefore = gameState.monsterHealth;
            break;
          case DamageTarget.minion:
            if (minionInstanceId != null) {
              for (final m in gameState.minions) {
                if (m.instanceId == minionInstanceId && m.isAlive) {
                  healthBefore = m.health;
                  break;
                }
              }
            }
            break;
          case DamageTarget.dummy:
            healthBefore = double.infinity; // Dummy can't die
            break;
          default:
            break;
        }
      }

      // Apply damage based on target type
      switch (targetType) {
        case DamageTarget.player:
          final effectiveDamage = damage * stance!.damageTakenMultiplier;
          gameState.playerHealth = (gameState.playerHealth - effectiveDamage)
              .clamp(0.0, gameState.playerMaxHealth);
          // Tide stance: convert portion of damage taken into primary attuned mana
          if (stance.damageTakenToManaRatio > 0) {
            gameState.generateManaFromDamageTaken(effectiveDamage * stance.damageTakenToManaRatio);
          }
          assert(() { print('$attackType hit player for ${effectiveDamage.toStringAsFixed(1)} damage! '
                'Player health: ${gameState.playerHealth.toStringAsFixed(1)}'); return true; }());
          // Reason: Auto-acquire nearest enemy when hit with no target (WoW behavior).
          // Melee players immediately know who is attacking them.
          if (gameState.currentTargetId == null && gameState.activeTransform != null) {
            final pos = gameState.activeTransform!.position;
            gameState.tabToNextTarget(pos.x, pos.z, gameState.activeRotation);
          }
          // Spell pushback: push back castProgress when hit while casting
          if (gameState.isCasting && gameState.castProgress > 0 &&
              gameState.castPushbackCount < 3) {
            final resistance = stance.spellPushbackResistance;
            if (resistance < 1.0) {
              // Reason: pushback = castTime * basePushback(0.25) * (1 - resistance)
              final pushbackAmount = gameState.currentCastTime * 0.25 * (1.0 - resistance);
              gameState.castProgress = (gameState.castProgress - pushbackAmount).clamp(0.0, gameState.currentCastTime);
              gameState.castPushbackCount++;
              assert(() { print('[PUSHBACK] Cast pushed back by ${pushbackAmount.toStringAsFixed(2)}s '
                    '(${gameState.castPushbackCount}/3, resistance=${(resistance * 100).round()}%)'); return true; }());
            }
          }
          break;

        case DamageTarget.monster:
          gameState.monsterHealth = (gameState.monsterHealth - damage)
              .clamp(0.0, gameState.monsterMaxHealth);
          assert(() { print('$attackType hit monster for $damage damage! '
                'Monster health: ${gameState.monsterHealth.toStringAsFixed(1)}'); return true; }());
          break;

        case DamageTarget.ally:
          if (allyIndex != null && allyIndex < gameState.allies.length) {
            final ally = gameState.allies[allyIndex];
            ally.health = (ally.health - damage).clamp(0.0, ally.maxHealth);
            assert(() { print('$attackType hit ally ${allyIndex + 1} for $damage damage! '
                  'Ally health: ${ally.health.toStringAsFixed(1)}'); return true; }());
          }
          break;

        case DamageTarget.minion:
          if (minionInstanceId != null) {
            for (final minion in gameState.minions) {
              if (minion.instanceId == minionInstanceId && minion.isAlive) {
                minion.takeDamage(damage);
                assert(() { print('$attackType hit ${minion.definition.name} for $damage damage! '
                      'Minion health: ${minion.health.toStringAsFixed(1)}/${minion.maxHealth}'); return true; }());
                break;
              }
            }
          }
          break;

        case DamageTarget.dummy:
          if (gameState.targetDummy != null && gameState.targetDummy!.isSpawned) {
            gameState.targetDummy!.takeDamage(damage);
            assert(() { print('$attackType hit Target Dummy for $damage damage! '
                  'Total: ${gameState.targetDummy!.totalDamageTaken.toStringAsFixed(1)}'); return true; }());
          }
          break;
      }

      // Log to combat log
      _logCombat(gameState, attackType, damage, targetType, allyIndex, minionInstanceId);

      // Spawn floating damage indicator for player attacks on enemies
      if (showDamageIndicator && damage > 0) {
        bool isKill = false;
        if (targetType == DamageTarget.monster) {
          isKill = healthBefore > 0 && gameState.monsterHealth <= 0;
        } else if (targetType == DamageTarget.minion && minionInstanceId != null) {
          bool minionAlive = false;
          for (final m in gameState.minions) {
            if (m.instanceId == minionInstanceId) {
              minionAlive = m.isAlive;
              break;
            }
          }
          isKill = healthBefore > 0 && !minionAlive;
        }

        // Position the indicator above the target
        final indicatorPos = targetPosition.clone();
        indicatorPos.y += 2.0;

        gameState.damageIndicators.add(DamageIndicator(
          damage: damage,
          worldPosition: indicatorPos,
          isMelee: isMelee,
          isKillingBlow: isKill,
        ));
      }

      return true;
    }

    return false;
  }

  /// Checks collision with player and applies damage if hit
  ///
  /// Convenience function for attacks targeting the player.
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - collisionThreshold: Distance threshold (defaults to GameConfig value)
  ///
  /// Returns:
  /// - true if hit was registered, false otherwise
  static bool checkAndDamagePlayer(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    if (gameState.playerTransform == null || gameState.playerHealth <= 0) {
      return false;
    }

    return checkAndApplyDamage(
      gameState,
      attackerPosition: attackerPosition,
      targetPosition: gameState.playerTransform!.position,
      collisionThreshold: collisionThreshold ?? GameConfig.collisionThreshold,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      targetType: DamageTarget.player,
    );
  }

  /// Checks collision with monster and applies damage if hit
  ///
  /// Convenience function for attacks targeting the monster.
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - collisionThreshold: Distance threshold (defaults to GameConfig value)
  ///
  /// Returns:
  /// - true if hit was registered, false otherwise
  static bool checkAndDamageMonster(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
    bool showDamageIndicator = false,
    bool isMelee = false,
  }) {
    if (gameState.monsterTransform == null || gameState.monsterHealth <= 0) {
      return false;
    }

    return checkAndApplyDamage(
      gameState,
      attackerPosition: attackerPosition,
      targetPosition: gameState.monsterTransform!.position,
      collisionThreshold: collisionThreshold ?? GameConfig.collisionThreshold,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      targetType: DamageTarget.monster,
      showDamageIndicator: showDamageIndicator,
      isMelee: isMelee,
    );
  }

  /// Checks collision with all allies and applies damage to the first hit
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - collisionThreshold: Distance threshold (defaults to GameConfig value)
  ///
  /// Returns:
  /// - true if any ally was hit, false otherwise
  static bool checkAndDamageAllies(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    for (int i = 0; i < gameState.allies.length; i++) {
      final ally = gameState.allies[i];
      if (ally.health <= 0) continue; // Skip dead allies

      final hit = checkAndApplyDamage(
        gameState,
        attackerPosition: attackerPosition,
        targetPosition: ally.transform.position,
        collisionThreshold: collisionThreshold ?? GameConfig.collisionThreshold,
        damage: damage,
        attackType: attackType,
        impactColor: impactColor,
        impactSize: impactSize,
        targetType: DamageTarget.ally,
        allyIndex: i,
      );

      if (hit) return true;
    }

    return false;
  }

  /// Checks collision with player and all allies, applying damage to the first hit
  ///
  /// Used for monster AoE or projectile attacks that can hit any friendly unit.
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - collisionThreshold: Distance threshold (defaults to GameConfig value)
  ///
  /// Returns:
  /// - true if any target was hit, false otherwise
  static bool checkAndDamagePlayerOrAllies(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    // Check player first
    if (checkAndDamagePlayer(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
    )) {
      return true;
    }

    // Then check allies
    return checkAndDamageAllies(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
    );
  }

  /// Checks collision with all minions and applies damage to the first hit
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// - attackerPosition: Position of the attacking projectile/melee hit
  /// - damage: Amount of damage to apply
  /// - attackType: Description of the attack (for logging)
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - collisionThreshold: Distance threshold (defaults to GameConfig value)
  ///
  /// Returns:
  /// - true if any minion was hit, false otherwise
  /// Minimum collision threshold for minions to ensure they can be hit
  static const double _minMinionCollisionThreshold = 0.8;

  static bool checkAndDamageMinions(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
    bool showDamageIndicator = false,
    bool isMelee = false,
  }) {
    for (final minion in gameState.aliveMinions) {
      // Use larger of: provided threshold, scale-based threshold, or minimum threshold
      // This ensures even small minions can be reliably hit
      final scaleBasedThreshold = minion.definition.effectiveScale * 0.8;
      final effectiveThreshold = collisionThreshold ??
          (scaleBasedThreshold > _minMinionCollisionThreshold
              ? scaleBasedThreshold
              : _minMinionCollisionThreshold);

      final hit = checkAndApplyDamage(
        gameState,
        attackerPosition: attackerPosition,
        targetPosition: minion.transform.position,
        collisionThreshold: effectiveThreshold,
        damage: damage,
        attackType: attackType,
        impactColor: impactColor,
        impactSize: impactSize,
        targetType: DamageTarget.minion,
        minionInstanceId: minion.instanceId,
        showDamageIndicator: showDamageIndicator,
        isMelee: isMelee,
      );

      if (hit) return true;
    }

    return false;
  }

  /// Checks collision with monster and all minions, applying damage to the first hit
  ///
  /// Used for player/ally attacks that should hit any enemy.
  /// Also checks the target dummy if it's spawned and targeted.
  ///
  /// Parameters:
  /// - isMeleeDamage: If true, generates red mana for the player when damage is dealt
  ///
  /// Returns:
  /// - true if any enemy was hit, false otherwise
  static bool checkAndDamageEnemies(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
    Color? abilityColor, // For DPS tracking
    bool isMeleeDamage = false, // For red mana generation
  }) {
    // Check target dummy first if it's the current target
    if (gameState.isTargetingDummy && gameState.targetDummy != null) {
      final dummy = gameState.targetDummy!;
      final threshold = collisionThreshold ?? 1.8;
      final ddx = attackerPosition.x - dummy.position.x;
      final ddy = attackerPosition.y - dummy.position.y;
      final ddz = attackerPosition.z - dummy.position.z;

      if (ddx * ddx + ddy * ddy + ddz * ddz < threshold * threshold) {
        // Use ability color if provided, otherwise derive from impact color
        final trackingColor = abilityColor ?? _vectorToColor(impactColor);

        final hit = damageTargetDummy(
          gameState,
          damage: damage,
          abilityName: attackType,
          abilityColor: trackingColor,
          impactColor: impactColor,
          impactSize: impactSize,
          isCritical: false,
          isHit: true,
          isMelee: isMeleeDamage,
        );
        return hit;
      }
    }

    // Check boss monster first
    final bossHealthBefore = gameState.monsterHealth;
    if (checkAndDamageMonster(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
      showDamageIndicator: true,
      isMelee: isMeleeDamage,
    )) {
      // Generate red mana from melee damage
      if (isMeleeDamage) {
        gameState.generateRedManaFromMelee(damage);
      }
      // Track melee streaks for mastery goals
      if (isMeleeDamage) {
        gameState.consecutiveMeleeHits++;
        GoalSystem.processEvent(gameState, 'consecutive_melee_hits',
            metadata: {'streak': gameState.consecutiveMeleeHits});
      }
      // Emit goal events on boss kill
      if (bossHealthBefore > 0 && gameState.monsterHealth <= 0) {
        GoalSystem.processEvent(gameState, 'enemy_killed');
        GoalSystem.processEvent(gameState, 'boss_killed');
      }
      return true;
    }

    // Then check minions — snapshot alive count before damage
    final aliveCountBefore = gameState.aliveMinions.length;
    final minionHit = checkAndDamageMinions(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: attackType,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
      showDamageIndicator: true,
      isMelee: isMeleeDamage,
    );

    if (minionHit) {
      // Generate red mana from melee damage to minions
      if (isMeleeDamage) {
        gameState.generateRedManaFromMelee(damage);
        // Track melee streaks for mastery goals
        gameState.consecutiveMeleeHits++;
        GoalSystem.processEvent(gameState, 'consecutive_melee_hits',
            metadata: {'streak': gameState.consecutiveMeleeHits});
      }
      // Check for minion kills — scan for newly dead minions
      // checkAndDamageMinions hits at most one, so at most one kill per call
      gameState.refreshAliveMinions();
      if (gameState.aliveMinions.length < aliveCountBefore) {
        GoalSystem.processEvent(gameState, 'enemy_killed');
        // Find the killed minion to emit type-specific goal event
        for (final minion in gameState.minions) {
          if (!minion.isAlive && minion.health <= 0) {
            // Heuristic: recently killed minion (health exactly 0 or below)
            GoalSystem.processEvent(
                gameState, 'kill_${minion.definition.id}');
            break;
          }
        }
      }
    }

    return minionHit;
  }

  /// Log a damage event to the combat log.
  static void _logCombat(GameState gs, String attackType, double damage,
      DamageTarget targetType, int? allyIndex, String? minionInstanceId) {
    String target;
    switch (targetType) {
      case DamageTarget.player:
        target = 'Player';
        break;
      case DamageTarget.monster:
        target = 'Monster';
        break;
      case DamageTarget.ally:
        target = 'Ally ${(allyIndex ?? 0) + 1}';
        break;
      case DamageTarget.minion:
        target = 'Minion';
        break;
      case DamageTarget.dummy:
        target = 'Dummy';
        break;
    }
    gs.combatLogMessages.add(CombatLogEntry(
      source: attackType.split(' ').first,
      action: attackType,
      type: CombatLogType.damage,
      amount: damage,
      target: target,
    ));
    // Cap at 250 entries, batch-trim to 200 to amortize removeRange cost
    if (gs.combatLogMessages.length > 250) {
      gs.combatLogMessages.removeRange(0, gs.combatLogMessages.length - 200);
    }
  }

  /// Convert Vector3 color to Flutter Color
  static Color _vectorToColor(Vector3 v) {
    return Color.fromRGBO(
      (v.x * 255).clamp(0, 255).toInt(),
      (v.y * 255).clamp(0, 255).toInt(),
      (v.z * 255).clamp(0, 255).toInt(),
      1.0,
    );
  }

  /// Damage a specific minion by instance ID (for targeted attacks)
  static bool damageMinion(
    GameState gameState, {
    required String minionInstanceId,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    bool showDamageIndicator = false,
    bool isMelee = false,
  }) {
    Monster? foundMinion;
    for (final m in gameState.minions) {
      if (m.instanceId == minionInstanceId && m.isAlive) {
        foundMinion = m;
        break;
      }
    }

    if (foundMinion == null) return false;
    final minion = foundMinion;

    final healthBefore = minion.health;

    createImpactEffect(
      gameState,
      position: minion.transform.position,
      color: impactColor,
      size: impactSize,
    );

    minion.takeDamage(damage);
    assert(() { print('$attackType hit ${minion.definition.name} for $damage damage! '
          'Health: ${minion.health.toStringAsFixed(1)}/${minion.maxHealth}'); return true; }());

    if (showDamageIndicator && damage > 0) {
      final indicatorPos = minion.transform.position.clone();
      indicatorPos.y += 2.0;
      gameState.damageIndicators.add(DamageIndicator(
        damage: damage,
        worldPosition: indicatorPos,
        isMelee: isMelee,
        isKillingBlow: healthBefore > 0 && !minion.isAlive,
      ));
    }

    return true;
  }

  /// Damage the target dummy and record for DPS tracking
  ///
  /// This is the primary function for attacking the target dummy.
  /// It handles damage application, impact effects, and DPS tracking.
  ///
  /// Parameters:
  /// - gameState: Current game state
  /// - damage: Amount of damage to apply
  /// - abilityName: Name of the ability for DPS tracking
  /// - abilityColor: Color for the DPS chart
  /// - impactColor: Color of the impact effect
  /// - impactSize: Size of the impact effect
  /// - isCritical: Whether this is a critical hit
  /// - isHit: Whether the attack hit (false for miss/dodge)
  ///
  /// Returns:
  /// - true if damage was applied, false if dummy not available
  static bool damageTargetDummy(
    GameState gameState, {
    required double damage,
    required String abilityName,
    required Color abilityColor,
    required Vector3 impactColor,
    required double impactSize,
    bool isCritical = false,
    bool isHit = true,
    bool isMelee = false,
  }) {
    final dummy = gameState.targetDummy;
    if (dummy == null || !dummy.isSpawned) return false;

    // Record to DPS tracker (even misses for hit rate calculation)
    gameState.dpsTracker.recordDamage(
      abilityName: abilityName,
      damage: isHit ? damage : 0,
      isCritical: isCritical,
      isHit: isHit,
      abilityColor: abilityColor,
    );

    if (isHit) {
      // Apply damage to dummy
      dummy.takeDamage(damage);

      // Create impact effect
      createImpactEffect(
        gameState,
        position: dummy.position,
        color: impactColor,
        size: impactSize,
      );

      // Spawn floating damage indicator
      if (damage > 0) {
        final indicatorPos = dummy.position.clone();
        indicatorPos.y += 2.0;
        gameState.damageIndicators.add(DamageIndicator(
          damage: damage,
          worldPosition: indicatorPos,
          isMelee: isMelee,
          isKillingBlow: false, // Dummy can't die
        ));
      }

      assert(() { print('[DPS] $abilityName hit Target Dummy for $damage damage${isCritical ? " (CRIT!)" : ""}'); return true; }());
    } else {
      assert(() { print('[DPS] $abilityName missed Target Dummy'); return true; }());
    }

    return true;
  }

  /// Check if current target is the dummy and apply damage with DPS tracking
  ///
  /// Convenience function that checks if the current target is the dummy
  /// and routes damage appropriately.
  ///
  /// Returns:
  /// - true if the target was the dummy and damage was applied
  /// - false if the target is not the dummy
  static bool checkAndDamageTargetDummy(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String abilityName,
    required Color abilityColor,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
    bool isCritical = false,
    bool isMelee = false,
  }) {
    final dummy = gameState.targetDummy;
    if (dummy == null || !dummy.isSpawned) return false;

    final threshold = collisionThreshold ?? 1.5;
    final tdx = attackerPosition.x - dummy.position.x;
    final tdy = attackerPosition.y - dummy.position.y;
    final tdz = attackerPosition.z - dummy.position.z;

    if (tdx * tdx + tdy * tdy + tdz * tdz < threshold * threshold) {
      return damageTargetDummy(
        gameState,
        damage: damage,
        abilityName: abilityName,
        abilityColor: abilityColor,
        impactColor: impactColor,
        impactSize: impactSize,
        isCritical: isCritical,
        isHit: true,
        isMelee: isMelee,
      );
    }

    return false;
  }

  /// Damage the current target (enemy or dummy) based on targeting
  ///
  /// This is the recommended function for player abilities that should
  /// work against both real enemies and the target dummy.
  ///
  /// Returns:
  /// - true if any target was hit
  static bool damageCurrentTarget(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String abilityName,
    required Color abilityColor,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
    bool isCritical = false,
  }) {
    // Check if targeting the dummy
    if (gameState.isTargetingDummy) {
      return checkAndDamageTargetDummy(
        gameState,
        attackerPosition: attackerPosition,
        damage: damage,
        abilityName: abilityName,
        abilityColor: abilityColor,
        impactColor: impactColor,
        impactSize: impactSize,
        collisionThreshold: collisionThreshold,
        isCritical: isCritical,
      );
    }

    // Otherwise damage enemies normally
    return checkAndDamageEnemies(
      gameState,
      attackerPosition: attackerPosition,
      damage: damage,
      attackType: abilityName,
      impactColor: impactColor,
      impactSize: impactSize,
      collisionThreshold: collisionThreshold,
    );
  }
}
