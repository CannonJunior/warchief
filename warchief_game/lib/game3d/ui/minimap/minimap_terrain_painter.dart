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
  final bool showLeyLines;
  final double elapsedTime;

  MinimapTerrainPainter({
    required this.playerX,
    required this.playerZ,
    required this.playerRotation,
    required this.viewRadius,
    required this.terrainManager,
    required this.leyLineManager,
    required this.minimapState,
    this.showLeyLines = true,
    this.elapsedTime = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final config = globalMinimapConfig;
    final resolution = config?.cacheResolution ?? 128;

    if (terrainManager == null) return;

    // Draw terrain color grid
    _paintTerrain(canvas, size, resolution);

    // Draw ley lines on top (gated by blue attunement + toggle at widget level)
    if ((config?.showLeyLines ?? true) && showLeyLines) {
      _paintLeyLines(canvas, size);
    }
  }

  /// Cached terrain color grid to avoid recomputing on every paint call.
  /// Invalidated when player position, rotation, or zoom changes enough
  /// to trigger shouldRepaint.
  static List<Color>? _terrainColorCache;
  static int _cacheResolution = 0;
  static double _cachePlayerX = double.nan;
  static double _cachePlayerZ = double.nan;
  static double _cacheRotation = double.nan;
  static double _cacheViewRadius = 0;
  static bool _cacheIsRotating = false;
  static int _cacheChunkCount = -1;
  static int _cacheSeed = -1;

  /// Lazy-initialized noise generator for terrain beyond loaded chunks.
  /// Matches seed to the actual terrain manager to stay consistent.
  static SimplexNoise? _noiseCache;
  static int _noiseSeed = -1;

  static SimplexNoise _noise(int seed) {
    if (_noiseCache == null || _noiseSeed != seed) {
      _noiseCache = SimplexNoise(seed: seed);
      _noiseSeed = seed;
    }
    return _noiseCache!;
  }

  /// Generate terrain height directly from noise for unloaded chunks.
  /// Uses the terrain manager's actual noise parameters (not TerrainConfig statics)
  /// so the fallback matches the currently-selected terrain preset.
  static double _noiseHeight(
    double worldX,
    double worldZ,
    int seed,
    double scale,
    int octaves,
    double persistence,
    double maxH,
  ) {
    final noise = _noise(seed);
    double amplitude = 1.0;
    double frequency = scale;
    double noiseValue = 0.0;
    double maxValue = 0.0;

    for (int i = 0; i < octaves; i++) {
      noiseValue += noise.noise2D(worldX * frequency, worldZ * frequency) * amplitude;
      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= 2.0;
    }

    return ((noiseValue / maxValue + 1.0) / 2.0) * maxH;
  }

  /// Sample heightmap and paint terrain colors.
  /// Uses a static color cache so heights are only sampled when the
  /// player moves beyond the refresh threshold (same as shouldRepaint).
  void _paintTerrain(Canvas canvas, Size size, int resolution) {
    final isRotating = minimapState.isRotatingMode;

    final currentChunkCount = terrainManager?.loadedChunkCount ?? 0;
    final currentSeed = terrainManager?.seed ?? TerrainConfig.seed;

    // Distance from last cache-build center.
    final movedFromCache = _cachePlayerX.isNaN
        ? double.infinity
        : math.sqrt(math.pow(playerX - _cachePlayerX, 2) +
                    math.pow(playerZ - _cachePlayerZ, 2));
    final refreshThreshold = viewRadius *
        (globalMinimapConfig?.refreshThresholdFraction ?? 0.3);

    // Check if the cached color grid is still valid.
    // Reason: include player movement (vs cache center), chunk count, and seed
    // so the cache refreshes as the player walks, chunks stream in, and when
    // the terrain preset changes between sessions.
    final needsRebuild = _terrainColorCache == null ||
        _cacheResolution != resolution ||
        _cacheViewRadius != viewRadius ||
        _cacheIsRotating != isRotating ||
        playerRotation != _cacheRotation ||
        movedFromCache > refreshThreshold ||
        _cacheChunkCount != currentChunkCount ||
        _cacheSeed != currentSeed;

    if (needsRebuild) {
      _rebuildTerrainCache(size, resolution, isRotating);
    }

    // Draw cached colors
    final pixelSize = size.width / resolution;
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = _terrainColorCache!;

    for (int py = 0; py < resolution; py++) {
      for (int px = 0; px < resolution; px++) {
        final idx = py * resolution + px;
        final color = colors[idx];
        if (color.a == 0) continue; // Outside circular mask

        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(px * pixelSize, py * pixelSize, pixelSize + 0.5, pixelSize + 0.5),
          paint,
        );
      }
    }
  }

  /// Rebuild the terrain color cache by sampling heights.
  void _rebuildTerrainCache(Size size, int resolution, bool isRotating) {
    final config = globalMinimapConfig;
    final sandColor = _colorFromList(
        config?.sandColor ?? [0.76, 0.70, 0.50, 1.0]);
    final grassColor = _colorFromList(
        config?.grassColor ?? [0.29, 0.49, 0.25, 1.0]);
    final rockColor = _colorFromList(
        config?.rockColor ?? [0.42, 0.42, 0.42, 1.0]);
    final sandThresh = config?.sandThreshold ?? 0.15;
    final rockThresh = config?.rockThreshold ?? 0.70;

    // Reason: use terrain manager's actual params so minimap matches the
    // selected preset rather than TerrainConfig static defaults.
    final tm = terrainManager;
    final maxHeight = tm?.maxHeight ?? TerrainConfig.maxHeight;
    final noiseSeed = tm?.seed ?? TerrainConfig.seed;
    final noiseScale = tm?.noiseScale ?? TerrainConfig.noiseScale;
    final noiseOctaves = tm?.noiseOctaves ?? TerrainConfig.noiseOctaves;
    final noisePersistence = tm?.noisePersistence ?? TerrainConfig.noisePersistence;
    final half = size.width / 2;
    final pixelSize = size.width / resolution;
    final halfRadius = half;
    final groundLevel = GameConfig.groundLevel;
    final transparent = const Color(0x00000000);

    final rotRad = playerRotation * math.pi / 180.0;
    final cosR = math.cos(rotRad);
    final sinR = math.sin(rotRad);

    final totalPixels = resolution * resolution;
    if (_terrainColorCache == null || _terrainColorCache!.length != totalPixels) {
      _terrainColorCache = List<Color>.filled(totalPixels, transparent);
    }
    final colors = _terrainColorCache!;

    for (int py = 0; py < resolution; py++) {
      for (int px = 0; px < resolution; px++) {
        final idx = py * resolution + px;
        final cx = (px + 0.5) * pixelSize;
        final cy = (py + 0.5) * pixelSize;

        final dx = cx - half;
        final dy = cy - half;
        if (dx * dx + dy * dy > halfRadius * halfRadius) {
          colors[idx] = transparent;
          continue;
        }

        double worldX, worldZ;
        if (isRotating) {
          final ndx = dx / halfRadius;
          final ndy = -dy / halfRadius;
          final rightComp = ndx * viewRadius;
          final fwdComp = ndy * viewRadius;
          worldX = playerX + rightComp * cosR - fwdComp * sinR;
          worldZ = playerZ - rightComp * sinR - fwdComp * cosR;
        } else {
          worldX = playerX - (dx / halfRadius) * viewRadius;
          worldZ = playerZ - (dy / halfRadius) * viewRadius;
        }

        double height;
        if (tm != null) {
          height = tm.getTerrainHeight(worldX, worldZ);
          // Reason: getTerrainHeight returns groundLevel for unloaded chunks;
          // fall back to noise using the terrain manager's actual parameters.
          if (height == groundLevel) {
            height = _noiseHeight(worldX, worldZ, noiseSeed, noiseScale, noiseOctaves, noisePersistence, maxHeight);
          }
        } else {
          height = _noiseHeight(worldX, worldZ, noiseSeed, noiseScale, noiseOctaves, noisePersistence, maxHeight);
        }
        final normalizedHeight = (height / maxHeight).clamp(0.0, 1.0);

        Color color;
        if (normalizedHeight < sandThresh) {
          color = sandColor;
        } else if (normalizedHeight > rockThresh) {
          color = rockColor;
        } else {
          final grassRange = rockThresh - sandThresh;
          final grassT = (normalizedHeight - sandThresh) / grassRange;
          if (grassT < 0.5) {
            color = Color.lerp(sandColor, grassColor, grassT * 2)!;
          } else {
            color = Color.lerp(grassColor, rockColor, (grassT - 0.5) * 2)!;
          }
        }
        colors[idx] = color;
      }
    }

    // Update cache metadata
    _cacheResolution = resolution;
    _cachePlayerX = playerX;
    _cachePlayerZ = playerZ;
    _cacheRotation = playerRotation;
    _cacheViewRadius = viewRadius;
    _cacheIsRotating = isRotating;
    _cacheChunkCount = terrainManager?.loadedChunkCount ?? 0;
    _cacheSeed = terrainManager?.seed ?? TerrainConfig.seed;
  }

  /// Draw ley line segments and power nodes within view.
  ///
  /// Reason: thicker lines (2.5x base) with a soft glow underneath make ley
  /// lines readable at all zoom levels. Power nodes get a pulsing outer ring
  /// plus a bright core diamond to stand out from terrain.
  void _paintLeyLines(Canvas canvas, Size size) {
    if (leyLineManager == null) return;

    final config = globalMinimapConfig;
    final lineColor = _colorFromList(
        config?.leyLineColor ?? [0.27, 0.53, 0.80, 0.6]);
    final nodeColor = _colorFromList(
        config?.powerNodeColor ?? [0.40, 0.27, 0.80, 0.8]);
    final baseLineWidth = config?.leyLineWidth ?? 1.0;
    final nodeRadius = config?.nodeRadius ?? 3.0;
    final pulse = math.sin(elapsedTime * 2.0) * 0.5 + 0.5;

    // Reason: 2.5x multiplier gives visible lines without obscuring terrain
    final lineWidth = baseLineWidth * 2.5;

    final half = size.width / 2;

    final segments = leyLineManager!.getVisibleSegments(
        playerX, playerZ, viewRadius);

    // Soft glow layer underneath the lines
    final glowLinePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.15 + pulse * 0.1)
      ..strokeWidth = lineWidth * 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final seg in segments) {
      final p1 = _worldToMinimap(seg.x1, seg.z1, half);
      final p2 = _worldToMinimap(seg.x2, seg.z2, half);
      if (p1 != null || p2 != null) {
        canvas.drawLine(p1 ?? p2!, p2 ?? p1!, glowLinePaint);
      }
    }

    // Core ley line segments
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final seg in segments) {
      final p1 = _worldToMinimap(seg.x1, seg.z1, half);
      final p2 = _worldToMinimap(seg.x2, seg.z2, half);
      if (p1 != null || p2 != null) {
        canvas.drawLine(p1 ?? p2!, p2 ?? p1!, linePaint);
      }
    }

    // Draw power nodes with prominent pulsing effect
    for (final node in leyLineManager!.powerNodes) {
      final pos = _worldToMinimap(node.x, node.z, half);
      if (pos != null) {
        // Outer glow ring (pulsing)
        final outerGlowRadius = nodeRadius * 2.5 + pulse * 2.0;
        canvas.drawCircle(
          pos,
          outerGlowRadius,
          Paint()
            ..color = nodeColor.withValues(alpha: 0.12 + pulse * 0.08)
            ..style = PaintingStyle.fill,
        );

        // Pulsing ring border
        canvas.drawCircle(
          pos,
          nodeRadius * 2.0 + pulse * 1.5,
          Paint()
            ..color = nodeColor.withValues(alpha: 0.3 + pulse * 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // Solid core circle
        canvas.drawCircle(
          pos,
          nodeRadius * 1.2,
          Paint()
            ..color = nodeColor
            ..style = PaintingStyle.fill,
        );

        // Bright center highlight
        canvas.drawCircle(
          pos,
          nodeRadius * 0.5,
          Paint()
            ..color = Color.fromRGBO(180, 160, 255, 0.9)
            ..style = PaintingStyle.fill,
        );
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
    // Repaint when player moves significantly, rotates, zoom changes, ley lines
    // toggle, the terrain seed changes (new preset), or new chunks have loaded.
    // Reason: chunk count check ensures terrain updates stream onto the minimap
    // as the infinite terrain manager loads new chunks — same approach used for
    // ley line mesh cache invalidation in render_system.dart.
    final chunkCount = terrainManager?.loadedChunkCount ?? 0;
    final oldChunkCount = oldDelegate.terrainManager?.loadedChunkCount ?? 0;
    if (chunkCount != oldChunkCount) return true;

    final seed = terrainManager?.seed ?? TerrainConfig.seed;
    final oldSeed = oldDelegate.terrainManager?.seed ?? TerrainConfig.seed;
    if (seed != oldSeed) return true;

    final dx = playerX - oldDelegate.playerX;
    final dz = playerZ - oldDelegate.playerZ;
    final moved = math.sqrt(dx * dx + dz * dz);
    final threshold = viewRadius *
        (globalMinimapConfig?.refreshThresholdFraction ?? 0.3);
    return moved > threshold ||
        playerRotation != oldDelegate.playerRotation ||
        viewRadius != oldDelegate.viewRadius ||
        showLeyLines != oldDelegate.showLeyLines;
  }
}
