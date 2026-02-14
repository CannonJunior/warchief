import 'mesh.dart';
import '../models/building.dart';

/// Factory for generating procedural building meshes from tier definitions.
///
/// Buildings are composed of multiple parts: foundation, walls, roof, and door.
/// Uses [Mesh.fromVerticesAndIndices] with per-vertex coloring (same approach
/// as ley line mesh creation in render_system.dart).
///
/// Buildings are static geometry -- created once on placement or upgrade,
/// and cached by the existing [_MeshBuffers] cache in [WebGLRenderer].
class BuildingMesh {
  BuildingMesh._();

  /// Create a complete building mesh from a tier definition.
  ///
  /// Generates foundation, walls (with door cutout), and peaked roof
  /// as a single combined mesh with per-vertex colors.
  static Mesh createBuilding(BuildingTierDef tier) {
    final vertices = <double>[];
    final indices = <int>[];
    var vertexCount = 0;

    // Extract part definitions
    final foundPart = tier.getPart('foundation');
    final wallPart = tier.getPart('walls');
    final roofPart = tier.getPart('roof');
    final doorPart = tier.getPart('door');

    // Foundation dimensions (fallbacks for safety)
    final fWidth = _getNum(foundPart, 'width', 6.0);
    final fDepth = _getNum(foundPart, 'depth', 8.0);
    final fHeight = _getNum(foundPart, 'height', 0.3);
    final fColor = _getColor(foundPart, 'color', [0.45, 0.35, 0.20]);

    // Wall dimensions
    final wHeight = _getNum(wallPart, 'height', 3.0);
    final wThick = _getNum(wallPart, 'thickness', 0.3);
    final wColor = _getColor(wallPart, 'color', [0.55, 0.40, 0.25]);

    // Roof dimensions
    final rOverhang = _getNum(roofPart, 'overhang', 0.5);
    final rColor = _getColor(roofPart, 'color', [0.35, 0.25, 0.15]);

    // Door dimensions
    final dWidth = _getNum(doorPart, 'width', 1.2);
    final dHeight = _getNum(doorPart, 'height', 2.2);
    final dColor = _getColor(doorPart, 'color', [0.40, 0.30, 0.18]);

    // 1. Foundation (flat box at ground level)
    vertexCount = _addBox(
      vertices, indices, vertexCount,
      0.0, fHeight / 2, 0.0,
      fWidth, fHeight, fDepth,
      fColor[0], fColor[1], fColor[2],
    );

    // 2. Walls (4 walls with door cutout on front face)
    vertexCount = _addWalls(
      vertices, indices, vertexCount,
      fWidth, fDepth, fHeight, wHeight, wThick,
      wColor[0], wColor[1], wColor[2],
      dWidth, dHeight,
      dColor[0], dColor[1], dColor[2],
    );

    // 3. Peaked roof
    vertexCount = _addPeakedRoof(
      vertices, indices, vertexCount,
      fWidth + rOverhang * 2, fDepth + rOverhang * 2,
      fHeight + wHeight,
      rColor[0], rColor[1], rColor[2],
    );

    if (vertices.isEmpty) {
      // Fallback: return a small colored cube
      return Mesh.fromVerticesAndIndices(
        vertices: [
          -0.5, 0.0, -0.5, 0.5, 0.3, 0.2,
           0.5, 0.0, -0.5, 0.5, 0.3, 0.2,
           0.5, 1.0, -0.5, 0.5, 0.3, 0.2,
          -0.5, 1.0, -0.5, 0.5, 0.3, 0.2,
          -0.5, 0.0,  0.5, 0.5, 0.3, 0.2,
           0.5, 0.0,  0.5, 0.5, 0.3, 0.2,
           0.5, 1.0,  0.5, 0.5, 0.3, 0.2,
          -0.5, 1.0,  0.5, 0.5, 0.3, 0.2,
        ],
        indices: [
          0, 1, 2, 0, 2, 3,
          5, 4, 7, 5, 7, 6,
          3, 2, 6, 3, 6, 7,
          4, 5, 1, 4, 1, 0,
          1, 5, 6, 1, 6, 2,
          4, 0, 3, 4, 3, 7,
        ],
        vertexStride: 6,
      );
    }

    return Mesh.fromVerticesAndIndices(
      vertices: vertices,
      indices: indices,
      vertexStride: 6,
    );
  }

  /// Add a box (foundation, wall segment) to the vertex/index lists.
  ///
  /// Center of box is at (x, y, z) with dimensions (w, h, d).
  /// Returns the new vertex count after adding 8 vertices.
  static int _addBox(
    List<double> verts,
    List<int> idx,
    int offset,
    double x, double y, double z,
    double w, double h, double d,
    double r, double g, double b,
  ) {
    final hw = w / 2;
    final hh = h / 2;
    final hd = d / 2;

    // 8 corner vertices
    // Vertex format: x, y, z, r, g, b
    verts.addAll([
      x - hw, y - hh, z + hd, r, g, b, // 0: front-bottom-left
      x + hw, y - hh, z + hd, r, g, b, // 1: front-bottom-right
      x + hw, y + hh, z + hd, r, g, b, // 2: front-top-right
      x - hw, y + hh, z + hd, r, g, b, // 3: front-top-left
      x - hw, y - hh, z - hd, r, g, b, // 4: back-bottom-left
      x + hw, y - hh, z - hd, r, g, b, // 5: back-bottom-right
      x + hw, y + hh, z - hd, r, g, b, // 6: back-top-right
      x - hw, y + hh, z - hd, r, g, b, // 7: back-top-left
    ]);

    // 6 faces, 2 triangles each = 36 indices
    idx.addAll([
      offset + 0, offset + 1, offset + 2, offset + 0, offset + 2, offset + 3,
      offset + 5, offset + 4, offset + 7, offset + 5, offset + 7, offset + 6,
      offset + 3, offset + 2, offset + 6, offset + 3, offset + 6, offset + 7,
      offset + 4, offset + 5, offset + 1, offset + 4, offset + 1, offset + 0,
      offset + 1, offset + 5, offset + 6, offset + 1, offset + 6, offset + 2,
      offset + 4, offset + 0, offset + 3, offset + 4, offset + 3, offset + 7,
    ]);

    return offset + 8;
  }

  /// Add 4 walls with a door opening on the front face (+Z side).
  ///
  /// The front wall is split into two segments with a gap for the door.
  /// The door itself is rendered as a recessed rectangle.
  static int _addWalls(
    List<double> verts,
    List<int> idx,
    int offset,
    double bWidth, double bDepth, double foundH, double wallH, double thick,
    double wr, double wg, double wb,
    double doorW, double doorH,
    double dr, double dg, double db,
  ) {
    final halfW = bWidth / 2;
    final halfD = bDepth / 2;
    final wallBase = foundH;
    final wallTop = foundH + wallH;
    final halfDoorW = doorW / 2;

    // Back wall (full width)
    offset = _addBox(
      verts, idx, offset,
      0.0, wallBase + wallH / 2, -halfD + thick / 2,
      bWidth, wallH, thick,
      wr, wg, wb,
    );

    // Left wall (full depth minus wall thickness on both ends)
    offset = _addBox(
      verts, idx, offset,
      -halfW + thick / 2, wallBase + wallH / 2, 0.0,
      thick, wallH, bDepth - thick * 2,
      wr * 0.9, wg * 0.9, wb * 0.9,
    );

    // Right wall
    offset = _addBox(
      verts, idx, offset,
      halfW - thick / 2, wallBase + wallH / 2, 0.0,
      thick, wallH, bDepth - thick * 2,
      wr * 0.9, wg * 0.9, wb * 0.9,
    );

    // Front wall - left segment (from left edge to door left)
    final leftSegW = halfW - halfDoorW;
    if (leftSegW > 0.01) {
      offset = _addBox(
        verts, idx, offset,
        -halfW + leftSegW / 2, wallBase + wallH / 2, halfD - thick / 2,
        leftSegW, wallH, thick,
        wr, wg, wb,
      );
    }

    // Front wall - right segment (from door right to right edge)
    final rightSegW = halfW - halfDoorW;
    if (rightSegW > 0.01) {
      offset = _addBox(
        verts, idx, offset,
        halfW - rightSegW / 2, wallBase + wallH / 2, halfD - thick / 2,
        rightSegW, wallH, thick,
        wr, wg, wb,
      );
    }

    // Front wall - above door (lintel)
    final lintelH = wallH - doorH;
    if (lintelH > 0.01) {
      offset = _addBox(
        verts, idx, offset,
        0.0, wallBase + doorH + lintelH / 2, halfD - thick / 2,
        doorW, lintelH, thick,
        wr, wg, wb,
      );
    }

    // Door (recessed dark rectangle on front face)
    offset = _addBox(
      verts, idx, offset,
      0.0, wallBase + doorH / 2, halfD - thick * 0.8,
      doorW, doorH, thick * 0.4,
      dr, dg, db,
    );

    return offset;
  }

  /// Add a peaked (gabled) roof as a triangular prism.
  ///
  /// The roof sits on top of the walls and overhangs slightly.
  /// The peak runs along the building's depth axis (Z).
  static int _addPeakedRoof(
    List<double> verts,
    List<int> idx,
    int offset,
    double roofW, double roofD,
    double baseY,
    double r, double g, double b,
  ) {
    final halfW = roofW / 2;
    final halfD = roofD / 2;
    final peakH = roofW * 0.35; // Roof peak height proportional to width
    final peakY = baseY + peakH;

    // Slightly darker color for the underside / gable faces
    final dr = r * 0.8;
    final dg = g * 0.8;
    final db = b * 0.8;

    // 6 vertices for the triangular prism
    // Front triangle
    verts.addAll([
      -halfW, baseY, halfD, dr, dg, db, // 0: front-bottom-left
       halfW, baseY, halfD, dr, dg, db, // 1: front-bottom-right
       0.0, peakY, halfD, r, g, b,      // 2: front-peak
    ]);
    // Back triangle
    verts.addAll([
      -halfW, baseY, -halfD, dr, dg, db, // 3: back-bottom-left
       halfW, baseY, -halfD, dr, dg, db, // 4: back-bottom-right
       0.0, peakY, -halfD, r, g, b,      // 5: back-peak
    ]);

    // Front gable face
    idx.addAll([offset + 0, offset + 1, offset + 2]);

    // Back gable face (reversed winding)
    idx.addAll([offset + 4, offset + 3, offset + 5]);

    // Left roof slope (2 triangles)
    idx.addAll([
      offset + 3, offset + 0, offset + 2,
      offset + 3, offset + 2, offset + 5,
    ]);

    // Right roof slope (2 triangles)
    idx.addAll([
      offset + 1, offset + 4, offset + 5,
      offset + 1, offset + 5, offset + 2,
    ]);

    return offset + 6;
  }

  // ==================== HELPERS ====================

  /// Extract a number from a part definition with fallback.
  static double _getNum(
      Map<String, dynamic>? part, String key, double fallback) {
    if (part == null) return fallback;
    final val = part[key];
    if (val is num) return val.toDouble();
    return fallback;
  }

  /// Extract a color [r, g, b] from a part definition with fallback.
  static List<double> _getColor(
      Map<String, dynamic>? part, String key, List<double> fallback) {
    if (part == null) return fallback;
    final val = part[key];
    if (val is List && val.length >= 3) {
      return val.map((e) => (e as num).toDouble()).toList();
    }
    return fallback;
  }
}
