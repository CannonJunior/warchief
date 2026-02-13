import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../rendering3d/infinite_terrain_manager.dart';
import '../../../rendering3d/ley_lines.dart';
import '../../../rendering3d/game_config_terrain.dart';
import '../../../rendering3d/heightmap.dart';
import '../../state/game_config.dart';
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
  final double playerRotation;
  final double viewRadius;
  final InfiniteTerrainManager? terrainManager;
  final LeyLineManager? leyLineManager;
  final MinimapState minimapState;

  MinimapTerrainPainter({
    required this.playerX,
    required this.playerZ,
    required this.playerRotation,
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

  /// Lazy-initialized noise generator for terrain beyond loaded chunks.
  /// Uses same seed and parameters as the infinite terrain manager.
  static SimplexNoise? _noiseCache;
  static SimplexNoise get _noise {
    _noiseCache ??= SimplexNoise(seed: TerrainConfig.seed);
    return _noiseCache!;
  }

  /// Generate terrain height directly from noise for unloaded chunks.
  /// Matches the algorithm in TerrainChunkWithLOD._generateChunkPerlinNoise.
  static double _noiseHeight(double worldX, double worldZ) {
    final scale = TerrainConfig.noiseScale;
    final octaves = TerrainConfig.noiseOctaves;
    final persistence = TerrainConfig.noisePersistence;
    final maxH = TerrainConfig.maxHeight;

    double amplitude = 1.0;
    double frequency = scale;
    double noiseValue = 0.0;
    double maxValue = 0.0;

    for (int i = 0; i < octaves; i++) {
      noiseValue += _noise.noise2D(worldX * frequency, worldZ * frequency) * amplitude;
      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= 2.0;
    }

    return ((noiseValue / maxValue + 1.0) / 2.0) * maxH;
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
    final groundLevel = GameConfig.groundLevel;

    final paint = Paint()..style = PaintingStyle.fill;
    final isRotating = minimapState.isRotatingMode;

    // Pre-compute rotation for player-relative minimap (forward = up)
    final rotRad = playerRotation * math.pi / 180.0;
    final cosR = math.cos(rotRad);
    final sinR = math.sin(rotRad);

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
        double worldX, worldZ;
        if (isRotating) {
          // Rotating minimap: up = forward direction
          final ndx = dx / halfRadius;
          final ndy = -dy / halfRadius;
          final rightComp = ndx * viewRadius;
          final fwdComp = ndy * viewRadius;
          worldX = playerX + rightComp * cosR - fwdComp * sinR;
          worldZ = playerZ - rightComp * sinR - fwdComp * cosR;
        } else {
          // Fixed-north with X negated to match screen-relative left/right
          worldX = playerX - (dx / halfRadius) * viewRadius;
          worldZ = playerZ - (dy / halfRadius) * viewRadius;
        }

        // Sample terrain height from loaded chunks, fall back to direct
        // noise when the chunk isn't loaded (zoomed out beyond render distance)
        double height;
        if (terrainManager != null) {
          height = terrainManager!.getTerrainHeight(worldX, worldZ);
          if (height == groundLevel) {
            // Chunk not loaded — use noise directly
            height = _noiseHeight(worldX, worldZ);
          }
        } else {
          height = _noiseHeight(worldX, worldZ);
        }
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
            color = Color.lerp(sandColor, grassColor, grassT * 2)!;
          } else {
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

    double mx, my;
    if (minimapState.isRotatingMode) {
      // Rotate into player-relative frame (forward = up)
      final rotRad = playerRotation * math.pi / 180.0;
      final cosR = math.cos(rotRad);
      final sinR = math.sin(rotRad);
      final rightComp = dx * cosR - dz * sinR;
      final fwdComp = -dx * sinR - dz * cosR;
      mx = half + (rightComp / viewRadius) * half;
      my = half - (fwdComp / viewRadius) * half;
    } else {
      // Fixed-north with X negated to match screen-relative left/right
      mx = half - (dx / viewRadius) * half;
      my = half - (dz / viewRadius) * half;
    }

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
    // Repaint when player moves significantly, rotates, or zoom changes
    final dx = playerX - oldDelegate.playerX;
    final dz = playerZ - oldDelegate.playerZ;
    final moved = math.sqrt(dx * dx + dz * dz);
    final threshold = viewRadius *
        (globalMinimapConfig?.refreshThresholdFraction ?? 0.3);
    return moved > threshold ||
        playerRotation != oldDelegate.playerRotation ||
        viewRadius != oldDelegate.viewRadius;
  }
}
