import 'dart:math' as math;
import 'dart:ui';
import 'package:vector_math/vector_math.dart';

import '../state/game_state.dart';
import '../utils/screen_projection.dart';
import '../../models/target_dummy.dart';

/// A candidate entity for click-to-select picking.
class _PickCandidate {
  /// Entity ID (e.g. 'boss', 'ally_0', minion instanceId, 'target_dummy')
  final String id;

  /// Projected screen position
  final Offset screenPos;

  /// Distance from click point in screen pixels
  final double distance;

  _PickCandidate(this.id, this.screenPos, this.distance);
}

/// Screen-space entity picking system for click-to-select targeting.
///
/// Projects all entity positions from 3D world space to 2D screen
/// coordinates, then finds the entity closest to the click point
/// within a configurable selection radius.
class EntityPickingSystem {
  EntityPickingSystem._(); // Private constructor

  /// Pick the nearest entity to a click position in screen space.
  ///
  /// Builds a list of all targetable entities (boss, minions, allies,
  /// target dummy), projects each to screen coordinates, and returns
  /// the ID of the closest entity within [selectionRadius] pixels.
  ///
  /// Args:
  ///   clickPos: Click position in screen pixels.
  ///   viewMatrix: Camera view matrix.
  ///   projMatrix: Camera projection matrix.
  ///   screenSize: Current viewport size.
  ///   gameState: Current game state with all entities.
  ///   selectionRadius: Maximum pixel distance for selection.
  ///
  /// Returns:
  ///   Entity ID string, or null if no entity within radius.
  static String? pickEntity({
    required Offset clickPos,
    required Matrix4 viewMatrix,
    required Matrix4 projMatrix,
    required Size screenSize,
    required GameState gameState,
    required double selectionRadius,
  }) {
    final candidates = <_PickCandidate>[];

    // Boss
    if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
      _addCandidate(
        candidates,
        'boss',
        gameState.monsterTransform!.position,
        clickPos,
        viewMatrix,
        projMatrix,
        screenSize,
      );
    }

    // Minions
    for (final minion in gameState.aliveMinions) {
      _addCandidate(
        candidates,
        minion.instanceId,
        minion.transform.position,
        clickPos,
        viewMatrix,
        projMatrix,
        screenSize,
      );
    }

    // Allies
    for (int i = 0; i < gameState.allies.length; i++) {
      final ally = gameState.allies[i];
      if (ally.health > 0) {
        _addCandidate(
          candidates,
          'ally_$i',
          ally.transform.position,
          clickPos,
          viewMatrix,
          projMatrix,
          screenSize,
        );
      }
    }

    // Duel combatants
    for (int i = 0; i < gameState.duelCombatants.length; i++) {
      final combatant = gameState.duelCombatants[i];
      if (combatant.health > 0) {
        _addCandidate(
          candidates,
          'duel_$i',
          combatant.transform.position,
          clickPos,
          viewMatrix,
          projMatrix,
          screenSize,
        );
      }
    }

    // Target dummy
    if (gameState.targetDummy != null && gameState.targetDummy!.isSpawned) {
      _addCandidate(
        candidates,
        TargetDummy.instanceId,
        gameState.targetDummy!.position,
        clickPos,
        viewMatrix,
        projMatrix,
        screenSize,
      );
    }

    if (candidates.isEmpty) return null;

    // Find closest candidate within selection radius
    candidates.sort((a, b) => a.distance.compareTo(b.distance));
    final closest = candidates.first;

    if (closest.distance <= selectionRadius) {
      return closest.id;
    }

    return null;
  }

  /// Project an entity and add it as a pick candidate if visible.
  static void _addCandidate(
    List<_PickCandidate> candidates,
    String id,
    Vector3 worldPos,
    Offset clickPos,
    Matrix4 viewMatrix,
    Matrix4 projMatrix,
    Size screenSize,
  ) {
    final screenPos = worldToScreen(worldPos, viewMatrix, projMatrix, screenSize);
    if (screenPos == null) return; // Behind camera

    final dx = screenPos.dx - clickPos.dx;
    final dy = screenPos.dy - clickPos.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    candidates.add(_PickCandidate(id, screenPos, distance));
  }
}
