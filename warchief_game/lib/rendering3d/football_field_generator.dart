import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';
import 'mesh.dart';
import 'math/transform3d.dart';

/// FootballFieldGenerator - Creates a regulation American football field
///
/// Generates a 100-yard football field with proper markings:
/// - 100 yards of playing field (53.3 yards wide standard)
/// - 10-yard end zones on each side (total 120 yards)
/// - Yard line markings every 5 yards
/// - Hash marks
/// - End zone coloring
/// - Goal posts (optional)
///
/// Coordinate system:
/// - X axis: Width of field (sideline to sideline)
/// - Y axis: Height (flat field at Y=0)
/// - Z axis: Length of field (end zone to end zone)
///
/// Usage:
/// ```dart
/// final field = FootballFieldGenerator.createField();
/// renderer.addMesh(field.fieldMesh, field.fieldTransform);
/// ```
class FootballFieldGenerator {
  FootballFieldGenerator._(); // Private constructor to prevent instantiation

  // ==================== FIELD DIMENSIONS (in yards) ====================

  /// Total field length including end zones (120 yards)
  static const double totalFieldLength = 120.0;

  /// Playing field length (100 yards, excluding end zones)
  static const double playingFieldLength = 100.0;

  /// End zone depth (10 yards each)
  static const double endZoneDepth = 10.0;

  /// Field width (53.3 yards - regulation width)
  static const double fieldWidth = 53.3;

  /// Yards to world units conversion (1 yard = 1 unit for simplicity)
  static const double yardsToUnits = 1.0;

  // ==================== FIELD COLORS ====================

  /// Field grass color (darker green)
  static final Vector3 grassColor = Vector3(0.15, 0.5, 0.15);

  /// End zone color (lighter green)
  static final Vector3 endZoneColor = Vector3(0.1, 0.45, 0.1);

  /// Yard line color (white)
  static final Vector3 yardLineColor = Vector3(0.9, 0.9, 0.9);

  /// Hash mark color (white)
  static final Vector3 hashMarkColor = Vector3(0.9, 0.9, 0.9);

  // ==================== MARKING DIMENSIONS ====================

  /// Yard line width (in yards)
  static const double yardLineWidth = 0.15;

  /// Hash mark length (in yards)
  static const double hashMarkLength = 2.0;

  /// Hash mark width (in yards)
  static const double hashMarkWidth = 0.1;

  /// Distance from center of hash marks to center of field
  static const double hashMarkOffset = 9.0; // NCAA/NFL hybrid

  /// Creates a complete football field with all markings
  ///
  /// Returns a record containing:
  /// - fieldMesh: Main grass field mesh
  /// - fieldTransform: Transform for the field mesh
  /// - markings: List of (mesh, transform) for yard lines and hash marks
  /// - endZones: List of (mesh, transform) for end zone areas
  /// - goalPosts: List of (mesh, transform) for goal post structures
  static ({
    Mesh fieldMesh,
    Transform3d fieldTransform,
    List<({Mesh mesh, Transform3d transform})> markings,
    List<({Mesh mesh, Transform3d transform})> endZones,
    List<({Mesh mesh, Transform3d transform})> goalPosts,
  }) createField() {
    // Create main field mesh (entire grass surface)
    final fieldMesh = _createFieldMesh();
    final fieldTransform = Transform3d(
      position: Vector3(0, 0, 0),
    );

    // Create field markings (yard lines and hash marks)
    final markings = <({Mesh mesh, Transform3d transform})>[];
    markings.addAll(_createYardLines());
    markings.addAll(_createHashMarks());

    // Create end zones
    final endZones = _createEndZones();

    // Create goal posts
    final goalPosts = _createGoalPosts();

    return (
      fieldMesh: fieldMesh,
      fieldTransform: fieldTransform,
      markings: markings,
      endZones: endZones,
      goalPosts: goalPosts,
    );
  }

  /// Creates the main field mesh (flat rectangular grass surface)
  static Mesh _createFieldMesh() {
    final lengthUnits = totalFieldLength * yardsToUnits;
    final widthUnits = fieldWidth * yardsToUnits;

    // Create a flat rectangular plane for the entire field
    // We'll use a grid with enough resolution for smooth appearance
    final gridSizeZ = 120; // 1 segment per yard length
    final gridSizeX = 54;  // 1 segment per yard width

    final vertexCount = (gridSizeX + 1) * (gridSizeZ + 1);
    final triangleCount = gridSizeX * gridSizeZ * 2;
    final indexCount = triangleCount * 3;

    final vertices = Float32List(vertexCount * 3);
    final normals = Float32List(vertexCount * 3);
    final colors = Float32List(vertexCount * 4);
    final indices = Uint16List(indexCount);

    // Generate vertices
    int vertIdx = 0;
    for (int z = 0; z <= gridSizeZ; z++) {
      for (int x = 0; x <= gridSizeX; x++) {
        // Position (centered around origin)
        final posX = (x / gridSizeX - 0.5) * widthUnits;
        final posZ = (z / gridSizeZ - 0.5) * lengthUnits;

        vertices[vertIdx * 3 + 0] = posX;
        vertices[vertIdx * 3 + 1] = 0.0; // Flat field
        vertices[vertIdx * 3 + 2] = posZ;

        // Normal (pointing up)
        normals[vertIdx * 3 + 0] = 0.0;
        normals[vertIdx * 3 + 1] = 1.0;
        normals[vertIdx * 3 + 2] = 0.0;

        // Color based on field zone
        final yardPosition = z.toDouble(); // Position in yards from back of field
        Vector3 color;

        if (yardPosition < endZoneDepth || yardPosition >= (totalFieldLength - endZoneDepth)) {
          // End zones
          color = endZoneColor;
        } else {
          // Playing field
          color = grassColor;
        }

        colors[vertIdx * 4 + 0] = color.x;
        colors[vertIdx * 4 + 1] = color.y;
        colors[vertIdx * 4 + 2] = color.z;
        colors[vertIdx * 4 + 3] = 1.0;

        vertIdx++;
      }
    }

    // Generate indices (two triangles per grid square)
    int idxIdx = 0;
    for (int z = 0; z < gridSizeZ; z++) {
      for (int x = 0; x < gridSizeX; x++) {
        final topLeft = z * (gridSizeX + 1) + x;
        final topRight = topLeft + 1;
        final bottomLeft = (z + 1) * (gridSizeX + 1) + x;
        final bottomRight = bottomLeft + 1;

        // First triangle
        indices[idxIdx++] = topLeft;
        indices[idxIdx++] = bottomLeft;
        indices[idxIdx++] = bottomRight;

        // Second triangle
        indices[idxIdx++] = topLeft;
        indices[idxIdx++] = bottomRight;
        indices[idxIdx++] = topRight;
      }
    }

    return Mesh(
      vertices: vertices,
      indices: indices,
      normals: normals,
      colors: colors,
    );
  }

  /// Creates yard line markings (every 5 yards)
  static List<({Mesh mesh, Transform3d transform})> _createYardLines() {
    final markings = <({Mesh mesh, Transform3d transform})>[];

    // Create yard lines every 5 yards in the playing field
    // Start at 10 yards (end of first end zone), end at 110 yards (start of second end zone)
    for (int yard = 10; yard <= 110; yard += 5) {
      // Skip the 50-yard line for now (we'll make it special later if needed)
      final posZ = (yard - totalFieldLength / 2) * yardsToUnits;

      final yardLineMesh = Mesh.plane(
        width: fieldWidth * yardsToUnits,
        height: yardLineWidth * yardsToUnits,
        color: yardLineColor,
      );

      final transform = Transform3d(
        position: Vector3(0, 0.01, posZ), // Slightly above ground to prevent z-fighting
        rotation: Vector3(0, 0, 0),
      );

      markings.add((mesh: yardLineMesh, transform: transform));
    }

    return markings;
  }

  /// Creates hash mark markings
  static List<({Mesh mesh, Transform3d transform})> _createHashMarks() {
    final markings = <({Mesh mesh, Transform3d transform})>[];

    // Hash marks appear every 1 yard between the 5-yard lines
    for (int yard = 11; yard <= 109; yard++) {
      // Skip yard lines (every 5 yards)
      if (yard % 5 == 0) continue;

      final posZ = (yard - totalFieldLength / 2) * yardsToUnits;

      // Left hash marks
      final leftHashMesh = Mesh.plane(
        width: hashMarkLength * yardsToUnits,
        height: hashMarkWidth * yardsToUnits,
        color: hashMarkColor,
      );

      final leftTransform = Transform3d(
        position: Vector3(-hashMarkOffset * yardsToUnits, 0.01, posZ),
        rotation: Vector3(0, 0, 0),
      );

      // Right hash marks
      final rightHashMesh = Mesh.plane(
        width: hashMarkLength * yardsToUnits,
        height: hashMarkWidth * yardsToUnits,
        color: hashMarkColor,
      );

      final rightTransform = Transform3d(
        position: Vector3(hashMarkOffset * yardsToUnits, 0.01, posZ),
        rotation: Vector3(0, 0, 0),
      );

      markings.add((mesh: leftHashMesh, transform: leftTransform));
      markings.add((mesh: rightHashMesh, transform: rightTransform));
    }

    return markings;
  }

  /// Creates end zone colored sections
  static List<({Mesh mesh, Transform3d transform})> _createEndZones() {
    final endZones = <({Mesh mesh, Transform3d transform})>[];

    // Near end zone (negative Z)
    final nearEndZoneMesh = Mesh.plane(
      width: fieldWidth * yardsToUnits,
      height: endZoneDepth * yardsToUnits,
      color: endZoneColor,
    );

    final nearEndZoneZ = -(playingFieldLength / 2 + endZoneDepth / 2) * yardsToUnits;
    final nearTransform = Transform3d(
      position: Vector3(0, 0.005, nearEndZoneZ), // Slightly above field
    );

    // Far end zone (positive Z)
    final farEndZoneMesh = Mesh.plane(
      width: fieldWidth * yardsToUnits,
      height: endZoneDepth * yardsToUnits,
      color: endZoneColor,
    );

    final farEndZoneZ = (playingFieldLength / 2 + endZoneDepth / 2) * yardsToUnits;
    final farTransform = Transform3d(
      position: Vector3(0, 0.005, farEndZoneZ), // Slightly above field
    );

    endZones.add((mesh: nearEndZoneMesh, transform: nearTransform));
    endZones.add((mesh: farEndZoneMesh, transform: farTransform));

    return endZones;
  }

  /// Get the yard position from a world Z coordinate
  ///
  /// Returns the yard line (0-100) for a given Z position
  /// Useful for game logic (first downs, scoring, etc.)
  static double getYardLineFromZ(double worldZ) {
    // Convert world Z to yard position
    // Field runs from -60 to +60 in world units
    // 0 yard line is at -50 world units
    final yardFromBackOfField = (worldZ + totalFieldLength / 2 * yardsToUnits) / yardsToUnits;

    // Convert to yard line (0-100 scale)
    if (yardFromBackOfField < endZoneDepth) {
      return 0.0; // In near end zone
    } else if (yardFromBackOfField >= totalFieldLength - endZoneDepth) {
      return 100.0; // In far end zone
    } else {
      return yardFromBackOfField - endZoneDepth; // Playing field yards (0-100)
    }
  }

  /// Get world Z coordinate from yard line
  ///
  /// Returns the world Z position for a given yard line (0-100)
  static double getZFromYardLine(double yardLine) {
    // Clamp to valid range
    final clampedYard = yardLine.clamp(0.0, 100.0);

    // Convert yard line to position from back of field
    final yardFromBack = endZoneDepth + clampedYard;

    // Convert to world Z (centered at origin)
    return (yardFromBack - totalFieldLength / 2) * yardsToUnits;
  }

  /// Check if a world position is in bounds (on the field)
  static bool isInBounds(Vector3 position) {
    final halfWidth = fieldWidth / 2 * yardsToUnits;
    final halfLength = totalFieldLength / 2 * yardsToUnits;

    return position.x.abs() <= halfWidth && position.z.abs() <= halfLength;
  }

  /// Check if a world position is in an end zone
  static bool isInEndZone(Vector3 position) {
    if (!isInBounds(position)) return false;

    final yardLine = getYardLineFromZ(position.z);
    return yardLine <= 0.0 || yardLine >= 100.0;
  }

  /// Creates goal posts at both ends of the field
  static List<({Mesh mesh, Transform3d transform})> _createGoalPosts() {
    final goalPosts = <({Mesh mesh, Transform3d transform})>[];

    // Goal post dimensions (NFL regulation)
    const postHeight = 10.0; // Height of uprights (10 yards)
    const crossbarHeight = 3.0; // Height of crossbar (10 feet = 3.33 yards, rounded)
    const crossbarWidth = 5.8; // Width between uprights (18.5 feet = 6.17 yards)
    const postDiameter = 0.15; // Diameter of posts
    final postColor = Vector3(1.0, 0.9, 0.0); // Yellow

    // Position of goal posts (at back of end zones)
    final nearGoalZ = -(playingFieldLength / 2 + endZoneDepth) * yardsToUnits;
    final farGoalZ = (playingFieldLength / 2 + endZoneDepth) * yardsToUnits;

    // Create goal posts at both ends
    for (final goalZ in [nearGoalZ, farGoalZ]) {
      // Left upright
      final leftUpright = Mesh.cube(
        size: postDiameter,
        color: postColor,
      );
      final leftTransform = Transform3d(
        position: Vector3(-crossbarWidth / 2, postHeight / 2, goalZ),
        scale: Vector3(1, postHeight / postDiameter, 1),
      );

      // Right upright
      final rightUpright = Mesh.cube(
        size: postDiameter,
        color: postColor,
      );
      final rightTransform = Transform3d(
        position: Vector3(crossbarWidth / 2, postHeight / 2, goalZ),
        scale: Vector3(1, postHeight / postDiameter, 1),
      );

      // Crossbar
      final crossbar = Mesh.cube(
        size: postDiameter,
        color: postColor,
      );
      final crossbarTransform = Transform3d(
        position: Vector3(0, crossbarHeight, goalZ),
        scale: Vector3(crossbarWidth / postDiameter, 1, 1),
      );

      goalPosts.add((mesh: leftUpright, transform: leftTransform));
      goalPosts.add((mesh: rightUpright, transform: rightTransform));
      goalPosts.add((mesh: crossbar, transform: crossbarTransform));
    }

    return goalPosts;
  }
}
