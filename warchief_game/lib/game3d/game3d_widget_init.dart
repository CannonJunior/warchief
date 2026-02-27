part of 'game3d_widget.dart';

/// Height buffer so unit bases rest visually above terrain surface.
const double _terrainBuffer = 0.15;

mixin _WidgetInitMixin on _GameStateBase {
  // ==================== CONFIG INITIALIZERS ====================

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

  /// Initialize the global ability order manager (category reordering)
  void _initializeAbilityOrder() {
    globalAbilityOrderManager ??= AbilityOrderManager();
    globalAbilityOrderManager!.loadOrders();
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

  /// Initialize the global comet system (config + orbital state)
  void _initializeCometSystem() {
    globalCometConfig ??= CometConfig();
    globalCometConfig!.initialize();
    globalCometState ??= CometState();
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

  /// Initialize the global melee combo configuration (JSON defaults)
  void _initializeComboConfig() {
    globalComboConfig ??= ComboConfig();
    globalComboConfig!.initialize();
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

  // ==================== GAME INITIALIZATION ====================

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
}
