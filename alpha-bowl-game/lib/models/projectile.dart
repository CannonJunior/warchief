import 'package:vector_math/vector_math.dart';
import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';

/// Projectile - Represents a moving projectile (like fireball)
class Projectile {
  Mesh mesh;
  Transform3d transform;
  Vector3 velocity;
  double lifetime;

  Projectile({
    required this.mesh,
    required this.transform,
    required this.velocity,
    this.lifetime = 5.0, // 5 seconds max lifetime
  });
}
