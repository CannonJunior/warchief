import 'dart:math' as math;
import 'package:flutter/material.dart' hide Matrix4;
import 'package:vector_math/vector_math.dart' hide Colors;

import '../../rendering3d/camera3d.dart';
import '../utils/screen_projection.dart';

/// A single floating damage number above a target
class DamageIndicator {
  /// Damage amount to display
  final double damage;

  /// World-space position where damage occurred (target's position)
  final Vector3 worldPosition;

  /// Whether this was a melee hit (rises faster, shorter lifetime)
  final bool isMelee;

  /// Whether this hit killed the target
  final bool isKillingBlow;

  /// Time elapsed since creation
  double age = 0.0;

  /// Random horizontal offset to prevent stacking
  final double xJitter;

  DamageIndicator({
    required this.damage,
    required this.worldPosition,
    this.isMelee = false,
    this.isKillingBlow = false,
  }) : xJitter = (math.Random().nextDouble() - 0.5) * 30.0;

  /// Maximum lifetime in seconds
  double get maxAge => isMelee ? 1.5 : 3.0;

  /// Whether this indicator has expired
  bool get isExpired => age >= maxAge;

  /// Normalized progress (0.0 = just spawned, 1.0 = about to expire)
  double get progress => (age / maxAge).clamp(0.0, 1.0);
}

/// Manages all active damage indicators and renders them as Flutter overlays
class DamageIndicatorOverlay extends StatelessWidget {
  final List<DamageIndicator> indicators;
  final Camera3D? camera;
  final double canvasWidth;
  final double canvasHeight;

  const DamageIndicatorOverlay({
    Key? key,
    required this.indicators,
    required this.camera,
    required this.canvasWidth,
    required this.canvasHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (camera == null || indicators.isEmpty) return const SizedBox.shrink();

    final viewMatrix = camera!.getViewMatrix();
    final projMatrix = camera!.getProjectionMatrix();
    final screenSize = MediaQuery.of(context).size;

    final children = <Widget>[];

    for (final indicator in indicators) {
      final screenPos = worldToScreen(
        indicator.worldPosition,
        viewMatrix,
        projMatrix,
        screenSize,
      );

      if (screenPos != null) {
        children.add(_buildIndicatorWidget(indicator, screenPos, screenSize));
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: children,
      ),
    );
  }

  Widget _buildIndicatorWidget(
    DamageIndicator indicator,
    Offset screenPos,
    Size screenSize,
  ) {
    final progress = indicator.progress;

    // Vertical rise: melee rises faster
    final riseSpeed = indicator.isMelee ? 120.0 : 60.0;
    // Ease out: starts fast, slows down
    final easedProgress = 1.0 - math.pow(1.0 - progress, 2.0);
    final yOffset = -easedProgress * riseSpeed;

    // Opacity: fade out in the last 30% of lifetime
    final fadeStart = 0.7;
    final opacity = progress > fadeStart
        ? (1.0 - (progress - fadeStart) / (1.0 - fadeStart)).clamp(0.0, 1.0)
        : 1.0;

    // Color: yellow normally, transitions to red on killing blow
    Color textColor;
    if (indicator.isKillingBlow) {
      // Start yellow, transition to red
      final redProgress = (progress * 2.0).clamp(0.0, 1.0);
      textColor = Color.lerp(
        const Color(0xFFFFDD00), // bright yellow
        const Color(0xFFFF2222), // bright red
        redProgress,
      )!;
    } else {
      textColor = const Color(0xFFFFDD00); // bright yellow
    }

    // Font size: starts large, shrinks slightly
    final baseFontSize = indicator.isMelee ? 30.0 : 33.0;
    // Brief scale-up at the start
    final scaleT = progress < 0.1 ? 1.0 + (0.1 - progress) * 3.0 : 1.0;
    final fontSize = baseFontSize * scaleT;

    final x = screenPos.dx + indicator.xJitter;
    final y = screenPos.dy + yOffset - 40.0; // Start above the unit

    // Don't render if off-screen
    if (x < -50 || x > screenSize.width + 50 ||
        y < -50 || y > screenSize.height + 50) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: x - 40,
      top: y - 12,
      child: IgnorePointer(
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sparkle trail for killing blows
              if (indicator.isKillingBlow && progress > 0.05)
                _buildSparkleTrail(indicator, progress, opacity),
              // Damage number
              Text(
                indicator.damage.round().toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withOpacity(opacity),
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(opacity * 0.9),
                      blurRadius: 3,
                      offset: const Offset(1, 1),
                    ),
                    Shadow(
                      color: Colors.black.withOpacity(opacity * 0.7),
                      blurRadius: 6,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Red sparkle trail beneath killing blow numbers
  Widget _buildSparkleTrail(
    DamageIndicator indicator,
    double progress,
    double opacity,
  ) {
    // Generate sparkle positions based on age
    final sparkleCount = 5;
    final rng = math.Random(indicator.damage.round());

    return SizedBox(
      width: 80,
      height: 20,
      child: CustomPaint(
        painter: _SparkleTrailPainter(
          progress: progress,
          opacity: opacity,
          sparkleCount: sparkleCount,
          rng: rng,
          age: indicator.age,
        ),
      ),
    );
  }
}

/// Paints sparkly red particles trailing beneath a killing blow number
class _SparkleTrailPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final int sparkleCount;
  final math.Random rng;
  final double age;

  _SparkleTrailPainter({
    required this.progress,
    required this.opacity,
    required this.sparkleCount,
    required this.rng,
    required this.age,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < sparkleCount; i++) {
      // Each sparkle has its own seed-based position and timing
      final seedX = rng.nextDouble();
      final seedY = rng.nextDouble();
      final seedPhase = rng.nextDouble();
      final seedSize = rng.nextDouble();

      // Sparkles twinkle based on age and phase offset
      final twinkle = (math.sin((age * 8.0) + seedPhase * math.pi * 2) + 1.0) / 2.0;

      // Sparkle position spreads as progress increases
      final x = size.width * 0.2 + seedX * size.width * 0.6;
      final y = seedY * size.height;

      // Size and opacity based on twinkle
      final sparkleSize = (1.5 + seedSize * 2.5) * twinkle;
      final sparkleOpacity = (opacity * twinkle * 0.8).clamp(0.0, 1.0);

      // Color: mix of red and orange-red
      final red = Color.lerp(
        const Color(0xFFFF4444),
        const Color(0xFFFF8800),
        seedPhase,
      )!;

      paint.color = red.withOpacity(sparkleOpacity);
      canvas.drawCircle(Offset(x, y), sparkleSize, paint);

      // Add a glow around larger sparkles
      if (sparkleSize > 2.0) {
        paint.color = red.withOpacity(sparkleOpacity * 0.3);
        canvas.drawCircle(Offset(x, y), sparkleSize * 2.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleTrailPainter oldDelegate) => true;
}

/// Static utility to update all damage indicators
void updateDamageIndicators(List<DamageIndicator> indicators, double dt) {
  for (final indicator in indicators) {
    indicator.age += dt;
  }
  indicators.removeWhere((i) => i.isExpired);
}
