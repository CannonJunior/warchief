import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../state/comet_state.dart' show ImpactCraterData;

/// Renders persistent 3D meteor impact craters on the terrain.
///
/// Each crater is built from three geometry layers:
///   1. **Scorched disc** — hexagonal glow-fan at ground level, orange-hot when
///      fresh, cooling to dark ash as the crater ages.
///   2. **Ejecta diamonds** — 8 flat diamond quads radiating from the rim,
///      representing splattered terrain material.
///   3. **Rock shards** — 4 cross-shaped debris pieces (two perpendicular
///      vertical quads each), visible from all camera angles.
///
/// All geometry is rebuilt every frame (max ~70 vertices × 20 craters = 1 400
/// vertices, well within budget). Positions are deterministic from the crater's
/// (x, z) coordinates so debris never jitters between frames.
class MeteorCraterRenderer {
  bool _initialized = false;
  bool get isInitialized => _initialized;

  Mesh? _mesh;
  final Transform3d _transform = Transform3d(position: Vector3(0, 0, 0));

  void init() {
    _initialized = true;
  }

  /// Rebuild mesh from current crater snapshots. Call once per frame.
  void update(List<ImpactCraterData> craters) {
    if (craters.isEmpty) {
      _mesh = null;
      return;
    }

    final vertices = <double>[];
    final indices = <int>[];
    int vc = 0;

    for (final c in craters) {
      vc = _buildCrater(c, vertices, indices, vc);
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

  /// Render all craters as one batched, depth-tested mesh.
  void render(WebGLRenderer renderer, Camera3D camera) {
    if (_mesh == null) return;
    renderer.render(_mesh!, _transform, camera);
  }

  // ==================== PRIVATE ====================

  /// Build geometry for one crater; returns updated vertex counter.
  int _buildCrater(
    ImpactCraterData c,
    List<double> verts,
    List<int> idxs,
    int vc,
  ) {
    // Deterministic pseudo-random seed from crater world position.
    // Reason: same seed every frame → debris never jitters.
    final seed = (c.x * 73856093).toInt() ^ (c.z * 19349663).toInt();
    final g = c.glowIntensity;
    final age = c.ageFraction;

    // ── 1. Scorched glow disc (hexagonal fan) ────────────────────────────────
    // Color transitions: orange-red (scorching) → muted purple → dark ash
    final centR = _lerp(0.15, 0.95, g);
    final centG = _lerp(0.04, 0.20, g * 0.6);
    final centB = _lerp(0.04, 0.30, g * 0.8);
    const discRadius = 2.2;
    const discY = 0.04; // Slight lift to avoid z-fighting with terrain

    // Centre vertex
    verts.addAll([c.x, c.y + discY, c.z, centR, centG, centB]);
    final centIdx = vc++;

    // 6 rim vertices fade to cold ash
    final edgeR = _lerp(0.08, 0.30, g) * (1.0 - age * 0.6);
    final edgeG = _lerp(0.03, 0.07, g) * (1.0 - age * 0.6);
    final edgeB = _lerp(0.03, 0.08, g) * (1.0 - age * 0.6);
    const segments = 6;
    for (int i = 0; i <= segments; i++) {
      final ang = i / segments * 2 * math.pi;
      verts.addAll([
        c.x + math.cos(ang) * discRadius,
        c.y + discY,
        c.z + math.sin(ang) * discRadius,
        edgeR, edgeG, edgeB,
      ]);
      if (i > 0) {
        idxs.addAll([centIdx, vc - 1, vc]);
      }
      vc++;
    }

    // ── 2. Ejecta diamonds (8 flat quads radiating from rim) ─────────────────
    const ejCount = 8;
    const ejDist = 2.5;
    const ejHalfLen = 0.85;
    const ejHalfWid = 0.35;
    const ejY = 0.06;
    final ejR = _lerp(0.10, 0.42, g) * (1.0 - age * 0.45);
    final ejG = _lerp(0.04, 0.08, g) * (1.0 - age * 0.45);
    final ejB = _lerp(0.04, 0.08, g) * (1.0 - age * 0.45);

    for (int i = 0; i < ejCount; i++) {
      // Deterministic angular offset for each ejecta piece
      final offsetFrac = ((seed >> i & 0x7F) / 127.0 - 0.5) * 0.35;
      final ang = (i / ejCount + offsetFrac) * 2 * math.pi;
      final ca = math.cos(ang);
      final sa = math.sin(ang);
      final cx = c.x + ca * ejDist;
      final cz = c.z + sa * ejDist;

      // Diamond: tip (outward), left, base (inward), right
      final tipX = cx + ca * ejHalfLen;
      final tipZ = cz + sa * ejHalfLen;
      final baseX = cx - ca * ejHalfLen * 0.45;
      final baseZ = cz - sa * ejHalfLen * 0.45;
      final leftX = cx - sa * ejHalfWid;
      final leftZ = cz + ca * ejHalfWid;
      final rightX = cx + sa * ejHalfWid;
      final rightZ = cz - ca * ejHalfWid;

      verts.addAll([tipX, c.y + ejY, tipZ, ejR * 0.55, ejG * 0.55, ejB * 0.55]);
      verts.addAll([leftX, c.y + ejY, leftZ, ejR, ejG, ejB]);
      verts.addAll([baseX, c.y + ejY, baseZ, ejR, ejG, ejB]);
      verts.addAll([rightX, c.y + ejY, rightZ, ejR, ejG, ejB]);
      idxs.addAll([vc, vc + 1, vc + 2, vc, vc + 2, vc + 3]);
      vc += 4;
    }

    // ── 3. Rock shards (4 cross-shaped standing debris pieces) ───────────────
    // Cross-shape = two perpendicular vertical quads — readable from any angle.
    const rockCount = 4;
    const rockHalfW = 0.22;

    for (int i = 0; i < rockCount; i++) {
      // Deterministic position per shard from seed
      final angSeed = (seed >> (i * 4) & 0xFF) / 255.0;
      final distSeed = (seed >> (i * 4 + 1) & 0xFF) / 255.0;
      final htSeed = (seed >> (i * 4 + 2) & 0xFF) / 255.0;
      final ang = angSeed * 2 * math.pi;
      final dist = 1.0 + distSeed * 2.2;
      final rx = c.x + math.cos(ang) * dist;
      final rz = c.z + math.sin(ang) * dist;
      final ry = c.y;
      // Rock height shrinks as crater ages (debris settles / erodes)
      final rh = (0.30 + htSeed * 0.55) * (1.0 - age * 0.35);

      // Color: dark basalt with orange-red glow tint when fresh
      final rr = _lerp(0.13, 0.55, g * (1.0 - age * 0.7));
      final rg = _lerp(0.07, 0.11, g * 0.4 * (1.0 - age * 0.7));
      final rb = _lerp(0.05, 0.09, g * 0.3 * (1.0 - age * 0.7));

      // Slab A: spans X axis
      verts.addAll([rx - rockHalfW, ry, rz, rr * 0.55, rg * 0.55, rb * 0.55]);
      verts.addAll([rx + rockHalfW, ry, rz, rr * 0.55, rg * 0.55, rb * 0.55]);
      verts.addAll([rx + rockHalfW, ry + rh, rz, rr, rg, rb]);
      verts.addAll([rx - rockHalfW, ry + rh, rz, rr, rg, rb]);
      idxs.addAll([vc, vc + 1, vc + 2, vc, vc + 2, vc + 3]);
      vc += 4;

      // Slab B: spans Z axis (perpendicular to A — cross shape)
      verts.addAll([rx, ry, rz - rockHalfW, rr * 0.55, rg * 0.55, rb * 0.55]);
      verts.addAll([rx, ry, rz + rockHalfW, rr * 0.55, rg * 0.55, rb * 0.55]);
      verts.addAll([rx, ry + rh, rz + rockHalfW, rr, rg, rb]);
      verts.addAll([rx, ry + rh, rz - rockHalfW, rr, rg, rb]);
      idxs.addAll([vc, vc + 1, vc + 2, vc, vc + 2, vc + 3]);
      vc += 4;
    }

    return vc;
  }

  static double _lerp(double a, double b, double t) =>
      a + (b - a) * t.clamp(0.0, 1.0);
}
