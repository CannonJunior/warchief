import 'dart:math' as math;
import 'package:flutter/material.dart' hide Matrix4;
import 'package:vector_math/vector_math.dart' hide Colors;

import '../../rendering3d/camera3d.dart';
import '../state/gameplay_settings.dart';
import '../utils/screen_projection.dart';

/// A single floating damage or heal number above a target
class DamageIndicator {
  /// Damage/heal amount to display
  final double damage;

  /// World-space position where damage/heal occurred (target's position)
  final Vector3 worldPosition;

  /// Whether this was a melee hit (rises faster, shorter lifetime)
  final bool isMelee;

  /// Whether this hit killed the target
  final bool isKillingBlow;

  /// Whether this is a healing number (green, prefixed with +)
  final bool isHeal;

  /// Time elapsed since creation
  double age = 0.0;

  /// Random horizontal offset to prevent stacking
  final double xJitter;

  DamageIndicator({
    required this.damage,
    required this.worldPosition,
    this.isMelee = false,
    this.isKillingBlow = false,
    this.isHeal = false,
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
    super.key,
    required this.indicators,
    required this.camera,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (camera == null || indicators.isEmpty) return const SizedBox.shrink();

    final settings = globalGameplaySettings;
    final showDamage = settings?.showDamageNumbers ?? true;
    final showHeals = settings?.showHealNumbers ?? true;

    final viewMatrix = camera!.getViewMatrix();
    final projMatrix = camera!.getProjectionMatrix();
    final screenSize = MediaQuery.of(context).size;

    final children = <Widget>[];

    for (final indicator in indicators) {
      // Reason: Skip rendering based on settings toggles
      if (indicator.isHeal && !showHeals) continue;
      if (!indicator.isHeal && !showDamage) continue;
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

    // Color: green for heals, yellow for damage, yellow→red for killing blow
    Color textColor;
    if (indicator.isHeal) {
      textColor = const Color(0xFF44FF44); // bright green
    } else if (indicator.isKillingBlow) {
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

    // Reason: Font size increased 10% from original (33→36.3, 30→33), scaled by settings
    final userScale = globalGameplaySettings?.damageNumberScale ?? 1.0;
    final baseFontSize = (indicator.isMelee ? 33.0 : 36.3) * userScale;
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
              // Damage/heal number
              Text(
                indicator.isHeal
                    ? '+${indicator.damage.round()}'
                    : indicator.damage.round().toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withValues(alpha: opacity),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  shadows: indicator.isKillingBlow
                      ? [
                          // Reason: Killing blow gets black + yellow shadows for emphasis
                          Shadow(
                            color: Colors.black.withValues(alpha: opacity * 0.9),
                            blurRadius: 4,
                            offset: const Offset(1, 1),
                          ),
                          Shadow(
                            color: const Color(0xFFFFDD00).withValues(alpha: opacity * 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 0),
                          ),
                        ]
                      : [
                          Shadow(
                            color: Colors.black.withValues(alpha: opacity * 0.9),
                            blurRadius: 3,
                            offset: const Offset(1, 1),
                          ),
                          Shadow(
                            color: Colors.black.withValues(alpha: opacity * 0.7),
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

      paint.color = red.withValues(alpha: sparkleOpacity);
      canvas.drawCircle(Offset(x, y), sparkleSize, paint);

      // Add a glow around larger sparkles
      if (sparkleSize > 2.0) {
        paint.color = red.withValues(alpha: sparkleOpacity * 0.3);
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

// ==================== QUEUED ABILITY LABEL ====================

/// Tracks the dissolving label shown when a queued ability executes.
class QueuedAbilityLabel {
  final String name;
  double age = 0.0;
  static const double maxAge = 1.0;

  QueuedAbilityLabel(this.name);

  bool get isExpired => age >= maxAge;
  double get progress => (age / maxAge).clamp(0.0, 1.0);
}

/// World-space overlay that shows the queued/executing ability name below
/// the active unit.
///
/// - **Queued** (casting or winding up): white text, no fade.
/// - **Executing** (just fired): yellow text with black shadow, dissolves.
class QueuedAbilityLabelOverlay extends StatelessWidget {
  /// Label currently dissolving after execution (null = none).
  final QueuedAbilityLabel? executingLabel;

  /// Ability name in the cast/windup queue (empty = none).
  final String queuedName;

  final Camera3D? camera;

  /// World-space position of the active unit's feet.
  final Vector3? unitPosition;

  const QueuedAbilityLabelOverlay({
    super.key,
    required this.executingLabel,
    required this.queuedName,
    required this.camera,
    required this.unitPosition,
  });

  @override
  Widget build(BuildContext context) {
    if (camera == null || unitPosition == null) return const SizedBox.shrink();
    if (queuedName.isEmpty && executingLabel == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final screenPos  = worldToScreen(
      unitPosition!,
      camera!.getViewMatrix(),
      camera!.getProjectionMatrix(),
      screenSize,
    );
    if (screenPos == null) return const SizedBox.shrink();

    // Render below the unit: +30px below the projected foot position
    const double yOffset = 30.0;
    final x = screenPos.dx;
    final y = screenPos.dy + yOffset;

    if (x < -100 || x > screenSize.width + 100 ||
        y < -20  || y > screenSize.height + 20) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    // Queued label — white, always opaque while cast/windup is active
    if (queuedName.isNotEmpty) {
      children.add(_buildLabel(
        text:    queuedName,
        color:   Colors.white,
        opacity: 1.0,
        x: x,
        y: y,
      ));
    }

    // Executing label — yellow, dissolves upward
    if (executingLabel != null) {
      final p       = executingLabel!.progress;
      final opacity = (1.0 - p).clamp(0.0, 1.0);
      // Slight upward drift during dissolve
      final drift   = -p * 18.0;
      children.add(_buildLabel(
        text:    executingLabel!.name,
        color:   const Color(0xFFFFDD00),
        opacity: opacity,
        x: x,
        y: y + drift,
        shadow: true,
      ));
    }

    return SizedBox.expand(
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  Widget _buildLabel({
    required String text,
    required Color  color,
    required double opacity,
    required double x,
    required double y,
    bool shadow = false,
  }) {
    const double width = 160.0;
    return Positioned(
      left: x - width / 2,
      top:  y,
      child: IgnorePointer(
        child: SizedBox(
          width: width,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:      color.withValues(alpha: opacity),
              fontSize:   13.0,
              fontWeight: FontWeight.w700,
              shadows: shadow
                  ? [
                      Shadow(
                        color:      Colors.black.withValues(alpha: opacity * 0.9),
                        blurRadius: 3,
                        offset:     const Offset(1, 1),
                      ),
                      Shadow(
                        color:      Colors.black.withValues(alpha: opacity * 0.6),
                        blurRadius: 6,
                        offset:     const Offset(0, 0),
                      ),
                    ]
                  : [
                      // Subtle shadow so white text is readable on any terrain
                      Shadow(
                        color:      Colors.black.withValues(alpha: 0.7),
                        blurRadius: 2,
                        offset:     const Offset(1, 1),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
