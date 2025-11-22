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
  final double aiInterval = 3.0; // Think every 3 seconds
  List<Projectile> projectiles;

  // Movement and pathfinding
  AllyMovementMode movementMode;
  BezierPath? currentPath;
  double moveSpeed;
  double followBufferDistance; // Distance to maintain from player when following
  bool isMoving;

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
    this.movementMode = AllyMovementMode.stationary,
    this.moveSpeed = 2.5,
    this.followBufferDistance = 4.0,
    this.isMoving = false,
  }) : projectiles = [];
}
