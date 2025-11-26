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

  @override
  String toString() {
    return 'Mesh(vertices: $vertexCount, triangles: $triangleCount)';
  }
}
