import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../state/wind_state.dart';
import '../state/wind_config.dart';

/// Individual wind particle data.
class _WindParticle {
  double x, y, z;
  double life;
  double maxLife;

  _WindParticle({
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.life = 0,
    this.maxLife = 3.0,
  });
}

/// Visual particle system for wind effects.
///
/// Spawns particles near the player that drift along the wind direction,
/// with slight vertical oscillation. Camera-bounded: only renders within
/// fadeDistance of the player for performance.
///
/// Uses batched rendering (single vertex-colored mesh draw call) like
/// the Ley Line rendering pattern in render_system.dart.
class WindParticleSystem {
  final List<_WindParticle> _particles = [];
  final math.Random _random = math.Random();
  bool _initialized = false;

  /// Whether the particle system has been initialized
  bool get isInitialized => _initialized;

  /// Cached mesh rebuilt each frame from particle positions
  Mesh? _mesh;
  final Transform3d _transform = Transform3d(
    position: Vector3(0, 0, 0),
  );

  /// Initialize particle pool.
  void init() {
    if (_initialized) return;

    final count = globalWindConfig?.particleCount ?? 60;
    _particles.clear();
    for (int i = 0; i < count; i++) {
      _particles.add(_WindParticle(
        life: 0, // Will be respawned on first update
        maxLife: 0,
      ));
    }
    _initialized = true;
    print('[WindParticles] Initialized with $count particles');
  }

  /// Update all particles: move along wind, recycle dead ones near player.
  void update(
    double dt,
    Vector3 playerPos,
    WindState windState,
  ) {
    if (!_initialized) return;

    final config = globalWindConfig;
    final particleSpeed = config?.particleSpeed ?? 2.0;
    final lifetime = config?.particleLifetime ?? 3.0;
    final fadeDistance = config?.fadeDistance ?? 15.0;

    final wv = windState.windVector;
    final windX = wv[0];
    final windZ = wv[1];
    final windStr = windState.windStrength;

    for (final p in _particles) {
      p.life -= dt;

      if (p.life <= 0) {
        // Respawn near player within fadeDistance
        _respawnParticle(p, playerPos, fadeDistance, lifetime);
      } else {
        // Move along wind direction with speed proportional to wind strength
        final speed = particleSpeed * (0.5 + windStr * 0.5);
        p.x += windX * speed * dt;
        p.z += windZ * speed * dt;

        // Slight vertical oscillation for natural feel
        p.y += math.sin(p.life * 3.0) * 0.3 * dt;
      }
    }

    // Rebuild mesh from current particle positions
    _rebuildMesh(playerPos, fadeDistance, windStr);
  }

  /// Respawn a dead particle randomly within fadeDistance of the player.
  void _respawnParticle(
    _WindParticle p,
    Vector3 playerPos,
    double fadeDistance,
    double lifetime,
  ) {
    // Random position within fadeDistance of player
    final angle = _random.nextDouble() * 2 * math.pi;
    final dist = _random.nextDouble() * fadeDistance;
    p.x = playerPos.x + math.cos(angle) * dist;
    p.z = playerPos.z + math.sin(angle) * dist;
    p.y = playerPos.y + 0.5 + _random.nextDouble() * 2.0; // Slightly above ground

    // Randomize lifetime for staggered recycling
    p.maxLife = lifetime * (0.5 + _random.nextDouble() * 0.5);
    p.life = p.maxLife;
  }

  /// Rebuild a single batched mesh from all alive particles.
  void _rebuildMesh(Vector3 playerPos, double fadeDistance, double windStr) {
    final vertices = <double>[];
    final indices = <int>[];
    var vertexCount = 0;

    final colorVals = globalWindConfig?.particleColor ?? [1.0, 1.0, 1.0, 0.3];
    final baseR = colorVals[0];
    final baseG = colorVals[1];
    final baseB = colorVals[2];
    final baseAlpha = colorVals.length > 3 ? colorVals[3] : 0.3;

    // Particle size (small quads)
    const particleSize = 0.08;

    for (final p in _particles) {
      if (p.life <= 0) continue;

      // Fade based on distance from player
      final dx = p.x - playerPos.x;
      final dz = p.z - playerPos.z;
      final dist = math.sqrt(dx * dx + dz * dz);
      if (dist > fadeDistance) continue;

      // Fade alpha: full in center, zero at fadeDistance edge
      final distFade = 1.0 - (dist / fadeDistance);
      // Fade alpha: fade in at start, fade out at end of life
      final lifeFraction = p.life / p.maxLife;
      final lifeFade = lifeFraction < 0.2
          ? lifeFraction / 0.2 // Fade in
          : lifeFraction > 0.8
              ? (1.0 - lifeFraction) / 0.2 // Fade out
              : 1.0;

      final alpha = baseAlpha * distFade * lifeFade * windStr;
      if (alpha < 0.01) continue;

      final r = baseR * alpha;
      final g = baseG * alpha;
      final b = baseB * alpha;

      // Create a tiny quad at particle position
      // 4 vertices per quad
      final halfSize = particleSize;
      vertices.addAll([
        p.x - halfSize, p.y, p.z - halfSize, r, g, b,
        p.x + halfSize, p.y, p.z - halfSize, r, g, b,
        p.x + halfSize, p.y, p.z + halfSize, r, g, b,
        p.x - halfSize, p.y, p.z + halfSize, r, g, b,
      ]);

      // 2 triangles per quad
      final base = vertexCount;
      indices.addAll([base, base + 1, base + 2]);
      indices.addAll([base, base + 2, base + 3]);
      vertexCount += 4;
    }

    if (vertices.isEmpty) {
      _mesh = null;
      return;
    }

    _mesh = Mesh.fromVerticesAndIndices(
      vertices: vertices,
      indices: indices,
      vertexStride: 6, // x, y, z, r, g, b
    );
  }

  /// Render all particles as a single batched mesh.
  void render(WebGLRenderer renderer, Camera3D camera) {
    if (_mesh == null) return;
    renderer.render(_mesh!, _transform, camera);
  }
}
