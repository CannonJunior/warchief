import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CustomPainter for cooldown clock animation
/// Draws a sweeping dark overlay that reveals the ability as cooldown completes
class CooldownClockPainter extends CustomPainter {
  final double progress; // 0.0 = just started cooldown, 1.0 = ready

  CooldownClockPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dark overlay that sweeps clockwise as cooldown progresses
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Calculate sweep angle (starts at top, sweeps clockwise)
    // progress 0.0 = full circle (360°), progress 1.0 = no circle (0°)
    final sweepAngle = (1.0 - progress) * 2 * math.pi;

    // Draw arc from top (-π/2) sweeping clockwise
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top (12 o'clock)
      sweepAngle, // Sweep clockwise
      true, // Use center (filled pie slice)
      paint,
    );
  }

  @override
  bool shouldRepaint(CooldownClockPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
