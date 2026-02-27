import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../state/wind_swirl_state.dart';
import '../state/wind_config.dart';

/// Renders active dust devils as animated swirling particle columns.
///
/// Each devil is drawn as N particles arranged in a rising helix:
/// - Funnel shape: narrow at the base, wider toward the top
/// - Particles are horizontal quads (XZ-plane) that rotate with angularPhase
/// - Organic variation added via sin-based wobble (no per-particle storage)
/// - Color: dusty tan, alpha fades at the base and crown
///
/// All devils are batched into a single mesh draw call per frame,
/// following the same pattern as [WindParticleSystem].
class DustDevilParticleSystem {
  bool _initialized = false;
  bool get isInitialized => _initialized;

  Mesh? _mesh;
  final Transform3d _transform = Transform3d(position: Vector3(0, 0, 0));

  void init() {
    _initialized = true;
  }

  /// Rebuild the batched mesh from current devil snapshots.
  void update(List<DustDevilData> devils) {
    if (devils.isEmpty) {
      _mesh = null;
      return;
    }

    final config        = globalWindConfig;
    final n             = config?.swirlParticleCount ?? 60;
    final maxH          = config?.swirlHeight        ?? 5.0;
    final baseRadius    = config?.swirlRadius        ?? 2.0;
    final ps            = config?.swirlParticleSize  ?? 0.18;

    final vertices = <double>[];
    final indices  = <int>[];
    var vc = 0;

    for (final d in devils) {
      for (int i = 0; i < n; i++) {
        final frac   = i / n;
        final angle  = d.angularPhase + frac * 2 * math.pi;
        final height = frac * maxH;

        // Funnel: narrow at base (15% of radius), wide at top (100%).
        // Reason: dust devil vortex draws in air at ground and expands upward.
        final r = baseRadius * (0.15 + 0.85 * frac);

        // Organic wobble via sin hash — avoids storing per-particle state.
        final wobble = math.sin(i * 2.3 + d.angularPhase * 0.7) * 0.25;
        final rOff   = r + wobble;
        final hOff   = height + math.cos(i * 1.7 + d.angularPhase) * 0.15;

        final px = d.x + math.cos(angle) * rOff;
        final py = d.baseY + hOff;
        final pz = d.z + math.sin(angle) * rOff;

        // Alpha: sin-curve peaks at mid-height, fades at base and crown.
        final alphaCurve = math.sin(frac * math.pi);
        final alpha = d.intensity * alphaCurve * 0.80;
        if (alpha < 0.01) continue;

        // Dusty tan color (premultiplied alpha for additive-style softness).
        final rr = 0.85 * alpha;
        final gg = 0.65 * alpha;
        final bb = 0.35 * alpha;

        // Horizontal quad in the XZ plane (flat disc-shaped mote).
        // v0 = back-left, v1 = back-right, v2 = front-right, v3 = front-left
        vertices.addAll([px - ps, py, pz - ps, rr, gg, bb]);
        vertices.addAll([px + ps, py, pz - ps, rr, gg, bb]);
        vertices.addAll([px + ps, py, pz + ps, rr, gg, bb]);
        vertices.addAll([px - ps, py, pz + ps, rr, gg, bb]);

        indices.addAll([vc, vc + 1, vc + 2]);
        indices.addAll([vc, vc + 2, vc + 3]);
        vc += 4;
      }
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

  /// Render all dust devil particles as a single batched mesh.
  void render(WebGLRenderer renderer, Camera3D camera) {
    if (_mesh == null) return;
    renderer.render(_mesh!, _transform, camera);
  }
}
