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
import '../models/monster.dart';
import '../models/monster_ontology.dart';
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
import 'ui/character_panel.dart';
import 'ui/bag_panel.dart';
import 'ui/dps_panel.dart';
import 'ui/cast_bar.dart';
import 'ui/mana_bar.dart';
import 'ui/damage_indicators.dart';
import 'ui/unit_frames/unit_frames.dart';
import '../models/target_dummy.dart';
import '../main.dart' show globalInterfaceConfig;
import 'state/action_bar_config.dart';
import 'state/ability_override_manager.dart';
import 'state/mana_config.dart';
import 'state/custom_options_manager.dart';
import 'state/custom_ability_manager.dart';

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

    // Initialize action bar config for ability slot assignments
    _initializeActionBarConfig();

    // Initialize ability override manager for custom ability edits
    _initializeAbilityOverrides();

    // Initialize mana config (JSON defaults + SharedPreferences overrides)
    _initializeManaConfig();

    // Initialize custom options manager (custom dropdown values + effect descriptions)
    _initializeCustomOptions();

    // Initialize custom ability manager (user-created abilities)
    _initializeCustomAbilities();

    // Initialize player inventory with sample items
    _initializeInventory();

    // Create canvas element immediately
    _initializeGame();
  }

  /// Initialize the global action bar configuration
  void _initializeActionBarConfig() {
    globalActionBarConfig ??= ActionBarConfig();
    globalActionBarConfig!.loadConfig();
  }

  /// Initialize the global ability override manager
  void _initializeAbilityOverrides() {
    globalAbilityOverrideManager ??= AbilityOverrideManager();
    globalAbilityOverrideManager!.loadOverrides();
  }

  /// Initialize the global mana configuration (JSON defaults + overrides)
  void _initializeManaConfig() {
    globalManaConfig ??= ManaConfig();
    globalManaConfig!.initialize();
  }

  /// Initialize the global custom options manager (dropdown values + effect descriptions)
  void _initializeCustomOptions() {
    globalCustomOptionsManager ??= CustomOptionsManager();
    globalCustomOptionsManager!.initialize();
  }

  /// Initialize the global custom ability manager (user-created abilities)
  void _initializeCustomAbilities() {
    globalCustomAbilityManager ??= CustomAbilityManager();
    globalCustomAbilityManager!.loadAbilities();
  }

  /// Initialize player inventory with sample items from database
  void _initializeInventory() {
    gameState.initializeInventory().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
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

      // Spawn minions (8 Goblin Rogues, 4 Orc Warlocks, 2 Cultist Priests, 1 Skeleton Champion)
      gameState.spawnMinions(gameState.infiniteTerrainManager);

      // Initialize Ley Lines for mana regeneration
      gameState.initializeLeyLines(
        seed: 42,
        worldSize: 300.0,
        siteCount: 30,
      );

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
  /// Small buffer to ensure units are visually above terrain surface
  static const double _terrainBuffer = 0.15;

  void _adjustStartingPositionsToTerrain() {
    if (gameState.infiniteTerrainManager == null) return;

    // Force initial terrain chunk loading around starting positions
    // This ensures terrain exists before querying heights
    final playerPos = gameState.playerTransform?.position;
    if (playerPos != null) {
      gameState.infiniteTerrainManager!.update(playerPos, playerPos);
    }

    // Adjust player Y to terrain height (add half size + buffer so bottom sits above terrain)
    if (gameState.playerTransform != null) {
      final terrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(
        gameState.playerTransform!.position.x,
        gameState.playerTransform!.position.z,
      );
      gameState.playerTransform!.position.y = terrainHeight + GameConfig.playerSize / 2 + _terrainBuffer;
      print('[Game3D] Player starting height adjusted to terrain: $terrainHeight (mesh Y: ${gameState.playerTransform!.position.y})');
    }

    // Adjust monster Y to terrain height (add half size + buffer so bottom sits above terrain)
    if (gameState.monsterTransform != null) {
      final terrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(
        gameState.monsterTransform!.position.x,
        gameState.monsterTransform!.position.z,
      );
      gameState.monsterTransform!.position.y = terrainHeight + GameConfig.monsterSize / 2 + _terrainBuffer;

      // Direction indicator sits on top of the monster mesh
      if (gameState.monsterDirectionIndicatorTransform != null) {
        gameState.monsterDirectionIndicatorTransform!.position.y =
            gameState.monsterTransform!.position.y + GameConfig.monsterSize / 2 + 0.1;
      }
      print('[Game3D] Monster starting height adjusted to terrain: $terrainHeight (mesh Y: ${gameState.monsterTransform!.position.y})');
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

    // Update mana regeneration based on Ley Line proximity
    gameState.updateManaRegen(dt);

    // Update AI systems (monster AI, ally AI, projectiles)
    AISystem.update(
      dt,
      gameState,
      logMonsterAI: _logMonsterAI,
      activateMonsterAbility1: _activateMonsterAbility1,
      activateMonsterAbility2: _activateMonsterAbility2,
      activateMonsterAbility3: _activateMonsterAbility3,
    );

    // Handle player ability input (slots 1-10)
    AbilitySystem.handleAbility1Input(inputManager!.isActionPressed(GameAction.actionBar1), gameState);
    AbilitySystem.handleAbility2Input(inputManager!.isActionPressed(GameAction.actionBar2), gameState);
    AbilitySystem.handleAbility3Input(inputManager!.isActionPressed(GameAction.actionBar3), gameState);
    AbilitySystem.handleAbility4Input(inputManager!.isActionPressed(GameAction.actionBar4), gameState);
    AbilitySystem.handleAbility5Input(inputManager!.isActionPressed(GameAction.actionBar5), gameState);
    AbilitySystem.handleAbility6Input(inputManager!.isActionPressed(GameAction.actionBar6), gameState);
    AbilitySystem.handleAbility7Input(inputManager!.isActionPressed(GameAction.actionBar7), gameState);
    AbilitySystem.handleAbility8Input(inputManager!.isActionPressed(GameAction.actionBar8), gameState);
    AbilitySystem.handleAbility9Input(inputManager!.isActionPressed(GameAction.actionBar9), gameState);
    AbilitySystem.handleAbility10Input(inputManager!.isActionPressed(GameAction.actionBar10), gameState);
    // ===== END ABILITY SYSTEM =====

    // ===== ALLY COMMAND SYSTEM =====
    _handleAllyCommands();

    // Update direction indicator position and rotation to match player
    if (gameState.directionIndicatorTransform != null && gameState.playerTransform != null) {
      gameState.directionIndicatorTransform!.position.x = gameState.playerTransform!.position.x;
      // Direction indicator sits on top of the player mesh (position.y is already at mesh center)
      gameState.directionIndicatorTransform!.position.y =
          gameState.playerTransform!.position.y + GameConfig.playerSize / 2 + 0.1;
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

    // Update floating damage indicators
    updateDamageIndicators(gameState.damageIndicators, dt);

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

  /// Check if a text input field currently has focus.
  /// EditableText is the inner widget that TextField/TextFormField use for input.
  bool _isTextFieldFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final context = focus.context;
    if (context == null) return false;
    // The focused widget itself is EditableText when a TextField has focus
    if (context.widget is EditableText) return true;
    // Also check ancestors in case focus is on a child of EditableText
    bool found = false;
    context.visitAncestorElements((element) {
      if (element.widget is EditableText) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  void _onKeyEvent(KeyEvent event) {
    // Handle P key for abilities modal (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyP) {
      print('P key detected! Toggling abilities modal.');
      setState(() {
        gameState.abilitiesModalOpen = !gameState.abilitiesModalOpen;
      });
      return;
    }

    // Handle C key for character panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      print('C key detected! Toggling character panel.');
      setState(() {
        gameState.characterPanelOpen = !gameState.characterPanelOpen;
      });
      return;
    }

    // Handle B key for bag panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyB) {
      print('B key detected! Toggling bag panel.');
      setState(() {
        gameState.bagPanelOpen = !gameState.bagPanelOpen;
      });
      return;
    }

    // Handle SHIFT+D for DPS testing panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyD) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if (isShiftPressed) {
        print('SHIFT+D detected! Toggling DPS panel.');
        setState(() {
          gameState.dpsPanelOpen = !gameState.dpsPanelOpen;
          if (gameState.dpsPanelOpen) {
            // Spawn target dummy when opening DPS panel
            gameState.spawnTargetDummy(gameState.infiniteTerrainManager);
            // Auto-target the dummy
            gameState.setTarget(TargetDummy.instanceId);
          } else {
            // Despawn target dummy when closing DPS panel
            gameState.despawnTargetDummy();
            // Clear target if it was the dummy
            if (gameState.currentTargetId == TargetDummy.instanceId) {
              gameState.clearTarget();
            }
          }
        });
        return;
      }
    }

    // Handle Tab/Shift+Tab for target cycling (WoW-style)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      final playerX = gameState.playerTransform?.position.x ?? 0.0;
      final playerZ = gameState.playerTransform?.position.z ?? 0.0;
      final playerRotation = gameState.playerTransform?.rotation.y ?? 0.0;

      setState(() {
        gameState.tabToNextTarget(playerX, playerZ, playerRotation, reverse: isShiftPressed);
        final target = gameState.getCurrentTarget();
        if (target != null) {
          final name = target['type'] == 'boss' ? 'Boss Monster' :
            (target['entity'] as Monster?)?.definition.name ?? 'Unknown';
          debugPrint('Tab target: $name (${isShiftPressed ? "reverse" : "forward"})');
        } else {
          debugPrint('No targets available');
        }
      });
      return;
    }

    // Handle Escape key to close any open modal/panel or clear target
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (gameState.abilitiesModalOpen) {
        setState(() {
          gameState.abilitiesModalOpen = false;
        });
        return;
      }
      if (gameState.characterPanelOpen) {
        setState(() {
          gameState.characterPanelOpen = false;
        });
        return;
      }
      if (gameState.bagPanelOpen) {
        setState(() {
          gameState.bagPanelOpen = false;
        });
        return;
      }
      if (gameState.dpsPanelOpen) {
        setState(() {
          gameState.dpsPanelOpen = false;
          gameState.despawnTargetDummy();
          if (gameState.currentTargetId == TargetDummy.instanceId) {
            gameState.clearTarget();
          }
        });
        return;
      }
      // Clear target if no modal is open
      if (gameState.currentTargetId != null) {
        setState(() {
          gameState.clearTarget();
          debugPrint('Target cleared');
        });
        return;
      }
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

  void _activateAbility5() {
    setState(() {
      AbilitySystem.handleAbility5Input(true, gameState);
    });
  }

  void _activateAbility6() {
    setState(() {
      AbilitySystem.handleAbility6Input(true, gameState);
    });
  }

  void _activateAbility7() {
    setState(() {
      AbilitySystem.handleAbility7Input(true, gameState);
    });
  }

  void _activateAbility8() {
    setState(() {
      AbilitySystem.handleAbility8Input(true, gameState);
    });
  }

  void _activateAbility9() {
    setState(() {
      AbilitySystem.handleAbility9Input(true, gameState);
    });
  }

  void _activateAbility10() {
    setState(() {
      AbilitySystem.handleAbility10Input(true, gameState);
    });
  }

  /// Handle ability dropped from Abilities Codex onto action bar slot
  void _handleAbilityDropped(int slotIndex, String abilityName) {
    final config = globalActionBarConfig;
    if (config != null) {
      config.setSlotAbility(slotIndex, abilityName);
      print('[ActionBar] Assigned "$abilityName" to slot ${slotIndex + 1}');
      setState(() {}); // Refresh UI to show new ability
    }
  }

  // ===== ALLY COMMAND METHODS =====

  /// Track previous command key states to detect key press (not hold)
  bool _followKeyWasPressed = false;
  bool _attackKeyWasPressed = false;
  bool _holdKeyWasPressed = false;
  bool _formationKeyWasPressed = false;

  /// Default positions for draggable panels (used if config not available)
  static const Map<String, Offset> _defaultPositions = {
    'instructions': Offset(10, 10),
    'combat_hud': Offset(300, 500),
    'monster_abilities': Offset(10, 300),
    'ai_chat': Offset(10, 450),
    'formation_panel': Offset(800, 150),
    'attack_panel': Offset(800, 260),
    'hold_panel': Offset(800, 370),
    'follow_panel': Offset(800, 480),
  };

  /// Track SHIFT+key states for panel toggling
  bool _shiftFollowWasPressed = false;
  bool _shiftAttackWasPressed = false;
  bool _shiftHoldWasPressed = false;
  bool _shiftFormationWasPressed = false;

  /// Drag state tracking for panels - used to prevent micro-drags from interfering with taps
  final Map<String, bool> _isDragging = {};
  final Map<String, Offset> _dragStartPos = {};
  static const double _dragThreshold = 5.0; // Pixels before drag activates

  /// Check if an interface is visible (defaults to true if config not available)
  bool _isVisible(String id) {
    return globalInterfaceConfig?.isVisible(id) ?? true;
  }

  /// Get position for an interface (from config manager or defaults)
  Offset _getPos(String id) {
    return globalInterfaceConfig?.getPosition(id) ?? _defaultPositions[id] ?? Offset.zero;
  }

  /// Update position for an interface (saves to config manager)
  void _updatePos(String id, Offset delta, Size screenSize, Size widgetSize) {
    Offset current = _getPos(id);
    double newX = (current.dx + delta.dx).clamp(0.0, screenSize.width - widgetSize.width);
    double newY = (current.dy + delta.dy).clamp(0.0, screenSize.height - widgetSize.height);
    globalInterfaceConfig?.setPosition(id, Offset(newX, newY));
  }

  /// Build a draggable panel (like AbilitiesModal pattern)
  Widget _draggable(String id, Widget child, {double width = 200, double height = 100}) {
    final pos = _getPos(id);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      // Use Listener for drag to avoid gesture arena conflicts with child buttons
      child: Listener(
        behavior: HitTestBehavior.translucent, // Allow children to also receive hit tests
        onPointerDown: (event) {
          // Record drag start position
          _isDragging[id] = false;
          _dragStartPos[id] = event.position;
        },
        onPointerMove: (event) {
          // Only process drag when primary button (left mouse) is pressed
          if (event.buttons == 1) {
            final startPos = _dragStartPos[id];
            if (startPos != null) {
              // Check if we've exceeded the drag threshold
              if (!(_isDragging[id] ?? false)) {
                final distance = (event.position - startPos).distance;
                if (distance >= _dragThreshold) {
                  _isDragging[id] = true;
                }
              }
              // Only apply movement if we're in drag mode
              if (_isDragging[id] ?? false) {
                _updatePos(id, event.delta, MediaQuery.of(context).size, Size(width, height));
              }
            }
          }
        },
        onPointerUp: (event) {
          // Reset drag state
          _isDragging[id] = false;
          _dragStartPos.remove(id);
        },
        onPointerCancel: (event) {
          // Reset drag state
          _isDragging[id] = false;
          _dragStartPos.remove(id);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: child,
        ),
      ),
    );
  }

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
        globalInterfaceConfig?.toggleVisibility('follow_panel');
      });
      print('[UI] Follow panel: ${_isVisible('follow_panel') ? "shown" : "hidden"}');
    }
    _shiftFollowWasPressed = shiftPressed && followPressed;

    // SHIFT+T - Toggle Attack panel
    if (shiftPressed && attackPressed && !_shiftAttackWasPressed) {
      setState(() {
        globalInterfaceConfig?.toggleVisibility('attack_panel');
      });
      print('[UI] Attack panel: ${_isVisible('attack_panel') ? "shown" : "hidden"}');
    }
    _shiftAttackWasPressed = shiftPressed && attackPressed;

    // SHIFT+G - Toggle Hold panel
    if (shiftPressed && holdPressed && !_shiftHoldWasPressed) {
      setState(() {
        globalInterfaceConfig?.toggleVisibility('hold_panel');
      });
      print('[UI] Hold panel: ${_isVisible('hold_panel') ? "shown" : "hidden"}');
    }
    _shiftHoldWasPressed = shiftPressed && holdPressed;

    // SHIFT+R - Toggle Formation panel
    if (shiftPressed && formationPressed && !_shiftFormationWasPressed) {
      setState(() {
        globalInterfaceConfig?.toggleVisibility('formation_panel');
      });
      print('[UI] Formation panel: ${_isVisible('formation_panel') ? "shown" : "hidden"}');
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
    debugPrint('_addAlly called! Current allies: ${gameState.allies.length}');
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

      // Get terrain height at ally position (add half size so bottom sits on terrain)
      const double allySize = 0.8;
      double allyY = 0.4 + allySize / 2 + _terrainBuffer; // Default fallback
      if (gameState.infiniteTerrainManager != null) {
        final terrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(allyX, allyZ);
        allyY = terrainHeight + allySize / 2 + _terrainBuffer;
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
        // Let text fields handle their own input
        if (_isTextFieldFocused()) {
          return KeyEventResult.ignored;
        }
        _onKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Container(
        color: Colors.transparent, // Transparent to show canvas behind
        child: Stack(
          children: [
            // Canvas will be created and appended to body in initState
            SizedBox.expand(),

            // Floating damage indicators (world-space positioned)
            DamageIndicatorOverlay(
              indicators: gameState.damageIndicators,
              camera: camera,
              canvasWidth: 1600,
              canvasHeight: 900,
            ),

            // Instructions overlay (draggable)
            if (_isVisible('instructions'))
              _draggable('instructions',
                InstructionsOverlay(
                  camera: camera,
                  gameState: gameState,
                ),
                width: 220, height: 200,
              ),

            // ========== NEW WOW-STYLE UNIT FRAMES (All Draggable) ==========

            // Combat HUD (draggable) - Row with fixed-width side panels
            if (_isVisible('combat_hud'))
              _draggable('combat_hud',
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end, // Bottom-align all
                  children: [
                    // Party section - fixed width container so CombatHUD doesn't shift
                    if (_isVisible('party_frames'))
                      SizedBox(
                        width: 172, // Fixed width: buttons (~160) + padding (12)
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          verticalDirection: VerticalDirection.up, // Grow upward
                          children: [
                            // Bottom: Ally control buttons (always at bottom-right of this section)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildAllyControlButton(
                                    icon: Icons.add,
                                    label: '+Ally',
                                    color: const Color(0xFF4CAF50),
                                    onPressed: _addAlly,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildAllyControlButton(
                                    icon: Icons.remove,
                                    label: '-Ally',
                                    color: const Color(0xFFEF5350),
                                    onPressed: _removeAlly,
                                  ),
                                ],
                              ),
                            ),
                            // Party frames above buttons (grows upward)
                            if (gameState.allies.isNotEmpty)
                              const SizedBox(height: 6),
                            if (gameState.allies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: PartyFrames(
                                  allies: gameState.allies,
                                  onAllySelected: (index) {
                                    print('Ally $index selected');
                                  },
                                  onAllyAbilityActivate: _activateAllyAbility,
                                ),
                              ),
                          ],
                        ),
                      ),
                    // CombatHUD - center anchor
                    _buildCombatHUD(),
                    // Minion section - fixed width container
                    if (_isVisible('minion_frames'))
                      SizedBox(
                        width: 172, // Fixed width to match party section
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          verticalDirection: VerticalDirection.up, // Grow upward
                          children: [
                            // Minion frames (grows upward from bottom)
                            if (gameState.minions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: MinionFrames(
                                  minions: gameState.minions,
                                  targetedMinionId: gameState.currentTargetId,
                                  onMinionSelected: (index) {
                                    // Set the clicked minion as current target
                                    if (index < gameState.minions.length) {
                                      final minion = gameState.minions[index];
                                      setState(() {
                                        gameState.setTarget(minion.instanceId);
                                        debugPrint('Targeted minion: ${minion.definition.name}');
                                      });
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                width: 400, height: 180,
              ),

            // Boss/Target abilities panel (draggable)
            if (_isVisible('monster_abilities'))
              _draggable('monster_abilities',
                TargetFrame(
                  name: 'Boss Monster',
                  health: gameState.monsterHealth,
                  maxHealth: gameState.monsterMaxHealth.toDouble(),
                  level: 15,
                  subtitle: 'Elite',
                  isPaused: gameState.monsterPaused,
                  isTargeted: gameState.currentTargetId == 'boss',
                  portraitWidget: const CubePortrait(
                    color: Color(0xFF9933CC),
                    size: 24,
                    hasDirectionIndicator: true,
                    indicatorColor: Colors.green,
                  ),
                  onTap: () {
                    setState(() {
                      gameState.setTarget('boss');
                      debugPrint('Targeted: Boss Monster');
                    });
                  },
                  onPauseToggle: () {
                    setState(() {
                      gameState.monsterPaused = !gameState.monsterPaused;
                    });
                    print('Monster AI ${gameState.monsterPaused ? 'paused' : 'resumed'}');
                  },
                  abilities: [
                    AbilityButtonData(
                      label: 'M1',
                      color: const Color(0xFF8B4513),
                      cooldown: gameState.monsterAbility1Cooldown,
                      maxCooldown: gameState.monsterAbility1CooldownMax,
                      onPressed: _activateMonsterAbility1,
                    ),
                    AbilityButtonData(
                      label: 'M2',
                      color: const Color(0xFF4B0082),
                      cooldown: gameState.monsterAbility2Cooldown,
                      maxCooldown: gameState.monsterAbility2CooldownMax,
                      onPressed: _activateMonsterAbility2,
                    ),
                    AbilityButtonData(
                      label: 'M3',
                      color: const Color(0xFF006400),
                      cooldown: gameState.monsterAbility3Cooldown,
                      maxCooldown: gameState.monsterAbility3CooldownMax,
                      onPressed: _activateMonsterAbility3,
                    ),
                  ],
                ),
                width: 200, height: 120,
              ),

            // AI Chat Panel (draggable)
            if (_isVisible('ai_chat'))
              _draggable('ai_chat',
                AIChatPanel(
                  messages: gameState.monsterAIChat,
                ),
                width: 300, height: 200,
              ),

            // ========== ALLY COMMAND PANELS (Each Draggable) ==========
            // Formation Panel (draggable)
            if (gameState.allies.isNotEmpty && _isVisible('formation_panel'))
              _draggable('formation_panel',
                _buildCommandPanelWithClose(
                  child: FormationSelector(
                    currentFormation: gameState.currentFormation,
                    onFormationChanged: _changeFormation,
                  ),
                  onClose: () => globalInterfaceConfig?.setVisibility('formation_panel', false),
                ),
                width: 180, height: 100,
              ),

            // Attack Panel (draggable)
            if (gameState.allies.isNotEmpty && _isVisible('attack_panel'))
              _draggable('attack_panel',
                _buildCommandPanelWithClose(
                  child: AttackCommandPanel(
                    currentCommand: _getCurrentAllyCommand(),
                    onActivate: () => _setAllyCommand(AllyCommand.attack),
                    allyCount: gameState.allies.length,
                  ),
                  onClose: () => globalInterfaceConfig?.setVisibility('attack_panel', false),
                ),
                width: 140, height: 80,
              ),

            // Hold Panel (draggable)
            if (gameState.allies.isNotEmpty && _isVisible('hold_panel'))
              _draggable('hold_panel',
                _buildCommandPanelWithClose(
                  child: HoldCommandPanel(
                    currentCommand: _getCurrentAllyCommand(),
                    onActivate: () => _setAllyCommand(AllyCommand.hold),
                    allyCount: gameState.allies.length,
                  ),
                  onClose: () => globalInterfaceConfig?.setVisibility('hold_panel', false),
                ),
                width: 140, height: 80,
              ),

            // Follow Panel (draggable)
            if (gameState.allies.isNotEmpty && _isVisible('follow_panel'))
              _draggable('follow_panel',
                _buildCommandPanelWithClose(
                  child: FollowCommandPanel(
                    currentCommand: _getCurrentAllyCommand(),
                    onActivate: () => _setAllyCommand(AllyCommand.follow),
                    allyCount: gameState.allies.length,
                  ),
                  onClose: () => globalInterfaceConfig?.setVisibility('follow_panel', false),
                ),
                width: 140, height: 80,
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

            // Character Panel (Press C to toggle)
            if (gameState.characterPanelOpen)
              CharacterPanel(
                gameState: gameState,
                onClose: () {
                  setState(() {
                    gameState.characterPanelOpen = false;
                  });
                },
              ),

            // Bag Panel (Press B to toggle)
            if (gameState.bagPanelOpen)
              BagPanel(
                inventory: gameState.playerInventory,
                onClose: () {
                  setState(() {
                    gameState.bagPanelOpen = false;
                  });
                },
                onItemClick: (index, item) {
                  if (item != null) {
                    print('[Bag] Clicked item at slot $index: ${item.name}');
                    // TODO: Implement item use/equip functionality
                  }
                },
              ),

            // DPS Panel (Press SHIFT+D to toggle)
            if (gameState.dpsPanelOpen)
              DpsPanel(
                dpsTracker: gameState.dpsTracker,
                onClose: () {
                  setState(() {
                    gameState.dpsPanelOpen = false;
                    gameState.despawnTargetDummy();
                    if (gameState.currentTargetId == TargetDummy.instanceId) {
                      gameState.clearTarget();
                    }
                  });
                },
              ),

            // Cast Bar (shows when casting or winding up)
            CastBar(gameState: gameState),
          ],
        ),
      ),
    );
  }

  /// Get target data for current target (for CombatHUD)
  Map<String, dynamic> _getTargetData() {
    final target = gameState.getCurrentTarget();

    if (target == null) {
      // No target selected
      return {
        'hasTarget': false,
        'name': null,
        'health': 0.0,
        'maxHealth': 1.0,
        'level': null,
        'color': const Color(0xFF666666),
      };
    }

    if (target['type'] == 'boss') {
      return {
        'hasTarget': true,
        'name': 'Boss Monster',
        'health': gameState.monsterHealth,
        'maxHealth': gameState.monsterMaxHealth.toDouble(),
        'level': 15,
        'color': const Color(0xFF9933CC), // Purple for boss
      };
    } else if (target['type'] == 'dummy') {
      final dummy = gameState.targetDummy;
      return {
        'hasTarget': true,
        'name': 'Target Dummy',
        'health': dummy?.displayHealth ?? 100000,
        'maxHealth': dummy?.maxHealth ?? 100000,
        'level': 0,
        'color': const Color(0xFFC19A6B), // Burlywood/wooden color
      };
    } else {
      final minion = target['entity'] as Monster?;
      if (minion == null) {
        return {
          'hasTarget': false,
          'name': null,
          'health': 0.0,
          'maxHealth': 1.0,
          'level': null,
          'color': const Color(0xFF666666),
        };
      }

      // Get color based on archetype
      Color archetypeColor;
      switch (minion.definition.archetype) {
        case MonsterArchetype.dps:
          archetypeColor = const Color(0xFFFF6B6B); // Red
          break;
        case MonsterArchetype.support:
          archetypeColor = const Color(0xFF9933FF); // Purple
          break;
        case MonsterArchetype.healer:
          archetypeColor = const Color(0xFF66CC66); // Green
          break;
        case MonsterArchetype.tank:
          archetypeColor = const Color(0xFFFFAA33); // Orange
          break;
        case MonsterArchetype.boss:
          archetypeColor = const Color(0xFFFF0000); // Bright red
          break;
      }

      return {
        'hasTarget': true,
        'name': minion.definition.name,
        'health': minion.health,
        'maxHealth': minion.maxHealth,
        'level': minion.definition.monsterPower,
        'color': archetypeColor,
      };
    }
  }

  /// Get target-of-target info
  String? _getTargetOfTargetInfo() {
    final tot = gameState.getTargetOfTarget();
    if (tot == null) return null;

    if (tot == 'player') return 'You';
    if (tot == 'none') return null;

    // Check if it's an ally (allies are identified by index like "ally_0", "ally_1")
    if (tot.startsWith('ally_')) {
      final index = int.tryParse(tot.substring(5));
      if (index != null && index < gameState.allies.length) {
        return 'Ally ${index + 1}';
      }
    }

    // Check if it's a minion
    final minion = gameState.minions.where((m) => m.instanceId == tot).firstOrNull;
    if (minion != null) return minion.definition.name;

    return tot;
  }

  /// Build Combat HUD with current target data
  Widget _buildCombatHUD() {
    final targetData = _getTargetData();
    final totInfo = _getTargetOfTargetInfo();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CombatHUD(
          playerName: 'Warchief',
          playerHealth: gameState.playerHealth,
          playerMaxHealth: gameState.playerMaxHealth,
          playerLevel: 10,
          playerPortraitWidget: const CubePortrait(
            color: Color(0xFF4D80CC),
            size: 36,
            hasDirectionIndicator: true,
            indicatorColor: Colors.red,
          ),
          gameState: gameState, // For mana bar display
          targetName: targetData['name'] as String?,
          targetHealth: targetData['health'] as double,
          targetMaxHealth: targetData['maxHealth'] as double,
          targetLevel: targetData['level'] as int?,
          hasTarget: targetData['hasTarget'] as bool,
          targetPortraitWidget: targetData['hasTarget'] as bool
              ? CubePortrait(
                  color: targetData['color'] as Color,
                  size: 36,
                  hasDirectionIndicator: true,
                  indicatorColor: Colors.green,
                )
              : null,
          ability1Cooldown: gameState.ability1Cooldown,
          ability1CooldownMax: gameState.ability1CooldownMax,
          ability2Cooldown: gameState.ability2Cooldown,
          ability2CooldownMax: gameState.ability2CooldownMax,
          ability3Cooldown: gameState.ability3Cooldown,
          ability3CooldownMax: gameState.ability3CooldownMax,
          ability4Cooldown: gameState.ability4Cooldown,
          ability4CooldownMax: gameState.ability4CooldownMax,
          ability5Cooldown: gameState.ability5Cooldown,
          ability5CooldownMax: gameState.ability5CooldownMax,
          ability6Cooldown: gameState.ability6Cooldown,
          ability6CooldownMax: gameState.ability6CooldownMax,
          ability7Cooldown: gameState.ability7Cooldown,
          ability7CooldownMax: gameState.ability7CooldownMax,
          ability8Cooldown: gameState.ability8Cooldown,
          ability8CooldownMax: gameState.ability8CooldownMax,
          ability9Cooldown: gameState.ability9Cooldown,
          ability9CooldownMax: gameState.ability9CooldownMax,
          ability10Cooldown: gameState.ability10Cooldown,
          ability10CooldownMax: gameState.ability10CooldownMax,
          onAbility1Pressed: _activateAbility1,
          onAbility2Pressed: _activateAbility2,
          onAbility3Pressed: _activateAbility3,
          onAbility4Pressed: _activateAbility4,
          onAbility5Pressed: _activateAbility5,
          onAbility6Pressed: _activateAbility6,
          onAbility7Pressed: _activateAbility7,
          onAbility8Pressed: _activateAbility8,
          onAbility9Pressed: _activateAbility9,
          onAbility10Pressed: _activateAbility10,
          actionBarConfig: globalActionBarConfig,
          onAbilityDropped: _handleAbilityDropped,
        ),
        // Target of Target display
        if (targetData['hasTarget'] as bool && totInfo != null)
          _buildTargetOfTarget(totInfo),
      ],
    );
  }

  /// Build Target of Target (ToT) display
  Widget _buildTargetOfTarget(String totName) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF252542),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_forward,
            size: 12,
            color: Color(0xFF888888),
          ),
          const SizedBox(width: 4),
          const Text(
            'Target:',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            totName,
            style: TextStyle(
              color: totName == 'You' ? const Color(0xFFFF6B6B) : const Color(0xFFCCCCCC),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build ally control button (+/- ally)
  Widget _buildAllyControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('Button "$label" tapped!');
          onPressed();
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build command panel with close button
  Widget _buildCommandPanelWithClose({
    required Widget child,
    required VoidCallback onClose,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF252542),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Close button row
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 2),
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFFF6B6B),
                  size: 12,
                ),
              ),
            ),
          ),
          // Panel content
          child,
        ],
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
