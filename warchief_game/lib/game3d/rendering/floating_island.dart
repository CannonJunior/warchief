import 'dart:math' as math;
import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../state/game_config.dart';

/// Floating Island - procedurally generated floating landmass
///
/// A 100×100 world-unit island hovering 100 yards above the warchief's
/// start position, with:
/// - Rolling grassy hills on top (green/brown per-vertex colors)
/// - Steep jagged rock walls on the sides
/// - Irregular stalactite spikes hanging from the bottom
class FloatingIsland {
  FloatingIsland._();

  // ==================== CONSTANTS ====================

  /// Top surface grid resolution (vertices per side)
  static const int _gridN = 21;

  /// Island side length in world units
  static const double _islandSize = 100.0;

  /// World units per grid cell  ((gridN-1) cells span the island)
  static const double _tileSize = _islandSize / (_gridN - 1);

  /// Maximum hill height above local base
  static const double _maxHillHeight = 8.0;

  /// How far below base the side walls and stalactites begin
  static const double _wallBase = -3.0;

  /// Number of stalactites per side in the stalactite grid
  static const int _stalGrid = 8;

  // ==================== PUBLIC API ====================

  /// Build the island mesh and a positioned transform.
  ///
  /// Returns (mesh, transform) where the transform centres the island
  /// 100 world units above the player's configured start position.
  static (Mesh, Transform3d) create() {
    final start = GameConfig.playerStartPosition;
    final islandPos = Vector3(start.x, start.y + 100.0, start.z);

    final verts = <double>[];
    final idxs = <int>[];

    // Reason: _addTopSurface returns the height array so _addSideWalls can
    // look up perimeter heights without a separate _computeHeights pass that
    // would recompute the same XZ coordinates a second time.
    final heights = _addTopSurface(verts, idxs);
    _addSideWalls(verts, idxs, heights);
    _addStalactites(verts, idxs);

    final mesh = Mesh.fromVerticesAndIndices(
      vertices: verts,
      indices: idxs,
      vertexStride: 6, // x, y, z, r, g, b
    );
    final transform = Transform3d(position: islandPos);
    return (mesh, transform);
  }

  // ==================== NOISE ====================

  /// Return the world-space Y of the island surface directly above (wx, wz),
  /// or `null` if that XZ position is outside the island bounds.
  ///
  /// Used by the physics system to provide ground collision on the island.
  static double? surfaceHeightAt(double wx, double wz) {
    final start = GameConfig.playerStartPosition;
    final lx = wx - start.x;
    final lz = wz - start.z;
    final half = (_gridN - 1) / 2.0 * _tileSize; // 50.0
    if (lx < -half || lx > half || lz < -half || lz > half) return null;
    return (start.y + 100.0) + _hillNoise(lx, lz);
  }

  /// Layered sin/cos noise that produces rolling hills in the 0.._maxHillHeight range.
  static double _hillNoise(double x, double z) {
    // Reason: multiple octaves with different frequencies give natural-looking
    // rolling hills without requiring an actual Perlin implementation.
    final nx = x * 0.045;
    final nz = z * 0.045;
    double n = math.sin(nx * 1.00) * math.cos(nz * 1.00) * 0.50
             + math.sin(nx * 2.30 + 1.40) * math.cos(nz * 1.90 + 0.70) * 0.28
             + math.sin(nx * 4.70 + 2.80) * math.cos(nz * 3.80 + 1.60) * 0.14
             + math.sin(nx * 9.10 + 0.40) * math.cos(nz * 9.50 + 2.20) * 0.08;
    // Remap from roughly [-1, 1] to [0, _maxHillHeight]
    return ((n + 1.0) / 2.0) * _maxHillHeight;
  }

  // ==================== TOP SURFACE ====================

  /// Build the top surface grid and return the height map for side-wall use.
  ///
  /// Computes XZ world coordinates once per vertex and uses them both to
  /// evaluate hill height and to write the vertex position, avoiding the
  /// redundant XZ recalculation that a separate _computeHeights pass would cause.
  ///
  /// Returns a row-major Float64List indexed as [row * _gridN + col].
  static Float64List _addTopSurface(List<double> verts, List<int> idxs) {
    final base = verts.length ~/ 6;
    final half = (_gridN - 1) / 2.0;
    final heights = Float64List(_gridN * _gridN);

    for (int r = 0; r < _gridN; r++) {
      for (int c = 0; c < _gridN; c++) {
        final x = (c - half) * _tileSize;
        final z = (r - half) * _tileSize;
        final y = _hillNoise(x, z);
        heights[r * _gridN + c] = y;
        final col = _grassColor(y, x, z);
        verts.addAll([x, y, z, col.x, col.y, col.z]);
      }
    }

    for (int r = 0; r < _gridN - 1; r++) {
      for (int c = 0; c < _gridN - 1; c++) {
        final tl = base + r * _gridN + c;
        final tr = tl + 1;
        final bl = tl + _gridN;
        final br = bl + 1;
        idxs.addAll([tl, bl, tr, tr, bl, br]);
      }
    }

    return heights;
  }

  /// Grass color: lush green at low elevations, dry brown at peaks.
  ///
  /// Returns a Vector3(r, g, b) consistent with the rest of the rendering
  /// pipeline's convention for passing colors as Vector3.
  static Vector3 _grassColor(double y, double x, double z) {
    final t = (y / _maxHillHeight).clamp(0.0, 1.0);
    // Low:  (0.18, 0.60, 0.13)  — rich grass
    // High: (0.52, 0.38, 0.16)  — dry soil / rock
    final rv = 0.18 + t * 0.34;
    final gv = 0.60 - t * 0.22;
    final bv = 0.13 + t * 0.03;
    // Small position-dependent variation to break up uniformity
    final vary = math.sin(x * 0.4 + z * 0.3) * 0.03;
    return Vector3(
      (rv + vary).clamp(0.0, 1.0),
      (gv + vary).clamp(0.0, 1.0),
      bv.clamp(0.0, 1.0),
    );
  }

  // ==================== SIDE WALLS ====================

  static void _addSideWalls(
    List<double> verts,
    List<int> idxs,
    Float64List heights,
  ) {
    final half = (_gridN - 1) / 2.0;

    void addQuad(
      double x1, double y1, double z1,
      double x2, double y2, double z2,
    ) {
      final base = verts.length ~/ 6;
      // Top edge uses a mid-rock colour; bottom edge is darker
      const rT = 0.32; const gT = 0.27; const bT = 0.22;
      const rB = 0.18; const gB = 0.15; const bB = 0.11;
      verts.addAll([x1, y1,       z1, rT, gT, bT]);
      verts.addAll([x2, y2,       z2, rT, gT, bT]);
      verts.addAll([x2, _wallBase, z2, rB, gB, bB]);
      verts.addAll([x1, _wallBase, z1, rB, gB, bB]);
      idxs.addAll([base, base + 1, base + 2, base, base + 2, base + 3]);
    }

    // Walk all four perimeter edges.  Winding order flips on opposite edges
    // so that all wall quads face outward.

    // North edge  (row = 0, col ascending → faces -Z)
    for (int c = 0; c < _gridN - 1; c++) {
      final x1 = (c     - half) * _tileSize;
      final x2 = (c + 1 - half) * _tileSize;
      final z  = (0     - half) * _tileSize;
      addQuad(x2, heights[c + 1], z,
              x1, heights[c],     z);
    }

    // South edge  (row = N-1, col descending → faces +Z)
    for (int c = _gridN - 2; c >= 0; c--) {
      final x1 = (c     - half) * _tileSize;
      final x2 = (c + 1 - half) * _tileSize;
      final z  = (_gridN - 1 - half) * _tileSize;
      addQuad(x1, heights[(_gridN - 1) * _gridN + c],     z,
              x2, heights[(_gridN - 1) * _gridN + c + 1], z);
    }

    // West edge  (col = 0, row descending → faces -X)
    for (int r = _gridN - 2; r >= 0; r--) {
      final z1 = (r     - half) * _tileSize;
      final z2 = (r + 1 - half) * _tileSize;
      final x  = (0     - half) * _tileSize;
      addQuad(x, heights[r     * _gridN], z1,
              x, heights[(r+1) * _gridN], z2);
    }

    // East edge  (col = N-1, row ascending → faces +X)
    for (int r = 0; r < _gridN - 1; r++) {
      final z1 = (r     - half) * _tileSize;
      final z2 = (r + 1 - half) * _tileSize;
      final x  = (_gridN - 1 - half) * _tileSize;
      addQuad(x, heights[r     * _gridN + (_gridN - 1)], z1,
              x, heights[(r+1) * _gridN + (_gridN - 1)], z2);
    }
  }

  // ==================== STALACTITES ====================

  static void _addStalactites(List<double> verts, List<int> idxs) {
    // Distribute stalactites on a coarse grid, then jitter positions.
    // The stalactites hang from _wallBase downward with varying lengths.
    final step = _islandSize / (_stalGrid - 1);

    for (int r = 0; r < _stalGrid; r++) {
      for (int c = 0; c < _stalGrid; c++) {
        // Base centre in island-local XZ
        final bx = (c - (_stalGrid - 1) / 2.0) * step;
        final bz = (r - (_stalGrid - 1) / 2.0) * step;

        // Pseudorandom jitter using stable sin/cos of position
        final seed = bx * 0.17 + bz * 0.31 + r * 1.7 + c * 2.3;
        final jx = math.sin(seed * 1.3) * step * 0.35;
        final jz = math.sin(seed * 2.7) * step * 0.35;
        final cx = bx + jx;
        final cz = bz + jz;

        // Skip if jitter pushed outside the island
        if (cx.abs() > 47.0 || cz.abs() > 47.0) continue;

        // Depth: deterministic-random between -12 and -55
        final depthN = (math.sin(seed * 0.6) + 1.0) / 2.0;
        final tipY = _wallBase - 12.0 - depthN * 43.0;

        // Base width proportional to depth so long stalactites are thicker
        final baseW = 3.5 + depthN * 5.5;

        _addOneStalactite(verts, idxs, cx, cz, tipY, baseW);
      }
    }
  }

  /// Build a single 4-sided pyramid stalactite: square base at [_wallBase] → point at tip.
  static void _addOneStalactite(
    List<double> verts,
    List<int> idxs,
    double cx, double cz,
    double tipY,
    double baseW,
  ) {
    final base = verts.length ~/ 6;

    // Rock colours: base slightly lighter than tip
    const rS = 0.25; const gS = 0.21; const bS = 0.17; // sides
    const rT = 0.14; const gT = 0.11; const bT = 0.09; // tip

    final hw = baseW / 2.0;

    // Jagged-looking base: slight rotational offset on each corner
    // Reason: pure axis-aligned squares look too artificial; a small twist
    // breaks the symmetry without requiring a noise texture.
    final twist = math.sin(cx * 0.4 + cz * 0.6) * hw * 0.25;

    verts.addAll([cx - hw + twist, _wallBase, cz - hw - twist, rS, gS, bS]); // 0
    verts.addAll([cx + hw + twist, _wallBase, cz - hw + twist, rS, gS, bS]); // 1
    verts.addAll([cx + hw - twist, _wallBase, cz + hw + twist, rS, gS, bS]); // 2
    verts.addAll([cx - hw - twist, _wallBase, cz + hw - twist, rS, gS, bS]); // 3
    verts.addAll([cx,              tipY,      cz,              rT, gT, bT]); // 4 tip

    // Four triangular faces
    idxs.addAll([base + 0, base + 1, base + 4]);
    idxs.addAll([base + 1, base + 2, base + 4]);
    idxs.addAll([base + 2, base + 3, base + 4]);
    idxs.addAll([base + 3, base + 0, base + 4]);

    // Closed flat base (visible looking up from below)
    idxs.addAll([base + 0, base + 2, base + 1]);
    idxs.addAll([base + 0, base + 3, base + 2]);
  }
}
