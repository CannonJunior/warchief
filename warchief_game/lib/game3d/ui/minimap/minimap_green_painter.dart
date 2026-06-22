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

  // Reason: Paint objects cached to avoid per-drawCircle allocations inside
  // the grass grid loop (which iterates 100s of pixels per frame).
  late final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  late final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

  /// Cached grass zone grid: each entry stores grass weight (0.0–1.0).
  /// Re-sampled only when player moves > _grassCacheThreshold world units.
  static List<double>? _cachedGrassWeights;
  static double _cachedGrassPlayerX = double.nan;
  static double _cachedGrassPlayerZ = double.nan;
  static int _cachedGrassStepsX = 0;
  static int _cachedGrassStepsY = 0;
  static bool _cachedGrassRotating = false;
  static double _cachedGrassRotation = 0.0;
  static double _cachedGrassViewRadius = 0.0;
  static const double _grassCacheThreshold = 3.0;

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

    const step = 4.0;
    final stepsX = (size.width / step).ceil();
    final stepsY = (size.height / step).ceil();

    // Rebuild grass weight cache if player moved significantly or params changed
    final dx = playerX - _cachedGrassPlayerX;
    final dz = playerZ - _cachedGrassPlayerZ;
    final needsRebuild = _cachedGrassWeights == null ||
        dx * dx + dz * dz > _grassCacheThreshold * _grassCacheThreshold ||
        stepsX != _cachedGrassStepsX || stepsY != _cachedGrassStepsY ||
        isRotatingMode != _cachedGrassRotating ||
        (isRotatingMode && (playerRotation - _cachedGrassRotation).abs() > 5.0) ||
        viewRadius != _cachedGrassViewRadius;

    if (needsRebuild) {
      _cachedGrassPlayerX = playerX;
      _cachedGrassPlayerZ = playerZ;
      _cachedGrassStepsX = stepsX;
      _cachedGrassStepsY = stepsY;
      _cachedGrassRotating = isRotatingMode;
      _cachedGrassRotation = playerRotation;
      _cachedGrassViewRadius = viewRadius;

      final weights = List<double>.filled(stepsX * stepsY, 0.0);

      double cosR = 1.0, sinR = 0.0;
      if (isRotatingMode) {
        final rotRad = playerRotation * math.pi / 180.0;
        cosR = math.cos(rotRad);
        sinR = math.sin(rotRad);
      }

      for (int iy = 0; iy < stepsY; iy++) {
        final py = iy * step;
        for (int ix = 0; ix < stepsX; ix++) {
          final px = ix * step;
          final rdx2 = px - half;
          final rdy2 = py - half;
          if (rdx2 * rdx2 + rdy2 * rdy2 > half * half) continue;

          double worldX, worldZ;
          if (isRotatingMode) {
            final ndx = (px - half) / half;
            final ndy = -(py - half) / half;
            final rightComp = ndx * viewRadius;
            final fwdComp = ndy * viewRadius;
            worldX = playerX + rightComp * cosR - fwdComp * sinR;
            worldZ = playerZ - rightComp * sinR - fwdComp * cosR;
          } else {
            worldX = playerX - ((px - half) / half) * viewRadius;
            worldZ = playerZ - ((py - half) / half) * viewRadius;
          }

          final height =
              gameState.infiniteTerrainManager!.getTerrainHeight(worldX, worldZ);
          final normalizedHeight = ((height + 10.0) / 40.0).clamp(0.0, 1.0);
          if (normalizedHeight > 0.15 && normalizedHeight < 0.65) {
            weights[iy * stepsX + ix] =
                1.0 - ((normalizedHeight - 0.4).abs() * 3.0).clamp(0.0, 1.0);
          }
        }
      }
      _cachedGrassWeights = weights;
    }

    // Draw from cached weights
    final weights = _cachedGrassWeights!;
    for (int iy = 0; iy < stepsY; iy++) {
      final py = iy * step;
      for (int ix = 0; ix < stepsX; ix++) {
        final w = weights[iy * stepsX + ix];
        if (w > 0.05) {
          _fillPaint.color = Color.fromRGBO(60, 200, 60, w * 0.18);
          canvas.drawRect(Rect.fromLTWH(ix * step, py, step, step), _fillPaint);
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
    _fillPaint.color = Color.fromRGBO(80, 255, 80, alpha);
    canvas.drawCircle(center, pixelRadius, _fillPaint);

    // Pulsing ring border
    _strokePaint
      ..color = Color.fromRGBO(100, 255, 100, 0.3 + pulse * 0.2)
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, pixelRadius * (0.9 + pulse * 0.1), _strokePaint);

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
        _fillPaint.color = const Color.fromRGBO(60, 200, 60, 0.15);
        canvas.drawCircle(pos, pixelRadius, _fillPaint);
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
      _fillPaint.color = Color.fromRGBO(40, 220, 40, 0.15 + pulse * 0.1);
      canvas.drawCircle(pos, glowRadius, _fillPaint);
      _strokePaint
        ..color = Color.fromRGBO(80, 255, 80, 0.4 + pulse * 0.3)
        ..strokeWidth = 1.5;
      canvas.drawCircle(pos, glowRadius, _strokePaint);

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

    _fillPaint.color = color;
    canvas.drawPath(path, _fillPaint);

    // Stem line
    _strokePaint
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(center.dx, center.dy - size * 0.3),
      Offset(center.dx, center.dy + size * 0.5),
      _strokePaint,
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
  bool shouldRepaint(MinimapGreenPainter oldDelegate) {
    // Reason: spirit auras and nature creature glows pulse via elapsedTime;
    // grass zones are static per player position. Skip when nothing changed.
    return elapsedTime != oldDelegate.elapsedTime ||
        oldDelegate.viewRadius != viewRadius ||
        oldDelegate.playerRotation != playerRotation ||
        oldDelegate.gameState.playerTransform?.position.x !=
            gameState.playerTransform?.position.x ||
        oldDelegate.gameState.playerTransform?.position.z !=
            gameState.playerTransform?.position.z ||
        oldDelegate.gameState.playerInSpiritForm != gameState.playerInSpiritForm;
  }
}
