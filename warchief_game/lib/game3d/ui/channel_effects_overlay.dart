import 'dart:math' as math;
import 'package:flutter/material.dart' hide Matrix4;
import 'package:vector_math/vector_math.dart' hide Colors;

import '../../rendering3d/camera3d.dart';
import '../data/abilities/ability_types.dart';
import '../data/abilities/abilities.dart' show AbilityRegistry;
import '../state/game_state.dart';
import '../utils/screen_projection.dart';

/// Overlay that renders visual effects for channeled abilities.
///
/// Each [ChannelEffect] type has a dedicated painter:
/// - lifeDrain: purple vortex arcs from target to caster
/// - blizzard: ice crystals descending in AoE area
/// - earthquake: earth particles erupting from ground in AoE
/// - conduit: lightning bolts from sky to target
class ChannelEffectOverlay extends StatelessWidget {
  final GameState gameState;
  final Camera3D? camera;

  const ChannelEffectOverlay({
    Key? key,
    required this.gameState,
    required this.camera,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!gameState.isChanneling || camera == null) {
      return const SizedBox.shrink();
    }

    final ability = AbilityRegistry.findByName(gameState.channelingAbilityName);
    if (ability == null || ability.channelEffect == ChannelEffect.none) {
      return const SizedBox.shrink();
    }

    final viewMatrix = camera!.getViewMatrix();
    final projMatrix = camera!.getProjectionMatrix();
    final screenSize = MediaQuery.of(context).size;

    return SizedBox.expand(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ChannelEffectPainter(
            effect: ability.channelEffect,
            progress: gameState.channelProgress,
            duration: gameState.channelDuration,
            casterPos: gameState.activeTransform?.position,
            targetPos: gameState.getCurrentTargetPosition(),
            aoeCenter: gameState.channelAoeCenter,
            aoeRadius: ability.aoeRadius,
            abilityColor: ability.color,
            viewMatrix: viewMatrix,
            projMatrix: projMatrix,
            screenSize: screenSize,
          ),
        ),
      ),
    );
  }
}

/// Paints the visual effect for the active channeled ability.
class _ChannelEffectPainter extends CustomPainter {
  final ChannelEffect effect;
  final double progress;
  final double duration;
  final Vector3? casterPos;
  final Vector3? targetPos;
  final Vector3? aoeCenter;
  final double aoeRadius;
  final Vector3 abilityColor;
  final dynamic viewMatrix;
  final dynamic projMatrix;
  final Size screenSize;

  _ChannelEffectPainter({
    required this.effect,
    required this.progress,
    required this.duration,
    required this.casterPos,
    required this.targetPos,
    required this.aoeCenter,
    required this.aoeRadius,
    required this.abilityColor,
    required this.viewMatrix,
    required this.projMatrix,
    required this.screenSize,
  });

  Offset? _project(Vector3 worldPos) {
    return worldToScreen(worldPos, viewMatrix, projMatrix, screenSize);
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (effect) {
      case ChannelEffect.lifeDrain:
        _paintLifeDrain(canvas, size);
        break;
      case ChannelEffect.blizzard:
        _paintBlizzard(canvas, size);
        break;
      case ChannelEffect.earthquake:
        _paintEarthquake(canvas, size);
        break;
      case ChannelEffect.conduit:
        _paintConduit(canvas, size);
        break;
      case ChannelEffect.none:
        break;
    }
  }

  // ==================== LIFE DRAIN ====================
  // Reason: Purple vortex arcs spiraling from target to caster
  void _paintLifeDrain(Canvas canvas, Size size) {
    if (casterPos == null || targetPos == null) return;

    final casterScreen = _project(casterPos!);
    // Reason: Project target slightly above ground for visual centering
    final targetAbove = targetPos!.clone()..y += 1.5;
    final targetScreen = _project(targetAbove);
    if (casterScreen == null || targetScreen == null) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final t = progress; // elapsed seconds
    final arcCount = 5;

    for (int i = 0; i < arcCount; i++) {
      final phase = i * (2 * math.pi / arcCount) + t * 3.0;
      // Reason: Each arc spirals along the line between target and caster
      // with sinusoidal offset perpendicular to the connection axis
      final dx = casterScreen.dx - targetScreen.dx;
      final dy = casterScreen.dy - targetScreen.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len < 1.0) continue;

      // Normal perpendicular to connection axis
      final nx = -dy / len;
      final ny = dx / len;

      final path = Path();
      final steps = 20;
      for (int s = 0; s <= steps; s++) {
        final frac = s / steps;
        // Reason: Particles flow from target (frac=0) to caster (frac=1)
        // with a moving wave pattern along the path
        final wave = math.sin(phase + frac * math.pi * 4) * (30.0 * (1.0 - frac * 0.5));
        final px = targetScreen.dx + dx * frac + nx * wave;
        final py = targetScreen.dy + dy * frac + ny * wave;
        if (s == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }

      // Reason: Fade opacity based on arc index for depth variation
      final opacity = (0.4 + 0.3 * math.sin(t * 2.0 + i)).clamp(0.2, 0.7);
      paint.color = Color.fromRGBO(180, 50, 200, opacity);
      canvas.drawPath(path, paint);
    }

    // Reason: Bright center particle stream for emphasis
    final centerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Color.fromRGBO(200, 80, 255, 0.5);

    final centerPath = Path();
    final centerSteps = 15;
    for (int s = 0; s <= centerSteps; s++) {
      final frac = s / centerSteps;
      final wobble = math.sin(t * 5.0 + frac * 6.0) * 8.0;
      final dx = casterScreen.dx - targetScreen.dx;
      final dy = casterScreen.dy - targetScreen.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      final nx = len > 0 ? -dy / len : 0.0;
      final ny = len > 0 ? dx / len : 0.0;
      final px = targetScreen.dx + (casterScreen.dx - targetScreen.dx) * frac + nx * wobble;
      final py = targetScreen.dy + (casterScreen.dy - targetScreen.dy) * frac + ny * wobble;
      if (s == 0) {
        centerPath.moveTo(px, py);
      } else {
        centerPath.lineTo(px, py);
      }
    }
    canvas.drawPath(centerPath, centerPaint);
  }

  // ==================== BLIZZARD ====================
  // Reason: Ice crystals falling from sky within AoE radius
  void _paintBlizzard(Canvas canvas, Size size) {
    final center = aoeCenter ?? targetPos;
    if (center == null) return;

    final rng = math.Random(42);
    final crystalCount = 40;
    final paint = Paint()..style = PaintingStyle.fill;

    final t = progress;
    final radius = aoeRadius > 0 ? aoeRadius : 5.0;

    for (int i = 0; i < crystalCount; i++) {
      // Reason: Deterministic random positions within AoE circle, cycling vertically
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist = math.sqrt(rng.nextDouble()) * radius;
      final fallSpeed = 2.0 + rng.nextDouble() * 3.0;
      final phaseOffset = rng.nextDouble() * 10.0;

      final wx = center.x + math.cos(angle) * dist;
      final wz = center.z + math.sin(angle) * dist;
      // Reason: Crystal cycles from sky (y+8) to ground (y+0) based on time
      final cyclePos = ((t * fallSpeed + phaseOffset) % 8.0);
      final wy = center.y + 8.0 - cyclePos;

      final screenPos = _project(Vector3(wx, wy, wz));
      if (screenPos == null) continue;

      // Reason: Crystal size varies with depth illusion and fades near ground
      final heightFrac = cyclePos / 8.0; // 0 at top, 1 at ground
      final crystalSize = 3.0 + rng.nextDouble() * 4.0;
      final opacity = (1.0 - heightFrac * 0.7).clamp(0.2, 0.8);

      // Ice blue color with variation
      final b = 200 + (rng.nextDouble() * 55).round();
      paint.color = Color.fromRGBO(180, 220, b, opacity);

      // Reason: Draw diamond shape for ice crystal
      final cx = screenPos.dx;
      final cy = screenPos.dy;
      final s = crystalSize;
      final crystalPath = Path()
        ..moveTo(cx, cy - s)
        ..lineTo(cx + s * 0.5, cy)
        ..lineTo(cx, cy + s * 0.6)
        ..lineTo(cx - s * 0.5, cy)
        ..close();
      canvas.drawPath(crystalPath, paint);
    }

    // Reason: Draw AoE boundary ring at ground level
    _paintAoeRing(canvas, center, radius, const Color(0x406699CC));
  }

  // ==================== EARTHQUAKE ====================
  // Reason: Earth/rock particles erupting upward from ground
  void _paintEarthquake(Canvas canvas, Size size) {
    final center = aoeCenter ?? targetPos;
    if (center == null) return;

    final rng = math.Random(77);
    final particleCount = 35;
    final paint = Paint()..style = PaintingStyle.fill;

    final t = progress;
    final radius = aoeRadius > 0 ? aoeRadius : 8.0;

    for (int i = 0; i < particleCount; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist = math.sqrt(rng.nextDouble()) * radius;
      final eruptSpeed = 1.5 + rng.nextDouble() * 2.0;
      final phaseOffset = rng.nextDouble() * 5.0;
      final particleSize = 2.0 + rng.nextDouble() * 5.0;

      final wx = center.x + math.cos(angle) * dist;
      final wz = center.z + math.sin(angle) * dist;
      // Reason: Particle erupts upward then falls back down in a parabolic arc
      final cycleT = ((t * eruptSpeed + phaseOffset) % 3.0) / 3.0;
      final height = 4.0 * cycleT * (1.0 - cycleT) * 4.0; // parabola peaks at 4 units
      final wy = center.y + height;

      final screenPos = _project(Vector3(wx, wy, wz));
      if (screenPos == null) continue;

      final opacity = (1.0 - cycleT * 0.6).clamp(0.2, 0.8);
      // Earth tones: brown to dark orange
      final r = 140 + (rng.nextDouble() * 60).round();
      final g = 90 + (rng.nextDouble() * 40).round();
      final b2 = 40 + (rng.nextDouble() * 30).round();
      paint.color = Color.fromRGBO(r, g, b2, opacity);

      // Reason: Irregular rock shapes via slightly offset rectangles
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: screenPos,
            width: particleSize,
            height: particleSize * (0.7 + rng.nextDouble() * 0.6),
          ),
          const Radius.circular(1),
        ),
        paint,
      );
    }

    // AoE boundary ring
    _paintAoeRing(canvas, center, radius, const Color(0x40996633));
  }

  // ==================== CONDUIT ====================
  // Reason: Jagged lightning bolt from sky to target, refreshed per frame
  void _paintConduit(Canvas canvas, Size size) {
    if (targetPos == null) return;

    final targetAbove = targetPos!.clone()..y += 1.5;
    final targetScreen = _project(targetAbove);
    if (targetScreen == null) return;

    // Reason: Lightning originates high above target
    final skyPos = targetPos!.clone()..y += 15.0;
    final skyScreen = _project(skyPos);
    if (skyScreen == null) return;

    final t = progress;
    // Reason: Draw multiple lightning bolts for visual richness
    for (int bolt = 0; bolt < 3; bolt++) {
      _paintLightningBolt(
        canvas,
        skyScreen,
        targetScreen,
        seed: (t * 30).round() + bolt * 1000,
        thickness: bolt == 0 ? 3.0 : 1.5,
        opacity: bolt == 0 ? 0.9 : 0.5,
      );
    }

    // Reason: Bright glow at impact point
    final glowPaint = Paint()
      ..color = const Color(0x40AABBFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(targetScreen, 20, glowPaint);

    // Caster connection line (faint)
    if (casterPos != null) {
      final casterScreen = _project(casterPos!);
      if (casterScreen != null) {
        final connPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0x306688FF);
        canvas.drawLine(casterScreen, targetScreen, connPaint);
      }
    }
  }

  void _paintLightningBolt(
    Canvas canvas,
    Offset from,
    Offset to, {
    required int seed,
    double thickness = 2.0,
    double opacity = 0.8,
  }) {
    final rng = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = Color.fromRGBO(170, 190, 255, opacity);

    final path = Path()..moveTo(from.dx, from.dy);
    final segments = 12;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;

    for (int i = 1; i <= segments; i++) {
      final frac = i / segments;
      // Reason: Horizontal jitter decreases near endpoints for clean connection
      final jitterScale = (1.0 - (2.0 * frac - 1.0).abs()) * 25.0;
      final jx = (rng.nextDouble() - 0.5) * jitterScale;
      final jy = (rng.nextDouble() - 0.5) * jitterScale * 0.3;
      final px = from.dx + dx * frac + jx;
      final py = from.dy + dy * frac + jy;
      path.lineTo(px, py);
    }
    canvas.drawPath(path, paint);

    // Reason: Bright white core for primary bolt
    if (thickness > 2.0) {
      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..color = Color.fromRGBO(220, 230, 255, opacity * 0.7);
      canvas.drawPath(path, corePaint);
    }
  }

  // ==================== SHARED HELPERS ====================

  /// Draw a faint ring on the ground at AoE boundary
  void _paintAoeRing(Canvas canvas, Vector3 center, double radius, Color color) {
    final ringPoints = <Offset>[];
    final segments = 24;
    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final wp = Vector3(
        center.x + math.cos(angle) * radius,
        center.y + 0.1,
        center.z + math.sin(angle) * radius,
      );
      final sp = _project(wp);
      if (sp != null) ringPoints.add(sp);
    }
    if (ringPoints.length < 3) return;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;

    final path = Path()..moveTo(ringPoints[0].dx, ringPoints[0].dy);
    for (int i = 1; i < ringPoints.length; i++) {
      path.lineTo(ringPoints[i].dx, ringPoints[i].dy);
    }
    canvas.drawPath(path, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _ChannelEffectPainter oldDelegate) => true;
}
