import 'package:vector_math/vector_math.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/item.dart' show EquipmentSlot;

/// A single visible equipment piece attached to a character in the 3D world.
///
/// The [worldTransform] is mutable and updated each frame by [EquipmentRenderer]
/// based on the character's world position and yaw.  This mirrors the
/// auraMesh/auraTransform pattern on [Ally].
class EquipmentVisual {
  final Mesh mesh;

  /// World-space transform — mutated every frame, no allocation.
  final Transform3d worldTransform;

  /// Offset in character-local space (before yaw rotation is applied).
  final Vector3 localOffset;

  final EquipmentSlot slot;

  EquipmentVisual({
    required this.mesh,
    required this.localOffset,
    required this.slot,
  }) : worldTransform = Transform3d();
}
