import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';
import 'mesh.dart';
import 'math/transform3d.dart';

/// TerrainGenerator - Creates 3D terrain meshes for isometric world
///
/// Generates tile-based terrain similar to the old 2D isometric system,
/// but as true 3D meshes that can be viewed from any angle with camera pitch/yaw.
///
/// Usage:
/// ```dart
/// final terrain = TerrainGenerator.createTileGrid(
///   width: 20,
///   height: 20,
///   tileSize: 1.0,
/// );
/// ```
class TerrainGenerator {
  /// Create a grid of terrain tiles
  ///
  /// Returns a list of (mesh, transform) pairs - one for each tile.
  /// This allows individual tiles to have different heights/colors later.
  static List<TerrainTile> createTileGrid({
    required int width,
    required int height,
    double tileSize = 1.0,
    Vector3? baseColor,
  }) {
    final tiles = <TerrainTile>[];
    final color = baseColor ?? Vector3(0.4, 0.6, 0.3); // Default grass green

    // Create individual tile mesh (reused for all tiles)
    final tileMesh = Mesh.plane(
      width: tileSize,
      height: tileSize,
      color: color,
    );

    // Position each tile in a grid
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Center the grid around origin
        final posX = (x - width / 2) * tileSize + tileSize / 2;
        final posZ = (y - height / 2) * tileSize + tileSize / 2;

        final transform = Transform3d(
          position: Vector3(posX, 0, posZ),
        );

        tiles.add(TerrainTile(
          mesh: tileMesh,
          transform: transform,
          gridX: x,
          gridY: y,
        ));
      }
    }

    return tiles;
  }

  /// Create a single-mesh terrain (more efficient, but less flexible)
  ///
  /// Instead of separate tiles, creates one big mesh for the entire terrain.
  /// Better performance, but can't easily change individual tile heights.
  static Mesh createSingleMesh({
    required int width,
    required int height,
    double tileSize = 1.0,
    Vector3? baseColor,
  }) {
    final color = baseColor ?? Vector3(0.4, 0.6, 0.3);

    // Calculate vertex and index counts
    final vertexCount = (width + 1) * (height + 1);
    final triangleCount = width * height * 2;
    final indexCount = triangleCount * 3;

    // Allocate arrays
    final vertices = Float32List(vertexCount * 3);
    final normals = Float32List(vertexCount * 3);
    final colors = Float32List(vertexCount * 4);
    final indices = Uint16List(indexCount);

    // Generate vertices
    int vertIdx = 0;
    for (int y = 0; y <= height; y++) {
      for (int x = 0; x <= width; x++) {
        // Center grid around origin
        final posX = (x - width / 2.0) * tileSize;
        final posZ = (y - height / 2.0) * tileSize;

        vertices[vertIdx * 3 + 0] = posX;
        vertices[vertIdx * 3 + 1] = 0.0; // Flat terrain (Y=0)
        vertices[vertIdx * 3 + 2] = posZ;

        // Normal points up (Y+)
        normals[vertIdx * 3 + 0] = 0.0;
        normals[vertIdx * 3 + 1] = 1.0;
        normals[vertIdx * 3 + 2] = 0.0;

        // Vertex color
        colors[vertIdx * 4 + 0] = color.x;
        colors[vertIdx * 4 + 1] = color.y;
        colors[vertIdx * 4 + 2] = color.z;
        colors[vertIdx * 4 + 3] = 1.0;

        vertIdx++;
      }
    }

    // Generate indices (two triangles per tile)
    int idxIdx = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Vertex indices for this tile's corners
        final topLeft = y * (width + 1) + x;
        final topRight = topLeft + 1;
        final bottomLeft = (y + 1) * (width + 1) + x;
        final bottomRight = bottomLeft + 1;

        // First triangle (top-left, bottom-left, bottom-right)
        indices[idxIdx++] = topLeft;
        indices[idxIdx++] = bottomLeft;
        indices[idxIdx++] = bottomRight;

        // Second triangle (top-left, bottom-right, top-right)
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

  /// Create terrain with random height variation
  ///
  /// Similar to createSingleMesh, but with per-vertex height variation.
  /// Useful for hills, valleys, etc.
  static Mesh createHeightmapTerrain({
    required int width,
    required int height,
    double tileSize = 1.0,
    double maxHeight = 2.0,
    int? seed,
  }) {
    // TODO: Implement perlin noise or simplex noise for natural-looking terrain
    // For now, return flat terrain
    return createSingleMesh(
      width: width,
      height: height,
      tileSize: tileSize,
    );
  }
}

/// TerrainTile - Represents a single tile in the terrain grid
///
/// Contains mesh, transform, and grid position for easy tile manipulation.
class TerrainTile {
  final Mesh mesh;
  final Transform3d transform;
  final int gridX;
  final int gridY;

  /// Tile height (can be modified for elevation changes)
  double height = 0.0;

  TerrainTile({
    required this.mesh,
    required this.transform,
    required this.gridX,
    required this.gridY,
    this.height = 0.0,
  });

  /// Set tile height (updates transform Y position)
  void setHeight(double newHeight) {
    height = newHeight;
    transform.position.y = newHeight;
  }

  /// Check if a world position is within this tile's bounds
  bool containsPoint(Vector3 worldPos, double tileSize) {
    final dx = (worldPos.x - transform.position.x).abs();
    final dz = (worldPos.z - transform.position.z).abs();
    return dx <= tileSize / 2 && dz <= tileSize / 2;
  }

  @override
  String toString() {
    return 'TerrainTile(grid: [$gridX, $gridY], height: $height)';
  }
}
