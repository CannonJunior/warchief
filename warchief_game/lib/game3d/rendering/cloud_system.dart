import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';

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
  static const int _cloudCount = 18;
  static const double _spawnRadius = 300.0;
  static const double _altitudeMin = 55.0;
  static const double _altitudeMax = 90.0;
  static const int _puffsPerCloudMin = 5;
  static const int _puffsPerCloudMax = 12;
  static const double _puffSizeMin = 8.0;
  static const double _puffSizeMax = 22.0;
  static const double _driftSpeed = 0.4;

  final math.Random _rng = math.Random(0xC10D);
  final List<_CloudCluster> _clusters = [];
  bool _generated = false;

  Mesh? _mesh;
  final Transform3d _transform = Transform3d(position: Vector3(0, 0, 0));

  /// Reusable vertex/index buffers
  final List<double> _vertices = [];
  final List<int> _indices = [];

  bool get isGenerated => _generated;

  void generate() {
    _clusters.clear();
    for (int i = 0; i < _cloudCount; i++) {
      final cx = (_rng.nextDouble() - 0.5) * _spawnRadius * 2;
      final cz = (_rng.nextDouble() - 0.5) * _spawnRadius * 2;
      final alt = _altitudeMin + _rng.nextDouble() * (_altitudeMax - _altitudeMin);
      final puffCount = _puffsPerCloudMin +
          _rng.nextInt(_puffsPerCloudMax - _puffsPerCloudMin + 1);

      final puffs = <_CloudPuff>[];
      final clusterRadius = 10.0 + _rng.nextDouble() * 15.0;
      for (int j = 0; j < puffCount; j++) {
        final angle = _rng.nextDouble() * math.pi * 2;
        final dist = _rng.nextDouble() * clusterRadius;
        final ox = math.cos(angle) * dist;
        final oz = math.sin(angle) * dist;
        final oy = (_rng.nextDouble() - 0.3) * clusterRadius * 0.4;
        final size = _puffSizeMin + _rng.nextDouble() * (_puffSizeMax - _puffSizeMin);

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
  }

  void update(double dt, double windAngle, double windStrength) {
    if (!_generated) return;
    final dx = math.cos(windAngle) * windStrength * _driftSpeed * dt;
    final dz = math.sin(windAngle) * windStrength * _driftSpeed * dt;
    for (final cluster in _clusters) {
      cluster.cx += dx;
      cluster.cz += dz;
      for (final p in cluster.puffs) {
        p.x += dx;
        p.z += dz;
      }
    }
    _rebuildMesh();
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
