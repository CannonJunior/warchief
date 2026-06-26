import 'package:flutter/foundation.dart' show debugPrint;
import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../state/wind_state.dart';
import '../state/wind_config.dart';
import '../../game/controllers/input_manager.dart';
import '../../rendering3d/camera3d.dart';
import '../../models/game_action.dart';
import '../../models/target_dummy.dart';
import '../../models/active_effect.dart';
import '../data/abilities/ability_types.dart' show StatusEffect;
import '../state/cc_config.dart';
import 'cc_behavior_system.dart';
import '../data/stances/stance_types.dart';
import '../state/stance_runtime_state.dart';
import 'stance_runtime_system.dart';

/// Input System - Handles player input processing
///
/// Processes input from InputManager and translates it into:
/// - Camera movements (yaw, pitch, zoom)
/// - Player movements (forward, backward, strafe, rotation)
///
/// Note: InputManager handles key events and action mapping.
/// This system handles the actual processing of those actions.
class InputSystem {
  InputSystem._(); // Private constructor

  /// Track previous camera toggle state to detect single press
  static bool _previousCameraToggleState = false;

  // ==================== DISORIENT STATE ====================
  static final List<int> _disorientMap = [0, 1, 2, 3]; // fwd, back, left, right
  static double _disorientRemapTimer = 0.0;
  static final math.Random _disorientRng = math.Random();

  // ==================== DOUBLE-TAP DETECTION FOR Q/E ====================

  /// Timestamp of last Q key release (for double-tap detection)
  static double _lastQReleaseTime = -1.0;

  /// Timestamp of last E key release (for double-tap detection)
  static double _lastEReleaseTime = -1.0;

  /// Whether Q was held in the previous frame
  static bool _prevQHeld = false;

  /// Whether E was held in the previous frame
  static bool _prevEHeld = false;

  /// Whether hard-bank mode is active for Q (double-tapped)
  static bool _hardBankQ = false;

  /// Whether hard-bank mode is active for E (double-tapped)
  static bool _hardBankE = false;

  /// Monotonic time accumulator for double-tap timing
  static double _flightTime = 0.0;

  /// Main entry point - processes all input
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame
  /// - inputManager: Input manager to read input state from
  /// - camera: Camera to control
  /// - gameState: Current game state to update
  static void update(
    double dt,
    InputManager inputManager,
    Camera3D camera,
    GameState gameState,
  ) {
    if (gameState.activeTransform == null) return;

    // Update input manager state
    inputManager.update(dt);

    // Process camera controls
    handleCameraInput(dt, inputManager, camera);

    // Process player movement
    handlePlayerMovement(dt, inputManager, gameState);
  }

  /// Handles camera input (yaw, pitch, zoom, mode toggle)
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame
  /// - inputManager: Input manager to read input state from
  /// - camera: Camera to control
  static void handleCameraInput(
    double dt,
    InputManager inputManager,
    Camera3D camera,
  ) {
    // Camera mode toggle (V key) - detect single press
    final cameraTogglePressed = inputManager.isActionPressed(GameAction.cameraToggleMode);
    if (cameraTogglePressed && !_previousCameraToggleState) {
      camera.toggleMode();
      debugPrint('Camera mode toggled to: ${camera.mode}');
    }
    _previousCameraToggleState = cameraTogglePressed;

    if (inputManager.isActionPressed(GameAction.cameraRotateLeft)) {
      camera.yawBy(-90 * dt); // J key - yaw left
    }
    if (inputManager.isActionPressed(GameAction.cameraRotateRight)) {
      camera.yawBy(90 * dt); // L key - yaw right
    }
    if (inputManager.isActionPressed(GameAction.cameraPitchUp)) {
      camera.pitchBy(45 * dt); // N key - pitch up
    }
    if (inputManager.isActionPressed(GameAction.cameraPitchDown)) {
      camera.pitchBy(-45 * dt); // M key - pitch down
    }
    if (inputManager.isActionPressed(GameAction.cameraZoomIn)) {
      camera.zoom(-5 * dt); // I key - zoom in
    }
    if (inputManager.isActionPressed(GameAction.cameraZoomOut)) {
      camera.zoom(5 * dt); // K key - zoom out
    }
  }

  /// Handles player movement input (WASD, QE, rotation)
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame
  /// - inputManager: Input manager to read input state from
  /// - gameState: Current game state to update
  static void handlePlayerMovement(
    double dt,
    InputManager inputManager,
    GameState gameState,
  ) {
    if (gameState.activeTransform == null) return;

    // Grounded blocks flight launch
    if (gameState.isFlying &&
        CcBehaviorSystem.isGrounded(gameState.playerActiveEffects)) {
      // Reason: grounded forces landing — can't stay airborne
      gameState.isFlying = false;
    }

    // Flight mode — different control scheme (Warchief only)
    if (gameState.isFlying) {
      _handleFlightMovement(dt, inputManager, gameState);
      return;
    }

    // Read raw movement inputs
    bool wantFwd = inputManager.isActionPressed(GameAction.moveForward);
    bool wantBack = inputManager.isActionPressed(GameAction.moveBackward);
    bool wantLeft = inputManager.isActionPressed(GameAction.strafeLeft);
    bool wantRight = inputManager.isActionPressed(GameAction.strafeRight);

    // Disorient: remap movement directions
    if (CcBehaviorSystem.isDisoriented(gameState.playerActiveEffects)) {
      final interval = globalCcConfig?.disorientRemapInterval ?? 1.5;
      _disorientRemapTimer += dt;
      if (_disorientRemapTimer >= interval) {
        _disorientRemapTimer = 0.0;
        _disorientMap.shuffle(_disorientRng);
      }
      final raw = [wantFwd, wantBack, wantLeft, wantRight];
      wantFwd = raw[_disorientMap[0]];
      wantBack = raw[_disorientMap[1]];
      wantLeft = raw[_disorientMap[2]];
      wantRight = raw[_disorientMap[3]];
    } else {
      _disorientRemapTimer = 0.0;
    }

    final isMoving = wantFwd || wantBack || wantLeft || wantRight;

    // Cancel cast/channel if moving during a stationary cast
    if (isMoving && gameState.isCasting) {
      gameState.cancelCast();
    }
    if (isMoving && gameState.isChanneling) {
      gameState.cancelChannel();
    }

    // Get effective speed (includes windup modifier if winding up)
    double effectiveSpeed = gameState.activeEffectiveSpeed;

    // Compute combined movement direction for wind modifier
    double moveDx = 0.0;
    double moveDz = 0.0;

    final fwd = Vector3(
      -math.sin(radians(gameState.activeRotation)),
      0,
      -math.cos(radians(gameState.activeRotation)),
    );
    final right = Vector3(
      math.cos(radians(gameState.activeRotation)),
      0,
      -math.sin(radians(gameState.activeRotation)),
    );

    if (wantFwd) { moveDx += fwd.x; moveDz += fwd.z; }
    if (wantBack) { moveDx -= fwd.x; moveDz -= fwd.z; }
    if (wantLeft) { moveDx -= right.x; moveDz -= right.z; }
    if (wantRight) { moveDx += right.x; moveDz += right.z; }

    // Warden stance: record directional input for ability modifiers
    if (gameState.playerStance == StanceId.warden) {
      final m = gameState.activeStance.mechanics;
      if (m != null) {
        WardenDirection dir;
        if (!isMoving) {
          dir = WardenDirection.stationary;
        } else if (inputManager.isActionPressed(GameAction.sprint) &&
            inputManager.isActionPressed(GameAction.moveForward)) {
          dir = WardenDirection.sprint;
        } else if (inputManager.isActionPressed(GameAction.moveForward) &&
            !inputManager.isActionPressed(GameAction.moveBackward)) {
          dir = WardenDirection.forward;
        } else if (inputManager.isActionPressed(GameAction.moveBackward) &&
            !inputManager.isActionPressed(GameAction.moveForward)) {
          dir = WardenDirection.backward;
        } else if (inputManager.isActionPressed(GameAction.strafeLeft)) {
          dir = WardenDirection.strafeLeft;
        } else if (inputManager.isActionPressed(GameAction.strafeRight)) {
          dir = WardenDirection.strafeRight;
        } else {
          dir = WardenDirection.forward;
        }
        StanceRuntimeSystem.recordWardenInput(m, gameState.stanceRuntime, dir);
      }
    }

    // Reason: headwind slows player, tailwind speeds up; resistance from active stance reduces penalty
    final windMod = globalWindState?.getMovementModifier(
      moveDx, moveDz,
      resistance: gameState.activeStance.windResistance,
    ) ?? 1.0;
    effectiveSpeed *= windMod;

    // A = Rotate Right (rotation not affected by windup)
    if (inputManager.isActionPressed(GameAction.rotateLeft)) {
      gameState.activeRotation = gameState.activeRotation + 180 * dt;
      gameState.activeTransform!.rotation.y = gameState.activeRotation;
    }

    // D = Rotate Left (rotation not affected by windup)
    if (inputManager.isActionPressed(GameAction.rotateRight)) {
      gameState.activeRotation = gameState.activeRotation - 180 * dt;
      gameState.activeTransform!.rotation.y = gameState.activeRotation;
    }

    // Accumulate movement delta from WASD/QE + wind drift
    double deltaX = 0.0;
    double deltaZ = 0.0;

    if (wantFwd) { deltaX += fwd.x * effectiveSpeed * dt; deltaZ += fwd.z * effectiveSpeed * dt; }
    if (wantBack) { deltaX -= fwd.x * effectiveSpeed * dt; deltaZ -= fwd.z * effectiveSpeed * dt; }
    if (wantLeft) { deltaX -= right.x * effectiveSpeed * dt; deltaZ -= right.z * effectiveSpeed * dt; }
    if (wantRight) { deltaX += right.x * effectiveSpeed * dt;
      deltaZ += right.z * effectiveSpeed * dt;
    }

    if (!gameState.ability4Active) {
      final drift = globalWindState?.getWindDrift(
        dt, resistance: gameState.activeStance.windResistance,
      ) ?? const [0.0, 0.0];
      deltaX += drift[0];
      deltaZ += drift[1];
    }

    // Apply movement then constrain against enemy collision
    if (deltaX != 0.0 || deltaZ != 0.0) {
      final pos = gameState.activeTransform!.position;
      pos.x += deltaX;
      pos.z += deltaZ;

      // Push player out of any enemy they overlap — movement abilities
      // (ability4Active / phased) skip this so dashes punch through.
      if (!gameState.ability4Active) {
        final radius = gameState.isWarchiefActive
            ? GameConfig.playerSize * 0.5
            : GameConfig.allySize * 0.5;
        _constrainAgainstEnemies(pos, radius, gameState);
      }
    }
  }

  /// Iteratively push position out of all overlapping enemy collision circles.
  /// Runs multiple passes so being pushed out of one enemy and into another
  /// is resolved within the same frame.
  static void _constrainAgainstEnemies(
    Vector3 pos,
    double radius,
    GameState gameState,
  ) {
    for (int iter = 0; iter < 4; iter++) {
      bool anyOverlap = false;

      // Boss monster
      if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
        final mt = gameState.monsterTransform!;
        final minDist = radius + GameConfig.monsterSize * 0.5;
        if (_pushOut(pos, mt.position.x, mt.position.z, minDist)) {
          anyOverlap = true;
        }
      }

      // Alive minions
      for (final minion in gameState.aliveMinions) {
        final minDist = radius + minion.definition.effectiveScale * 0.5;
        final mp = minion.transform.position;
        if (_pushOut(pos, mp.x, mp.z, minDist)) {
          anyOverlap = true;
        }
      }

      // Duel combatants
      for (final combatant in gameState.duelCombatants) {
        if (combatant.health <= 0) continue;
        final minDist = radius + GameConfig.allySize * 0.5;
        if (_pushOut(pos, combatant.transform.position.x, combatant.transform.position.z, minDist)) {
          anyOverlap = true;
        }
      }

      // Target dummy
      final dummy = gameState.targetDummy;
      if (dummy != null && dummy.isSpawned) {
        final minDist = radius + TargetDummy.size * 0.5;
        if (_pushOut(pos, dummy.transform.position.x, dummy.transform.position.z, minDist)) {
          anyOverlap = true;
        }
      }

      if (!anyOverlap) break;
    }
  }

  /// Push pos out of the circle centred at (cx, cz) with combined radius
  /// minDist.  Returns true if an overlap was resolved.
  static bool _pushOut(Vector3 pos, double cx, double cz, double minDist) {
    final dx = pos.x - cx;
    final dz = pos.z - cz;
    final distSq = dx * dx + dz * dz;
    if (distSq >= minDist * minDist) return false;

    final dist = math.sqrt(distSq);
    if (dist < 0.001) {
      // Exactly on top — nudge in an arbitrary direction
      pos.x += minDist;
      return true;
    }
    final nx = dx / dist;
    final nz = dz / dist;
    pos.x = cx + nx * minDist;
    pos.z = cz + nz * minDist;
    return true;
  }

  /// Handles flight movement controls.
  ///
  /// S = pitch up (climb), W = pitch down (dive), neither = auto-level.
  /// Q = bank left + airplane turn left, E = bank right + airplane turn right.
  /// Double-tap Q/E = hard bank (50% faster, 90-degree max).
  /// Constant forward movement at flightSpeed * cos(pitch).
  /// Vertical: flightSpeed * sin(pitch) (handled in physics).
  /// ALT = speed boost, Space = speed boost (costs white mana).
  /// SHIFT + Q/W/E/S = suppress camera angle changes.
  /// A/D = direct yaw, A+Q / D+E = barrel roll.
  /// Turning reduces groundspeed proportionally.
  static void _handleFlightMovement(
    double dt,
    InputManager inputManager,
    GameState gameState,
  ) {
    // Flight is Warchief-only
    if (!gameState.isWarchiefActive) return;
    if (gameState.playerTransform == null) return;

    _flightTime += dt;

    final config = globalWindConfig;
    final pitchRate = config?.pitchRate ?? 60.0;
    final baseSpeed = config?.flightSpeed ?? 7.0;
    final boostMult = config?.boostMultiplier ?? 1.5;
    final doubleTapWindow = config?.flightDoubleTapWindow ?? 0.3;
    final hardBankRateMult = config?.flightHardBankRateMultiplier ?? 1.5;
    final hardBankMaxAngle = config?.flightHardBankMaxAngle ?? 90.0;
    final spaceBoostMult = config?.flightSpaceBoostMultiplier ?? 1.8;
    final spaceBoostManaCost = config?.flightSpaceBoostManaCost ?? 8.0;
    final turnSpeedReduction = config?.flightTurnSpeedReductionFactor ?? 0.3;

    // Sovereign buff speed bonus
    final sovereignSpeedMult = gameState.sovereignBuffActive ? 1.5 : 1.0;

    // Wind Warp flight speed bonus (doubles flight speed for 5s)
    final windWarpSpeedMult = gameState.windWarpSpeedActive ? 2.0 : 1.0;

    // ==================== PITCH (S = up, W = down) ====================

    // S = pitch up (climb) — unclamped, allows full loops
    if (inputManager.isActionPressed(GameAction.moveBackward)) {
      gameState.flightPitchAngle += pitchRate * dt;
    }
    // W = pitch down (dive) — unclamped, allows full loops
    else if (inputManager.isActionPressed(GameAction.moveForward)) {
      gameState.flightPitchAngle -= pitchRate * dt;
    }
    // Neither W nor S — auto-level toward nearest horizon
    else {
      // Normalize to [-180, 180] for shortest-path auto-leveling
      double normalized = gameState.flightPitchAngle % 360.0;
      if (normalized > 180.0) normalized -= 360.0;
      if (normalized < -180.0) normalized += 360.0;

      final levelRate = pitchRate * 0.5 * dt;
      if (normalized.abs() < levelRate) {
        gameState.flightPitchAngle = 0.0;
      } else if (normalized > 0) {
        gameState.flightPitchAngle -= levelRate;
      } else {
        gameState.flightPitchAngle += levelRate;
      }
    }

    // Keep angle in [-360, 360] range to avoid precision drift
    if (gameState.flightPitchAngle > 360.0) gameState.flightPitchAngle -= 360.0;
    if (gameState.flightPitchAngle < -360.0) gameState.flightPitchAngle += 360.0;

    // ==================== SPEED ====================

    final stanceSpeedMult = gameState.activeStance.movementSpeedMultiplier;
    double currentSpeed = baseSpeed * sovereignSpeedMult * windWarpSpeedMult * stanceSpeedMult;

    // ALT = speed boost
    if (inputManager.isActionPressed(GameAction.sprint)) {
      currentSpeed *= boostMult;
    }

    // Spacebar = speed boost at cost of white mana
    if (inputManager.isActionPressed(GameAction.jump)) {
      final manaCost = spaceBoostManaCost * dt;
      if (gameState.hasWhiteMana(manaCost)) {
        gameState.spendWhiteMana(manaCost);
        currentSpeed *= spaceBoostMult;
      }
    }

    gameState.flightSpeed = currentSpeed;

    // ==================== FORWARD MOVEMENT ====================

    final fwd = Vector3(
      -math.sin(radians(gameState.playerRotation)),
      0,
      -math.cos(radians(gameState.playerRotation)),
    );

    final pitchRad = gameState.flightPitchAngle * (math.pi / 180.0);
    final horizontalSpeed = currentSpeed * math.cos(pitchRad);
    gameState.playerTransform!.position += fwd * horizontalSpeed * dt;

    // ==================== DOUBLE-TAP DETECTION FOR Q/E ====================

    final qHeld = inputManager.isActionPressed(GameAction.strafeLeft);
    final eHeld = inputManager.isActionPressed(GameAction.strafeRight);

    // Reason: detect key release (held last frame, not this frame) to
    // record release timestamp for double-tap window comparison
    if (_prevQHeld && !qHeld) {
      // Q was just released
      _lastQReleaseTime = _flightTime;
      _hardBankQ = false;
    }
    if (_prevEHeld && !eHeld) {
      // E was just released
      _lastEReleaseTime = _flightTime;
      _hardBankE = false;
    }

    // Detect double-tap: key pressed again within doubleTapWindow of release
    if (qHeld && !_prevQHeld && _lastQReleaseTime > 0) {
      if ((_flightTime - _lastQReleaseTime) <= doubleTapWindow) {
        _hardBankQ = true;
      }
    }
    if (eHeld && !_prevEHeld && _lastEReleaseTime > 0) {
      if ((_flightTime - _lastEReleaseTime) <= doubleTapWindow) {
        _hardBankE = true;
      }
    }

    _prevQHeld = qHeld;
    _prevEHeld = eHeld;

    // ==================== BANKING / BARREL ROLL ====================

    final bankRate = config?.flightBankRate ?? 120.0;
    final maxBankAngle = config?.flightMaxBankAngle ?? 60.0;
    final autoLevelRate = config?.flightAutoLevelRate ?? 90.0;
    final autoLevelThreshold = config?.flightAutoLevelThreshold ?? 90.0;
    final bankToTurnMult = config?.flightBankToTurnMultiplier ?? 2.5;
    final barrelRollRate = config?.flightBarrelRollRate ?? 360.0;

    final aHeld = inputManager.isActionPressed(GameAction.rotateLeft);
    final dHeld = inputManager.isActionPressed(GameAction.rotateRight);

    final barrelRollLeft = qHeld && aHeld;
    final barrelRollRight = eHeld && dHeld;

    // Determine effective bank rate and max angle based on double-tap state
    final effectiveBankRate = (_hardBankQ || _hardBankE)
        ? bankRate * hardBankRateMult
        : bankRate;
    final effectiveMaxBankAngle = (_hardBankQ || _hardBankE)
        ? hardBankMaxAngle
        : maxBankAngle;

    if (barrelRollLeft) {
      gameState.flightBankAngle -= barrelRollRate * dt;
      if (gameState.flightBankAngle < -360) gameState.flightBankAngle += 360;
    } else if (barrelRollRight) {
      gameState.flightBankAngle += barrelRollRate * dt;
      if (gameState.flightBankAngle > 360) gameState.flightBankAngle -= 360;
    } else if (qHeld) {
      gameState.flightBankAngle = (gameState.flightBankAngle - effectiveBankRate * dt)
          .clamp(-effectiveMaxBankAngle, effectiveMaxBankAngle);
    } else if (eHeld) {
      gameState.flightBankAngle = (gameState.flightBankAngle + effectiveBankRate * dt)
          .clamp(-effectiveMaxBankAngle, effectiveMaxBankAngle);
    } else {
      // Auto-level bank when no Q/E input
      if (gameState.flightBankAngle.abs() < autoLevelThreshold) {
        if (gameState.flightBankAngle > 0) {
          gameState.flightBankAngle =
              (gameState.flightBankAngle - autoLevelRate * dt)
                  .clamp(0.0, double.infinity);
        } else if (gameState.flightBankAngle < 0) {
          gameState.flightBankAngle =
              (gameState.flightBankAngle + autoLevelRate * dt)
                  .clamp(double.negativeInfinity, 0.0);
        }
      }
    }

    // ==================== APPLY VISUAL ROTATIONS ====================

    gameState.playerTransform!.rotation.x = gameState.flightPitchAngle;
    gameState.playerTransform!.rotation.z = -gameState.flightBankAngle;

    // ==================== YAW: BANK-INDUCED + A/D DIRECT ====================

    // Track total yaw change this frame for turn speed reduction
    double yawDeltaThisFrame = 0.0;

    // Reason: during barrel rolls, yaw inputs are suppressed (keys used for combo)
    if (!barrelRollLeft && !barrelRollRight) {
      // Airplane-style turn from banking: bank angle drives yaw rotation.
      // Negative bank (Q/left) → turn left (positive rotation),
      // positive bank (E/right) → turn right (negative rotation).
      if (gameState.flightBankAngle.abs() > 1.0) {
        final bankRad = gameState.flightBankAngle * (math.pi / 180.0);
        final bankTurnRate = math.sin(bankRad) * bankToTurnMult * 60.0;
        final bankYawDelta = bankTurnRate * dt;
        gameState.playerRotation -= bankYawDelta;
        gameState.playerTransform!.rotation.y = gameState.playerRotation;
        yawDeltaThisFrame += bankYawDelta.abs();
      }

      // A/D direct yaw (additive, with bank-enhanced turn rate)
      final bankAngleRad =
          (gameState.flightBankAngle.abs().clamp(0.0, 90.0)) *
              (math.pi / 180.0);
      final turnMultiplier = 1.0 + math.sin(bankAngleRad) * bankToTurnMult;
      final effectiveTurnRate = 180.0 * turnMultiplier;

      if (aHeld) {
        final directYawDelta = effectiveTurnRate * dt;
        gameState.playerRotation += directYawDelta;
        gameState.playerTransform!.rotation.y = gameState.playerRotation;
        yawDeltaThisFrame += directYawDelta.abs();
      }
      if (dHeld) {
        final directYawDelta = effectiveTurnRate * dt;
        gameState.playerRotation -= directYawDelta;
        gameState.playerTransform!.rotation.y = gameState.playerRotation;
        yawDeltaThisFrame += directYawDelta.abs();
      }
    }

    // ==================== TURN SPEED REDUCTION ====================

    // Reason: turning should bleed groundspeed proportionally to how
    // hard the player is turning, simulating aerodynamic drag in turns
    if (yawDeltaThisFrame > 0.0 && dt > 0.0) {
      final yawRateDegreesPerSec = yawDeltaThisFrame / dt;
      // Normalize turn rate: 180 deg/s is full reduction factor
      final normalizedTurnRate = (yawRateDegreesPerSec / 180.0).clamp(0.0, 1.0);
      final speedReduction = 1.0 - (normalizedTurnRate * turnSpeedReduction);
      currentSpeed *= speedReduction;
    }

    // ==================== STORE GROUND SPEED ====================

    // Reason: ground speed = horizontal component for HUD display
    gameState.flightGroundSpeed = currentSpeed * math.cos(pitchRad).abs();
  }
}
