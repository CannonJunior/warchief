import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/wind_state.dart';
import '../state/wind_config.dart';
import '../../game/controllers/input_manager.dart';
import '../../rendering3d/camera3d.dart';
import '../../models/game_action.dart';

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
    if (gameState.playerTransform == null) return;

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
      print('Camera mode toggled to: ${camera.mode}');
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
    if (gameState.playerTransform == null) return;

    // Flight mode — different control scheme
    if (gameState.isFlying) {
      _handleFlightMovement(dt, inputManager, gameState);
      return;
    }

    // Check if any movement key is pressed
    final isMoving = inputManager.isActionPressed(GameAction.moveForward) ||
        inputManager.isActionPressed(GameAction.moveBackward) ||
        inputManager.isActionPressed(GameAction.strafeLeft) ||
        inputManager.isActionPressed(GameAction.strafeRight);

    // Cancel cast if moving during a stationary cast
    if (isMoving && gameState.isCasting) {
      gameState.cancelCast();
    }

    // Get effective speed (includes windup modifier if winding up)
    double effectiveSpeed = gameState.effectivePlayerSpeed;

    // Compute combined movement direction for wind modifier
    double moveDx = 0.0;
    double moveDz = 0.0;

    final fwd = Vector3(
      -math.sin(radians(gameState.playerRotation)),
      0,
      -math.cos(radians(gameState.playerRotation)),
    );
    final right = Vector3(
      math.cos(radians(gameState.playerRotation)),
      0,
      -math.sin(radians(gameState.playerRotation)),
    );

    if (inputManager.isActionPressed(GameAction.moveForward)) {
      moveDx += fwd.x;
      moveDz += fwd.z;
    }
    if (inputManager.isActionPressed(GameAction.moveBackward)) {
      moveDx -= fwd.x;
      moveDz -= fwd.z;
    }
    if (inputManager.isActionPressed(GameAction.strafeLeft)) {
      moveDx -= right.x;
      moveDz -= right.z;
    }
    if (inputManager.isActionPressed(GameAction.strafeRight)) {
      moveDx += right.x;
      moveDz += right.z;
    }

    // Reason: headwind slows player, tailwind speeds up
    final windMod = globalWindState?.getMovementModifier(moveDx, moveDz) ?? 1.0;
    effectiveSpeed *= windMod;

    // W = Forward
    if (inputManager.isActionPressed(GameAction.moveForward)) {
      gameState.playerTransform!.position += fwd * effectiveSpeed * dt;
    }

    // S = Backward
    if (inputManager.isActionPressed(GameAction.moveBackward)) {
      gameState.playerTransform!.position -= fwd * effectiveSpeed * dt;
    }

    // A = Rotate Right (rotation not affected by windup)
    if (inputManager.isActionPressed(GameAction.rotateLeft)) {
      gameState.playerRotation += 180 * dt; // A key - rotate right
      gameState.playerTransform!.rotation.y = gameState.playerRotation;
    }

    // D = Rotate Left (rotation not affected by windup)
    if (inputManager.isActionPressed(GameAction.rotateRight)) {
      gameState.playerRotation -= 180 * dt; // D key - rotate left
      gameState.playerTransform!.rotation.y = gameState.playerRotation;
    }

    // Q = Strafe Left
    if (inputManager.isActionPressed(GameAction.strafeLeft)) {
      gameState.playerTransform!.position -= right * effectiveSpeed * dt;
    }

    // E = Strafe Right
    if (inputManager.isActionPressed(GameAction.strafeRight)) {
      gameState.playerTransform!.position += right * effectiveSpeed * dt;
    }
  }

  /// Handles flight movement controls.
  ///
  /// W = pitch up (climb), S = pitch down (dive), neither = auto-level.
  /// Constant forward movement at flightSpeed * cos(pitch).
  /// Vertical: flightSpeed * sin(pitch) (handled in physics).
  /// ALT = speed boost, Space = brake + small upward bump.
  /// A/D rotation still works, Q/E strafe disabled.
  static void _handleFlightMovement(
    double dt,
    InputManager inputManager,
    GameState gameState,
  ) {
    if (gameState.playerTransform == null) return;

    final config = globalWindConfig;
    final pitchRate = config?.pitchRate ?? 60.0;
    final maxPitch = config?.maxPitchAngle ?? 45.0;
    final baseSpeed = config?.flightSpeed ?? 7.0;
    final boostMult = config?.boostMultiplier ?? 1.5;
    final brakeMult = config?.brakeMultiplier ?? 0.6;
    final brakeJump = config?.brakeJumpForce ?? 3.0;

    // Sovereign buff speed bonus
    final sovereignSpeedMult = gameState.sovereignBuffActive ? 1.5 : 1.0;

    // Wind Warp flight speed bonus (doubles flight speed for 5s)
    final windWarpSpeedMult = gameState.windWarpSpeedActive ? 2.0 : 1.0;

    // W = pitch up (climb)
    if (inputManager.isActionPressed(GameAction.moveForward)) {
      gameState.flightPitchAngle += pitchRate * dt;
      if (gameState.flightPitchAngle > maxPitch) {
        gameState.flightPitchAngle = maxPitch;
      }
    }
    // S = pitch down (dive)
    else if (inputManager.isActionPressed(GameAction.moveBackward)) {
      gameState.flightPitchAngle -= pitchRate * dt;
      if (gameState.flightPitchAngle < -maxPitch) {
        gameState.flightPitchAngle = -maxPitch;
      }
    }
    // Neither W nor S — auto-level toward 0
    else {
      // Reason: drift pitch toward 0 for stable level flight when keys released
      final levelRate = pitchRate * 0.5 * dt;
      if (gameState.flightPitchAngle > 0) {
        gameState.flightPitchAngle =
            (gameState.flightPitchAngle - levelRate).clamp(0.0, maxPitch);
      } else if (gameState.flightPitchAngle < 0) {
        gameState.flightPitchAngle =
            (gameState.flightPitchAngle + levelRate).clamp(-maxPitch, 0.0);
      }
    }

    // Calculate current speed with modifiers
    double currentSpeed = baseSpeed * sovereignSpeedMult * windWarpSpeedMult;

    // ALT = speed boost
    if (inputManager.isActionPressed(GameAction.sprint)) {
      currentSpeed *= boostMult;
    }

    // Spacebar = air brake + small upward bump
    if (inputManager.isActionPressed(GameAction.jump)) {
      currentSpeed *= brakeMult;
      gameState.playerTransform!.position.y += brakeJump * dt;
    }

    gameState.flightSpeed = currentSpeed;

    // Forward direction in XZ plane
    final fwd = Vector3(
      -math.sin(radians(gameState.playerRotation)),
      0,
      -math.cos(radians(gameState.playerRotation)),
    );

    // Apply constant forward movement (XZ only; Y handled by physics)
    final pitchRad = gameState.flightPitchAngle * (math.pi / 180.0);
    final horizontalSpeed = currentSpeed * math.cos(pitchRad);
    gameState.playerTransform!.position += fwd * horizontalSpeed * dt;

    // ==================== BANKING / BARREL ROLL ====================

    final bankRate = config?.flightBankRate ?? 120.0;
    final maxBankAngle = config?.flightMaxBankAngle ?? 60.0;
    final autoLevelRate = config?.flightAutoLevelRate ?? 90.0;
    final autoLevelThreshold = config?.flightAutoLevelThreshold ?? 90.0;
    final bankToTurnMult = config?.flightBankToTurnMultiplier ?? 2.5;
    final barrelRollRate = config?.flightBarrelRollRate ?? 360.0;

    // Detect key states (Q=strafeLeft, E=strafeRight, A=rotateLeft, D=rotateRight)
    final qHeld = inputManager.isActionPressed(GameAction.strafeLeft);
    final eHeld = inputManager.isActionPressed(GameAction.strafeRight);
    final aHeld = inputManager.isActionPressed(GameAction.rotateLeft);
    final dHeld = inputManager.isActionPressed(GameAction.rotateRight);

    final barrelRollLeft = qHeld && aHeld;
    final barrelRollRight = eHeld && dHeld;

    // Banking / barrel roll logic
    // Reason: positive rotateZ = counter-clockwise from behind = bank LEFT,
    // so Q (bank left) increases angle, E (bank right) decreases angle.
    if (barrelRollLeft) {
      // Continuous left barrel roll — uncapped
      gameState.flightBankAngle -= barrelRollRate * dt;
      if (gameState.flightBankAngle < -360) gameState.flightBankAngle += 360;
    } else if (barrelRollRight) {
      // Continuous right barrel roll — uncapped
      gameState.flightBankAngle += barrelRollRate * dt;
      if (gameState.flightBankAngle > 360) gameState.flightBankAngle -= 360;
    } else if (qHeld) {
      // Bank left
      gameState.flightBankAngle = (gameState.flightBankAngle - bankRate * dt)
          .clamp(-maxBankAngle, maxBankAngle);
    } else if (eHeld) {
      // Bank right
      gameState.flightBankAngle = (gameState.flightBankAngle + bankRate * dt)
          .clamp(-maxBankAngle, maxBankAngle);
    } else {
      // Auto-level: only if |bankAngle| < autoLevelThreshold (90 deg)
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

    // Apply visual roll (rotation.z stores degrees, same as rotation.y for yaw)
    // Reason: rotateZ(positive) tilts the model opposite to the camera's
    // cockpit roll, so we negate to keep model and camera visually consistent.
    gameState.playerTransform!.rotation.z = -gameState.flightBankAngle;

    // ==================== A/D YAW WITH BANK-ENHANCED TURN RATE ====================

    // Reason: during barrel rolls, A/D yaw is suppressed (keys are used for combo)
    if (!barrelRollLeft && !barrelRollRight) {
      final bankAngleRad =
          (gameState.flightBankAngle.abs().clamp(0.0, 90.0)) *
              (math.pi / 180.0);
      final turnMultiplier = 1.0 + math.sin(bankAngleRad) * bankToTurnMult;
      final effectiveTurnRate = 180.0 * turnMultiplier;

      if (aHeld) {
        gameState.playerRotation +=
            effectiveTurnRate * dt;
        gameState.playerTransform!.rotation.y = gameState.playerRotation;
      }
      if (dHeld) {
        gameState.playerRotation -=
            effectiveTurnRate * dt;
        gameState.playerTransform!.rotation.y = gameState.playerRotation;
      }
    }
  }
}
