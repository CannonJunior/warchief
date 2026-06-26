import 'dart:math' as math;
import '../state/game_state.dart';
import '../state/cc_config.dart';
import '../../models/active_effect.dart';
import '../../models/ally.dart';
import '../../models/combat_log_entry.dart';
import '../../models/monster.dart';
import '../data/abilities/ability_types.dart';

/// Active suppress pair: both caster and target are locked down.
class SuppressPair {
  final String casterId;
  final String targetId;
  double remainingDuration;
  SuppressPair({required this.casterId, required this.targetId, required this.remainingDuration});
}

/// Centralized per-frame CC behavior logic.
///
/// Handles sleep (damage-break + regen), charm (forced walk), polymorph
/// (damage-break + speed cap), taunt (forced target), suppress (mutual lock),
/// and banish (cooldown acceleration).
///
/// Called from game3d_widget_update.dart after updateActiveEffects.
class CcBehaviorSystem {
  CcBehaviorSystem._();

  static final List<SuppressPair> _suppressPairs = [];
  static List<SuppressPair> get suppressPairs => _suppressPairs;

  static void update(double dt, GameState gameState) {
    final cfg = globalCcConfig;

    _updateSleep(dt, gameState, cfg);
    _updatePolymorph(gameState);
    _updateBanish(dt, gameState, cfg);
    _updateSuppressPairs(dt, gameState);
  }

  static void reset() {
    _suppressPairs.clear();
  }

  // ==================== SLEEP ====================

  /// Sleep: passive HP regen; damage-break handled in the damage pipeline
  /// (any call to damage a sleeping target should call breakSleepOnDamage first).
  static void _updateSleep(double dt, GameState gameState, CcConfig? cfg) {
    final regenPct = (cfg?.sleepRegenPercent ?? 1.0) / 100.0;

    // Player
    if (_hasEffect(gameState.playerActiveEffects, StatusEffect.sleep)) {
      gameState.playerHealth = (gameState.playerHealth + gameState.playerMaxHealth * regenPct * dt)
          .clamp(0.0, gameState.playerMaxHealth);
    }

    // Allies
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      if (_hasEffect(ally.activeEffects, StatusEffect.sleep)) {
        ally.health = (ally.health + ally.maxHealth * regenPct * dt)
            .clamp(0.0, ally.maxHealth);
      }
    }

    // Boss
    if (gameState.monsterHealth > 0 &&
        _hasEffect(gameState.monsterActiveEffects, StatusEffect.sleep)) {
      gameState.monsterHealth = (gameState.monsterHealth + gameState.monsterMaxHealth * regenPct * dt)
          .clamp(0.0, gameState.monsterMaxHealth);
    }

    // Minions
    for (final minion in gameState.aliveMinions) {
      if (_hasEffect(minion.activeEffects, StatusEffect.sleep)) {
        minion.health = (minion.health + minion.maxHealth * regenPct * dt)
            .clamp(0.0, minion.maxHealth);
      }
    }
  }

  /// Call before applying damage to a unit. Removes sleep if present.
  /// Returns true if sleep was broken (caller may want to log it).
  /// When [gameState] and [targetName] are provided, logs "Sleep broken on [target]"
  /// to the combat log automatically.
  static bool breakSleepOnDamage(List<ActiveEffect> effects,
      {GameState? gameState, String? targetName}) {
    final idx = effects.indexWhere((e) => e.type == StatusEffect.sleep && !e.isExpired);
    if (idx < 0) return false;
    effects.removeAt(idx);
    if (gameState != null) {
      gameState.addCombatLog(CombatLogEntry(
        source: 'CC', action: 'Sleep broken on ${targetName ?? 'target'}',
        type: CombatLogType.debuff, target: targetName,
      ));
    }
    return true;
  }

  // ==================== POLYMORPH ====================

  /// Polymorph: damage-break handled the same way as sleep.
  static void _updatePolymorph(GameState gameState) {
    // Behavioral updates (speed capping, random wander for AI) are handled
    // in the AI and input systems by checking for the polymorph effect.
  }

  /// Call before applying damage to a unit. Removes polymorph if present.
  /// When [gameState] and [targetName] are provided, logs "Polymorph broken on [target]"
  /// to the combat log automatically.
  static bool breakPolymorphOnDamage(List<ActiveEffect> effects,
      {GameState? gameState, String? targetName}) {
    final idx = effects.indexWhere((e) => e.type == StatusEffect.polymorph && !e.isExpired);
    if (idx < 0) return false;
    effects.removeAt(idx);
    if (gameState != null) {
      gameState.addCombatLog(CombatLogEntry(
        source: 'CC', action: 'Polymorph broken on ${targetName ?? 'target'}',
        type: CombatLogType.debuff, target: targetName,
      ));
    }
    return true;
  }

  // ==================== BANISH ====================

  /// Banish: accelerate cooldown ticking.
  static void _updateBanish(double dt, GameState gameState, CcConfig? cfg) {
    final tickRate = cfg?.banishCooldownTickRate ?? 3.0;
    // Reason: cooldowns already tick by dt each frame. Banish adds
    // (tickRate - 1) * dt extra so the total is tickRate * dt.
    final bonusTick = (tickRate - 1.0) * dt;
    if (bonusTick <= 0) return;

    // Allies (includes player-controlled allies)
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      if (!_hasEffect(ally.activeEffects, StatusEffect.banish)) continue;
      for (int i = 0; i < ally.abilityCooldowns.length; i++) {
        if (ally.abilityCooldowns[i] > 0) {
          ally.abilityCooldowns[i] = (ally.abilityCooldowns[i] - bonusTick).clamp(0.0, double.infinity);
        }
      }
    }
  }

  // ==================== SUPPRESS ====================

  /// Register a new suppress pair (called when suppress effect is applied).
  static void addSuppressPair(String casterId, String targetId, double duration) {
    _suppressPairs.add(SuppressPair(
      casterId: casterId, targetId: targetId, remainingDuration: duration,
    ));
  }

  /// Tick suppress pairs. When a pair expires or is broken, apply 0.5s
  /// disorient micro-stagger to both caster and target.
  static void _updateSuppressPairs(double dt, GameState gameState) {
    _suppressPairs.removeWhere((pair) {
      pair.remainingDuration -= dt;
      if (pair.remainingDuration <= 0) {
        _applySuppressBreakStagger(gameState, pair.casterId);
        _applySuppressBreakStagger(gameState, pair.targetId);
        return true;
      }
      return false;
    });
  }

  /// Break a suppress pair involving [unitId] (e.g. when caster takes heavy damage).
  static void breakSuppress(GameState gameState, String unitId) {
    _suppressPairs.removeWhere((pair) {
      if (pair.casterId == unitId || pair.targetId == unitId) {
        _applySuppressBreakStagger(gameState, pair.casterId);
        _applySuppressBreakStagger(gameState, pair.targetId);
        // Remove suppress effects from both
        _removeEffect(gameState, pair.casterId, StatusEffect.suppress);
        _removeEffect(gameState, pair.targetId, StatusEffect.suppress);
        return true;
      }
      return false;
    });
  }

  static void _applySuppressBreakStagger(GameState gameState, String unitId) {
    final stagger = ActiveEffect(
      type: StatusEffect.stun, remainingDuration: 0.5,
      totalDuration: 0.5, strength: 1.0, sourceName: 'Suppress Break',
    );
    _addEffectToUnit(gameState, unitId, stagger);
  }

  // ==================== DAZE ====================

  /// Call when a dazed unit takes damage. Cancels any active cast/channel/windup
  /// and resets melee combo chain. Returns true if a cast was interrupted.
  static bool handleDazeDamageInterrupt(GameState gameState, String unitId) {
    final effects = _getEffects(gameState, unitId);
    if (effects == null || !_hasEffect(effects, StatusEffect.daze)) return false;

    if (unitId == 'player') {
      bool interrupted = false;
      if (gameState.isCasting) { gameState.cancelCast(); interrupted = true; }
      if (gameState.isChanneling) { gameState.cancelChannel(); interrupted = true; }
      if (gameState.isWindingUp) { gameState.isWindingUp = false; interrupted = true; }
      gameState.meleeChainCount = 0;
      gameState.meleeChainModeActive = false;
      return interrupted;
    }
    return false;
  }

  // ==================== GROUNDED ====================

  /// Whether this unit is grounded (blocks dashes, flight, teleports).
  static bool isGrounded(List<ActiveEffect> effects) {
    return _hasEffect(effects, StatusEffect.grounded);
  }

  // ==================== NEARSIGHT ====================

  /// Whether the player is nearsighted (fog-of-war shrink, hide CC overlay).
  static bool isNearsighted(List<ActiveEffect> effects) {
    return _hasEffect(effects, StatusEffect.nearsight);
  }

  // ==================== DISORIENT ====================

  /// Whether a unit is disoriented (scrambled input, camera sway).
  static bool isDisoriented(List<ActiveEffect> effects) {
    return _hasEffect(effects, StatusEffect.disorient);
  }

  // ==================== QUERY HELPERS ====================

  /// Whether a unit has a specific hard CC that blocks all actions.
  static bool isHardCCd(List<ActiveEffect> effects) {
    for (final e in effects) {
      if (e.isExpired) continue;
      switch (e.type) {
        case StatusEffect.stun:
        case StatusEffect.sleep:
        case StatusEffect.charm:
        case StatusEffect.polymorph:
        case StatusEffect.suppress:
        case StatusEffect.banish:
        case StatusEffect.airborne:
        case StatusEffect.fear:
        case StatusEffect.freeze:
          return true;
        default:
          continue;
      }
    }
    return false;
  }

  /// Whether a unit is banished (phased out — untargetable + invulnerable).
  static bool isBanished(List<ActiveEffect> effects) {
    return _hasEffect(effects, StatusEffect.banish);
  }

  /// Whether a unit is taunted (forced to attack taunter).
  static bool isTaunted(List<ActiveEffect> effects) {
    return _hasEffect(effects, StatusEffect.taunt);
  }

  /// Whether a unit is charmed (walking toward caster).
  static bool isCharmed(List<ActiveEffect> effects) {
    return _hasEffect(effects, StatusEffect.charm);
  }

  /// Whether a unit is polymorphed (critter form, movement only).
  static bool isPolymorphed(List<ActiveEffect> effects) {
    return _hasEffect(effects, StatusEffect.polymorph);
  }

  // ==================== INTERNAL HELPERS ====================

  static bool _hasEffect(List<ActiveEffect> effects, StatusEffect type) {
    for (final e in effects) {
      if (e.type == type && !e.isExpired) return true;
    }
    return false;
  }

  static void _removeEffect(GameState gameState, String unitId, StatusEffect type) {
    final effects = _getEffects(gameState, unitId);
    effects?.removeWhere((e) => e.type == type);
  }

  static void _addEffectToUnit(GameState gameState, String unitId, ActiveEffect effect) {
    final effects = _getEffects(gameState, unitId);
    effects?.add(effect);
  }

  static List<ActiveEffect>? _getEffects(GameState gameState, String unitId) {
    if (unitId == 'player') return gameState.playerActiveEffects;
    if (unitId == 'boss') return gameState.monsterActiveEffects;
    final ally = gameState.allies.where((a) => a.name == unitId).firstOrNull;
    if (ally != null) return ally.activeEffects;
    final minion = gameState.minionById(unitId);
    if (minion != null) return minion.activeEffects;
    return null;
  }
}
