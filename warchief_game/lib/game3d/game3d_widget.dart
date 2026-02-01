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
import '../rendering3d/infinite_terrain_manager.dart';
import '../rendering3d/game_config_terrain.dart';
import '../rendering3d/player_mesh.dart';
import '../game/controllers/input_manager.dart';
import '../models/game_action.dart';
import '../ai/ollama_client.dart';
import '../models/projectile.dart';
import '../models/ally.dart';
import '../models/ai_chat_message.dart';
import 'ai/ally_strategy.dart';
import 'ai/tactical_positioning.dart';
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
import 'ui/formation_panel.dart';
import 'ui/draggable_panel.dart';
import 'ui/ally_command_panels.dart';
import 'ui/ui_config.dart';
import 'ui/abilities_modal.dart';

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

      // Initialize terrain texturing system (async but we don't wait for it)
      _initializeTerrainTexturing();

      // Initialize camera
      camera = Camera3D(
        position: Vector3(0, 10, 15),
        rotation: Vector3(30, 0, 0), // Start at 30 degrees
        aspectRatio: canvas.width! / canvas.height!,
      );

      // Set camera to orbit around origin
      camera!.setTarget(Vector3(0, 0, 0));
      camera!.setTargetDistance(15);

      // Initialize terrain - use infinite terrain if enabled
      if (TerrainConfig.useInfiniteTerrain) {
        gameState.infiniteTerrainManager = InfiniteTerrainManager.fromConfig();
        // Set GL context for texture cleanup
        gameState.infiniteTerrainManager!.setGLContext(renderer!.gl);
        print('[Game3D] Infinite terrain enabled with texture splatting: ${TerrainConfig.useTextureSplatting}');
      } else {
        // Fallback to old terrain system
        gameState.terrainTiles = TerrainGenerator.createTileGrid(
          width: GameConfig.terrainGridSize,
          height: GameConfig.terrainGridSize,
          tileSize: GameConfig.terrainTileSize,
        );
      }

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

      // Adjust player and monster starting positions to terrain height
      _adjustStartingPositionsToTerrain();

      print('Game3D initialized successfully!');

      // Start game loop
      _startGameLoop();
    } catch (e, stackTrace) {
      print('Error initializing Game3D: $e');
      print(stackTrace);
    }
  }

  /// Initialize terrain texturing system
  ///
  /// This loads procedural terrain textures and creates the terrain shader.
  /// Called asynchronously during game initialization.
  Future<void> _initializeTerrainTexturing() async {
    if (renderer == null) return;
    if (!TerrainConfig.useTextureSplatting) {
      print('[Game3D] Texture splatting disabled in config');
      return;
    }

    try {
      await renderer!.initializeTerrainTexturing();
      print('[Game3D] Terrain texturing initialized successfully');
      print(TerrainConfig.getSummary());
    } catch (e) {
      print('[Game3D] Failed to initialize terrain texturing: $e');
      print('[Game3D] Falling back to vertex-colored terrain');
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

  /// Adjust starting positions of units to match terrain height
  ///
  /// Called after terrain and units are initialized to ensure units
  /// start at the correct elevation instead of floating or buried.
  void _adjustStartingPositionsToTerrain() {
    if (gameState.infiniteTerrainManager == null) return;

    // Force initial terrain chunk loading around starting positions
    // This ensures terrain exists before querying heights
    final playerPos = gameState.playerTransform?.position;
    if (playerPos != null) {
      gameState.infiniteTerrainManager!.update(playerPos, playerPos);
    }

    // Adjust player Y to terrain height
    if (gameState.playerTransform != null) {
      final terrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(
        gameState.playerTransform!.position.x,
        gameState.playerTransform!.position.z,
      );
      gameState.playerTransform!.position.y = terrainHeight;
      print('[Game3D] Player starting height adjusted to terrain: $terrainHeight');
    }

    // Adjust monster Y to terrain height
    if (gameState.monsterTransform != null) {
      final terrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(
        gameState.monsterTransform!.position.x,
        gameState.monsterTransform!.position.z,
      );
      gameState.monsterTransform!.position.y = terrainHeight;

      // Also adjust monster direction indicator
      if (gameState.monsterDirectionIndicatorTransform != null) {
        gameState.monsterDirectionIndicatorTransform!.position.y = terrainHeight + 0.7;
      }
      print('[Game3D] Monster starting height adjusted to terrain: $terrainHeight');
    }
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

    // Update infinite terrain (chunk loading/unloading based on player position)
    if (gameState.infiniteTerrainManager != null && gameState.playerTransform != null && camera != null) {
      gameState.infiniteTerrainManager!.update(
        gameState.playerTransform!.position,
        camera!.position,
      );
    }

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
    );

    // Handle player ability input
    AbilitySystem.handleAbility1Input(inputManager!.isActionPressed(GameAction.actionBar1), gameState);
    AbilitySystem.handleAbility2Input(inputManager!.isActionPressed(GameAction.actionBar2), gameState);
    AbilitySystem.handleAbility3Input(inputManager!.isActionPressed(GameAction.actionBar3), gameState);
    AbilitySystem.handleAbility4Input(inputManager!.isActionPressed(GameAction.actionBar4), gameState);
    // ===== END ABILITY SYSTEM =====

    // ===== ALLY COMMAND SYSTEM =====
    _handleAllyCommands();

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

      // Calculate shadow offset based on player height above terrain (higher = further from player)
      final playerHeight = PhysicsSystem.getPlayerHeight(gameState);
      final shadowOffsetX = playerHeight * lightDirX;
      final shadowOffsetZ = playerHeight * lightDirZ;

      // Position shadow with offset from player
      gameState.shadowTransform!.position.x = gameState.playerTransform!.position.x + shadowOffsetX;
      gameState.shadowTransform!.position.z = gameState.playerTransform!.position.z + shadowOffsetZ;

      // Set shadow Y to terrain height at shadow position (slightly above to avoid z-fighting)
      if (gameState.infiniteTerrainManager != null) {
        final shadowTerrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(
          gameState.shadowTransform!.position.x,
          gameState.shadowTransform!.position.z,
        );
        gameState.shadowTransform!.position.y = shadowTerrainHeight + 0.01;
      }

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
    // Handle P key for abilities modal (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyP) {
      print('P key detected! Toggling modal. Current state: ${gameState.abilitiesModalOpen}');
      setState(() {
        gameState.abilitiesModalOpen = !gameState.abilitiesModalOpen;
        print('Modal now: ${gameState.abilitiesModalOpen}');
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
      AbilitySystem.handleAbility3Input(true, gameState);
    });
  }

  void _activateAbility4() {
    setState(() {
      AbilitySystem.handleAbility4Input(true, gameState);
    });
  }

  // ===== ALLY COMMAND METHODS =====

  /// Track previous command key states to detect key press (not hold)
  bool _followKeyWasPressed = false;
  bool _attackKeyWasPressed = false;
  bool _holdKeyWasPressed = false;
  bool _formationKeyWasPressed = false;

  /// Panel visibility states (toggled with SHIFT+key)
  bool _showAttackPanel = false;
  bool _showFollowPanel = false;
  bool _showHoldPanel = false;
  bool _showFormationPanel = true; // Shown by default

  /// Panel positions (for draggable panels)
  Offset _attackPanelPosition = Offset(20, 200);
  Offset _followPanelPosition = Offset(170, 200);
  Offset _holdPanelPosition = Offset(320, 200);
  Offset _formationPanelPosition = Offset(0, 0); // Will be set in build

  /// Track SHIFT+key states for panel toggling
  bool _shiftFollowWasPressed = false;
  bool _shiftAttackWasPressed = false;
  bool _shiftHoldWasPressed = false;
  bool _shiftFormationWasPressed = false;

  /// Handle ally command input (F=Follow, G=Attack, H=Hold)
  void _handleAllyCommands() {
    if (inputManager == null) return;

    final shiftPressed = inputManager!.isShiftPressed();
    final followPressed = inputManager!.isActionPressed(GameAction.petFollow);
    final attackPressed = inputManager!.isActionPressed(GameAction.petAttack);
    final holdPressed = inputManager!.isActionPressed(GameAction.petStay);
    final formationPressed = inputManager!.isActionPressed(GameAction.cycleFormation);

    // SHIFT+F - Toggle Follow panel
    if (shiftPressed && followPressed && !_shiftFollowWasPressed) {
      setState(() {
        _showFollowPanel = !_showFollowPanel;
      });
      print('[UI] Follow panel: ${_showFollowPanel ? "shown" : "hidden"}');
    }
    _shiftFollowWasPressed = shiftPressed && followPressed;

    // SHIFT+T - Toggle Attack panel
    if (shiftPressed && attackPressed && !_shiftAttackWasPressed) {
      setState(() {
        _showAttackPanel = !_showAttackPanel;
      });
      print('[UI] Attack panel: ${_showAttackPanel ? "shown" : "hidden"}');
    }
    _shiftAttackWasPressed = shiftPressed && attackPressed;

    // SHIFT+G - Toggle Hold panel
    if (shiftPressed && holdPressed && !_shiftHoldWasPressed) {
      setState(() {
        _showHoldPanel = !_showHoldPanel;
      });
      print('[UI] Hold panel: ${_showHoldPanel ? "shown" : "hidden"}');
    }
    _shiftHoldWasPressed = shiftPressed && holdPressed;

    // SHIFT+R - Toggle Formation panel
    if (shiftPressed && formationPressed && !_shiftFormationWasPressed) {
      setState(() {
        _showFormationPanel = !_showFormationPanel;
      });
      print('[UI] Formation panel: ${_showFormationPanel ? "shown" : "hidden"}');
    }
    _shiftFormationWasPressed = shiftPressed && formationPressed;

    // Without SHIFT - execute commands
    if (!shiftPressed) {
      // F key - Follow command (toggle)
      if (followPressed && !_followKeyWasPressed) {
        _setAllyCommand(AllyCommand.follow);
        print('[ALLY CMD] All allies: FOLLOW');
      }
      _followKeyWasPressed = followPressed;

      // T key - Attack command (toggle)
      if (attackPressed && !_attackKeyWasPressed) {
        _setAllyCommand(AllyCommand.attack);
        print('[ALLY CMD] All allies: ATTACK');
      }
      _attackKeyWasPressed = attackPressed;

      // G key - Hold command (toggle)
      if (holdPressed && !_holdKeyWasPressed) {
        _setAllyCommand(AllyCommand.hold);
        print('[ALLY CMD] All allies: HOLD');
      }
      _holdKeyWasPressed = holdPressed;

      // R key - Cycle formation
      if (formationPressed && !_formationKeyWasPressed) {
        _cycleFormation();
      }
      _formationKeyWasPressed = formationPressed;
    }
  }

  /// Cycle through available formations
  void _cycleFormation() {
    final formations = FormationType.values;
    final currentIndex = formations.indexOf(gameState.currentFormation);
    final nextIndex = (currentIndex + 1) % formations.length;
    gameState.currentFormation = formations[nextIndex];
    gameState.invalidateTacticalPositions();
    print('[FORMATION] Changed to: ${gameState.currentFormation.name}');
  }

  /// Set command for all allies
  void _setAllyCommand(AllyCommand command) {
    setState(() {
      for (final ally in gameState.allies) {
        // If same command, toggle it off
        if (ally.currentCommand == command) {
          ally.currentCommand = AllyCommand.none;
          ally.movementMode = AllyMovementMode.followPlayer;
        } else {
          ally.currentCommand = command;
          ally.commandTimer = 0.0;
        }
      }
    });
  }

  /// Get the current command active across allies (for UI display)
  AllyCommand _getCurrentAllyCommand() {
    if (gameState.allies.isEmpty) return AllyCommand.none;
    // Return the first non-none command, or none if all allies have none
    for (final ally in gameState.allies) {
      if (ally.currentCommand != AllyCommand.none) {
        return ally.currentCommand;
      }
    }
    return AllyCommand.none;
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
    final projectileMesh = Mesh.cube(
      size: shadowBolt.projectileSize,
      color: shadowBolt.color,
    );
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

  /// Change an ally's strategy
  void _changeAllyStrategy(Ally ally, AllyStrategyType newStrategy) {
    setState(() {
      ally.strategyType = newStrategy;
      // Update follow distance based on new strategy
      ally.followBufferDistance = ally.strategy.followDistance;
      print('Ally strategy changed to: ${ally.strategy.name}');
    });
  }

  /// Change the formation type for all allies
  void _changeFormation(FormationType newFormation) {
    setState(() {
      gameState.currentFormation = newFormation;
      gameState.invalidateTacticalPositions();
      print('[FORMATION] Changed to: ${newFormation.name}');
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

      // Calculate ally position with terrain height
      final allyX = gameState.playerTransform != null
          ? gameState.playerTransform!.position.x + offsetX
          : 2.0 + offsetX;
      final allyZ = gameState.playerTransform != null
          ? gameState.playerTransform!.position.z + offsetZ
          : 2.0 + offsetZ;

      // Get terrain height at ally position
      double allyY = 0.4;
      if (gameState.infiniteTerrainManager != null) {
        allyY = gameState.infiniteTerrainManager!.getTerrainHeight(allyX, allyZ);
      }

      final allyPosition = Vector3(allyX, allyY, allyZ);

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

            // Player HUD
            Positioned(
              top: UIConfig.playerHudTop,
              right: UIConfig.playerHudRight,
              child: PlayerHud(
                gameState: gameState,
                onAbility1Pressed: _activateAbility1,
                onAbility2Pressed: _activateAbility2,
                onAbility3Pressed: _activateAbility3,
                onAbility4Pressed: _activateAbility4,
              ),
            ),

            // Allies Panel
            AlliesPanel(
              allies: gameState.allies,
              onActivateAllyAbility: _activateAllyAbility,
              onStrategyChanged: _changeAllyStrategy,
              onAddAlly: _addAlly,
              onRemoveAlly: _removeAlly,
            ),

            // ========== DRAGGABLE ALLY COMMAND PANELS ==========

            // Formation Panel (SHIFT+R to toggle)
            if (gameState.allies.isNotEmpty && _showFormationPanel)
              DraggablePanel(
                initialPosition: Offset(MediaQuery.of(context).size.width - 200, 260),
                onClose: () => setState(() => _showFormationPanel = false),
                child: FormationSelector(
                  currentFormation: gameState.currentFormation,
                  onFormationChanged: _changeFormation,
                ),
              ),

            // Attack Command Panel (SHIFT+T to toggle)
            if (gameState.allies.isNotEmpty && _showAttackPanel)
              DraggablePanel(
                initialPosition: _attackPanelPosition,
                onClose: () => setState(() => _showAttackPanel = false),
                child: AttackCommandPanel(
                  currentCommand: _getCurrentAllyCommand(),
                  onActivate: () => _setAllyCommand(AllyCommand.attack),
                  allyCount: gameState.allies.length,
                ),
              ),

            // Follow Command Panel (SHIFT+F to toggle)
            if (gameState.allies.isNotEmpty && _showFollowPanel)
              DraggablePanel(
                initialPosition: _followPanelPosition,
                onClose: () => setState(() => _showFollowPanel = false),
                child: FollowCommandPanel(
                  currentCommand: _getCurrentAllyCommand(),
                  onActivate: () => _setAllyCommand(AllyCommand.follow),
                  allyCount: gameState.allies.length,
                ),
              ),

            // Hold Command Panel (SHIFT+G to toggle)
            if (gameState.allies.isNotEmpty && _showHoldPanel)
              DraggablePanel(
                initialPosition: _holdPanelPosition,
                onClose: () => setState(() => _showHoldPanel = false),
                child: HoldCommandPanel(
                  currentCommand: _getCurrentAllyCommand(),
                  onActivate: () => _setAllyCommand(AllyCommand.hold),
                  allyCount: gameState.allies.length,
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
