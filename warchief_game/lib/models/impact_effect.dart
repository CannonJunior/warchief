import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';

/// ImpactEffect - Visual effect for projectile impacts
class ImpactEffect {
  Mesh mesh;
  Transform3d transform;
  double lifetime;
  double maxLifetime;

  ImpactEffect({
    required this.mesh,
    required this.transform,
    this.lifetime = 0.5, // 0.5 seconds impact animation
  }) : maxLifetime = lifetime;

  double get progress => 1.0 - (lifetime / maxLifetime);
}
