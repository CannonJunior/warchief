import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Rotatable isometric cube painter for the character panel paper doll.
///
/// Projects a 3D cube onto screen using a dimetric/isometric projection.
/// All vertices rotate rigidly around the vertical Y axis, so dragging
/// turns the cube smoothly without distortion.
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

    final rotRad = rotation * math.pi / 180.0;
    final cosR = math.cos(rotRad);
    final sinR = math.sin(rotRad);

    // Isometric projection scales
    final xScale = size.width * 0.32; // horizontal half-extent of diamond
    final yScale = size.height * 0.15; // depth half-extent (diamond flatness)
    final sideH = size.height * 0.38; // vertical height of the side faces

    // Vertical center of the top diamond (offset slightly upward)
    final topCenterY = centerY - sideH * 0.25;

    // 4 vertical edges of the cube, rotated in the XZ plane.
    // At θ=0: front=(0,-1), left=(-1,0), right=(1,0), back=(0,1)
    // After Y-axis rotation by θ, projected to screen offsets:
    //   screenX = x_rotated * xScale
    //   screenY = z_rotated * yScale (positive z = toward viewer = down)
    final frontSX = sinR * xScale;
    final frontSY = cosR * yScale;

    final leftSX = -cosR * xScale;
    final leftSY = sinR * yScale;

    final rightSX = cosR * xScale;
    final rightSY = -sinR * yScale;

    final backSX = -sinR * xScale;
    final backSY = -cosR * yScale;

    // Top face vertices
    final topBack = Offset(centerX + backSX, topCenterY + backSY);
    final topLeft = Offset(centerX + leftSX, topCenterY + leftSY);
    final topRight = Offset(centerX + rightSX, topCenterY + rightSY);
    final topFront = Offset(centerX + frontSX, topCenterY + frontSY);

    // Bottom face vertices (displaced down by sideH)
    final botLeft = Offset(centerX + leftSX, topCenterY + leftSY + sideH);
    final botRight = Offset(centerX + rightSX, topCenterY + rightSY + sideH);
    final botFront = Offset(centerX + frontSX, topCenterY + frontSY + sideH);

    // Face visibility (alpha modulation based on rotation)
    final leftAlpha = (0.5 + 0.5 * cosR).clamp(0.2, 1.0);
    final rightAlpha = (0.5 - 0.5 * cosR).clamp(0.2, 1.0);

    // Draw left face: topLeft → topFront → botFront → botLeft
    final leftPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topFront.dx, topFront.dy)
      ..lineTo(botFront.dx, botFront.dy)
      ..lineTo(botLeft.dx, botLeft.dy)
      ..close();
    canvas.drawPath(
      leftPath,
      Paint()..color = leftColor.withValues(alpha: leftAlpha),
    );

    // Draw right face: topRight → topFront → botFront → botRight
    final rightPath = Path()
      ..moveTo(topRight.dx, topRight.dy)
      ..lineTo(topFront.dx, topFront.dy)
      ..lineTo(botFront.dx, botFront.dy)
      ..lineTo(botRight.dx, botRight.dy)
      ..close();
    canvas.drawPath(
      rightPath,
      Paint()..color = rightColor.withValues(alpha: rightAlpha),
    );

    // Draw top face: topBack → topLeft → topFront → topRight
    final topPath = Path()
      ..moveTo(topBack.dx, topBack.dy)
      ..lineTo(topLeft.dx, topLeft.dy)
      ..lineTo(topFront.dx, topFront.dy)
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

    // Draw "face" indicator eyes on the front side
    final eyeY = topCenterY + frontSY + sideH * 0.3;
    final eyeSpacing = size.width * 0.06;
    final eyePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final eyeRadius = size.width * 0.025;

    // Eyes follow the front face position
    final eyeCenterX = centerX + frontSX * 0.5;
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
