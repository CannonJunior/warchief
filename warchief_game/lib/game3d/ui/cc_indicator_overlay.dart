import 'dart:math' as math;
import 'package:flutter/material.dart' hide Matrix4;
import 'package:vector_math/vector_math.dart' hide Colors;

import '../../../models/active_effect.dart';
import '../../../rendering3d/camera3d.dart';
import '../../game3d/data/abilities/ability_types.dart';
import '../../game3d/state/game_state.dart';
import '../../game3d/utils/screen_projection.dart';

// CC types that warrant world-space badges.
// Excludes buffs (haste, shield, regen, strength) and DoTs (burn, poison, bleed).
const _ccTypes = {
  StatusEffect.stun,
  StatusEffect.freeze,
  StatusEffect.root,
  StatusEffect.silence,
  StatusEffect.fear,
  StatusEffect.blind,
  StatusEffect.slow,
  StatusEffect.interrupt,
};

/// Container for a unit's position and its active CC effects.
class _UnitCcData {
  final Vector3 worldPosition;
  final List<ActiveEffect> ccEffects;
  _UnitCcData(this.worldPosition, this.ccEffects);
}

/// World-space overlay that renders persistent CC status badges above affected units.
///
/// Displays stun, freeze, root, silence, fear, blind, slow, and interrupt as
/// colored icon badges (with countdown timer and a remaining-duration arc ring)
/// anchored to each unit's head position in the 3D world.
class CcIndicatorOverlay extends StatelessWidget {
  final GameState gameState;
  final Camera3D? camera;

  const CcIndicatorOverlay({
    Key? key,
    required this.gameState,
    required this.camera,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (camera == null) return const SizedBox.shrink();

    final viewMatrix = camera!.getViewMatrix();
    final projMatrix = camera!.getProjectionMatrix();
    final screenSize = MediaQuery.of(context).size;

    final units = _collectCcUnits();
    if (units.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];

    for (final unit in units) {
      // Offset 2.5 world units upward so the badge floats above the unit's head.
      final headPos = Vector3(
        unit.worldPosition.x,
        unit.worldPosition.y + 2.5,
        unit.worldPosition.z,
      );
      final screenPos = worldToScreen(headPos, viewMatrix, projMatrix, screenSize);

      // Skip if behind camera or outside viewport (with 60px margin).
      if (screenPos == null) continue;
      if (screenPos.dx < -60 || screenPos.dx > screenSize.width + 60 ||
          screenPos.dy < -60 || screenPos.dy > screenSize.height + 60) {
        continue;
      }

      children.add(_buildUnitBadges(unit.ccEffects, screenPos));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return SizedBox.expand(
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  // ==================== DATA COLLECTION ====================

  /// Iterate all game entities and return those with active CC effects.
  List<_UnitCcData> _collectCcUnits() {
    final result = <_UnitCcData>[];

    // Reason: use .any() as a cheap O(1)-exit guard before calling .toList().
    // .toList() allocates a List object even when empty; with many units this
    // adds up across every build.  .any() short-circuits on first match and
    // only triggers .toList() (and position.clone()) when CC is actually present.

    bool _hasCc(Iterable<ActiveEffect> effects) =>
        effects.any((e) => _ccTypes.contains(e.type) && !e.isExpired);
    List<ActiveEffect> _collectCc(Iterable<ActiveEffect> effects) =>
        effects.where((e) => _ccTypes.contains(e.type) && !e.isExpired).toList();

    // Player / currently-controlled character (Warchief or active ally)
    final playerPos = gameState.activeTransform?.position;
    if (playerPos != null) {
      final effects = gameState.activeCharacterActiveEffects;
      if (_hasCc(effects)) {
        result.add(_UnitCcData(playerPos.clone(), _collectCc(effects)));
      }
    }

    // Boss monster
    final monsterPos = gameState.monsterTransform?.position;
    if (monsterPos != null && gameState.monsterHealth > 0) {
      final effects = gameState.monsterActiveEffects;
      if (_hasCc(effects)) {
        result.add(_UnitCcData(monsterPos.clone(), _collectCc(effects)));
      }
    }

    // Allies — skip the Spirit Wolf summon which isn't a real party member
    for (final ally in gameState.allies) {
      if (ally.isSummoned && ally.name == 'Spirit Wolf') continue;
      if (ally.health <= 0) continue;
      if (_hasCc(ally.activeEffects)) {
        result.add(_UnitCcData(ally.transform.position.clone(), _collectCc(ally.activeEffects)));
      }
    }

    // Alive minions (enemy side)
    for (final minion in gameState.aliveMinions) {
      if (_hasCc(minion.activeEffects)) {
        result.add(_UnitCcData(minion.transform.position.clone(), _collectCc(minion.activeEffects)));
      }
    }

    return result;
  }

  // ==================== RENDERING ====================

  /// Build a horizontal row of CC badges centered above the screen position.
  Widget _buildUnitBadges(List<ActiveEffect> effects, Offset screenPos) {
    const badgeSize = 44.0;
    const gap = 4.0;
    final totalWidth = effects.length * badgeSize + (effects.length - 1) * gap;

    return Positioned(
      left: screenPos.dx - totalWidth / 2,
      top: screenPos.dy - badgeSize / 2,
      child: IgnorePointer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < effects.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              _CcBadge(effect: effects[i]),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== BADGE WIDGET ====================

/// A single 44×44 CC badge showing an icon, countdown timer, and ring arc.
class _CcBadge extends StatelessWidget {
  final ActiveEffect effect;

  const _CcBadge({required this.effect});

  @override
  Widget build(BuildContext context) {
    final color = ActiveEffect.colorFor(effect.type);
    final icon = ActiveEffect.iconFor(effect.type);
    final timerText = '${effect.remainingDuration.toStringAsFixed(1)}s';

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background + colored border + glow shadow
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: color.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Remaining-duration arc ring drawn outside the icon, like action-bar cooldown
          CustomPaint(
            size: const Size(44, 44),
            painter: _CcProgressRingPainter(
              progress: effect.progress,
              color: color,
            ),
          ),
          // Icon + countdown stacked inside badge
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 1),
              Text(
                timerText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== PROGRESS RING ====================

/// Paints the remaining CC duration as a colored stroke arc around the badge edge.
///
/// Unlike _ProgressRingPainter in buff_debuff_icons.dart (which fills the expired
/// portion with a dark overlay), this draws only the REMAINING portion as a
/// colored arc — matching the action-bar cooldown ring aesthetic.
class _CcProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CcProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    // Reason: inset by 2.5px so the ring sits just inside the badge border
    final radius = size.width / 2 - 2.5;
    final remainingSweep = progress * 2 * math.pi;
    const startAngle = -math.pi / 2; // Start from 12-o'clock, sweeps clockwise

    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      remainingSweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CcProgressRingPainter oldDelegate) =>
      (progress - oldDelegate.progress).abs() > 0.01 || color != oldDelegate.color;
}
