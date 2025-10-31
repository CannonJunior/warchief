import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Simple isometric map renderer
///
/// Creates a grid of isometric tiles for the game world.
/// This is a basic implementation - will be enhanced in Phase 2.
class IsometricMap extends Component {
  /// Map dimensions (in tiles)
  final int width;
  final int height;

  /// Tile size (width of the tile diamond)
  final double tileWidth;
  final double tileHeight;

  /// List of tile components
  final List<IsometricTile> tiles = [];

  IsometricMap({
    this.width = 20,
    this.height = 20,
    this.tileWidth = 64,
    this.tileHeight = 32,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Generate tiles
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final tile = IsometricTile(
          gridX: x,
          gridY: y,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
        );
        tiles.add(tile);
        add(tile);
      }
    }
  }

  /// Convert grid coordinates to screen position
  Vector2 gridToScreen(int gridX, int gridY) {
    final screenX = (gridX - gridY) * (tileWidth / 2);
    final screenY = (gridX + gridY) * (tileHeight / 2);
    return Vector2(screenX, screenY);
  }

  /// Convert screen position to grid coordinates
  Vector2 screenToGrid(double screenX, double screenY) {
    final gridX = (screenX / (tileWidth / 2) + screenY / (tileHeight / 2)) / 2;
    final gridY = (screenY / (tileHeight / 2) - screenX / (tileWidth / 2)) / 2;
    return Vector2(gridX, gridY);
  }
}

/// Individual isometric tile
class IsometricTile extends PositionComponent {
  final int gridX;
  final int gridY;
  final double tileWidth;
  final double tileHeight;

  /// Tile color (alternating pattern for visibility)
  late Color tileColor;

  IsometricTile({
    required this.gridX,
    required this.gridY,
    required this.tileWidth,
    required this.tileHeight,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Calculate screen position from grid coordinates
    final screenX = (gridX - gridY) * (tileWidth / 2);
    final screenY = (gridX + gridY) * (tileHeight / 2);
    position = Vector2(screenX, screenY);

    // Alternating tile colors (checkerboard pattern)
    final isLight = (gridX + gridY) % 2 == 0;
    tileColor = isLight ? const Color(0xFF4A5568) : const Color(0xFF2D3748);

    // Create the tile visual
    add(_createTileVisual());
  }

  /// Create the diamond-shaped tile visual
  Component _createTileVisual() {
    return CustomPainterComponent(
      painter: _IsometricTilePainter(
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        color: tileColor,
      ),
      size: Vector2(tileWidth, tileHeight),
      anchor: Anchor.center,
    );
  }
}

/// Custom painter for isometric tile
class _IsometricTilePainter extends CustomPainter {
  final double tileWidth;
  final double tileHeight;
  final Color color;

  _IsometricTilePainter({
    required this.tileWidth,
    required this.tileHeight,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Diamond shape (isometric tile)
    final path = Path()
      ..moveTo(tileWidth / 2, 0) // Top
      ..lineTo(tileWidth, tileHeight / 2) // Right
      ..lineTo(tileWidth / 2, tileHeight) // Bottom
      ..lineTo(0, tileHeight / 2) // Left
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
