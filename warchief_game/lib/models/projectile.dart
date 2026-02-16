import 'package:vector_math/vector_math.dart';
import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';
import '../game3d/data/abilities/ability_types.dart';

/// Projectile - Represents a moving projectile (like fireball)
class Projectile {
  Mesh mesh;
  Transform3d transform;
  Vector3 velocity;
  double lifetime;

  /// Target ID for homing projectiles (null for non-homing)
  String? targetId;

  /// Speed of the projectile (used for homing to recalculate velocity)
  double speed;

  /// Whether this projectile homes in on its target
  bool isHoming;

  /// Damage dealt by this projectile
  double damage;

  /// Name of the ability (for logging)
  String abilityName;

  /// Impact effect color
  Vector3 impactColor;

  /// Impact effect size
  double impactSize;

  /// Status effect to apply on hit (StatusEffect.none = no effect)
  StatusEffect statusEffect;

  /// Duration of the status effect in seconds
  double statusDuration;

  /// Number of DoT ticks (0 = no DoT)
  int dotTicks;

  Projectile({
    required this.mesh,
    required this.transform,
    required this.velocity,
    this.lifetime = 5.0, // 5 seconds max lifetime
    this.targetId,
    this.speed = 10.0,
    this.isHoming = false,
    this.damage = 10.0,
    this.abilityName = 'Projectile',
    Vector3? impactColor,
    this.impactSize = 0.5,
    this.statusEffect = StatusEffect.none,
    this.statusDuration = 0.0,
    this.dotTicks = 0,
  }) : impactColor = impactColor ?? Vector3(1.0, 0.5, 0.0);
}
