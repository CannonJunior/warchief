import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controllers/input_manager.dart';
import 'controllers/camera_controller.dart';
import 'components/player_character.dart';
import 'world/isometric_map.dart';
import '../models/game_action.dart';

/// Main Warchief game class
///
/// This is the core game engine that manages all game components,
/// handles input, and orchestrates the game loop.
class WarchiefGame extends FlameGame
    with KeyboardEvents, ScrollDetector, SecondaryTapCallbacks, MouseMovementDetector {
  /// Input manager for handling keyboard input
  late final InputManager inputManager;

  /// Camera controller for managing camera movement and rotation
  late final CameraController cameraController;

  /// Player character
  late final PlayerCharacter player;

  /// Isometric map
  late final IsometricMap map;

  /// Track if right mouse button is being used for camera drag
  bool isRightMouseDragging = false;

  WarchiefGame() : super(
    camera: CameraComponent.withFixedResolution(width: 1600, height: 900),
  );

  @override
  Color backgroundColor() => const Color(0xFF1a1a1a);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    debugMode = true; // Enable debug mode for development

    // Initialize input manager
    inputManager = InputManager();

    // Initialize camera controller with world reference for dual-axis rotation
    cameraController = CameraController(camera: camera, world: world);

    // Create isometric map
    map = IsometricMap(
      width: 20,
      height: 20,
      tileWidth: 64,
      tileHeight: 32,
    );
    world.add(map);

    // Create player character at center of map
    final mapCenter = Vector2(
      (map.width / 2) * map.tileWidth / 2,
      (map.height / 2) * map.tileHeight / 2,
    );
    player = PlayerCharacter(
      inputManager: inputManager,
      initialPosition: mapCenter,
    );
    world.add(player);

    // Set camera to follow player
    cameraController.setTarget(player);

    // Add FPS counter for development
    camera.viewport.add(
      FpsTextComponent(
        position: Vector2(10, 10),
        anchor: Anchor.topLeft,
      ),
    );

    // Add instructions overlay
    camera.viewport.add(
      TextComponent(
        text: 'W/S: Move Forward/Back | A/D: Rotate | Q/E: Strafe | Space: Jump\nCamera: J/L=Rotate | I/K=Zoom | U/O=Pan Left/Right | N/M=Pitch | Right-Click+Drag',
        position: Vector2(10, 50),
        anchor: Anchor.topLeft,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );

    debugPrint('Warchief game loaded successfully!');
    debugPrint('Player position: ${player.position}');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update input manager (for continuous key press handling)
    inputManager.update(dt);

    // Handle camera controls with keyboard
    if (inputManager.isActionPressed(GameAction.cameraRotateLeft)) {
      cameraController.rotateLeft(dt);
    }
    if (inputManager.isActionPressed(GameAction.cameraRotateRight)) {
      cameraController.rotateRight(dt);
    }
    if (inputManager.isActionPressed(GameAction.cameraZoomIn)) {
      cameraController.zoomIn(dt);
    }
    if (inputManager.isActionPressed(GameAction.cameraZoomOut)) {
      cameraController.zoomOut(dt);
    }
    if (inputManager.isActionPressed(GameAction.cameraPanLeft)) {
      cameraController.panLeft(dt);
    }
    if (inputManager.isActionPressed(GameAction.cameraPanRight)) {
      cameraController.panRight(dt);
    }
    if (inputManager.isActionPressed(GameAction.cameraPitchUp)) {
      cameraController.pitchUp(dt);
    }
    if (inputManager.isActionPressed(GameAction.cameraPitchDown)) {
      cameraController.pitchDown(dt);
    }

    // Update camera controller
    cameraController.update(dt);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Delegate to input manager
    return inputManager.handleKeyEvent(event);
  }

  @override
  void onScroll(PointerScrollInfo info) {
    super.onScroll(info);

    // Handle camera zoom
    cameraController.handleScroll(info.scrollDelta.global.y);
  }

  @override
  void onSecondaryTapDown(SecondaryTapDownEvent event) {
    super.onSecondaryTapDown(event);

    // Secondary tap = right-click
    isRightMouseDragging = true;
    cameraController.startRotation(event.localPosition);
    debugPrint('Right mouse button detected - camera rotation started at ${event.localPosition}');
  }

  @override
  void onSecondaryTapUp(SecondaryTapUpEvent event) {
    super.onSecondaryTapUp(event);

    if (isRightMouseDragging) {
      isRightMouseDragging = false;
      cameraController.stopRotation();
      debugPrint('Right mouse button released - camera rotation ended');
    }
  }

  @override
  void onSecondaryTapCancel(SecondaryTapCancelEvent event) {
    super.onSecondaryTapCancel(event);

    if (isRightMouseDragging) {
      isRightMouseDragging = false;
      cameraController.stopRotation();
      debugPrint('Secondary tap cancelled - camera rotation ended');
    }
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);

    // If right mouse button is pressed, update camera rotation
    if (isRightMouseDragging) {
      cameraController.updateRotation(info.eventPosition.widget);
    }
  }
}
