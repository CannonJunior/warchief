import 'dart:typed_data';
import 'dart:math' as math;
import 'heightmap.dart';
import 'game_config_terrain.dart';

/// SplatMapGenerator - Procedurally generates terrain type distribution
///
/// Creates splat maps that control how terrain textures are blended:
/// - R channel: Grass weight
/// - G channel: Dirt weight
/// - B channel: Rock weight
/// - A channel: Sand weight
///
/// Terrain distribution is based on:
/// - Height (low=sand, mid=grass, high=rock)
/// - Slope (steep=rock, flat=grass/dirt)
/// - Noise layers for natural variation
///
/// Usage:
/// ```dart
/// final splatData = SplatMapGenerator.generateSplatMap(
///   heightmap: heightmap,
///   resolution: 16,
///   maxHeight: 3.0,
/// );
/// ```
class SplatMapGenerator {
  SplatMapGenerator._(); // Prevent instantiation

  /// Generate a splat map for terrain chunk
  ///
  /// Parameters:
  /// - heightmap: Source heightmap for height/slope data
  /// - resolution: Output resolution (width = height = resolution)
  /// - maxHeight: Maximum terrain height for normalization
  /// - seed: Random seed for variation noise
  ///
  /// Returns: Float32List with RGBA values (4 floats per pixel, 0.0-1.0 range)
  static Float32List generateSplatMap({
    required Heightmap heightmap,
    required int resolution,
    required double maxHeight,
    int seed = 0,
  }) {
    final splatData = Float32List(resolution * resolution * 4);

    // Generate variation noise for more natural distribution
    final variationNoise = _generateVariationNoise(resolution, seed);

    for (int y = 0; y < resolution; y++) {
      for (int x = 0; x < resolution; x++) {
        final idx = (y * resolution + x) * 4;

        // Map splat map coordinates to heightmap coordinates
        final hx = (x / resolution * heightmap.width).floor().clamp(0, heightmap.width - 1);
        final hy = (y / resolution * heightmap.height).floor().clamp(0, heightmap.height - 1);

        // Get height and slope at this position
        final height = heightmap.getHeightAt(hx, hy);
        final normalizedHeight = height / maxHeight;
        final slope = _calculateSlope(heightmap, hx, hy);

        // Get variation noise at this position
        final variation = variationNoise[y * resolution + x];

        // Calculate terrain weights
        final weights = _calculateTerrainWeights(
          normalizedHeight: normalizedHeight,
          slope: slope,
          variation: variation,
        );

        // Store weights in splat map (RGBA = grass, dirt, rock, sand)
        splatData[idx + 0] = weights.grass;
        splatData[idx + 1] = weights.dirt;
        splatData[idx + 2] = weights.rock;
        splatData[idx + 3] = weights.sand;
      }
    }

    return splatData;
  }

  /// Calculate terrain type weights based on height, slope, and variation
  static _TerrainWeights _calculateTerrainWeights({
    required double normalizedHeight,
    required double slope,
    required double variation,
  }) {
    double grass = 0.0;
    double dirt = 0.0;
    double rock = 0.0;
    double sand = 0.0;

    // Height-based distribution
    final sandThreshold = TerrainConfig.sandMaxHeight;
    final grassThreshold = TerrainConfig.grassMaxHeight;
    final rockSlopeThreshold = TerrainConfig.rockMinSlope;

    if (normalizedHeight < sandThreshold) {
      // Low areas: sand transitioning to grass
      sand = _smoothstep(0.0, sandThreshold, sandThreshold - normalizedHeight);
      grass = 1.0 - sand;
    } else if (normalizedHeight < grassThreshold) {
      // Mid areas: primarily grass with some dirt
      grass = 1.0;

      // Add dirt in flat areas with some variation
      if (slope > 0.9 && variation > 0.7) {
        final dirtAmount = (variation - 0.7) / 0.3 * 0.4;
        dirt = dirtAmount;
        grass = 1.0 - dirtAmount;
      }
    } else {
      // High areas: rock transitioning from grass
      rock = _smoothstep(grassThreshold, 1.0, normalizedHeight);
      grass = 1.0 - rock;
    }

    // Slope-based rock override
    // Steep slopes (low slope value) get more rock
    if (slope < rockSlopeThreshold) {
      final steepness = 1.0 - (slope / rockSlopeThreshold);
      final rockBoost = steepness * steepness; // Quadratic for steeper slopes

      // Blend in rock based on steepness
      final targetRock = math.max(rock, rockBoost);
      final blendFactor = rockBoost * 0.8; // How much to blend towards rock

      rock = rock + (targetRock - rock) * blendFactor;
      grass *= (1.0 - blendFactor * 0.6);
      sand *= (1.0 - blendFactor * 0.8);
      dirt *= (1.0 - blendFactor * 0.4);
    }

    // Add dirt transition zones between grass and rock
    if (grass > 0.2 && rock > 0.2) {
      final transitionStrength = math.min(grass, rock) * 2;
      dirt += transitionStrength * 0.3;
      grass *= (1.0 - transitionStrength * 0.15);
      rock *= (1.0 - transitionStrength * 0.15);
    }

    // Add variation-based dirt patches in grass areas
    if (grass > 0.5 && variation > 0.85) {
      final dirtPatch = (variation - 0.85) / 0.15 * 0.3;
      dirt += dirtPatch;
      grass -= dirtPatch;
    }

    // Normalize weights to sum to 1.0
    final total = grass + dirt + rock + sand;
    if (total > 0.0) {
      grass /= total;
      dirt /= total;
      rock /= total;
      sand /= total;
    } else {
      grass = 1.0; // Default to grass if something went wrong
    }

    return _TerrainWeights(grass: grass, dirt: dirt, rock: rock, sand: sand);
  }

  /// Calculate slope at a heightmap position
  ///
  /// Returns 1.0 for flat terrain, 0.0 for vertical cliffs
  static double _calculateSlope(Heightmap heightmap, int x, int y) {
    final width = heightmap.width;
    final height = heightmap.height;

    // Get neighboring heights
    final xLeft = (x - 1).clamp(0, width - 1);
    final xRight = (x + 1).clamp(0, width - 1);
    final yUp = (y - 1).clamp(0, height - 1);
    final yDown = (y + 1).clamp(0, height - 1);

    final heightLeft = heightmap.getHeightAt(xLeft, y);
    final heightRight = heightmap.getHeightAt(xRight, y);
    final heightUp = heightmap.getHeightAt(x, yUp);
    final heightDown = heightmap.getHeightAt(x, yDown);

    // Calculate gradient
    final dx = (xRight - xLeft) * heightmap.tileSize;
    final dy = (yDown - yUp) * heightmap.tileSize;

    double gradX = 0.0;
    double gradY = 0.0;

    if (dx > 0) {
      gradX = (heightRight - heightLeft) / dx;
    }
    if (dy > 0) {
      gradY = (heightDown - heightUp) / dy;
    }

    // Calculate slope from gradient
    // slope = cos(atan(gradientMagnitude)) = 1 / sqrt(1 + grad^2)
    final gradMagnitude = math.sqrt(gradX * gradX + gradY * gradY);
    return 1.0 / math.sqrt(1.0 + gradMagnitude * gradMagnitude);
  }

  /// Generate variation noise for natural-looking terrain distribution
  static List<double> _generateVariationNoise(int resolution, int seed) {
    final noise = List<double>.filled(resolution * resolution, 0.0);

    // Layer 1: Low frequency noise for large-scale variation
    for (int y = 0; y < resolution; y++) {
      for (int x = 0; x < resolution; x++) {
        final fx = x / resolution;
        final fy = y / resolution;

        // Simple value noise with interpolation
        final value = _valueNoise(fx * 4, fy * 4, seed);
        noise[y * resolution + x] = value;
      }
    }

    // Layer 2: Add higher frequency detail
    for (int y = 0; y < resolution; y++) {
      for (int x = 0; x < resolution; x++) {
        final fx = x / resolution;
        final fy = y / resolution;

        final detail = _valueNoise(fx * 8, fy * 8, seed + 1000) * 0.5;
        noise[y * resolution + x] = (noise[y * resolution + x] + detail) / 1.5;
      }
    }

    return noise;
  }

  /// Simple value noise for terrain variation
  static double _valueNoise(double x, double y, int seed) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;

    // Smoothstep interpolation
    final sx = fx * fx * (3 - 2 * fx);
    final sy = fy * fy * (3 - 2 * fy);

    // Get corner values
    final v00 = _hash(ix, iy, seed);
    final v10 = _hash(ix + 1, iy, seed);
    final v01 = _hash(ix, iy + 1, seed);
    final v11 = _hash(ix + 1, iy + 1, seed);

    // Bilinear interpolation
    final v0 = v00 + sx * (v10 - v00);
    final v1 = v01 + sx * (v11 - v01);
    return v0 + sy * (v1 - v0);
  }

  /// Hash function for random values at grid points
  static double _hash(int x, int y, int seed) {
    var n = x + y * 57 + seed * 131;
    n = (n << 13) ^ n;
    return ((n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) / 2147483648.0;
  }

  /// Smoothstep function for smooth transitions
  static double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// Debug: Get terrain type name from weights
  static String getTerrainTypeName(_TerrainWeights weights) {
    if (weights.sand > 0.5) return 'Sand';
    if (weights.rock > 0.5) return 'Rock';
    if (weights.dirt > 0.3) return 'Dirt';
    return 'Grass';
  }

  /// Debug: Visualize splat map as colored pixels
  static List<int> visualizeSplatMap(Float32List splatData, int resolution) {
    final pixels = List<int>.filled(resolution * resolution * 4, 0);

    for (int i = 0; i < resolution * resolution; i++) {
      final grass = splatData[i * 4 + 0];
      final dirt = splatData[i * 4 + 1];
      final rock = splatData[i * 4 + 2];
      final sand = splatData[i * 4 + 3];

      // Map to colors
      final r = ((grass * 80 + dirt * 130 + rock * 120 + sand * 210)).toInt().clamp(0, 255);
      final g = ((grass * 140 + dirt * 100 + rock * 115 + sand * 190)).toInt().clamp(0, 255);
      final b = ((grass * 50 + dirt * 70 + rock * 110 + sand * 140)).toInt().clamp(0, 255);

      pixels[i * 4 + 0] = r;
      pixels[i * 4 + 1] = g;
      pixels[i * 4 + 2] = b;
      pixels[i * 4 + 3] = 255;
    }

    return pixels;
  }
}

/// Internal class for terrain weights
class _TerrainWeights {
  final double grass;
  final double dirt;
  final double rock;
  final double sand;

  const _TerrainWeights({
    required this.grass,
    required this.dirt,
    required this.rock,
    required this.sand,
  });

  @override
  String toString() {
    return 'TerrainWeights(grass: ${grass.toStringAsFixed(2)}, dirt: ${dirt.toStringAsFixed(2)}, rock: ${rock.toStringAsFixed(2)}, sand: ${sand.toStringAsFixed(2)})';
  }
}
