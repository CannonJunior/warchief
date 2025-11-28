import 'package:vector_math/vector_math.dart';

import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/terrain_generator.dart';
import '../../rendering3d/heightmap.dart';
import '../../rendering3d/infinite_terrain_manager.dart';
import '../../models/projectile.dart';
import '../../models/impact_effect.dart';
import '../../models/ally.dart';
import '../../models/ai_chat_message.dart';
import '../../models/football.dart';
import 'game_config.dart';
import '../utils/movement_prediction.dart';
import '../utils/bezier_path.dart';

/// Game State - Centralized state management for the 3D game
///
/// This class holds all mutable game state including:
/// - Player state (position, rotation, abilities, health)
/// - Monster state (position, rotation, abilities, health, AI)
/// - Ally state
/// - Projectiles and visual effects
/// - Game loop state (frame count, timing)
class GameState {
  // ==================== SINGLETON MESHES (REUSABLE) ====================

  /// Singleton projectile meshes (reused to prevent memory leak)
  /// These are created once and reused for all projectiles
  static Mesh? _fireballMeshSingleton;
  static Mesh? _shadowBoltMeshSingleton;
  static Mesh? _impactEffectMeshSingleton;

  /// Get or create fireball mesh singleton
  Mesh getFireballMesh() {
    _fireballMeshSingleton ??= Mesh.cube(
      size: 0.3,
      color: Vector3(1.0, 0.4, 0.0), // Orange fireball
    );
    return _fireballMeshSingleton!;
  }

  /// Get or create shadow bolt mesh singleton
  Mesh getShadowBoltMesh() {
    _shadowBoltMeshSingleton ??= Mesh.cube(
      size: 0.4,
      color: Vector3(0.5, 0.1, 0.8), // Purple shadow bolt
    );
    return _shadowBoltMeshSingleton!;
  }

  /// Get or create impact effect mesh singleton
  Mesh getImpactEffectMesh() {
    _impactEffectMeshSingleton ??= Mesh.cube(
      size: 0.5,
      color: Vector3(1.0, 1.0, 0.0), // Yellow impact
    );
    return _impactEffectMeshSingleton!;
  }

  // ==================== TERRAIN ====================

  // Old terrain system (for backwards compatibility)
  List<TerrainTile>? terrainTiles;
  Heightmap? terrainHeightmap; // For collision detection

  // New infinite terrain system with LOD
  InfiniteTerrainManager? infiniteTerrainManager;

  // ==================== FOOTBALL FIELD ====================

  // Football field components
  Mesh? footballFieldMesh;
  Transform3d? footballFieldTransform;
  List<({Mesh mesh, Transform3d transform})> footballFieldMarkings = [];
  List<({Mesh mesh, Transform3d transform})> footballFieldEndZones = [];
  List<({Mesh mesh, Transform3d transform})> footballFieldGoalPosts = [];

  // ==================== FOOTBALL (BALL) STATE ====================

  /// Active football (when thrown/fumbled)
  Football? activeFootball;

  /// Ball possession state
  bool ballCarrierHasBall = true;

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

  // ==================== AI CHAT ====================

  List<AIChatMessage> monsterAIChat = [];

  // ==================== UI STATE ====================

  /// Whether the abilities modal is currently open
  bool abilitiesModalOpen = false;

  /// Whether the playbook modal is currently open
  bool playbookModalOpen = false;

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

  // ==================== ABILITY 1: BULLET PASS ====================

  double ability1Cooldown = 0.0;
  final double ability1CooldownMax = GameConfig.ability1CooldownMax;
  bool ability1Active = false;
  double ability1ActiveTime = 0.0;
  final double ability1Duration = GameConfig.ability1Duration;
  bool ability1HitRegistered = false; // Prevent multiple hits
  Mesh? swordMesh; // Reused for visual effects
  Transform3d? swordTransform;

  // ==================== ABILITY 2: SPRINT ====================

  double ability2Cooldown = 0.0;
  final double ability2CooldownMax = GameConfig.ability2CooldownMax;
  bool ability2Active = false;
  double ability2ActiveTime = 0.0;
  List<Projectile> fireballs = []; // Reused for football projectiles (Bullet Pass)

  // ==================== ABILITY 3: SPIN-OUT ====================

  double ability3Cooldown = 0.0;
  final double ability3CooldownMax = GameConfig.ability3CooldownMax;
  bool ability3Active = false;
  double ability3ActiveTime = 0.0;
  final double ability3Duration = GameConfig.ability3Duration;
  bool ability3SpinClockwise = false; // Spin direction (true = clockwise, false = counter-clockwise)
  Vector3? ability3PivotPoint; // Pivot point for orbital spinning (left edge for CCW, right edge for CW)
  Vector3? ability3StartPosition; // Player position at start of spin
  double ability3StartRotation = 0.0; // Player rotation at start of spin
  Mesh? healEffectMesh; // Reused for visual effects
  Transform3d? healEffectTransform;

  // ==================== VISUAL EFFECTS ====================

  List<ImpactEffect> impactEffects = []; // List of active impact effects

  // ==================== MOVEMENT TRACKING ====================

  /// Player movement tracker for AI prediction
  final PlayerMovementTracker playerMovementTracker = PlayerMovementTracker();

  // ==================== GAME LOOP STATE ====================

  int? animationFrameId;
  DateTime? lastFrameTime;
  int frameCount = 0;

  // Frame rate limiting - target 60 FPS
  static const double targetFrameTime = 1000 / 60; // ~16.67ms per frame for 60 FPS
  double frameTimeAccumulator = 0.0;

  // PERFORMANCE FIX: AI throttling (run every 100ms instead of every frame)
  double aiAccumulatedTime = 0.0;
  static const double aiUpdateInterval = 0.1; // 100ms = 10 updates per second
}
