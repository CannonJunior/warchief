import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../state/game_config.dart';

/// Tower mesh — a 7-floor octagonal stone tower rising from the floating island.
///
/// Geometry: exterior octagonal walls, solid floor platforms, exterior spiral
/// ramp (one quarter-turn per floor), and crenellated battlements on the roof.
///
/// All positions are in local space relative to the tower base; the returned
/// [Transform3d] places the base at the island surface centre.
class TowerMesh {
  TowerMesh._();

  // ==================== CONSTANTS ====================

  static const int floorCount = 7;
  static const double floorHeight = 8.0;
  static const double exteriorRadius = 12.0;
  static const double interiorRadius = 10.0;
  static const double totalHeight = floorCount * floorHeight; // 56.0
  static const int _octSides = 8;

  /// Tower centre X in world space (matches island centre).
  static double get centerX => GameConfig.playerStartPosition.x;

  /// Tower centre Z in world space (matches island centre).
  static double get centerZ => GameConfig.playerStartPosition.z;

  /// World Y where the tower base begins (~1.5 units above island base).
  static double get islandBaseY => GameConfig.playerStartPosition.y + 100.5;

  // ==================== PUBLIC API ====================

  /// Build the tower mesh and a positioned [Transform3d].
  ///
  /// Returns (mesh, transform) centred on the floating island.
  static (Mesh, Transform3d) create() {
    final start = GameConfig.playerStartPosition;

    final verts = <double>[];
    final idxs  = <int>[];

    _addFloorPlatforms(verts, idxs);
    _addExteriorWalls(verts, idxs);
    _addSpiralRamp(verts, idxs);
    _addBattlements(verts, idxs);

    final mesh      = Mesh.fromVerticesAndIndices(vertices: verts, indices: idxs, vertexStride: 6);
    final transform = Transform3d(position: Vector3(start.x, start.y + 100.5, start.z));
    return (mesh, transform);
  }

  // ==================== COLLISION HELPERS ====================

  /// Return the tower floor world-Y that the player should stand on, or `null`
  /// if the player is outside the tower's octagonal footprint.
  ///
  /// Finds the highest floor platform at or below [playerY] so the player
  /// lands correctly when falling through the interior.
  static double? floorGroundAt(double wx, double wz, double playerY) {
    final dx = wx - centerX;
    final dz = wz - centerZ;
    if (dx * dx + dz * dz > exteriorRadius * exteriorRadius) return null;
    if (playerY < islandBaseY) return null;

    // Reason: iterate from highest floor down so we return the first (highest)
    // one at or below the player — that is the surface they'd land on.
    for (int f = floorCount; f >= 0; f--) {
      final floorY = islandBaseY + f * floorHeight;
      if (playerY >= floorY - 0.1) return floorY;
    }
    return islandBaseY;
  }

  /// Return the ramp surface world-Y at this XZ position that is at or below
  /// [playerY], or `null` if the player is outside the ramp's radial band.
  ///
  /// The ramp turns counter-clockwise from angle 0 at ground level to
  /// (floorCount × π/2) radians at the roof. For a given player angle, the
  /// function enumerates all ramp segments that pass through that bearing
  /// and returns the highest one below the player.
  static double? rampGroundAt(double wx, double wz, double playerY) {
    const rampInner   = exteriorRadius;
    const rampOuter   = exteriorRadius + 2.5;
    const rampTol     = 0.7; // radial tolerance beyond ramp edge
    const totalAngle  = floorCount * math.pi / 2.0;

    final dx   = wx - centerX;
    final dz   = wz - centerZ;
    final dist = math.sqrt(dx * dx + dz * dz);
    if (dist < rampInner - rampTol || dist > rampOuter + rampTol) return null;
    if (playerY < islandBaseY - 1.0) return null;

    // Bearing from tower centre to player, normalised to [0, 2π)
    double alpha = math.atan2(dz, dx);
    if (alpha < 0) alpha += 2 * math.pi;

    // Enumerate ramp passes through this bearing (at most 2 for 1.75 turns)
    double? bestH;
    for (int k = 0; k <= 2; k++) {
      final t = alpha + k * 2 * math.pi;
      if (t > totalAngle + 0.1) break;
      final h = islandBaseY + t * totalHeight / totalAngle;
      if (h <= playerY + 0.3 && (bestH == null || h > bestH)) {
        bestH = h;
      }
    }
    return bestH;
  }

  // ==================== GEOMETRY HELPERS ====================

  /// Octagon vertex XZ at [r] for side index [i] (0-7 counter-clockwise).
  static (double, double) _oct(int i, double r) {
    final a = i * math.pi / 4.0;
    return (r * math.cos(a), r * math.sin(a));
  }

  /// Append a quad (4 verts, 2 tris) with a flat colour.
  static void _quad(
    List<double> v, List<int> idx,
    double x1, double y1, double z1,
    double x2, double y2, double z2,
    double x3, double y3, double z3,
    double x4, double y4, double z4,
    double r, double g, double b,
  ) {
    final base = v.length ~/ 6;
    v.addAll([x1, y1, z1, r, g, b]);
    v.addAll([x2, y2, z2, r, g, b]);
    v.addAll([x3, y3, z3, r, g, b]);
    v.addAll([x4, y4, z4, r, g, b]);
    idx.addAll([base, base + 1, base + 2, base, base + 2, base + 3]);
  }

  // ==================== FLOOR PLATFORMS ====================

  /// Solid octagonal floor disc at each level (ground floor + one per upper floor + roof).
  static void _addFloorPlatforms(List<double> v, List<int> idx) {
    for (int f = 0; f <= floorCount; f++) {
      final y    = f * floorHeight;
      final base = v.length ~/ 6;

      v.addAll([0.0, y, 0.0, 0.55, 0.52, 0.48]); // Centre vertex
      for (int i = 0; i < _octSides; i++) {
        final (x, z) = _oct(i, exteriorRadius);
        v.addAll([x, y, z, 0.50, 0.47, 0.43]);
      }
      // Fan of 8 triangles
      for (int i = 0; i < _octSides; i++) {
        idx.addAll([base, base + 1 + i, base + 1 + (i + 1) % _octSides]);
      }
    }
  }

  // ==================== EXTERIOR WALLS ====================

  /// Stone octagonal walls per floor with vertical colour gradient.
  ///
  /// Door opening (face 4) is left open on the ground floor so the player
  /// has a visible entrance portal.
  static void _addExteriorWalls(List<double> v, List<int> idx) {
    for (int f = 0; f < floorCount; f++) {
      final yB = f * floorHeight;
      final yT = yB + floorHeight;

      for (int i = 0; i < _octSides; i++) {
        // Reason: skip door face on ground floor so there is a walkable entrance.
        if (f == 0 && i == 4) continue;

        final (x1, z1) = _oct(i, exteriorRadius);
        final (x2, z2) = _oct((i + 1) % _octSides, exteriorRadius);

        // Blue-grey at top, dark stone at base
        final base = v.length ~/ 6;
        v.addAll([x1, yT, z1, 0.46, 0.46, 0.52]);
        v.addAll([x2, yT, z2, 0.46, 0.46, 0.52]);
        v.addAll([x2, yB, z2, 0.28, 0.27, 0.32]);
        v.addAll([x1, yB, z1, 0.28, 0.27, 0.32]);
        idx.addAll([base, base + 1, base + 2, base, base + 2, base + 3]);
      }
    }
  }

  // ==================== SPIRAL RAMP ====================

  /// Exterior ramp spiralling 1/4 turn per floor from ground to roof.
  ///
  /// 56 steps gives a smooth arc at this scale. Each step is a flat quad
  /// slightly elevated relative to the previous one.
  static void _addSpiralRamp(List<double> v, List<int> idx) {
    const steps      = 56;
    const rampInner  = exteriorRadius;
    const rampOuter  = exteriorRadius + 2.5;
    const totalAngle = floorCount * math.pi / 2.0; // 1/4 turn × 7 floors

    for (int s = 0; s < steps; s++) {
      final t0 = s / steps;
      final t1 = (s + 1) / steps;
      final a0 = t0 * totalAngle;
      final a1 = t1 * totalAngle;
      final y0 = t0 * totalHeight;
      final y1 = t1 * totalHeight;

      final xi0 = rampInner * math.cos(a0); final zi0 = rampInner * math.sin(a0);
      final xi1 = rampInner * math.cos(a1); final zi1 = rampInner * math.sin(a1);
      final xo0 = rampOuter * math.cos(a0); final zo0 = rampOuter * math.sin(a0);
      final xo1 = rampOuter * math.cos(a1); final zo1 = rampOuter * math.sin(a1);

      _quad(v, idx, xi0, y0, zi0, xo0, y0, zo0, xo1, y1, zo1, xi1, y1, zi1, 0.38, 0.36, 0.40);
    }
  }

  // ==================== BATTLEMENTS ====================

  /// Crenellated battlements at the tower roof.
  ///
  /// Even-numbered octagon faces get a raised merlon block.
  static void _addBattlements(List<double> v, List<int> idx) {
    const yBase   = totalHeight;
    const merlonH = 1.8;

    for (int i = 0; i < _octSides; i++) {
      if (i % 2 != 0) continue; // Reason: alternating merlons = crenellation pattern

      final (x1, z1) = _oct(i, exteriorRadius - 1.0);
      final (x2, z2) = _oct((i + 1) % _octSides, exteriorRadius - 1.0);
      final (xo1, zo1) = _oct(i, exteriorRadius + 0.5);
      final (xo2, zo2) = _oct((i + 1) % _octSides, exteriorRadius + 0.5);

      // Top face of merlon
      _quad(v, idx,
        x1, yBase + merlonH, z1,  x2, yBase + merlonH, z2,
        xo2, yBase + merlonH, zo2, xo1, yBase + merlonH, zo1,
        0.50, 0.50, 0.55,
      );
      // Outer face (visible from outside)
      _quad(v, idx,
        xo1, yBase, zo1,  xo2, yBase, zo2,
        xo2, yBase + merlonH, zo2,  xo1, yBase + merlonH, zo1,
        0.42, 0.42, 0.48,
      );
    }
  }
}
