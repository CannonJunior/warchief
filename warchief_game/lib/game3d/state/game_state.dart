import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/terrain_generator.dart';
import '../../rendering3d/heightmap.dart';
import '../../rendering3d/infinite_terrain_manager.dart';
import '../../models/projectile.dart';
import '../../models/impact_effect.dart';
import '../../models/ally.dart';
import '../../models/ai_chat_message.dart';
import '../../models/monster.dart';
import '../../models/monster_ontology.dart';
import 'game_config.dart';
import '../utils/movement_prediction.dart';
import '../utils/bezier_path.dart';
import '../ai/tactical_positioning.dart';
import '../data/monsters/minion_definitions.dart';

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

  double playerRotation = GameConfig.playerStartRotation;
  double playerSpeed = GameConfig.playerSpeed;

  // Player health
  double playerHealth = 100.0;
  final double playerMaxHealth = 100.0;

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

  // Monster sword state (for melee ability 1)
  Mesh? monsterSwordMesh;
  Transform3d? monsterSwordTransform;
  bool monsterAbility1Active = false;
  double monsterAbility1ActiveTime = 0.0;
  bool monsterAbility1HitRegistered = false;

  // ==================== ALLY STATE ====================

  List<Ally> allies = []; // Start with zero allies
  FormationType currentFormation = FormationType.scattered; // Active formation
  Map<Ally, TacticalPosition>? _cachedTacticalPositions;
  double _tacticalPositionCacheTime = 0.0;

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

  // ==================== MINIONS STATE ====================

  /// List of active minion instances
  List<Monster> minions = [];

  /// Whether minions have been spawned this session
  bool minionsSpawned = false;

  /// Direction indicator meshes for minions (shared by type)
  final Map<String, Mesh> _minionDirectionIndicators = {};

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

  /// Spawn all minions according to DefaultMinionSpawns configuration
  /// Total: 8 Goblin Rogues + 4 Orc Warlocks + 2 Cultist Priests + 1 Skeleton Champion = 15 minions
  void spawnMinions(InfiniteTerrainManager? terrainManager) {
    if (minionsSpawned) return;

    print('[MINIONS] Spawning minions...');
    print(DefaultMinionSpawns.summary);

    // Base spawn position (offset from monster)
    final baseX = GameConfig.monsterStartPosition.x;
    final baseZ = GameConfig.monsterStartPosition.z - 10; // Behind the boss

    int totalSpawned = 0;

    for (final spawnConfig in DefaultMinionSpawns.spawns) {
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

      // Adjust Y positions to terrain height
      for (final monster in monsters) {
        if (terrainManager != null) {
          final terrainY = terrainManager.getTerrainHeight(
            monster.transform.position.x,
            monster.transform.position.z,
          );
          monster.transform.position.y = terrainY;
          if (monster.directionIndicatorTransform != null) {
            monster.directionIndicatorTransform!.position.y =
                terrainY + definition.effectiveScale * 0.6;
          }
        }
      }

      minions.addAll(monsters);
      totalSpawned += spawnConfig.count;

      print('[MINIONS] Spawned ${spawnConfig.count}x ${definition.name} '
          '(MP ${definition.monsterPower})');
    }

    minionsSpawned = true;
    print('[MINIONS] Total spawned: ${minions.length} minions');
    print('[MINIONS] Total Monster Power: ${DefaultMinionSpawns.totalMonsterPower}');
  }

  /// Get all alive minions
  List<Monster> get aliveMinions => minions.where((m) => m.isAlive).toList();

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

  // ==================== AI CHAT ====================

  List<AIChatMessage> monsterAIChat = [];

  // ==================== UI STATE ====================

  /// Whether the abilities modal is currently open
  bool abilitiesModalOpen = false;

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

  // ==================== ABILITY 1: SWORD ====================

  double ability1Cooldown = 0.0;
  final double ability1CooldownMax = GameConfig.ability1CooldownMax;
  bool ability1Active = false;
  double ability1ActiveTime = 0.0;
  final double ability1Duration = GameConfig.ability1Duration;
  bool ability1HitRegistered = false; // Prevent multiple hits per swing
  Mesh? swordMesh;
  Transform3d? swordTransform;

  // ==================== ABILITY 2: FIREBALL ====================

  double ability2Cooldown = 0.0;
  final double ability2CooldownMax = GameConfig.ability2CooldownMax;
  List<Projectile> fireballs = []; // List of active fireballs

  // ==================== ABILITY 3: HEAL ====================

  double ability3Cooldown = 0.0;
  final double ability3CooldownMax = GameConfig.ability3CooldownMax;
  bool ability3Active = false;
  double ability3ActiveTime = 0.0;
  final double ability3Duration = 1.0; // Heal effect duration
  Mesh? healEffectMesh;
  Transform3d? healEffectTransform;

  // ==================== ABILITY 4: DASH ATTACK ====================

  double ability4Cooldown = 0.0;
  final double ability4CooldownMax = 6.0; // 6 second cooldown
  bool ability4Active = false;
  double ability4ActiveTime = 0.0;
  final double ability4Duration = 0.4; // Dash duration
  bool ability4HitRegistered = false; // Prevent multiple hits per dash
  Mesh? dashTrailMesh;
  Transform3d? dashTrailTransform;

  // ==================== VISUAL EFFECTS ====================

  List<ImpactEffect> impactEffects = []; // List of active impact effects

  // ==================== MOVEMENT TRACKING ====================

  /// Player movement tracker for AI prediction
  final PlayerMovementTracker playerMovementTracker = PlayerMovementTracker();

  // ==================== GAME LOOP STATE ====================

  int? animationFrameId;
  DateTime? lastFrameTime;
  int frameCount = 0;
}
