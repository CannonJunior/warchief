import 'package:flutter/material.dart';
import '../../state/game_state.dart';
import '../../state/map_state.dart';
import '../../rendering/tower_mesh.dart';
import 'world_map_painter.dart';
import 'dungeon_map_painter.dart';

/// Full-screen World Map overlay (WoW-style).
///
/// Covers 80 % of the screen, centred, with a dark semi-transparent
/// background. Displays:
/// - [WorldMapPainter] when outdoors — zoom-able terrain survey
/// - [DungeonMapPainter] when inside the tower — octagonal floor plan
///
/// Toggle with M key (4-state cycle defined in game3d_widget_input.dart).
class MapPanel extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onClose;

  const MapPanel({super.key, required this.gameState, required this.onClose});

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final width  = size.width  * 0.80;
    final height = size.height * 0.80;
    final isIndoors = gameState.isIndoors;
    final mapState  = gameState.mapState;

    // Sync map mode to zone
    if (isIndoors && mapState.mode != MapMode.dungeon) {
      mapState.mode = MapMode.dungeon;
    } else if (!isIndoors && mapState.mode != MapMode.world) {
      mapState.mode = MapMode.world;
    }

    return Center(
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: const Color(0xCC0D1117),
          border: Border.all(color: const Color(0xFF4A4A5E), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _buildTitleBar(context, isIndoors),
            Expanded(
              child: Row(
                children: [
                  if (isIndoors) _buildFloorButtons(context, mapState),
                  Expanded(
                    child: GestureDetector(
                      onPanUpdate: isIndoors ? null : (details) {
                        // Reason: drag pans the world map view;
                        // scale factor converts pixel delta to world units.
                        final scale = (2.0 * mapState.viewRadius) / (width - (isIndoors ? 60 : 0));
                        mapState.pan(-details.delta.dx * scale, -details.delta.dy * scale);
                      },
                      child: CustomPaint(
                        painter: isIndoors
                            ? DungeonMapPainter(gameState: gameState, mapState: mapState)
                            : WorldMapPainter(
                                playerX: gameState.playerTransform?.position.x ?? 0,
                                playerZ: gameState.playerTransform?.position.z ?? 0,
                                terrainManager: gameState.infiniteTerrainManager,
                                mapState: mapState,
                              ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isIndoors) _buildZoomBar(context, mapState),
          ],
        ),
      ),
    );
  }

  // ==================== TITLE BAR ====================

  Widget _buildTitleBar(BuildContext context, bool isIndoors) {
    final title = isIndoors
        ? 'Tower — Floor ${gameState.currentFloor + 1}'
        : 'World Map';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF4A4A5E))),
      ),
      child: Row(
        children: [
          const Icon(Icons.map, color: Color(0xFF9090CC), size: 16),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                color: Color(0xFFCCCCEE),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              )),
          const Spacer(),
          // Reset pan button (world map only)
          if (!isIndoors)
            _iconBtn(Icons.my_location, 'Reset view', () {
              gameState.mapState.resetPan();
            }),
          const SizedBox(width: 4),
          _iconBtn(Icons.close, 'Close (M)', onClose),
        ],
      ),
    );
  }

  // ==================== FLOOR SELECTOR (DUNGEON) ====================

  Widget _buildFloorButtons(BuildContext context, MapState mapState) {
    return Container(
      width: 56,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFF4A4A5E))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          for (int f = TowerMesh.floorCount - 1; f >= 0; f--)
            _floorBtn(f, mapState),
        ],
      ),
    );
  }

  Widget _floorBtn(int floor, MapState mapState) {
    final isSelected = mapState.selectedFloor == floor;
    final isCurrent  = gameState.currentFloor == floor && gameState.isIndoors;

    return GestureDetector(
      onTap: () => mapState.selectedFloor = floor,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3A3A5A)
              : const Color(0xFF1A1A2A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFF8888CC) : const Color(0xFF333348),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('${floor + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF888898),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
            // Yellow dot = player is here
            if (isCurrent)
              const Positioned(
                right: 2, top: 2,
                child: CircleAvatar(radius: 3, backgroundColor: Colors.yellow),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== ZOOM BAR (WORLD MAP) ====================

  Widget _buildZoomBar(BuildContext context, MapState mapState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF4A4A5E))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconBtn(Icons.remove, 'Zoom out', mapState.zoomOut),
          const SizedBox(width: 8),
          Text(mapState.zoomLabel,
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
          const SizedBox(width: 8),
          _iconBtn(Icons.add, 'Zoom in', mapState.zoomIn),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: const Color(0xFF9090CC), size: 16),
        ),
      ),
    );
  }
}
