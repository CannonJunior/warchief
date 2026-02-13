import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../state/game_state.dart';
import '../../state/minimap_config.dart';

/// CustomPainter that draws entity blips on the minimap.
///
/// Entity types and their representations (all config-driven):
/// - Player: silver triangle rotated by facing direction (always at center)
/// - Allies: green filled circles
/// - Enemy minions: red filled circles
/// - Boss: larger bright red filled circle
/// - Target dummy: yellow X shape
class MinimapEntityPainter extends CustomPainter {
  final GameState gameState;
  final double viewRadius;

  MinimapEntityPainter({
    required this.gameState,
    required this.viewRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final config = globalMinimapConfig;
    final half = size.width / 2;
    final playerX = gameState.playerTransform?.position.x ?? 0.0;
    final playerZ = gameState.playerTransform?.position.z ?? 0.0;

    // Draw target dummy (yellow X)
    if (gameState.targetDummy != null && gameState.targetDummy!.isSpawned) {
      final pos = _worldToMinimap(
          gameState.targetDummy!.position.x,
          gameState.targetDummy!.position.z,
          playerX, playerZ, half);
      if (pos != null) {
        _drawX(canvas, pos, 6, const Color(0xFFFFCC00));
      }
    }

    // Draw ley power nodes (small blue-purple diamonds)
    if (gameState.leyLineManager != null) {
      final nodeColor = _colorFromList(
          config?.powerNodeColor ?? [0.40, 0.27, 0.80, 0.8]);
      for (final node in gameState.leyLineManager!.powerNodes) {
        final pos = _worldToMinimap(node.x, node.z, playerX, playerZ, half);
        if (pos != null) {
          _drawDiamond(canvas, pos, 3, nodeColor);
        }
      }
    }

    // Draw enemy minions (red dots)
    final enemyColor = _colorFromList(
        config?.enemyColor ?? [1.0, 0.27, 0.27, 1.0]);
    final enemySize = (config?.enemySize ?? 4).toDouble();
    for (final minion in gameState.aliveMinions) {
      final pos = _worldToMinimap(
          minion.transform.position.x,
          minion.transform.position.z,
          playerX, playerZ, half);
      if (pos != null) {
        canvas.drawCircle(pos, enemySize / 2, Paint()..color = enemyColor);
      }
    }

    // Draw boss (larger red dot)
    if (gameState.monsterHealth > 0 && gameState.monsterTransform != null) {
      final bossColor = _colorFromList(
          config?.bossColor ?? [1.0, 0.0, 0.0, 1.0]);
      final bossSize = (config?.bossSize ?? 8).toDouble();
      final pos = _worldToMinimap(
          gameState.monsterTransform!.position.x,
          gameState.monsterTransform!.position.z,
          playerX, playerZ, half);
      if (pos != null) {
        // Glow behind boss dot
        canvas.drawCircle(
            pos,
            bossSize / 2 + 2,
            Paint()..color = bossColor.withOpacity(0.3));
        canvas.drawCircle(pos, bossSize / 2, Paint()..color = bossColor);
      }
    }

    // Draw allies (green dots)
    final allyColor = _colorFromList(
        config?.allyColor ?? [0.40, 0.80, 0.40, 1.0]);
    final allySize = (config?.allySize ?? 5).toDouble();
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      final pos = _worldToMinimap(
          ally.transform.position.x,
          ally.transform.position.z,
          playerX, playerZ, half);
      if (pos != null) {
        canvas.drawCircle(pos, allySize / 2, Paint()..color = allyColor);
      }
    }

    // Draw player arrow (silver triangle at center, rotated by facing)
    _drawPlayerArrow(canvas, half);
  }

  /// Draw the player as a rotated triangle at the minimap center.
  void _drawPlayerArrow(Canvas canvas, double half) {
    final config = globalMinimapConfig;
    final playerColor = _colorFromList(
        config?.playerColor ?? [0.75, 0.75, 0.75, 1.0]);
    final playerSize = (config?.playerSize ?? 8).toDouble();
    final rotation = gameState.playerRotation;

    // Convert rotation to radians (game rotation: 0=north, increases clockwise)
    final angleRad = rotation * math.pi / 180.0;

    canvas.save();
    canvas.translate(half, half);
    canvas.rotate(angleRad);

    final path = Path()
      ..moveTo(0, -playerSize) // Tip (forward)
      ..lineTo(-playerSize * 0.6, playerSize * 0.5) // Bottom left
      ..lineTo(0, playerSize * 0.2) // Bottom notch
      ..lineTo(playerSize * 0.6, playerSize * 0.5) // Bottom right
      ..close();

    // Outline glow
    canvas.drawPath(
      path,
      Paint()
        ..color = playerColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Filled arrow
    canvas.drawPath(path, Paint()..color = playerColor);

    canvas.restore();
  }

  /// Draw an X shape at position.
  void _drawX(Canvas canvas, Offset pos, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(pos.dx - size / 2, pos.dy - size / 2),
      Offset(pos.dx + size / 2, pos.dy + size / 2),
      paint,
    );
    canvas.drawLine(
      Offset(pos.dx + size / 2, pos.dy - size / 2),
      Offset(pos.dx - size / 2, pos.dy + size / 2),
      paint,
    );
  }

  /// Draw a diamond shape at position.
  void _drawDiamond(Canvas canvas, Offset pos, double size, Color color) {
    final path = Path()
      ..moveTo(pos.dx, pos.dy - size)
      ..lineTo(pos.dx + size, pos.dy)
      ..lineTo(pos.dx, pos.dy + size)
      ..lineTo(pos.dx - size, pos.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  /// Convert world coordinates to minimap pixel position.
  Offset? _worldToMinimap(double worldX, double worldZ,
      double playerX, double playerZ, double half) {
    final dx = worldX - playerX;
    final dz = worldZ - playerZ;

    final mx = half + (dx / viewRadius) * half;
    final my = half - (dz / viewRadius) * half;

    // Check within circular bounds
    final rdx = mx - half;
    final rdy = my - half;
    if (rdx * rdx + rdy * rdy > half * half) return null;

    return Offset(mx, my);
  }

  /// Convert [r, g, b, a] list to Color.
  static Color _colorFromList(List<double> rgba) {
    return Color.fromRGBO(
      (rgba[0] * 255).round(),
      (rgba[1] * 255).round(),
      (rgba[2] * 255).round(),
      rgba.length > 3 ? rgba[3] : 1.0,
    );
  }

  @override
  bool shouldRepaint(MinimapEntityPainter oldDelegate) => true;
}
