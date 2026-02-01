import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';
import 'projectile.dart';
import '../game3d/utils/bezier_path.dart';

/// Ally Movement Mode - Different ways an ally can move
enum AllyMovementMode {
  stationary, // Stays in place
  followPlayer, // Follows player at buffer distance
  commanded, // Moves to commanded position
  tactical, // AI-controlled tactical movement
}

/// Player commands for ally control
enum AllyCommand {
  none, // No active command - use AI
  follow, // Follow player closely
  attack, // Aggressively attack enemy
  hold, // Hold current position
  defensive, // Prioritize survival
}

/// Ally - Represents an allied NPC character
class Ally {
  Mesh mesh;
  Transform3d transform;
  Transform3d? directionIndicatorTransform;
  double rotation;
  double health;
  double maxHealth;
  int abilityIndex; // 0, 1, or 2 (which player ability they have)
  double abilityCooldown;
  double abilityCooldownMax;
  double aiTimer;
  final double aiInterval = 1.0; // Think every 1 second for responsive AI
  List<Projectile> projectiles;

  // Movement and pathfinding
  AllyMovementMode movementMode;
  BezierPath? currentPath;
  double moveSpeed;
  double followBufferDistance; // Distance to maintain from player when following
  bool isMoving;

  // Player command system
  AllyCommand currentCommand;
  double commandTimer; // Time since command was issued

  Ally({
    required this.mesh,
    required this.transform,
    this.directionIndicatorTransform,
    this.rotation = 0.0,
    this.health = 50.0,
    this.maxHealth = 50.0,
    required this.abilityIndex,
    this.abilityCooldown = 0.0,
    this.abilityCooldownMax = 5.0,
    this.aiTimer = 0.0,
    this.movementMode = AllyMovementMode.followPlayer,
    this.moveSpeed = 2.5,
    this.followBufferDistance = 4.0,
    this.isMoving = false,
    this.currentCommand = AllyCommand.none,
    this.commandTimer = 0.0,
  }) : projectiles = [];
}
