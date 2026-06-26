import 'dart:math' as math;
import '../state/game_state.dart';
import '../state/game_config.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/target_dummy.dart';

/// Unit separation system that prevents overlapping.
///
/// After all movement each frame (input, AI, wind drift, wall collisions),
/// this system checks every pair of units and pushes overlapping pairs apart.
///
/// Cross-faction pairs (friendly vs enemy): only the friendly unit is pushed.
/// Enemies act as solid obstacles that cannot be displaced by walking into
/// them. Movement abilities bypass this by setting the player as "phased."
///
/// Same-faction pairs use a softer spring with multiple iterations so that
/// crowds of enemies (or allies) spread out naturally without bunching.
class UnitCollisionSystem {
  UnitCollisionSystem._();

  /// Same-faction spring strength per iteration. At 0.8 with 4 iterations,
  /// remaining overlap is 0.2^4 ≈ 0.2% — effectively fully resolved.
  static const double _sameFactionStrength = 0.8;

  /// Number of pairwise iterations. Multiple passes resolve multi-body
  /// clumps that a single pass cannot (e.g. 5 minions converging on one spot).
  static const int _iterations = 4;

  /// Reusable list to avoid per-frame allocation.
  static final List<_CollisionUnit> _units = [];

  static final math.Random _rng = math.Random();

  /// Run pairwise separation on all active units.
  static void resolve(GameState gameState) {
    _units.clear();

    final playerPhased = gameState.ability4Active;

    // Player
    if (gameState.playerTransform != null && !playerPhased) {
      _units.add(_CollisionUnit(
        gameState.playerTransform!,
        GameConfig.playerSize * 0.5,
        _Faction.friendly,
      ));
    }

    // Allies
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      _units.add(_CollisionUnit(ally.transform, GameConfig.allySize * 0.5, _Faction.friendly));
    }

    // Boss monster
    if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
      _units.add(_CollisionUnit(
        gameState.monsterTransform!,
        GameConfig.monsterSize * 0.5,
        _Faction.enemy,
      ));
    }

    // Alive minions
    for (final minion in gameState.aliveMinions) {
      _units.add(_CollisionUnit(
        minion.transform,
        minion.definition.effectiveScale * 0.5,
        _Faction.enemy,
      ));
    }

    // Duel combatants
    for (final combatant in gameState.duelCombatants) {
      if (combatant.health <= 0) continue;
      _units.add(_CollisionUnit(combatant.transform, GameConfig.allySize * 0.5, _Faction.neutral));
    }

    // Target dummy
    final dummy = gameState.targetDummy;
    if (dummy != null && dummy.isSpawned) {
      _units.add(_CollisionUnit(dummy.transform, TargetDummy.size * 0.5, _Faction.neutral));
    }

    // Multiple iterations resolve multi-body clumps
    final n = _units.length;
    for (int iter = 0; iter < _iterations; iter++) {
      for (int i = 0; i < n; i++) {
        final a = _units[i];
        for (int j = i + 1; j < n; j++) {
          _separate(a, _units[j]);
        }
      }
    }
  }

  static void _separate(_CollisionUnit a, _CollisionUnit b) {
    final dx = a.t.position.x - b.t.position.x;
    final dz = a.t.position.z - b.t.position.z;
    final distSq = dx * dx + dz * dz;
    final minDist = a.radius + b.radius;

    if (distSq >= minDist * minDist) return;

    final dist = math.sqrt(distSq);

    double nx, nz;
    if (dist < 0.001) {
      final angle = _rng.nextDouble() * math.pi * 2;
      nx = math.cos(angle);
      nz = math.sin(angle);
    } else {
      nx = dx / dist;
      nz = dz / dist;
    }

    final overlap = minDist - dist;

    final crossFaction = a.faction != b.faction &&
        a.faction != _Faction.neutral &&
        b.faction != _Faction.neutral;

    if (crossFaction) {
      // Only the friendly unit gets pushed — enemies are solid obstacles.
      // Push by full overlap so the friendly unit can't make net progress
      // even if it keeps walking/pathing into the enemy each frame.
      if (a.faction == _Faction.friendly) {
        a.t.position.x += nx * overlap;
        a.t.position.z += nz * overlap;
      } else {
        b.t.position.x -= nx * overlap;
        b.t.position.z -= nz * overlap;
      }
    } else {
      // Same-faction or neutral: soft spring, push both equally
      final push = overlap * 0.5 * _sameFactionStrength;
      a.t.position.x += nx * push;
      a.t.position.z += nz * push;
      b.t.position.x -= nx * push;
      b.t.position.z -= nz * push;
    }
  }
}

enum _Faction { friendly, enemy, neutral }

class _CollisionUnit {
  final Transform3d t;
  final double radius;
  final _Faction faction;
  _CollisionUnit(this.t, this.radius, this.faction);
}
