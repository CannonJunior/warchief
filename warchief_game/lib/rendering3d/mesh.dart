import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';

/// Mesh - 3D geometry data structure
///
/// Contains vertices, indices, normals, and texture coordinates.
/// Used by WebGLRenderer to draw 3D objects.
///
/// Usage:
/// ```dart
/// final mesh = Mesh(
///   vertices: Float32List.fromList([
///     -1, -1, 0,  // vertex 0
///      1, -1, 0,  // vertex 1
///      0,  1, 0,  // vertex 2
///   ]),
///   indices: Uint16List.fromList([0, 1, 2]),
/// );
/// ```
class Mesh {
  /// Vertex positions (x, y, z) packed as [x1, y1, z1, x2, y2, z2, ...]
  final Float32List vertices;

  /// Triangle indices (3 per triangle) - which vertices form each triangle
  final Uint16List indices;

  /// Normals (x, y, z) for lighting - one per vertex
  final Float32List? normals;

  /// Texture coordinates (u, v) - one per vertex
  final Float32List? texCoords;

  /// Vertex colors (r, g, b, a) - one per vertex
  final Float32List? colors;

  Mesh({
    required this.vertices,
    required this.indices,
    this.normals,
    this.texCoords,
    this.colors,
  }) {
    // Validation
    assert(vertices.length % 3 == 0, 'Vertices must be multiple of 3 (x, y, z)');
    assert(indices.length % 3 == 0, 'Indices must be multiple of 3 (triangles)');

    if (normals != null) {
      assert(normals!.length == vertices.length, 'Normals count must match vertices');
    }
    if (texCoords != null) {
      assert(texCoords!.length == (vertices.length / 3) * 2, 'TexCoords must be 2 per vertex');
    }
    if (colors != null) {
      assert(colors!.length == (vertices.length / 3) * 4, 'Colors must be 4 per vertex (RGBA)');
    }
  }

  /// Get number of vertices
  int get vertexCount => vertices.length ~/ 3;

  /// Get number of triangles
  int get triangleCount => indices.length ~/ 3;

  /// Create a mesh from raw vertex and index data with vertex colors
  ///
  /// Useful for procedurally generated geometry like Ley Lines.
  /// Vertex data format: [x, y, z, r, g, b, x, y, z, r, g, b, ...]
  /// where r, g, b are color components in 0.0-1.0 range.
  factory Mesh.fromVerticesAndIndices({
    required List<double> vertices,
    required List<int> indices,
    int vertexStride = 6, // x, y, z, r, g, b
  }) {
    final numVertices = vertices.length ~/ vertexStride;

    // Extract positions
    final positions = Float32List(numVertices * 3);
    for (int i = 0; i < numVertices; i++) {
      positions[i * 3 + 0] = vertices[i * vertexStride + 0]; // x
      positions[i * 3 + 1] = vertices[i * vertexStride + 1]; // y
      positions[i * 3 + 2] = vertices[i * vertexStride + 2]; // z
    }

    // Extract colors (RGBA, adding A=1.0)
    final colors = Float32List(numVertices * 4);
    for (int i = 0; i < numVertices; i++) {
      colors[i * 4 + 0] = vertices[i * vertexStride + 3]; // r
      colors[i * 4 + 1] = vertices[i * vertexStride + 4]; // g
      colors[i * 4 + 2] = vertices[i * vertexStride + 5]; // b
      colors[i * 4 + 3] = 1.0; // a
    }

    // Convert indices
    final indexList = Uint16List.fromList(indices.map((i) => i).toList());

    // Generate simple up-facing normals
    final normals = Float32List(numVertices * 3);
    for (int i = 0; i < numVertices; i++) {
      normals[i * 3 + 0] = 0.0;
      normals[i * 3 + 1] = 1.0;
      normals[i * 3 + 2] = 0.0;
    }

    return Mesh(
      vertices: positions,
      indices: indexList,
      normals: normals,
      colors: colors,
    );
  }

  /// Create a plane mesh (quad made of 2 triangles)
  ///
  /// Useful for terrain tiles, floors, walls, etc.
  /// Creates a double-sided plane so it's visible from both above and below.
  factory Mesh.plane({
    double width = 1.0,
    double height = 1.0,
    Vector3? color,
  }) {
    final halfW = width / 2;
    final halfH = height / 2;

    // Double-sided plane: 8 vertices (4 for top face, 4 for bottom face)
    final vertices = Float32List.fromList([
      // Top face (normals pointing up)
      -halfW, 0, -halfH,  // 0: bottom-left
       halfW, 0, -halfH,  // 1: bottom-right
       halfW, 0,  halfH,  // 2: top-right
      -halfW, 0,  halfH,  // 3: top-left
      // Bottom face (same positions, but normals will point down)
      -halfW, 0, -halfH,  // 4: bottom-left
       halfW, 0, -halfH,  // 5: bottom-right
       halfW, 0,  halfH,  // 6: top-right
      -halfW, 0,  halfH,  // 7: top-left
    ]);

    // Indices for both faces (bottom face has reversed winding order)
    final indices = Uint16List.fromList([
      // Top face (counter-clockwise when viewed from above)
      0, 1, 2,  // First triangle
      0, 2, 3,  // Second triangle
      // Bottom face (counter-clockwise when viewed from below)
      4, 6, 5,  // First triangle (reversed)
      4, 7, 6,  // Second triangle (reversed)
    ]);

    final normals = Float32List.fromList([
      // Top face normals (pointing up)
      0, 1, 0,
      0, 1, 0,
      0, 1, 0,
      0, 1, 0,
      // Bottom face normals (pointing down)
      0, -1, 0,
      0, -1, 0,
      0, -1, 0,
      0, -1, 0,
    ]);

    final texCoords = Float32List.fromList([
      // Top face
      0, 0,
      1, 0,
      1, 1,
      0, 1,
      // Bottom face
      0, 0,
      1, 0,
      1, 1,
      0, 1,
    ]);

    Float32List? colors;
    if (color != null) {
      colors = Float32List.fromList([
        // Top face
        color.x, color.y, color.z, 1.0,
        color.x, color.y, color.z, 1.0,
        color.x, color.y, color.z, 1.0,
        color.x, color.y, color.z, 1.0,
        // Bottom face
        color.x, color.y, color.z, 1.0,
        color.x, color.y, color.z, 1.0,
        color.x, color.y, color.z, 1.0,
        color.x, color.y, color.z, 1.0,
      ]);
    }

    return Mesh(
      vertices: vertices,
      indices: indices,
      normals: normals,
      texCoords: texCoords,
      colors: colors,
    );
  }

  /// Create a cube mesh
  ///
  /// Useful for buildings, boxes, character placeholders, etc.
  factory Mesh.cube({
    double size = 1.0,
    Vector3? color,
  }) {
    final s = size / 2;

    // 8 vertices of a cube
    final vertices = Float32List.fromList([
      // Front face (Z+)
      -s, -s,  s,  // 0: bottom-left-front
       s, -s,  s,  // 1: bottom-right-front
       s,  s,  s,  // 2: top-right-front
      -s,  s,  s,  // 3: top-left-front

      // Back face (Z-)
      -s, -s, -s,  // 4: bottom-left-back
       s, -s, -s,  // 5: bottom-right-back
       s,  s, -s,  // 6: top-right-back
      -s,  s, -s,  // 7: top-left-back
    ]);

    final indices = Uint16List.fromList([
      // Front face
      0, 1, 2,  0, 2, 3,
      // Back face
      5, 4, 7,  5, 7, 6,
      // Top face
      3, 2, 6,  3, 6, 7,
      // Bottom face
      4, 5, 1,  4, 1, 0,
      // Right face
      1, 5, 6,  1, 6, 2,
      // Left face
      4, 0, 3,  4, 3, 7,
    ]);

    // Simple normals (not perfect, but good enough for a basic cube)
    final normals = Float32List.fromList([
      // Front vertices - point forward
      0, 0, 1,  0, 0, 1,  0, 0, 1,  0, 0, 1,
      // Back vertices - point backward
      0, 0, -1,  0, 0, -1,  0, 0, -1,  0, 0, -1,
    ]);

    Float32List? colors;
    if (color != null) {
      colors = Float32List(8 * 4);
      for (int i = 0; i < 8; i++) {
        colors[i * 4 + 0] = color.x;
        colors[i * 4 + 1] = color.y;
        colors[i * 4 + 2] = color.z;
        colors[i * 4 + 3] = 1.0;
      }
    }

    return Mesh(
      vertices: vertices,
      indices: indices,
      normals: normals,
      colors: colors,
    );
  }

  /// Compute normals from vertices and indices
  ///
  /// Calculates face normals and averages them per vertex.
  /// Call this if you create a mesh without normals.
  static Float32List computeNormals(Float32List vertices, Uint16List indices) {
    final normals = Float32List(vertices.length);

    // For each triangle
    for (int i = 0; i < indices.length; i += 3) {
      final i0 = indices[i] * 3;
      final i1 = indices[i + 1] * 3;
      final i2 = indices[i + 2] * 3;

      // Get triangle vertices
      final v0 = Vector3(vertices[i0], vertices[i0 + 1], vertices[i0 + 2]);
      final v1 = Vector3(vertices[i1], vertices[i1 + 1], vertices[i1 + 2]);
      final v2 = Vector3(vertices[i2], vertices[i2 + 1], vertices[i2 + 2]);

      // Compute face normal via cross product
      final edge1 = v1 - v0;
      final edge2 = v2 - v0;
      final normal = edge1.cross(edge2).normalized();

      // Add to each vertex normal (will average later)
      for (final idx in [i0, i1, i2]) {
        normals[idx] += normal.x;
        normals[idx + 1] += normal.y;
        normals[idx + 2] += normal.z;
      }
    }

    // Normalize all vertex normals
    for (int i = 0; i < normals.length; i += 3) {
      final normal = Vector3(normals[i], normals[i + 1], normals[i + 2]).normalized();
      normals[i] = normal.x;
      normals[i + 1] = normal.y;
      normals[i + 2] = normal.z;
    }

    return normals;
  }

  /// Create a copy of this mesh with computed normals
  Mesh withComputedNormals() {
    return Mesh(
      vertices: vertices,
      indices: indices,
      normals: computeNormals(vertices, indices),
      texCoords: texCoords,
      colors: colors,
    );
  }

  /// Create a triangle mesh (double-sided triangle pointing forward)
  ///
  /// Useful for direction indicators, arrows, etc.
  /// The triangle points in the +Z direction by default.
  /// Double-sided so it's visible from all camera angles.
  factory Mesh.triangle({
    double size = 1.0,
    Vector3? color,
  }) {
    final halfSize = size / 2;

    // Triangle vertices: tip points forward (+Z), base is back
    // Double-sided: 6 vertices (3 for top face, 3 for bottom face)
    final vertices = Float32List.fromList([
      // Top face (visible from above)
      0, 0, halfSize,           // 0: tip (forward)
      -halfSize, 0, -halfSize,  // 1: left back corner
      halfSize, 0, -halfSize,   // 2: right back corner
      // Bottom face (visible from below)
      0, 0, halfSize,           // 3: tip (forward)
      -halfSize, 0, -halfSize,  // 4: left back corner
      halfSize, 0, -halfSize,   // 5: right back corner
    ]);

    final indices = Uint16List.fromList([
      // Top face (counter-clockwise from above)
      0, 1, 2,
      // Bottom face (counter-clockwise from below, reversed winding)
      3, 5, 4,
    ]);

    // Normals (up for top face, down for bottom face)
    final normals = Float32List.fromList([
      // Top face normals
      0, 1, 0,
      0, 1, 0,
      0, 1, 0,
      // Bottom face normals
      0, -1, 0,
      0, -1, 0,
      0, -1, 0,
    ]);

    Float32List? colors;
    if (color != null) {
      colors = Float32List.fromList([
        // Top face
        color.x, color.y, color.z, 1.0,
        color.x, color.y, color.z, 1.0,
        color.x, color.y, color.z, 1.0,
        // Bottom face
        color.x, color.y, color.z, 1.0,
        color.x, color.y, color.z, 1.0,
        color.x, color.y, color.z, 1.0,
      ]);
    }

    return Mesh(
      vertices: vertices,
      indices: indices,
      normals: normals,
      colors: colors,
    );
  }

  /// Create a dashed rectangle target indicator mesh
  ///
  /// Creates a rectangular indicator with dashed lines (gaps in each side).
  /// Each side has a dash-gap-dash pattern (1/3 dash, 1/3 gap, 1/3 dash).
  /// The rectangle lies flat on the ground (Y plane) with slight height offset.
  ///
  /// Parameters:
  /// - size: Width and depth of the rectangle
  /// - lineWidth: Thickness of the dash lines
  /// - color: Color of the dashes (defaults to yellow)
  factory Mesh.targetIndicator({
    double size = 1.5,
    double lineWidth = 0.05,
    Vector3? color,
  }) {
    color ??= Vector3(1.0, 0.2, 0.2); // Default red (crosshairs style)

    final halfSize = size / 2;
    final dashLength = size / 5; // Each dash is 1/5 of side length for larger gaps
    final halfLine = lineWidth / 2;
    final y = 0.02; // Slight offset above ground to prevent z-fighting

    // We need 8 dashes total (2 per side, with gap in middle)
    // Each dash is a thin rectangle
    final allVertices = <double>[];
    final allIndices = <int>[];
    final allNormals = <double>[];
    final allColors = <double>[];

    int vertexOffset = 0;

    void addDash(double x1, double z1, double x2, double z2) {
      // Calculate perpendicular direction for line width
      final dx = x2 - x1;
      final dz = z2 - z1;
      final len = _sqrt(dx * dx + dz * dz);
      if (len < 0.001) return;

      final perpX = -dz / len * halfLine;
      final perpZ = dx / len * halfLine;

      // Double-sided dash: 8 vertices (4 for top face, 4 for bottom face)
      // Top face vertices
      allVertices.addAll([
        x1 + perpX, y, z1 + perpZ, // 0
        x1 - perpX, y, z1 - perpZ, // 1
        x2 - perpX, y, z2 - perpZ, // 2
        x2 + perpX, y, z2 + perpZ, // 3
      ]);
      // Bottom face vertices (same positions)
      allVertices.addAll([
        x1 + perpX, y, z1 + perpZ, // 4
        x1 - perpX, y, z1 - perpZ, // 5
        x2 - perpX, y, z2 - perpZ, // 6
        x2 + perpX, y, z2 + perpZ, // 7
      ]);

      // Indices for top face (counter-clockwise when viewed from above)
      allIndices.addAll([
        vertexOffset + 0, vertexOffset + 1, vertexOffset + 2,
        vertexOffset + 0, vertexOffset + 2, vertexOffset + 3,
      ]);
      // Indices for bottom face (reversed winding for viewing from below)
      allIndices.addAll([
        vertexOffset + 4, vertexOffset + 6, vertexOffset + 5,
        vertexOffset + 4, vertexOffset + 7, vertexOffset + 6,
      ]);

      // Normals for top face (pointing up)
      for (int i = 0; i < 4; i++) {
        allNormals.addAll([0, 1, 0]);
        allColors.addAll([color!.x, color.y, color.z, 1.0]);
      }
      // Normals for bottom face (pointing down)
      for (int i = 0; i < 4; i++) {
        allNormals.addAll([0, -1, 0]);
        allColors.addAll([color!.x, color.y, color.z, 1.0]);
      }

      vertexOffset += 8;
    }

    // Front side (positive Z): two dashes with gap in middle
    addDash(-halfSize, halfSize, -halfSize + dashLength, halfSize);
    addDash(halfSize - dashLength, halfSize, halfSize, halfSize);

    // Back side (negative Z): two dashes with gap in middle
    addDash(-halfSize, -halfSize, -halfSize + dashLength, -halfSize);
    addDash(halfSize - dashLength, -halfSize, halfSize, -halfSize);

    // Left side (negative X): two dashes with gap in middle
    addDash(-halfSize, -halfSize, -halfSize, -halfSize + dashLength);
    addDash(-halfSize, halfSize - dashLength, -halfSize, halfSize);

    // Right side (positive X): two dashes with gap in middle
    addDash(halfSize, -halfSize, halfSize, -halfSize + dashLength);
    addDash(halfSize, halfSize - dashLength, halfSize, halfSize);

    return Mesh(
      vertices: Float32List.fromList(allVertices),
      indices: Uint16List.fromList(allIndices),
      normals: Float32List.fromList(allNormals),
      colors: Float32List.fromList(allColors),
    );
  }

  /// Create a flat circular disc with radial alpha falloff for aura glow effects
  ///
  /// Creates a soft circular glow when rendered with additive blending.
  /// The disc has 3 concentric rings with decreasing alpha:
  /// - Center vertex: full color, alpha 0.35
  /// - Mid ring (8 vertices at 50% radius): full color, alpha 0.2
  /// - Outer ring (8 vertices at 100% radius): full color, alpha 0.0
  /// Total: 17 vertices, 32 triangles (16 inner + 16 outer), double-sided.
  ///
  /// Parameters:
  /// - radius: The radius of the disc
  /// - color: RGB color as Vector3 (components 0.0-1.0)
  factory Mesh.auraDisc({
    double radius = 1.0,
    required Vector3 color,
  }) {
    const int segments = 8;
    const double centerAlpha = 0.35;
    const double midAlpha = 0.2;
    const double outerAlpha = 0.0;
    final double midRadius = radius * 0.5;

    // 17 vertices per face * 2 faces (double-sided) = 34 vertices
    final allVertices = <double>[];
    final allNormals = <double>[];
    final allColors = <double>[];
    final allIndices = <int>[];

    // Reason: Double-sided so the disc is visible from both above and below camera angles
    for (int face = 0; face < 2; face++) {
      final normalY = face == 0 ? 1.0 : -1.0;
      final baseVertex = face * (1 + segments * 2);

      // Center vertex
      allVertices.addAll([0.0, 0.0, 0.0]);
      allNormals.addAll([0.0, normalY, 0.0]);
      allColors.addAll([color.x, color.y, color.z, centerAlpha]);

      // Mid ring vertices (8 at 50% radius)
      for (int i = 0; i < segments; i++) {
        final angle = (i / segments) * 2.0 * 3.14159265;
        final x = _cos(angle) * midRadius;
        final z = _sin(angle) * midRadius;
        allVertices.addAll([x, 0.0, z]);
        allNormals.addAll([0.0, normalY, 0.0]);
        allColors.addAll([color.x, color.y, color.z, midAlpha]);
      }

      // Outer ring vertices (8 at 100% radius)
      for (int i = 0; i < segments; i++) {
        final angle = (i / segments) * 2.0 * 3.14159265;
        final x = _cos(angle) * radius;
        final z = _sin(angle) * radius;
        allVertices.addAll([x, 0.0, z]);
        allNormals.addAll([0.0, normalY, 0.0]);
        allColors.addAll([color.x, color.y, color.z, outerAlpha]);
      }

      // Inner triangles (center to mid ring) — 8 triangles
      for (int i = 0; i < segments; i++) {
        final next = (i + 1) % segments;
        if (face == 0) {
          // Top face: counter-clockwise from above
          allIndices.addAll([baseVertex, baseVertex + 1 + i, baseVertex + 1 + next]);
        } else {
          // Bottom face: reversed winding
          allIndices.addAll([baseVertex, baseVertex + 1 + next, baseVertex + 1 + i]);
        }
      }

      // Outer triangles (mid ring to outer ring) — 8 quads = 16 triangles
      for (int i = 0; i < segments; i++) {
        final next = (i + 1) % segments;
        final midI = baseVertex + 1 + i;
        final midNext = baseVertex + 1 + next;
        final outI = baseVertex + 1 + segments + i;
        final outNext = baseVertex + 1 + segments + next;

        if (face == 0) {
          allIndices.addAll([midI, outI, outNext]);
          allIndices.addAll([midI, outNext, midNext]);
        } else {
          allIndices.addAll([midI, outNext, outI]);
          allIndices.addAll([midI, midNext, outNext]);
        }
      }
    }

    return Mesh(
      vertices: Float32List.fromList(allVertices),
      indices: Uint16List.fromList(allIndices),
      normals: Float32List.fromList(allNormals),
      colors: Float32List.fromList(allColors),
    );
  }

  /// Simple sine approximation using Taylor series
  static double _sin(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.14159265) x -= 6.28318530;
    while (x < -3.14159265) x += 6.28318530;
    final x2 = x * x;
    final x3 = x2 * x;
    final x5 = x3 * x2;
    final x7 = x5 * x2;
    return x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0;
  }

  /// Simple cosine approximation using Taylor series
  static double _cos(double x) {
    return _sin(x + 1.5707963); // cos(x) = sin(x + pi/2)
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  @override
  String toString() {
    return 'Mesh(vertices: $vertexCount, triangles: $triangleCount)';
  }
}
