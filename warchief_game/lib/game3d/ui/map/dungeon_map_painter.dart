import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../rendering/tower_mesh.dart';
import '../../state/game_state.dart';
import '../../state/map_state.dart';

/// [CustomPainter] that renders a 2D overhead floor plan of the tower.
///
/// Draws the octagonal cross-section for all 7 floors, highlights the
/// currently viewed floor, and overlays player/ally/enemy dots.
class DungeonMapPainter extends CustomPainter {
  final GameState gameState;
  final MapState mapState;

  DungeonMapPainter({required this.gameState, required this.mapState});

  @override
  void paint(Canvas canvas, Size size) {
    final viewFloor = mapState.selectedFloor;

    // Draw all floors faintly
    for (int f = 0; f < TowerMesh.floorCount; f++) {
      _drawFloorOutline(canvas, size, f, active: f == viewFloor);
    }

    // Draw compass rose
    _drawCompass(canvas, size);

    // Draw door arrow (ground floor entrance)
    if (viewFloor == 0) {
      _drawDoorArrow(canvas, size);
    }

    // Draw stair indicators between floors
    _drawStairArrows(canvas, size, viewFloor);

    // Overlay entity dots
    _drawEntityDots(canvas, size);
  }

  // ==================== FLOOR OUTLINE ====================

  void _drawFloorOutline(Canvas canvas, Size size, int floor, {required bool active}) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final scale = math.min(cx, cy) * 0.75 / TowerMesh.exteriorRadius;

    final outerPath = _octPath(cx, cy, TowerMesh.exteriorRadius * scale);
    final innerPath = _octPath(cx, cy, TowerMesh.interiorRadius * scale);

    if (active) {
      // Active floor: filled grey ring
      final fillPaint = Paint()
        ..color = const Color(0xFF5A5A6A)
        ..style = PaintingStyle.fill;
      canvas.drawPath(outerPath, fillPaint);
      final clearPaint = Paint()
        ..color = const Color(0xFF2A2A35)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver;
      canvas.drawPath(innerPath, clearPaint);

      // Bright border
      final borderPaint = Paint()
        ..color = const Color(0xFFAAAAAA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(outerPath, borderPaint);
      canvas.drawPath(innerPath, borderPaint);
    } else {
      // Other floors: faint outline only
      final fadePaint = Paint()
        ..color = const Color(0x55888888)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawPath(outerPath, fadePaint);
    }
  }

  // ==================== OCTAGON PATH HELPER ====================

  Path _octPath(double cx, double cy, double r) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4.0;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  // ==================== DOOR ARROW ====================

  void _drawDoorArrow(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final scale = math.min(cx, cy) * 0.75 / TowerMesh.exteriorRadius;
    // Face 4 = angle 4*π/4 = π (pointing left = -X direction in our octagon)
    const faceAngle = 4 * math.pi / 4.0;
    final ax = cx + TowerMesh.exteriorRadius * scale * 1.15 * math.cos(faceAngle);
    final ay = cy + TowerMesh.exteriorRadius * scale * 1.15 * math.sin(faceAngle);

    final paint = Paint()
      ..color = const Color(0xFF80FF80)
      ..style = PaintingStyle.fill;

    // Draw small triangle arrow
    final path = Path()
      ..moveTo(ax, ay)
      ..lineTo(ax - 8 * math.cos(faceAngle + math.pi / 2), ay - 8 * math.sin(faceAngle + math.pi / 2))
      ..lineTo(ax - 8 * math.cos(faceAngle - math.pi / 2), ay - 8 * math.sin(faceAngle - math.pi / 2))
      ..close();
    canvas.drawPath(path, paint);
  }

  // ==================== STAIR ARROWS ====================

  void _drawStairArrows(Canvas canvas, Size size, int viewFloor) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final scale = math.min(cx, cy) * 0.75 / TowerMesh.exteriorRadius;
    final innerR = TowerMesh.interiorRadius * scale * 0.7;

    final paint = Paint()
      ..color = const Color(0xFFFFCC44)
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(color: Colors.yellow.shade200, fontSize: 9);

    // Up arrow (if not top floor)
    if (viewFloor < TowerMesh.floorCount - 1) {
      _drawArrowAt(canvas, cx + innerR * 0.5, cy - innerR * 0.5, true, paint, textStyle);
    }
    // Down arrow (if not ground floor)
    if (viewFloor > 0) {
      _drawArrowAt(canvas, cx - innerR * 0.5, cy + innerR * 0.5, false, paint, textStyle);
    }
  }

  void _drawArrowAt(Canvas canvas, double x, double y, bool up, Paint paint, TextStyle style) {
    final dir = up ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(x, y + dir * 8)
      ..lineTo(x - 5, y - dir * 4)
      ..lineTo(x + 5, y - dir * 4)
      ..close();
    canvas.drawPath(path, paint);

    final label = up ? '▲' : '▼';
    final tp = TextPainter(text: TextSpan(text: label, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y + dir * 9));
  }

  // ==================== ENTITY DOTS ====================

  void _drawEntityDots(Canvas canvas, Size size) {
    final cx    = size.width  / 2;
    final cy    = size.height / 2;
    final scale = math.min(cx, cy) * 0.75 / TowerMesh.exteriorRadius;

    void dot(double wx, double wz, Color color, double radius) {
      final sx = cx + (wx - TowerMesh.centerX) * scale;
      final sy = cy + (wz - TowerMesh.centerZ) * scale;
      canvas.drawCircle(Offset(sx, sy), radius,
          Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(sx, sy), radius,
          Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }

    // Player
    final pt = gameState.playerTransform;
    if (pt != null && gameState.isIndoors) {
      dot(pt.position.x, pt.position.z, Colors.yellow, 5);
    }

    // Allies
    for (final ally in gameState.allies) {
      final pos = ally.transform.position;
      final inTower = (math.sqrt(math.pow(pos.x - TowerMesh.centerX, 2) +
          math.pow(pos.z - TowerMesh.centerZ, 2))) < TowerMesh.exteriorRadius;
      if (inTower) dot(pos.x, pos.z, Colors.greenAccent, 4);
    }

    // Enemies inside tower
    for (final m in gameState.aliveMinions) {
      final pos = m.transform.position;
      final inTower = (math.sqrt(math.pow(pos.x - TowerMesh.centerX, 2) +
          math.pow(pos.z - TowerMesh.centerZ, 2))) < TowerMesh.exteriorRadius;
      if (inTower) dot(pos.x, pos.z, Colors.redAccent, 3.5);
    }
  }

  // ==================== COMPASS ====================

  void _drawCompass(Canvas canvas, Size size) {
    const offset = 16.0;
    final x = size.width - offset;
    final y = offset;
    final style = TextStyle(color: const Color(0xFFCCCCCC), fontSize: 9, fontWeight: FontWeight.bold);
    void label(String t, double dx, double dy) {
      final tp = TextPainter(text: TextSpan(text: t, style: style), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x + dx - tp.width / 2, y + dy - tp.height / 2));
    }
    label('N', 0, -10); label('S', 0, 10); label('W', -10, 0); label('E', 10, 0);
  }

  @override
  bool shouldRepaint(DungeonMapPainter old) =>
      old.mapState.selectedFloor != mapState.selectedFloor ||
      old.gameState.isIndoors    != gameState.isIndoors;
}
