import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';

/// Transform3d - Represents position, rotation, and scale in 3D space
///
/// This class is the foundation for all 3D objects (camera, meshes, etc).
/// It supports separate pitch, yaw, and roll rotations for dual-axis camera control.
///
/// Usage:
/// ```dart
/// final transform = Transform3d(
///   position: Vector3(0, 0, 10),
///   rotation: Vector3(0, 45, 0), // pitch, yaw, roll in degrees
///   scale: Vector3(1, 1, 1),
/// );
/// final matrix = transform.toMatrix();
/// ```
class Transform3d {
  /// Position in 3D space (x, y, z)
  Vector3 position;

  /// Rotation in degrees (pitch, yaw, roll)
  /// - pitch: rotation around X-axis (looking up/down)
  /// - yaw: rotation around Y-axis (looking left/right)
  /// - roll: rotation around Z-axis (tilting head)
  Vector3 rotation;

  /// Scale factor (x, y, z)
  Vector3 scale;

  Transform3d({
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
  })  : position = position ?? Vector3.zero(),
        rotation = rotation ?? Vector3.zero(),
        scale = scale ?? Vector3(1, 1, 1);

  /// Create a transform from a 4x4 matrix
  factory Transform3d.fromMatrix(Matrix4 matrix) {
    final position = matrix.getTranslation();
    final scale = matrix.getMaxScaleOnAxis();
    // Note: Extracting rotation from matrix is complex; use direct rotation values when possible
    return Transform3d(
      position: position,
      scale: Vector3(scale, scale, scale),
    );
  }

  /// Convert this transform into a 4x4 transformation matrix
  ///
  /// Matrix order: Scale -> Rotate -> Translate
  /// This is the standard order for 3D transformations.
  Matrix4 toMatrix() {
    final matrix = Matrix4.identity();

    // Apply translation
    matrix.translate(position);

    // Apply rotation (pitch, yaw, roll)
    // Order matters: yaw -> pitch -> roll (Y -> X -> Z)
    final yawRad = radians(rotation.y);
    final pitchRad = radians(rotation.x);
    final rollRad = radians(rotation.z);

    matrix.rotateY(yawRad);
    matrix.rotateX(pitchRad);
    matrix.rotateZ(rollRad);

    // Apply scale
    matrix.scale(scale);

    return matrix;
  }

  /// Get forward direction vector (where this transform is "looking")
  ///
  /// In our coordinate system:
  /// - Forward is -Z axis (into the screen)
  /// - This is affected by yaw and pitch rotation
  Vector3 get forward {
    final yawRad = radians(rotation.y);
    final pitchRad = radians(rotation.x);

    return Vector3(
      -math.sin(yawRad) * math.cos(pitchRad),
      math.sin(pitchRad),
      -math.cos(yawRad) * math.cos(pitchRad),
    ).normalized();
  }

  /// Get right direction vector (perpendicular to forward)
  Vector3 get right {
    final yawRad = radians(rotation.y);

    return Vector3(
      math.cos(yawRad),
      0,
      -math.sin(yawRad),
    ).normalized();
  }

  /// Get up direction vector (perpendicular to forward and right)
  Vector3 get up {
    return forward.cross(right).normalized();
  }

  /// Translate by a delta vector
  void translate(Vector3 delta) {
    position += delta;
  }

  /// Rotate by delta angles (in degrees)
  void rotate(Vector3 deltaRotation) {
    rotation += deltaRotation;

    // Keep angles in reasonable range (-360 to 360)
    rotation.x = rotation.x % 360;
    rotation.y = rotation.y % 360;
    rotation.z = rotation.z % 360;
  }

  /// Apply uniform scale
  void scaleUniform(double factor) {
    scale.scale(factor);
  }

  /// Clone this transform
  Transform3d clone() {
    return Transform3d(
      position: Vector3.copy(position),
      rotation: Vector3.copy(rotation),
      scale: Vector3.copy(scale),
    );
  }

  /// Linearly interpolate between this transform and another
  ///
  /// t = 0 returns this transform
  /// t = 1 returns other transform
  /// t = 0.5 returns halfway between
  Transform3d lerp(Transform3d other, double t) {
    return Transform3d(
      position: position * (1 - t) + other.position * t,
      rotation: rotation * (1 - t) + other.rotation * t,
      scale: scale * (1 - t) + other.scale * t,
    );
  }

  @override
  String toString() {
    return 'Transform3d(pos: $position, rot: $rotation, scale: $scale)';
  }
}
