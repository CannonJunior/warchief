import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/wind_state.dart';
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
}
