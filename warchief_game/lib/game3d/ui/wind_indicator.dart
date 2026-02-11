import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state/wind_state.dart';

/// HUD wind compass showing wind direction and strength.
///
/// Small directional arrow in a screen corner. Arrow rotates with wind angle,
/// size/opacity scales with wind strength. Silver-white, compact, no overlap
/// with mana bars.
class WindIndicator extends StatelessWidget {
  final WindState windState;
  final double size;

  const WindIndicator({
    Key? key,
    required this.windState,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final strength = windState.windStrength;
    final angleDeg = windState.windAngleDegrees;
    // Opacity scales with wind strength (minimum 0.3 so always visible)
    final opacity = 0.3 + strength * 0.7;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A).withOpacity(0.7),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Color.lerp(
            const Color(0xFF333344),
            const Color(0xFFE0E0E0),
            strength,
          )!,
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wind direction arrow
          Transform.rotate(
            angle: angleDeg * math.pi / 180.0,
            child: Opacity(
              opacity: opacity,
              child: CustomPaint(
                size: Size(size * 0.6, size * 0.6),
                painter: _WindArrowPainter(strength: strength),
              ),
            ),
          ),
          // Strength text
          Positioned(
            bottom: 2,
            child: Text(
              '${(strength * 100).toInt()}',
              style: TextStyle(
                color: Colors.white.withOpacity(opacity * 0.8),
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the wind direction arrow.
class _WindArrowPainter extends CustomPainter {
  final double strength;

  _WindArrowPainter({required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.lerp(
        const Color(0xFF888899),
        const Color(0xFFF0F0FF),
        strength,
      )!
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final halfW = size.width * 0.25;
    final halfH = size.height * 0.45;

    // Arrow pointing up (rotation applied by Transform.rotate parent)
    final path = Path()
      ..moveTo(cx, cy - halfH) // Top point
      ..lineTo(cx + halfW, cy + halfH * 0.5) // Bottom right
      ..lineTo(cx, cy + halfH * 0.2) // Bottom notch
      ..lineTo(cx - halfW, cy + halfH * 0.5) // Bottom left
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WindArrowPainter oldDelegate) =>
      oldDelegate.strength != strength;
}
