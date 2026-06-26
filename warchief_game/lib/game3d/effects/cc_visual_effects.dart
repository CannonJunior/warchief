import 'dart:math' as math;
import 'package:flutter/material.dart' hide Matrix4;
import 'package:vector_math/vector_math.dart' hide Colors;

import '../../models/active_effect.dart';
import '../../rendering3d/camera3d.dart';
import '../data/abilities/ability_types.dart';
import '../state/game_state.dart';
import '../systems/cc_behavior_system.dart';
import '../systems/gravity_well_system.dart';
import '../utils/screen_projection.dart';

// ==================== CC VISUAL EFFECTS OVERLAY ====================

/// CC types that receive lightweight visual indicators in this overlay.
const _visualCcTypes = {
  StatusEffect.sleep,
  StatusEffect.charm,
  StatusEffect.banish,
  StatusEffect.airborne,
  StatusEffect.suppress,
  StatusEffect.disorient,
  StatusEffect.grounded,
  StatusEffect.daze,
  StatusEffect.nearsight,
  StatusEffect.polymorph,
  StatusEffect.taunt,
};

/// Container for a unit's world position and its active visual CC effects.
class _UnitVisualData {
  final Vector3 worldPosition;
  final List<ActiveEffect> effects;
  _UnitVisualData(this.worldPosition, this.effects);
}

/// Lightweight visual effects overlay for active CC effects on units.
///
/// Renders small positioned icons/widgets at each affected unit's screen
/// position. This is a companion to [CcIndicatorOverlay] which shows
/// status badges — this layer adds thematic visual flair per CC type.
class CcVisualEffects extends StatelessWidget {
  final GameState gameState;
  final Camera3D? camera;

  const CcVisualEffects({
    super.key,
    required this.gameState,
    required this.camera,
  });

  @override
  Widget build(BuildContext context) {
    if (camera == null) return const SizedBox.shrink();

    final viewMatrix = camera!.getViewMatrix();
    final projMatrix = camera!.getProjectionMatrix();
    final screenSize = MediaQuery.of(context).size;
    // Reason: elapsed time drives animations (sine waves, rotation, orbits)
    final time = gameState.gameTimeSec;

    final children = <Widget>[];

    // -- Per-unit CC visual indicators --
    final units = _collectUnits();
    for (final unit in units) {
      final headPos = Vector3(
        unit.worldPosition.x,
        unit.worldPosition.y + 2.5,
        unit.worldPosition.z,
      );
      final screenPos = worldToScreen(headPos, viewMatrix, projMatrix, screenSize);
      if (screenPos == null) continue;
      if (screenPos.dx < -80 || screenPos.dx > screenSize.width + 80 ||
          screenPos.dy < -80 || screenPos.dy > screenSize.height + 80) {
        continue;
      }

      for (final effect in unit.effects) {
        final widget = _buildEffectWidget(effect.type, screenPos, time);
        if (widget != null) children.add(widget);
      }
    }

    // -- Gravity Well indicators (not tied to a unit) --
    for (final well in GravityWellSystem.activeWells) {
      final wellPos = Vector3(well.anchorX, 0.5, well.anchorZ);
      final sp = worldToScreen(wellPos, viewMatrix, projMatrix, screenSize);
      if (sp != null) {
        children.add(_buildGravityWell(sp, time, well));
      }
    }

    // -- Nearsight vignette (full-screen, player-only) --
    if (CcBehaviorSystem.isNearsighted(gameState.playerActiveEffects)) {
      children.add(_buildNearsightVignette(screenSize));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }

  // ==================== DATA COLLECTION ====================

  List<_UnitVisualData> _collectUnits() {
    final result = <_UnitVisualData>[];

    bool hasVisualCc(Iterable<ActiveEffect> effects) =>
        effects.any((e) => _visualCcTypes.contains(e.type) && !e.isExpired);
    List<ActiveEffect> collectVisualCc(Iterable<ActiveEffect> effects) =>
        effects.where((e) => _visualCcTypes.contains(e.type) && !e.isExpired).toList();

    // Player / active character
    final playerPos = gameState.activeTransform?.position;
    if (playerPos != null) {
      final effects = gameState.activeCharacterActiveEffects;
      if (hasVisualCc(effects)) {
        result.add(_UnitVisualData(playerPos.clone(), collectVisualCc(effects)));
      }
    }

    // Boss monster
    final monsterPos = gameState.monsterTransform?.position;
    if (monsterPos != null && gameState.monsterHealth > 0) {
      final effects = gameState.monsterActiveEffects;
      if (hasVisualCc(effects)) {
        result.add(_UnitVisualData(monsterPos.clone(), collectVisualCc(effects)));
      }
    }

    // Allies (skip Spirit Wolf summon)
    for (final ally in gameState.allies) {
      if (ally.isSummoned && ally.name == 'Spirit Wolf') continue;
      if (ally.health <= 0) continue;
      if (hasVisualCc(ally.activeEffects)) {
        result.add(_UnitVisualData(
          ally.transform.position.clone(),
          collectVisualCc(ally.activeEffects),
        ));
      }
    }

    // Alive minions
    for (final minion in gameState.aliveMinions) {
      if (hasVisualCc(minion.activeEffects)) {
        result.add(_UnitVisualData(
          minion.transform.position.clone(),
          collectVisualCc(minion.activeEffects),
        ));
      }
    }

    return result;
  }

  // ==================== EFFECT BUILDERS ====================

  Widget? _buildEffectWidget(StatusEffect type, Offset pos, double time) {
    switch (type) {
      case StatusEffect.sleep:
        return _buildSleepZs(pos, time);
      case StatusEffect.charm:
        return _buildCharmHeart(pos, time);
      case StatusEffect.banish:
        return _buildBanishCircle(pos);
      case StatusEffect.airborne:
        // Reason: only show airborne arrow when unit is actually elevated
        if (gameState.airborneHeight <= 0) return null;
        return _buildAirborneArrow(pos);
      case StatusEffect.suppress:
        return _buildSuppressLock(pos);
      case StatusEffect.disorient:
        return _buildDisorientSpiral(pos, time);
      case StatusEffect.grounded:
        return _buildGroundedVine(pos);
      case StatusEffect.daze:
        return _buildDazeStar(pos, time);
      case StatusEffect.polymorph:
        return _buildPolymorphPoof(pos, time);
      case StatusEffect.taunt:
        return _buildTauntExclamation(pos);
      default:
        return null;
    }
  }

  // ==================== SLEEP ====================

  /// Three small "Z" characters floating upward with a sine wave offset.
  Widget _buildSleepZs(Offset pos, double time) {
    // Reason: stagger each Z by 0.8s so they fan out at different heights
    const color = Color(0xFF9370DB); // Purple-blue
    final children = <Widget>[];
    for (int i = 0; i < 3; i++) {
      final phase = time * 1.2 + i * 0.8;
      final yOffset = -(phase % 3.0) * 12.0; // Float upward, reset every 3s
      final xOffset = math.sin(phase * 1.5) * 6.0; // Sine wave sway
      final opacity = (1.0 - (phase % 3.0) / 3.0).clamp(0.0, 1.0);
      final fontSize = 10.0 + i * 2.0;
      children.add(Positioned(
        left: pos.dx - 8 + xOffset + i * 8,
        top: pos.dy - 30 + yOffset,
        child: Opacity(
          opacity: opacity,
          child: Text(
            'Z',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
            ),
          ),
        ),
      ));
    }
    return Stack(clipBehavior: Clip.none, children: children);
  }

  // ==================== CHARM ====================

  /// Pink heart icon pulsing at the unit's position.
  Widget _buildCharmHeart(Offset pos, double time) {
    // Reason: scale oscillates 0.8..1.2 for a gentle pulse
    final scale = 1.0 + 0.2 * math.sin(time * 4.0);
    return Positioned(
      left: pos.dx - 10,
      top: pos.dy - 28,
      child: Transform.scale(
        scale: scale,
        child: const Icon(
          Icons.favorite,
          size: 20,
          color: Color(0xFFFF69B4), // Hot pink
          shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
        ),
      ),
    );
  }

  // ==================== BANISH ====================

  /// Semi-transparent dark blue circle overlay at unit position.
  Widget _buildBanishCircle(Offset pos) {
    return Positioned(
      left: pos.dx - 18,
      top: pos.dy - 18,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF191970).withValues(alpha: 0.5),
          border: Border.all(
            color: const Color(0xFF4169E1).withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ==================== AIRBORNE ====================

  /// Upward arrow icon at unit position, sky blue.
  Widget _buildAirborneArrow(Offset pos) {
    return Positioned(
      left: pos.dx - 10,
      top: pos.dy - 32,
      child: const Icon(
        Icons.arrow_upward,
        size: 20,
        color: Color(0xFF87CEEB), // Sky blue
        shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
      ),
    );
  }

  // ==================== SUPPRESS ====================

  /// Lock icon at unit position, deep purple.
  Widget _buildSuppressLock(Offset pos) {
    return Positioned(
      left: pos.dx - 10,
      top: pos.dy - 28,
      child: const Icon(
        Icons.lock,
        size: 20,
        color: Color(0xFF6A0DAD), // Deep purple
        shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
      ),
    );
  }

  // ==================== DISORIENT ====================

  /// Spinning spiral icon at unit position, gold colored.
  Widget _buildDisorientSpiral(Offset pos, double time) {
    final angle = time * 3.0; // ~0.5 rotations per second
    return Positioned(
      left: pos.dx - 10,
      top: pos.dy - 28,
      child: Transform.rotate(
        angle: angle,
        child: const Icon(
          Icons.toys,
          size: 20,
          color: Color(0xFFFFD700), // Gold
          shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
        ),
      ),
    );
  }

  // ==================== GROUNDED ====================

  /// Vine icon at unit base, earth brown.
  Widget _buildGroundedVine(Offset pos) {
    return Positioned(
      left: pos.dx - 10,
      top: pos.dy + 4, // Below the unit, near base
      child: const Icon(
        Icons.grass,
        size: 20,
        color: Color(0xFF8B4513), // Earth brown (saddle brown)
        shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
      ),
    );
  }

  // ==================== DAZE ====================

  /// Star icon orbiting above unit head, amber.
  Widget _buildDazeStar(Offset pos, double time) {
    // Reason: orbit radius 14px, completes one loop every ~2.5s
    final angle = time * 2.5;
    final orbitX = math.cos(angle) * 14.0;
    final orbitY = math.sin(angle) * 8.0; // Flattened orbit for perspective
    return Positioned(
      left: pos.dx - 8 + orbitX,
      top: pos.dy - 36 + orbitY,
      child: const Icon(
        Icons.star,
        size: 16,
        color: Color(0xFFFFBF00), // Amber
        shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
      ),
    );
  }

  // ==================== NEARSIGHT VIGNETTE ====================

  /// Dark semi-transparent vignette covering screen edges when player
  /// is nearsighted.
  Widget _buildNearsightVignette(Size screenSize) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.7,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.7),
            ],
            stops: const [0.2, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  // ==================== POLYMORPH ====================

  /// Small green circle "poof" particle at unit position.
  Widget _buildPolymorphPoof(Offset pos, double time) {
    // Reason: gentle pulse to suggest lingering magical transformation
    final scale = 0.9 + 0.15 * math.sin(time * 5.0);
    return Positioned(
      left: pos.dx - 8,
      top: pos.dy - 24,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF32CD32).withValues(alpha: 0.6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF32CD32).withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TAUNT ====================

  /// Red exclamation icon at unit position.
  Widget _buildTauntExclamation(Offset pos) {
    return Positioned(
      left: pos.dx - 10,
      top: pos.dy - 28,
      child: const Icon(
        Icons.priority_high,
        size: 20,
        color: Color(0xFFDC143C), // Crimson red
        shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
      ),
    );
  }

  // ==================== GRAVITY WELL ====================

  /// Pulsing violet circle at the gravity well's anchor position.
  Widget _buildGravityWell(Offset pos, double time, GravityWell well) {
    // Reason: pulse between 28-36px radius to convey pulling energy
    final pulseSize = 32.0 + 4.0 * math.sin(time * 3.5);
    final opacity = (well.remainingDuration / well.duration).clamp(0.2, 0.7);
    return Positioned(
      left: pos.dx - pulseSize / 2,
      top: pos.dy - pulseSize / 2,
      child: Container(
        width: pulseSize,
        height: pulseSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF8A2BE2).withValues(alpha: opacity * 0.4),
          border: Border.all(
            color: const Color(0xFF8A2BE2).withValues(alpha: opacity),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A2BE2).withValues(alpha: opacity * 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
