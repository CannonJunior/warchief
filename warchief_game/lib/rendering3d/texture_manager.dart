import 'dart:typed_data';
import 'dart:math' as math;

/// TextureManager - Manages terrain texture loading and procedural generation
///
/// Creates and caches terrain textures for the splatting system:
/// - Procedurally generates tileable terrain textures (grass, dirt, rock, sand)
/// - Manages WebGL texture objects
/// - Handles texture binding and unit assignment
///
/// Usage:
/// ```dart
/// final textureManager = TextureManager(gl);
/// await textureManager.initialize();
/// textureManager.bindTerrainTextures();
/// ```
class TextureManager {
  final dynamic gl; // WebGL RenderingContext

  /// Terrain diffuse textures (indexed by TerrainTextureType)
  final Map<TerrainTextureType, dynamic> _diffuseTextures = {};

  /// Terrain normal textures (indexed by TerrainTextureType)
  final Map<TerrainTextureType, dynamic> _normalTextures = {};

  /// Detail texture for close-up variation
  dynamic _detailTexture;

  /// Texture resolution for procedural textures
  final int textureSize;

  /// Whether textures have been initialized
  bool _initialized = false;

  TextureManager(this.gl, {this.textureSize = 256});

  /// Initialize all terrain textures
  ///
  /// Generates procedural textures for all terrain types.
  /// Call once during game initialization.
  Future<void> initialize() async {
    if (_initialized) return;

    print('[TextureManager] Initializing terrain textures...');

    // Generate diffuse textures for each terrain type
    for (final type in TerrainTextureType.values) {
      _diffuseTextures[type] = _generateDiffuseTexture(type);
      _normalTextures[type] = _generateNormalTexture(type);
    }

    // Generate detail texture
    _detailTexture = _generateDetailTexture();

    _initialized = true;
    print('[TextureManager] Initialized ${_diffuseTextures.length} terrain textures');
  }

  /// Generate a procedural diffuse texture for terrain type
  dynamic _generateDiffuseTexture(TerrainTextureType type) {
    final pixels = Uint8List(textureSize * textureSize * 4);
    final random = math.Random(type.index * 12345);

    // Base colors for each terrain type
    final baseColor = _getBaseColor(type);

    for (int y = 0; y < textureSize; y++) {
      for (int x = 0; x < textureSize; x++) {
        final idx = (y * textureSize + x) * 4;

        // Add noise variation for natural look
        final noise = _generateTextureNoise(x, y, type, random);

        // Apply color with variation
        pixels[idx + 0] = _clampColor(baseColor.r + noise.r);
        pixels[idx + 1] = _clampColor(baseColor.g + noise.g);
        pixels[idx + 2] = _clampColor(baseColor.b + noise.b);
        pixels[idx + 3] = 255; // Full opacity
      }
    }

    return _createWebGLTexture(pixels);
  }

  /// Generate a procedural normal map texture
  dynamic _generateNormalTexture(TerrainTextureType type) {
    final pixels = Uint8List(textureSize * textureSize * 4);
    final random = math.Random(type.index * 54321);

    // Normal map intensity varies by terrain type
    final intensity = _getNormalIntensity(type);

    for (int y = 0; y < textureSize; y++) {
      for (int x = 0; x < textureSize; x++) {
        final idx = (y * textureSize + x) * 4;

        // Generate height-based normal
        final dx = _sampleNormalHeight(x + 1, y, type, random) -
            _sampleNormalHeight(x - 1, y, type, random);
        final dz = _sampleNormalHeight(x, y + 1, type, random) -
            _sampleNormalHeight(x, y - 1, type, random);

        // Create normal vector (tangent space)
        var nx = -dx * intensity;
        var ny = 1.0;
        var nz = -dz * intensity;

        // Normalize
        final len = math.sqrt(nx * nx + ny * ny + nz * nz);
        nx /= len;
        ny /= len;
        nz /= len;

        // Convert from [-1,1] to [0,255]
        pixels[idx + 0] = ((nx * 0.5 + 0.5) * 255).toInt().clamp(0, 255);
        pixels[idx + 1] = ((ny * 0.5 + 0.5) * 255).toInt().clamp(0, 255);
        pixels[idx + 2] = ((nz * 0.5 + 0.5) * 255).toInt().clamp(0, 255);
        pixels[idx + 3] = 255;
      }
    }

    return _createWebGLTexture(pixels);
  }

  /// Generate high-frequency detail texture
  dynamic _generateDetailTexture() {
    final pixels = Uint8List(textureSize * textureSize * 4);
    final random = math.Random(99999);

    for (int y = 0; y < textureSize; y++) {
      for (int x = 0; x < textureSize; x++) {
        final idx = (y * textureSize + x) * 4;

        // High-frequency noise for detail
        final noise = (random.nextDouble() * 30 - 15).toInt();
        final value = 128 + noise;

        pixels[idx + 0] = value.clamp(0, 255);
        pixels[idx + 1] = value.clamp(0, 255);
        pixels[idx + 2] = value.clamp(0, 255);
        pixels[idx + 3] = 255;
      }
    }

    return _createWebGLTexture(pixels);
  }

  /// Get base color for terrain type
  _ColorRGB _getBaseColor(TerrainTextureType type) {
    switch (type) {
      case TerrainTextureType.grass:
        return _ColorRGB(80, 140, 50); // Green grass
      case TerrainTextureType.dirt:
        return _ColorRGB(130, 100, 70); // Brown dirt
      case TerrainTextureType.rock:
        return _ColorRGB(120, 115, 110); // Gray rock
      case TerrainTextureType.sand:
        return _ColorRGB(210, 190, 140); // Tan sand
    }
  }

  /// Generate texture noise for natural variation
  _ColorRGB _generateTextureNoise(
      int x, int y, TerrainTextureType type, math.Random random) {
    // Use different noise patterns per terrain type
    switch (type) {
      case TerrainTextureType.grass:
        // Grass: small blades, green variation
        final blade = _grassBladeNoise(x, y, random);
        return _ColorRGB(
          (blade * 20 - 10).toInt(),
          (blade * 40 - 10).toInt(),
          (blade * 10 - 5).toInt(),
        );

      case TerrainTextureType.dirt:
        // Dirt: clumpy, earthy variation
        final clump = _dirtClumpNoise(x, y, random);
        return _ColorRGB(
          (clump * 30 - 15).toInt(),
          (clump * 25 - 12).toInt(),
          (clump * 20 - 10).toInt(),
        );

      case TerrainTextureType.rock:
        // Rock: crystalline, cracks
        final crack = _rockCrackNoise(x, y, random);
        return _ColorRGB(
          (crack * 40 - 20).toInt(),
          (crack * 40 - 20).toInt(),
          (crack * 40 - 20).toInt(),
        );

      case TerrainTextureType.sand:
        // Sand: fine grain, slight sparkle
        final grain = _sandGrainNoise(x, y, random);
        return _ColorRGB(
          (grain * 25 - 12).toInt(),
          (grain * 20 - 10).toInt(),
          (grain * 15 - 7).toInt(),
        );
    }
  }

  /// Grass blade noise pattern
  double _grassBladeNoise(int x, int y, math.Random random) {
    // Create grass blade-like patterns
    final fx = x / textureSize * 16;
    final fy = y / textureSize * 16;
    final blade = math.sin(fx * 3.14159 * 2 + fy * 0.5) * 0.5 + 0.5;
    return blade * 0.7 + random.nextDouble() * 0.3;
  }

  /// Dirt clump noise pattern
  double _dirtClumpNoise(int x, int y, math.Random random) {
    // Create clumpy dirt patterns using cellular-like noise
    final fx = x / textureSize;
    final fy = y / textureSize;
    final worley = _worleyNoise(fx * 8, fy * 8, random);
    return worley * 0.6 + random.nextDouble() * 0.4;
  }

  /// Rock crack noise pattern
  double _rockCrackNoise(int x, int y, math.Random random) {
    // Create crystalline crack patterns
    final fx = x / textureSize;
    final fy = y / textureSize;
    final crack = _voronoiNoise(fx * 6, fy * 6, random);
    return crack * 0.8 + random.nextDouble() * 0.2;
  }

  /// Sand grain noise pattern
  double _sandGrainNoise(int x, int y, math.Random random) {
    // Fine grain sand with occasional sparkle
    final sparkle = random.nextDouble() > 0.98 ? 1.0 : 0.0;
    return random.nextDouble() * 0.8 + sparkle * 0.2;
  }

  /// Simple Worley/cellular noise approximation
  double _worleyNoise(double x, double y, math.Random random) {
    final ix = x.floor();
    final iy = y.floor();
    var minDist = 2.0;

    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final seed = ((ix + dx) * 73856093) ^ ((iy + dy) * 19349663);
        final cellRandom = math.Random(seed.abs());
        final px = ix + dx + cellRandom.nextDouble();
        final py = iy + dy + cellRandom.nextDouble();
        final dist = math.sqrt((x - px) * (x - px) + (y - py) * (y - py));
        minDist = math.min(minDist, dist);
      }
    }

    return minDist.clamp(0.0, 1.0);
  }

  /// Simple Voronoi noise for rock cracks
  double _voronoiNoise(double x, double y, math.Random random) {
    final worley = _worleyNoise(x, y, random);
    // Edge detection for crack-like appearance
    return worley < 0.15 ? 0.0 : 1.0 - worley * 0.5;
  }

  /// Get normal intensity based on terrain type
  double _getNormalIntensity(TerrainTextureType type) {
    switch (type) {
      case TerrainTextureType.grass:
        return 0.3; // Subtle grass texture
      case TerrainTextureType.dirt:
        return 0.5; // Medium bumps
      case TerrainTextureType.rock:
        return 1.0; // Strong rock detail
      case TerrainTextureType.sand:
        return 0.2; // Fine sand ripples
    }
  }

  /// Sample height for normal calculation
  double _sampleNormalHeight(int x, int y, TerrainTextureType type, math.Random random) {
    // Wrap coordinates for seamless tiling
    x = x % textureSize;
    y = y % textureSize;
    if (x < 0) x += textureSize;
    if (y < 0) y += textureSize;

    final seed = (x * 73856093) ^ (y * 19349663) ^ (type.index * 83492791);
    final localRandom = math.Random(seed.abs());
    return localRandom.nextDouble();
  }

  /// Clamp color value to valid range
  int _clampColor(int value) {
    return value.clamp(0, 255);
  }

  /// Create WebGL texture from pixel data
  dynamic _createWebGLTexture(Uint8List pixels) {
    final texture = gl.createTexture();
    gl.bindTexture(0x0DE1, texture); // TEXTURE_2D

    // Upload pixel data
    gl.texImage2D(
      0x0DE1, // TEXTURE_2D
      0, // mip level
      0x1908, // RGBA
      textureSize,
      textureSize,
      0, // border
      0x1908, // RGBA
      0x1401, // UNSIGNED_BYTE
      pixels,
    );

    // Set texture parameters for tiling
    gl.texParameteri(0x0DE1, 0x2801, 0x2601); // MIN_FILTER = LINEAR
    gl.texParameteri(0x0DE1, 0x2800, 0x2601); // MAG_FILTER = LINEAR
    gl.texParameteri(0x0DE1, 0x2802, 0x2901); // WRAP_S = REPEAT
    gl.texParameteri(0x0DE1, 0x2803, 0x2901); // WRAP_T = REPEAT

    // Generate mipmaps for LOD
    gl.generateMipmap(0x0DE1); // TEXTURE_2D
    gl.texParameteri(0x0DE1, 0x2801, 0x2703); // MIN_FILTER = LINEAR_MIPMAP_LINEAR

    gl.bindTexture(0x0DE1, null);

    return texture;
  }

  /// Bind all terrain textures to texture units for rendering
  ///
  /// Texture unit assignment:
  /// - 0: Grass diffuse
  /// - 1: Dirt diffuse
  /// - 2: Rock diffuse
  /// - 3: Sand diffuse
  /// - 4: Grass normal
  /// - 5: Dirt normal
  /// - 6: Rock normal
  /// - 7: Sand normal
  /// - 8: Detail texture
  void bindTerrainTextures() {
    if (!_initialized) {
      print('[TextureManager] Warning: Textures not initialized');
      return;
    }

    // Bind diffuse textures (units 0-3)
    _bindTexture(0, _diffuseTextures[TerrainTextureType.grass]);
    _bindTexture(1, _diffuseTextures[TerrainTextureType.dirt]);
    _bindTexture(2, _diffuseTextures[TerrainTextureType.rock]);
    _bindTexture(3, _diffuseTextures[TerrainTextureType.sand]);

    // Bind normal textures (units 4-7)
    _bindTexture(4, _normalTextures[TerrainTextureType.grass]);
    _bindTexture(5, _normalTextures[TerrainTextureType.dirt]);
    _bindTexture(6, _normalTextures[TerrainTextureType.rock]);
    _bindTexture(7, _normalTextures[TerrainTextureType.sand]);

    // Bind detail texture (unit 8)
    _bindTexture(8, _detailTexture);
  }

  /// Bind a texture to a specific texture unit
  void _bindTexture(int unit, dynamic texture) {
    gl.activeTexture(0x84C0 + unit); // TEXTURE0 + unit
    gl.bindTexture(0x0DE1, texture); // TEXTURE_2D
  }

  /// Get diffuse texture for terrain type
  dynamic getDiffuseTexture(TerrainTextureType type) {
    return _diffuseTextures[type];
  }

  /// Get normal texture for terrain type
  dynamic getNormalTexture(TerrainTextureType type) {
    return _normalTextures[type];
  }

  /// Get detail texture
  dynamic get detailTexture => _detailTexture;

  /// Check if textures are initialized
  bool get isInitialized => _initialized;

  /// Create a splat map texture from splat data
  ///
  /// Parameters:
  /// - splatData: Float32List of RGBA values (R=grass, G=dirt, B=rock, A=sand)
  /// - resolution: Width/height of splat map
  ///
  /// Returns: WebGL texture object
  dynamic createSplatMapTexture(Float32List splatData, int resolution) {
    // Convert float [0,1] to byte [0,255]
    final pixels = Uint8List(resolution * resolution * 4);

    for (int i = 0; i < resolution * resolution; i++) {
      pixels[i * 4 + 0] = (splatData[i * 4 + 0] * 255).toInt().clamp(0, 255);
      pixels[i * 4 + 1] = (splatData[i * 4 + 1] * 255).toInt().clamp(0, 255);
      pixels[i * 4 + 2] = (splatData[i * 4 + 2] * 255).toInt().clamp(0, 255);
      pixels[i * 4 + 3] = (splatData[i * 4 + 3] * 255).toInt().clamp(0, 255);
    }

    final texture = gl.createTexture();
    gl.bindTexture(0x0DE1, texture); // TEXTURE_2D

    gl.texImage2D(
      0x0DE1, // TEXTURE_2D
      0,
      0x1908, // RGBA
      resolution,
      resolution,
      0,
      0x1908, // RGBA
      0x1401, // UNSIGNED_BYTE
      pixels,
    );

    // Use linear filtering for smooth blending
    gl.texParameteri(0x0DE1, 0x2801, 0x2601); // MIN_FILTER = LINEAR
    gl.texParameteri(0x0DE1, 0x2800, 0x2601); // MAG_FILTER = LINEAR
    gl.texParameteri(0x0DE1, 0x2802, 0x812F); // WRAP_S = CLAMP_TO_EDGE
    gl.texParameteri(0x0DE1, 0x2803, 0x812F); // WRAP_T = CLAMP_TO_EDGE

    gl.bindTexture(0x0DE1, null);

    return texture;
  }

  /// Delete a texture
  void deleteTexture(dynamic texture) {
    if (texture != null) {
      gl.deleteTexture(texture);
    }
  }

  /// Dispose all textures
  void dispose() {
    for (final texture in _diffuseTextures.values) {
      gl.deleteTexture(texture);
    }
    for (final texture in _normalTextures.values) {
      gl.deleteTexture(texture);
    }
    if (_detailTexture != null) {
      gl.deleteTexture(_detailTexture);
    }

    _diffuseTextures.clear();
    _normalTextures.clear();
    _detailTexture = null;
    _initialized = false;

    print('[TextureManager] Disposed');
  }
}

/// Terrain texture types
enum TerrainTextureType {
  grass, // Green grass for flatlands
  dirt, // Brown dirt for paths/transitions
  rock, // Gray rock for steep slopes/mountains
  sand, // Tan sand for beaches/deserts
}

/// Simple RGB color helper
class _ColorRGB {
  final int r;
  final int g;
  final int b;

  const _ColorRGB(this.r, this.g, this.b);
}
