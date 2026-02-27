import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../state/comet_state.dart';
import '../state/comet_config.dart';

/// Individual meteor streak data.
class _MeteorParticle {
  double x, y, z;
  double vx, vy, vz;
  double life;
  double maxLife;
  double brightness; // 0.6–1.0 random per particle

  // Flash effect state (when meteor impacts terrain)
  double flashTimer = 0.0;
  double flashX = 0.0, flashZ = 0.0;

  _MeteorParticle({
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.vx = 0,
    this.vy = -80.0,
    this.vz = 0,
    this.life = 0,
    this.maxLife = 3.0,
    this.brightness = 0.8,
  });
}

/// Meteor particle system for the comet shower.
///
/// Spawns downward-streaking meteor particles from a radiant point high in the
/// sky, aligned with the comet's azimuth direction. Meteors impact the terrain,
/// triggering an impact flash and registering a black-mana crater in CometState.
///
/// Follows the [WindParticleSystem] pattern: pool-based, batched mesh rendering.
class MeteorParticleSystem {
  static const int _maxPool = 500;

  final List<_MeteorParticle> _particles = [];
  final math.Random _random = math.Random();

  /// Accumulated spawn time (drives rate-based spawning)
  double _spawnAccum = 0.0;

  Mesh? _mesh;
  final Transform3d _transform = Transform3d(position: Vector3(0, 0, 0));

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize the particle pool at max capacity.
  void init() {
    if (_initialized) return;
    for (int i = 0; i < _maxPool; i++) {
      _particles.add(_MeteorParticle(life: -1)); // -1 = inactive
    }
    _initialized = true;
  }

  /// Update all meteor particles and spawn new ones based on shower intensity.
  ///
  /// [playerX] / [playerZ] used as spawn center and for terrain height sampling.
  /// [terrainHeight] callback returns terrain Y at (x, z).
  void update(
    double dt,
    double playerX,
    double playerZ,
    double Function(double x, double z) terrainHeight,
    CometState cometState,
  ) {
    if (!_initialized) return;

    final config = globalCometConfig;
    final speed = config?.meteorSpeed ?? 80.0;
    final lifetime = config?.meteorLifetime ?? 3.0;
    final spawnRadius = config?.meteorSpawnRadius ?? 80.0;
    final spawnHeight = config?.meteorSpawnHeight ?? 200.0;
    final flashDuration = config?.meteorImpactFlashDuration ?? 0.4;

    // ── Update active particles ──────────────────────────────────────────────
    for (final p in _particles) {
      if (p.life < 0) continue;

      p.life -= dt;

      // Update flash timer independently (persists a bit after respawn)
      if (p.flashTimer > 0) {
        p.flashTimer -= dt;
      }

      if (p.life <= 0) {
        // Particle expired without impact — deactivate
        p.life = -1;
        continue;
      }

      // Move meteor
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.z += p.vz * dt;

      // Check terrain impact
      final th = terrainHeight(p.x, p.z);
      if (p.y <= th + 0.5) {
        // Impact! Register crater with terrain height for 3D debris placement
        cometState.addImpactCrater(p.x, th, p.z);
        p.flashTimer = flashDuration;
        p.flashX = p.x;
        p.flashZ = p.z;
        // Deactivate this streak; a new one will spawn from pool
        p.life = -1;
      }
    }

    // ── Spawn new particles ──────────────────────────────────────────────────
    final baseRate = config?.meteorBaseRate ?? 0.5;
    final showerRate = config?.meteorShowerRate ?? 5.0;

    // Reason: blend between base and shower rate based on shower intensity
    final effectiveRate = baseRate +
        (showerRate - baseRate) * cometState.meteorShowerIntensity;

    _spawnAccum += effectiveRate * dt;

    while (_spawnAccum >= 1.0) {
      _spawnAccum -= 1.0;
      _spawnOne(playerX, playerZ, spawnRadius, spawnHeight, speed, lifetime,
          cometState);
    }

    // ── Rebuild mesh ─────────────────────────────────────────────────────────
    _rebuildMesh(config);
  }

  /// Render the meteor batch with additive blending (glow effect).
  void render(WebGLRenderer renderer, Camera3D camera) {
    if (!_initialized || _mesh == null) return;
    final gl = renderer.gl;

    gl.enable(0x0BE2); // GL_BLEND
    gl.blendFunc(0x0302, 0x0001); // SRC_ALPHA, ONE (additive)
    gl.depthMask(false);

    renderer.render(_mesh!, _transform, camera);

    gl.depthMask(true);
    gl.disable(0x0BE2);
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  void _spawnOne(
    double cx,
    double cz,
    double spawnRadius,
    double spawnHeight,
    double speed,
    double lifetime,
    CometState cometState,
  ) {
    // Find an inactive slot
    _MeteorParticle? slot;
    for (final p in _particles) {
      if (p.life < 0) {
        slot = p;
        break;
      }
    }
    if (slot == null) return; // Pool exhausted

    // Random position above player within spawn radius
    final angle = _random.nextDouble() * 2.0 * math.pi;
    final r = _random.nextDouble() * spawnRadius;
    slot.x = cx + math.cos(angle) * r;
    slot.z = cz + math.sin(angle) * r;
    slot.y = spawnHeight + _random.nextDouble() * 30.0;

    // Velocity: diagonal — strong horizontal component from comet's azimuth direction.
    // Reason: near-vertical motion keeps meteors outside the isometric camera's frustum
    // (top-of-view is ~0° elevation) and makes trails invisible due to XZ-perp collapse.
    // A 37° diagonal (hSpeed=0.6, vSpeed=0.8) crosses the visible play area.
    final azimuth = cometState.skyAzimuthFraction * 2.0 * math.pi;
    final hSpeed = speed * 0.6; // horizontal component from comet azimuth
    final vSpeed = speed * 0.8; // vertical component
    final jitter = speed * 0.08; // small perpendicular jitter for variety
    final perpAzimuth = azimuth + math.pi / 2.0;
    slot.vx = math.cos(azimuth) * hSpeed +
        math.cos(perpAzimuth) * jitter * (_random.nextDouble() - 0.5);
    slot.vy = -vSpeed * (0.9 + _random.nextDouble() * 0.1);
    slot.vz = math.sin(azimuth) * hSpeed +
        math.sin(perpAzimuth) * jitter * (_random.nextDouble() - 0.5);

    slot.maxLife = lifetime * (0.7 + _random.nextDouble() * 0.6);
    slot.life = slot.maxLife;
    slot.brightness = 0.6 + _random.nextDouble() * 0.4;
    slot.flashTimer = 0.0;
  }

  void _rebuildMesh(CometConfig? config) {
    final headC = config?.meteorHeadColor ?? [0.90, 0.80, 1.00];
    final tailC = config?.meteorTailColor ?? [0.10, 0.00, 0.20];
    final trailLen = config?.meteorTrailLength ?? 4.0;

    final vertices = <double>[];
    final indices = <int>[];
    int vertexCount = 0;

    for (final p in _particles) {
      // Render flash quads for craters (brief bright dot at impact site)
      if (p.flashTimer > 0) {
        final alpha = (p.flashTimer /
                (globalCometConfig?.meteorImpactFlashDuration ?? 0.4))
            .clamp(0.0, 1.0);
        final fSize = 1.5 * alpha;
        final fr = headC[0] * alpha;
        final fg = headC[1] * alpha * 0.8;
        final fb = headC[2] * alpha;
        // Flat ground quad for flash
        vertices.addAll([p.flashX - fSize, 0.3, p.flashZ - fSize, fr, fg, fb]);
        vertices.addAll([p.flashX + fSize, 0.3, p.flashZ - fSize, fr, fg, fb]);
        vertices.addAll([p.flashX + fSize, 0.3, p.flashZ + fSize, fr, fg, fb]);
        vertices.addAll([p.flashX - fSize, 0.3, p.flashZ + fSize, fr, fg, fb]);
        indices.addAll([vertexCount, vertexCount + 1, vertexCount + 2]);
        indices.addAll([vertexCount, vertexCount + 2, vertexCount + 3]);
        vertexCount += 4;
      }

      if (p.life < 0) continue;

      // Life fraction for alpha fade
      final lifeFrac = (p.life / p.maxLife).clamp(0.0, 1.0);

      // Trail: elongated quad aligned to velocity direction
      final spd =
          math.sqrt(p.vx * p.vx + p.vy * p.vy + p.vz * p.vz);
      if (spd < 0.001) continue;

      // Normalised velocity for trail direction
      final nvx = p.vx / spd;
      final nvy = p.vy / spd;
      final nvz = p.vz / spd;

      // Perpendicular for trail width — in XZ plane; fallback to world-X for near-vertical motion.
      // Reason: near-vertical velocity (nvz≈0, nvx≈0) collapses the XZ perp to zero, making trails invisible.
      double perpX = -nvz;
      double perpZ = nvx;
      final perpLen = math.sqrt(perpX * perpX + perpZ * perpZ);
      if (perpLen < 0.01) {
        perpX = 1.0;
        perpZ = 0.0;
      } else {
        perpX /= perpLen;
        perpZ /= perpLen;
      }
      const trailWidth = 0.15;

      // Head position (current particle position)
      final hx = p.x;
      final hy = p.y;
      final hz = p.z;

      // Tail position (upstream along velocity)
      final tl = trailLen * lifeFrac;
      final tx = p.x - nvx * tl;
      final ty = p.y - nvy * tl;
      final tz = p.z - nvz * tl;

      final br = p.brightness * lifeFrac;

      // Head color (bright, comet color)
      final hr = headC[0] * br;
      final hg = headC[1] * br;
      final hb = headC[2] * br;

      // Tail color (dark void color)
      final tr2 = tailC[0];
      final tg = tailC[1];
      final tb = tailC[2];

      // 4 vertices: trail as a quad (head wide, tail narrow)
      vertices.addAll([
        hx + perpX * trailWidth, hy, hz + perpZ * trailWidth, hr, hg, hb
      ]);
      vertices.addAll([
        hx - perpX * trailWidth, hy, hz - perpZ * trailWidth, hr, hg, hb
      ]);
      vertices.addAll([tx, ty, tz, tr2, tg, tb]);
      vertices.addAll([tx, ty, tz, tr2, tg, tb]);

      indices.addAll([vertexCount, vertexCount + 1, vertexCount + 2]);
      indices.addAll([vertexCount + 1, vertexCount + 3, vertexCount + 2]);
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
}
