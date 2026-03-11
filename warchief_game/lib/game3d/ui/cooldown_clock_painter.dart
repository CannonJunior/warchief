import 'package:flutter/material.dart';
import 'dart:math' as math;

// Reason: module-level Paint is allocated once for the app lifetime and reused
// across all CooldownClockPainter instances and frames.  Declaring it here
// avoids one heap allocation per paint() call (up to 10 buttons × 60 fps).
final _clockPaint = Paint()..style = PaintingStyle.fill;

/// CustomPainter for cooldown clock animation
/// Draws a sweeping overlay that reveals the ability as cooldown completes.
/// [overlayColor] defaults to dark; pass amber for combo-ready slots.
class CooldownClockPainter extends CustomPainter {
  final double progress; // 0.0 = just started cooldown, 1.0 = ready
  final Color overlayColor;

  CooldownClockPainter({
    required this.progress,
    this.overlayColor = const Color(0xB3000000), // Colors.black.withValues(alpha: 0.7)
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Reason: reuse the module-level Paint; just update color before drawing.
    _clockPaint.color = overlayColor;

    // Calculate sweep angle (starts at top, sweeps clockwise)
    // progress 0.0 = full circle (360°), progress 1.0 = no circle (0°)
    final sweepAngle = (1.0 - progress) * 2 * math.pi;

    // Draw arc from top (-π/2) sweeping clockwise
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top (12 o'clock)
      sweepAngle, // Sweep clockwise
      true, // Use center (filled pie slice)
      _clockPaint,
    );
  }

  @override
  bool shouldRepaint(CooldownClockPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.overlayColor != overlayColor;
  }
}
