import 'package:vector_math/vector_math.dart' hide Colors;
import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';

/// Target Dummy - A practice target for DPS testing
///
/// The target dummy:
/// - Can be targeted and damaged
/// - Has infinite health (doesn't die)
/// - Doesn't fight back
/// - Displays damage numbers
class TargetDummy {
  static const String instanceId = 'target_dummy';
  static const double size = 1.5;

  final Mesh mesh;
  final Transform3d transform;
  Mesh? directionIndicator;
  Transform3d? directionIndicatorTransform;

  /// Current "health" - resets periodically for visual feedback
  double displayHealth;
  final double maxHealth;

  /// Damage taken in current session
  double totalDamageTaken = 0;

  /// Whether the dummy is currently spawned
  bool isSpawned = false;

  TargetDummy({
    required this.mesh,
    required this.transform,
    this.directionIndicator,
    this.directionIndicatorTransform,
    this.displayHealth = 100000,
    this.maxHealth = 100000,
  });

  /// Create a target dummy at a specific position
  factory TargetDummy.spawn(Vector3 position) {
    // Create a distinctive mesh - a wooden dummy color (tan/brown)
    final mesh = Mesh.cube(
      size: size,
      color: Vector3(0.76, 0.60, 0.42), // Burlywood/wooden color
    );

    final transform = Transform3d(
      position: position.clone(),
      scale: Vector3(1, 1, 1),
    );

    // Create direction indicator (yellow triangle for visibility)
    final indicator = Mesh.triangle(
      size: 0.4,
      color: Vector3(1.0, 0.85, 0.0), // Golden yellow
    );

    final indicatorTransform = Transform3d(
      position: Vector3(position.x, position.y + size / 2 + 0.2, position.z),
      scale: Vector3(1, 1, 1),
    );

    final dummy = TargetDummy(
      mesh: mesh,
      transform: transform,
      directionIndicator: indicator,
      directionIndicatorTransform: indicatorTransform,
    );
    dummy.isSpawned = true;
    return dummy;
  }

  /// Take damage (always hits, records damage)
  void takeDamage(double amount) {
    totalDamageTaken += amount;
    // Reduce display health for visual feedback
    displayHealth -= amount;
    // Reset if it goes too low
    if (displayHealth < maxHealth * 0.1) {
      displayHealth = maxHealth;
    }
  }

  /// Reset the dummy's stats
  void reset() {
    displayHealth = maxHealth;
    totalDamageTaken = 0;
  }

  /// Get position
  Vector3 get position => transform.position;

  /// Distance to a point
  double distanceTo(Vector3 point) {
    final dx = transform.position.x - point.x;
    final dy = transform.position.y - point.y;
    final dz = transform.position.z - point.z;
    return _sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Distance to a point (XZ plane only)
  double distanceToXZ(Vector3 point) {
    final dx = transform.position.x - point.x;
    final dz = transform.position.z - point.z;
    return _sqrt(dx * dx + dz * dz);
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
