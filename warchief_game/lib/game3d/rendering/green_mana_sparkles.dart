import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../state/game_state.dart';
import '../data/abilities/ability_types.dart' show ManaColor;

/// Individual green mana sparkle particle.
class _GreenSparkle {
  double startX, startY, startZ;
  double endX, endY, endZ;
  double life;
  double maxLife;
  double arcOffset; // Perpendicular offset for curved arc
  double progress;  // 0.0 to 1.0 along the arc

  _GreenSparkle({
    this.startX = 0, this.startY = 0, this.startZ = 0,
    this.endX = 0, this.endY = 0, this.endZ = 0,
    this.life = 0, this.maxLife = 0.5,
    this.arcOffset = 0, this.progress = 0,
  });
}

/// Arc-sparkle particle system for green mana.
///
/// Draws electric sparkles between green mana sources (grass, allies,
/// spirit beings) and green-attuned characters. Uses a pre-allocated
/// pool pattern like [WindParticleSystem].
class GreenManaSparkleSystem {
  static const int _maxPool = 200;

  final List<_GreenSparkle> _pool = [];
  int _activeCount = 0;
  final math.Random _rng = math.Random();
  bool _initialized = false;

  Mesh? _mesh;
  final Transform3d _transform = Transform3d(position: Vector3(0, 0, 0));

  bool get isInitialized => _initialized;

  void init() {
    if (_initialized) return;
    _pool.clear();
    for (int i = 0; i < _maxPool; i++) {
      _pool.add(_GreenSparkle());
    }
    _initialized = true;
  }

  /// Update sparkles: spawn from green mana sources, advance along arcs.
  void update(double dt, GameState gameState) {
    if (!_initialized) return;

    final greenAttuned = gameState.activeManaAttunements.contains(ManaColor.green);
    if (!greenAttuned) {
      _activeCount = 0;
      _mesh = null;
      return;
    }

    // Update existing sparkles
    for (int i = 0; i < _activeCount; i++) {
      final s = _pool[i];
      s.life -= dt;
      if (s.life > 0) {
        s.progress = 1.0 - (s.life / s.maxLife);
      }
    }

    // Remove dead sparkles by compacting
    int write = 0;
    for (int read = 0; read < _activeCount; read++) {
      if (_pool[read].life > 0) {
        if (write != read) {
          final tmp = _pool[write];
          _pool[write] = _pool[read];
          _pool[read] = tmp;
        }
        write++;
      }
    }
    _activeCount = write;

    // Spawn new sparkles based on regen rate
    final regenRate = gameState.currentGreenManaRegenRate;
    if (regenRate <= 0) {
      if (_activeCount == 0) _mesh = null;
      return;
    }

    // Spawn rate: ~10 sparkles per second per point of regen
    final spawnRate = regenRate * 10.0;
    final spawnsThisFrame = (spawnRate * dt).toInt() +
        (_rng.nextDouble() < (spawnRate * dt - (spawnRate * dt).floorToDouble()) ? 1 : 0);

    // Get active character position from transform
    final transform = gameState.isWarchiefActive
        ? gameState.playerTransform
        : gameState.activeAlly?.transform;
    if (transform == null) return;
    final pos = transform.position;
    final px = pos.x;
    final pz = pos.z;
    final py = pos.y + 0.5;

    for (int i = 0; i < spawnsThisFrame && _activeCount < _maxPool; i++) {
      final s = _pool[_activeCount];
      _activeCount++;

      // Randomize source type: grass (from ground) or proximity (horizontal)
      final fromGround = _rng.nextBool();
      if (fromGround) {
        // Sparkles rise from ground beneath character
        final offsetX = (_rng.nextDouble() - 0.5) * 2.0;
        final offsetZ = (_rng.nextDouble() - 0.5) * 2.0;
        s.startX = px + offsetX;
        s.startY = py - 0.5;
        s.startZ = pz + offsetZ;
        s.endX = px + offsetX * 0.3;
        s.endY = py + 0.5 + _rng.nextDouble() * 0.5;
        s.endZ = pz + offsetZ * 0.3;
      } else {
        // Sparkles arc horizontally from random nearby position
        final angle = _rng.nextDouble() * math.pi * 2;
        final dist = 1.0 + _rng.nextDouble() * 2.0;
        s.startX = px + math.cos(angle) * dist;
        s.startY = py + (_rng.nextDouble() - 0.5) * 0.5;
        s.startZ = pz + math.sin(angle) * dist;
        s.endX = px;
        s.endY = py;
        s.endZ = pz;
      }

      s.maxLife = 0.3 + _rng.nextDouble() * 0.5;
      s.life = s.maxLife;
      s.arcOffset = (_rng.nextDouble() - 0.5) * 1.5;
      s.progress = 0.0;
    }

    _rebuildMesh();
  }

  /// Rebuild batched mesh from active sparkles.
  ///
  /// Uses Mesh.fromVerticesAndIndices with stride 6 (x,y,z,r,g,b)
  /// matching the wind particle rendering pattern.
  void _rebuildMesh() {
    if (_activeCount == 0) {
      _mesh = null;
      return;
    }

    final vertices = <double>[];
    final indices = <int>[];
    int vertexCount = 0;

    for (int i = 0; i < _activeCount; i++) {
      final s = _pool[i];
      final t = s.progress.clamp(0.0, 1.0);

      // Interpolate position along arc with quadratic bezier
      final mx = (s.startX + s.endX) * 0.5 + s.arcOffset;
      final my = (s.startY + s.endY) * 0.5 + s.arcOffset * 0.5;
      final mz = (s.startZ + s.endZ) * 0.5;

      final oneMinusT = 1.0 - t;
      final px = oneMinusT * oneMinusT * s.startX +
          2.0 * oneMinusT * t * mx +
          t * t * s.endX;
      final py = oneMinusT * oneMinusT * s.startY +
          2.0 * oneMinusT * t * my +
          t * t * s.endY;
      final pz = oneMinusT * oneMinusT * s.startZ +
          2.0 * oneMinusT * t * mz +
          t * t * s.endZ;

      // Fade in/out over lifetime
      final alpha = t < 0.2
          ? t / 0.2
          : t > 0.8
              ? (1.0 - t) / 0.2
              : 1.0;

      // Sparkle size
      final size = 0.04 + alpha * 0.03;

      // Green with white core, pre-multiplied by alpha
      final coreBlend = (1.0 - (t - 0.5).abs() * 2.0).clamp(0.0, 1.0);
      final a = alpha * 0.9;
      final r = (0.3 + coreBlend * 0.7) * a;
      final g = 1.0 * a;
      final b = (0.4 + coreBlend * 0.6) * a;

      // Build quad (4 vertices) centered at (px, py, pz)
      vertices.addAll([
        px - size, py - size, pz, r, g, b,
        px + size, py - size, pz, r, g, b,
        px + size, py + size, pz, r, g, b,
        px - size, py + size, pz, r, g, b,
      ]);

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
      vertexStride: 6,
    );
  }

  /// Render the sparkle mesh with additive blending.
  void render(WebGLRenderer renderer, Camera3D camera) {
    if (_mesh == null) return;

    final gl = renderer.gl;
    gl.enable(0x0BE2); // GL_BLEND
    gl.blendFunc(0x0302, 0x0001); // SRC_ALPHA, ONE (additive)
    gl.depthMask(false);

    renderer.render(_mesh!, _transform, camera);

    gl.depthMask(true);
    gl.disable(0x0BE2);
  }
}
