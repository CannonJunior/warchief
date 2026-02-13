import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vm;
import '../../state/minimap_state.dart';
import '../../state/minimap_config.dart';
import '../../utils/screen_projection.dart';

/// CustomPainter that renders ping animations on the minimap.
///
/// Each ping displays as expanding concentric rings that fade over time.
/// Ring count, max radius, and color are all config-driven.
class MinimapPingPainter extends CustomPainter {
  final double playerX;
  final double playerZ;
  final double viewRadius;
  final List<MinimapPing> pings;
  final double elapsedTime;

  MinimapPingPainter({
    required this.playerX,
    required this.playerZ,
    required this.viewRadius,
    required this.pings,
    required this.elapsedTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pings.isEmpty) return;

    final config = globalMinimapConfig;
    final ringCount = config?.pingRingCount ?? 3;
    final maxRingRadius = config?.pingMaxRingRadius ?? 20.0;
    final half = size.width / 2;

    for (final ping in pings) {
      final pos = _worldToMinimap(ping.worldX, ping.worldZ, half);
      if (pos == null) continue;

      final age = ping.normalizedAge(elapsedTime);
      final alpha = (1.0 - age).clamp(0.0, 1.0);

      // Draw expanding concentric rings
      for (int i = 0; i < ringCount; i++) {
        // Stagger ring expansion so they appear one after another
        final ringDelay = i * 0.15;
        final ringAge = ((age - ringDelay) / (1.0 - ringDelay))
            .clamp(0.0, 1.0);
        if (ringAge <= 0) continue;

        final ringRadius = ringAge * maxRingRadius;
        final ringAlpha = alpha * (1.0 - ringAge) * 0.8;

        if (ringAlpha <= 0.01) continue;

        final paint = Paint()
          ..color = ping.color.withOpacity(ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawCircle(pos, ringRadius, paint);
      }

      // Draw central dot that fades
      final dotPaint = Paint()
        ..color = ping.color.withOpacity(alpha * 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 3.0 * (1.0 - age * 0.5), dotPaint);
    }
  }

  /// Convert world coordinates to minimap pixel position.
  Offset? _worldToMinimap(double worldX, double worldZ, double half) {
    final dx = worldX - playerX;
    final dz = worldZ - playerZ;

    final mx = half + (dx / viewRadius) * half;
    final my = half - (dz / viewRadius) * half;

    // Check within circular bounds (allow slight overflow for ping rings)
    final rdx = mx - half;
    final rdy = my - half;
    if (rdx * rdx + rdy * rdy > (half + 20) * (half + 20)) return null;

    return Offset(mx, my);
  }

  @override
  bool shouldRepaint(MinimapPingPainter oldDelegate) => true;
}

/// World-space ping overlay rendered in the 3D game view.
///
/// Projects ping positions from world space to screen space and renders
/// a pulsing diamond icon. If the ping is off-screen, shows a directional
/// arrow at the screen edge pointing toward the ping.
class MinimapPingWorldOverlay extends StatelessWidget {
  final List<MinimapPing> pings;
  final double elapsedTime;
  final vm.Matrix4? viewMatrix;
  final vm.Matrix4? projMatrix;
  final Size screenSize;

  const MinimapPingWorldOverlay({
    Key? key,
    required this.pings,
    required this.elapsedTime,
    required this.viewMatrix,
    required this.projMatrix,
    required this.screenSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pings.isEmpty || viewMatrix == null || projMatrix == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: pings.map((ping) => _buildPingIndicator(ping)).toList(),
    );
  }

  /// Build a world-space ping indicator for a single ping.
  Widget _buildPingIndicator(MinimapPing ping) {
    final age = ping.normalizedAge(elapsedTime);
    final alpha = (1.0 - age).clamp(0.0, 1.0);
    if (alpha <= 0.01) return const SizedBox.shrink();

    final config = globalMinimapConfig;
    final indicatorSize =
        (config?.pingWorldIndicatorSize ?? 32).toDouble();

    // Project ping world position to screen
    // Reason: pings are on the XZ plane, Y=0 for screen projection
    final worldPos = vm.Vector3(ping.worldX, 0.5, ping.worldZ);
    final screenPos = worldToScreen(
        worldPos, viewMatrix!, projMatrix!, screenSize);

    if (screenPos == null) {
      // Behind camera — show edge indicator
      return _buildEdgeIndicator(ping, alpha, indicatorSize);
    }

    // Check if on-screen
    if (screenPos.dx < -indicatorSize ||
        screenPos.dx > screenSize.width + indicatorSize ||
        screenPos.dy < -indicatorSize ||
        screenPos.dy > screenSize.height + indicatorSize) {
      return _buildEdgeIndicator(ping, alpha, indicatorSize);
    }

    // Pulsing scale animation
    final pulse = 1.0 + math.sin(elapsedTime * 4.0) * 0.15 * alpha;

    return Positioned(
      left: screenPos.dx - indicatorSize / 2,
      top: screenPos.dy - indicatorSize / 2,
      child: Opacity(
        opacity: alpha,
        child: Transform.scale(
          scale: pulse,
          child: CustomPaint(
            size: Size(indicatorSize, indicatorSize),
            painter: _PingDiamondPainter(color: ping.color),
          ),
        ),
      ),
    );
  }

  /// Build an edge arrow indicator when ping is off-screen.
  Widget _buildEdgeIndicator(
      MinimapPing ping, double alpha, double indicatorSize) {
    // Calculate direction from screen center to ping
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    // Simple approach: project ping, then clamp to screen edges
    final worldPos = vm.Vector3(ping.worldX, 0.5, ping.worldZ);
    final screenPos = worldToScreen(
        worldPos, viewMatrix!, projMatrix!, screenSize);

    double targetX, targetY;
    if (screenPos != null) {
      targetX = screenPos.dx;
      targetY = screenPos.dy;
    } else {
      // Behind camera: place at bottom edge
      targetX = centerX;
      targetY = screenSize.height + 100;
    }

    // Direction from center to target
    final dx = targetX - centerX;
    final dy = targetY - centerY;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return const SizedBox.shrink();

    // Clamp to screen edge with margin
    const margin = 40.0;
    final edgeX = (centerX + dx / dist * (centerX - margin))
        .clamp(margin, screenSize.width - margin);
    final edgeY = (centerY + dy / dist * (centerY - margin))
        .clamp(margin, screenSize.height - margin);

    final angle = math.atan2(dy, dx);

    return Positioned(
      left: edgeX - indicatorSize / 4,
      top: edgeY - indicatorSize / 4,
      child: Opacity(
        opacity: alpha * 0.7,
        child: Transform.rotate(
          angle: angle,
          child: Icon(
            Icons.arrow_forward,
            color: ping.color,
            size: indicatorSize / 2,
          ),
        ),
      ),
    );
  }
}

/// Diamond-shaped ping icon painter for world-space rendering.
class _PingDiamondPainter extends CustomPainter {
  final Color color;

  _PingDiamondPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final halfW = size.width * 0.35;
    final halfH = size.height * 0.35;

    final path = Path()
      ..moveTo(cx, cy - halfH)
      ..lineTo(cx + halfW, cy)
      ..lineTo(cx, cy + halfH)
      ..lineTo(cx - halfW, cy)
      ..close();

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Fill
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PingDiamondPainter oldDelegate) =>
      oldDelegate.color != color;
}
