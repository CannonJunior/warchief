import 'package:vector_math/vector_math.dart';
import 'mesh.dart';
import 'math/transform3d.dart';

/// PlayerMesh - Generates 3D meshes for player character
///
/// For now, uses a simple colored cube as a placeholder.
/// Can be enhanced later with proper character models, animations, etc.
///
/// Usage:
/// ```dart
/// final player = PlayerMesh.createSimpleCharacter();
/// ```
class PlayerMesh {
  /// Create a simple character representation (colored cube)
  ///
  /// This is a placeholder - good enough to test movement, camera, etc.
  static Mesh createSimpleCharacter({
    double size = 0.8,
    Vector3? bodyColor,
  }) {
    final color = bodyColor ?? Vector3(0.2, 0.5, 0.8); // Default blue

    return Mesh.cube(
      size: size,
      color: color,
    );
  }

  /// Create a more detailed character (stacked cubes for body parts)
  ///
  /// Creates a simple humanoid shape using multiple cubes.
  /// Returns a list of (mesh, transform) for each body part.
  static List<BodyPart> createHumanoidCharacter({
    Vector3? bodyColor,
    Vector3? headColor,
  }) {
    final body = bodyColor ?? Vector3(0.2, 0.5, 0.8); // Blue body
    final head = headColor ?? Vector3(0.9, 0.7, 0.6); // Skin tone

    return [
      // Head
      BodyPart(
        mesh: Mesh.cube(size: 0.4, color: head),
        transform: Transform3d(position: Vector3(0, 1.0, 0)),
        name: 'head',
      ),

      // Torso
      BodyPart(
        mesh: Mesh.cube(size: 0.6, color: body),
        transform: Transform3d(
          position: Vector3(0, 0.5, 0),
          scale: Vector3(1.0, 1.2, 0.5),
        ),
        name: 'torso',
      ),

      // Left Arm
      BodyPart(
        mesh: Mesh.cube(size: 0.3, color: body),
        transform: Transform3d(
          position: Vector3(-0.5, 0.5, 0),
          scale: Vector3(0.5, 1.5, 0.5),
        ),
        name: 'leftArm',
      ),

      // Right Arm
      BodyPart(
        mesh: Mesh.cube(size: 0.3, color: body),
        transform: Transform3d(
          position: Vector3(0.5, 0.5, 0),
          scale: Vector3(0.5, 1.5, 0.5),
        ),
        name: 'rightArm',
      ),

      // Left Leg
      BodyPart(
        mesh: Mesh.cube(size: 0.3, color: body),
        transform: Transform3d(
          position: Vector3(-0.15, -0.3, 0),
          scale: Vector3(0.5, 1.2, 0.5),
        ),
        name: 'leftLeg',
      ),

      // Right Leg
      BodyPart(
        mesh: Mesh.cube(size: 0.3, color: body),
        transform: Transform3d(
          position: Vector3(0.15, -0.3, 0),
          scale: Vector3(0.5, 1.2, 0.5),
        ),
        name: 'rightLeg',
      ),
    ];
  }
}

/// BodyPart - Represents a single body part (mesh + transform)
///
/// Used for multi-part characters where each part can be animated independently.
class BodyPart {
  final Mesh mesh;
  final Transform3d transform;
  final String name;

  BodyPart({
    required this.mesh,
    required this.transform,
    required this.name,
  });

  /// Get world transform by combining with parent character transform
  Transform3d getWorldTransform(Transform3d characterTransform) {
    final worldMatrix = characterTransform.toMatrix() * transform.toMatrix();
    return Transform3d.fromMatrix(worldMatrix);
  }

  @override
  String toString() => 'BodyPart($name)';
}
