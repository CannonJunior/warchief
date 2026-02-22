import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../state/game_state.dart';
import '../../state/mana_config.dart';
import '../../state/gameplay_settings.dart';
import '../../data/abilities/ability_types.dart' show ManaColor;
import '../../../models/monster_ontology.dart' show MonsterFaction;

/// Draws a green mana source overlay on the minimap.
///
/// Shows:
/// - Grass regen zones: soft green tint on terrain areas where grass grows
/// - Spirit being auras: bright green pulsing rings around spirit-form allies
/// - Nature creatures: prominent glow + leaf icon around elemental/nature minions
///   that replenish high amounts of green mana (e.g. Dryad Lifebinder)
///
/// Only displayed when the active character is attuned to Green mana
/// and the green overlay toggle is enabled.
class MinimapGreenPainter extends CustomPainter {
  final GameState gameState;
  final double viewRadius;
  final double playerRotation;
  final bool isRotatingMode;
  final double elapsedTime;

  MinimapGreenPainter({
    required this.gameState,
    required this.viewRadius,
    required this.playerRotation,
    required this.isRotatingMode,
    required this.elapsedTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final half = size.width / 2;
    final center = Offset(half, half);

    // Clip to circle
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: half)));

    _paintGrassZones(canvas, size, half);
    _paintSpiritBeingAuras(canvas, half);
    _paintNatureCreatures(canvas, half);

    canvas.restore();
  }

  /// Paint a soft green tint over areas where grass grows (mid-height terrain).
  ///
  /// Reason: samples terrain height at a coarse grid and fills grass-weight
  /// pixels with translucent green so players can see where to stand for regen.
  void _paintGrassZones(Canvas canvas, Size size, double half) {
    if (gameState.infiniteTerrainManager == null) return;

    final playerX = gameState.playerTransform?.position.x ?? 0.0;
    final playerZ = gameState.playerTransform?.position.z ?? 0.0;

    // Reason: coarse grid (every 4 pixels) keeps paint fast while giving a
    // readable heat-map feel; finer grids cause frame drops.
    const step = 4.0;
    final paint = Paint()..style = PaintingStyle.fill;

    for (double py = 0; py < size.height; py += step) {
      for (double px = 0; px < size.width; px += step) {
        // Check circular bounds
        final rdx = px - half;
        final rdy = py - half;
        if (rdx * rdx + rdy * rdy > half * half) continue;

        // Convert minimap pixel to world coordinate
        double worldX, worldZ;
        if (isRotatingMode) {
          final ndx = (px - half) / half;
          final ndy = -(py - half) / half;
          final rightComp = ndx * viewRadius;
          final fwdComp = ndy * viewRadius;
          final rotRad = playerRotation * math.pi / 180.0;
          final cosR = math.cos(rotRad);
          final sinR = math.sin(rotRad);
          worldX = playerX + rightComp * cosR - fwdComp * sinR;
          worldZ = playerZ - rightComp * sinR - fwdComp * cosR;
        } else {
          worldX = playerX - ((px - half) / half) * viewRadius;
          worldZ = playerZ - ((py - half) / half) * viewRadius;
        }

        // Compute grass weight (same formula as game_state.dart)
        final height =
            gameState.infiniteTerrainManager!.getTerrainHeight(worldX, worldZ);
        final normalizedHeight = ((height + 10.0) / 40.0).clamp(0.0, 1.0);
        double grassWeight = 0.0;
        if (normalizedHeight > 0.15 && normalizedHeight < 0.65) {
          grassWeight =
              1.0 - ((normalizedHeight - 0.4).abs() * 3.0).clamp(0.0, 1.0);
        }

        if (grassWeight > 0.05) {
          paint.color = Color.fromRGBO(60, 200, 60, grassWeight * 0.18);
          canvas.drawRect(
              Rect.fromLTWH(px, py, step, step), paint);
        }
      }
    }
  }

  /// Paint pulsing aura rings around spirit-form allies.
  void _paintSpiritBeingAuras(Canvas canvas, double half) {
    final config = globalManaConfig;
    final spiritRadius = config?.spiritBeingRadius ?? 6.0;
    final playerX = gameState.playerTransform?.position.x ?? 0.0;
    final playerZ = gameState.playerTransform?.position.z ?? 0.0;

    final pulse = math.sin(elapsedTime * 2.5) * 0.5 + 0.5;

    // Draw Warchief spirit form aura
    if (gameState.playerInSpiritForm) {
      _drawSpiritAura(canvas, Offset(half, half), spiritRadius, half, pulse);
    }

    // Draw ally spirit form auras
    for (final ally in gameState.allies) {
      if (ally.health <= 0 || !ally.inSpiritForm) continue;
      final pos = _worldToMinimap(
          ally.transform.position.x, ally.transform.position.z,
          playerX, playerZ, half);
      if (pos != null) {
        _drawSpiritAura(canvas, pos, spiritRadius, half, pulse);
      }
    }
  }

  /// Draw a pulsing green aura circle at a minimap position.
  void _drawSpiritAura(
      Canvas canvas, Offset center, double worldRadius, double half,
      double pulse) {
    final pixelRadius = (worldRadius / viewRadius) * half;
    final alpha = 0.12 + pulse * 0.1;

    // Soft filled circle
    canvas.drawCircle(
      center,
      pixelRadius,
      Paint()
        ..color = Color.fromRGBO(80, 255, 80, alpha)
        ..style = PaintingStyle.fill,
    );

    // Pulsing ring border
    canvas.drawCircle(
      center,
      pixelRadius * (0.9 + pulse * 0.1),
      Paint()
        ..color = Color.fromRGBO(100, 255, 100, 0.3 + pulse * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Small spirit icon at center (diamond shape)
    _drawLeafIcon(canvas, center, 4.0, Color.fromRGBO(120, 255, 120, 0.8));
  }

  /// Paint prominent indicators around nature creatures (elemental faction)
  /// that are high green mana sources.
  void _paintNatureCreatures(Canvas canvas, double half) {
    final playerX = gameState.playerTransform?.position.x ?? 0.0;
    final playerZ = gameState.playerTransform?.position.z ?? 0.0;
    final pulse = math.sin(elapsedTime * 3.0) * 0.5 + 0.5;

    // Check green-attuned alive allies that could be nature creatures
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      final allyAttunements =
          (globalGameplaySettings?.attunementRequired ?? true)
              ? ally.combinedManaAttunements
              : {ManaColor.blue, ManaColor.red, ManaColor.white, ManaColor.green};
      if (!allyAttunements.contains(ManaColor.green)) continue;

      final pos = _worldToMinimap(
          ally.transform.position.x, ally.transform.position.z,
          playerX, playerZ, half);
      if (pos != null) {
        // Reason: green-attuned allies are proximity regen sources; show
        // their proximity radius as a subtle green ring
        final config = globalManaConfig;
        final proxRadius = config?.proximityRadius ?? 2.0;
        final pixelRadius = (proxRadius / viewRadius) * half;
        canvas.drawCircle(
          pos,
          pixelRadius,
          Paint()
            ..color = Color.fromRGBO(60, 200, 60, 0.15)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Highlight elemental/nature minions prominently
    for (final minion in gameState.aliveMinions) {
      if (minion.definition.faction != MonsterFaction.elemental &&
          minion.definition.faction != MonsterFaction.beast) {
        continue;
      }

      final pos = _worldToMinimap(
          minion.transform.position.x, minion.transform.position.z,
          playerX, playerZ, half);
      if (pos == null) continue;

      // Prominent glow ring
      final glowRadius = 8.0 + pulse * 3.0;
      canvas.drawCircle(
        pos,
        glowRadius,
        Paint()
          ..color = Color.fromRGBO(40, 220, 40, 0.15 + pulse * 0.1)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        pos,
        glowRadius,
        Paint()
          ..color = Color.fromRGBO(80, 255, 80, 0.4 + pulse * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Leaf icon
      _drawLeafIcon(
          canvas, pos, 5.0, Color.fromRGBO(80, 255, 80, 0.7 + pulse * 0.3));
    }
  }

  /// Draw a simple leaf-shaped icon at position.
  void _drawLeafIcon(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size) // Top tip
      ..quadraticBezierTo(
          center.dx + size, center.dy, center.dx, center.dy + size) // Right curve
      ..quadraticBezierTo(
          center.dx - size, center.dy, center.dx, center.dy - size) // Left curve
      ..close();

    canvas.drawPath(path, Paint()..color = color);

    // Stem line
    canvas.drawLine(
      Offset(center.dx, center.dy - size * 0.3),
      Offset(center.dx, center.dy + size * 0.5),
      Paint()
        ..color = color.withOpacity(0.6)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
  }

  /// Convert world coordinates to minimap pixel position.
  Offset? _worldToMinimap(double worldX, double worldZ, double playerX,
      double playerZ, double half) {
    final dx = worldX - playerX;
    final dz = worldZ - playerZ;

    double mx, my;
    if (isRotatingMode) {
      final rotRad = playerRotation * math.pi / 180.0;
      final cosR = math.cos(rotRad);
      final sinR = math.sin(rotRad);
      final rightComp = dx * cosR - dz * sinR;
      final fwdComp = -dx * sinR - dz * cosR;
      mx = half + (rightComp / viewRadius) * half;
      my = half - (fwdComp / viewRadius) * half;
    } else {
      mx = half - (dx / viewRadius) * half;
      my = half - (dz / viewRadius) * half;
    }

    final rdx = mx - half;
    final rdy = my - half;
    if (rdx * rdx + rdy * rdy > half * half) return null;

    return Offset(mx, my);
  }

  @override
  bool shouldRepaint(MinimapGreenPainter oldDelegate) => true;
}
