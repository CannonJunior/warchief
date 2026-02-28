part of 'game_state.dart';

/// Helper to create building meshes without importing building_system.dart.
///
/// Reason: game_state.dart must not import building_system.dart because
/// building_system.dart imports game_state.dart. This helper delegates
/// to BuildingMesh directly instead.
class _BuildingMeshHelper {
  static Mesh create(BuildingTierDef tier) {
    // Inline import to avoid circular dependency
    return _createFromParts(tier);
  }

  /// Minimal mesh creation from tier parts.
  /// Delegates to the BuildingMesh factory via the rendering3d layer.
  static Mesh _createFromParts(BuildingTierDef tier) {
    // Use the same factory as building_mesh.dart
    // This import is safe because rendering3d has no dependency on game3d/state
    return BuildingMesh.createBuilding(tier);
  }
}

extension GameStateWorldExt on GameState {
  /// Initialize Ley Lines for the world
  void initializeLeyLines({int seed = 42, double worldSize = 200.0, int siteCount = 25}) {
    leyLineManager = LeyLineManager(
      seed: seed,
      worldSize: worldSize,
      siteCount: siteCount,
    );
    print('[LeyLines] Initialized with seed $seed, ${leyLineManager!.segments.length} segments');
  }

  /// Get tactical positions for all allies (cached for performance)
  Map<Ally, TacticalPosition> getTacticalPositions() {
    // Recalculate every 0.5 seconds or when cache is invalid
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (_cachedTacticalPositions == null ||
        now - _tacticalPositionCacheTime > 0.5) {
      _cachedTacticalPositions = TacticalPositioning.calculatePositions(
        this,
        currentFormation,
      );
      _tacticalPositionCacheTime = now;
    }
    return _cachedTacticalPositions!;
  }

  /// Force recalculation of tactical positions
  void invalidateTacticalPositions() {
    _cachedTacticalPositions = null;
  }

  /// Get or create direction indicator mesh for a minion type
  Mesh getMinionDirectionIndicator(MonsterDefinition definition) {
    return _minionDirectionIndicators.putIfAbsent(
      definition.id,
      () => Mesh.triangle(
        size: 0.3 * definition.effectiveScale,
        color: definition.accentColor,
      ),
    );
  }

  /// Spawn all minions according to the provided [spawns] list, or
  /// [DefaultMinionSpawns.spawns] if none is given.
  void spawnMinions(
    InfiniteTerrainManager? terrainManager, {
    List<MinionSpawnConfig>? spawns,
  }) {
    if (minionsSpawned) return;

    final spawnList = spawns ?? DefaultMinionSpawns.spawns;

    print('[MINIONS] Spawning minions...');
    print(DefaultMinionSpawns.summary);

    // Base spawn position (offset from monster)
    final baseX = GameConfig.monsterStartPosition.x;
    final baseZ = GameConfig.monsterStartPosition.z - 10; // Behind the boss

    int totalSpawned = 0;

    for (final spawnConfig in spawnList) {
      final definition = MinionDefinitions.getById(spawnConfig.definitionId);
      if (definition == null) {
        print('[MINIONS] Warning: Unknown definition ${spawnConfig.definitionId}');
        continue;
      }

      // Calculate spawn center for this group (arrange groups in a line)
      final groupOffset = totalSpawned * 0.5;
      final centerX = baseX + (groupOffset % 4) * 4 - 6;
      final centerZ = baseZ - (groupOffset ~/ 4) * 4;

      // Get terrain height at spawn center
      double centerY = 0.0;
      if (terrainManager != null) {
        centerY = terrainManager.getTerrainHeight(centerX, centerZ);
      }

      // Create monsters for this group
      final monsters = MonsterFactory.createGroup(
        definition: definition,
        centerPosition: Vector3(centerX, centerY, centerZ),
        count: spawnConfig.count,
        spreadRadius: spawnConfig.spreadRadius,
      );

      // Adjust Y positions to terrain height (add half size so bottom sits on terrain)
      for (final monster in monsters) {
        if (terrainManager != null) {
          final terrainY = terrainManager.getTerrainHeight(
            monster.transform.position.x,
            monster.transform.position.z,
          );
          // Add half the minion size + buffer so bottom of mesh sits above terrain
          const double terrainBuffer = 0.15;
          monster.transform.position.y = terrainY + definition.effectiveScale / 2 + terrainBuffer;
          // Direction indicator sits on top of the mesh
          if (monster.directionIndicatorTransform != null) {
            monster.directionIndicatorTransform!.position.y =
                monster.transform.position.y + definition.effectiveScale / 2 + 0.1;
          }
        }
      }

      minions.addAll(monsters);
      totalSpawned += spawnConfig.count;

      print('[MINIONS] Spawned ${spawnConfig.count}x ${definition.name} '
          '(MP ${definition.monsterPower})');
    }

    minionsSpawned = true;
    rebuildMinionIndex();
    print('[MINIONS] Total spawned: ${minions.length} minions');
    print('[MINIONS] Total Monster Power: ${DefaultMinionSpawns.totalMonsterPower}');
  }

  /// Rebuild the alive minions cache. Call once per frame at the start of the update loop.
  void refreshAliveMinions() {
    _cachedAliveMinions = minions.where((m) => m.isAlive).toList();
    // Reason: Keep _minionIndex in sync so currentTargetActiveEffects and
    // getCurrentTargetPosition work for minions after spawns/deaths.
    rebuildMinionIndex();
  }

  /// Get minions by archetype
  List<Monster> getMinionsByArchetype(MonsterArchetype archetype) {
    return minions.where((m) =>
        m.isAlive && m.definition.archetype == archetype).toList();
  }

  /// Get the nearest minion to a position
  Monster? getNearestMinion(Vector3 position, {double maxRange = double.infinity}) {
    Monster? nearest;
    double nearestDist = maxRange;

    for (final minion in aliveMinions) {
      final dist = minion.distanceTo(position);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = minion;
      }
    }

    return nearest;
  }

  /// Spawn the warchief's home at a fixed position near player start.
  ///
  /// Only spawns once — skips if a warchief_home already exists.
  void spawnWarchiefHome(InfiniteTerrainManager? terrainManager) {
    if (buildings.any((b) => b.definition.id == 'warchief_home')) return;

    final config = globalBuildingConfig;
    final typeDef = BuildingDefinition.fromConfig(
      'warchief_home',
      config?.getBuildingType('warchief_home'),
    );
    if (typeDef == null) {
      print('[BUILDING] Warning: warchief_home definition not found in config');
      return;
    }

    // Place near player start, offset to the side
    final homeX = GameConfig.playerStartPosition.x + 15;
    final homeZ = GameConfig.playerStartPosition.z + 15;

    final building = _placeBuildingInternal(
      definition: typeDef,
      worldX: homeX,
      worldZ: homeZ,
      terrainManager: terrainManager,
    );

    buildings.add(building);
    print('[BUILDING] Warchief Home placed at ($homeX, $homeZ)');
  }

  /// Internal helper: place a building and return it.
  Building _placeBuildingInternal({
    required BuildingDefinition definition,
    required double worldX,
    required double worldZ,
    required InfiniteTerrainManager? terrainManager,
    int tier = 0,
  }) {
    // Imported inline to avoid circular dependency
    // Uses BuildingSystem.placeBuilding from systems layer
    final tierDef = definition.getTier(tier);
    final mesh = _createBuildingMeshFromTier(tierDef);
    double y = 0.0;
    if (terrainManager != null) {
      y = terrainManager.getTerrainHeight(worldX, worldZ);
    }
    final transform = Transform3d(
      position: Vector3(worldX, y, worldZ),
    );
    return Building(
      instanceId: '${definition.id}_${buildings.length}',
      definition: definition,
      currentTier: tier,
      mesh: mesh,
      transform: transform,
    );
  }

  /// Create building mesh from tier (delegates to BuildingMesh factory).
  Mesh _createBuildingMeshFromTier(BuildingTierDef tier) {
    // Reason: import is at file level, keeping this as a helper method
    // avoids importing building_system.dart into game_state.dart (circular)
    return _BuildingMeshHelper.create(tier);
  }

  /// Get the nearest building to player within a given range.
  ///
  /// Returns null if no building is within range.
  Building? getNearestBuilding(double range) {
    if (playerTransform == null) return null;
    final px = playerTransform!.position.x;
    final pz = playerTransform!.position.z;

    Building? nearest;
    double nearestDist = range;

    for (final building in buildings) {
      if (!building.isPlaced) continue;
      final dist = building.distanceTo(px, pz);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = building;
      }
    }
    return nearest;
  }

  /// Add a console log message with automatic trimming.
  void addConsoleLog(String message, {ConsoleLogLevel level = ConsoleLogLevel.info}) {
    consoleLogMessages.add(ConsoleLogEntry(message: message, level: level));
    if (consoleLogMessages.length > 250) {
      consoleLogMessages.removeRange(0, consoleLogMessages.length - 200);
    }
  }

  /// Spawn a target dummy 40 yards in front of the player
  void spawnTargetDummy(InfiniteTerrainManager? terrainManager) {
    if (targetDummy != null && targetDummy!.isSpawned) return;
    if (playerTransform == null) return;

    // Calculate position 40 yards (units) in front of the player
    final playerPos = playerTransform!.position;
    final playerRot = playerRotation * 3.14159 / 180.0;

    // Direction player is facing
    final dirX = -_gsin(playerRot);
    final dirZ = -_gcos(playerRot);

    // Position 40 units ahead
    const distance = 40.0;
    final dummyX = playerPos.x + dirX * distance;
    final dummyZ = playerPos.z + dirZ * distance;

    // Get terrain height at dummy position
    double dummyY = playerPos.y;
    if (terrainManager != null) {
      final terrainHeight = terrainManager.getTerrainHeight(dummyX, dummyZ);
      dummyY = terrainHeight + TargetDummy.size / 2 + 0.15;
    }

    targetDummy = TargetDummy.spawn(Vector3(dummyX, dummyY, dummyZ));

    // Start DPS tracking session
    dpsTracker.startSession();

    print('[DPS] Target Dummy spawned at ($dummyX, $dummyY, $dummyZ)');
  }

  /// Despawn the target dummy
  void despawnTargetDummy() {
    if (targetDummy == null) return;

    targetDummy!.isSpawned = false;
    targetDummy = null;

    // End DPS tracking session
    dpsTracker.endSession();

    print('[DPS] Target Dummy despawned');
  }

  /// Initialize player inventory with sample items from database
  Future<void> initializeInventory() async {
    if (inventoryInitialized) return;

    // Load the item database
    await ItemDatabase.instance.load();

    // Add sample items to bag
    final sampleItems = [
      'health_potion',
      'health_potion',
      'mana_potion',
      'iron_sword',
      'chainmail_armor',
      'iron_helm',
      'leather_boots',
      'leather_gloves',
      'iron_greaves',
      'travelers_cloak',
      'wooden_shield',
      'ring_of_strength',
      'amulet_of_fortitude',
      'talisman_of_ley',
      'talisman_of_blood',
      'talisman_of_wind',
      'talisman_of_growth',
      'iron_ore',
      'gold_coin',
      'dragon_scale',
    ];

    for (final itemId in sampleItems) {
      final item = ItemDatabase.instance.createItem(itemId);
      if (item != null) {
        playerInventory.addToBag(item);
      }
    }

    // Pre-equip some items on the player
    final startingEquipment = [
      'steel_plate',
      'steel_helm',
      'war_axe',
      'tower_shield',
      'boots_of_swiftness',
      'gauntlets_of_might',
      'legplates_of_valor',
      'cloak_of_shadows',
      'signet_of_the_warchief',
      'band_of_protection',
      'all_source_talisman',
    ];

    for (final itemId in startingEquipment) {
      final item = ItemDatabase.instance.createItem(itemId);
      if (item != null && item.isEquippable) {
        playerInventory.equip(item);
      }
    }

    // Set player health to full after equipping starting gear
    playerHealth = playerMaxHealth;

    // Reason: attunement cache may have been populated before equipment was loaded
    invalidatePlayerAttunementCache();

    inventoryInitialized = true;
    print('[GameState] Inventory initialized with ${playerInventory.usedBagSlots} bag items and equipment');
    print('[GameState] Player max health: $playerMaxHealth (base \${GameState.basePlayerMaxHealth} + ${playerInventory.totalEquippedStats.health} from gear)');
  }

  /// Start flight if player has enough White Mana for initial cost.
  ///
  /// Spends the initial mana cost and sets isFlying = true.
  void startFlight() {
    final config = globalWindConfig;
    final cost = config?.initialManaCost ?? 15.0;
    if (!hasWhiteMana(cost)) {
      print('[FLIGHT] Not enough White Mana to take flight (need $cost)');
      return;
    }
    spendWhiteMana(cost);
    isFlying = true;
    flightPitchAngle = 0.0;
    flightBankAngle = 0.0;
    flightSpeed = config?.flightSpeed ?? 7.0;
    flightGroundSpeed = 0.0;
    // Reset visual pitch and roll
    if (playerTransform != null) {
      playerTransform!.rotation.x = 0.0;
      playerTransform!.rotation.z = 0.0;
    }
    // Cancel any cast/windup/channel when entering flight
    cancelCast();
    cancelWindup();
    cancelChannel();
    print('[FLIGHT] Taking flight! (spent ${cost.toStringAsFixed(0)} White Mana)');
  }

  /// End flight — reset all flight state.
  void endFlight() {
    isFlying = false;
    flightPitchAngle = 0.0;
    flightBankAngle = 0.0;
    flightSpeed = globalWindConfig?.flightSpeed ?? 7.0;
    flightGroundSpeed = 0.0;
    // Reset visual pitch and roll
    if (playerTransform != null) {
      playerTransform!.rotation.x = 0.0;
      playerTransform!.rotation.z = 0.0;
    }
    print('[FLIGHT] Flight ended');
  }

  /// Toggle flight on/off.
  void toggleFlight() {
    if (isFlying) {
      endFlight();
    } else {
      startFlight();
    }
  }

  /// Tick summoned unit durations and despawn expired ones.
  void tickSummonDurations(double dt) {
    allies.removeWhere((ally) {
      if (!ally.isSummoned || ally.summonDuration < 0) return false;
      ally.summonDuration -= dt;
      if (ally.summonDuration <= 0) {
        addConsoleLog('${ally.name} expired (summon duration ended)');
        // Reason: If controlling this summon, switch back to Warchief
        if (activeAlly == ally) activeCharacterIndex = 0;
        return true;
      }
      return false;
    });
  }

  /// Compute spawn position 3 units in front of caster, at terrain height.
  Vector3 _summonSpawnPosition(Transform3d casterTransform) {
    final angle = casterTransform.rotation.y * (math.pi / 180.0);
    final spawnX = casterTransform.position.x - math.sin(angle) * 3.0;
    final spawnZ = casterTransform.position.z - math.cos(angle) * 3.0;
    double spawnY = casterTransform.position.y;
    if (infiniteTerrainManager != null) {
      spawnY = infiniteTerrainManager!.getTerrainHeight(spawnX, spawnZ) + 0.35 + 0.15;
    }
    return Vector3(spawnX, spawnY, spawnZ);
  }

  /// Pre-populate a summoned unit's action bar slots.
  void _setupSummonActionBar(int allyIndex, List<String> abilities) {
    final config = globalActionBarConfigManager?.getConfig(allyIndex);
    if (config == null) return;
    for (int i = 0; i < abilities.length && i < 5; i++) {
      config.setSlotAbility(i, abilities[i]);
    }
  }

  /// Spawn a summoned skeleton warrior (red mana melee) in front of the caster.
  void spawnSummonedSkeleton(Transform3d casterTransform) {
    final pos = _summonSpawnPosition(casterTransform);

    final skeleton = Ally(
      mesh: Mesh.cube(size: 0.7, color: Vector3(0.8, 0.8, 0.7)),
      transform: Transform3d(position: pos),
      name: 'Skeleton Warrior',
      isSummoned: true,
      summonDuration: 60.0,
      summonDurationMax: 60.0,
      health: 30.0,
      maxHealth: 30.0,
      abilityIndex: 0,
      moveSpeed: 2.0,
      redMana: 50.0,
      maxRedMana: 50.0,
    );
    // Reason: Red attunement lets the skeleton use red mana melee abilities
    skeleton.temporaryAttunements = {ManaColor.red};
    skeleton.invalidateAttunementCache();

    allies.add(skeleton);

    // Reason: allyIndex is 1-based in the config manager (0 = Warchief)
    final allyConfigIndex = allies.length;
    _setupSummonActionBar(allyConfigIndex, [
      'Sword', 'Heavy Strike', 'Whirlwind', 'Crushing Blow', 'Charge',
    ]);

    addConsoleLog('Skeleton Warrior summoned (60s duration)');
  }

  /// Spawn a summoned skeleton mage (blue mana caster) in front of the caster.
  void spawnSummonedSkeletonMage(Transform3d casterTransform) {
    final pos = _summonSpawnPosition(casterTransform);

    final mage = Ally(
      mesh: Mesh.cube(size: 0.7, color: Vector3(0.5, 0.6, 0.9)),
      transform: Transform3d(position: pos),
      name: 'Skeleton Mage',
      isSummoned: true,
      summonDuration: 60.0,
      summonDurationMax: 60.0,
      health: 20.0,
      maxHealth: 20.0,
      abilityIndex: 1,
      moveSpeed: 1.8,
      blueMana: 100.0,
      maxBlueMana: 100.0,
    );
    // Reason: Blue attunement lets the mage use blue mana caster abilities
    mage.temporaryAttunements = {ManaColor.blue};
    mage.invalidateAttunementCache();

    allies.add(mage);

    final allyConfigIndex = allies.length;
    _setupSummonActionBar(allyConfigIndex, [
      'Fireball', 'Frost Bolt', 'Arcane Missile', 'Ice Shard', 'Frost Nova',
    ]);

    addConsoleLog('Skeleton Mage summoned (60s duration)');
  }
}
