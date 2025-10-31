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
  factory Mesh.plane({
    double width = 1.0,
    double height = 1.0,
    Vector3? color,
  }) {
    final halfW = width / 2;
    final halfH = height / 2;

    final vertices = Float32List.fromList([
      -halfW, 0, -halfH,  // 0: bottom-left
       halfW, 0, -halfH,  // 1: bottom-right
       halfW, 0,  halfH,  // 2: top-right
      -halfW, 0,  halfH,  // 3: top-left
    ]);

    final indices = Uint16List.fromList([
      0, 1, 2,  // First triangle
      0, 2, 3,  // Second triangle
    ]);

    final normals = Float32List.fromList([
      0, 1, 0,  // All normals point up (Y+)
      0, 1, 0,
      0, 1, 0,
      0, 1, 0,
    ]);

    final texCoords = Float32List.fromList([
      0, 0,  // bottom-left
      1, 0,  // bottom-right
      1, 1,  // top-right
      0, 1,  // top-left
    ]);

    Float32List? colors;
    if (color != null) {
      colors = Float32List.fromList([
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

  @override
  String toString() {
    return 'Mesh(vertices: $vertexCount, triangles: $triangleCount)';
  }
}
