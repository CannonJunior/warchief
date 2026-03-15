import 'package:vector_math/vector_math.dart';
import '../state/game_state.dart';
import '../data/abilities/abilities.dart';
import '../../models/active_effect.dart';

/// Gameplay Aura System — spreads aura buffs from casters to nearby friendly units.
///
/// Each unit with an active aura effect (identified by sourceName matching an
/// [AbilityData] where [AbilityData.isAura] == true) pulses a short-lived buff
/// to all friendlies within [AbilityData.auraRange] every [_tickInterval] seconds.
class GameplayAuraSystem {
  GameplayAuraSystem._();

  /// How often auras pulse their buff to nearby units (seconds).
  static const double _tickInterval = 1.0;

  /// Duration applied to nearby allies per pulse. Must exceed _tickInterval so
  /// allies don't lose the buff between pulses when on the range boundary.
  static const double _pulseDuration = 3.0;

  static double _accumulator = 0.0;

  static void update(double dt, GameState gameState) {
    _accumulator += dt;
    if (_accumulator < _tickInterval) return;
    _accumulator -= _tickInterval;
    _tickAuras(gameState);
  }

  static void _tickAuras(GameState gameState) {
    // Process auras from the player/warchief
    if (gameState.playerTransform != null) {
      _processUnitAuras(
        activeEffects: gameState.playerActiveEffects,
        casterPos: gameState.playerTransform!.position,
        gameState: gameState,
      );
    }
    // Process auras from each alive ally
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      _processUnitAuras(
        activeEffects: ally.activeEffects,
        casterPos: ally.transform.position,
        gameState: gameState,
      );
    }
  }

  /// For a single unit's active effects, find all active aura effects and
  /// pulse their buff to nearby friendlies.
  static void _processUnitAuras({
    required List<ActiveEffect> activeEffects,
    required Vector3 casterPos,
    required GameState gameState,
  }) {
    for (final effect in activeEffects) {
      if (effect.isExpired) continue;
      final ability = AbilityRegistry.findByName(effect.sourceName);
      if (ability == null || !ability.isAura) continue;
      _pulseAura(ability: ability, casterPos: casterPos, gameState: gameState);
    }
  }

  /// Apply/refresh the aura's buff on all friendly units within range.
  static void _pulseAura({
    required AbilityData ability,
    required Vector3 casterPos,
    required GameState gameState,
  }) {
    final range = ability.auraRange;
    final effectType = ability.statusEffect;
    final strength = ability.statusStrength;
    final sourceName = '${ability.name} [Aura]';

    // Helper: squared XZ distance check (Y ignored — units share the same terrain plane)
    double distSq(Vector3 a, Vector3 b) {
      final dx = a.x - b.x;
      final dz = a.z - b.z;
      return dx * dx + dz * dz;
    }

    final rangeSq = range * range;

    // Apply to player
    if (gameState.playerTransform != null &&
        distSq(gameState.playerTransform!.position, casterPos) <= rangeSq) {
      _refreshOrAddBuff(
        effects: gameState.playerActiveEffects,
        type: effectType,
        duration: _pulseDuration,
        strength: strength,
        sourceName: sourceName,
      );
    }

    // Apply to alive allies
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      if (distSq(ally.transform.position, casterPos) <= rangeSq) {
        _refreshOrAddBuff(
          effects: ally.activeEffects,
          type: effectType,
          duration: _pulseDuration,
          strength: strength,
          sourceName: sourceName,
        );
      }
    }
  }

  /// Refresh an existing aura buff or add a new one if absent.
  static void _refreshOrAddBuff({
    required List<ActiveEffect> effects,
    required StatusEffect type,
    required double duration,
    required double strength,
    required String sourceName,
  }) {
    for (final e in effects) {
      if (e.type == type && e.sourceName == sourceName) {
        e.remainingDuration = duration;
        return;
      }
    }
    effects.add(ActiveEffect(
      type: type,
      remainingDuration: duration,
      totalDuration: duration,
      strength: strength,
      sourceName: sourceName,
    ));
  }
}
