import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/terrain_generator.dart';
import '../../rendering3d/heightmap.dart';
import '../../rendering3d/infinite_terrain_manager.dart';
import '../../rendering3d/ley_lines.dart';
import '../../models/projectile.dart';
import '../../models/impact_effect.dart';
import '../ui/damage_indicators.dart';
import '../../models/ally.dart';
import '../../models/ai_chat_message.dart';
import '../../models/monster.dart';
import '../../models/monster_ontology.dart';
import '../../models/inventory.dart';
import '../../models/item.dart';
import '../../models/damage_event.dart';
import '../../models/target_dummy.dart';
import '../../models/building.dart';
import '../../models/goal.dart';
import '../../models/raid_chat_message.dart';
import '../../models/combat_log_entry.dart';
import '../../models/console_log_entry.dart';
import '../../models/active_effect.dart';
import '../../rendering3d/building_mesh.dart';
import '../../data/item_database.dart';
import 'game_config.dart';
import 'mana_config.dart';
import 'building_config.dart';
import 'wind_config.dart';
import 'wind_state.dart';
import 'comet_config.dart';
import 'comet_state.dart' show globalCometState;
import 'minimap_state.dart';
import '../utils/movement_prediction.dart';
import '../utils/bezier_path.dart';
import '../ai/tactical_positioning.dart';
import '../data/monsters/minion_definitions.dart';
import '../data/abilities/ability_types.dart' show ManaColor, AbilityData;
import '../data/stances/stances.dart';
import 'gameplay_settings.dart';
import 'action_bar_config.dart' show globalActionBarConfigManager;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

part 'game_state_stance.dart';
part 'game_state_mana.dart';
part 'game_state_targeting.dart';
part 'game_state_world.dart';

/// Game State - Centralized state management for the 3D game
///
/// This class holds all mutable game state including:
/// - Player state (position, rotation, abilities, health)
/// - Monster state (position, rotation, abilities, health, AI)
/// - Ally state
/// - Projectiles and visual effects
/// - Game loop state (frame count, timing)
class GameState {
  // ==================== TERRAIN ====================

  // Old terrain system (for backwards compatibility)
  List<TerrainTile>? terrainTiles;
  Heightmap? terrainHeightmap; // For collision detection

  // New infinite terrain system with LOD
  InfiniteTerrainManager? infiniteTerrainManager;

  // ==================== PLAYER STATE ====================

  Mesh? playerMesh;
  Transform3d? playerTransform;
  Mesh? directionIndicator;
  Transform3d? directionIndicatorTransform;
  Mesh? shadowMesh;
  Transform3d? shadowTransform;

  // Aura glow effect at player base
  Mesh? playerAuraMesh;
  Transform3d? playerAuraTransform;
  Vector3? lastPlayerAuraColor;

  double playerRotation = GameConfig.playerStartRotation;
  double playerSpeed = GameConfig.playerSpeed;

  // Player health
  double playerHealth = 100.0;
  static const double basePlayerMaxHealth = 100.0;

  /// Max health is base + total health bonus from all equipped items,
  /// then multiplied by the active stance's maxHealthMultiplier.
  double get playerMaxHealth =>
      (basePlayerMaxHealth + playerInventory.totalEquippedStats.health) *
      activeStance.maxHealthMultiplier;

  // ==================== STANCE STATE ====================

  /// Current stance for the Warchief.
  StanceId playerStance = StanceId.none;

  /// Cooldown remaining before the active character can switch stances.
  double stanceSwitchCooldown = 0.0;

  /// How long the current stance has been active (for Fury timer display).
  double stanceActiveTime = 0.0;

  /// Drunken Master: current re-rolled damage multiplier.
  double drunkenDamageRoll = 1.0;

  /// Drunken Master: current re-rolled damage-taken multiplier.
  double drunkenDamageTakenRoll = 1.0;

  /// Drunken Master: accumulator for re-roll interval timing.
  double stanceRerollAccumulator = 0.0;

  /// Random number generator for Drunken Master re-rolls.
  final math.Random _stanceRng = math.Random();

  /// Drunken Master: visual pulse timer (counts down from ~0.4s on each re-roll).
  double drunkenRerollPulseTimer = 0.0;

  /// Whether the stance selector UI is expanded.
  bool stanceSelectorOpen = false;

  /// Get the [StanceData] for the currently active character.
  ///
  /// For the Warchief, reads [playerStance]. For allies, reads their
  /// [Ally.currentStance]. If the stance registry is not loaded yet,
  /// returns the neutral [StanceData.none].
  StanceData get activeStance {
    final registry = globalStanceRegistry;
    if (registry == null) return StanceData.none;
    final id = isWarchiefActive ? playerStance : (activeAlly?.currentStance ?? StanceId.none);
    var base = registry.getStance(id);

    // Reason: Apply user overrides (sparse merge) before random roll logic
    final overrideMgr = globalStanceOverrideManager;
    if (overrideMgr != null) {
      base = overrideMgr.getEffectiveStance(base);
    }

    // Reason: Drunken Master overrides damageMultiplier and damageTakenMultiplier
    // with independently re-rolled random values. We return a modified copy.
    if (base.hasRandomModifiers) {
      return base.copyWith(
        damageMultiplier: drunkenDamageRoll,
        damageTakenMultiplier: drunkenDamageTakenRoll,
      );
    }
    return base;
  }

  // ==================== PLAYER MANA ====================

  /// Blue mana - regenerated near Ley Lines
  double blueMana = 100.0;
  double get maxBlueMana =>
      (globalManaConfig?.maxBlueMana ?? 100.0) +
      playerInventory.totalEquippedStats.maxBlueMana;

  /// Red mana - generated by melee damage and Ley Power nodes
  /// Characters start with 0 red mana
  double redMana = 0.0;
  double get maxRedMana =>
      (globalManaConfig?.maxRedMana ?? 100.0) +
      playerInventory.totalEquippedStats.maxRedMana;

  /// White mana - regenerated by wind exposure
  double whiteMana = 0.0;
  double get maxWhiteMana =>
      (globalWindConfig?.whiteMaxMana ?? 100.0) +
      playerInventory.totalEquippedStats.maxWhiteMana;

  /// Current white mana regeneration rate (from wind exposure)
  double currentWhiteManaRegenRate = 0.0;

  /// Green mana - regenerated by proximity to nature (grass, green mana users, spirit beings)
  double greenMana = 0.0;
  double get maxGreenMana =>
      (globalManaConfig?.maxGreenMana ?? 100.0) +
      playerInventory.totalEquippedStats.maxGreenMana;

  /// Current green mana regen rate (sum of all sources)
  double currentGreenManaRegenRate = 0.0;

  /// Black mana - void/comet energy regenerated from comet proximity and meteor impacts
  double blackMana = 0.0;
  double get maxBlackMana => globalCometConfig?.maxBlackMana ?? 100.0;

  /// Current black mana regen rate (ambient + comet surge + crater bonuses)
  double currentBlackManaRegenRate = 0.0;

  /// Whether the Warchief is in spirit form
  bool playerInSpiritForm = false;

  /// Time since last green mana source was active (for decay delay)
  double _timeSinceLastGreenManaSource = 0.0;

  /// Temporary mana attunements for Warchief (from buffs/auras)
  Set<ManaColor> temporaryAttunements = {};

  /// All mana colors — returned when attunement is not required.
  static const Set<ManaColor> _allManaColors = {ManaColor.blue, ManaColor.red, ManaColor.white, ManaColor.green, ManaColor.black};

  /// Cached player mana attunements. Invalidated when equipment or temporary attunements change.
  Set<ManaColor>? _cachedPlayerManaAttunements;

  /// Invalidate cached player mana attunements (call on equip/unequip/buff change).
  void invalidatePlayerAttunementCache() {
    _cachedPlayerManaAttunements = null;
  }

  /// Mana colors the Warchief is attuned to (equipped items + temporary).
  /// When attunement requirement is disabled, returns all four colors.
  /// Cached until equipment or temporary attunements change.
  Set<ManaColor> get playerManaAttunements {
    if (!(globalGameplaySettings?.attunementRequired ?? true)) {
      // Reason: clear cache while attunement is off so toggling it back on
      // forces a fresh computation from current equipment.
      _cachedPlayerManaAttunements = null;
      return _allManaColors;
    }
    if (_cachedPlayerManaAttunements != null) return _cachedPlayerManaAttunements!;
    _cachedPlayerManaAttunements = {...playerInventory.manaAttunements, ...temporaryAttunements};
    return _cachedPlayerManaAttunements!;
  }

  /// Wind state for wind simulation
  final WindState _windState = WindState();

  /// Expose wind state for rendering and movement systems
  WindState get windState => _windState;

  /// Time elapsed since last red mana gain or spend (for decay grace period)
  double _timeSinceLastRedManaChange = 0.0;

  /// Current mana regeneration rate (updated based on Ley Line proximity)
  double currentManaRegenRate = 0.0;

  /// Current red mana regeneration rate (from power nodes only)
  double currentRedManaRegenRate = 0.0;

  /// Ley Line info for current position (for UI display)
  LeyLineInfo? currentLeyLineInfo;

  /// Whether player is currently on a Ley Power node
  bool isOnPowerNode = false;

  /// Spend blue mana for an ability
  /// Returns true if mana was spent, false if not enough mana
  bool spendBlueMana(double amount) {
    if (blueMana >= amount) {
      blueMana -= amount;
      return true;
    }
    return false;
  }

  /// Check if player has enough blue mana
  bool hasBlueMana(double amount) => blueMana >= amount;

  /// Spend red mana for an ability
  /// Returns true if mana was spent, false if not enough mana
  bool spendRedMana(double amount) {
    if (redMana >= amount) {
      redMana -= amount;
      _timeSinceLastRedManaChange = 0.0; // Reset decay timer on spend
      return true;
    }
    return false;
  }

  /// Check if player has enough red mana
  bool hasRedMana(double amount) => redMana >= amount;

  /// Spend white mana for an ability
  /// Returns true if mana was spent, false if not enough mana
  bool spendWhiteMana(double amount) {
    if (whiteMana >= amount) {
      whiteMana -= amount;
      return true;
    }
    return false;
  }

  /// Check if player has enough white mana
  bool hasWhiteMana(double amount) => whiteMana >= amount;

  /// Generate white mana directly (e.g. from items or abilities)
  void generateWhiteMana(double amount) {
    whiteMana = (whiteMana + amount).clamp(0.0, maxWhiteMana);
  }

  /// Spend green mana for an ability
  /// Returns true if mana was spent, false if not enough mana
  bool spendGreenMana(double amount) {
    if (greenMana >= amount) {
      greenMana -= amount;
      return true;
    }
    return false;
  }

  /// Check if player has enough green mana
  bool hasGreenMana(double amount) => greenMana >= amount;

  /// Generate green mana directly (e.g. from regen or abilities)
  void generateGreenMana(double amount) {
    greenMana = (greenMana + amount).clamp(0.0, maxGreenMana);
  }

  /// Spend black mana for an ability. Returns true if spent, false if insufficient.
  bool spendBlackMana(double amount) {
    if (blackMana >= amount) {
      blackMana -= amount;
      return true;
    }
    return false;
  }

  /// Check if player has enough black mana.
  bool canAffordBlackMana(double amount) => blackMana >= amount;

  /// Generate black mana directly (e.g. from items or abilities)
  void generateBlackMana(double amount) {
    blackMana = (blackMana + amount).clamp(0.0, maxBlackMana);
  }

  /// Generate red mana from dealing melee damage
  /// Amount is proportional to damage dealt (default 20% of damage = red mana)
  void generateRedManaFromMelee(double damageDealt) {
    final manaPerDamage = globalManaConfig?.manaPerDamage ?? 0.2;
    final manaGained = damageDealt * manaPerDamage;
    redMana = (redMana + manaGained).clamp(0.0, maxRedMana);
    if (manaGained > 0) {
      _timeSinceLastRedManaChange = 0.0; // Reset decay timer on gain
      print('[MANA] Generated ${manaGained.toStringAsFixed(1)} red mana from melee damage');
    }
  }

  // ==================== LEY LINES ====================

  /// Ley Lines manager - generates and manages magical energy lines
  LeyLineManager? leyLineManager;


  // ==================== MONSTER STATE ====================

  Mesh? monsterMesh;
  Transform3d? monsterTransform;
  Mesh? monsterDirectionIndicator;
  Transform3d? monsterDirectionIndicatorTransform;
  double monsterRotation = 180.0; // Face toward player initially

  // Monster health and abilities
  double monsterHealth = GameConfig.monsterMaxHealth;
  final double monsterMaxHealth = GameConfig.monsterMaxHealth;
  double monsterAbility1Cooldown = 0.0;
  final double monsterAbility1CooldownMax = GameConfig.monsterAbility1CooldownMax;
  double monsterAbility2Cooldown = 0.0;
  final double monsterAbility2CooldownMax = GameConfig.monsterAbility2CooldownMax;
  double monsterAbility3Cooldown = 0.0;
  final double monsterAbility3CooldownMax = GameConfig.monsterAbility3CooldownMax;

  // Monster AI state
  bool monsterPaused = false;
  double monsterAiTimer = 0.0;
  final double monsterAiInterval = GameConfig.monsterAiInterval;
  List<Projectile> monsterProjectiles = [];

  // Monster movement and pathfinding
  BezierPath? monsterCurrentPath;
  double monsterMoveSpeed = 3.0; // Units per second
  String monsterCurrentStrategy = 'BALANCED'; // Current combat strategy

  // ==================== ACTIVE STATUS EFFECTS ====================

  /// Active status effects on the Warchief/player
  List<ActiveEffect> playerActiveEffects = [];

  /// Active status effects on the boss monster
  List<ActiveEffect> monsterActiveEffects = [];


  // Monster sword state (for melee ability 1)
  Mesh? monsterSwordMesh;
  Transform3d? monsterSwordTransform;
  bool monsterAbility1Active = false;
  double monsterAbility1ActiveTime = 0.0;
  bool monsterAbility1HitRegistered = false;

  // ==================== ACTIVE CHARACTER (PARTY) ====================

  /// Index of the active party member: 0 = Warchief, 1+ = ally index + 1
  int activeCharacterIndex = 0;

  /// Whether the active character is the Warchief
  bool get isWarchiefActive => activeCharacterIndex == 0;

  /// Get the active ally (null if Warchief is active)
  Ally? get activeAlly {
    if (activeCharacterIndex == 0 || activeCharacterIndex > allies.length) {
      return null;
    }
    return allies[activeCharacterIndex - 1];
  }

  /// Whether the active character is a summoned unit
  bool get isActiveSummoned => activeAlly?.isSummoned ?? false;

  /// Number of action bar slots for the active character (5 for summoned, 10 for player chars)
  int get activeActionBarSlots => isActiveSummoned ? 5 : 10;

  /// Active effects on the currently controlled character (Warchief or active ally/summon).
  List<ActiveEffect> get activeCharacterActiveEffects {
    if (isWarchiefActive) return playerActiveEffects;
    return activeAlly?.activeEffects ?? [];
  }


  /// Transform of the currently controlled character (Warchief or active ally)
  Transform3d? get activeTransform =>
      isWarchiefActive ? playerTransform : activeAlly?.transform;

  /// Rotation of the currently controlled character
  double get activeRotation =>
      isWarchiefActive ? playerRotation : (activeAlly?.rotation ?? 0.0);

  /// Set rotation of the currently controlled character
  set activeRotation(double val) {
    if (isWarchiefActive) {
      playerRotation = val;
    } else if (activeAlly != null) {
      activeAlly!.rotation = val;
    }
  }

  /// Effective speed of the currently controlled character (includes stance).
  double get activeEffectiveSpeed =>
      isWarchiefActive
          ? effectivePlayerSpeed
          : (activeAlly?.moveSpeed ?? 2.5) * activeStance.movementSpeedMultiplier;

  // ==================== ACTIVE CHARACTER MANA ====================

  /// Active character mana getters — delegate to Warchief or active ally
  double get activeBlueMana => isWarchiefActive ? blueMana : (activeAlly?.blueMana ?? 0.0);
  double get activeRedMana => isWarchiefActive ? redMana : (activeAlly?.redMana ?? 0.0);
  double get activeWhiteMana => isWarchiefActive ? whiteMana : (activeAlly?.whiteMana ?? 0.0);
  double get activeMaxBlueMana => isWarchiefActive ? maxBlueMana : (activeAlly?.maxBlueMana ?? 0.0);
  double get activeMaxRedMana => isWarchiefActive ? maxRedMana : (activeAlly?.maxRedMana ?? 0.0);
  double get activeMaxWhiteMana => isWarchiefActive ? maxWhiteMana : (activeAlly?.maxWhiteMana ?? 0.0);
  double get activeGreenMana => isWarchiefActive ? greenMana : (activeAlly?.greenMana ?? 0.0);
  double get activeMaxGreenMana => isWarchiefActive ? maxGreenMana : (activeAlly?.maxGreenMana ?? 0.0);
  double get activeBlackMana => isWarchiefActive ? blackMana : (activeAlly?.blackMana ?? 0.0);
  double get activeMaxBlackMana => isWarchiefActive ? maxBlackMana : (activeAlly?.maxBlackMana ?? 0.0);

  /// Mana attunements for the active character (Warchief or ally).
  /// When attunement requirement is disabled, returns all four colors.
  Set<ManaColor> get activeManaAttunements {
    if (!(globalGameplaySettings?.attunementRequired ?? true)) return _allManaColors;
    if (isWarchiefActive) return playerManaAttunements;
    final ally = activeAlly;
    if (ally == null) return {};
    return ally.combinedManaAttunements;
  }

  /// Haste percentage for the active character (reduces cast/windup times).
  /// Formula: effectiveTime = baseTime / (1 + haste/100).
  int get activeHaste {
    if (isWarchiefActive) return playerInventory.totalEquippedStats.haste;
    return activeAlly?.inventory.totalEquippedStats.haste ?? 0;
  }

  /// Melt percentage for the active character (reduces cooldown times).
  /// Formula: effectiveCooldown = baseCooldown / (1 + melt/100).
  int get activeMelt {
    if (isWarchiefActive) return playerInventory.totalEquippedStats.melt;
    return activeAlly?.inventory.totalEquippedStats.melt ?? 0;
  }

  /// Active character's per-slot cooldown list (Warchief or ally).
  List<double> get activeAbilityCooldowns {
    if (isWarchiefActive) return abilityCooldowns;
    return activeAlly?.abilityCooldowns ?? abilityCooldowns;
  }

  /// Active character's per-slot max cooldown list.
  List<double> get activeAbilityCooldownMaxes {
    if (isWarchiefActive) return abilityCooldownMaxes;
    return activeAlly?.abilityCooldownMaxes ?? abilityCooldownMaxes;
  }

  /// Check if active character has enough mana
  bool activeHasBlueMana(double amount) => isWarchiefActive ? hasBlueMana(amount) : (activeAlly?.blueMana ?? 0.0) >= amount;
  bool activeHasRedMana(double amount) => isWarchiefActive ? hasRedMana(amount) : (activeAlly?.redMana ?? 0.0) >= amount;
  bool activeHasWhiteMana(double amount) => isWarchiefActive ? hasWhiteMana(amount) : (activeAlly?.whiteMana ?? 0.0) >= amount;
  bool activeHasGreenMana(double amount) => isWarchiefActive ? hasGreenMana(amount) : (activeAlly?.greenMana ?? 0.0) >= amount;
  bool activeHasBlackMana(double amount) => isWarchiefActive ? canAffordBlackMana(amount) : (activeAlly?.blackMana ?? 0.0) >= amount;

  /// Spend mana from active character's pool
  bool activeSpendBlueMana(double amount) {
    if (isWarchiefActive) return spendBlueMana(amount);
    final ally = activeAlly;
    if (ally != null && ally.blueMana >= amount) { ally.blueMana -= amount; return true; }
    return false;
  }

  bool activeSpendRedMana(double amount) {
    if (isWarchiefActive) return spendRedMana(amount);
    final ally = activeAlly;
    if (ally != null && ally.redMana >= amount) { ally.redMana -= amount; return true; }
    return false;
  }

  bool activeSpendWhiteMana(double amount) {
    if (isWarchiefActive) return spendWhiteMana(amount);
    final ally = activeAlly;
    if (ally != null && ally.whiteMana >= amount) { ally.whiteMana -= amount; return true; }
    return false;
  }

  bool activeSpendGreenMana(double amount) {
    if (isWarchiefActive) return spendGreenMana(amount);
    final ally = activeAlly;
    if (ally != null && ally.greenMana >= amount) { ally.greenMana -= amount; return true; }
    return false;
  }

  bool activeSpendBlackMana(double amount) {
    if (isWarchiefActive) return spendBlackMana(amount);
    final ally = activeAlly;
    if (ally != null && ally.blackMana >= amount) { ally.blackMana -= amount; return true; }
    return false;
  }

  /// Set active character's white mana (for Silent Mind restore)
  set activeWhiteMana(double val) {
    if (isWarchiefActive) { whiteMana = val; } else if (activeAlly != null) { activeAlly!.whiteMana = val; }
  }

  // ==================== ACTIVE CHARACTER HEALTH ====================

  /// Active character health getters/setter
  double get activeHealth => isWarchiefActive ? playerHealth : (activeAlly?.health ?? 0.0);
  set activeHealth(double val) {
    if (isWarchiefActive) { playerHealth = val; } else if (activeAlly != null) { activeAlly!.health = val; }
  }
  double get activeMaxHealth => isWarchiefActive ? playerMaxHealth : (activeAlly?.maxHealth ?? 0.0);

  /// Selected index in the character panel carousel (null = not externally set)
  int? characterPanelSelectedIndex;

  // ==================== FRIENDLY TARGET CYCLING ====================

  /// Index for friendly tab targeting cycle
  int _friendlyTabIndex = -1;


  // ==================== ALLY STATE ====================

  List<Ally> allies = []; // Start with zero allies
  FormationType currentFormation = FormationType.scattered; // Active formation
  Map<Ally, TacticalPosition>? _cachedTacticalPositions;
  double _tacticalPositionCacheTime = 0.0;



  // ==================== MINIONS STATE ====================

  /// List of active minion instances
  List<Monster> minions = [];

  /// Whether minions have been spawned this session
  bool minionsSpawned = false;

  /// Direction indicator meshes for minions (shared by type)
  final Map<String, Mesh> _minionDirectionIndicators = {};



  /// Cached list of alive minions, rebuilt once per frame via [refreshAliveMinions].
  List<Monster> _cachedAliveMinions = [];
  int _aliveMinionsFrame = -1;

  /// Get all alive minions (cached per frame).
  /// Call [refreshAliveMinions] once at the start of each game loop tick.
  List<Monster> get aliveMinions => _cachedAliveMinions;




  // ==================== AI CHAT ====================

  List<AIChatMessage> monsterAIChat = [];

  // ==================== TARGETING STATE ====================

  /// Current player target ID ('boss' for main monster, or minion instanceId)
  String? currentTargetId;

  /// Target indicator mesh (yellow dashed rectangle)
  Mesh? targetIndicatorMesh;
  Transform3d? targetIndicatorTransform;
  double lastTargetIndicatorSize = 0.0; // Track size for recreation
  String? lastTargetIndicatorId; // Track target for color change detection

  /// Index for tab targeting cycle
  int _tabTargetIndex = -1;

  /// Cached list of targetable enemies for tab cycling
  List<String> _targetableEnemyIds = [];
  double _targetListCacheTime = 0.0;

  /// Index of minions by instanceId for O(1) lookup.
  final Map<String, Monster> _minionIndex = {};

  /// Maximum range for tab targeting (WoW uses ~40 yards; our units are smaller)
  static const double _tabTargetMaxRange = 50.0;

  /// Melee range threshold — enemies within this distance get highest priority
  static const double _meleeRange = 5.0;


  // ==================== MINIMAP STATE ====================

  /// Minimap state: zoom, pings, elapsed time, terrain cache
  final MinimapState minimapState = MinimapState();

  /// Whether the minimap is currently visible (M key toggle)
  bool minimapOpen = true;

  // ==================== BUILDINGS ====================

  /// Active buildings in the world.
  List<Building> buildings = [];

  /// Whether the building panel is currently open.
  bool buildingPanelOpen = false;

  /// Currently selected building (for interaction panel).
  Building? selectedBuilding;





  // ==================== GOALS ====================

  /// All goals (active, completed, abandoned).
  List<Goal> goals = [];

  /// Convenience: only active goals.
  List<Goal> get activeGoals =>
      goals.where((g) => g.status == GoalStatus.active).toList();

  /// Convenience: completed goals awaiting reflection.
  List<Goal> get completedGoals =>
      goals.where((g) => g.status == GoalStatus.completed).toList();

  /// Warrior Spirit chat messages.
  List<AIChatMessage> warriorSpiritMessages = [];

  /// Goal the Warrior Spirit is currently suggesting (accept/decline).
  GoalDefinition? pendingSpiritGoal;

  /// Whether the goals panel is open (G key).
  bool goalsPanelOpen = false;

  /// Whether the Warrior Spirit panel is open (V key).
  bool warriorSpiritPanelOpen = false;

  // ==================== MACRO / CHAT STATE ====================

  /// Raid Chat messages (system-generated combat alerts).
  List<RaidChatMessage> raidChatMessages = [];

  /// Combat log entries (ability usage and effects).
  List<CombatLogEntry> combatLogMessages = [];

  /// Console log entries (player actions for troubleshooting).
  List<ConsoleLogEntry> consoleLogMessages = [];


  /// Whether the unified chat panel is open (backtick key).
  bool chatPanelOpen = false;

  /// Active tab in the chat panel: 0 = Spirit, 1 = Raid, 2 = Combat, 3 = Console.
  int chatPanelActiveTab = 0;

  /// Melee hit streak tracker (for mastery goals).
  int consecutiveMeleeHits = 0;

  /// Visited power node IDs (for exploration goals).
  Set<String> visitedPowerNodes = {};

  // ==================== UI STATE ====================

  /// Whether the abilities modal is currently open
  bool abilitiesModalOpen = false;

  /// Whether the character panel is currently open
  bool characterPanelOpen = false;

  /// Whether the bag/inventory panel is currently open
  bool bagPanelOpen = false;

  /// Whether the DPS testing panel is currently open
  bool dpsPanelOpen = false;

  /// Whether the unified ally commands panel is currently open (F key)
  bool allyCommandPanelOpen = false;

  /// Whether the macro builder panel is open (R key).
  bool macroPanelOpen = false;

  // ==================== DPS TESTING STATE ====================

  /// DPS tracker for measuring damage output
  final DpsTracker dpsTracker = DpsTracker();

  /// Target dummy for DPS testing (null when not spawned)
  TargetDummy? targetDummy;



  /// Check if target dummy is the current target
  bool get isTargetingDummy => currentTargetId == TargetDummy.instanceId;

  // ==================== INVENTORY STATE ====================

  /// Player inventory (equipment and bag)
  final Inventory playerInventory = Inventory();

  /// Whether the inventory has been initialized with items
  bool inventoryInitialized = false;


  // ==================== FLIGHT STATE ====================

  /// Whether the player is currently flying
  bool isFlying = false;

  /// Current pitch angle in degrees (-45 to +45). Positive = climb, negative = dive.
  double flightPitchAngle = 0.0;

  /// Current flight speed (modified by ALT boost / Space brake)
  double flightSpeed = 7.0;

  /// Current bank angle in degrees. Positive = right, negative = left.
  double flightBankAngle = 0.0;

  /// Current height above terrain (computed each frame by physics system)
  double flightAltitude = 0.0;

  /// Current horizontal ground speed (for HUD display)
  double flightGroundSpeed = 0.0;

  /// Whether the Sovereign of the Sky buff is active
  bool sovereignBuffActive = false;

  /// Remaining time on Sovereign buff
  double sovereignBuffTimer = 0.0;

  /// Whether the Wind Affinity buff is active (doubles white mana regen)
  bool windAffinityActive = false;

  /// Remaining time on Wind Affinity buff
  double windAffinityTimer = 0.0;

  /// Whether Silent Mind is active (next white ability is free + instant)
  bool silentMindActive = false;

  /// Whether Wind Warp flight speed buff is active (doubles flight speed)
  bool windWarpSpeedActive = false;

  /// Remaining time on Wind Warp speed buff
  double windWarpSpeedTimer = 0.0;




  // ==================== JUMP/PHYSICS STATE ====================

  bool isJumping = false;
  double verticalVelocity = 0.0;
  bool isGrounded = true;
  int jumpsRemaining = 2; // Allow 2 jumps total (ground jump + air jump)
  final int maxJumps = 2;
  final double jumpForce = GameConfig.jumpVelocity;
  final double gravity = GameConfig.gravity;
  final double groundLevel = GameConfig.groundLevel;
  bool jumpKeyWasPressed = false; // Track previous jump key state

  // ==================== CASTING/WINDUP STATE ====================

  /// Whether the player is currently casting a spell with cast time
  bool isCasting = false;

  /// Current cast progress in seconds (0 to castTime)
  double castProgress = 0.0;

  /// The total cast time of the current spell being cast
  double currentCastTime = 0.0;

  /// The slot index of the ability being cast
  int? castingSlotIndex;

  /// Name of the ability being cast (for UI display)
  String castingAbilityName = '';

  /// Number of pushbacks applied to the current cast (capped at 3)
  int castPushbackCount = 0;

  /// Whether the player is currently winding up a melee attack
  bool isWindingUp = false;

  /// Current windup progress in seconds (0 to windupTime)
  double windupProgress = 0.0;

  /// The total windup time of the current melee attack
  double currentWindupTime = 0.0;

  /// The slot index of the ability being wound up
  int? windupSlotIndex;

  /// Name of the ability being wound up (for UI display)
  String windupAbilityName = '';

  /// Movement speed modifier from windup (0.0 = stopped, 1.0 = full speed)
  double windupMovementSpeedModifier = 1.0;

  /// Pending mana cost to spend when cast/windup completes.
  /// If interrupted, cost is not spent.
  double pendingManaCost = 0.0;

  /// Whether the pending mana is blue (true) or red (false)
  /// Note: for white mana, use pendingManaType = 2
  bool pendingManaIsBlue = true;

  /// Pending mana type: 0=blue, 1=red, 2=white
  int pendingManaType = 0;

  /// Get the effective movement speed considering windup modifier and stance.
  double get effectivePlayerSpeed =>
      playerSpeed * windupMovementSpeedModifier * activeStance.movementSpeedMultiplier;



  // ==================== CHANNELING STATE ====================

  /// Whether the player is currently channeling a spell
  bool isChanneling = false;

  /// Current channel elapsed time in seconds (0 to channelDuration)
  double channelProgress = 0.0;

  /// Total channel duration of the current spell
  double channelDuration = 0.0;

  /// Name of the ability being channeled (for UI display)
  String channelingAbilityName = '';

  /// The slot index of the ability being channeled
  int? channelingSlotIndex;

  /// Center position for AoE channeled abilities (stored at channel start)
  Vector3? channelAoeCenter;


  /// Get channel progress as percentage (1.0 = just started, 0.0 = about to finish)
  /// Reason: Channeling bar drains from full to empty, opposite of cast bar
  double get channelPercentage => channelDuration > 0 ? (1.0 - channelProgress / channelDuration).clamp(0.0, 1.0) : 0.0;

  /// Check if player is performing any cast/windup/channel action
  bool get isPerformingAction => isCasting || isWindingUp || isChanneling;

  /// Get cast progress as percentage (0.0 to 1.0)
  double get castPercentage => currentCastTime > 0 ? castProgress / currentCastTime : 0.0;

  /// Get windup progress as percentage (0.0 to 1.0)
  double get windupPercentage => currentWindupTime > 0 ? windupProgress / currentWindupTime : 0.0;

  // ==================== GLOBAL COOLDOWN ====================

  /// GCD remaining for the Warchief (seconds)
  double gcdRemaining = 0.0;

  /// GCD max duration for UI display (seconds)
  double gcdMax = 0.0;

  /// GCD remaining for the currently active character
  double get activeGcdRemaining {
    if (isWarchiefActive) return gcdRemaining;
    return activeAlly?.gcdRemaining ?? 0.0;
  }

  // ==================== ABILITY COOLDOWNS (slots 0-9) ====================

  /// Current cooldown remaining per slot (indexed 0-9).
  final List<double> abilityCooldowns = List<double>.filled(10, 0.0);

  /// Maximum cooldown per slot (indexed 0-9).
  final List<double> abilityCooldownMaxes = [
    GameConfig.ability1CooldownMax, // slot 0: Sword
    GameConfig.ability2CooldownMax, // slot 1: Fireball
    GameConfig.ability3CooldownMax, // slot 2: Heal
    6.0,                            // slot 3: Dash Attack
    5.0, 5.0, 5.0, 5.0, 5.0, 5.0,  // slots 4-9: Extended
  ];

  // ==================== ABILITY 1: SWORD ====================

  bool ability1Active = false;
  double ability1ActiveTime = 0.0;
  final double ability1Duration = GameConfig.ability1Duration;
  bool ability1HitRegistered = false; // Prevent multiple hits per swing

  /// Tracks the currently-active generic melee ability data so that
  /// updateAbility1() can read damage/range/impact from it instead of
  /// always using the hardcoded playerSword values.  Null means the
  /// default Sword ability is active.
  AbilityData? activeGenericMeleeAbility;
  Mesh? swordMesh;
  Transform3d? swordTransform;

  // ==================== ABILITY 2: FIREBALL ====================

  List<Projectile> fireballs = []; // List of active fireballs

  // ==================== ABILITY 3: HEAL ====================

  bool ability3Active = false;
  double ability3ActiveTime = 0.0;
  final double ability3Duration = 1.0; // Heal effect duration
  Mesh? healEffectMesh;
  Transform3d? healEffectTransform;

  // ==================== ABILITY 4: DASH ATTACK ====================

  bool ability4Active = false;
  double ability4ActiveTime = 0.0;
  double ability4Duration = 0.4; // Dash duration (set per ability)
  bool ability4HitRegistered = false; // Prevent multiple hits per dash

  /// The ability data driving the current dash (null = legacy playerDashAttack)
  AbilityData? activeDashAbility;

  /// Snapshot of the target position when the dash started (move toward this)
  Vector3? dashTargetPosition;

  Mesh? dashTrailMesh;
  Transform3d? dashTrailTransform;

  // ==================== VISUAL EFFECTS ====================

  List<ImpactEffect> impactEffects = []; // List of active impact effects
  List<DamageIndicator> damageIndicators = []; // Floating damage numbers

  // ==================== MOVEMENT TRACKING ====================

  /// Player movement tracker for AI prediction
  final PlayerMovementTracker playerMovementTracker = PlayerMovementTracker();

  // ==================== GAME LOOP STATE ====================

  int? animationFrameId;
  /// Last requestAnimationFrame timestamp in milliseconds (from performance.now()).
  /// Using the rAF timestamp instead of DateTime.now() gives monotonic,
  /// sub-millisecond precision that is synchronized with display refresh,
  /// preventing timing drift in cast bars and windups.
  double? lastTimestamp;
  int frameCount = 0;

  // ==================== SUMMONED UNITS ====================





}

