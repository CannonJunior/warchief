import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../state/wind_state.dart';

/// A single wind particle flowing across the minimap.
///
/// Particles drift in the wind direction, leaving short trails.
/// When they exit the circular bounds or expire, they respawn at a
/// random position along the upwind edge.
class _WindParticle {
  double x;
  double y;
  double prevX;
  double prevY;
  double age;
  double maxAge;

  /// Per-particle speed jitter (0.7–1.3) for organic variation.
  double speedScale;

  _WindParticle({
    required this.x,
    required this.y,
    required this.age,
    required this.maxAge,
    required this.speedScale,
  })  : prevX = x,
        prevY = y;
}

/// Draws an animated wind-map overlay on the minimap.
///
/// Renders dozens of tiny particle streamlines that flow in the current
/// wind direction. Particle speed and trail length reflect wind strength.
/// Color encodes speed using a meteorological gradient:
///   calm (blue) → moderate (cyan/green) → strong (yellow/orange) → derecho (red).
///
/// During derecho storms the particle density doubles, speeds surge,
/// colors shift to hot orange/red, and a pulsing radial glow appears
/// with a "DERECHO" label.
///
/// Only displayed when the active character is attuned to White mana
/// and the wind overlay toggle is enabled.
class MinimapWindPainter extends CustomPainter {
  /// Wind state providing direction, strength, and derecho data.
  final WindState windState;

  /// Player rotation in degrees (for rotating-mode alignment).
  final double playerRotation;

  /// Whether the minimap is in rotating mode.
  final bool isRotatingMode;

  /// Elapsed time for animation.
  final double elapsedTime;

  MinimapWindPainter({
    required this.windState,
    required this.playerRotation,
    required this.isRotatingMode,
    required this.elapsedTime,
  });

  // ==================== STATIC PARTICLE POOL ====================

  static List<_WindParticle>? _particles;
  static double _lastElapsed = 0.0;
  static final math.Random _rng = math.Random(42);

  /// Number of particles in normal conditions.
  static const int _normalCount = 90;

  /// Number of particles during derecho.
  static const int _derechoCount = 160;

  // ==================== WIND SPEED COLOR SCALE ====================

  /// Reason: meteorological color scale maps speed to intuition —
  /// blue = calm, green = breezy, yellow = gusty, red = extreme.
  static const List<Color> _speedColors = [
    Color(0xFF3366BB), // 0.0  calm
    Color(0xFF4499DD), // 0.15
    Color(0xFF44BBBB), // 0.30
    Color(0xFF44BB66), // 0.45
    Color(0xFF99CC33), // 0.60
    Color(0xFFDDBB22), // 0.75
    Color(0xFFEE8811), // 0.90
    Color(0xFFDD3311), // 1.0+ extreme / derecho
  ];

  /// Interpolate the speed color scale at a normalized value [0..1+].
  static Color _speedToColor(double t) {
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (_speedColors.length - 1);
    final idx = scaled.floor().clamp(0, _speedColors.length - 2);
    final frac = scaled - idx;
    return Color.lerp(_speedColors[idx], _speedColors[idx + 1], frac)!;
  }

  // ==================== PAINT ====================

  @override
  void paint(Canvas canvas, Size size) {
    final half = size.width / 2;
    final center = Offset(half, half);

    // Clip to circle
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: half)));

    final isDerecho = windState.isDerechoActive;
    final derechoInt = windState.derechoIntensity;
    final strength = windState.windStrength;
    final effectiveStr = windState.effectiveWindStrength;

    // Reason: wind angle is in world space; in rotating mode subtract
    // player rotation so particles align with the minimap's rotated frame.
    double drawAngle = windState.windAngle;
    if (isRotatingMode) {
      drawAngle -= playerRotation * math.pi / 180.0;
    }

    // Derecho background glow
    if (isDerecho) {
      _paintDerechoGlow(canvas, half, center, derechoInt);
    }

    // Advance and draw particles
    final targetCount = isDerecho ? _derechoCount : _normalCount;
    _ensureParticles(targetCount, half);
    final dt = elapsedTime - _lastElapsed;
    _lastElapsed = elapsedTime;

    // Reason: clamp dt to avoid particle teleportation on tab-switch or lag spike
    final safeDt = dt.clamp(0.0, 0.1);
    _advanceParticles(safeDt, drawAngle, effectiveStr, half, targetCount);
    _drawParticles(canvas, half, strength, effectiveStr, isDerecho, derechoInt, drawAngle);

    // DERECHO label
    if (isDerecho && derechoInt > 0.3) {
      _paintDerechoLabel(canvas, half, derechoInt);
    }

    canvas.restore();
  }

  // ==================== DERECHO EFFECTS ====================

  /// Pulsing orange/red radial glow during derecho.
  void _paintDerechoGlow(
      Canvas canvas, double half, Offset center, double intensity) {
    final pulse = math.sin(elapsedTime * 3.0) * 0.5 + 0.5;
    final glowAlpha = 0.04 + intensity * 0.12 * (0.7 + pulse * 0.3);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(255, 100, 0, glowAlpha),
          Color.fromRGBO(255, 40, 0, glowAlpha * 0.3),
          Color.fromRGBO(255, 40, 0, 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: half));
    canvas.drawCircle(center, half, glowPaint);
  }

  /// "DERECHO" label at top of minimap.
  void _paintDerechoLabel(Canvas canvas, double half, double intensity) {
    final pulse = math.sin(elapsedTime * 3.0) * 0.5 + 0.5;
    final labelAlpha = ((intensity - 0.3) / 0.7).clamp(0.0, 1.0);
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'DERECHO',
        style: TextStyle(
          color: Color.fromRGBO(
              255, 136, 0, labelAlpha * (0.7 + pulse * 0.3)),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(half - textPainter.width / 2, 4));
  }

  // ==================== PARTICLE MANAGEMENT ====================

  /// Create or resize the particle pool to match target count.
  static void _ensureParticles(int count, double half) {
    if (_particles == null) {
      _particles = List.generate(count, (_) => _spawnRandom(half));
      return;
    }
    while (_particles!.length < count) {
      _particles!.add(_spawnRandom(half));
    }
    if (_particles!.length > count) {
      _particles!.removeRange(count, _particles!.length);
    }
  }

  /// Spawn a particle at a random position inside the circle.
  static _WindParticle _spawnRandom(double half) {
    // Reason: uniform random in a circle via rejection sampling
    double x, y;
    do {
      x = (_rng.nextDouble() * 2.0 - 1.0) * half;
      y = (_rng.nextDouble() * 2.0 - 1.0) * half;
    } while (x * x + y * y > half * half);

    return _WindParticle(
      x: x,
      y: y,
      age: _rng.nextDouble() * 3.0, // stagger start ages
      maxAge: 2.0 + _rng.nextDouble() * 2.5,
      speedScale: 0.7 + _rng.nextDouble() * 0.6,
    );
  }

  /// Respawn a particle on the upwind edge of the circle.
  static void _respawn(_WindParticle p, double half, double angle) {
    // Reason: spawning on the upwind semicircle makes particles always
    // flow across visible area rather than spawning mid-screen.
    final upwindAngle = angle + math.pi; // opposite of wind direction
    final spread = (_rng.nextDouble() - 0.5) * math.pi; // ±90° arc
    final spawnAngle = upwindAngle + spread;
    final r = half * (0.85 + _rng.nextDouble() * 0.15);
    p.x = math.cos(spawnAngle) * r;
    p.y = math.sin(spawnAngle) * r;
    p.prevX = p.x;
    p.prevY = p.y;
    p.age = 0.0;
    p.maxAge = 2.0 + _rng.nextDouble() * 2.5;
    p.speedScale = 0.7 + _rng.nextDouble() * 0.6;
  }

  /// Move all particles along the wind direction.
  void _advanceParticles(double dt, double angle, double effectiveStr,
      double half, int targetCount) {
    if (_particles == null || dt <= 0) return;

    // Reason: pixel speed scales with effective strength so derechos
    // produce visibly fast-moving particles, calm winds drift slowly.
    final baseSpeed = half * 0.4;
    final windDx = math.cos(angle);
    final windDy = math.sin(angle);

    for (final p in _particles!) {
      p.prevX = p.x;
      p.prevY = p.y;

      final speed = baseSpeed * effectiveStr * p.speedScale;
      p.x += windDx * speed * dt;
      p.y += windDy * speed * dt;
      p.age += dt;

      // Respawn if outside circle or expired
      if (p.x * p.x + p.y * p.y > half * half || p.age > p.maxAge) {
        _respawn(p, half, angle);
      }
    }
  }

  // ==================== DRAWING ====================

  /// Render all particles as short colored trails, curved by wind angular velocity.
  void _drawParticles(Canvas canvas, double half, double baseStrength,
      double effectiveStr, bool isDerecho, double derechoInt, double drawAngle) {
    if (_particles == null) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Reason: normalize effective strength into 0..1 range for color lookup.
    // Normal max is 1.0; during derecho effective strength can exceed 1.0,
    // map that into the hot end of the color scale.
    const maxNormalStr = 1.0;

    // Compute curved trail parameters once per frame.
    // Reason: using a fixed look-back time (curveSecs) decouples curvature from
    // particle speed, so high-effStr derecho doesn't shrink trailDuration and
    // accidentally cancel the angular offset. The clamp prevents spiral artifacts.
    final angVel = windState.windAngularVelocity;
    const trailPx   = 12.0;  // visible trail length in minimap pixels
    const curveSecs = 1.5;   // seconds of wind history to represent as curvature
    const maxAngOff = math.pi * 0.75;
    final angOffset = (angVel * curveSecs).clamp(-maxAngOff, maxAngOff);
    // Tail angle: where the wind was pointing curveSecs seconds ago.
    final tailAngle = drawAngle - angOffset;
    // Mid-trail angle: halfway between tail and head directions.
    final midAngle  = drawAngle - angOffset * 0.5;
    // Precompute trig for tail and mid so inner loop stays light.
    final tailCos = math.cos(tailAngle);
    final tailSin = math.sin(tailAngle);
    final midCos  = math.cos(midAngle);
    final midSin  = math.sin(midAngle);
    final useBezier = angVel.abs() > 0.05;

    for (final p in _particles!) {
      // Fade in at birth, fade out near death
      final lifeFrac = (p.age / p.maxAge).clamp(0.0, 1.0);
      final fadeIn = (p.age / 0.3).clamp(0.0, 1.0);
      final fadeOut = ((1.0 - lifeFrac) / 0.3).clamp(0.0, 1.0);
      final alpha = fadeIn * fadeOut;
      if (alpha < 0.02) continue;

      // Color from speed scale
      final speedNorm = (effectiveStr * p.speedScale / maxNormalStr)
          .clamp(0.0, 1.0);
      Color color;
      if (isDerecho) {
        // Reason: during derecho, lerp from the speed color toward hot
        // orange/red to make the storm visually unmistakable.
        final baseColor = _speedToColor(speedNorm);
        color = Color.lerp(
            baseColor, const Color(0xFFEE4400), derechoInt * 0.6)!;
      } else {
        color = _speedToColor(speedNorm);
      }

      // Reason: trail width scales with strength — thin whispy lines in
      // calm conditions, thicker strokes in strong wind.
      final strokeWidth = 1.0 + effectiveStr.clamp(0.0, 3.0) * 0.5;
      paint
        ..color = color.withOpacity(alpha * (0.4 + effectiveStr.clamp(0.0, 1.0) * 0.4))
        ..strokeWidth = strokeWidth;

      // Head = current particle position.
      final hx = p.x + half;
      final hy = p.y + half;
      // Tail = particle position minus the trail vector in the historical wind direction.
      final tx = p.x - tailCos * trailPx + half;
      final ty = p.y - tailSin * trailPx + half;

      if (useBezier) {
        // Quadratic bezier: tail → (control at mid-direction) → head.
        // Reason: curvature of the bezier encodes the wind's turn rate —
        // fast turning produces tight curves, steady wind stays straight.
        final cpx = p.x - midCos * trailPx * 0.5 + half;
        final cpy = p.y - midSin * trailPx * 0.5 + half;
        canvas.drawPath(
          Path()
            ..moveTo(tx, ty)
            ..quadraticBezierTo(cpx, cpy, hx, hy),
          paint,
        );
      } else {
        canvas.drawLine(Offset(tx, ty), Offset(hx, hy), paint);
      }
    }
  }

  @override
  bool shouldRepaint(MinimapWindPainter oldDelegate) {
    // Reason: particles advance every frame, always repaint when visible
    return true;
  }
}
