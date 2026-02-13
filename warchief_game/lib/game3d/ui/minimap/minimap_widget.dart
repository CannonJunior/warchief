import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../rendering3d/camera3d.dart';
import '../../state/game_state.dart';
import '../../state/wind_state.dart';
import '../../state/minimap_config.dart';
import '../../state/minimap_state.dart';
import 'minimap_terrain_painter.dart';
import 'minimap_entity_painter.dart';
import 'minimap_border_icons.dart';
import 'minimap_ping_overlay.dart';

/// Circular minimap widget showing terrain, entities, ley lines, and pings.
///
/// Placed at top-right corner of the game screen. Replaces the standalone
/// WindIndicator — wind direction is shown as an arrow on the minimap border.
/// Click the minimap to create a ping visible on both the minimap and in
/// the 3D world view.
///
/// Layout:
///   Column(mainAxisSize: min)
///     Stack(clipBehavior: Clip.none)  // Allow sun icons to overflow
///       ClipOval                       // Circular mask
///         Stack
///           CustomPaint(TerrainPainter)
///           CustomPaint(EntityPainter)
///           CustomPaint(PingPainter)
///       MinimapBorderIcons             // Suns, zoom, wind arrow
///     Clock widget                     // Below minimap
class MinimapWidget extends StatelessWidget {
  final GameState gameState;
  final WindState windState;
  final Camera3D? camera;
  final void Function(double worldX, double worldZ) onPingCreated;

  const MinimapWidget({
    Key? key,
    required this.gameState,
    required this.windState,
    required this.camera,
    required this.onPingCreated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = globalMinimapConfig;
    final size = (config?.minimapSize ?? 160).toDouble();
    final borderW = (config?.borderWidth ?? 2).toDouble();
    final bgColor = _colorFromList(
        config?.backgroundColor ?? [0.04, 0.04, 0.10, 0.85]);
    final borderColor = _colorFromList(
        config?.borderColor ?? [0.15, 0.15, 0.26, 1.0]);

    final minimapState = gameState.minimapState;
    final playerX = gameState.playerTransform?.position.x ?? 0.0;
    final playerZ = gameState.playerTransform?.position.z ?? 0.0;
    final viewRadius = minimapState.viewRadius;
    final isRotating = minimapState.isRotatingMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minimap circle with border icons that can overflow
        SizedBox(
          width: size + 20, // Extra space for sun icons outside border
          height: size + 20,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Circular minimap with terrain, entities, pings
              GestureDetector(
                onTapDown: (details) => _handleTap(details, size, playerX,
                    playerZ, viewRadius, gameState.playerRotation, isRotating),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor,
                      width: borderW,
                    ),
                  ),
                  child: ClipOval(
                    child: Container(
                      color: bgColor,
                      child: Stack(
                        children: [
                          // Terrain layer
                          CustomPaint(
                            size: Size(size, size),
                            painter: MinimapTerrainPainter(
                              playerX: playerX,
                              playerZ: playerZ,
                              playerRotation: gameState.playerRotation,
                              viewRadius: viewRadius,
                              terrainManager:
                                  gameState.infiniteTerrainManager,
                              leyLineManager: gameState.leyLineManager,
                              minimapState: minimapState,
                            ),
                          ),
                          // Entity blips layer
                          CustomPaint(
                            size: Size(size, size),
                            painter: MinimapEntityPainter(
                              gameState: gameState,
                              viewRadius: viewRadius,
                              mapRotation: gameState.playerRotation,
                              isRotatingMode: isRotating,
                            ),
                          ),
                          // Ping overlay layer
                          CustomPaint(
                            size: Size(size, size),
                            painter: MinimapPingPainter(
                              playerX: playerX,
                              playerZ: playerZ,
                              playerRotation: gameState.playerRotation,
                              viewRadius: viewRadius,
                              pings: minimapState.pings,
                              elapsedTime: minimapState.elapsedTime,
                              isRotatingMode: isRotating,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Border icons: suns, zoom, wind arrow, north indicator, rotation toggle
              MinimapBorderIcons(
                size: size,
                elapsedTime: minimapState.elapsedTime,
                windState: windState,
                zoomLevel: minimapState.zoomLevel,
                zoomLevelCount:
                    (config?.zoomLevels.length ?? 4),
                onZoomIn: () => minimapState.zoomIn(),
                onZoomOut: () => minimapState.zoomOut(),
                playerRotation: gameState.playerRotation,
                isRotatingMode: isRotating,
                onToggleRotation: () {
                  minimapState.isRotatingMode = !minimapState.isRotatingMode;
                },
              ),
            ],
          ),
        ),
        // Clock below minimap
        _buildClock(minimapState),
      ],
    );
  }

  /// Convert tap position on the minimap to world coordinates and create ping.
  void _handleTap(TapDownDetails details, double size, double playerX,
      double playerZ, double viewRadius, double playerRotation,
      bool isRotating) {
    final localPos = details.localPosition;
    final half = size / 2;

    // Check if tap is within the circular area
    final dx = localPos.dx - half;
    final dy = localPos.dy - half;
    if (dx * dx + dy * dy > half * half) return;

    double worldX, worldZ;
    if (isRotating) {
      // Un-rotate from player-relative frame back to world
      final ndx = dx / half;
      final ndy = -dy / half;
      final rightComp = ndx * viewRadius;
      final fwdComp = ndy * viewRadius;
      final rotRad = playerRotation * math.pi / 180.0;
      final cosR = math.cos(rotRad);
      final sinR = math.sin(rotRad);
      worldX = playerX + rightComp * cosR - fwdComp * sinR;
      worldZ = playerZ - rightComp * sinR - fwdComp * cosR;
    } else {
      // Fixed-north with X negated to match screen-relative left/right
      worldX = playerX - (dx / half) * viewRadius;
      worldZ = playerZ - (dy / half) * viewRadius;
    }

    onPingCreated(worldX, worldZ);
  }

  /// Build the clock widget below the minimap.
  Widget _buildClock(MinimapState minimapState) {
    final config = globalMinimapConfig;
    if (!(config?.clockShowByDefault ?? true)) return const SizedBox.shrink();

    final fontSize = (config?.clockFontSize ?? 9).toDouble();
    final warchiefEnabled = config?.warchiefTimeEnabled ?? false;

    // Get current time string
    String timeString;
    if (minimapState.warchiefTimeMode && warchiefEnabled) {
      timeString = '??:??';
    } else {
      final now = DateTime.now();
      timeString =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      onTap: warchiefEnabled
          ? () {
              minimapState.warchiefTimeMode = !minimapState.warchiefTimeMode;
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A1A).withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFF252542),
            width: 1,
          ),
        ),
        child: Tooltip(
          message: minimapState.warchiefTimeMode
              ? 'Coming soon'
              : (warchiefEnabled ? 'Tap for Warchief time' : ''),
          child: Text(
            timeString,
            style: TextStyle(
              color: const Color(0xFFCCCCCC),
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  /// Convert [r, g, b, a] list to Color.
  static Color _colorFromList(List<double> rgba) {
    return Color.fromRGBO(
      (rgba[0] * 255).round(),
      (rgba[1] * 255).round(),
      (rgba[2] * 255).round(),
      rgba.length > 3 ? rgba[3] : 1.0,
    );
  }
}
