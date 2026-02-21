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
import '../models/item.dart';
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
import 'ui/ally_commands_panel.dart';
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
import 'state/item_config.dart';
import 'state/custom_item_manager.dart';
import 'state/wind_config.dart';
import 'state/wind_state.dart';
import 'state/minimap_config.dart';
import 'state/minimap_state.dart';
import 'state/building_config.dart';
import 'state/goals_config.dart';
import 'state/macro_config.dart';
import 'state/macro_manager.dart';
import 'state/gameplay_settings.dart';
import 'data/stances/stances.dart';
import 'ui/minimap/minimap_widget.dart';
import 'ui/minimap/minimap_ping_overlay.dart';
import 'ui/building_panel.dart';
import 'ui/goals_panel.dart';
import 'ui/warrior_spirit_panel.dart';
import 'ui/chat_panel.dart';
import 'ui/stance_selector.dart';
import 'ui/stance_effects_overlay.dart';
import 'ui/macro_builder_panel.dart';
import 'systems/entity_picking_system.dart';
import 'systems/building_system.dart';
import 'systems/goal_system.dart';
import 'systems/macro_system.dart';
import 'ai/warrior_spirit.dart';
import 'effects/aura_system.dart';
// Note: WindIndicator replaced by minimap border wind arrow

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

  // Reason: explicit FocusNode so we can reclaim keyboard focus from text fields
  // after the user interacts with editor panels or clicks on the game world.
  final FocusNode _gameFocusNode = FocusNode(debugLabel: 'Game3D');

  @override
  void initState() {
    super.initState();
    canvasId = 'game3d_canvas_${DateTime.now().millisecondsSinceEpoch}';

    // Initialize input manager
    inputManager = InputManager();

    // Initialize Ollama client for AI
    ollamaClient = OllamaClient();

    // Initialize game config (JSON defaults + SharedPreferences overrides)
    _initializeGameConfig();

    // Initialize action bar config for ability slot assignments
    _initializeActionBarConfig();

    // Initialize ability override manager for custom ability edits
    _initializeAbilityOverrides();

    // Initialize mana config (JSON defaults + SharedPreferences overrides)
    _initializeManaConfig();

    // Initialize wind config (JSON defaults for wind simulation)
    _initializeWindConfig();

    // Initialize minimap config (JSON defaults for minimap display)
    _initializeMinimapConfig();

    // Initialize building config (JSON defaults for building definitions)
    _initializeBuildingConfig();

    // Initialize custom options manager (custom dropdown values + effect descriptions)
    _initializeCustomOptions();

    // Initialize custom ability manager (user-created abilities)
    _initializeCustomAbilities();

    // Initialize item config (power level weights, sentience thresholds)
    _initializeItemConfig();

    // Initialize custom item manager (user-created items)
    _initializeCustomItems();

    // Initialize goals config (JSON defaults for goal definitions)
    _initializeGoalsConfig();

    // Initialize macro config and manager (macro system)
    _initializeMacroConfig();

    // Initialize gameplay settings (attunement toggles, etc.)
    _initializeGameplaySettings();

    // Initialize stance registry (JSON definitions for exotic stances)
    _initializeStanceRegistry();

    // Initialize stance override manager for custom stance edits
    _initializeStanceOverrides();

    // Initialize player inventory with sample items
    _initializeInventory();

    // Create canvas element immediately
    _initializeGame();
  }

  /// Initialize the global game configuration (JSON defaults + overrides)
  void _initializeGameConfig() {
    globalGameConfig ??= GameConfig();
    globalGameConfig!.initialize();
  }

  /// Initialize the global action bar configuration manager
  void _initializeActionBarConfig() {
    globalActionBarConfigManager ??= ActionBarConfigManager();
    // Pre-load Warchief config (index 0)
    globalActionBarConfigManager!.getConfig(0);
  }

  /// Initialize the global ability override manager
  void _initializeAbilityOverrides() {
    globalAbilityOverrideManager ??= AbilityOverrideManager();
    globalAbilityOverrideManager!.loadOverrides();
  }

  /// Initialize the global stance override manager
  void _initializeStanceOverrides() {
    globalStanceOverrideManager ??= StanceOverrideManager();
    globalStanceOverrideManager!.loadOverrides();
  }

  /// Initialize the global mana configuration (JSON defaults + overrides)
  void _initializeManaConfig() {
    globalManaConfig ??= ManaConfig();
    globalManaConfig!.initialize();
  }

  /// Initialize the global wind configuration and state (JSON defaults)
  void _initializeWindConfig() {
    globalWindConfig ??= WindConfig();
    globalWindConfig!.initialize();
    globalWindState ??= WindState();
  }

  /// Initialize the global minimap configuration (JSON defaults)
  void _initializeMinimapConfig() {
    globalMinimapConfig ??= MinimapConfig();
    globalMinimapConfig!.initialize();
  }

  /// Initialize the global building configuration (JSON defaults)
  void _initializeBuildingConfig() {
    globalBuildingConfig ??= BuildingConfig();
    globalBuildingConfig!.initialize().then((_) {
      // Spawn warchief's home after config is loaded
      gameState.spawnWarchiefHome(gameState.infiniteTerrainManager);
      if (mounted) setState(() {});
    });
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

  /// Initialize the global item config (power level weights, sentience thresholds)
  void _initializeItemConfig() {
    globalItemConfig ??= ItemConfig();
    globalItemConfig!.initialize();
  }

  /// Initialize the global custom item manager (user-created items)
  void _initializeCustomItems() {
    globalCustomItemManager ??= CustomItemManager();
    globalCustomItemManager!.loadItems();
  }

  /// Initialize the global goals configuration and Warrior Spirit
  void _initializeGoalsConfig() {
    globalGoalsConfig ??= GoalsConfig();
    globalGoalsConfig!.initialize().then((_) {
      // Initialize Warrior Spirit after goals config is loaded
      WarriorSpirit.init();
      if (mounted) setState(() {});
    });
  }

  /// Initialize macro config and macro manager
  void _initializeMacroConfig() {
    globalMacroConfig ??= MacroConfig();
    globalMacroConfig!.initialize();
    globalMacroManager ??= MacroManager();
    globalMacroManager!.loadMacros();
  }

  /// Initialize gameplay settings (attunement toggles, etc.)
  void _initializeGameplaySettings() {
    globalGameplaySettings ??= GameplaySettings();
    globalGameplaySettings!.load();
  }

  /// Initialize the global stance registry (JSON definitions)
  void _initializeStanceRegistry() {
    globalStanceRegistry ??= StanceRegistry();
    globalStanceRegistry!.initialize().then((_) {
      // Reason: load saved stance selections after registry is ready
      gameState.loadStanceConfig().then((_) {
        if (mounted) setState(() {});
      });
    });
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

      // Initialize player aura glow disc (reflects equipped ability categories)
      gameState.playerAuraTransform = Transform3d(
        position: Vector3(0, 0.02, 0),
        scale: Vector3(1, 1, 1),
      );
      _updatePlayerAuraColor();

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
    // lastTimestamp will be set on the first rAF callback
    gameState.lastTimestamp = null;
    print('Starting game loop...');

    void gameLoop(num timestamp) {
      if (!mounted) return;

      // Use the requestAnimationFrame timestamp (DOMHighResTimeStamp from
      // performance.now()) for dt calculation.  This is monotonic,
      // sub-millisecond precision, and synchronized with the display refresh
      // — unlike DateTime.now() which has only millisecond precision and can
      // drift due to NTP sync, privacy coarsening, or system clock changes.
      final tsMs = timestamp.toDouble();
      final dt = gameState.lastTimestamp != null
          ? ((tsMs - gameState.lastTimestamp!) / 1000.0).clamp(0.0, 0.1)
          : 0.016; // Default to ~60fps on first frame
      gameState.lastTimestamp = tsMs;

      gameState.frameCount++;

      // Log every 60 frames (~1 second at 60fps)
      if (gameState.frameCount % 60 == 0) {
        print('Frame ${gameState.frameCount} - dt: ${dt.toStringAsFixed(4)}s - Terrain: ${gameState.terrainTiles?.length ?? 0} tiles');
        // Reason: Periodic aura refresh catches all config change paths (drag-drop, load-class, character switch)
        _refreshAllAuraColors();
      }

      _update(dt, tsMs / 1000.0);
      _render();

      // Update UI — every frame during active casts/windups for smooth
      // progress bars, otherwise every 10 frames to reduce rebuild overhead
      final needsFrequentUiUpdate = gameState.isCasting || gameState.isWindingUp;
      if (mounted && (needsFrequentUiUpdate || gameState.frameCount % 10 == 0)) {
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

  void _update(double dt, double gameTimeSec) {
    if (inputManager == null || camera == null || gameState.activeTransform == null) return;

    // Refresh per-frame caches before any system reads them
    gameState.refreshAliveMinions();

    // Process player and camera input
    InputSystem.update(dt, inputManager!, camera!, gameState);

    // Handle jump input
    final jumpKeyIsPressed = inputManager!.isActionPressed(GameAction.jump);
    PhysicsSystem.handleJumpInput(jumpKeyIsPressed, gameState);

    // Update physics (gravity, vertical movement, ground collision)
    PhysicsSystem.update(dt, gameState);

    // Track player movement for AI prediction using rAF timestamp (no DateTime.now() overhead)
    if (gameState.playerTransform != null) {
      gameState.playerMovementTracker.update(
        gameState.playerTransform!.position,
        gameTimeSec,
      );
    }

    // Update infinite terrain (chunk loading/unloading based on active character position)
    if (gameState.infiniteTerrainManager != null && gameState.activeTransform != null && camera != null) {
      gameState.infiniteTerrainManager!.update(
        gameState.activeTransform!.position,
        camera!.position,
      );
    }

    // ===== ABILITY SYSTEM =====
    // Update player ability cooldowns and effects
    AbilitySystem.update(dt, gameState);

    // Update mana regeneration based on Ley Line proximity
    gameState.updateManaRegen(dt);

    // Update wind simulation and White Mana regeneration
    gameState.updateWindAndWhiteMana(dt);

    // Update green mana regeneration (grass proximity, ally proximity, spirit beings)
    gameState.updateGreenManaRegen(dt);

    // Tick and expire active status effects on all entities
    gameState.updateActiveEffects(dt);

    // Update stance timers (Fury drain, Drunken re-rolls, switch cooldown)
    gameState.updateStanceTimers(dt);

    // Apply building aura effects (health + mana regen near buildings)
    BuildingSystem.applyBuildingAuras(gameState, dt);

    // Update minimap state (elapsed time for sun orbits, ping decay)
    gameState.minimapState.update(dt);

    // Update Warrior Spirit (periodic goal suggestion check)
    WarriorSpirit.update(gameState, dt);

    // Update macro execution engine (spell rotations + raid chat alerts)
    MacroSystem.update(dt, gameState);

    // Track flight duration for mastery goals
    if (gameState.isFlying) {
      _flightDurationAccum += dt;
      GoalSystem.processEvent(gameState, 'flight_duration',
          metadata: {'value': _flightDurationAccum.toInt()});
    } else {
      _flightDurationAccum = 0;
    }

    // Track power node visits for exploration goals
    if (gameState.isOnPowerNode && gameState.playerTransform != null) {
      final px = gameState.playerTransform!.position.x;
      final pz = gameState.playerTransform!.position.z;
      final nodeKey = '${px.toInt()}_${pz.toInt()}';
      if (!gameState.visitedPowerNodes.contains(nodeKey)) {
        gameState.visitedPowerNodes.add(nodeKey);
        GoalSystem.processEvent(gameState, 'visit_power_node');
        print('[GOALS] Visited new power node: $nodeKey');
      }
    }

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

    // Update Warchief direction indicator position and rotation
    if (gameState.directionIndicatorTransform != null && gameState.playerTransform != null) {
      gameState.directionIndicatorTransform!.position.x = gameState.playerTransform!.position.x;
      gameState.directionIndicatorTransform!.position.y =
          gameState.playerTransform!.position.y + GameConfig.playerSize / 2 + 0.1;
      gameState.directionIndicatorTransform!.position.z = gameState.playerTransform!.position.z;
      gameState.directionIndicatorTransform!.rotation.y = gameState.playerRotation + 180;
    }

    // Update active ally direction indicator when controlling an ally
    if (!gameState.isWarchiefActive) {
      final activeAlly = gameState.activeAlly;
      if (activeAlly != null && activeAlly.directionIndicatorTransform != null) {
        activeAlly.directionIndicatorTransform!.position.x = activeAlly.transform.position.x;
        activeAlly.directionIndicatorTransform!.position.y =
            activeAlly.transform.position.y + 0.8 / 2 + 0.1;
        activeAlly.directionIndicatorTransform!.position.z = activeAlly.transform.position.z;
        activeAlly.directionIndicatorTransform!.rotation.y = activeAlly.rotation + 180;
      }
    }

    // Update shadow position, rotation, and scale based on active character height and light direction
    if (gameState.shadowTransform != null && gameState.activeTransform != null) {
      // Light direction (from upper-right-front) - normalized direction from where light is coming
      final lightDirX = 0.5; // Light from right
      final lightDirZ = 0.3; // Light from front

      // Calculate shadow offset based on character height above terrain (higher = further from character)
      final playerHeight = PhysicsSystem.getPlayerHeight(gameState);
      final shadowOffsetX = playerHeight * lightDirX;
      final shadowOffsetZ = playerHeight * lightDirZ;

      // Position shadow with offset from active character
      gameState.shadowTransform!.position.x = gameState.activeTransform!.position.x + shadowOffsetX;
      gameState.shadowTransform!.position.z = gameState.activeTransform!.position.z + shadowOffsetZ;

      // Set shadow Y to terrain height at shadow position (slightly above to avoid z-fighting)
      if (gameState.infiniteTerrainManager != null) {
        final shadowTerrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(
          gameState.shadowTransform!.position.x,
          gameState.shadowTransform!.position.z,
        );
        gameState.shadowTransform!.position.y = shadowTerrainHeight + 0.01;
      }

      // Rotate shadow to match active character rotation
      gameState.shadowTransform!.rotation.y = gameState.activeRotation;

      // Shadow gets larger the higher the player is (scale factor includes base size adjustment)
      final scaleFactor = 1.0 + playerHeight * 0.15;
      gameState.shadowTransform!.scale = Vector3(scaleFactor, 1, scaleFactor);
    }

    // Update aura positions — place at each unit's base on terrain
    _updateAuraPositions();

    // Update floating damage indicators
    updateDamageIndicators(gameState.damageIndicators, dt);

    // Update camera based on mode — follows the active character
    if (camera!.mode == CameraMode.thirdPerson) {
      // Third-person mode: Camera follows active character from behind
      camera!.updateThirdPersonFollow(
        gameState.activeTransform!.position,
        gameState.activeRotation,
        dt,
      );
    } else {
      // Static mode: Camera orbits around active character with smoothing
      final currentTarget = camera!.getTarget();
      final distanceFromTarget = (gameState.activeTransform!.position - currentTarget).length;

      // Update camera target smoothly when active character moves away from center
      if (distanceFromTarget > 0.1) {
        // Smoothly interpolate camera target toward active character position
        final newTarget = currentTarget + (gameState.activeTransform!.position - currentTarget) * 0.05;
        camera!.setTarget(newTarget);
      }
    }

    // Flight camera: roll from banking, pitch offset from pitch angle.
    // SHIFT suppresses camera angle changes so the player can look around.
    if (gameState.isFlying) {
      final shiftHeld = inputManager!.isShiftPressed();
      if (shiftHeld) {
        camera!.rollAngle = 0.0;
        camera!.targetPitchOffset = 0.0;
      } else {
        camera!.rollAngle = gameState.flightBankAngle;
        final pitchRad = gameState.flightPitchAngle * (math.pi / 180.0);
        camera!.targetPitchOffset = math.sin(pitchRad) * 5.0;
      }
    } else {
      camera!.rollAngle = 0.0;
      camera!.targetPitchOffset = 0.0;
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
      if (!_isVisible('abilities_codex')) return;
      print('P key detected! Toggling abilities modal.');
      setState(() {
        gameState.abilitiesModalOpen = !gameState.abilitiesModalOpen;
      });
      return;
    }

    // Handle C key for character panel (only on key down, not repeat)
    // Opens to the active party member's tab
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (!_isVisible('character_panel')) return;
      print('C key detected! Toggling character panel (active: ${gameState.activeCharacterIndex}).');
      setState(() {
        gameState.characterPanelOpen = !gameState.characterPanelOpen;
        if (!gameState.characterPanelOpen) {
          gameState.characterPanelSelectedIndex = null;
        }
      });
      return;
    }

    // Handle B key for bag panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyB) {
      if (!_isVisible('bag_panel')) return;
      print('B key detected! Toggling bag panel.');
      setState(() {
        gameState.bagPanelOpen = !gameState.bagPanelOpen;
      });
      return;
    }

    // Handle M key for minimap toggle (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyM) {
      if (!_isVisible('minimap')) return;
      setState(() {
        gameState.minimapOpen = !gameState.minimapOpen;
      });
      return;
    }

    // Handle F key for ally commands panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyF) {
      if (!_isVisible('ally_commands')) return;
      if (gameState.allies.isNotEmpty) {
        print('F key detected! Toggling ally commands panel.');
        setState(() {
          gameState.allyCommandPanelOpen = !gameState.allyCommandPanelOpen;
        });
      }
      return;
    }

    // Handle G key for goals panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyG) {
      // Reason: G was previously unbound. Only intercept without shift
      // so T (attack) and G (hold) commands still work with shift combos.
      if (!HardwareKeyboard.instance.isShiftPressed) {
        setState(() {
          gameState.goalsPanelOpen = !gameState.goalsPanelOpen;
        });
        return;
      }
    }

    // Handle R key for Macro Builder panel (only on key down)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyR) {
      if (!_isVisible('rotation_builder')) return;
      setState(() {
        gameState.macroPanelOpen = !gameState.macroPanelOpen;
      });
      return;
    }

    // Handle ` (backtick) key for Chat panel (only on key down)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backquote) {
      setState(() {
        gameState.chatPanelOpen = !gameState.chatPanelOpen;
      });
      return;
    }

    // Handle H key for building panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyH) {
      setState(() {
        if (gameState.buildingPanelOpen) {
          // Close if already open
          gameState.buildingPanelOpen = false;
          gameState.selectedBuilding = null;
        } else {
          // Open if near a building
          final nearest = gameState.getNearestBuilding(
            globalBuildingConfig?.interactionRange ?? 5.0,
          );
          if (nearest != null) {
            gameState.selectedBuilding = nearest;
            gameState.buildingPanelOpen = true;
            print('[BUILDING] Opened panel for ${nearest.definition.name}');
          }
        }
      });
      return;
    }

    // Handle X key for stances: Shift+X cycles, X toggles selector panel
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyX) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if (isShiftPressed) {
        // Shift+X: cycle to next stance
        setState(() {
          gameState.cycleStance();
        });
      } else {
        // X: toggle stance selector panel
        setState(() {
          gameState.stanceSelectorOpen = !gameState.stanceSelectorOpen;
        });
      }
      return;
    }

    // Handle SHIFT+D for DPS testing panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyD) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if (isShiftPressed) {
        if (!_isVisible('dps_panel')) return;
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
    // Shift+Tab = cycle friendly targets, Tab = cycle enemy targets
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

      if (isShiftPressed) {
        // Shift+Tab = cycle friendly targets
        setState(() {
          gameState.tabToNextFriendlyTarget();
          debugPrint('Shift+Tab: friendly target -> ${gameState.currentTargetId}');
        });
        return;
      }

      final playerX = gameState.playerTransform?.position.x ?? 0.0;
      final playerZ = gameState.playerTransform?.position.z ?? 0.0;
      final playerRotation = gameState.playerTransform?.rotation.y ?? 0.0;

      setState(() {
        gameState.tabToNextTarget(playerX, playerZ, playerRotation);
        final target = gameState.getCurrentTarget();
        if (target != null) {
          final name = target['type'] == 'boss' ? 'Boss Monster' :
            (target['entity'] as Monster?)?.definition.name ?? 'Unknown';
          debugPrint('Tab target: $name');
        } else {
          debugPrint('No targets available');
        }
      });
      return;
    }

    // Handle [ and ] keys for party cycling or panel carousel
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.bracketLeft) {
      setState(() {
        if (gameState.characterPanelOpen) {
          // Cycle panel carousel
          final total = 1 + gameState.allies.length;
          final current = gameState.characterPanelSelectedIndex ?? gameState.activeCharacterIndex;
          gameState.characterPanelSelectedIndex = (current - 1 + total) % total;
        } else {
          // Cycle active controlled character
          gameState.cycleActiveCharacterPrev();
          _updateActiveActionBarConfig();
        }
      });
      return;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.bracketRight) {
      setState(() {
        if (gameState.characterPanelOpen) {
          // Cycle panel carousel
          final total = 1 + gameState.allies.length;
          final current = gameState.characterPanelSelectedIndex ?? gameState.activeCharacterIndex;
          gameState.characterPanelSelectedIndex = (current + 1) % total;
        } else {
          // Cycle active controlled character
          gameState.cycleActiveCharacterNext();
          _updateActiveActionBarConfig();
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
          gameState.characterPanelSelectedIndex = null;
        });
        return;
      }
      if (gameState.bagPanelOpen) {
        setState(() {
          gameState.bagPanelOpen = false;
        });
        return;
      }
      if (gameState.allyCommandPanelOpen) {
        setState(() {
          gameState.allyCommandPanelOpen = false;
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
      if (gameState.buildingPanelOpen) {
        setState(() {
          gameState.buildingPanelOpen = false;
          gameState.selectedBuilding = null;
        });
        return;
      }
      if (gameState.goalsPanelOpen) {
        setState(() {
          gameState.goalsPanelOpen = false;
        });
        return;
      }
      if (gameState.macroPanelOpen) {
        setState(() {
          gameState.macroPanelOpen = false;
        });
        return;
      }
      if (gameState.chatPanelOpen) {
        setState(() {
          gameState.chatPanelOpen = false;
        });
        return;
      }
      if (gameState.warriorSpiritPanelOpen) {
        setState(() {
          gameState.warriorSpiritPanelOpen = false;
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

  /// Handle left-click on the game world for entity picking (click-to-select).
  ///
  /// Projects all entity positions to screen space and selects the closest
  /// entity to the click point within [GameConfig.clickSelectionRadius].
  /// Clicking empty space clears the current target.
  void _handleWorldClick(PointerDownEvent event) {
    // Only process primary (left) mouse button
    if (event.buttons != 1) return;
    if (camera == null) return;

    // Reclaim keyboard focus from any active text field
    _gameFocusNode.requestFocus();

    final clickPos = event.localPosition;
    final viewMatrix = camera!.getViewMatrix();
    final projMatrix = camera!.getProjectionMatrix();
    final screenSize = MediaQuery.of(context).size;

    final pickedId = EntityPickingSystem.pickEntity(
      clickPos: clickPos,
      viewMatrix: viewMatrix,
      projMatrix: projMatrix,
      screenSize: screenSize,
      gameState: gameState,
      selectionRadius: GameConfig.clickSelectionRadius,
    );

    setState(() {
      gameState.setTarget(pickedId);
      if (pickedId != null) {
        debugPrint('Click-selected: $pickedId');
      }
    });
  }

  /// Handle ping created from clicking the minimap.
  ///
  /// Creates a [MinimapPing] at the given world XZ position and adds it
  /// to the minimap state. The ping is visible on both the minimap
  /// (expanding rings) and in the 3D world view (diamond icon).
  void _handleMinimapPing(double worldX, double worldZ) {
    final config = globalMinimapConfig;
    final colorList = config?.pingDefaultColor ?? [1.0, 0.9, 0.3, 1.0];
    final color = Color.fromRGBO(
      (colorList[0] * 255).round(),
      (colorList[1] * 255).round(),
      (colorList[2] * 255).round(),
      colorList.length > 3 ? colorList[3] : 1.0,
    );

    setState(() {
      gameState.minimapState.addPing(MinimapPing(
        worldX: worldX,
        worldZ: worldZ,
        createTime: gameState.minimapState.elapsedTime,
        color: color,
      ));
    });
    print('[MINIMAP] Ping at world ($worldX, $worldZ)');
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

  /// Update the action bar config manager to match the active character
  void _updateActiveActionBarConfig() {
    globalActionBarConfigManager?.setActiveIndex(gameState.activeCharacterIndex);
    final activeIdx = gameState.activeCharacterIndex;
    final name = activeIdx == 0 ? 'Warchief' : 'Ally $activeIdx';
    print('[PARTY] Active character: $name');
  }

  /// Handle ability dropped from Abilities Codex onto action bar slot
  void _handleAbilityDropped(int slotIndex, String abilityName) {
    final config = globalActionBarConfig;
    if (config != null) {
      config.setSlotAbility(slotIndex, abilityName);
      print('[ActionBar] Assigned "$abilityName" to slot ${slotIndex + 1}');
      _refreshAllAuraColors(); // Update aura glow to reflect new ability loadout
      setState(() {}); // Refresh UI to show new ability
    }
  }

  /// Handle class loaded to action bar — update active character mesh color
  void _handleClassLoaded(String category) {
    final color = AuraSystem.getCategoryColorVec3(category);
    if (gameState.isWarchiefActive) {
      gameState.playerMesh = PlayerMesh.createSimpleCharacter(bodyColor: color);
    } else {
      final ally = gameState.activeAlly;
      if (ally != null) {
        ally.mesh = Mesh.cube(size: 0.8, color: color);
      }
    }
    _refreshAllAuraColors();
    setState(() {});
  }

  // ===== ALLY COMMAND METHODS =====

  /// Flight duration accumulator for goals tracking
  double _flightDurationAccum = 0;

  /// Track previous command key states to detect key press (not hold)
  bool _attackKeyWasPressed = false;
  bool _holdKeyWasPressed = false;
  bool _formationKeyWasPressed = false;

  /// Default positions for draggable panels (used if config not available)
  static const Map<String, Offset> _defaultPositions = {
    'instructions': Offset(10, 10),
    'combat_hud': Offset(300, 500),
    'monster_abilities': Offset(10, 300),
    'ai_chat': Offset(10, 450),
    'minimap': Offset(1410, 8),
  };

  /// Track SHIFT+key state for formation panel toggling
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

  /// Handle ally command input (T=Attack, G=Hold, R=Formation)
  ///
  /// F key now toggles the unified AllyCommandsPanel (handled in _onKeyEvent).
  void _handleAllyCommands() {
    if (inputManager == null) return;

    final shiftPressed = inputManager!.isShiftPressed();
    final attackPressed = inputManager!.isActionPressed(GameAction.petAttack);
    final holdPressed = inputManager!.isActionPressed(GameAction.petStay);
    final formationPressed = inputManager!.isActionPressed(GameAction.cycleFormation);

    // Without SHIFT - execute commands directly
    if (!shiftPressed) {
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
    // Track ally commands for goals
    GoalSystem.processEvent(gameState, 'ally_command_issued');
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

      // Initialize aura for the new ally
      final allyIndex = gameState.allies.length; // 1-based for config manager
      _updateAllyAuraColor(ally, allyIndex);

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

  /// Update the player's aura mesh color from the active action bar config.
  void _updatePlayerAuraColor() {
    final config = globalActionBarConfigManager?.getConfig(0);
    if (config == null) return;

    final color = AuraSystem.computeAuraColor(config);
    final newMesh = AuraSystem.createOrUpdateAuraMesh(
      color: color,
      radius: 1.2,
      existing: gameState.playerAuraMesh,
      lastColor: gameState.lastPlayerAuraColor,
    );
    gameState.playerAuraMesh = newMesh;
    if (color != null) {
      gameState.lastPlayerAuraColor = color.clone();
    }
  }

  /// Update an ally's aura mesh color from their action bar config.
  void _updateAllyAuraColor(Ally ally, int allyConfigIndex) {
    final config = globalActionBarConfigManager?.getConfig(allyConfigIndex);
    if (config == null) return;

    final color = AuraSystem.computeAuraColor(config);
    final newMesh = AuraSystem.createOrUpdateAuraMesh(
      color: color,
      radius: 0.8,
      existing: ally.auraMesh,
      lastColor: ally.lastAuraColor,
    );
    ally.auraMesh = newMesh;
    if (color != null) {
      ally.lastAuraColor = color.clone();
    }
  }

  /// Position all aura discs at their unit's base on terrain each frame.
  void _updateAuraPositions() {
    // Player aura — update position in-place to avoid Vector3 allocation
    if (gameState.playerAuraTransform != null && gameState.playerTransform != null) {
      double auraY = 0.02;
      if (gameState.infiniteTerrainManager != null) {
        auraY = gameState.infiniteTerrainManager!.getTerrainHeight(
          gameState.playerTransform!.position.x,
          gameState.playerTransform!.position.z,
        ) + 0.02;
      }
      gameState.playerAuraTransform!.position.x = gameState.playerTransform!.position.x;
      gameState.playerAuraTransform!.position.y = auraY;
      gameState.playerAuraTransform!.position.z = gameState.playerTransform!.position.z;
    }

    // Ally auras — update position in-place
    for (final ally in gameState.allies) {
      if (ally.auraMesh != null) {
        double auraY = 0.02;
        if (gameState.infiniteTerrainManager != null) {
          auraY = gameState.infiniteTerrainManager!.getTerrainHeight(
            ally.transform.position.x,
            ally.transform.position.z,
          ) + 0.02;
        }
        ally.auraTransform.position.x = ally.transform.position.x;
        ally.auraTransform.position.y = auraY;
        ally.auraTransform.position.z = ally.transform.position.z;
      }
    }
  }

  /// Refresh all aura colors (call when action bar config changes).
  void _refreshAllAuraColors() {
    _updatePlayerAuraColor();
    for (int i = 0; i < gameState.allies.length; i++) {
      _updateAllyAuraColor(gameState.allies[i], i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _gameFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        // Let text fields handle their own input, but allow Escape through
        // so the user can always close panels and return to the game.
        if (_isTextFieldFocused()) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            _gameFocusNode.requestFocus();
            _onKeyEvent(event);
            return KeyEventResult.handled;
          }
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
            // Listener captures left-clicks for entity picking (click-to-select)
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) => _handleWorldClick(event),
              child: SizedBox.expand(),
            ),

            // Floating damage indicators (world-space positioned)
            DamageIndicatorOverlay(
              indicators: gameState.damageIndicators,
              camera: camera,
              canvasWidth: 1600,
              canvasHeight: 900,
            ),

            // World-space ping indicators (from minimap pings)
            if (gameState.minimapState.pings.isNotEmpty && camera != null)
              MinimapPingWorldOverlay(
                pings: gameState.minimapState.pings,
                elapsedTime: gameState.minimapState.elapsedTime,
                viewMatrix: camera?.getViewMatrix(),
                projMatrix: camera?.getProjectionMatrix(),
                screenSize: MediaQuery.of(context).size,
              ),

            // Stance visual effects (Drunken pulse, Fury vignette)
            StanceEffectsOverlay(gameState: gameState),

            // Minimap (draggable, replaces standalone WindIndicator)
            if (gameState.minimapOpen && _isVisible('minimap'))
              _draggable('minimap',
                MinimapWidget(
                  gameState: gameState,
                  windState: gameState.windState,
                  camera: camera,
                  onPingCreated: _handleMinimapPing,
                ),
                width: 180, height: 200,
              ),

            // Stance selector (left side, vertically centered)
            Positioned(
              left: 12,
              top: MediaQuery.of(context).size.height * 0.35,
              child: StanceSelector(
                gameState: gameState,
                onStateChanged: () => setState(() {}),
              ),
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

            // Character Panel (Press C to toggle)
            // Reason: Rendered before command panels so they appear on top of the 750px-wide panel
            if (gameState.characterPanelOpen && _isVisible('character_panel'))
              CharacterPanel(
                gameState: gameState,
                initialIndex: gameState.characterPanelSelectedIndex ?? gameState.activeCharacterIndex,
                onClose: () {
                  setState(() {
                    gameState.characterPanelOpen = false;
                    gameState.characterPanelSelectedIndex = null;
                  });
                },
              ),

            // ========== ALLY COMMANDS PANEL (Press F to toggle) ==========
            if (gameState.allies.isNotEmpty && gameState.allyCommandPanelOpen && _isVisible('ally_commands'))
              AllyCommandsPanel(
                onClose: () {
                  setState(() {
                    gameState.allyCommandPanelOpen = false;
                  });
                },
                currentFormation: gameState.currentFormation,
                onFormationChanged: _changeFormation,
                currentCommand: _getCurrentAllyCommand(),
                onCommandChanged: _setAllyCommand,
                allyCount: gameState.allies.length,
              ),

            // Abilities Modal (Press P to toggle)
            if (gameState.abilitiesModalOpen && _isVisible('abilities_codex'))
              AbilitiesModal(
                onClose: () {
                  setState(() {
                    gameState.abilitiesModalOpen = false;
                  });
                  _gameFocusNode.requestFocus();
                },
                onClassLoaded: _handleClassLoaded,
                gameState: gameState,
              ),

            // Bag Panel (Press B to toggle)
            if (gameState.bagPanelOpen && _isVisible('bag_panel'))
              BagPanel(
                inventory: gameState.playerInventory,
                onClose: () {
                  setState(() {
                    gameState.bagPanelOpen = false;
                  });
                  _gameFocusNode.requestFocus();
                },
                onItemClick: (index, item) {
                  if (item != null) {
                    print('[Bag] Clicked item at slot $index: ${item.name}');
                  }
                },
                onItemEquipped: () => setState(() {
                  gameState.invalidatePlayerAttunementCache();
                }),
                onUnequipToBag: (slot, item) {
                  setState(() {
                    final inventory = gameState.playerInventory;
                    final oldMaxHealth = gameState.playerMaxHealth;
                    inventory.unequip(slot);
                    inventory.addToBag(item);
                    // Reason: adjust health by delta so removing +30 HP gear
                    // removes 30 from current health
                    final healthDelta = gameState.playerMaxHealth - oldMaxHealth;
                    gameState.playerHealth = (gameState.playerHealth + healthDelta)
                        .clamp(0.0, gameState.playerMaxHealth);
                    gameState.invalidatePlayerAttunementCache();
                  });
                },
                onItemCreated: (item) {
                  setState(() {
                    gameState.playerInventory.addToBag(item);
                  });
                },
              ),

            // DPS Panel (Press SHIFT+D to toggle)
            if (gameState.dpsPanelOpen && _isVisible('dps_panel'))
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

            // Building Panel (Press H near a building to toggle)
            if (gameState.buildingPanelOpen && gameState.selectedBuilding != null)
              BuildingPanel(
                building: gameState.selectedBuilding!,
                leyLineManager: gameState.leyLineManager,
                onClose: () {
                  setState(() {
                    gameState.buildingPanelOpen = false;
                    gameState.selectedBuilding = null;
                  });
                },
                onUpgrade: () {
                  setState(() {
                    BuildingSystem.upgradeBuilding(gameState.selectedBuilding!);
                  });
                },
              ),

            // Goals Panel (Press G to toggle)
            if (gameState.goalsPanelOpen)
              GoalsPanel(
                goals: gameState.goals,
                pendingGoal: gameState.pendingSpiritGoal,
                onAcceptGoal: (def) => setState(() {
                  gameState.goals.add(GoalSystem.acceptGoal(def));
                  gameState.pendingSpiritGoal = null;
                }),
                onDeclineGoal: () => setState(() {
                  gameState.pendingSpiritGoal = null;
                }),
                onClose: () => setState(() {
                  gameState.goalsPanelOpen = false;
                }),
              ),

            // Macro Builder Panel (Press R to toggle)
            if (gameState.macroPanelOpen && _isVisible('rotation_builder'))
              MacroBuilderPanel(
                gameState: gameState,
                onClose: () => setState(() { gameState.macroPanelOpen = false; }),
                onMacroStarted: () => setState(() {}),
              ),

            // Chat Panel (Press ` to toggle — Spirit + Raid tabs)
            if (gameState.chatPanelOpen)
              ChatPanel(
                spiritMessages: gameState.warriorSpiritMessages,
                onSendSpiritMessage: (msg) async {
                  gameState.warriorSpiritMessages.add(
                    AIChatMessage(text: msg, isInput: true));
                  setState(() {});
                  final reply = await WarriorSpirit.chat(gameState, msg);
                  gameState.warriorSpiritMessages.add(
                    AIChatMessage(text: reply, isInput: false));
                  if (mounted) setState(() {});
                },
                raidMessages: gameState.raidChatMessages,
                combatLogMessages: gameState.combatLogMessages,
                initialTab: gameState.chatPanelActiveTab,
                onTabChanged: (tab) {
                  gameState.chatPanelActiveTab = tab;
                },
                onClose: () => setState(() {
                  gameState.chatPanelOpen = false;
                }),
              ),

            // Warrior Spirit Panel (Press V to toggle — standalone)
            if (gameState.warriorSpiritPanelOpen && !gameState.chatPanelOpen)
              WarriorSpiritPanel(
                messages: gameState.warriorSpiritMessages,
                onSendMessage: (msg) async {
                  gameState.warriorSpiritMessages.add(
                    AIChatMessage(text: msg, isInput: true));
                  setState(() {});
                  final reply = await WarriorSpirit.chat(gameState, msg);
                  gameState.warriorSpiritMessages.add(
                    AIChatMessage(text: reply, isInput: false));
                  if (mounted) setState(() {});
                },
                onClose: () => setState(() {
                  gameState.warriorSpiritPanelOpen = false;
                }),
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
        'mana': 0.0,
        'maxMana': 0.0,
        'level': null,
        'color': const Color(0xFF666666),
        'isFriendly': false,
      };
    }

    if (target['type'] == 'player') {
      return {
        'hasTarget': true,
        'name': 'Warchief',
        'health': gameState.playerHealth,
        'maxHealth': gameState.playerMaxHealth,
        'mana': gameState.blueMana,
        'maxMana': gameState.maxBlueMana,
        'level': 10,
        'color': const Color(0xFF4D80CC),
        'isFriendly': true,
      };
    }

    if (target['type'] == 'boss') {
      return {
        'hasTarget': true,
        'name': 'Boss Monster',
        'health': gameState.monsterHealth,
        'maxHealth': gameState.monsterMaxHealth.toDouble(),
        'mana': 100.0,
        'maxMana': 100.0,
        'level': 15,
        'color': const Color(0xFF9933CC), // Purple for boss
        'isFriendly': false,
      };
    } else if (target['type'] == 'dummy') {
      final dummy = gameState.targetDummy;
      return {
        'hasTarget': true,
        'name': 'Target Dummy',
        'health': dummy?.displayHealth ?? 100000,
        'maxHealth': dummy?.maxHealth ?? 100000,
        'mana': 0.0,
        'maxMana': 0.0,
        'level': 0,
        'color': const Color(0xFFC19A6B), // Burlywood/wooden color
        'isFriendly': false,
      };
    } else if (target['type'] == 'ally') {
      final ally = target['entity'] as Ally?;
      if (ally == null) {
        return {
          'hasTarget': false,
          'name': null,
          'health': 0.0,
          'maxHealth': 1.0,
          'mana': 0.0,
          'maxMana': 0.0,
          'level': null,
          'color': const Color(0xFF666666),
          'isFriendly': false,
        };
      }
      final allyIndex = int.tryParse((target['id'] as String).substring(5)) ?? 0;
      return {
        'hasTarget': true,
        'name': 'Ally ${allyIndex + 1}',
        'health': ally.health,
        'maxHealth': ally.maxHealth,
        'mana': ally.blueMana,
        'maxMana': ally.maxBlueMana,
        'level': 10,
        'color': const Color(0xFF66CC66), // Green for allies
        'isFriendly': true,
      };
    } else {
      final minion = target['entity'] as Monster?;
      if (minion == null) {
        return {
          'hasTarget': false,
          'name': null,
          'health': 0.0,
          'maxHealth': 1.0,
          'mana': 0.0,
          'maxMana': 0.0,
          'level': null,
          'color': const Color(0xFF666666),
          'isFriendly': false,
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
        'mana': minion.mana,
        'maxMana': minion.maxMana,
        'level': minion.definition.monsterPower,
        'color': archetypeColor,
        'isFriendly': false,
      };
    }
  }

  /// Get target-of-target data for the ToT unit frame.
  /// Returns null if no target-of-target exists.
  Map<String, dynamic>? _getTargetOfTargetData() {
    final tot = gameState.getTargetOfTarget();
    if (tot == null || tot == 'none') return null;

    if (tot == 'player') {
      return {
        'name': 'You',
        'health': gameState.playerHealth,
        'maxHealth': gameState.playerMaxHealth,
        'level': 10,
        'color': const Color(0xFF4D80CC),
        'isFriendly': true,
      };
    }

    if (tot.startsWith('ally_')) {
      final index = int.tryParse(tot.substring(5));
      if (index != null && index < gameState.allies.length) {
        final ally = gameState.allies[index];
        return {
          'name': 'Ally ${index + 1}',
          'health': ally.health,
          'maxHealth': ally.maxHealth,
          'level': 5 + index + 1,
          'color': const Color(0xFF66CC66),
          'isFriendly': true,
        };
      }
    }

    // Check minions
    final minion = gameState.minions.where((m) => m.instanceId == tot).firstOrNull;
    if (minion != null) {
      return {
        'name': minion.definition.name,
        'health': minion.health,
        'maxHealth': minion.maxHealth,
        'level': minion.definition.monsterPower,
        'color': Color(minion.healthBarColor),
        'isFriendly': false,
      };
    }

    return null;
  }

  /// Build Combat HUD with current target data
  Widget _buildCombatHUD() {
    final targetData = _getTargetData();
    final totData = _getTargetOfTargetData();

    // Determine friendly/enemy colors for target frame
    final isFriendly = targetData['isFriendly'] as bool? ?? false;
    final targetBorderColor = isFriendly
        ? const Color(0xFF4CAF50) // Green border for friendlies
        : const Color(0xFFFF6B6B); // Red border for enemies
    final targetHealthColor = isFriendly
        ? const Color(0xFF66BB6A) // Green health for friendlies
        : const Color(0xFFEF5350); // Red health for enemies

    // Determine active character info for player frame
    final isWarchief = gameState.isWarchiefActive;
    final activeAlly = gameState.activeAlly;
    final activeName = isWarchief
        ? 'Warchief'
        : 'Ally ${gameState.activeCharacterIndex}';
    final activeHealth = isWarchief
        ? gameState.playerHealth
        : (activeAlly?.health ?? 0);
    final activeMaxHealth = isWarchief
        ? gameState.playerMaxHealth
        : (activeAlly?.maxHealth ?? 50);
    final activeLevel = isWarchief
        ? 10
        : (5 + gameState.activeCharacterIndex);
    final activePortraitColor = isWarchief
        ? const Color(0xFF4D80CC)
        : const Color(0xFF66CC66);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CombatHUD(
          playerName: activeName,
          playerHealth: activeHealth,
          playerMaxHealth: activeMaxHealth,
          playerLevel: activeLevel,
          playerPortraitWidget: CubePortrait(
            color: activePortraitColor,
            size: 36,
            hasDirectionIndicator: true,
            indicatorColor: isWarchief ? Colors.red : Colors.green,
          ),
          gameState: gameState, // For mana bar display
          targetName: targetData['name'] as String?,
          targetHealth: targetData['health'] as double,
          targetMaxHealth: targetData['maxHealth'] as double,
          targetMana: targetData['mana'] as double,
          targetMaxMana: targetData['maxMana'] as double,
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
          abilityCooldowns: gameState.activeAbilityCooldowns,
          abilityCooldownMaxes: gameState.activeAbilityCooldownMaxes,
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
          actionBarConfig: globalActionBarConfigManager?.activeConfig,
          targetBorderColor: targetBorderColor,
          targetHealthColor: targetHealthColor,
          totName: totData?['name'] as String?,
          totHealth: (totData?['health'] as num?)?.toDouble() ?? 0.0,
          totMaxHealth: (totData?['maxHealth'] as num?)?.toDouble() ?? 1.0,
          totLevel: totData?['level'] as int?,
          totPortraitWidget: totData != null
              ? CubePortrait(
                  color: totData['color'] as Color,
                  size: 24,
                  hasDirectionIndicator: false,
                )
              : null,
          totBorderColor: totData != null
              ? ((totData['isFriendly'] as bool)
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF6B6B))
              : const Color(0xFF888888),
          totHealthColor: totData != null
              ? ((totData['isFriendly'] as bool)
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFEF5350))
              : const Color(0xFF4CAF50),
          onAbilityDropped: _handleAbilityDropped,
          onStateChanged: () => setState(() {}),
        ),
      ],
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

    _gameFocusNode.dispose();

    super.dispose();
  }
}

class Math {
  static double sin(double radians) => math.sin(radians);
  static double cos(double radians) => math.cos(radians);
}
