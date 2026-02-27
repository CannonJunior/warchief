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

/// Visual particle system for wind effects with trail rendering.
///
/// Spawns particles near the player that drift along the wind direction,
/// rendered as elongated streaks (trails) aligned with the wind vector.
/// During derecho storms, particle count, trail length, and intensity
/// scale up dramatically (10x by default).
///
/// Uses batched rendering (single vertex-colored mesh draw call) like
/// the Ley Line rendering pattern in render_system.dart.
class WindParticleSystem {
  final List<_WindParticle> _particles = [];
  final math.Random _random = math.Random();
  bool _initialized = false;

  /// Whether the particle system has been initialized
  bool get isInitialized => _initialized;

  /// Normal (non-derecho) particle count
  int _normalCount = 150;

  /// Maximum particle pool size (accounts for derecho scaling)
  int _maxPoolSize = 1500;

  /// Cached mesh rebuilt each frame from particle positions
  Mesh? _mesh;
  final Transform3d _transform = Transform3d(
    position: Vector3(0, 0, 0),
  );

  /// Initialize particle pool sized for derecho max capacity.
  void init() {
    if (_initialized) return;

    final config = globalWindConfig;
    _normalCount = config?.particleCount ?? 150;
    final visualMult = config?.derechoVisualMultiplier ?? 10.0;
    _maxPoolSize = (_normalCount * visualMult).toInt();

    _particles.clear();
    for (int i = 0; i < _maxPoolSize; i++) {
      _particles.add(_WindParticle(
        life: 0,
        maxLife: 0,
      ));
    }
    _initialized = true;
    print('[WindParticles] Initialized with $_normalCount normal / '
        '$_maxPoolSize max (derecho) particles');
  }

  /// Update all particles: move along wind, recycle dead ones near player.
  ///
  /// Active particle count scales with derecho visual multiplier.
  /// Trail rendering parameters are computed in [_rebuildMesh].
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
    final effStr = windState.effectiveWindStrength;

    // Reason: scale active particle count by derecho visual multiplier
    // so storms produce dramatically more visible wind streaks
    final activeCount = (_normalCount * windState.derechoVisualMultiplier)
        .toInt()
        .clamp(0, _maxPoolSize);

    for (int i = 0; i < _maxPoolSize; i++) {
      final p = _particles[i];
      p.life -= dt;

      if (p.life <= 0) {
        if (i < activeCount) {
          // Respawn within active pool
          _respawnParticle(p, playerPos, fadeDistance, lifetime);
        }
        // Particles beyond activeCount stay dead (natural drain when
        // derecho ends — no popping)
      } else {
        // Move along wind direction with speed proportional to effective strength
        final speed = particleSpeed * (0.5 + effStr * 0.5);
        p.x += windX * speed * dt;
        p.z += windZ * speed * dt;

        // Slight vertical oscillation for natural feel
        p.y += math.sin(p.life * 3.0) * 0.3 * dt;
      }
    }

    // Rebuild mesh from current particle positions
    _rebuildMesh(playerPos, fadeDistance, windState);
  }

  /// Respawn a dead particle randomly within fadeDistance of the player.
  void _respawnParticle(
    _WindParticle p,
    Vector3 playerPos,
    double fadeDistance,
    double lifetime,
  ) {
    final angle = _random.nextDouble() * 2 * math.pi;
    final dist = _random.nextDouble() * fadeDistance;
    p.x = playerPos.x + math.cos(angle) * dist;
    p.z = playerPos.z + math.sin(angle) * dist;
    p.y = playerPos.y + 0.3 + _random.nextDouble() * 3.0;

    // Randomize lifetime for staggered recycling
    p.maxLife = lifetime * (0.5 + _random.nextDouble() * 0.5);
    p.life = p.maxLife;
  }

  /// Rebuild a single batched mesh from all alive particles as wind trails.
  ///
  /// Each particle is rendered as an elongated quad (trail) aligned with
  /// the wind direction vector. Trail length scales with wind strength
  /// and derecho intensity.
  void _rebuildMesh(
      Vector3 playerPos, double fadeDistance, WindState windState) {
    final vertices = <double>[];
    final indices = <int>[];
    var vertexCount = 0;

    final config = globalWindConfig;
    final trailsEnabled = config?.trailsEnabled ?? true;
    final effStr = windState.effectiveWindStrength;
    final isDerecho = windState.isDerechoActive;
    final derechoInt = windState.derechoIntensity;

    // Choose color: normal wind vs derecho
    final normalColor =
        config?.particleColor ?? [1.0, 1.0, 1.0, 0.6];
    final derechoColor =
        config?.derechoColor ?? [0.9, 0.95, 1.0, 0.85];

    final baseR = isDerecho
        ? _lerp(normalColor[0], derechoColor[0], derechoInt)
        : normalColor[0];
    final baseG = isDerecho
        ? _lerp(normalColor[1], derechoColor[1], derechoInt)
        : normalColor[1];
    final baseB = isDerecho
        ? _lerp(normalColor[2], derechoColor[2], derechoInt)
        : normalColor[2];
    final baseAlpha = isDerecho
        ? _lerp(
            normalColor.length > 3 ? normalColor[3] : 0.6,
            derechoColor.length > 3 ? derechoColor[3] : 0.85,
            derechoInt)
        : (normalColor.length > 3 ? normalColor[3] : 0.6);

    // Trail geometry: elongated along wind direction
    final trailLength = trailsEnabled
        ? (config?.trailLength ?? 1.2) * (0.3 + effStr * 0.7)
        : (config?.particleSize ?? 0.25);
    final trailWidth = trailsEnabled
        ? (config?.trailWidth ?? 0.08)
        : (config?.particleSize ?? 0.25);

    // Wind direction unit vector for trail alignment
    final windAngle = windState.windAngle;
    final dirX = math.cos(windAngle);
    final dirZ = math.sin(windAngle);
    // Perpendicular direction for trail width
    final perpX = -dirZ;
    final perpZ = dirX;

    final halfLen = trailLength * 0.5;
    final halfWid = trailWidth * 0.5;

    // Reason: compute a 2-segment bent strip so the trail has a visible elbow
    // rather than an imperceptible parallelogram deformation.
    // curveDurationMult amplifies the look-back time so normal-wind curves
    // are clearly visible; clamp prevents spiral artifacts at extreme angVel.
    final angVel = windState.windAngularVelocity;
    final particleSpeedConfig = config?.particleSpeed ?? 2.0;
    final speedFactor = 0.5 + effStr * 0.5;
    final trailDuration =
        trailLength / (particleSpeedConfig * speedFactor).clamp(0.001, double.infinity);
    const curveDurationMult = 2.0;
    final angleOffset = (angVel * trailDuration * curveDurationMult)
        .clamp(-math.pi / 2, math.pi / 2);

    final tailAngle = windAngle - angleOffset;
    final midAngle  = windAngle - angleOffset * 0.5;

    final tailDirX  = math.cos(tailAngle);
    final tailDirZ  = math.sin(tailAngle);
    final tailPerpX = -tailDirZ;
    final tailPerpZ =  tailDirX;

    // Mid-elbow perpendicular (at particle centre)
    final midPerpX = -math.sin(midAngle);
    final midPerpZ =  math.cos(midAngle);

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
          ? lifeFraction / 0.2
          : lifeFraction > 0.8
              ? (1.0 - lifeFraction) / 0.2
              : 1.0;

      // Reason: use base windStrength (0-1) for normal alpha scaling,
      // but clamp to 1.0 so derecho doesn't wash out to pure white
      final strengthAlpha = windState.windStrength.clamp(0.0, 1.0);
      final alpha = baseAlpha * distFade * lifeFade * strengthAlpha;
      if (alpha < 0.01) continue;

      final r = baseR * alpha;
      final g = baseG * alpha;
      final b = baseB * alpha;

      // 6-vertex 2-segment bent strip.
      // v0,v1 = head (downwind, current wind direction)
      // v2,v3 = elbow at particle centre (mid-direction perpendicular)
      // v4,v5 = tail (upwind, historical wind direction)
      // Reason: a flat 4-vertex parallelogram looks like a rotated line even
      // with 20°+ skew. Two joined segments with a visible elbow read as curved.
      vertices.addAll([
        // v0: head right
        p.x + dirX     * halfLen + perpX     * halfWid, p.y,
        p.z + dirZ     * halfLen + perpZ     * halfWid, r, g, b,
        // v1: head left
        p.x + dirX     * halfLen - perpX     * halfWid, p.y,
        p.z + dirZ     * halfLen - perpZ     * halfWid, r, g, b,
        // v2: elbow right (particle centre, mid-direction perp)
        p.x + midPerpX * halfWid, p.y,
        p.z + midPerpZ * halfWid, r, g, b,
        // v3: elbow left
        p.x - midPerpX * halfWid, p.y,
        p.z - midPerpZ * halfWid, r, g, b,
        // v4: tail right
        p.x - tailDirX * halfLen + tailPerpX * halfWid, p.y,
        p.z - tailDirZ * halfLen + tailPerpZ * halfWid, r, g, b,
        // v5: tail left
        p.x - tailDirX * halfLen - tailPerpX * halfWid, p.y,
        p.z - tailDirZ * halfLen - tailPerpZ * halfWid, r, g, b,
      ]);

      final base = vertexCount;
      // Front segment: head → elbow
      indices.addAll([base,     base + 1, base + 3]);
      indices.addAll([base,     base + 3, base + 2]);
      // Back segment: elbow → tail
      indices.addAll([base + 2, base + 3, base + 5]);
      indices.addAll([base + 2, base + 5, base + 4]);
      vertexCount += 6;
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

  /// Linear interpolation helper.
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Render all particles as a single batched mesh.
  void render(WebGLRenderer renderer, Camera3D camera) {
    if (_mesh == null) return;
    renderer.render(_mesh!, _transform, camera);
  }
}
