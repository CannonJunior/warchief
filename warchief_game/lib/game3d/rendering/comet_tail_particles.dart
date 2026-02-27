import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../state/comet_state.dart';

/// Individual tail particle.
class _TailParticle {
  double x = 0, y = 0, z = 0;
  double vx = 0, vy = 0, vz = 0;
  double life = -1; // negative = inactive slot
  double maxLife = 1.0;
  int layer = 0; // 0=core(white-blue), 1=mid(blue-purple), 2=outer(deep-violet)
}

/// Animates a streaming particle tail behind the comet.
///
/// Particles spawn at the comet's world position and drift backward along the
/// anti-orbital tangent (opposite to the direction the comet is travelling).
/// Three colour layers produce a white-core → violet-outer gradient:
///   Layer 0 – bright white-blue core
///   Layer 1 – blue-purple mid band
///   Layer 2 – deep violet outer wisps
///
/// All particles are batched into a single additive-blended mesh per frame.
/// The system is fully invisible when [CometState.cometIntensity] < 0.02.
class CometTailParticleSystem {
  static const int _maxPool = 240;

  final List<_TailParticle> _pool = [];
  final math.Random _rng = math.Random(7); // fixed seed — deterministic spawn order
  double _spawnAccum = 0.0;

  Mesh? _mesh;
  final Transform3d _transform = Transform3d(position: Vector3(0, 0, 0));

  bool _initialized = false;

  // ==================== INIT ====================

  void init() {
    if (_initialized) return;
    for (int i = 0; i < _maxPool; i++) {
      _pool.add(_TailParticle());
    }
    _initialized = true;
  }

  // ==================== UPDATE ====================

  /// Advance particle simulation by [dt] seconds.
  void update(double dt, CometState cometState) {
    if (!_initialized) init();

    final intensity = cometState.cometIntensity;
    if (intensity < 0.02) {
      // Drain pool quickly when comet dims so particles don't linger post-flyby
      for (final p in _pool) {
        p.life = -1;
      }
      _mesh = null;
      return;
    }

    final pos = cometState.cometWorldPosition; // [x, y, z]
    final tangent = cometState.orbitalTangent; // normalised [dx, dy, dz]

    // Anti-tangent: tail streams opposite to comet's direction of motion
    final atx = -tangent[0];
    final aty = -tangent[1];
    final atz = -tangent[2];

    // Advance existing particles
    for (final p in _pool) {
      if (p.life < 0) continue;
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.z += p.vz * dt;
    }

    // Reason: spawn rate scales with intensity — thin tail at aphelion,
    // dense luminous stream at perihelion.
    final spawnRate = 28.0 * intensity;
    _spawnAccum += spawnRate * dt;
    while (_spawnAccum >= 1.0) {
      _spawnAccum -= 1.0;
      _spawnOne(pos[0], pos[1], pos[2], atx, aty, atz, intensity);
    }

    _rebuildMesh(intensity);
  }

  // ==================== RENDER ====================

  void render(WebGLRenderer renderer, Camera3D camera) {
    if (_mesh == null) return;
    renderer.render(_mesh!, _transform, camera);
  }

  // ==================== PRIVATE ====================

  void _spawnOne(
    double cx,
    double cy,
    double cz,
    double atx,
    double aty,
    double atz,
    double intensity,
  ) {
    _TailParticle? slot;
    for (final p in _pool) {
      if (p.life < 0) {
        slot = p;
        break;
      }
    }
    if (slot == null) return;

    // Pick colour layer — weighted toward core (brighter centre)
    final r = _rng.nextDouble();
    slot.layer = r < 0.45 ? 0 : (r < 0.75 ? 1 : 2);

    // Radial spread perpendicular to tail direction in the XZ plane.
    // Reason: outer layers spread wider to simulate dust-tail divergence.
    final spread = 3.0 + slot.layer * 7.0;
    final jAngle = _rng.nextDouble() * 2 * math.pi;

    // Compute a perpendicular vector to the anti-tangent in XZ: perp = (atz, 0, -atx)
    final pLen = math.sqrt(atx * atx + atz * atz);
    final px = pLen > 0.001 ? atz / pLen : 1.0;
    final pz = pLen > 0.001 ? -atx / pLen : 0.0;
    final rSpread = spread * (0.3 + _rng.nextDouble() * 0.7);

    slot.x = cx + math.cos(jAngle) * px * rSpread - math.sin(jAngle) * pz * rSpread;
    slot.y = cy + (_rng.nextDouble() - 0.5) * spread * 0.35;
    slot.z = cz + math.cos(jAngle) * pz * rSpread + math.sin(jAngle) * px * rSpread;

    // Velocity: mainly along anti-tangent with slight random jitter
    final speed = 10.0 + _rng.nextDouble() * 22.0;
    const jitterMag = 3.0;
    slot.vx = atx * speed + (_rng.nextDouble() - 0.5) * jitterMag;
    slot.vy = aty * speed + (_rng.nextDouble() - 0.5) * jitterMag * 0.2;
    slot.vz = atz * speed + (_rng.nextDouble() - 0.5) * jitterMag;

    slot.maxLife = 3.0 + _rng.nextDouble() * 4.5; // 3–7.5 s
    slot.life = slot.maxLife;
  }

  void _rebuildMesh(double intensity) {
    // Layer particle sizes (world units — large because comet is ~450 units away)
    const sizes = [3.5, 6.5, 11.0];

    final vertices = <double>[];
    final indices = <int>[];
    int vc = 0;

    for (final p in _pool) {
      if (p.life < 0) continue;
      final lifeFrac = (p.life / p.maxLife).clamp(0.0, 1.0);

      // Reason: outer layers fade faster so the white-blue core remains visible
      // throughout particle lifetime while violet wisps dissolve at the edges.
      final alphaScale = p.layer == 0 ? 0.92 : (p.layer == 1 ? 0.55 : 0.28);
      final alpha = lifeFrac * intensity * alphaScale;
      if (alpha < 0.008) continue;

      double r, g, b;
      switch (p.layer) {
        case 1:
          r = 0.45 * alpha;
          g = 0.22 * alpha;
          b = 1.00 * alpha;
          break;
        case 2:
          r = 0.22 * alpha;
          g = 0.04 * alpha;
          b = 0.68 * alpha;
          break;
        default: // core
          r = 0.80 * alpha;
          g = 0.85 * alpha;
          b = 1.00 * alpha;
          break;
      }

      final ps = sizes[p.layer];
      // Horizontal XZ quad — visible as a bright disc when the camera looks down
      vertices.addAll([p.x - ps, p.y, p.z - ps, r, g, b]);
      vertices.addAll([p.x + ps, p.y, p.z - ps, r, g, b]);
      vertices.addAll([p.x + ps, p.y, p.z + ps, r, g, b]);
      vertices.addAll([p.x - ps, p.y, p.z + ps, r, g, b]);
      indices.addAll([vc, vc + 1, vc + 2, vc, vc + 2, vc + 3]);
      vc += 4;
    }

    if (vertices.isEmpty) {
      _mesh = null;
      return;
    }
    _mesh = Mesh.fromVerticesAndIndices(
      vertices: vertices,
      indices: indices,
      vertexStride: 6,
    );
  }
}
