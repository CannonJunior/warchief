import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Rotatable isometric cube painter for the character panel paper doll.
///
/// Based on the _IsometricCubePainter pattern from combat_hud.dart.
/// Accepts a rotation angle (0-360) that shifts the center vertex
/// horizontally via sin(rotation) to simulate 3D rotation.
class RotatableCubePainter extends CustomPainter {
  final Color baseColor;
  final double rotation;

  RotatableCubePainter({
    required this.baseColor,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Derive face colors from base color
    final topColor = Color.lerp(baseColor, Colors.white, 0.3)!;
    final leftColor = Color.lerp(baseColor, Colors.black, 0.35)!;
    final rightColor = Color.lerp(baseColor, Colors.black, 0.2)!;

    // Isometric projection factors
    final cubeWidth = size.width * 0.7;
    final cubeHeight = size.height * 0.4;
    final sideHeight = size.height * 0.5;

    // Rotation shifts the center vertex horizontally to simulate turning
    final rotRad = rotation * math.pi / 180.0;
    final shift = math.sin(rotRad) * cubeWidth * 0.4;

    // 6 vertices of the visible isometric cube
    final top = Offset(centerX + shift * 0.3, centerY - sideHeight * 0.6);
    final topLeft = Offset(centerX - cubeWidth / 2, centerY - cubeHeight / 2);
    final topRight = Offset(centerX + cubeWidth / 2, centerY - cubeHeight / 2);
    final center = Offset(centerX + shift, centerY + cubeHeight * 0.1);
    final bottomLeft = Offset(centerX - cubeWidth / 2, centerY + sideHeight * 0.4);
    final bottomRight = Offset(centerX + cubeWidth / 2, centerY + sideHeight * 0.4);
    final bottom = Offset(centerX + shift * 0.3, centerY + sideHeight * 0.7);

    // Calculate face visibility based on rotation for opacity modulation
    final leftAlpha = (0.5 + 0.5 * math.cos(rotRad)).clamp(0.2, 1.0);
    final rightAlpha = (0.5 - 0.5 * math.cos(rotRad)).clamp(0.2, 1.0);

    // Draw left face
    final leftPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    canvas.drawPath(
      leftPath,
      Paint()..color = leftColor.withValues(alpha: leftAlpha),
    );

    // Draw right face
    final rightPath = Path()
      ..moveTo(topRight.dx, topRight.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..close();
    canvas.drawPath(
      rightPath,
      Paint()..color = rightColor.withValues(alpha: rightAlpha),
    );

    // Draw top face
    final topPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(topLeft.dx, topLeft.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor);

    // Draw subtle edge lines
    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(topPath, edgePaint);
    canvas.drawPath(leftPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);

    // Draw a subtle "face" indicator on the front-facing side
    final eyeY = centerY - sideHeight * 0.1;
    final eyeSpacing = cubeWidth * 0.12;
    final eyePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final eyeRadius = size.width * 0.025;

    // Shift eyes with rotation
    final eyeCenterX = centerX + shift * 0.5;
    canvas.drawCircle(
      Offset(eyeCenterX - eyeSpacing, eyeY),
      eyeRadius,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(eyeCenterX + eyeSpacing, eyeY),
      eyeRadius,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant RotatableCubePainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.baseColor != baseColor;
  }
}

/// Convenience widget wrapping RotatableCubePainter in a fixed-size box.
class RotatableCubePortrait extends StatelessWidget {
  final Color color;
  final double size;
  final double rotation;

  const RotatableCubePortrait({
    Key? key,
    required this.color,
    this.size = 120,
    this.rotation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: RotatableCubePainter(
          baseColor: color,
          rotation: rotation,
        ),
      ),
    );
  }
}
