import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state/wind_state.dart';

/// HUD wind compass showing wind direction and strength.
///
/// Small directional arrow in a screen corner. Arrow rotates with wind angle,
/// size/opacity scales with wind strength. Silver-white, compact, no overlap
/// with mana bars. Shows "DERECHO" warning label during active storms.
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
    final isDerecho = windState.isDerechoActive;
    final derechoInt = windState.derechoIntensity;
    // Opacity scales with wind strength (minimum 0.3 so always visible)
    final opacity = isDerecho ? 1.0 : 0.3 + strength * 0.7;

    // Reason: derecho pulses the border between orange and red for urgency
    final borderColor = isDerecho
        ? Color.lerp(
            const Color(0xFFFF6600),
            const Color(0xFFFF2200),
            (math.sin(DateTime.now().millisecondsSinceEpoch / 200.0) + 1) / 2 *
                derechoInt,
          )!
        : Color.lerp(
            const Color(0xFF333344),
            const Color(0xFFE0E0E0),
            strength,
          )!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Derecho warning label
        if (isDerecho)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withOpacity(0.85 * derechoInt),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
            ),
            child: Text(
              'DERECHO',
              style: TextStyle(
                color: Colors.orange.shade200,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        // Compass circle
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A).withOpacity(0.7),
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(
              color: borderColor,
              width: isDerecho ? 2.0 : 1.5,
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
                    painter: _WindArrowPainter(
                      strength: strength,
                      isDerecho: isDerecho,
                      derechoIntensity: derechoInt,
                    ),
                  ),
                ),
              ),
              // Strength text
              Positioned(
                bottom: 2,
                child: Text(
                  '${(windState.windStrengthPercent).toInt()}',
                  style: TextStyle(
                    color: isDerecho
                        ? Colors.orange.shade200.withOpacity(0.9)
                        : Colors.white.withOpacity(opacity * 0.8),
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the wind direction arrow.
class _WindArrowPainter extends CustomPainter {
  final double strength;
  final bool isDerecho;
  final double derechoIntensity;

  _WindArrowPainter({
    required this.strength,
    this.isDerecho = false,
    this.derechoIntensity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Reason: during derecho, arrow transitions from silver to orange
    final normalColor = Color.lerp(
      const Color(0xFF888899),
      const Color(0xFFF0F0FF),
      strength,
    )!;
    final derechoColor = Color.lerp(
      const Color(0xFFFF8800),
      const Color(0xFFFFCC44),
      strength,
    )!;

    final paint = Paint()
      ..color = isDerecho
          ? Color.lerp(normalColor, derechoColor, derechoIntensity)!
          : normalColor
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
      oldDelegate.strength != strength ||
      oldDelegate.isDerecho != isDerecho ||
      oldDelegate.derechoIntensity != derechoIntensity;
}
