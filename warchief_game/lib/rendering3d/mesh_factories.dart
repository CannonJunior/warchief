part of 'mesh.dart';

// ==================== MATH HELPERS ====================

/// Simple sine approximation using Taylor series
double _meshSin(double x) {
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
double _meshCos(double x) => _meshSin(x + 1.5707963); // cos(x) = sin(x + pi/2)

/// Newton's method square root approximation
double _meshSqrt(double x) {
  if (x <= 0) return 0;
  double guess = x / 2;
  for (int i = 0; i < 10; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}

// ==================== COMPLEX FACTORY IMPLEMENTATIONS ====================

/// Implementation of Mesh.targetIndicator factory.
///
/// Creates a dashed rectangle target indicator mesh. Each side has a
/// dash-gap-dash pattern (2 dashes, with a gap in the middle).
/// The rectangle lies flat on the ground (Y plane) with slight height offset.
Mesh _buildMeshTargetIndicator({
  required double size,
  required double lineWidth,
  required Vector3 color,
}) {
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
    final len = _meshSqrt(dx * dx + dz * dz);
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
      allColors.addAll([color.x, color.y, color.z, 1.0]);
    }
    // Normals for bottom face (pointing down)
    for (int i = 0; i < 4; i++) {
      allNormals.addAll([0, -1, 0]);
      allColors.addAll([color.x, color.y, color.z, 1.0]);
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

/// Implementation of Mesh.auraDisc factory.
///
/// Creates a flat circular disc with radial alpha falloff for aura glow effects.
/// The disc has 3 concentric rings with decreasing alpha:
/// - Center vertex: full color, alpha 0.35
/// - Mid ring (8 vertices at 50% radius): full color, alpha 0.2
/// - Outer ring (8 vertices at 100% radius): full color, alpha 0.0
/// Total: 17 vertices, 32 triangles (16 inner + 16 outer), double-sided.
Mesh _buildMeshAuraDisc({
  required double radius,
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
      final x = _meshCos(angle) * midRadius;
      final z = _meshSin(angle) * midRadius;
      allVertices.addAll([x, 0.0, z]);
      allNormals.addAll([0.0, normalY, 0.0]);
      allColors.addAll([color.x, color.y, color.z, midAlpha]);
    }

    // Outer ring vertices (8 at 100% radius)
    for (int i = 0; i < segments; i++) {
      final angle = (i / segments) * 2.0 * 3.14159265;
      final x = _meshCos(angle) * radius;
      final z = _meshSin(angle) * radius;
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
