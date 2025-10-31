import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'dart:ui' as ui;

import '../rendering3d/webgl_renderer.dart';
import '../rendering3d/camera3d.dart';
import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';
import '../rendering3d/terrain_generator.dart';
import '../rendering3d/player_mesh.dart';
import '../game/controllers/input_manager.dart';
import '../models/game_action.dart';

/// Game3D - Main 3D game widget using custom WebGL renderer
///
/// This replaces the Flame-based WarchiefGame with true 3D rendering.
/// Supports dual-axis camera rotation (J/L for yaw, N/M for pitch).
///
/// Usage:
/// ```dart
/// MaterialApp(
///   home: Scaffold(
///     body: Game3D(),
///   ),
/// )
/// ```
class Game3D extends StatefulWidget {
  const Game3D({Key? key}) : super(key: key);

  @override
  State<Game3D> createState() => _Game3DState();
}

class _Game3DState extends State<Game3D> {
  // Canvas element for WebGL
  late html.CanvasElement canvas;
  late String canvasId;

  // Core systems
  WebGLRenderer? renderer;
  Camera3D? camera;
  InputManager? inputManager;

  // Game objects
  List<TerrainTile>? terrainTiles;
  Mesh? playerMesh;
  Transform3d? playerTransform;

  // Game state
  double playerRotation = 0.0;
  double playerSpeed = 5.0;
  int? animationFrameId;
  DateTime? lastFrameTime;
  int frameCount = 0;

  @override
  void initState() {
    super.initState();
    canvasId = 'game3d_canvas_${DateTime.now().millisecondsSinceEpoch}';

    // Initialize input manager
    inputManager = InputManager();

    // Create canvas element immediately
    _initializeGame();
  }

  void _initializeGame() {
    try {
      print('=== Game3D Initialization Starting ===');

      // Create canvas element
      canvas = html.CanvasElement()
        ..id = canvasId
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.zIndex = '-1' // Behind Flutter UI
        ..style.pointerEvents = 'none'; // Let Flutter handle input

      // Append canvas to document body
      html.document.body?.append(canvas);
      print('Canvas created and appended to DOM');

      // Set canvas size
      canvas.width = 1600;
      canvas.height = 900;
      print('Canvas size: ${canvas.width}x${canvas.height}');

      // Initialize renderer
      renderer = WebGLRenderer(canvas);

      // Initialize camera
      camera = Camera3D(
        position: Vector3(0, 10, 15),
        rotation: Vector3(-30, 0, 0), // Look down at 30 degrees
        aspectRatio: canvas.width! / canvas.height!,
      );

      // Set camera to orbit around origin
      camera!.setTarget(Vector3(0, 0, 0));
      camera!.setTargetDistance(15);

      // Initialize terrain
      terrainTiles = TerrainGenerator.createTileGrid(
        width: 20,
        height: 20,
        tileSize: 1.0,
      );

      // Initialize player
      playerMesh = PlayerMesh.createSimpleCharacter();
      playerTransform = Transform3d(
        position: Vector3(0, 0.5, 0), // Slightly above ground
        scale: Vector3(1, 1, 1),
      );

      print('Game3D initialized successfully!');

      // Start game loop
      _startGameLoop();
    } catch (e, stackTrace) {
      print('Error initializing Game3D: $e');
      print(stackTrace);
    }
  }

  void _startGameLoop() {
    lastFrameTime = DateTime.now();
    print('Starting game loop...');

    void gameLoop(num timestamp) {
      if (!mounted) return;

      final now = DateTime.now();
      final dt = lastFrameTime != null
          ? (now.millisecondsSinceEpoch - lastFrameTime!.millisecondsSinceEpoch) / 1000.0
          : 0.016; // Default to ~60fps
      lastFrameTime = now;

      frameCount++;

      // Log every 60 frames (~1 second at 60fps)
      if (frameCount % 60 == 0) {
        print('Frame $frameCount - dt: ${dt.toStringAsFixed(4)}s - Terrain: ${terrainTiles?.length ?? 0} tiles');
      }

      _update(dt);
      _render();

      animationFrameId = html.window.requestAnimationFrame(gameLoop);
    }

    animationFrameId = html.window.requestAnimationFrame(gameLoop);
    print('Game loop started - animationFrameId: $animationFrameId');
  }

  void _update(double dt) {
    if (inputManager == null || camera == null || playerTransform == null) return;

    inputManager!.update(dt);

    // Camera controls
    if (inputManager!.isActionPressed(GameAction.cameraRotateLeft)) {
      camera!.yawBy(-90 * dt); // J key - yaw left
    }
    if (inputManager!.isActionPressed(GameAction.cameraRotateRight)) {
      camera!.yawBy(90 * dt); // L key - yaw right
    }
    if (inputManager!.isActionPressed(GameAction.cameraPitchUp)) {
      camera!.pitchBy(45 * dt); // N key - pitch up
    }
    if (inputManager!.isActionPressed(GameAction.cameraPitchDown)) {
      camera!.pitchBy(-45 * dt); // M key - pitch down
    }
    if (inputManager!.isActionPressed(GameAction.cameraZoomIn)) {
      camera!.zoom(-5 * dt); // I key - zoom in
    }
    if (inputManager!.isActionPressed(GameAction.cameraZoomOut)) {
      camera!.zoom(5 * dt); // K key - zoom out
    }

    // Player movement controls
    if (inputManager!.isActionPressed(GameAction.moveForward)) {
      // Move forward in player's facing direction
      final forward = Vector3(
        -Math.sin(radians(playerRotation)),
        0,
        -Math.cos(radians(playerRotation)),
      );
      playerTransform!.position += forward * playerSpeed * dt;
    }

    if (inputManager!.isActionPressed(GameAction.moveBackward)) {
      // Move backward
      final forward = Vector3(
        -Math.sin(radians(playerRotation)),
        0,
        -Math.cos(radians(playerRotation)),
      );
      playerTransform!.position -= forward * playerSpeed * dt;
    }

    if (inputManager!.isActionPressed(GameAction.rotateLeft)) {
      playerRotation -= 180 * dt; // A key - rotate left
      playerTransform!.rotation.y = playerRotation;
    }

    if (inputManager!.isActionPressed(GameAction.rotateRight)) {
      playerRotation += 180 * dt; // D key - rotate right
      playerTransform!.rotation.y = playerRotation;
    }

    if (inputManager!.isActionPressed(GameAction.strafeLeft)) {
      // Strafe left (perpendicular to facing direction)
      final right = Vector3(
        Math.cos(radians(playerRotation)),
        0,
        -Math.sin(radians(playerRotation)),
      );
      playerTransform!.position -= right * playerSpeed * dt;
    }

    if (inputManager!.isActionPressed(GameAction.strafeRight)) {
      // Strafe right
      final right = Vector3(
        Math.cos(radians(playerRotation)),
        0,
        -Math.sin(radians(playerRotation)),
      );
      playerTransform!.position += right * playerSpeed * dt;
    }

    // Update camera to follow player
    camera!.setTarget(playerTransform!.position);
  }

  void _render() {
    if (renderer == null || camera == null) {
      print('Render skipped - renderer: ${renderer != null}, camera: ${camera != null}');
      return;
    }

    // Clear screen
    renderer!.clear();

    // Render terrain tiles
    if (terrainTiles != null) {
      for (final tile in terrainTiles!) {
        renderer!.render(tile.mesh, tile.transform, camera!);
      }
    }

    // Render player
    if (playerMesh != null && playerTransform != null) {
      renderer!.render(playerMesh!, playerTransform!, camera!);
    }
  }

  void _onKeyEvent(KeyEvent event) {
    if (inputManager != null) {
      inputManager!.handleKeyEvent(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        _onKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Container(
        color: Colors.transparent, // Transparent to show canvas behind
        child: Stack(
          children: [
            // Canvas will be created and appended to body in initState
            SizedBox.expand(),

            // Instructions overlay
            Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Camera: J/L=Yaw | N/M=Pitch | I/K=Zoom',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Movement: W/S=Forward/Back | A/D=Rotate | Q/E=Strafe',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pitch: ${camera?.pitch.toStringAsFixed(1) ?? "0"}° | '
                    'Yaw: ${camera?.yaw.toStringAsFixed(1) ?? "0"}°',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Stop game loop
    if (animationFrameId != null) {
      html.window.cancelAnimationFrame(animationFrameId!);
    }

    // Cleanup renderer
    renderer?.dispose();

    // Remove canvas from DOM
    canvas.remove();

    super.dispose();
  }
}

class Math {
  static double sin(double radians) => math.sin(radians);
  static double cos(double radians) => math.cos(radians);
}
