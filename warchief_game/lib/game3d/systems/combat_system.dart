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
import 'melee_combo_system.dart';
import '../data/stances/stances.dart';
import '../data/abilities/ability_types.dart' show DamageSchool, StatusEffect, vulnerabilityForSchool;

part 'combat_system_enemies.dart';

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
    final impactMesh = Mesh.cube(size: size, color: color);
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
    DamageSchool damageSchool = DamageSchool.physical,
  }) {
    final dx = attackerPosition.x - targetPosition.x;
    final dy = attackerPosition.y - targetPosition.y;
    final dz = attackerPosition.z - targetPosition.z;
    final distSq = dx * dx + dy * dy + dz * dz;

    if (distSq < collisionThreshold * collisionThreshold) {
      // Reason: Check for matching vulnerability on target — 10% bonus per stack
      if (targetType == DamageTarget.monster || targetType == DamageTarget.minion) {
        final matchingVuln = vulnerabilityForSchool(damageSchool);
        List<dynamic>? effects;
        if (targetType == DamageTarget.monster) {
          effects = gameState.monsterActiveEffects;
        } else if (minionInstanceId != null) {
          for (final m in gameState.minions) {
            if (m.instanceId == minionInstanceId && m.isAlive) {
              effects = m.activeEffects;
              break;
            }
          }
        }
        if (effects != null) {
          for (final e in effects) {
            if (e.type == matchingVuln) {
              damage *= 1.0 + e.strength * 0.10;
              break;
            }
          }
        }
      }
      // Reason: Cache activeStance once — the getter does registry lookup +
      // override merge + potential copyWith on every call.
      final stance = targetType == DamageTarget.player ? gameState.activeStance : null;

      // Dodge check: player stance dodgeChance (skip for target dummy)
      if (targetType == DamageTarget.player) {
        final dodgeChance = stance!.dodgeChance;
        if (dodgeChance > 0 && _csRng.nextDouble() < dodgeChance) {
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
      createImpactEffect(gameState, position: attackerPosition, color: impactColor, size: impactSize);

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
      _csLogCombat(gameState, attackType, damage, targetType, allyIndex, minionInstanceId);

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
  static bool checkAndDamagePlayer(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    if (gameState.playerTransform == null || gameState.playerHealth <= 0) return false;
    return checkAndApplyDamage(
      gameState,
      attackerPosition: attackerPosition,
      targetPosition: gameState.playerTransform!.position,
      collisionThreshold: collisionThreshold ?? GameConfig.collisionThreshold,
      damage: damage, attackType: attackType, impactColor: impactColor,
      impactSize: impactSize, targetType: DamageTarget.player,
    );
  }

  /// Checks collision with monster and applies damage if hit
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
    if (gameState.monsterTransform == null || gameState.monsterHealth <= 0) return false;
    return checkAndApplyDamage(
      gameState,
      attackerPosition: attackerPosition,
      targetPosition: gameState.monsterTransform!.position,
      collisionThreshold: collisionThreshold ?? GameConfig.collisionThreshold,
      damage: damage, attackType: attackType, impactColor: impactColor,
      impactSize: impactSize, targetType: DamageTarget.monster,
      showDamageIndicator: showDamageIndicator, isMelee: isMelee,
    );
  }

  /// Checks collision with all allies and applies damage to the first hit
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
      if (ally.health <= 0) continue;
      final hit = checkAndApplyDamage(
        gameState,
        attackerPosition: attackerPosition,
        targetPosition: ally.transform.position,
        collisionThreshold: collisionThreshold ?? GameConfig.collisionThreshold,
        damage: damage, attackType: attackType, impactColor: impactColor,
        impactSize: impactSize, targetType: DamageTarget.ally, allyIndex: i,
      );
      if (hit) return true;
    }
    return false;
  }

  /// Checks collision with player and all allies, applying damage to the first hit
  static bool checkAndDamagePlayerOrAllies(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
  }) {
    if (checkAndDamagePlayer(gameState, attackerPosition: attackerPosition,
        damage: damage, attackType: attackType, impactColor: impactColor,
        impactSize: impactSize, collisionThreshold: collisionThreshold)) {
      return true;
    }
    return checkAndDamageAllies(gameState, attackerPosition: attackerPosition,
        damage: damage, attackType: attackType, impactColor: impactColor,
        impactSize: impactSize, collisionThreshold: collisionThreshold);
  }

  /// Minimum collision threshold for minions to ensure they can be hit
  static const double _minMinionCollisionThreshold = 0.8;

  /// Checks collision with all minions and applies damage to the first hit
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
        damage: damage, attackType: attackType, impactColor: impactColor,
        impactSize: impactSize, targetType: DamageTarget.minion,
        minionInstanceId: minion.instanceId,
        showDamageIndicator: showDamageIndicator, isMelee: isMelee,
      );
      if (hit) return true;
    }
    return false;
  }

  // ==================== DELEGATES → _CombatAdvanced ====================

  /// Checks collision with monster and all minions, applying damage to first hit
  static bool checkAndDamageEnemies(
    GameState gameState, {
    required Vector3 attackerPosition,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    required double impactSize,
    double? collisionThreshold,
    Color? abilityColor,
    bool isMeleeDamage = false,
  }) => _CombatAdvanced.checkAndDamageEnemies(gameState,
      attackerPosition: attackerPosition, damage: damage, attackType: attackType,
      impactColor: impactColor, impactSize: impactSize,
      collisionThreshold: collisionThreshold, abilityColor: abilityColor,
      isMeleeDamage: isMeleeDamage);

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
    DamageSchool damageSchool = DamageSchool.physical,
  }) => _CombatAdvanced.damageMinion(gameState,
      minionInstanceId: minionInstanceId, damage: damage, attackType: attackType,
      impactColor: impactColor, impactSize: impactSize,
      showDamageIndicator: showDamageIndicator, isMelee: isMelee,
      damageSchool: damageSchool);

  /// Damage the target dummy and record for DPS tracking
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
  }) => _CombatAdvanced.damageTargetDummy(gameState,
      damage: damage, abilityName: abilityName, abilityColor: abilityColor,
      impactColor: impactColor, impactSize: impactSize,
      isCritical: isCritical, isHit: isHit, isMelee: isMelee);

  /// Check if current target is the dummy and apply damage with DPS tracking
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
  }) => _CombatAdvanced.checkAndDamageTargetDummy(gameState,
      attackerPosition: attackerPosition, damage: damage, abilityName: abilityName,
      abilityColor: abilityColor, impactColor: impactColor, impactSize: impactSize,
      collisionThreshold: collisionThreshold, isCritical: isCritical, isMelee: isMelee);

  /// Damage the current target (enemy or dummy) based on targeting
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
  }) => _CombatAdvanced.damageCurrentTarget(gameState,
      attackerPosition: attackerPosition, damage: damage, abilityName: abilityName,
      abilityColor: abilityColor, impactColor: impactColor, impactSize: impactSize,
      collisionThreshold: collisionThreshold, isCritical: isCritical);
}
