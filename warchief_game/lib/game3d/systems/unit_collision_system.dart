import 'dart:math' as math;
import '../state/game_state.dart';
import '../state/game_config.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/target_dummy.dart';

/// Soft spring-force separation that prevents units from overlapping.
///
/// After all movement each frame (input, AI, wind drift, wall collisions),
/// this system checks every pair of units and pushes overlapping pairs apart
/// proportionally to their overlap depth. The result is a gentle springy
/// separation rather than a hard snap, so units briefly overlap during fast
/// movement but smoothly resolve.
///
/// During dash abilities the player is excluded ("phased") so movement
/// abilities punch through crowds.
class UnitCollisionSystem {
  UnitCollisionSystem._();

  /// How aggressively overlapping units are pushed apart each frame.
  /// 0.0 = no push, 1.0 = instant snap apart. 0.4 gives a soft springy feel.
  static const double _separationStrength = 0.4;

  /// Reusable list to avoid per-frame allocation.
  static final List<_CollisionUnit> _units = [];

  static final math.Random _rng = math.Random();

  /// Run pairwise soft separation on all active units.
  static void resolve(GameState gameState) {
    _units.clear();

    final playerPhased = gameState.ability4Active;

    // Player
    if (gameState.playerTransform != null && !playerPhased) {
      _units.add(_CollisionUnit(
        gameState.playerTransform!,
        GameConfig.playerSize * 0.5,
      ));
    }

    // Allies
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      _units.add(_CollisionUnit(ally.transform, GameConfig.allySize * 0.5));
    }

    // Boss monster
    if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
      _units.add(_CollisionUnit(
        gameState.monsterTransform!,
        GameConfig.monsterSize * 0.5,
      ));
    }

    // Alive minions
    for (final minion in gameState.aliveMinions) {
      _units.add(_CollisionUnit(
        minion.transform,
        minion.definition.effectiveScale * 0.5,
      ));
    }

    // Duel combatants
    for (final combatant in gameState.duelCombatants) {
      if (combatant.health <= 0) continue;
      _units.add(_CollisionUnit(combatant.transform, GameConfig.allySize * 0.5));
    }

    // Target dummy
    final dummy = gameState.targetDummy;
    if (dummy != null && dummy.isSpawned) {
      _units.add(_CollisionUnit(dummy.transform, TargetDummy.size * 0.5));
    }

    // Pairwise separation
    final n = _units.length;
    for (int i = 0; i < n; i++) {
      final a = _units[i];
      for (int j = i + 1; j < n; j++) {
        final b = _units[j];
        _separate(a, b);
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
      // Nearly identical positions — random nudge to break symmetry
      final angle = _rng.nextDouble() * math.pi * 2;
      nx = math.cos(angle);
      nz = math.sin(angle);
    } else {
      nx = dx / dist;
      nz = dz / dist;
    }

    final overlap = minDist - dist;
    final push = overlap * 0.5 * _separationStrength;

    a.t.position.x += nx * push;
    a.t.position.z += nz * push;
    b.t.position.x -= nx * push;
    b.t.position.z -= nz * push;
  }
}

class _CollisionUnit {
  final Transform3d t;
  final double radius;
  _CollisionUnit(this.t, this.radius);
}
