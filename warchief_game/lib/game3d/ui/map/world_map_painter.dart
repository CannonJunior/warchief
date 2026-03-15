import 'package:flutter/material.dart';
import '../../../rendering3d/infinite_terrain_manager.dart';
import '../../../rendering3d/game_config_terrain.dart';
import '../../../rendering3d/heightmap.dart';
import '../../state/map_state.dart';

/// [CustomPainter] that renders a large-scale world terrain map.
///
/// Samples [InfiniteTerrainManager.getTerrainHeight] on a grid scaled to
/// the current zoom level. Falls back to [SimplexNoise] for unloaded chunks.
/// Uses a static cache keyed on zoom/pan/chunk-count — rebuilds only when
/// those change.
class WorldMapPainter extends CustomPainter {
  final double playerX;
  final double playerZ;
  final InfiniteTerrainManager? terrainManager;
  final MapState mapState;

  WorldMapPainter({
    required this.playerX,
    required this.playerZ,
    required this.terrainManager,
    required this.mapState,
  });

  // ==================== STATIC CACHE ====================

  static List<Color>? _cache;
  static int    _cacheRes     = 0;
  static double _cacheCX      = double.nan;
  static double _cacheCZ      = double.nan;
  static double _cacheR       = 0;
  static int    _cacheChunks  = -1;
  static int    _cacheSeed    = -1;

  static SimplexNoise? _noise;
  static int           _noiseSeed = -1;

  static SimplexNoise _getOrCreateNoise(int seed) {
    if (_noise == null || _noiseSeed != seed) {
      _noise     = SimplexNoise(seed: seed);
      _noiseSeed = seed;
    }
    return _noise!;
  }

  // ==================== PAINT ====================

  @override
  void paint(Canvas canvas, Size size) {
    final res  = mapState.resolution;
    final r    = mapState.viewRadius;
    final cx   = playerX + mapState.panX;
    final cz   = playerZ + mapState.panZ;
    final seed = terrainManager?.seed ?? TerrainConfig.seed;
    final chunks = terrainManager?.loadedChunkCount ?? 0;

    final needsRebuild = _cache == null ||
        _cacheRes    != res   ||
        _cacheR      != r     ||
        _cacheCX     != cx    ||
        _cacheCZ     != cz    ||
        _cacheChunks != chunks ||
        _cacheSeed   != seed  ||
        mapState.terrainDirty;

    if (needsRebuild) {
      _rebuildCache(res, r, cx, cz, seed, chunks);
      mapState.terrainDirty = false;
    }

    _drawTerrain(canvas, size, res);
    _drawPlayerDot(canvas, size, r, cx, cz);
  }

  void _rebuildCache(int res, double r, double cx, double cz, int seed, int chunks) {
    final step = (2.0 * r) / res;
    final colors = List<Color>.filled(res * res, Colors.transparent);

    for (int py = 0; py < res; py++) {
      for (int px = 0; px < res; px++) {
        final wx = cx - r + (px + 0.5) * step;
        final wz = cz - r + (py + 0.5) * step;

        final h = terrainManager != null
            ? terrainManager!.getTerrainHeight(wx, wz)
            : _fallbackHeight(wx, wz, seed);

        colors[py * res + px] = _heightToColor(h);
      }
    }

    _cache       = colors;
    _cacheRes    = res;
    _cacheR      = r;
    _cacheCX     = cx;
    _cacheCZ     = cz;
    _cacheChunks = chunks;
    _cacheSeed   = seed;
  }

  void _drawTerrain(Canvas canvas, Size size, int res) {
    if (_cache == null) return;
    final pixSize = size.width / res;
    final paint   = Paint()..style = PaintingStyle.fill;
    for (int py = 0; py < res; py++) {
      for (int px = 0; px < res; px++) {
        paint.color = _cache![py * res + px];
        canvas.drawRect(
          Rect.fromLTWH(px * pixSize, py * pixSize, pixSize + 0.5, pixSize + 0.5),
          paint,
        );
      }
    }
  }

  void _drawPlayerDot(Canvas canvas, Size size, double r, double cx, double cz) {
    // Map player world pos to canvas pixel pos
    final sx = (playerX - (cx - r)) / (2 * r) * size.width;
    final sy = (playerZ - (cz - r)) / (2 * r) * size.height;

    final paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sx, sy), 5.0, paint);

    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(sx, sy), 5.0, border);
  }

  // ==================== COLOUR MAPPING ====================

  static double _fallbackHeight(double wx, double wz, int seed) {
    final noise = _getOrCreateNoise(seed);
    final scale = TerrainConfig.noiseScale;
    double amp = 1.0, freq = scale, val = 0.0, maxV = 0.0;
    for (int o = 0; o < TerrainConfig.noiseOctaves; o++) {
      val  += noise.noise2D(wx * freq, wz * freq) * amp;
      maxV += amp;
      amp  *= TerrainConfig.noisePersistence;
      freq *= 2.0;
    }
    return ((val / maxV + 1.0) / 2.0) * TerrainConfig.maxHeight;
  }

  static Color _heightToColor(double h) {
    final maxH = TerrainConfig.maxHeight.toDouble();
    final t = (h / maxH).clamp(0.0, 1.0);

    // Sand → grass → rock → snow gradient matching minimap
    if (t < 0.15) return Color.fromRGBO(194, 178, 128, 1); // sand
    if (t < 0.50) {
      final s = ((t - 0.15) / 0.35).clamp(0.0, 1.0);
      return Color.fromRGBO(
        (50  + s * 20).round(),
        (120 - s * 30).round(),
        (30  + s * 10).round(), 1);
    }
    if (t < 0.80) {
      final s = ((t - 0.50) / 0.30).clamp(0.0, 1.0);
      return Color.fromRGBO(
        (70  + s * 60).round(),
        (90  - s * 30).round(),
        (50  + s * 20).round(), 1);
    }
    return const Color.fromRGBO(220, 220, 225, 1); // snow
  }

  @override
  bool shouldRepaint(WorldMapPainter old) =>
      old.playerX    != playerX    ||
      old.playerZ    != playerZ    ||
      old.mapState   != mapState   ||
      mapState.terrainDirty;
}
