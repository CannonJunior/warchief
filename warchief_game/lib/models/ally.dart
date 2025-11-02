import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';
import 'projectile.dart';

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
  }) : projectiles = [];
}
