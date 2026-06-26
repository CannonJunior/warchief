import 'dart:math' as math;
import '../state/game_state.dart';
import '../state/cc_config.dart';

/// An active gravity well pulling nearby units toward its anchor.
class GravityWell {
  final double anchorX;
  final double anchorZ;
  final double radius;
  final double pullSpeed;
  final double duration;
  double remainingDuration;
  final int casterId;

  GravityWell({
    required this.anchorX,
    required this.anchorZ,
    required this.radius,
    required this.pullSpeed,
    required this.duration,
    required this.casterId,
  }) : remainingDuration = duration;
}

/// Manages active gravity wells and applies per-frame pull to nearby units.
class GravityWellSystem {
  GravityWellSystem._();

  static final List<GravityWell> _wells = [];

  static List<GravityWell> get activeWells => _wells;

  static void add(GravityWell well) => _wells.add(well);

  static void reset() => _wells.clear();

  static void update(double dt, GameState gameState) {
    _wells.removeWhere((well) {
      well.remainingDuration -= dt;
      if (well.remainingDuration <= 0) return true;

      final r2 = well.radius * well.radius;

      // Pull player
      if (gameState.playerTransform != null) {
        _pullUnit(
          dt, well, r2,
          gameState.playerTransform!.position.x,
          gameState.playerTransform!.position.z,
          (dx, dz) {
            gameState.playerTransform!.position.x += dx;
            gameState.playerTransform!.position.z += dz;
          },
        );
      }

      // Pull allies
      for (final ally in gameState.allies) {
        if (ally.health <= 0) continue;
        _pullUnit(
          dt, well, r2,
          ally.transform.position.x, ally.transform.position.z,
          (dx, dz) {
            ally.transform.position.x += dx;
            ally.transform.position.z += dz;
          },
        );
      }

      // Pull boss
      if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
        _pullUnit(
          dt, well, r2,
          gameState.monsterTransform!.position.x,
          gameState.monsterTransform!.position.z,
          (dx, dz) {
            gameState.monsterTransform!.position.x += dx;
            gameState.monsterTransform!.position.z += dz;
          },
        );
      }

      // Pull minions
      for (final minion in gameState.aliveMinions) {
        _pullUnit(
          dt, well, r2,
          minion.transform.position.x, minion.transform.position.z,
          (dx, dz) {
            minion.transform.position.x += dx;
            minion.transform.position.z += dz;
          },
        );
      }

      return false;
    });
  }

  static void _pullUnit(
    double dt, GravityWell well, double r2,
    double ux, double uz,
    void Function(double dx, double dz) applyDelta,
  ) {
    final dx = well.anchorX - ux;
    final dz = well.anchorZ - uz;
    final distSq = dx * dx + dz * dz;
    if (distSq >= r2 || distSq < 0.01) return;

    final dist = math.sqrt(distSq);
    // Reason: pull strength falls off linearly with distance from center
    final distRatio = dist / well.radius;
    final pullStr = well.pullSpeed * (1.0 - distRatio) * dt;
    final nx = dx / dist;
    final nz = dz / dist;
    applyDelta(nx * pullStr, nz * pullStr);
  }
}
