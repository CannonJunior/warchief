import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../rendering3d/infinite_terrain_manager.dart';
import '../../../rendering3d/ley_lines.dart';
import '../../../rendering3d/game_config_terrain.dart';
import '../../state/minimap_config.dart';
import '../../state/minimap_state.dart';

/// CustomPainter that renders a top-down terrain color map on the minimap.
///
/// Samples the heightmap at regular intervals and maps height to color:
/// sand (low), grass (mid), rock (high). Also draws ley line segments
/// and power nodes within the visible area.
///
/// Uses a cache: regenerates only when the player moves more than
/// [refreshThresholdFraction] * viewRadius from the cache center.
class MinimapTerrainPainter extends CustomPainter {
  final double playerX;
  final double playerZ;
  final double viewRadius;
  final InfiniteTerrainManager? terrainManager;
  final LeyLineManager? leyLineManager;
  final MinimapState minimapState;

  MinimapTerrainPainter({
    required this.playerX,
    required this.playerZ,
    required this.viewRadius,
    required this.terrainManager,
    required this.leyLineManager,
    required this.minimapState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final config = globalMinimapConfig;
    final resolution = config?.cacheResolution ?? 128;

    if (terrainManager == null) return;

    // Draw terrain color grid
    _paintTerrain(canvas, size, resolution);

    // Draw ley lines on top
    if (config?.showLeyLines ?? true) {
      _paintLeyLines(canvas, size);
    }
  }

  /// Sample heightmap and paint terrain colors.
  void _paintTerrain(Canvas canvas, Size size, int resolution) {
    final config = globalMinimapConfig;
    final sandColor = _colorFromList(
        config?.sandColor ?? [0.76, 0.70, 0.50, 1.0]);
    final grassColor = _colorFromList(
        config?.grassColor ?? [0.29, 0.49, 0.25, 1.0]);
    final rockColor = _colorFromList(
        config?.rockColor ?? [0.42, 0.42, 0.42, 1.0]);
    final sandThresh = config?.sandThreshold ?? 0.15;
    final rockThresh = config?.rockThreshold ?? 0.70;

    final maxHeight = TerrainConfig.maxHeight;
    final half = size.width / 2;
    final pixelSize = size.width / resolution;
    final halfRadius = half;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int py = 0; py < resolution; py++) {
      for (int px = 0; px < resolution; px++) {
        // Pixel center in minimap space
        final cx = (px + 0.5) * pixelSize;
        final cy = (py + 0.5) * pixelSize;

        // Check if within circular mask
        final dx = cx - half;
        final dy = cy - half;
        if (dx * dx + dy * dy > halfRadius * halfRadius) continue;

        // Convert to world coordinates
        final worldX = playerX + (dx / halfRadius) * viewRadius;
        final worldZ = playerZ - (dy / halfRadius) * viewRadius;

        // Sample terrain height
        final height = terrainManager!.getTerrainHeight(worldX, worldZ);
        final normalizedHeight = (height / maxHeight).clamp(0.0, 1.0);

        // Map height to color
        Color color;
        if (normalizedHeight < sandThresh) {
          color = sandColor;
        } else if (normalizedHeight > rockThresh) {
          color = rockColor;
        } else {
          // Interpolate between sand→grass→rock
          final grassRange = rockThresh - sandThresh;
          final grassT = (normalizedHeight - sandThresh) / grassRange;
          if (grassT < 0.5) {
            // Sand to grass transition
            color = Color.lerp(sandColor, grassColor, grassT * 2)!;
          } else {
            // Grass to rock transition
            color = Color.lerp(grassColor, rockColor, (grassT - 0.5) * 2)!;
          }
        }

        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(px * pixelSize, py * pixelSize, pixelSize + 0.5, pixelSize + 0.5),
          paint,
        );
      }
    }
  }

  /// Draw ley line segments and power nodes within view.
  void _paintLeyLines(Canvas canvas, Size size) {
    if (leyLineManager == null) return;

    final config = globalMinimapConfig;
    final lineColor = _colorFromList(
        config?.leyLineColor ?? [0.27, 0.53, 0.80, 0.6]);
    final nodeColor = _colorFromList(
        config?.powerNodeColor ?? [0.40, 0.27, 0.80, 0.8]);
    final lineWidth = config?.leyLineWidth ?? 1.0;
    final nodeRadius = config?.nodeRadius ?? 3.0;

    final half = size.width / 2;

    // Draw ley line segments
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    final segments = leyLineManager!.getVisibleSegments(
        playerX, playerZ, viewRadius);
    for (final seg in segments) {
      final p1 = _worldToMinimap(seg.x1, seg.z1, half);
      final p2 = _worldToMinimap(seg.x2, seg.z2, half);
      if (p1 != null || p2 != null) {
        canvas.drawLine(
          p1 ?? p2!,
          p2 ?? p1!,
          linePaint,
        );
      }
    }

    // Draw power nodes
    final nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;

    for (final node in leyLineManager!.powerNodes) {
      final pos = _worldToMinimap(node.x, node.z, half);
      if (pos != null) {
        // Glow effect
        final glowPaint = Paint()
          ..color = nodeColor.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, nodeRadius * 1.5, glowPaint);
        canvas.drawCircle(pos, nodeRadius, nodePaint);
      }
    }
  }

  /// Convert world coordinates to minimap pixel position.
  /// Returns null if outside the circular view.
  Offset? _worldToMinimap(double worldX, double worldZ, double half) {
    final dx = worldX - playerX;
    final dz = worldZ - playerZ;

    final mx = half + (dx / viewRadius) * half;
    final my = half - (dz / viewRadius) * half;

    // Check within circular bounds (with small margin for lines)
    final rdx = mx - half;
    final rdy = my - half;
    if (rdx * rdx + rdy * rdy > (half + 5) * (half + 5)) return null;

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
  bool shouldRepaint(MinimapTerrainPainter oldDelegate) {
    // Repaint when player moves significantly or zoom changes
    final dx = playerX - oldDelegate.playerX;
    final dz = playerZ - oldDelegate.playerZ;
    final moved = math.sqrt(dx * dx + dz * dz);
    final threshold = viewRadius *
        (globalMinimapConfig?.refreshThresholdFraction ?? 0.3);
    return moved > threshold ||
        viewRadius != oldDelegate.viewRadius;
  }
}
