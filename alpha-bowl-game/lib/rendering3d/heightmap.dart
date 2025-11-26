import 'dart:math' as math;

/// Heightmap - 2D grid of elevation values for terrain
///
/// Provides height queries with bilinear interpolation for smooth terrain collision.
class Heightmap {
  final int width;
  final int height;
  final List<List<double>> _heights;
  final double tileSize;
  final double maxHeight;

  Heightmap({
    required this.width,
    required this.height,
    required this.tileSize,
    this.maxHeight = 10.0,
  }) : _heights = List.generate(
          height,
          (_) => List.filled(width, 0.0),
        );

  /// Get height at specific grid coordinates (no interpolation)
  double getHeightAt(int x, int z) {
    if (x < 0 || x >= width || z < 0 || z >= height) {
      return 0.0;
    }
    return _heights[z][x];
  }

  /// Set height at specific grid coordinates
  void setHeightAt(int x, int z, double value) {
    if (x >= 0 && x < width && z >= 0 && z < height) {
      _heights[z][x] = value;
    }
  }

  /// Get interpolated terrain height at world position
  ///
  /// Uses bilinear interpolation for smooth height values between grid points.
  /// This is the primary function for terrain collision detection.
  ///
  /// Parameters:
  /// - worldX: X coordinate in world space
  /// - worldZ: Z coordinate in world space
  ///
  /// Returns: Interpolated height at the given position
  double getTerrainHeight(double worldX, double worldZ) {
    // Convert world position to grid coordinates
    // Account for terrain being centered around origin
    final gridX = (worldX / tileSize) + (this.width - 1) / 2.0;
    final gridZ = (worldZ / tileSize) + (this.height - 1) / 2.0;

    // Get integer grid indices
    final x0 = gridX.floor();
    final z0 = gridZ.floor();
    final x1 = x0 + 1;
    final z1 = z0 + 1;

    // Get fractional parts for interpolation
    final fx = gridX - x0;
    final fz = gridZ - z0;

    // Sample the four surrounding heights
    final h00 = getHeightAt(x0, z0);
    final h10 = getHeightAt(x1, z0);
    final h01 = getHeightAt(x0, z1);
    final h11 = getHeightAt(x1, z1);

    // Bilinear interpolation
    // Interpolate along X axis
    final h0 = h00 * (1 - fx) + h10 * fx;
    final h1 = h01 * (1 - fx) + h11 * fx;

    // Interpolate along Z axis
    final terrainHeight = h0 * (1 - fz) + h1 * fz;

    return terrainHeight;
  }

  /// Generate flat terrain (all heights = 0)
  void generateFlat() {
    for (int z = 0; z < height; z++) {
      for (int x = 0; x < width; x++) {
        _heights[z][x] = 0.0;
      }
    }
  }

  /// Generate terrain using Perlin noise
  ///
  /// Creates organic, natural-looking terrain with multiple octaves for detail.
  ///
  /// Parameters:
  /// - seed: Random seed for deterministic generation
  /// - scale: Controls frequency of noise (lower = larger features)
  /// - octaves: Number of noise layers (more = more detail)
  /// - persistence: How much each octave contributes (0.0 to 1.0)
  void generatePerlinNoise({
    int seed = 12345,
    double scale = 0.05,
    int octaves = 4,
    double persistence = 0.5,
  }) {
    final noise = SimplexNoise(seed: seed);

    for (int z = 0; z < height; z++) {
      for (int x = 0; x < width; x++) {
        double amplitude = 1.0;
        double frequency = scale;
        double noiseValue = 0.0;
        double maxValue = 0.0;

        // Generate multiple octaves
        for (int i = 0; i < octaves; i++) {
          final sampleX = x * frequency;
          final sampleZ = z * frequency;

          final noise2D = noise.noise2D(sampleX, sampleZ);
          noiseValue += noise2D * amplitude;
          maxValue += amplitude;

          amplitude *= persistence;
          frequency *= 2.0;
        }

        // Normalize to [0, 1] then scale to max height
        noiseValue = (noiseValue / maxValue + 1.0) / 2.0;
        _heights[z][x] = noiseValue * maxHeight;
      }
    }
  }

  /// Generate simple hills with sine waves
  void generateHills() {
    for (int z = 0; z < height; z++) {
      for (int x = 0; x < width; x++) {
        final dx = (x - width / 2) / width;
        final dz = (z - height / 2) / height;

        // Multiple sine waves for variety
        final h = (math.sin(dx * math.pi * 4) * 0.3 +
                math.sin(dz * math.pi * 3) * 0.3 +
                math.sin((dx + dz) * math.pi * 5) * 0.2) *
            maxHeight;

        _heights[z][x] = h + maxHeight * 0.5; // Offset to keep positive
      }
    }
  }

  /// Get all heights as a flat list (for rendering)
  List<double> getFlatHeights() {
    final result = <double>[];
    for (int z = 0; z < height; z++) {
      for (int x = 0; x < width; x++) {
        result.add(_heights[z][x]);
      }
    }
    return result;
  }

  /// Get min and max heights for debugging
  ({double min, double max}) getHeightRange() {
    double min = double.infinity;
    double max = double.negativeInfinity;

    for (int z = 0; z < height; z++) {
      for (int x = 0; x < width; x++) {
        final h = _heights[z][x];
        if (h < min) min = h;
        if (h > max) max = h;
      }
    }

    return (min: min, max: max);
  }
}

/// Simple 2D Simplex/Perlin-like noise implementation
///
/// Based on Ken Perlin's improved noise algorithm.
/// Provides smooth, continuous noise values for terrain generation.
class SimplexNoise {
  final int seed;
  late List<int> _perm;
  late List<int> _permMod12;

  // Gradient vectors for 2D noise
  static const _grad3 = [
    [1, 1],
    [-1, 1],
    [1, -1],
    [-1, -1],
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ];

  SimplexNoise({this.seed = 0}) {
    _initializePermutation();
  }

  void _initializePermutation() {
    final random = math.Random(seed);

    // Create permutation table
    final p = List.generate(256, (i) => i);
    // Fisher-Yates shuffle with seed
    for (int i = 255; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = p[i];
      p[i] = p[j];
      p[j] = temp;
    }

    // Duplicate for overflow
    _perm = List.generate(512, (i) => p[i % 256]);
    _permMod12 = List.generate(512, (i) => _perm[i] % 12);
  }

  /// Generate 2D noise value at given coordinates
  ///
  /// Returns value in range [-1, 1]
  double noise2D(double x, double y) {
    // Skew the input space to determine which simplex cell we're in
    final F2 = 0.5 * (math.sqrt(3) - 1.0);
    final s = (x + y) * F2;
    final i = (x + s).floor();
    final j = (y + s).floor();

    final G2 = (3.0 - math.sqrt(3)) / 6.0;
    final t = (i + j) * G2;
    final X0 = i - t;
    final Y0 = j - t;
    final x0 = x - X0;
    final y0 = y - Y0;

    // Determine which simplex we are in
    int i1, j1;
    if (x0 > y0) {
      i1 = 1;
      j1 = 0;
    } else {
      i1 = 0;
      j1 = 1;
    }

    final x1 = x0 - i1 + G2;
    final y1 = y0 - j1 + G2;
    final x2 = x0 - 1.0 + 2.0 * G2;
    final y2 = y0 - 1.0 + 2.0 * G2;

    // Work out the hashed gradient indices
    final ii = i & 255;
    final jj = j & 255;
    final gi0 = _permMod12[ii + _perm[jj]] % 8;
    final gi1 = _permMod12[ii + i1 + _perm[jj + j1]] % 8;
    final gi2 = _permMod12[ii + 1 + _perm[jj + 1]] % 8;

    // Calculate contribution from corners
    double n0, n1, n2;

    double t0 = 0.5 - x0 * x0 - y0 * y0;
    if (t0 < 0) {
      n0 = 0.0;
    } else {
      t0 *= t0;
      n0 = t0 * t0 * _dot(_grad3[gi0], x0, y0);
    }

    double t1 = 0.5 - x1 * x1 - y1 * y1;
    if (t1 < 0) {
      n1 = 0.0;
    } else {
      t1 *= t1;
      n1 = t1 * t1 * _dot(_grad3[gi1], x1, y1);
    }

    double t2 = 0.5 - x2 * x2 - y2 * y2;
    if (t2 < 0) {
      n2 = 0.0;
    } else {
      t2 *= t2;
      n2 = t2 * t2 * _dot(_grad3[gi2], x2, y2);
    }

    // Add contributions and scale to [-1, 1]
    return 70.0 * (n0 + n1 + n2);
  }

  double _dot(List<int> g, double x, double y) {
    return g[0] * x + g[1] * y;
  }
}
