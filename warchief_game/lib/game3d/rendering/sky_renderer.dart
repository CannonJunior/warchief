import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../state/comet_state.dart';
import '../state/comet_config.dart';
import 'comet_tail_particles.dart';

/// Sky and comet billboard renderer.
///
/// Renders two world-space elements:
///   1. A large sky quad (gradient from zenith to horizon) that replaces the
///      flat clearColor background visible above terrain.
///   2. A composite comet billboard (coma + ion tail + dust tail) that scales
///      with cometIntensity and moves across the sky with the orbital phase.
///
/// Both elements use depth-writes-off so they never occlude 3D geometry.
class SkyRenderer {
  Mesh? _skyMesh;
  Mesh? _cometMesh;

  /// Last intensity at which meshes were built (dirty flag threshold = 0.02)
  double _lastBuiltIntensity = -1.0;
  double _lastBuiltPhase = -1.0;

  final Transform3d _skyTransform = Transform3d(
    position: Vector3(0, 120, 0),
  );

  Transform3d _cometTransform = Transform3d(
    position: Vector3(400, 180, 400),
  );

  final CometTailParticleSystem _tailParticles = CometTailParticleSystem();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Call once per frame to rebuild meshes and advance the tail particle simulation.
  ///
  /// [dt] is used for particle physics; use an approximate value (e.g. 0.016)
  /// when the exact frame delta is unavailable.
  void update(CometState cometState, double dt) {
    final intensityDelta = (cometState.cometIntensity - _lastBuiltIntensity).abs();
    final phaseDelta = (cometState.orbitalPhase - _lastBuiltPhase).abs();

    // Reason: rebuild threshold of 0.02 balances visual smoothness vs CPU cost
    if (intensityDelta > 0.02 || phaseDelta > 0.005) {
      _buildSkyMesh(cometState);
      _buildCometMesh(cometState);
      _lastBuiltIntensity = cometState.cometIntensity;
      _lastBuiltPhase = cometState.orbitalPhase;
    }

    // Advance streaming tail particles every frame
    _tailParticles.update(dt, cometState);
  }

  /// Render the sky gradient background quad.
  ///
  /// Must be called BEFORE terrain rendering so the sky sits behind everything.
  /// Depth writes are disabled so sky never occludes foreground geometry.
  void renderSky(
    WebGLRenderer renderer,
    Camera3D camera,
    CometState cometState,
  ) {
    if (_skyMesh == null) _buildSkyMesh(cometState);
    final mesh = _skyMesh;
    if (mesh == null) return;

    final gl = renderer.gl;
    gl.disable(0x0B71); // GL_DEPTH_TEST off — sky is always behind everything
    gl.depthMask(false);

    renderer.render(mesh, _skyTransform, camera);

    gl.enable(0x0B71); // GL_DEPTH_TEST back on
    gl.depthMask(true);
  }

  /// Render the comet: particle tail streaks + static billboard (coma + tails).
  ///
  /// Must be called AFTER opaque terrain/characters so additive blend works.
  /// Render order: tail particles first (behind coma), then the bright billboard.
  void renderComet(
    WebGLRenderer renderer,
    Camera3D camera,
    CometState cometState,
  ) {
    if (cometState.cometIntensity < 0.01) return;

    final gl = renderer.gl;
    gl.enable(0x0BE2); // GL_BLEND
    gl.blendFunc(0x0302, 0x0001); // SRC_ALPHA, ONE (additive glow)
    gl.depthMask(false);

    // Render dynamic particle tail first (behind the bright coma)
    _tailParticles.render(renderer, camera);

    // Render static comet billboard (coma + ion/dust tails) on top
    if (_cometMesh == null) _buildCometMesh(cometState);
    final mesh = _cometMesh;
    if (mesh != null) {
      _updateCometTransform(cometState);
      renderer.render(mesh, _cometTransform, camera);
    }

    gl.depthMask(true);
    gl.disable(0x0BE2);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _buildSkyMesh(CometState cometState) {
    final config = globalCometConfig;
    final intensity = cometState.cometIntensity;

    // Base horizon color lerped toward comet tint during flyby
    final tintStrength = (config?.cometTintStrength ?? 0.6) * intensity;

    final zen = config?.zenithColor ?? [0.05, 0.01, 0.10];
    final hor = config?.horizonColorDay ?? [0.12, 0.06, 0.04];

    // During comet flyby, horizon shifts toward deep purple void
    final comaC = config?.comaColor ?? [0.85, 0.70, 1.00];
    final zr = _lerp(zen[0], comaC[0] * 0.1, tintStrength * 0.5);
    final zg = _lerp(zen[1], comaC[1] * 0.05, tintStrength * 0.5);
    final zb = _lerp(zen[2], comaC[2] * 0.15, tintStrength * 0.5);
    final hr = _lerp(hor[0], comaC[0] * 0.05, tintStrength * 0.3);
    final hg = _lerp(hor[1], comaC[1] * 0.02, tintStrength * 0.3);
    final hb = _lerp(hor[2], comaC[2] * 0.08, tintStrength * 0.3);

    // Sky: large flat quad, 2000x2000, center at Y=120.
    // Centre vertex = zenith color; corners = horizon color.
    const half = 1000.0;
    final vertices = <double>[
      // Centre (zenith)
      0,   0, 0,    zr, zg, zb,
      // NW corner
      -half, 0, -half, hr, hg, hb,
      // NE corner
       half, 0, -half, hr, hg, hb,
      // SE corner
       half, 0,  half, hr, hg, hb,
      // SW corner
      -half, 0,  half, hr, hg, hb,
    ];
    // Fan triangles from centre
    final indices = <int>[0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1];

    _skyMesh = Mesh.fromVerticesAndIndices(
      vertices: vertices,
      indices: indices,
      vertexStride: 6,
    );
  }

  void _buildCometMesh(CometState cometState) {
    final config = globalCometConfig;
    final intensity = cometState.cometIntensity;
    if (intensity < 0.01) {
      _cometMesh = null;
      return;
    }

    final comaC = config?.comaColor ?? [0.85, 0.70, 1.00];
    final ionC = config?.ionTailColor ?? [0.50, 0.30, 1.00];
    final dustC = config?.dustTailColor ?? [0.70, 0.55, 0.90];

    final comaMinSize = config?.comaMinSize ?? 0.02;
    final comaMaxSize = config?.comaMaxSize ?? 0.15;
    final ionMaxLen = config?.ionTailMaxLength ?? 0.5;
    final dustMaxLen = config?.dustTailMaxLength ?? 0.35;

    // Sizes scale with intensity
    final comaSize = _lerp(comaMinSize, comaMaxSize, intensity) * 30.0; // world units
    final ionLen = ionMaxLen * intensity * 200.0;
    final dustLen = dustMaxLen * intensity * 160.0;
    final brightness = intensity;

    final vertices = <double>[];
    final indices = <int>[];
    int vc = 0;

    // ── Coma (bright central quad) ─────────────────────────────────────────
    final cr = comaC[0] * brightness;
    final cg = comaC[1] * brightness;
    final cb = comaC[2] * brightness;

    vertices.addAll([-comaSize, -comaSize, 0, cr, cg, cb]);
    vertices.addAll([ comaSize, -comaSize, 0, cr, cg, cb]);
    vertices.addAll([ comaSize,  comaSize, 0, cr, cg, cb]);
    vertices.addAll([-comaSize,  comaSize, 0, cr, cg, cb]);
    indices.addAll([vc, vc+1, vc+2, vc, vc+2, vc+3]);
    vc += 4;

    // ── Ion tail (thin elongated quad pointing away from primary sun +X) ───
    final ir = ionC[0] * brightness * 0.8;
    final ig = ionC[1] * brightness * 0.8;
    final ib = ionC[2] * brightness * 0.8;
    final ionWidth = comaSize * 0.4;

    vertices.addAll([-ionWidth, 0, 0,       ir, ig, ib]);
    vertices.addAll([ ionWidth, 0, 0,       ir, ig, ib]);
    vertices.addAll([ ionWidth, 0, -ionLen, 0,  0,  0 ]); // fades to black
    vertices.addAll([-ionWidth, 0, -ionLen, 0,  0,  0 ]);
    indices.addAll([vc, vc+1, vc+2, vc, vc+2, vc+3]);
    vc += 4;

    // ── Dust tail (wider, angled ~20° from ion tail) ───────────────────────
    final dr = dustC[0] * brightness * 0.6;
    final dg = dustC[1] * brightness * 0.6;
    final db = dustC[2] * brightness * 0.6;
    final dustWidth = comaSize * 0.7;
    final dustAngleRad = 20.0 * math.pi / 180.0;
    final dustEndX = -math.sin(dustAngleRad) * dustLen;
    final dustEndZ = -math.cos(dustAngleRad) * dustLen;

    vertices.addAll([-dustWidth, 0, 0,        dr, dg, db]);
    vertices.addAll([ dustWidth, 0, 0,        dr, dg, db]);
    vertices.addAll([ dustEndX + dustWidth * 0.5, 0, dustEndZ, 0, 0, 0]);
    vertices.addAll([ dustEndX - dustWidth * 0.5, 0, dustEndZ, 0, 0, 0]);
    indices.addAll([vc, vc+1, vc+2, vc, vc+2, vc+3]);
    vc += 4;

    _cometMesh = Mesh.fromVerticesAndIndices(
      vertices: vertices,
      indices: indices,
      vertexStride: 6,
    );
  }

  void _updateCometTransform(CometState cometState) {
    // Comet orbits a large circle far from origin at high altitude
    final azimuth = cometState.skyAzimuthFraction * 2.0 * math.pi;
    final elevationFrac = cometState.skyElevationFraction;
    const orbitRadius = 450.0;
    const minAlt = 150.0;
    const maxAlt = 220.0;

    final cx = math.cos(azimuth) * orbitRadius;
    final cz = math.sin(azimuth) * orbitRadius;
    final cy = minAlt + (maxAlt - minAlt) * elevationFrac;

    _cometTransform = Transform3d(position: Vector3(cx, cy, cz));
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0.0, 1.0);
}
