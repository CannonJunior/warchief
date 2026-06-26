import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../state/cloud_config.dart';

/// Individual cloud puff within a cloud cluster.
class _CloudPuff {
  double x, y, z;
  double size;
  double r, g, b, a;

  _CloudPuff({
    required this.x, required this.y, required this.z,
    required this.size,
    required this.r, required this.g, required this.b, required this.a,
  });
}

/// A cluster of puffs forming one cloud.
class _CloudCluster {
  double cx, cz;
  double altitude;
  final List<_CloudPuff> puffs;

  _CloudCluster({
    required this.cx, required this.cz, required this.altitude,
    required this.puffs,
  });
}

/// Simple cloud system using flat billboard quads rendered with the standard
/// vertex-colored mesh pipeline. Generates cumulus-style cloud clusters at
/// fixed altitudes and drifts them with the wind.
class CloudSystem {
  final math.Random _rng = math.Random(0xC10D);
  final List<_CloudCluster> _clusters = [];
  bool _generated = false;

  Mesh? _mesh;
  final Transform3d _transform = Transform3d(position: Vector3(0, 0, 0));

  /// Accumulated wind drift applied via transform offset instead of
  /// per-puff position mutation, avoiding a full mesh rebuild each frame.
  double _driftX = 0.0;
  double _driftZ = 0.0;

  /// Reusable vertex/index buffers
  final List<double> _vertices = [];
  final List<int> _indices = [];

  bool get isGenerated => _generated;

  void generate() {
    _clusters.clear();
    _driftX = 0.0;
    _driftZ = 0.0;
    final cfg = globalCloudConfig;
    final cloudCount = cfg?.cloudCount ?? 18;
    final spawnRadius = cfg?.spawnRadius ?? 300.0;
    final altMin = cfg?.altitudeMin ?? 55.0;
    final altMax = cfg?.altitudeMax ?? 90.0;
    final puffsMin = cfg?.puffsPerCloudMin ?? 5;
    final puffsMax = cfg?.puffsPerCloudMax ?? 12;
    final pSizeMin = cfg?.puffSizeMin ?? 8.0;
    final pSizeMax = cfg?.puffSizeMax ?? 22.0;
    for (int i = 0; i < cloudCount; i++) {
      final cx = (_rng.nextDouble() - 0.5) * spawnRadius * 2;
      final cz = (_rng.nextDouble() - 0.5) * spawnRadius * 2;
      final alt = altMin + _rng.nextDouble() * (altMax - altMin);
      final puffCount = puffsMin + _rng.nextInt(puffsMax - puffsMin + 1);

      final puffs = <_CloudPuff>[];
      final clusterRadius = 10.0 + _rng.nextDouble() * 15.0;
      for (int j = 0; j < puffCount; j++) {
        final angle = _rng.nextDouble() * math.pi * 2;
        final dist = _rng.nextDouble() * clusterRadius;
        final ox = math.cos(angle) * dist;
        final oz = math.sin(angle) * dist;
        final oy = (_rng.nextDouble() - 0.3) * clusterRadius * 0.4;
        final size = pSizeMin + _rng.nextDouble() * (pSizeMax - pSizeMin);

        // Reason: top puffs are bright white (sunlit), bottom puffs are darker
        // blue-grey (shadowed underside), matching real cumulus shading.
        final heightFrac = (oy / (clusterRadius * 0.4) + 1.0) * 0.5;
        final lit = heightFrac.clamp(0.0, 1.0);
        final cr = 0.75 + lit * 0.20;
        final cg = 0.78 + lit * 0.17;
        final cb = 0.84 + lit * 0.11;

        puffs.add(_CloudPuff(
          x: cx + ox, y: alt + oy, z: cz + oz,
          size: size,
          r: cr, g: cg, b: cb,
          a: 0.35 + _rng.nextDouble() * 0.20,
        ));
      }
      _clusters.add(_CloudCluster(cx: cx, cz: cz, altitude: alt, puffs: puffs));
    }
    _generated = true;
    _rebuildMesh();
  }

  void update(double dt, double windAngle, double windStrength) {
    if (!_generated) return;
    final driftSpeed = globalCloudConfig?.driftSpeed ?? 0.4;
    _driftX += math.cos(windAngle) * windStrength * driftSpeed * dt;
    _driftZ += math.sin(windAngle) * windStrength * driftSpeed * dt;
    _transform.position.x = _driftX;
    _transform.position.z = _driftZ;
  }

  void render(WebGLRenderer renderer, Camera3D camera) {
    final mesh = _mesh;
    if (mesh == null) return;

    final gl = renderer.gl;
    gl.enable(0x0BE2); // GL_BLEND
    gl.blendFunc(0x0302, 0x0303); // SRC_ALPHA, ONE_MINUS_SRC_ALPHA
    gl.depthMask(false);

    renderer.render(mesh, _transform, camera);

    gl.depthMask(true);
    gl.disable(0x0BE2);
  }

  void _rebuildMesh() {
    _vertices.clear();
    _indices.clear();
    int vc = 0;

    for (final cluster in _clusters) {
      for (final p in cluster.puffs) {
        final s = p.size;
        final r = p.r * p.a;
        final g = p.g * p.a;
        final b = p.b * p.a;

        // Flat horizontal quad (cloud billboard lying flat in XZ plane)
        _vertices.addAll([
          p.x - s, p.y, p.z - s, r, g, b,
          p.x + s, p.y, p.z - s, r, g, b,
          p.x + s, p.y, p.z + s, r, g, b,
          p.x - s, p.y, p.z + s, r, g, b,
        ]);
        _indices.addAll([vc, vc + 1, vc + 2, vc, vc + 2, vc + 3]);
        vc += 4;
      }
    }

    if (_vertices.isEmpty) {
      _mesh = null;
      return;
    }

    _mesh = Mesh.fromVerticesAndIndices(
      vertices: _vertices,
      indices: _indices,
      vertexStride: 6,
    );
  }
}

/// Global cloud system singleton.
CloudSystem? globalCloudSystem;
