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
import '../ai/ollama_client.dart';
import '../models/projectile.dart';
import '../models/impact_effect.dart';
import '../models/ally.dart';
import '../models/ai_chat_message.dart';
import 'state/game_config.dart';
import 'state/game_state.dart';
import 'systems/physics_system.dart';
import 'systems/ability_system.dart';

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
  OllamaClient? ollamaClient;

  // Game state - centralized state management
  final GameState gameState = GameState();

  @override
  void initState() {
    super.initState();
    canvasId = 'game3d_canvas_${DateTime.now().millisecondsSinceEpoch}';

    // Initialize input manager
    inputManager = InputManager();

    // Initialize Ollama client for AI
    ollamaClient = OllamaClient();

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
        rotation: Vector3(30, 0, 0), // Start at 30 degrees
        aspectRatio: canvas.width! / canvas.height!,
      );

      // Set camera to orbit around origin
      camera!.setTarget(Vector3(0, 0, 0));
      camera!.setTargetDistance(15);

      // Initialize terrain
      gameState.terrainTiles = TerrainGenerator.createTileGrid(
        width: GameConfig.terrainGridSize,
        height: GameConfig.terrainGridSize,
        tileSize: GameConfig.terrainTileSize,
      );

      // Initialize player
      gameState.playerMesh = PlayerMesh.createSimpleCharacter();
      gameState.playerTransform = Transform3d(
        position: GameConfig.playerStartPosition,
        scale: Vector3(1, 1, 1),
      );

      // Initialize direction indicator (red triangle on top of player)
      gameState.directionIndicator = Mesh.triangle(
        size: GameConfig.playerDirectionIndicatorSize,
        color: Vector3(1.0, 0.0, 0.0), // Red color
      );
      gameState.directionIndicatorTransform = Transform3d(
        position: Vector3(0, 1.2, 0), // On top of player cube
        scale: Vector3(1, 1, 1),
      );

      // Initialize shadow (dark semi-transparent plane under player)
      gameState.shadowMesh = Mesh.plane(
        width: 1.0,
        height: 1.0,
        color: Vector3(0.0, 0.0, 0.0), // Black shadow
      );
      gameState.shadowTransform = Transform3d(
        position: Vector3(0, 0.01, 0), // Slightly above ground to avoid z-fighting
        scale: Vector3(1, 1, 1),
      );

      // Initialize sword mesh (gray metallic plane for sword swing)
      gameState.swordMesh = Mesh.plane(
        width: 0.3,
        height: 1.5,
        color: Vector3(0.7, 0.7, 0.8), // Gray metallic color
      );
      gameState.swordTransform = Transform3d(
        position: Vector3(0, 0, 0), // Will be positioned in front of player when active
        scale: Vector3(1, 1, 1),
      );

      // Initialize heal effect mesh (green/yellow glow around player)
      gameState.healEffectMesh = Mesh.cube(
        size: 1.5,
        color: Vector3(0.5, 1.0, 0.3), // Green/yellow healing color
      );
      gameState.healEffectTransform = Transform3d(
        position: Vector3(0, 0, 0), // Will match player position when active
        scale: Vector3(1, 1, 1),
      );

      // Initialize monster (purple enemy at opposite end of terrain)
      gameState.monsterMesh = Mesh.cube(
        size: GameConfig.monsterSize,
        color: Vector3(0.6, 0.2, 0.8), // Purple color
      );
      gameState.monsterTransform = Transform3d(
        position: GameConfig.monsterStartPosition,
        rotation: Vector3(0, gameState.monsterRotation, 0),
        scale: Vector3(1, 1, 1),
      );

      // Initialize monster direction indicator (green triangle on top of monster)
      gameState.monsterDirectionIndicator = Mesh.triangle(
        size: GameConfig.monsterDirectionIndicatorSize,
        color: Vector3(0.0, 1.0, 0.0), // Green color
      );
      gameState.monsterDirectionIndicatorTransform = Transform3d(
        position: Vector3(GameConfig.monsterStartPosition.x, GameConfig.monsterStartPosition.y + 0.7, GameConfig.monsterStartPosition.z),
        rotation: Vector3(0, gameState.monsterRotation + 180, 0),
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
    gameState.lastFrameTime = DateTime.now();
    print('Starting game loop...');

    void gameLoop(num timestamp) {
      if (!mounted) return;

      final now = DateTime.now();
      final dt = gameState.lastFrameTime != null
          ? (now.millisecondsSinceEpoch - gameState.lastFrameTime!.millisecondsSinceEpoch) / 1000.0
          : 0.016; // Default to ~60fps
      gameState.lastFrameTime = now;

      gameState.frameCount++;

      // Log every 60 frames (~1 second at 60fps)
      if (gameState.frameCount % 60 == 0) {
        print('Frame ${gameState.frameCount} - dt: ${dt.toStringAsFixed(4)}s - Terrain: ${gameState.terrainTiles?.length ?? 0} tiles');
      }

      _update(dt);
      _render();

      // Update UI every 10 frames to show camera changes
      if (gameState.frameCount % 10 == 0 && mounted) {
        setState(() {});
      }

      gameState.animationFrameId = html.window.requestAnimationFrame(gameLoop);
    }

    gameState.animationFrameId = html.window.requestAnimationFrame(gameLoop);
    print('Game loop started - animationFrameId: ${gameState.animationFrameId}');
  }

  void _update(double dt) {
    if (inputManager == null || camera == null || gameState.playerTransform == null) return;

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
    // W = Forward
    if (inputManager!.isActionPressed(GameAction.moveForward)) {
      // Move forward in player's facing direction
      final forward = Vector3(
        -Math.sin(radians(gameState.playerRotation)),
        0,
        -Math.cos(radians(gameState.playerRotation)),
      );
      gameState.playerTransform!.position += forward * gameState.playerSpeed * dt;
    }

    // S = Backward
    if (inputManager!.isActionPressed(GameAction.moveBackward)) {
      // Move backward
      final forward = Vector3(
        -Math.sin(radians(gameState.playerRotation)),
        0,
        -Math.cos(radians(gameState.playerRotation)),
      );
      gameState.playerTransform!.position -= forward * gameState.playerSpeed * dt;
    }

    // A = Rotate Right
    if (inputManager!.isActionPressed(GameAction.rotateLeft)) {
      gameState.playerRotation += 180 * dt; // A key - rotate right
      gameState.playerTransform!.rotation.y = gameState.playerRotation;
    }

    // D = Rotate Left
    if (inputManager!.isActionPressed(GameAction.rotateRight)) {
      gameState.playerRotation -= 180 * dt; // D key - rotate left
      gameState.playerTransform!.rotation.y = gameState.playerRotation;
    }

    // Q = Strafe Left
    if (inputManager!.isActionPressed(GameAction.strafeLeft)) {
      // Strafe left (perpendicular to facing direction)
      final right = Vector3(
        Math.cos(radians(gameState.playerRotation)),
        0,
        -Math.sin(radians(gameState.playerRotation)),
      );
      gameState.playerTransform!.position -= right * gameState.playerSpeed * dt;
    }

    // E = Strafe Right
    if (inputManager!.isActionPressed(GameAction.strafeRight)) {
      // Strafe right
      final right = Vector3(
        Math.cos(radians(gameState.playerRotation)),
        0,
        -Math.sin(radians(gameState.playerRotation)),
      );
      gameState.playerTransform!.position += right * gameState.playerSpeed * dt;
    }

    // Handle jump input
    final jumpKeyIsPressed = inputManager!.isActionPressed(GameAction.jump);
    PhysicsSystem.handleJumpInput(jumpKeyIsPressed, gameState);

    // Update physics (gravity, vertical movement, ground collision)
    PhysicsSystem.update(dt, gameState);

    // ===== ABILITY SYSTEM =====
    // Update player ability cooldowns and effects
    AbilitySystem.update(dt, gameState);

    // Update monster ability cooldowns
    if (gameState.monsterAbility1Cooldown > 0) gameState.monsterAbility1Cooldown -= dt;
    if (gameState.monsterAbility2Cooldown > 0) gameState.monsterAbility2Cooldown -= dt;
    if (gameState.monsterAbility3Cooldown > 0) gameState.monsterAbility3Cooldown -= dt;

    // Update ally cooldowns
    for (final ally in gameState.allies) {
      if (ally.abilityCooldown > 0) ally.abilityCooldown -= dt;
    }

    // ===== MONSTER AI SYSTEM =====
    if (!gameState.monsterPaused && gameState.monsterHealth > 0 && gameState.monsterTransform != null && gameState.playerTransform != null) {
      gameState.monsterAiTimer += dt;

      // AI thinks every 2 seconds
      if (gameState.monsterAiTimer >= gameState.monsterAiInterval) {
        gameState.monsterAiTimer = 0.0;

        // Calculate distance to player
        final distanceToPlayer = (gameState.monsterTransform!.position - gameState.playerTransform!.position).length;

        // Log AI input (game state)
        _logMonsterAI('Health: ${gameState.monsterHealth.toStringAsFixed(0)} | Dist: ${distanceToPlayer.toStringAsFixed(1)}', isInput: true);

        // Always face the player
        final toPlayer = gameState.playerTransform!.position - gameState.monsterTransform!.position;
        gameState.monsterRotation = math.atan2(-toPlayer.x, -toPlayer.z) * (180 / math.pi);
        gameState.monsterDirectionIndicatorTransform?.rotation.y = gameState.monsterRotation;

        // Decision making
        String decision = '';
        if (distanceToPlayer > 8.0) {
          // Move toward player if too far
          final moveDirection = toPlayer.normalized();
          gameState.monsterTransform!.position += moveDirection * 0.5;
          decision = 'MOVE_FORWARD';
        } else if (distanceToPlayer < 3.0) {
          // Move away if too close
          final moveDirection = toPlayer.normalized();
          gameState.monsterTransform!.position -= moveDirection * 0.3;
          decision = 'RETREAT';
        } else {
          decision = 'HOLD';
        }

        // Use abilities based on distance and cooldown
        if (distanceToPlayer < 5.0 && gameState.monsterAbility1Cooldown <= 0) {
          _activateMonsterAbility1(); // Dark strike
          decision += ' + DARK_STRIKE';
        } else if (distanceToPlayer > 4.0 && distanceToPlayer < 12.0 && gameState.monsterAbility2Cooldown <= 0) {
          _activateMonsterAbility2(); // Shadow bolt
          decision += ' + SHADOW_BOLT';
        } else if (gameState.monsterHealth < 50 && gameState.monsterAbility3Cooldown <= 0) {
          _activateMonsterAbility3(); // Healing
          decision += ' + HEAL';
        }

        // Log AI output (decision)
        _logMonsterAI(decision, isInput: false);
      }
    }

    // ===== ALLY AI SYSTEM =====
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue; // Skip dead allies

      ally.aiTimer += dt;

      // AI thinks every 3 seconds
      if (ally.aiTimer >= ally.aiInterval) {
        ally.aiTimer = 0.0;

        if (gameState.playerTransform != null && gameState.monsterTransform != null) {
          // Calculate distances
          final distanceToPlayer = (ally.transform.position - gameState.playerTransform!.position).length;
          final distanceToMonster = (ally.transform.position - gameState.monsterTransform!.position).length;

          // Fallback rule-based AI (when Ollama unavailable)
          String decision = _makeAllyDecision(ally, distanceToPlayer, distanceToMonster);

          // Execute decision
          _executeAllyDecision(ally, decision);
        }
      }

      // Update ally's direction indicator to face monster
      if (ally.directionIndicatorTransform != null && gameState.monsterTransform != null) {
        final toMonster = gameState.monsterTransform!.position - ally.transform.position;
        ally.rotation = math.atan2(-toMonster.x, -toMonster.z) * (180 / math.pi);
        ally.directionIndicatorTransform!.rotation.y = ally.rotation;
      }

      // Update ally's projectiles
      ally.projectiles.removeWhere((projectile) {
        projectile.transform.position += projectile.velocity * dt;
        projectile.lifetime -= dt;

        // Check collision with monster using generalized function
        if (gameState.monsterTransform != null) {
          final hitRegistered = _checkAndHandleCollision(
            attackerPosition: projectile.transform.position,
            targetPosition: gameState.monsterTransform!.position,
            collisionThreshold: 1.0,
            damage: 15.0, // Ally fireball does 15 damage
            attackType: 'Ally fireball',
            impactColor: Vector3(1.0, 0.4, 0.0), // Orange impact
            impactSize: 0.6,
          );
          if (hitRegistered) return true;
        }

        return projectile.lifetime <= 0;
      });
    }

    // Update monster projectiles
    gameState.monsterProjectiles.removeWhere((projectile) {
      projectile.transform.position += projectile.velocity * dt;
      projectile.lifetime -= dt;

      // Check collision with player
      if (gameState.playerTransform != null) {
        final distance = (projectile.transform.position - gameState.playerTransform!.position).length;
        if (distance < 1.0) {
          // Hit player - create impact
          final impactMesh = Mesh.cube(
            size: 0.8,
            color: Vector3(0.5, 0.0, 0.5), // Purple impact
          );
          final impactTransform = Transform3d(
            position: projectile.transform.position.clone(),
            scale: Vector3(1, 1, 1),
          );
          gameState.impactEffects.add(ImpactEffect(
            mesh: impactMesh,
            transform: impactTransform,
          ));
          print('Monster hit player! (implement player damage later)');
          return true;
        }
      }

      return projectile.lifetime <= 0;
    });

    // Handle player ability input
    AbilitySystem.handleAbility1Input(inputManager!.isActionPressed(GameAction.actionBar1), gameState);
    AbilitySystem.handleAbility2Input(inputManager!.isActionPressed(GameAction.actionBar2), gameState);
    AbilitySystem.handleAbility3Input(inputManager!.isActionPressed(GameAction.actionBar3), gameState);
    // ===== END ABILITY SYSTEM =====

    // Update direction indicator position and rotation to match player
    if (gameState.directionIndicatorTransform != null && gameState.playerTransform != null) {
      gameState.directionIndicatorTransform!.position.x = gameState.playerTransform!.position.x;
      gameState.directionIndicatorTransform!.position.y = gameState.playerTransform!.position.y + 0.5; // Flush with top of cube
      gameState.directionIndicatorTransform!.position.z = gameState.playerTransform!.position.z;
      gameState.directionIndicatorTransform!.rotation.y = gameState.playerRotation + 180; // Rotate 180 degrees
    }

    // Update shadow position, rotation, and scale based on player height and light direction
    if (gameState.shadowTransform != null && gameState.playerTransform != null) {
      // Light direction (from upper-right-front) - normalized direction from where light is coming
      final lightDirX = 0.5; // Light from right
      final lightDirZ = 0.3; // Light from front

      // Calculate shadow offset based on player height (higher = further from player)
      final playerHeight = PhysicsSystem.getPlayerHeight(gameState);
      final shadowOffsetX = playerHeight * lightDirX;
      final shadowOffsetZ = playerHeight * lightDirZ;

      // Position shadow with offset from player
      gameState.shadowTransform!.position.x = gameState.playerTransform!.position.x + shadowOffsetX;
      gameState.shadowTransform!.position.z = gameState.playerTransform!.position.z + shadowOffsetZ;

      // Rotate shadow to match player rotation
      gameState.shadowTransform!.rotation.y = gameState.playerRotation;

      // Shadow gets larger the higher the player is (scale factor includes base size adjustment)
      final scaleFactor = 1.0 + playerHeight * 0.15;
      gameState.shadowTransform!.scale = Vector3(scaleFactor, 1, scaleFactor);
    }

    // Update camera to follow player (with smoothing to avoid "terrain moving" effect)
    // Only update camera target if player moves significantly from center
    final currentTarget = camera!.getTarget();
    final distanceFromTarget = (gameState.playerTransform!.position - currentTarget).length;

    // Update camera target smoothly when player moves away from center
    if (distanceFromTarget > 0.1) {
      // Smoothly interpolate camera target toward player position
      final newTarget = currentTarget + (gameState.playerTransform!.position - currentTarget) * 0.05;
      camera!.setTarget(newTarget);
    }
  }

  void _render() {
    if (renderer == null || camera == null) {
      print('Render skipped - renderer: ${renderer != null}, camera: ${camera != null}');
      return;
    }

    // Clear screen
    renderer!.clear();

    // Render terrain tiles
    if (gameState.terrainTiles != null) {
      for (final tile in gameState.terrainTiles!) {
        renderer!.render(tile.mesh, tile.transform, camera!);
      }
    }

    // Render shadow (before player so it appears underneath)
    if (gameState.shadowMesh != null && gameState.shadowTransform != null) {
      renderer!.render(gameState.shadowMesh!, gameState.shadowTransform!, camera!);
    }

    // Render player
    if (gameState.playerMesh != null && gameState.playerTransform != null) {
      renderer!.render(gameState.playerMesh!, gameState.playerTransform!, camera!);
    }

    // Render direction indicator
    if (gameState.directionIndicator != null && gameState.directionIndicatorTransform != null) {
      renderer!.render(gameState.directionIndicator!, gameState.directionIndicatorTransform!, camera!);
    }

    // Render monster
    if (gameState.monsterMesh != null && gameState.monsterTransform != null) {
      renderer!.render(gameState.monsterMesh!, gameState.monsterTransform!, camera!);
    }

    // Render monster direction indicator
    if (gameState.monsterDirectionIndicator != null && gameState.monsterDirectionIndicatorTransform != null) {
      renderer!.render(gameState.monsterDirectionIndicator!, gameState.monsterDirectionIndicatorTransform!, camera!);
    }

    // Render allies
    for (final ally in gameState.allies) {
      // Render ally mesh
      renderer!.render(ally.mesh, ally.transform, camera!);

      // Render ally projectiles
      for (final projectile in ally.projectiles) {
        renderer!.render(projectile.mesh, projectile.transform, camera!);
      }
    }

    // Render ability effects
    // Render sword attack
    if (gameState.ability1Active && gameState.swordMesh != null && gameState.swordTransform != null) {
      renderer!.render(gameState.swordMesh!, gameState.swordTransform!, camera!);
    }

    // Render fireballs
    for (final fireball in gameState.fireballs) {
      renderer!.render(fireball.mesh, fireball.transform, camera!);
    }

    // Render monster projectiles
    for (final projectile in gameState.monsterProjectiles) {
      renderer!.render(projectile.mesh, projectile.transform, camera!);
    }

    // Render impact effects
    for (final impact in gameState.impactEffects) {
      renderer!.render(impact.mesh, impact.transform, camera!);
    }

    // Render heal effect
    if (gameState.ability3Active && gameState.healEffectMesh != null && gameState.healEffectTransform != null) {
      renderer!.render(gameState.healEffectMesh!, gameState.healEffectTransform!, camera!);
    }
  }

  void _onKeyEvent(KeyEvent event) {
    if (inputManager != null) {
      inputManager!.handleKeyEvent(event);
    }
  }

  // Ability activation methods (for clickable buttons)
  void _activateAbility1() {
    setState(() {
      AbilitySystem.handleAbility1Input(true, gameState);
    });
  }

  void _activateAbility2() {
    setState(() {
      AbilitySystem.handleAbility2Input(true, gameState);
    });
  }

  void _activateAbility3() {
    setState(() {
      AbilitySystem.handleAbility3Input(true, gameState);
    });
  }

  // ===== MONSTER ABILITY METHODS =====

  /// Activate Monster Ability 1: Dark Strike (melee attack)
  void _activateMonsterAbility1() {
    if (gameState.monsterAbility1Cooldown > 0 || gameState.monsterHealth <= 0) return;

    setState(() {
      gameState.monsterAbility1Cooldown = gameState.monsterAbility1CooldownMax;
    });
    print('Monster uses Dark Strike! (melee attack)');
  }

  /// Activate Monster Ability 2: Shadow Bolt (ranged projectile)
  void _activateMonsterAbility2() {
    if (gameState.monsterAbility2Cooldown > 0 || gameState.monsterHealth <= 0) return;
    if (gameState.monsterTransform == null || gameState.playerTransform == null) return;

    // Create shadow bolt projectile aimed at player
    final direction = (gameState.playerTransform!.position - gameState.monsterTransform!.position).normalized();
    final projectileMesh = Mesh.cube(
      size: 0.5,
      color: Vector3(0.5, 0.0, 0.5), // Purple
    );
    final projectileTransform = Transform3d(
      position: gameState.monsterTransform!.position.clone() + Vector3(0, 1, 0),
      scale: Vector3(1, 1, 1),
    );

    setState(() {
      gameState.monsterProjectiles.add(Projectile(
        mesh: projectileMesh,
        transform: projectileTransform,
        velocity: direction * 8.0,
        lifetime: 5.0,
      ));
      gameState.monsterAbility2Cooldown = gameState.monsterAbility2CooldownMax;
    });
    print('Monster casts Shadow Bolt! (projectile)');
  }

  /// Activate Monster Ability 3: Dark Healing (restore health)
  void _activateMonsterAbility3() {
    if (gameState.monsterAbility3Cooldown > 0 || gameState.monsterHealth <= 0) return;

    setState(() {
      // Heal for 20-30 HP
      gameState.monsterHealth = math.min(gameState.monsterMaxHealth.toDouble(), gameState.monsterHealth + 25);
      gameState.monsterAbility3Cooldown = gameState.monsterAbility3CooldownMax;
    });
    print('Monster heals itself! Health: ${gameState.monsterHealth}/${gameState.monsterMaxHealth}');
  }

  // ===== AI CHAT LOGGING =====

  /// Add a message to the Monster AI chat log
  void _logMonsterAI(String text, {required bool isInput}) {
    setState(() {
      gameState.monsterAIChat.add(AIChatMessage(
        text: text,
        isInput: isInput,
      ));

      // Keep only last 50 messages to avoid memory issues
      if (gameState.monsterAIChat.length > 50) {
        gameState.monsterAIChat.removeAt(0);
      }
    });
  }

  // ===== COLLISION DETECTION HELPER =====

  /// Generalized collision detection with damage and impact effects
  ///
  /// Returns true if collision occurred
  bool _checkAndHandleCollision({
    required Vector3 attackerPosition,
    required Vector3 targetPosition,
    required double collisionThreshold,
    required double damage,
    required String attackType,
    required Vector3 impactColor,
    double impactSize = 0.6,
  }) {
    final distance = (attackerPosition - targetPosition).length;

    if (distance < collisionThreshold && gameState.monsterHealth > 0) {
      // Create impact effect
      final impactMesh = Mesh.cube(
        size: impactSize,
        color: impactColor,
      );
      final impactTransform = Transform3d(
        position: targetPosition.clone(),
        scale: Vector3(1, 1, 1),
      );

      setState(() {
        gameState.impactEffects.add(ImpactEffect(
          mesh: impactMesh,
          transform: impactTransform,
        ));

        // Deal damage to monster
        gameState.monsterHealth = (gameState.monsterHealth - damage).clamp(0.0, gameState.monsterMaxHealth);
      });

      print('$attackType hit monster for $damage damage! Monster health: ${gameState.monsterHealth.toStringAsFixed(1)}');
      return true;
    }

    return false;
  }

  // ===== ALLY AI HELPER METHODS =====

  /// Make AI decision for an ally (fallback rule-based AI)
  String _makeAllyDecision(Ally ally, double distanceToPlayer, double distanceToMonster) {
    // Too far from player - move to player
    if (distanceToPlayer > 8.0) {
      return 'MOVE_TO_PLAYER';
    }

    // Too close to monster - retreat
    if (distanceToMonster < 3.0) {
      return 'RETREAT';
    }

    // Use ability if ready and monster in range
    if (ally.abilityCooldown <= 0 && distanceToMonster < 10.0) {
      return 'USE_ABILITY';
    }

    // Move toward monster if in good position
    if (distanceToMonster > 6.0) {
      return 'MOVE_TO_MONSTER';
    }

    return 'HOLD_POSITION';
  }

  /// Execute ally's AI decision
  void _executeAllyDecision(Ally ally, String decision) {
    if (decision == 'MOVE_TO_PLAYER' && gameState.playerTransform != null) {
      // Move toward player
      final direction = (gameState.playerTransform!.position - ally.transform.position).normalized();
      ally.transform.position += direction * 0.5;
    } else if (decision == 'MOVE_TO_MONSTER' && gameState.monsterTransform != null) {
      // Move toward monster
      final direction = (gameState.monsterTransform!.position - ally.transform.position).normalized();
      ally.transform.position += direction * 0.5;
    } else if (decision == 'RETREAT' && gameState.monsterTransform != null) {
      // Move away from monster
      final direction = (gameState.monsterTransform!.position - ally.transform.position).normalized();
      ally.transform.position -= direction * 0.3;
    } else if (decision == 'USE_ABILITY') {
      // Use ally's ability based on their abilityIndex
      if (ally.abilityIndex == 0) {
        // Ability 0: Sword (melee attack with collision detection against all entities)
        bool hitRegistered = false;

        // Check collision with monster
        if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
          final distance = (ally.transform.position - gameState.monsterTransform!.position).length;
          if (distance <= 2.0) {
            hitRegistered = _checkAndHandleCollision(
              attackerPosition: ally.transform.position,
              targetPosition: gameState.monsterTransform!.position,
              collisionThreshold: 2.0,
              damage: 10.0,
              attackType: 'Ally sword',
              impactColor: Vector3(0.7, 0.7, 0.8),
              impactSize: 0.5,
            );
            if (hitRegistered) {
              print('Ally sword hit monster!');
            }
          }
        }

        // Check collision with player (if not already hit something)
        if (!hitRegistered && gameState.playerTransform != null && gameState.playerHealth > 0) {
          final distance = (ally.transform.position - gameState.playerTransform!.position).length;
          if (distance <= 2.0) {
            final distanceBefore = (ally.transform.position - gameState.playerTransform!.position).length;
            if (distanceBefore <= 2.0) {
              setState(() {
                gameState.playerHealth = math.max(0, gameState.playerHealth - 10.0);

                // Create impact effect
                gameState.impactEffects.add(ImpactEffect(
                  mesh: Mesh.cube(
                    size: 0.5,
                    color: Vector3(0.7, 0.7, 0.8),
                  ),
                  transform: Transform3d(
                    position: gameState.playerTransform!.position.clone() + Vector3(0, 0.5, 0),
                    scale: Vector3(1, 1, 1),
                  ),
                  lifetime: 0.3,
                ));
              });
              hitRegistered = true;
              print('Ally sword hit player! Player health: ${gameState.playerHealth}');
            }
          }
        }

        // Check collision with other allies (if not already hit something)
        if (!hitRegistered) {
          for (final otherAlly in gameState.allies) {
            // Skip the attacker and dead allies
            if (otherAlly == ally || otherAlly.health <= 0) continue;

            final distance = (ally.transform.position - otherAlly.transform.position).length;
            if (distance <= 2.0) {
              setState(() {
                otherAlly.health = math.max(0, otherAlly.health - 10.0);

                // Create impact effect
                gameState.impactEffects.add(ImpactEffect(
                  mesh: Mesh.cube(
                    size: 0.5,
                    color: Vector3(0.7, 0.7, 0.8),
                  ),
                  transform: Transform3d(
                    position: otherAlly.transform.position.clone() + Vector3(0, 0.5, 0),
                    scale: Vector3(1, 1, 1),
                  ),
                  lifetime: 0.3,
                ));
              });
              hitRegistered = true;
              print('Ally sword hit another ally! Ally health: ${otherAlly.health}');
              break; // Only hit one target
            }
          }
        }

        // Always set cooldown, whether hit lands or not
        setState(() {
          ally.abilityCooldown = ally.abilityCooldownMax;
        });

        if (!hitRegistered) {
          print('Ally sword missed - out of range!');
        }
      } else if (ally.abilityIndex == 1 && gameState.monsterTransform != null) {
        // Ability 1: Fireball (ranged projectile)
        final direction = (gameState.monsterTransform!.position - ally.transform.position).normalized();
        final fireballMesh = Mesh.cube(
          size: 0.3,
          color: Vector3(1.0, 0.4, 0.0), // Orange fireball
        );
        final startPos = ally.transform.position.clone() + Vector3(0, 0.4, 0);
        final fireballTransform = Transform3d(
          position: startPos,
          scale: Vector3(1, 1, 1),
        );

        setState(() {
          ally.projectiles.add(Projectile(
            mesh: fireballMesh,
            transform: fireballTransform,
            velocity: direction * 10.0,
            lifetime: 5.0,
          ));
          ally.abilityCooldown = ally.abilityCooldownMax;
        });
        print('Ally casts Fireball!');
      } else if (ally.abilityIndex == 2) {
        // Ability 2: Heal (restore ally's own health)
        setState(() {
          ally.health = math.min(ally.maxHealth, ally.health + 15);
          ally.abilityCooldown = ally.abilityCooldownMax;
        });
        print('Ally heals itself! Health: ${ally.health}/${ally.maxHealth}');
      }
    }
    // HOLD_POSITION - do nothing
  }

  // ===== ALLY MANAGEMENT METHODS =====

  /// Manually activate an ally's ability (called from UI button)
  void _activateAllyAbility(Ally ally) {
    if (ally.abilityCooldown > 0 || ally.health <= 0) {
      print('Ally ability on cooldown or ally is dead');
      return;
    }

    setState(() {
      // Force the ally to use their ability
      _executeAllyDecision(ally, 'USE_ABILITY');
      print('Manually activated ally ability ${ally.abilityIndex}');
    });
  }

  /// Add a new ally with a random ability
  void _addAlly() {
    setState(() {
      // Generate random ability (0, 1, or 2)
      final random = math.Random();
      final randomAbility = random.nextInt(3);

      // Create ally mesh (smaller, brighter blue than player)
      final allyMesh = Mesh.cube(
        size: 0.8, // 0.8x player size
        color: Vector3(0.4, 0.7, 1.0), // Brighter blue than player (0.3, 0.5, 0.8)
      );

      // Position ally near player (offset to avoid overlap)
      final allyCount = gameState.allies.length;
      final angle = (allyCount * 60.0) * (math.pi / 180.0); // Space out in circle
      final offsetX = math.cos(angle) * 2.0;
      final offsetZ = math.sin(angle) * 2.0;

      final allyPosition = gameState.playerTransform != null
          ? Vector3(
              gameState.playerTransform!.position.x + offsetX,
              0.4, // Slightly lower than player (0.5)
              gameState.playerTransform!.position.z + offsetZ,
            )
          : Vector3(2, 0.4, 2); // Default position if no player

      final allyTransform = Transform3d(
        position: allyPosition,
        scale: Vector3(1, 1, 1),
      );

      // Create ally object
      final ally = Ally(
        mesh: allyMesh,
        transform: allyTransform,
        rotation: 0.0,
        abilityIndex: randomAbility,
        health: 50.0,
        maxHealth: 50.0,
        abilityCooldown: 0.0,
        abilityCooldownMax: 5.0,
        aiTimer: 0.0,
      );

      gameState.allies.add(ally);

      final abilityNames = ['Sword', 'Fireball', 'Heal'];
      print('Ally added! Ability: ${abilityNames[randomAbility]} (Total: ${gameState.allies.length})');
    });
  }

  /// Remove the most recently added ally
  void _removeAlly() {
    if (gameState.allies.isEmpty) {
      print('No allies to remove!');
      return;
    }

    setState(() {
      gameState.allies.removeLast();
      print('Ally removed! Remaining: ${gameState.allies.length}');
    });
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
                    'Jump: Spacebar',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Abilities:',
                    style: TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '1: Sword ${gameState.ability1Cooldown > 0 ? "(${gameState.ability1Cooldown.toStringAsFixed(1)}s)" : "READY"}',
                    style: TextStyle(
                      color: gameState.ability1Cooldown > 0 ? Colors.red : Colors.green,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '2: Fireball ${gameState.ability2Cooldown > 0 ? "(${gameState.ability2Cooldown.toStringAsFixed(1)}s)" : "READY"}',
                    style: TextStyle(
                      color: gameState.ability2Cooldown > 0 ? Colors.red : Colors.green,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '3: Heal ${gameState.ability3Cooldown > 0 ? "(${gameState.ability3Cooldown.toStringAsFixed(1)}s)" : "READY"}',
                    style: TextStyle(
                      color: gameState.ability3Cooldown > 0 ? Colors.red : Colors.green,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Camera Angle to Terrain: ${(camera?.pitch.abs() ?? 0).toStringAsFixed(1)}°',
                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Camera Position: '
                    'X: ${camera?.position.x.toStringAsFixed(1) ?? "0"} | '
                    'Y: ${camera?.position.y.toStringAsFixed(1) ?? "0"} | '
                    'Z: ${camera?.position.z.toStringAsFixed(1) ?? "0"}',
                    style: TextStyle(color: Colors.amber, fontSize: 10),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pitch: ${camera?.pitch.toStringAsFixed(1) ?? "0"}° | '
                    'Yaw: ${camera?.yaw.toStringAsFixed(1) ?? "0"}°',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          // HUD - Monster Information (Top-left, below camera controls)
          Positioned(
            top: 360,
            left: 10,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monster label
                  Text(
                    'BOSS MONSTER',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Health bar
                  Container(
                    width: 200,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade600, width: 2),
                    ),
                    child: Stack(
                      children: [
                        // Health fill
                        FractionallySizedBox(
                          widthFactor: (gameState.monsterHealth / gameState.monsterMaxHealth).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: gameState.monsterHealth > 50 ? Colors.green :
                                     gameState.monsterHealth > 25 ? Colors.orange : Colors.red,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Health text
                        Center(
                          child: Text(
                            '${gameState.monsterHealth.toStringAsFixed(0)} / ${gameState.monsterMaxHealth.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  // Ability buttons
                  Row(
                    children: [
                      _buildAbilityButton(
                        label: 'M1',
                        color: Color(0xFF9B59B6), // Purple
                        cooldown: gameState.monsterAbility1Cooldown,
                        maxCooldown: gameState.monsterAbility1CooldownMax,
                        onPressed: _activateMonsterAbility1,
                      ),
                      SizedBox(width: 8),
                      _buildAbilityButton(
                        label: 'M2',
                        color: Color(0xFF8E44AD), // Darker purple
                        cooldown: gameState.monsterAbility2Cooldown,
                        maxCooldown: gameState.monsterAbility2CooldownMax,
                        onPressed: _activateMonsterAbility2,
                      ),
                      SizedBox(width: 8),
                      _buildAbilityButton(
                        label: 'M3',
                        color: Color(0xFF6C3483), // Even darker purple
                        cooldown: gameState.monsterAbility3Cooldown,
                        maxCooldown: gameState.monsterAbility3CooldownMax,
                        onPressed: _activateMonsterAbility3,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Pause button for monster AI
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        gameState.monsterPaused = !gameState.monsterPaused;
                      });
                      print('Monster AI ${gameState.monsterPaused ? 'paused' : 'resumed'}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gameState.monsterPaused ? Colors.green : Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      gameState.monsterPaused ? 'Resume Monster' : 'Pause Monster',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // HUD - AI Chat Interface (Below Monster)
          Positioned(
            top: 640,
            left: 10,
            child: Container(
              width: 300,
              height: 200,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MONSTER AI CHAT',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        reverse: true, // Latest messages at bottom
                        itemCount: gameState.monsterAIChat.length,
                        itemBuilder: (context, index) {
                          final reversedIndex = gameState.monsterAIChat.length - 1 - index;
                          final message = gameState.monsterAIChat[reversedIndex];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.isInput ? '→ ' : '← ',
                                  style: TextStyle(
                                    color: message.isInput ? Colors.yellow : Colors.green,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    message.text,
                                    style: TextStyle(
                                      color: message.isInput ? Colors.yellow.shade200 : Colors.green.shade200,
                                      fontSize: 8,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // HUD - Player and Allies (Top-right corner)
          Positioned(
            top: 120,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Player Interface
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Player label
                      Text(
                        'PLAYER',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Health circles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(4, (index) {
                          return Container(
                            margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                              border: Border.all(color: Colors.red.shade900, width: 3),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 12),
                      // Ability buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildAbilityButton(
                            label: '1',
                            color: Color(0xFFB3B3CC), // Gray (sword)
                            cooldown: gameState.ability1Cooldown,
                            maxCooldown: gameState.ability1CooldownMax,
                            onPressed: _activateAbility1,
                          ),
                          SizedBox(width: 10),
                          _buildAbilityButton(
                            label: '2',
                            color: Color(0xFFFF6600), // Orange (fireball)
                            cooldown: gameState.ability2Cooldown,
                            maxCooldown: gameState.ability2CooldownMax,
                            onPressed: _activateAbility2,
                          ),
                          SizedBox(width: 10),
                          _buildAbilityButton(
                            label: '3',
                            color: Color(0xFF80FF4D), // Green (heal)
                            cooldown: gameState.ability3Cooldown,
                            maxCooldown: gameState.ability3CooldownMax,
                            onPressed: _activateAbility3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Allies Display
                ...gameState.allies.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ally = entry.value;
                  final abilityNames = ['Sword', 'Fireball', 'Heal'];
                  final abilityColors = [
                    Color(0xFFB3B3CC), // Gray (sword)
                    Color(0xFFFF6600), // Orange (fireball)
                    Color(0xFF80FF4D), // Green (heal)
                  ];

                  return Container(
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyan, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Ally label
                        Text(
                          'ALLY ${index + 1}',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        // Health bar
                        Container(
                          width: 150,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                          ),
                          child: Stack(
                            children: [
                              // Health fill
                              FractionallySizedBox(
                                widthFactor: (ally.health / ally.maxHealth).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: ally.health > 25 ? Colors.green :
                                           ally.health > 12 ? Colors.orange : Colors.red,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Health text
                              Center(
                                child: Text(
                                  '${ally.health.toStringAsFixed(0)} / ${ally.maxHealth.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        // Ability display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              abilityNames[ally.abilityIndex],
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                            SizedBox(width: 6),
                            InkWell(
                              onTap: ally.abilityCooldown > 0 || ally.health <= 0
                                  ? null
                                  : () => _activateAllyAbility(ally),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white30, width: 2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Stack(
                                  children: [
                                    // Base color
                                    Container(
                                      decoration: BoxDecoration(
                                        color: ally.abilityCooldown > 0
                                            ? Colors.grey.shade700
                                            : abilityColors[ally.abilityIndex],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    // Cooldown clock animation
                                    if (ally.abilityCooldown > 0)
                                      CustomPaint(
                                        size: Size(40, 40),
                                        painter: CooldownClockPainter(
                                          progress: 1.0 - (ally.abilityCooldown / ally.abilityCooldownMax),
                                        ),
                                      ),
                                    // Ability number label
                                    Center(
                                      child: Text(
                                        '${ally.abilityIndex + 1}',
                                        style: TextStyle(
                                          color: ally.abilityCooldown > 0
                                              ? Colors.white38
                                              : Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Ally management buttons (Top-right corner)
          Positioned(
            top: 10,
            right: 170,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ALLIES (${gameState.allies.length})',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      // Add Ally button
                      ElevatedButton(
                        onPressed: _addAlly,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size(50, 30),
                        ),
                        child: Text(
                          '+ Ally',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Remove Ally button
                      ElevatedButton(
                        onPressed: gameState.allies.isEmpty ? null : _removeAlly,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          disabledBackgroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size(50, 30),
                        ),
                        child: Text(
                          '- Ally',
                          style: TextStyle(
                            color: gameState.allies.isEmpty ? Colors.white38 : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

  // Build ability button with cooldown clock animation
  Widget _buildAbilityButton({
    required String label,
    required Color color,
    required double cooldown,
    required double maxCooldown,
    VoidCallback? onPressed,
  }) {
    final isOnCooldown = cooldown > 0;
    final progress = isOnCooldown ? (1.0 - (cooldown / maxCooldown)) : 1.0;

    return InkWell(
      onTap: isOnCooldown || onPressed == null ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: Colors.white30, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Base color
            Container(
              decoration: BoxDecoration(
                color: isOnCooldown ? Colors.grey.shade700 : color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Cooldown clock animation
            if (isOnCooldown)
              CustomPaint(
                size: Size(60, 60),
                painter: CooldownClockPainter(progress: progress),
              ),
            // Label
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isOnCooldown ? Colors.white38 : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Cooldown text
            if (isOnCooldown)
              Positioned(
                bottom: 4,
                right: 4,
                child: Text(
                  cooldown.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
    if (gameState.animationFrameId != null) {
      html.window.cancelAnimationFrame(gameState.animationFrameId!);
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

/// CustomPainter for cooldown clock animation
/// Draws a sweeping dark overlay that reveals the ability as cooldown completes
class CooldownClockPainter extends CustomPainter {
  final double progress; // 0.0 = just started cooldown, 1.0 = ready

  CooldownClockPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dark overlay that sweeps clockwise as cooldown progresses
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Calculate sweep angle (starts at top, sweeps clockwise)
    // progress 0.0 = full circle (360°), progress 1.0 = no circle (0°)
    final sweepAngle = (1.0 - progress) * 2 * math.pi;

    // Draw arc from top (-π/2) sweeping clockwise
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top (12 o'clock)
      sweepAngle, // Sweep clockwise
      true, // Use center (filled pie slice)
      paint,
    );
  }

  @override
  bool shouldRepaint(CooldownClockPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
