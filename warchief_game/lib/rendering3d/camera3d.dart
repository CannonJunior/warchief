import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import 'math/transform3d.dart';

/// Camera3D - 3D perspective camera with dual-axis rotation
///
/// Supports true pitch (X-axis) and yaw (Y-axis) rotation for WoW-style camera control.
/// This camera generates view and projection matrices for 3D rendering.
///
/// Usage:
/// ```dart
/// final camera = Camera3D(
///   fov: 60,
///   aspectRatio: 16/9,
///   near: 0.1,
///   far: 1000.0,
/// );
/// camera.setTarget(Vector3(0, 0, 0));
/// camera.pitchBy(10); // N/M keys
/// camera.yawBy(15);   // J/L keys
/// final viewMatrix = camera.getViewMatrix();
/// final projMatrix = camera.getProjectionMatrix();
/// ```
class Camera3D {
  /// Transform for camera position and rotation
  final Transform3d transform;

  /// Field of view (degrees)
  double fov;

  /// Aspect ratio (width / height)
  double aspectRatio;

  /// Near clipping plane distance
  final double near;

  /// Far clipping plane distance
  final double far;

  /// Target position to look at (null = use forward direction)
  Vector3? _target;

  /// Distance from target (for orbiting)
  double _targetDistance = 10.0;

  /// Min/max pitch angles (in degrees)
  final double minPitch = -89.0;  // Almost straight down
  final double maxPitch = 89.0;   // Almost straight up

  Camera3D({
    Vector3? position,
    Vector3? rotation,
    this.fov = 60.0,
    this.aspectRatio = 16.0 / 9.0,
    this.near = 0.1,
    this.far = 1000.0,
  }) : transform = Transform3d(
          position: position ?? Vector3(0, 5, 10),
          rotation: rotation ?? Vector3(0, 0, 0),
        );

  /// Get the view matrix for rendering
  ///
  /// View matrix transforms world space to camera space.
  /// This is the inverse of the camera's transform matrix.
  Matrix4 getViewMatrix() {
    if (_target != null) {
      // Look-at mode: camera looks at target
      return makeViewMatrix(
        transform.position,
        _target!,
        Vector3(0, 1, 0), // Up vector
      );
    } else {
      // Free-look mode: use camera's forward direction
      final forward = transform.forward;
      final lookAt = transform.position + forward;
      return makeViewMatrix(
        transform.position,
        lookAt,
        Vector3(0, 1, 0),
      );
    }
  }

  /// Get the projection matrix for rendering
  ///
  /// Projection matrix transforms camera space to clip space.
  /// This creates the perspective effect (far objects appear smaller).
  Matrix4 getProjectionMatrix() {
    return makePerspectiveMatrix(
      radians(fov),
      aspectRatio,
      near,
      far,
    );
  }

  /// Set a target position for the camera to orbit around
  void setTarget(Vector3 target) {
    _target = target;
    updatePositionFromTarget();
  }

  /// Clear target (switch to free-look mode)
  void clearTarget() {
    _target = null;
  }

  /// Update camera position based on target and current rotation
  ///
  /// This positions the camera at _targetDistance from the target,
  /// using current pitch/yaw angles.
  void updatePositionFromTarget() {
    if (_target == null) return;

    // Calculate camera position based on spherical coordinates
    final pitchRad = radians(transform.rotation.x);
    final yawRad = radians(transform.rotation.y);

    // Spherical to Cartesian conversion
    final x = _targetDistance * -math.sin(yawRad) * math.cos(pitchRad);
    final y = _targetDistance * math.sin(pitchRad);
    final z = _targetDistance * -math.cos(yawRad) * math.cos(pitchRad);

    transform.position = _target! + Vector3(x, y, z);
  }

  /// Rotate camera up/down (pitch - N/M keys)
  ///
  /// Positive delta looks up, negative looks down.
  /// This is rotation around the X-axis.
  void pitchBy(double deltaDegrees) {
    transform.rotation.x = (transform.rotation.x + deltaDegrees)
        .clamp(minPitch, maxPitch);

    if (_target != null) {
      updatePositionFromTarget();
    }
  }

  /// Rotate camera left/right (yaw - J/L keys)
  ///
  /// Positive delta rotates right, negative rotates left.
  /// This is rotation around the Y-axis.
  void yawBy(double deltaDegrees) {
    transform.rotation.y = (transform.rotation.y + deltaDegrees) % 360.0;

    if (_target != null) {
      updatePositionFromTarget();
    }
  }

  /// Set distance from target
  void setTargetDistance(double distance) {
    _targetDistance = distance.clamp(1.0, 100.0);

    if (_target != null) {
      updatePositionFromTarget();
    }
  }

  /// Zoom in/out by adjusting target distance
  void zoom(double delta) {
    setTargetDistance(_targetDistance + delta);
  }

  /// Move camera forward/backward along its forward direction
  void moveForward(double distance) {
    transform.position += transform.forward * distance;
  }

  /// Move camera right/left along its right direction
  void strafe(double distance) {
    transform.position += transform.right * distance;
  }

  /// Move camera up/down in world space
  void moveVertical(double distance) {
    transform.position.y += distance;
  }

  /// Get current pitch angle (degrees)
  double get pitch => transform.rotation.x;

  /// Get current yaw angle (degrees)
  double get yaw => transform.rotation.y;

  /// Get current position
  Vector3 get position => transform.position;

  /// Get forward direction
  Vector3 get forward => transform.forward;

  /// Get right direction
  Vector3 get right => transform.right;

  /// Get up direction
  Vector3 get up => transform.up;
}
