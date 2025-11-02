import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/terrain_generator.dart';
import '../../models/projectile.dart';
import '../../models/impact_effect.dart';
import '../../models/ally.dart';
import '../../models/ai_chat_message.dart';
import 'game_config.dart';

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

  List<TerrainTile>? terrainTiles;

  // ==================== PLAYER STATE ====================

  Mesh? playerMesh;
  Transform3d? playerTransform;
  Mesh? directionIndicator;
  Transform3d? directionIndicatorTransform;
  Mesh? shadowMesh;
  Transform3d? shadowTransform;

  double playerRotation = GameConfig.playerStartRotation;
  double playerSpeed = GameConfig.playerSpeed;

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

  // ==================== ALLY STATE ====================

  List<Ally> allies = []; // Start with zero allies

  // ==================== AI CHAT ====================

  List<AIChatMessage> monsterAIChat = [];

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

  // ==================== VISUAL EFFECTS ====================

  List<ImpactEffect> impactEffects = []; // List of active impact effects

  // ==================== GAME LOOP STATE ====================

  int? animationFrameId;
  DateTime? lastFrameTime;
  int frameCount = 0;
}
