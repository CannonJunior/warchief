import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Draws a pre-projected world-space range circle on the Flutter canvas.
///
/// Callers supply [projectedPoints] — a list of screen-space [Offset]s
/// (nulls are skipped, causing path breaks for points behind the camera).
/// This avoids importing vector_math in a standalone file, which would
/// conflict with Flutter's vector_math_64 transitive import.
class RangeCircleOverlay extends StatelessWidget {
  final List<Offset?> projectedPoints;

  const RangeCircleOverlay({
    super.key,
    required this.projectedPoints,
  });

  @override
  Widget build(BuildContext context) {
    if (projectedPoints.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _RangeCirclePainter(projectedPoints: projectedPoints),
      ),
    );
  }
}

class _RangeCirclePainter extends CustomPainter {
  final List<Offset?> projectedPoints;

  const _RangeCirclePainter({required this.projectedPoints});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xCCFFAA00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    bool pathStarted = false;

    for (final pt in projectedPoints) {
      if (pt == null) {
        pathStarted = false;
        continue;
      }
      if (!pathStarted) {
        path.moveTo(pt.dx, pt.dy);
        pathStarted = true;
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RangeCirclePainter old) =>
      old.projectedPoints != projectedPoints;
}

/// Number of polygon segments used to approximate the circle.
const int kRangeCircleSegments = 64;

/// Build the list of world-angle steps for a range circle.
/// Returns angles [0, 2π] with [kRangeCircleSegments] + 1 entries (closed).
List<double> buildRangeCircleAngles() => List.generate(
      kRangeCircleSegments + 1,
      (i) => 2.0 * math.pi * i / kRangeCircleSegments,
    );
