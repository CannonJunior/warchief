import 'dart:html' as html;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import '../rendering3d/webgl_renderer.dart';
import '../rendering3d/camera3d.dart';
import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';
import '../rendering3d/terrain_generator.dart';
import '../rendering3d/football_field_generator.dart';
import '../rendering3d/player_mesh.dart';
import '../game/controllers/input_manager.dart';
import '../models/game_action.dart';
import '../ai/ollama_client.dart';
import '../models/projectile.dart';
import '../models/ally.dart';
import '../models/ai_chat_message.dart';
import '../models/football.dart';
import 'state/game_config.dart';
import 'state/game_state.dart';
import 'state/abilities_config.dart';
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
import 'ui/ui_config.dart';
import 'ui/abilities_modal.dart';
import 'ui/playbook_modal.dart';
import 'ui/video_panel.dart';

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

  // PERFORMANCE FIX: Track previous UI state to avoid unnecessary rebuilds
  double _lastPlayerHealth = 100.0;
  double _lastMonsterHealth = 100.0;
  int _lastAllyCount = 0;

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

      // Initialize camera for football field view
      // Position camera behind the player, looking down the field
      camera = Camera3D(
        position: Vector3(0, 20, -40), // Higher and further back for field view
        rotation: Vector3(35, 0, 0), // Looking down at ~35 degrees
        aspectRatio: canvas.width! / canvas.height!,
      );

      // Set camera to follow ball carrier (positioned at midfield initially)
      camera!.setTarget(Vector3(0, 0, -30)); // Looking toward opponent's end zone
      camera!.setTargetDistance(25); // Further back for better field view

      // Initialize football field
      final footballField = FootballFieldGenerator.createField();
      gameState.footballFieldMesh = footballField.fieldMesh;
      gameState.footballFieldTransform = footballField.fieldTransform;
      gameState.footballFieldMarkings = footballField.markings;
      gameState.footballFieldEndZones = footballField.endZones;
      gameState.footballFieldGoalPosts = footballField.goalPosts;
      print('Football field created with ${footballField.markings.length} markings');

      // OLD: Initialize terrain (commented out for now)
      // gameState.terrainTiles = TerrainGenerator.createTileGrid(
      //   width: GameConfig.terrainGridSize,
      //   height: GameConfig.terrainGridSize,
      //   tileSize: GameConfig.terrainTileSize,
      // );

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

      // Initialize monster sword mesh (giant dark purple sword)
      gameState.monsterSwordMesh = Mesh.plane(
        width: GameConfig.monsterSwordWidth,
        height: GameConfig.monsterSwordHeight,
        color: GameConfig.monsterSwordColor,
      );
      gameState.monsterSwordTransform = Transform3d(
        position: Vector3(0, 0, 0), // Will be positioned when active
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
      final dtMs = gameState.lastFrameTime != null
          ? (now.millisecondsSinceEpoch - gameState.lastFrameTime!.millisecondsSinceEpoch).toDouble()
          : 16.67; // Default to ~60fps
      gameState.lastFrameTime = now;

      // Frame rate limiting - skip frames if running too fast
      gameState.frameTimeAccumulator += dtMs;
      if (gameState.frameTimeAccumulator < GameState.targetFrameTime) {
        // Frame came too early, skip it
        gameState.animationFrameId = html.window.requestAnimationFrame(gameLoop);
        return;
      }
      gameState.frameTimeAccumulator = 0.0;

      final dt = dtMs / 1000.0; // Convert to seconds
      gameState.frameCount++;

      // Log every 60 frames (~1 second at 60fps)
      if (gameState.frameCount % 60 == 0) {
        print('Frame ${gameState.frameCount} - dt: ${dt.toStringAsFixed(4)}s');
      }

      _update(dt);
      _render();

      // PERFORMANCE FIX: Only update UI when state actually changes
      // Check every 10 frames to avoid too many comparisons
      if (gameState.frameCount % 10 == 0 && mounted) {
        final healthChanged = gameState.playerHealth != _lastPlayerHealth ||
                             gameState.monsterHealth != _lastMonsterHealth;
        final alliesChanged = gameState.allies.length != _lastAllyCount;

        if (healthChanged || alliesChanged) {
          _lastPlayerHealth = gameState.playerHealth;
          _lastMonsterHealth = gameState.monsterHealth;
          _lastAllyCount = gameState.allies.length;
          setState(() {});
        }
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

    // Track player movement for AI prediction
    if (gameState.playerTransform != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      gameState.playerMovementTracker.update(
        gameState.playerTransform!.position,
        currentTime,
      );
    }

    // ===== ABILITY SYSTEM =====
    // Update player ability cooldowns and effects
    AbilitySystem.update(dt, gameState);

    // PERFORMANCE FIX: Throttle AI updates to every 100ms instead of every frame
    gameState.aiAccumulatedTime += dt;
    if (gameState.aiAccumulatedTime >= GameState.aiUpdateInterval) {
      // Update AI systems (monster AI, ally AI, projectiles)
      AISystem.update(
        gameState.aiAccumulatedTime, // Use accumulated time
        gameState,
        logMonsterAI: _logMonsterAI,
        activateMonsterAbility1: _activateMonsterAbility1,
        activateMonsterAbility2: _activateMonsterAbility2,
        activateMonsterAbility3: _activateMonsterAbility3,
      );
      gameState.aiAccumulatedTime = 0.0; // Reset accumulator
    }

    // Handle player ability input
    AbilitySystem.handleAbility1Input(inputManager!.isActionPressed(GameAction.actionBar1), gameState);
    AbilitySystem.handleAbility2Input(inputManager!.isActionPressed(GameAction.actionBar2), gameState);

    // Check spin direction: E (strafe right) = clockwise, Q (strafe left) = counter-clockwise
    final strafeRight = inputManager!.isActionPressed(GameAction.strafeRight);
    final strafeLeft = inputManager!.isActionPressed(GameAction.strafeLeft);
    final spinClockwise = strafeRight; // E = clockwise
    final spinCounterClockwise = strafeLeft; // Q = counter-clockwise

    // Pass true for clockwise if E is pressed, false if Q is pressed or neither
    AbilitySystem.handleAbility3Input(
      inputManager!.isActionPressed(GameAction.actionBar3),
      spinClockwise && !spinCounterClockwise, // Only clockwise if E pressed and Q not pressed
      gameState
    );
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

    // Update camera based on mode
    if (camera!.mode == CameraMode.thirdPerson) {
      // Third-person mode: Camera follows player from behind
      camera!.updateThirdPersonFollow(
        gameState.playerTransform!.position,
        gameState.playerRotation,
        dt,
      );
    } else {
      // Static mode: Camera orbits around player with smoothing
      final currentTarget = camera!.getTarget();
      final distanceFromTarget = (gameState.playerTransform!.position - currentTarget).length;

      // Update camera target smoothly when player moves away from center
      if (distanceFromTarget > 0.1) {
        // Smoothly interpolate camera target toward player position
        final newTarget = currentTarget + (gameState.playerTransform!.position - currentTarget) * 0.05;
        camera!.setTarget(newTarget);
      }
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
    // Check if any modifier keys are pressed (CTRL, ALT, SHIFT, META)
    final hasModifiers = HardwareKeyboard.instance.isControlPressed ||
                         HardwareKeyboard.instance.isAltPressed ||
                         HardwareKeyboard.instance.isShiftPressed ||
                         HardwareKeyboard.instance.isMetaPressed;

    // Handle P key for abilities modal (only on key down, not repeat, no modifiers)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyP && !hasModifiers) {
      print('P key detected! Toggling modal. Current state: ${gameState.abilitiesModalOpen}');
      setState(() {
        gameState.abilitiesModalOpen = !gameState.abilitiesModalOpen;
        print('Modal now: ${gameState.abilitiesModalOpen}');
      });
      return;
    }

    // Handle O key for playbook modal (only on key down, not repeat, no modifiers)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyO && !hasModifiers) {
      print('O key detected! Toggling playbook. Current state: ${gameState.playbookModalOpen}');
      setState(() {
        gameState.playbookModalOpen = !gameState.playbookModalOpen;
        print('Playbook now: ${gameState.playbookModalOpen}');
      });
      return;
    }

    // Handle V key for video panel (only on key down, not repeat, no modifiers)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyV && !hasModifiers) {
      print('V key detected! Toggling video panel. Current state: ${gameState.videoPanelOpen}');
      setState(() {
        gameState.videoPanelOpen = !gameState.videoPanelOpen;
        print('Video panel now: ${gameState.videoPanelOpen}');
      });
      return;
    }

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
      // Check spin direction: E = clockwise, Q = counter-clockwise
      final strafeRight = inputManager?.isActionPressed(GameAction.strafeRight) ?? false;
      final strafeLeft = inputManager?.isActionPressed(GameAction.strafeLeft) ?? false;
      final spinClockwise = strafeRight && !strafeLeft;
      AbilitySystem.handleAbility3Input(true, spinClockwise, gameState);
    });
  }

  // ===== MONSTER ABILITY METHODS =====

  /// Activate Monster Ability 1: Dark Strike (melee sword attack)
  void _activateMonsterAbility1() {
    if (gameState.monsterAbility1Cooldown > 0 || gameState.monsterHealth <= 0) return;
    if (gameState.monsterAbility1Active) return; // Already swinging

    setState(() {
      gameState.monsterAbility1Cooldown = gameState.monsterAbility1CooldownMax;
      gameState.monsterAbility1Active = true;
      gameState.monsterAbility1ActiveTime = 0.0;
      gameState.monsterAbility1HitRegistered = false;
    });
    print('Monster uses Dark Strike! (sword attack)');
  }

  /// Activate Monster Ability 2: Shadow Bolt (ranged projectile)
  void _activateMonsterAbility2() {
    if (gameState.monsterAbility2Cooldown > 0 || gameState.monsterHealth <= 0) return;
    if (gameState.monsterTransform == null || gameState.playerTransform == null) return;

    final shadowBolt = AbilitiesConfig.monsterShadowBolt;

    // Create shadow bolt projectile aimed at player
    final direction = (gameState.playerTransform!.position - gameState.monsterTransform!.position).normalized();
    // PERFORMANCE FIX: Reuse singleton mesh instead of creating new one
    final projectileMesh = gameState.getShadowBoltMesh();
    final projectileTransform = Transform3d(
      position: gameState.monsterTransform!.position.clone() + Vector3(0, 1, 0),
      scale: Vector3(1, 1, 1),
    );

    setState(() {
      gameState.monsterProjectiles.add(Projectile(
        mesh: projectileMesh,
        transform: projectileTransform,
        velocity: direction * shadowBolt.projectileSpeed,
        lifetime: 5.0,
      ));
      gameState.monsterAbility2Cooldown = gameState.monsterAbility2CooldownMax;
    });
    print('Monster casts ${shadowBolt.name}!');
  }

  /// Activate Monster Ability 3: Dark Healing (restore health)
  void _activateMonsterAbility3() {
    if (gameState.monsterAbility3Cooldown > 0 || gameState.monsterHealth <= 0) return;

    final darkHeal = AbilitiesConfig.monsterDarkHeal;

    final oldHealth = gameState.monsterHealth;
    setState(() {
      gameState.monsterHealth = math.min(gameState.monsterMaxHealth.toDouble(), gameState.monsterHealth + darkHeal.healAmount);
      gameState.monsterAbility3Cooldown = gameState.monsterAbility3CooldownMax;
    });
    final healedAmount = gameState.monsterHealth - oldHealth;
    print('[HEAL] Monster uses ${darkHeal.name}! Restored ${healedAmount.toStringAsFixed(1)} HP (${gameState.monsterHealth.toStringAsFixed(0)}/${gameState.monsterMaxHealth})');
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

  /// Snap the ball to start the play
  void _snapBall() {
    if (gameState.activeFootball == null || gameState.loadedPlayPositions == null) {
      print('Cannot snap: no football or loaded play');
      return;
    }

    setState(() {
      gameState.playIsSnapped = true;

      // Find Center and QB positions from loaded play
      final positions = gameState.loadedPlayPositions as List<dynamic>;

      // Find Center (ball carrier)
      final centerPos = positions.firstWhere(
        (p) => p.abbreviation == 'C',
        orElse: () => null,
      );

      // Find QB (snap target) - or designated snap target
      var snapTarget = positions.firstWhere(
        (p) => p.abbreviation == 'QB',
        orElse: () => null,
      );

      // If no QB found, snap to first backfield player (RB/FB)
      snapTarget ??= positions.firstWhere(
        (p) => p.abbreviation == 'RB' || p.abbreviation == 'FB',
        orElse: () => null,
      );

      if (centerPos == null || snapTarget == null) {
        print('Cannot snap: Center or snap target not found');
        return;
      }

      // Find corresponding ally positions on field for Center and snap target
      Ally? centerAlly;
      Ally? targetAlly;

      for (int i = 0; i < gameState.allies.length; i++) {
        final pos = positions[i];
        if (pos.abbreviation == 'C') {
          centerAlly = gameState.allies[i];
        } else if (pos.abbreviation == snapTarget.abbreviation) {
          targetAlly = gameState.allies[i];
        }
      }

      if (centerAlly == null || targetAlly == null) {
        print('Cannot snap: Center or target ally not found on field');
        return;
      }

      // Calculate snap velocity (from Center to QB)
      final centerPosition = centerAlly.transform.position;
      final targetPosition = targetAlly.transform.position;
      final snapDirection = (targetPosition - centerPosition).normalized();
      final snapSpeed = 15.0; // Fast snap speed
      final snapVelocity = snapDirection * snapSpeed;

      // Update football to be a moving projectile (snap)
      gameState.activeFootball!.velocity = snapVelocity;
      gameState.activeFootball!.state = FootballState.inFlight;
      gameState.activeFootball!.timeInFlight = 0.0;
      gameState.ballCarrierHasBall = false;

      print('SNAP! Ball snapped from Center to ${snapTarget.abbreviation}');
      print('Ball velocity: ${snapVelocity}');

      // Start executing player actions (routes, blocks, runs)
      _executePlayerActions();
    });
  }

  /// Execute player actions from the loaded play
  void _executePlayerActions() {
    if (gameState.loadedPlayPositions == null) return;

    final positions = gameState.loadedPlayPositions as List<dynamic>;

    for (int i = 0; i < positions.length && i < gameState.allies.length; i++) {
      final playerPos = positions[i];
      final ally = gameState.allies[i];

      // Skip if no action assigned
      if (playerPos.assignedAction == null) {
        print('${playerPos.abbreviation}: No action assigned');
        continue;
      }

      final action = playerPos.assignedAction as String;
      final isFlipped = playerPos.actionFlipped ?? false;

      print('${playerPos.abbreviation}: Executing ${action}${isFlipped ? " (flipped)" : ""}');

      // Get action visual definition from playbook
      final actionPath = _getActionVisualPath(action);

      if (actionPath != null) {
        // Convert action path to 3D movement path for ally
        _setAllyActionPath(ally, actionPath, isFlipped, playerPos.abbreviation);
      } else {
        print('Warning: No visual path found for action: ${action}');
      }
    }
  }

  /// Get action visual path from playbook action definitions
  List<Map<String, dynamic>>? _getActionVisualPath(String actionName) {
    // Import action definitions from PlaybookModal
    // These are the same visual definitions used in the playbook

    // Routes
    final routes = {
      'Go': [
        {'x': 0.0, 'y': -200.0}, // Straight downfield
      ],
      'Post': [
        {'x': 0.0, 'y': -80.0},
        {'x': -60.0, 'y': -140.0}, // Cut toward middle
      ],
      'Corner': [
        {'x': 0.0, 'y': -80.0},
        {'x': 60.0, 'y': -140.0}, // Cut toward sideline
      ],
      'Slant': [
        {'x': 40.0, 'y': -60.0}, // Quick diagonal cut
      ],
      'Out': [
        {'x': 0.0, 'y': -40.0},
        {'x': 80.0, 'y': -40.0}, // Break to sideline
      ],
      'In': [
        {'x': 0.0, 'y': -40.0},
        {'x': -80.0, 'y': -40.0}, // Break to middle
      ],
      'Curl': [
        {'x': 0.0, 'y': -80.0},
        {'x': 0.0, 'y': -60.0}, // Run then come back
      ],
      'Flat': [
        {'x': 60.0, 'y': -20.0}, // Quick out to flat
      ],
    };

    // Blocks
    final blocks = {
      'Drive Block': [
        {'x': 0.0, 'y': -30.0}, // Push forward
      ],
      'Pull Block': [
        {'x': 80.0, 'y': -20.0}, // Pull to the side
      ],
      'Reach Block': [
        {'x': 40.0, 'y': -10.0}, // Reach to outside
      ],
      'Down Block': [
        {'x': -40.0, 'y': -10.0}, // Block down inside
      ],
      'Pass Block': [
        {'x': 0.0, 'y': -10.0}, // Slight backpedal
      ],
    };

    // Runs
    final runs = {
      'Dive': [
        {'x': 0.0, 'y': -60.0}, // Straight ahead
      ],
      'Sweep': [
        {'x': 100.0, 'y': -40.0}, // Wide to sideline
      ],
      'Power': [
        {'x': 40.0, 'y': -60.0}, // Power to hole
      ],
      'Counter': [
        {'x': -30.0, 'y': 10.0}, // Fake one way
        {'x': 60.0, 'y': -60.0}, // Cut back other way
      ],
    };

    // Check all action categories
    if (routes.containsKey(actionName)) return routes[actionName];
    if (blocks.containsKey(actionName)) return blocks[actionName];
    if (runs.containsKey(actionName)) return runs[actionName];

    return null;
  }

  /// Set ally to follow action path in 3D space
  void _setAllyActionPath(Ally ally, List<Map<String, dynamic>> actionPath, bool isFlipped, String position) {
    // Convert playbook 2D path to 3D field coordinates
    final startPosition = ally.transform.position.clone();

    // Build 3D waypoints from 2D action path
    final waypoints = <Vector3>[];
    waypoints.add(startPosition); // Start at current position

    // Playbook scaling: 1 yard = 13.33 pixels in playbook
    final yardsPerPixel = 30.0 / 400.0; // 30 yards over 400 pixels
    final fieldWidth = 50.0;

    for (final segment in actionPath) {
      final pixelX = (segment['x'] as double) * (isFlipped ? -1 : 1); // Flip X if needed
      final pixelY = segment['y'] as double;

      // Convert to yards
      final yardsX = pixelX * yardsPerPixel;
      final yardsY = pixelY * yardsPerPixel;

      // Scale to game field coordinates
      final fieldX = startPosition.x + (yardsX * (fieldWidth / 53.33)); // Scale to field width
      final fieldZ = startPosition.z + yardsY; // Y in playbook = Z in game

      waypoints.add(Vector3(fieldX, 0.4, fieldZ));
    }

    // Set ally to follow this path
    ally.movementMode = AllyMovementMode.followPath;
    ally.pathWaypoints = waypoints;
    ally.currentWaypointIndex = 0;

    print('${position} executing path with ${waypoints.length} waypoints');
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

  /// Spawn units from playbook onto the field
  void _spawnPlaybookUnits(List<PlayerPosition> players, String? playName) {
    setState(() {
      // Store loaded play data
      gameState.loadedPlayName = playName;
      gameState.loadedPlayPositions = players;
      gameState.playIsSnapped = false;

      // Clear existing allies
      gameState.allies.clear();

      // The playbook modal field represents 30 yards (10 behind LOS, 20 downfield)
      // Playbook dimensions: 700x400 pixels
      // LOS is at y=266.67 (2/3 from top)

      final playbookWidth = 700.0;
      final playbookHeight = 400.0;
      final playbookLOS = 266.67; // Line of scrimmage in playbook (pixels)

      // Field width: 53.33 yards = ~50 game units
      final fieldWidth = 50.0;

      // Playbook represents 30 yards total depth
      final playbookYards = 30.0;
      final yardsPerPixel = playbookYards / playbookHeight; // 30 yards / 400 pixels = 0.075 yards/pixel

      // Player is at z=-15, let's position LOS at z=-9 (6 yards ahead of player/QB)
      final gameLOS = -9.0;

      for (final player in players) {
        // Convert playbook X to field X (centered)
        // Playbook X (0-700) -> Field X (-25 to 25)
        final fieldX = ((player.position.x / playbookWidth) - 0.5) * fieldWidth;

        // Convert playbook Y to field Z
        // Playbook Y coordinates: Top (0) = +20 yards, Middle (266.67) = LOS (0), Bottom (400) = -10 yards
        // Calculate yards from LOS in playbook
        final pixelsFromLOS = player.position.y - playbookLOS;
        final yardsFromLOS = pixelsFromLOS * yardsPerPixel;

        // Map to game field position relative to game LOS
        final fieldZ = gameLOS + yardsFromLOS;

        // Create ally mesh with different colors based on position
        final color = _getPositionColor(player.abbreviation);
        final allyMesh = Mesh.cube(
          size: 0.8,
          color: color,
        );

        final allyTransform = Transform3d(
          position: Vector3(fieldX, 0.4, fieldZ),
          scale: Vector3(1, 1, 1),
        );

        // Assign ability based on player position/action
        final abilityIndex = _getAbilityForPosition(player);

        final ally = Ally(
          mesh: allyMesh,
          transform: allyTransform,
          rotation: math.pi, // 180 degrees - face downfield toward opponent's end zone
          abilityIndex: abilityIndex,
          health: 50.0,
          maxHealth: 50.0,
          abilityCooldown: 0.0,
          abilityCooldownMax: 5.0,
          aiTimer: 0.0,
          movementMode: AllyMovementMode.stationary,
        );

        gameState.allies.add(ally);
      }

      // Create football at line of scrimmage (center of field, at LOS)
      // Football positioned at ground level at the LOS
      final footballMesh = Mesh.cube(
        size: 0.3, // Small football size
        color: Vector3(0.6, 0.4, 0.2), // Brown football color
      );

      final footballPosition = Vector3(0, 0.15, gameLOS); // Center X, on ground, at LOS Z

      final footballTransform = Transform3d(
        position: footballPosition,
        scale: Vector3(0.4, 0.3, 0.6), // Ellipsoid shape
      );

      // Create football entity (not active/thrown yet, just placed at LOS)
      gameState.activeFootball = Football(
        position: footballPosition,
        velocity: Vector3.zero(),
        mesh: footballMesh,
        transform: footballTransform,
        state: FootballState.carried, // Ball is at center, not in flight
        timeInFlight: 0.0,
        maxFlightTime: 999.0, // Won't auto-incomplete while on ground
      );

      print('Spawned ${gameState.allies.length} units from playbook onto field');
      print('Loaded play: ${playName ?? "unnamed"}');
      print('Football placed at LOS (z=${gameLOS})');
    });
  }

  /// Get color for position type
  Vector3 _getPositionColor(String abbreviation) {
    // QB - Red
    if (abbreviation == 'QB') return Vector3(1.0, 0.3, 0.3);

    // RB/FB - Orange
    if (abbreviation == 'RB' || abbreviation == 'FB') return Vector3(1.0, 0.6, 0.2);

    // Offensive Line - Blue
    if (abbreviation == 'LT' || abbreviation == 'LG' || abbreviation == 'C' ||
        abbreviation == 'RG' || abbreviation == 'RT') return Vector3(0.3, 0.5, 1.0);

    // TE - Cyan
    if (abbreviation == 'TE') return Vector3(0.3, 0.8, 0.8);

    // WR - Yellow/Green
    if (abbreviation == 'WR1' || abbreviation == 'WR2') return Vector3(0.5, 1.0, 0.3);

    // Default - Light blue
    return Vector3(0.4, 0.7, 1.0);
  }

  /// Get ability index based on player position and assigned action
  int _getAbilityForPosition(PlayerPosition player) {
    // If the player has an assigned action, try to map it to an ability
    if (player.assignedAction != null) {
      final action = player.assignedAction!;

      // Routes get Fireball (ranged attack)
      if (action.contains('Route') || action.contains('Go') || action.contains('Post') ||
          action.contains('Corner') || action.contains('Fly')) {
        return 1; // Fireball
      }

      // Blocks get Sword (melee)
      if (action.contains('Block')) {
        return 0; // Sword
      }
    }

    // Default assignments based on position
    if (player.abbreviation == 'QB') return 1; // Fireball
    if (player.abbreviation == 'RB' || player.abbreviation == 'FB') return 0; // Sword
    if (player.abbreviation == 'WR1' || player.abbreviation == 'WR2') return 1; // Fireball
    if (player.abbreviation == 'TE') return 0; // Sword

    // Offensive line gets random
    return math.Random().nextInt(3);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        // If any modal with text input is open, allow keyboard events to pass through
        // (except for modal toggle keys WITHOUT modifiers)
        final modalOpen = gameState.abilitiesModalOpen || gameState.playbookModalOpen || gameState.videoPanelOpen;

        if (modalOpen) {
          // Check if this is a modal toggle key (P, O, V) WITHOUT modifiers
          if (event is KeyDownEvent) {
            final hasModifiers = HardwareKeyboard.instance.isControlPressed ||
                                HardwareKeyboard.instance.isAltPressed ||
                                HardwareKeyboard.instance.isShiftPressed ||
                                HardwareKeyboard.instance.isMetaPressed;

            if (!hasModifiers &&
                (event.logicalKey == LogicalKeyboardKey.keyP ||
                 event.logicalKey == LogicalKeyboardKey.keyO ||
                 event.logicalKey == LogicalKeyboardKey.keyV)) {
              _onKeyEvent(event);
              return KeyEventResult.handled;
            }
          }
          // For all other keys (including CTRL+V, CTRL+C, etc.), let them pass through to text fields
          return KeyEventResult.ignored;
        }

        // No modal open - handle game input normally
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

            // Player HUD
            Positioned(
              top: UIConfig.playerHudTop,
              right: UIConfig.playerHudRight,
              child: PlayerHud(
                gameState: gameState,
                onAbility1Pressed: _activateAbility1,
                onAbility2Pressed: _activateAbility2,
                onAbility3Pressed: _activateAbility3,
              ),
            ),

            // Allies Panel
            AlliesPanel(
              allies: gameState.allies,
              onActivateAllyAbility: _activateAllyAbility,
              onAddAlly: _addAlly,
              onRemoveAlly: _removeAlly,
            ),

            // Snap Button (only shown when play is loaded)
            if (gameState.loadedPlayName != null && !gameState.playIsSnapped)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Play: ${gameState.loadedPlayName}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _snapBall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        child: Text('SNAP'),
                      ),
                    ],
                  ),
                ),
              ),

            // Abilities Modal (Press P to toggle)
            if (gameState.abilitiesModalOpen)
              AbilitiesModal(
                onClose: () {
                  setState(() {
                    gameState.abilitiesModalOpen = false;
                  });
                },
              ),

            // Playbook Modal (Press O to toggle)
            if (gameState.playbookModalOpen)
              PlaybookModal(
                onClose: () {
                  setState(() {
                    gameState.playbookModalOpen = false;
                  });
                },
                onPractice: (players, playName) {
                  _spawnPlaybookUnits(players, playName);
                },
              ),

            // Video Panel (Press V to toggle)
            if (gameState.videoPanelOpen)
              VideoPanel(
                onClose: () {
                  setState(() {
                    gameState.videoPanelOpen = false;
                  });
                },
                onMakePlay: (formationName, playName, videoUrl) {
                  // The formation has already been saved by VideoAnalysisService
                  // Just show confirmation that it was created
                  print('Formation "$formationName" with play "$playName" created from video: $videoUrl');
                },
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
