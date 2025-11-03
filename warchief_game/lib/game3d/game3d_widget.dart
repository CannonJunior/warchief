import 'dart:html' as html;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

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
import 'systems/ai_system.dart';
import 'systems/input_system.dart';
import 'systems/render_system.dart';
import 'ui/instructions_overlay.dart';
import 'ui/monster_hud.dart';
import 'ui/ai_chat_panel.dart';
import 'ui/player_hud.dart';
import 'ui/allies_panel.dart';

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

    // Process player and camera input
    InputSystem.update(dt, inputManager!, camera!, gameState);

    // Handle jump input
    final jumpKeyIsPressed = inputManager!.isActionPressed(GameAction.jump);
    PhysicsSystem.handleJumpInput(jumpKeyIsPressed, gameState);

    // Update physics (gravity, vertical movement, ground collision)
    PhysicsSystem.update(dt, gameState);

    // ===== ABILITY SYSTEM =====
    // Update player ability cooldowns and effects
    AbilitySystem.update(dt, gameState);

    // Update AI systems (monster AI, ally AI, projectiles)
    AISystem.update(
      dt,
      gameState,
      logMonsterAI: _logMonsterAI,
      activateMonsterAbility1: _activateMonsterAbility1,
      activateMonsterAbility2: _activateMonsterAbility2,
      activateMonsterAbility3: _activateMonsterAbility3,
      checkAndHandleCollision: _checkAndHandleCollision,
    );

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

    RenderSystem.render(renderer!, camera!, gameState);
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


  // ===== ALLY MANAGEMENT METHODS =====

  /// Manually activate an ally's ability (called from UI button)
  void _activateAllyAbility(Ally ally) {
    if (ally.abilityCooldown > 0 || ally.health <= 0) {
      print('Ally ability on cooldown or ally is dead');
      return;
    }

    setState(() {
      // Force the ally to use their ability
      AISystem.executeAllyDecision(ally, 'ATTACK', gameState);
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
            InstructionsOverlay(
              camera: camera,
              gameState: gameState,
            ),

            // Monster HUD
            MonsterHud(
              gameState: gameState,
              onAbility1Pressed: _activateMonsterAbility1,
              onAbility2Pressed: _activateMonsterAbility2,
              onAbility3Pressed: _activateMonsterAbility3,
              onPauseToggle: () {
                setState(() {
                  gameState.monsterPaused = !gameState.monsterPaused;
                });
                print('Monster AI ${gameState.monsterPaused ? 'paused' : 'resumed'}');
              },
            ),

            // AI Chat Panel
            AIChatPanel(
              messages: gameState.monsterAIChat,
            ),

            // Player and Allies Panel
            Positioned(
              top: 120,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Player HUD
                  PlayerHud(
                    gameState: gameState,
                    onAbility1Pressed: _activateAbility1,
                    onAbility2Pressed: _activateAbility2,
                    onAbility3Pressed: _activateAbility3,
                  ),
                ],
              ),
            ),

            // Allies Panel
            AlliesPanel(
              allies: gameState.allies,
              onActivateAllyAbility: _activateAllyAbility,
              onAddAlly: _addAlly,
              onRemoveAlly: _removeAlly,
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
