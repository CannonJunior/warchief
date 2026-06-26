import 'dart:math' as math;
import '../state/game_state.dart';
import '../state/cc_config.dart';
import '../state/wind_state.dart';
import '../../models/ally.dart';
import '../../models/monster.dart';
import '../../models/active_effect.dart';
import '../data/abilities/ability_types.dart';

/// Per-frame airborne physics: gravity, landing, fall damage, juggle window.
///
/// Called from game3d_widget_update.dart after ability system, before render.
class AirborneSystem {
  AirborneSystem._();

  static void update(double dt, GameState gameState) {
    final cfg = globalCcConfig;
    final gravity = cfg?.airborneGravityAccel ?? 12.0;
    final baseHeight = cfg?.airborneLaunchHeightBase ?? 4.0;
    final fallDmgPerUnit = cfg?.airborneFallDamagePerUnit ?? 5.0;
    final juggleWindow = cfg?.airborneJuggleWindow ?? 0.5;

    // Player (Warchief)
    _updateUnit(dt, gravity, baseHeight, fallDmgPerUnit, juggleWindow,
      gameState.airborneHeight, gameState.airborneVelocityY,
      gameState.airborneSourceHeight, gameState.juggleWindowTimer,
      (h) => gameState.airborneHeight = h,
      (v) => gameState.airborneVelocityY = v,
      (s) => gameState.airborneSourceHeight = s,
      (j) => gameState.juggleWindowTimer = j,
      (dmg) { gameState.playerHealth = (gameState.playerHealth - dmg).clamp(0.0, gameState.playerMaxHealth); },
      gameState.playerTransform,
    );

    // Allies
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      _updateUnit(dt, gravity, baseHeight, fallDmgPerUnit, juggleWindow,
        ally.airborneHeight, ally.airborneVelocityY,
        ally.airborneSourceHeight, ally.juggleWindowTimer,
        (h) => ally.airborneHeight = h,
        (v) => ally.airborneVelocityY = v,
        (s) => ally.airborneSourceHeight = s,
        (j) => ally.juggleWindowTimer = j,
        (dmg) { ally.health = (ally.health - dmg).clamp(0.0, ally.maxHealth); },
        ally.transform,
      );
    }

    // Minions
    for (final minion in gameState.aliveMinions) {
      _updateUnit(dt, gravity, baseHeight, fallDmgPerUnit, juggleWindow,
        minion.airborneHeight, minion.airborneVelocityY,
        minion.airborneSourceHeight, minion.juggleWindowTimer,
        (h) => minion.airborneHeight = h,
        (v) => minion.airborneVelocityY = v,
        (s) => minion.airborneSourceHeight = s,
        (j) => minion.juggleWindowTimer = j,
        (dmg) { minion.health = (minion.health - dmg).clamp(0.0, minion.maxHealth); },
        minion.transform,
      );
    }
  }

  /// Tick one unit's airborne state. If height > 0, applies gravity and checks
  /// for landing. If only the juggle window is ticking, decrements it.
  /// After physics, offsets the transform Y by the current airborne height
  /// (terrain height was already set by the movement system this frame).
  static void _updateUnit(
    double dt, double gravity, double baseHeight,
    double fallDmgPerUnit, double juggleWindow,
    double height, double velY, double source, double juggle,
    void Function(double) setHeight,
    void Function(double) setVelY,
    void Function(double) setSource,
    void Function(double) setJuggle,
    void Function(double) applyDamage,
    dynamic transform,
  ) {
    if (height > 0) {
      // Reason: wind extends effective hang time by reducing gravity slightly
      final windMult = globalWindState != null &&
              globalWindState!.effectiveWindStrength > 1.0
          ? 1.0 -
              (globalCcConfig?.airborneWindDurationBonus ?? 0.3) *
                  ((globalWindState!.effectiveWindStrength - 1.0) / 9.0).clamp(0.0, 1.0)
          : 1.0;

      velY -= gravity * windMult * dt;
      height += velY * dt;
      if (height > source) source = height;

      if (height <= 0) {
        height = 0.0;
        velY = 0.0;

        if (source > baseHeight) {
          applyDamage((source - baseHeight) * fallDmgPerUnit);
        }

        setJuggle(juggleWindow);
        source = 0.0;
      }

      setHeight(height);
      setVelY(velY);
      setSource(source);
    } else if (juggle > 0) {
      setJuggle((juggle - dt).clamp(0.0, double.infinity));
    }

    // Offset mesh Y so the unit visually floats above terrain
    if (transform != null && height > 0) {
      transform.position.y += height;
    }
  }
}
