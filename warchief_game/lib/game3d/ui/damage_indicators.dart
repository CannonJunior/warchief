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

    // Color: read from typography settings, with killing-blow lerp toward kill color
    final s = globalGameplaySettings;
    Color textColor;
    if (indicator.isHeal) {
      textColor = Color(s?.combatHealColor ?? 0xFF44FF44);
    } else if (indicator.isKillingBlow) {
      // Start at damage color, transition to kill color
      final redProgress = (progress * 2.0).clamp(0.0, 1.0);
      textColor = Color.lerp(
        Color(s?.combatDamageColor ?? 0xFFFFDD00),
        Color(s?.combatKillColor   ?? 0xFFFF2222),
        redProgress,
      )!;
    } else {
      textColor = Color(s?.combatDamageColor ?? 0xFFFFDD00);
    }
    final useShadow = s?.combatShadow ?? true;

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
                  fontFamily: s?.combatFontFamily == 'Default'
                      ? null
                      : (s?.combatFontFamily ?? 'Bangers'),
                  fontWeight: FontWeight.w900,
                  shadows: !useShadow
                      ? null
                      : indicator.isKillingBlow
                          ? [
                              // Reason: Killing blow gets black + kill-color shadows for emphasis
                              Shadow(
                                color: Colors.black.withValues(alpha: opacity * 0.9),
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                              Shadow(
                                color: Color(s?.combatKillColor ?? 0xFFFF2222)
                                    .withValues(alpha: opacity * 0.6),
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

/// An ability that was just executed out of the queue and is now playing its
/// exit animation: shown in yellow, fading out over [maxAge] seconds.
class ExitingQueueLabel {
  final String name;
  final double maxAge;
  double age = 0.0;

  ExitingQueueLabel(this.name, {required this.maxAge});

  bool   get isExpired => age >= maxAge;
  /// Opacity from 1.0 (just fired) down to 0.0 (fully faded).
  double get opacity   => maxAge > 0 ? (1.0 - age / maxAge).clamp(0.0, 1.0) : 0.0;
}

/// World-space overlay showing queued and executing ability names below the unit.
///
/// One entry in the queued-ability display, carrying its display name and
/// whether its slot is currently on cooldown (drives text colour).
class QueuedDisplayEntry {
  final String name;
  final bool isOnCooldown;
  const QueuedDisplayEntry(this.name, {required this.isOnCooldown});
}

/// - **Queue**: Bangers, right-aligned single line joined by " > ".
///   On-cooldown entries render in Colors.white38, matching the muted label
///   colour used on ability buttons during their cooldown sweep.
/// - **Exiting** (just fired from queue): rendered at the front of the queue
///   line in yellow, fading to transparent over [ExitingQueueLabel.maxAge] s.
/// - **Executing** (direct hotkey, not queue): yellow + black shadow, dissolves upward.
class QueuedAbilityLabelOverlay extends StatelessWidget {
  final QueuedAbilityLabel? executingLabel;

  /// Queue entries exiting via fade animation (rendered yellow, fading).
  final List<ExitingQueueLabel> exitingLabels;

  /// Entries waiting in the queue, in order, with per-entry cooldown state.
  final List<QueuedDisplayEntry> queuedEntries;

  final Camera3D? camera;
  final Vector3? unitPosition;

  /// Number of consecutive abilities fired in an active combo window.
  /// Displayed as "x{n} COMBO" above the queue when ≥ 2.
  final int comboStreak;

  const QueuedAbilityLabelOverlay({
    super.key,
    required this.executingLabel,
    required this.exitingLabels,
    required this.queuedEntries,
    required this.camera,
    required this.unitPosition,
    this.comboStreak = 0,
  });

  // Reason: wide enough that a full queue (5 long names) fits on one line
  // at 26px without wrapping.
  static const double _width = 1000.0;
  static const double _baseFontSize = 26.0;

  @override
  Widget build(BuildContext context) {
    if (camera == null || unitPosition == null) return const SizedBox.shrink();
    if (queuedEntries.isEmpty && exitingLabels.isEmpty && executingLabel == null && comboStreak < 2) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final screenPos  = worldToScreen(
      unitPosition!,
      camera!.getViewMatrix(),
      camera!.getProjectionMatrix(),
      screenSize,
    );
    if (screenPos == null) return const SizedBox.shrink();

    final x = screenPos.dx;
    final y = screenPos.dy + 30.0;

    if (x < -200 || x > screenSize.width + 200 ||
        y < -40   || y > screenSize.height + 40) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    // Combo tracker — displayed above the queue line when a chain is active.
    if (comboStreak >= 2) {
      children.add(_buildComboTracker(comboStreak, x, y));
    }

    if (queuedEntries.isNotEmpty || exitingLabels.isNotEmpty) {
      children.add(_buildQueueText(queuedEntries, exitingLabels, x, y));
    }

    if (executingLabel != null) {
      final p       = executingLabel!.progress;
      final opacity = (1.0 - p).clamp(0.0, 1.0);
      // Reason: start 24px above queue line so it's never visually merged with it,
      // then drift another 18px upward as it dissolves.
      children.add(_buildText(
        text:    executingLabel!.name,
        color:   const Color(0xFFFFDD00),
        opacity: opacity,
        x: x,
        y: y - 24.0 - p * 18.0,
        shadow: true,
      ));
    }

    return SizedBox.expand(
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  /// Renders "x{n} COMBO" in gold above the queue line while a combo chain
  /// is active (streak ≥ 2).  Positioned [_comboTrackerOffset]px above the
  /// queue baseline so the two labels never overlap.
  static const double _comboTrackerOffset = 30.0;
  static const double _comboFontSize = 20.0;

  Widget _buildComboTracker(int streak, double x, double y) {
    final s          = globalGameplaySettings;
    final fontFamily = (s?.queueFontFamily ?? 'Bangers') == 'Default'
        ? null
        : (s?.queueFontFamily ?? 'Bangers');

    return Positioned(
      left: x - _width,
      top:  y - _comboTrackerOffset,
      child: IgnorePointer(
        child: SizedBox(
          width: _width,
          child: Text(
            'x$streak COMBO',
            textAlign: TextAlign.right,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontFamily:  fontFamily,
              fontSize:    _comboFontSize,
              fontWeight:  FontWeight.bold,
              color:       const Color(0xFFFFAA00),
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the queue line as a [RichText] so each entry can be coloured
  /// independently.
  ///
  /// Exiting entries (just fired from queue) appear first in yellow, fading
  /// from opaque to transparent.  Waiting entries follow in white (or white38
  /// when on cooldown, matching the ability-button label colour during cooldown).
  Widget _buildQueueText(
    List<QueuedDisplayEntry> entries,
    List<ExitingQueueLabel> exiting,
    double x,
    double y,
  ) {
    final s = globalGameplaySettings;
    final queueFamily = s?.queueFontFamily ?? 'Bangers';
    final fontSize = _baseFontSize * (s?.queueFontScale ?? 1.0);
    final fontFamily = queueFamily == 'Default' ? null : queueFamily;

    final spans = <InlineSpan>[];
    bool needsSeparator = false;

    // Exiting entries: yellow, fading.
    for (final ex in exiting) {
      if (needsSeparator) {
        spans.add(TextSpan(
          text: ' > ',
          style: TextStyle(
            color: Colors.white70.withValues(alpha: ex.opacity),
            fontFamily: fontFamily,
          ),
        ));
      }
      spans.add(TextSpan(
        text: ex.name,
        style: TextStyle(
          color: const Color(0xFFFFDD00).withValues(alpha: ex.opacity),
          fontFamily: fontFamily,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: ex.opacity * 0.7),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ));
      needsSeparator = true;
    }

    // Waiting entries: white (or dimmed when on cooldown).
    for (final entry in entries) {
      if (needsSeparator) {
        spans.add(TextSpan(
          text: ' > ',
          style: TextStyle(color: Colors.white70, fontFamily: fontFamily),
        ));
      }
      final readyColor = Color(s?.queueTextColor ?? 0xFFFFFFFF);
      spans.add(TextSpan(
        text: entry.name,
        style: TextStyle(
          // Reason: mirror the Colors.white38 used on button labels during cooldown.
          color: entry.isOnCooldown
              ? readyColor.withValues(alpha: 0.38)
              : readyColor,
          fontFamily: fontFamily,
        ),
      ));
      needsSeparator = true;
    }

    return Positioned(
      left: x - _width,
      top:  y,
      child: IgnorePointer(
        child: SizedBox(
          width: _width,
          child: RichText(
            textAlign:  TextAlign.right,
            maxLines:   1,
            softWrap:   false,
            overflow:   TextOverflow.visible,
            text: TextSpan(
              style: TextStyle(
                fontSize:   fontSize,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color:      Colors.black.withValues(alpha: 0.7),
                    blurRadius: 2,
                    offset:     const Offset(1, 1),
                  ),
                ],
              ),
              children: spans,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText({
    required String text,
    required Color  color,
    required double opacity,
    required double x,
    required double y,
    bool shadow = false,
  }) {
    final s = globalGameplaySettings;
    final queueFamily = s?.queueFontFamily ?? 'Bangers';
    final fontSize = _baseFontSize * (s?.queueFontScale ?? 1.0);

    return Positioned(
      // Reason: right edge of the box is anchored at the unit's screen x so
      // text grows leftward and never clips off the right side of the screen.
      left: x - _width,
      top:  y,
      child: IgnorePointer(
        child: SizedBox(
          width: _width,
          child: Text(
            text,
            textAlign:  TextAlign.right,
            maxLines:   1,
            softWrap:   false,
            overflow:   TextOverflow.visible,
            style: TextStyle(
              color:      color.withValues(alpha: opacity),
              fontSize:   fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: queueFamily == 'Default' ? null : queueFamily,
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
                      ),
                    ]
                  : [
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
