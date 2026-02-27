import 'package:vector_math/vector_math.dart';

import '../state/game_state.dart';
import '../state/combo_config.dart';
import '../../models/active_effect.dart';
import '../../models/combat_log_entry.dart';
import '../data/abilities/ability_types.dart' show StatusEffect;
import '../data/abilities/abilities.dart' show AbilityRegistry;
import '../ui/damage_indicators.dart' show DamageIndicator;

/// Melee Combo System — tracks consecutive same-class hits and fires
/// per-class reward effects when the threshold is reached.
///
/// ## Regular Combos
/// Every time a melee ability lands, [onMeleeHit] is called with the
/// ability name. The system looks up the ability's category via
/// [AbilityRegistry] and checks if it matches the current active combo.
/// Reaching the threshold (3 hits) triggers the class reward and resets.
///
/// ## Chain Combos
/// A chain primer ability (`enablesComboChain = true`) activates chain mode.
/// In chain mode, the next 7 same-class melee hits fire:
/// - Hit 3: the regular 3-hit combo reward (counter is NOT reset)
/// - Hit 7: the upgraded chain combo reward; chain mode then deactivates.
///
/// [update] must be called each frame to decay the inactivity timers.
class MeleeComboSystem {
  MeleeComboSystem._();

  // ==================== FRAME UPDATE ====================

  /// Decay combo/chain timers; reset if their windows expire.
  static void update(double dt, GameState gameState) {
    // Regular combo timer
    if (gameState.meleeComboCategory != null) {
      gameState.meleeComboTimer += dt;
      final window = globalComboConfig?.comboWindow ?? 4.0;
      if (gameState.meleeComboTimer > window) {
        gameState.meleeComboCount = 0;
        gameState.meleeComboCategory = null;
        gameState.meleeComboTimer = 0.0;
      }
    }

    // Chain mode inactivity timer
    if (gameState.meleeChainModeActive) {
      gameState.meleeChainTimer += dt;
      final chainWindow = globalComboConfig?.chainWindow ?? 7.0;
      if (gameState.meleeChainTimer > chainWindow) {
        gameState.meleeChainModeActive = false;
        gameState.meleeChainCount = 0;
        gameState.meleeChainTimer = 0.0;
        gameState.meleeChainCategory = null;
      }
    }
  }

  // ==================== HIT REGISTRATION ====================

  /// Called immediately after a melee hit connects.
  ///
  /// [attackType] is the ability name string (e.g. 'Void Strike', 'Shield Bash').
  static void onMeleeHit(GameState gameState, String attackType) {
    final ability = AbilityRegistry.findByName(attackType);
    if (ability == null) return;
    final category = ability.category;

    final cfg = globalComboConfig?.getCategoryConfig(category);
    if (cfg == null) return; // no combo defined for this category

    // --- Chain primer: activate chain mode and return ---
    if (ability.enablesComboChain) {
      gameState.meleeChainModeActive = true;
      gameState.meleeChainCount = 0;
      gameState.meleeChainTimer = 0.0;
      gameState.meleeChainCategory = category;
      // Reason: reset regular combo so it doesn't compete while chaining.
      gameState.meleeComboCount = 0;
      gameState.meleeComboCategory = null;
      gameState.meleeComboTimer = 0.0;
      _logChainActivated(gameState, category);
      return;
    }

    // --- Chain mode: count hits toward 7-hit chain ---
    if (gameState.meleeChainModeActive) {
      if (gameState.meleeChainCategory != category) {
        // Wrong class breaks chain mode; fall through to start a new regular combo.
        gameState.meleeChainModeActive = false;
        gameState.meleeChainCount = 0;
        gameState.meleeChainTimer = 0.0;
        gameState.meleeChainCategory = null;
      } else {
        gameState.meleeChainCount++;
        gameState.meleeChainTimer = 0.0;

        // First 3-hit combo fires inside the chain (count is not reset).
        if (gameState.meleeChainCount == 3) {
          _triggerEffect(gameState, category, cfg);
        }

        // Full 7-hit chain fires on the 7th hit.
        if (gameState.meleeChainCount >= 7) {
          final chainCfg = cfg['chain'];
          if (chainCfg is Map<String, dynamic>) {
            _triggerChainEffect(gameState, category, chainCfg);
          }
          gameState.meleeChainModeActive = false;
          gameState.meleeChainCount = 0;
          gameState.meleeChainTimer = 0.0;
          gameState.meleeChainCategory = null;
        }
        return; // Don't process regular combo while in chain mode.
      }
    }

    // --- Regular combo tracking ---
    final threshold = cfg['threshold'] as int? ?? 3;

    if (gameState.meleeComboCategory == category) {
      // Continuing an existing combo — increment and reset inactivity timer.
      gameState.meleeComboCount++;
      gameState.meleeComboTimer = 0.0;
    } else {
      // New category (or first hit) — start fresh.
      gameState.meleeComboCategory = category;
      gameState.meleeComboCount = 1;
      gameState.meleeComboTimer = 0.0;
    }

    if (gameState.meleeComboCount >= threshold) {
      _triggerEffect(gameState, category, cfg);
      // Reason: reset to 0 so the very next hit can begin a new combo.
      gameState.meleeComboCount = 0;
      gameState.meleeComboCategory = null;
      gameState.meleeComboTimer = 0.0;
    }
  }

  // ==================== EFFECT DISPATCH ====================

  static void _triggerEffect(
    GameState gameState,
    String category,
    Map<String, dynamic> cfg,
  ) {
    final effect = cfg['effect'] as String? ?? '';
    switch (effect) {
      case 'knockback': _applyKnockback(gameState, cfg);
      case 'slow':      _applySlow(gameState, cfg);
      case 'haste':     _applyHaste(gameState, cfg);
      case 'redMana':   _applyRedMana(gameState, cfg);
      case 'aoe':       _applyAoe(gameState, cfg);
      case 'heal':      _applyHeal(gameState, cfg);
      case 'strength':  _applyStrength(gameState, cfg);
      case 'regen':     _applyRegen(gameState, cfg);
    }
    _logComboTrigger(gameState, category, effect);
  }

  /// Dispatch upgraded chain combo effects based on per-class chain config.
  static void _triggerChainEffect(
    GameState gs,
    String category,
    Map<String, dynamic> chain,
  ) {
    switch (category) {
      case 'warrior':
        // AoE knockback slam + burst damage around impact point.
        _applyKnockback(gs, chain);
        _applyAoe(gs, chain);
      case 'rogue':
        // Stronger slow + lifesteal regen HoT.
        _applySlow(gs, {'duration': 4.0, 'strength': chain['strength'] ?? 0.60});
        _applyRegen(gs, {
          'duration': 8.0,
          'healPerTick': chain['healPerTick'] ?? 4.0,
          'tickInterval': chain['tickInterval'] ?? 0.5,
        });
      case 'windwalker':
        // Enhanced haste surge.
        _applyHaste(gs, {'duration': 8.0, 'strength': chain['strength'] ?? 0.60});
      case 'starbreaker':
        // Dual mana burst: red + black.
        final redAmt = (chain['redManaAmount'] as num?)?.toDouble() ?? 60.0;
        final blackAmt = (chain['blackManaAmount'] as num?)?.toDouble() ?? 30.0;
        gs.redMana = (gs.redMana + redAmt).clamp(0.0, gs.maxRedMana);
        gs.blackMana = (gs.blackMana + blackAmt).clamp(0.0, gs.maxBlackMana);
      case 'stormheart':
        // Larger lightning AoE burst.
        _applyAoe(gs, chain);
      case 'healer':
        // Massive instant heal + regeneration HoT.
        _applyHeal(gs, {'amount': chain['amount'] ?? 60.0});
        _applyRegen(gs, {
          'duration': 8.0,
          'healPerTick': chain['healPerTick'] ?? 6.0,
          'tickInterval': chain['tickInterval'] ?? 0.5,
        });
      case 'necromancer':
        // Red mana gain + weakness debuff on monster.
        final manaAmt = (chain['redManaAmount'] as num?)?.toDouble() ?? 50.0;
        gs.redMana = (gs.redMana + manaAmt).clamp(0.0, gs.maxRedMana);
        _applyWeakness(gs, chain);
      case 'nature':
        // Root + sustained poison DoT.
        _applyRoot(gs, chain);
        _applyPoison(gs, chain);
      case 'greenseer':
        // Powerful long-duration regeneration.
        _applyRegen(gs, {
          'duration': (chain['duration'] as num?)?.toDouble() ?? 10.0,
          'healPerTick': chain['healPerTick'] ?? 12.0,
          'tickInterval': 0.5,
        });
      case 'mage':
        // Strength buff + arcane AoE burst.
        _applyStrength(gs, {'duration': 8.0, 'strength': chain['strength'] ?? 0.50});
        final dmg = (chain['damage'] as num?)?.toDouble();
        if (dmg != null) {
          _applyAoe(gs, {'damage': dmg, 'radius': chain['radius'] ?? 5.0});
        }
      case 'spiritkin':
        // Strong haste burst + healing regen.
        _applyHaste(gs, {
          'duration': 8.0,
          'strength': chain['hasteStrength'] ?? 0.60,
        });
        _applyRegen(gs, {
          'duration': 8.0,
          'healPerTick': chain['healPerTick'] ?? 6.0,
          'tickInterval': chain['tickInterval'] ?? 0.5,
        });
      case 'elemental':
        // Red mana surge + elemental AoE.
        final redAmt = (chain['redManaAmount'] as num?)?.toDouble() ?? 40.0;
        gs.redMana = (gs.redMana + redAmt).clamp(0.0, gs.maxRedMana);
        _applyAoe(gs, chain);
    }
    _logChainTrigger(gs, category);
  }

  // ==================== EFFECTS ====================

  /// warrior — slam target away from attacker.
  static void _applyKnockback(GameState gameState, Map<String, dynamic> cfg) {
    final force = (cfg['knockbackForce'] as num?)?.toDouble() ?? 5.0;
    if (gameState.monsterTransform != null &&
        gameState.playerTransform != null &&
        gameState.monsterHealth > 0) {
      final dir = gameState.monsterTransform!.position -
          gameState.playerTransform!.position;
      if (dir.length > 0.01) {
        dir.normalize();
        gameState.monsterTransform!.position += dir * force;
        gameState.monsterCurrentPath = null;
      }
    }
  }

  /// rogue / nature — slows monster movement for [duration] seconds.
  static void _applySlow(GameState gameState, Map<String, dynamic> cfg) {
    final duration = (cfg['duration'] as num?)?.toDouble() ?? 3.0;
    final strength = (cfg['strength'] as num?)?.toDouble() ?? 0.4;
    if (gameState.monsterHealth <= 0) return;
    gameState.monsterActiveEffects
        .removeWhere((e) => e.type == StatusEffect.slow && !e.isPermanent);
    gameState.monsterActiveEffects.add(ActiveEffect(
      type: StatusEffect.slow,
      remainingDuration: duration,
      totalDuration: duration,
      strength: strength,
      sourceName: 'Melee Combo',
    ));
  }

  /// windwalker / spiritkin — gives player a speed boost for [duration] seconds.
  static void _applyHaste(GameState gameState, Map<String, dynamic> cfg) {
    final duration = (cfg['duration'] as num?)?.toDouble() ?? 3.0;
    final strength = (cfg['strength'] as num?)?.toDouble() ?? 0.3;
    gameState.playerActiveEffects
        .removeWhere((e) => e.type == StatusEffect.haste && !e.isPermanent);
    gameState.playerActiveEffects.add(ActiveEffect(
      type: StatusEffect.haste,
      remainingDuration: duration,
      totalDuration: duration,
      strength: strength,
      sourceName: 'Melee Combo',
    ));
  }

  /// starbreaker / necromancer / elemental — burst of red mana.
  static void _applyRedMana(GameState gameState, Map<String, dynamic> cfg) {
    final amount = (cfg['amount'] as num?)?.toDouble() ?? 20.0;
    gameState.redMana = (gameState.redMana + amount).clamp(0.0, gameState.maxRedMana);
  }

  /// stormheart — burst of shadow damage to all nearby enemies.
  static void _applyAoe(GameState gameState, Map<String, dynamic> cfg) {
    final damage = (cfg['damage'] as num?)?.toDouble() ?? 30.0;
    final radius = (cfg['radius'] as num?)?.toDouble() ?? 4.0;
    final origin = gameState.activeTransform?.position;
    if (origin == null) return;

    if (gameState.monsterHealth > 0 && gameState.monsterTransform != null) {
      final dist = (gameState.monsterTransform!.position - origin).length;
      if (dist <= radius) {
        gameState.monsterHealth =
            (gameState.monsterHealth - damage).clamp(0.0, gameState.monsterMaxHealth);
        _addDamageIndicator(gameState, gameState.monsterTransform!.position, damage);
      }
    }

    for (final minion in gameState.aliveMinions) {
      final dist = (minion.transform.position - origin).length;
      if (dist <= radius) {
        minion.health = (minion.health - damage).clamp(0.0, minion.maxHealth);
        _addDamageIndicator(gameState, minion.transform.position, damage);
      }
    }
    gameState.refreshAliveMinions();
  }

  /// healer — instant self-heal.
  static void _applyHeal(GameState gameState, Map<String, dynamic> cfg) {
    final amount = (cfg['amount'] as num?)?.toDouble() ?? 20.0;
    gameState.playerHealth =
        (gameState.playerHealth + amount).clamp(0.0, gameState.playerMaxHealth);
    if (gameState.playerTransform != null) {
      _addHealIndicator(gameState, gameState.playerTransform!.position, amount);
    }
  }

  /// mage — short damage buff (strength) applied to player.
  static void _applyStrength(GameState gameState, Map<String, dynamic> cfg) {
    final duration = (cfg['duration'] as num?)?.toDouble() ?? 4.0;
    final strength = (cfg['strength'] as num?)?.toDouble() ?? 0.25;
    gameState.playerActiveEffects
        .removeWhere((e) => e.type == StatusEffect.strength && !e.isPermanent);
    gameState.playerActiveEffects.add(ActiveEffect(
      type: StatusEffect.strength,
      remainingDuration: duration,
      totalDuration: duration,
      strength: strength,
      sourceName: 'Melee Combo',
    ));
  }

  /// greenseer — regeneration over time (heals via negative DoT).
  static void _applyRegen(GameState gameState, Map<String, dynamic> cfg) {
    final duration = (cfg['duration'] as num?)?.toDouble() ?? 5.0;
    final healPerTick = (cfg['healPerTick'] as num?)?.toDouble() ?? 4.0;
    final tickInterval = (cfg['tickInterval'] as num?)?.toDouble() ?? 0.5;
    gameState.playerActiveEffects
        .removeWhere((e) => e.type == StatusEffect.regen && !e.isPermanent);
    // Reason: negative damagePerTick means the DoT loop heals instead of damages.
    gameState.playerActiveEffects.add(ActiveEffect(
      type: StatusEffect.regen,
      remainingDuration: duration,
      totalDuration: duration,
      damagePerTick: -healPerTick,
      tickInterval: tickInterval,
      sourceName: 'Melee Combo',
    ));
  }

  /// necromancer chain — weakness debuff on monster.
  static void _applyWeakness(GameState gameState, Map<String, dynamic> cfg) {
    final duration = (cfg['debuffDuration'] as num?)?.toDouble() ?? 4.0;
    final strength = (cfg['debuffStrength'] as num?)?.toDouble() ?? 0.30;
    if (gameState.monsterHealth <= 0) return;
    gameState.monsterActiveEffects
        .removeWhere((e) => e.type == StatusEffect.weakness && !e.isPermanent);
    gameState.monsterActiveEffects.add(ActiveEffect(
      type: StatusEffect.weakness,
      remainingDuration: duration,
      totalDuration: duration,
      strength: strength,
      sourceName: 'Melee Combo Chain',
    ));
  }

  /// nature chain — root the monster in place.
  static void _applyRoot(GameState gameState, Map<String, dynamic> cfg) {
    final duration = (cfg['rootDuration'] as num?)?.toDouble() ?? 3.0;
    if (gameState.monsterHealth <= 0) return;
    gameState.monsterActiveEffects
        .removeWhere((e) => e.type == StatusEffect.root && !e.isPermanent);
    gameState.monsterActiveEffects.add(ActiveEffect(
      type: StatusEffect.root,
      remainingDuration: duration,
      totalDuration: duration,
      sourceName: 'Melee Combo Chain',
    ));
  }

  /// nature chain — poison DoT on monster.
  static void _applyPoison(GameState gameState, Map<String, dynamic> cfg) {
    final dps = (cfg['poisonDps'] as num?)?.toDouble() ?? 8.0;
    final duration = (cfg['poisonDuration'] as num?)?.toDouble() ?? 5.0;
    if (gameState.monsterHealth <= 0) return;
    gameState.monsterActiveEffects
        .removeWhere((e) => e.type == StatusEffect.poison && !e.isPermanent);
    gameState.monsterActiveEffects.add(ActiveEffect(
      type: StatusEffect.poison,
      remainingDuration: duration,
      totalDuration: duration,
      damagePerTick: dps,
      tickInterval: 1.0,
      sourceName: 'Melee Combo Chain',
    ));
  }

  // ==================== HELPERS ====================

  static void _addDamageIndicator(
    GameState gameState,
    Vector3 worldPos,
    double damage,
  ) {
    final pos = worldPos.clone();
    pos.y += 2.0;
    gameState.damageIndicators.add(DamageIndicator(
      damage: damage,
      worldPosition: pos,
      isMelee: true,
    ));
  }

  static void _addHealIndicator(
    GameState gameState,
    Vector3 worldPos,
    double amount,
  ) {
    final pos = worldPos.clone();
    pos.y += 2.0;
    gameState.damageIndicators.add(DamageIndicator(
      damage: amount,
      worldPosition: pos,
      isHeal: true,
    ));
  }

  static void _logComboTrigger(
    GameState gameState,
    String category,
    String effect,
  ) {
    final label = _effectLabel(effect);
    gameState.combatLogMessages.add(CombatLogEntry(
      source: 'Combo',
      action: '$category combo: $label',
      type: CombatLogType.damage,
      amount: 0,
      target: 'Self',
    ));
    if (gameState.combatLogMessages.length > 250) {
      gameState.combatLogMessages
          .removeRange(0, gameState.combatLogMessages.length - 200);
    }
  }

  static void _logChainActivated(GameState gameState, String category) {
    gameState.combatLogMessages.add(CombatLogEntry(
      source: 'Chain',
      action: '$category chain primed — land 7 hits!',
      type: CombatLogType.damage,
      amount: 0,
      target: 'Self',
    ));
    if (gameState.combatLogMessages.length > 250) {
      gameState.combatLogMessages
          .removeRange(0, gameState.combatLogMessages.length - 200);
    }
  }

  static void _logChainTrigger(GameState gameState, String category) {
    gameState.combatLogMessages.add(CombatLogEntry(
      source: 'Chain',
      action: '$category CHAIN COMBO!',
      type: CombatLogType.damage,
      amount: 0,
      target: 'Self',
    ));
    if (gameState.combatLogMessages.length > 250) {
      gameState.combatLogMessages
          .removeRange(0, gameState.combatLogMessages.length - 200);
    }
  }

  static String _effectLabel(String effect) {
    switch (effect) {
      case 'knockback': return 'Combo Knockback!';
      case 'slow':      return 'Combo Slow!';
      case 'haste':     return 'Combo Haste!';
      case 'redMana':   return 'Combo Red Mana Surge!';
      case 'aoe':       return 'Combo Shockwave!';
      case 'heal':      return 'Combo Heal!';
      case 'strength':  return 'Combo Strength!';
      case 'regen':     return 'Combo Regen!';
      default:          return 'Combo!';
    }
  }
}
