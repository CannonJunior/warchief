import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import 'math/transform3d.dart';

/// Camera Mode - Different camera perspectives
enum CameraMode {
  static,       // Static orbit camera
  thirdPerson,  // Third-person over-the-shoulder following camera
}

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

  /// Current camera mode
  CameraMode _mode = CameraMode.static;

  /// Third-person camera settings
  double _thirdPersonDistance = 8.0;  // Distance behind player
  double _thirdPersonHeight = 4.0;     // Height above player
  double _thirdPersonPitch = 25.0;     // Fixed pitch angle for third-person
  final double _thirdPersonFOV = 90.0; // Wide FOV for third-person view
  final double _staticFOV = 60.0;      // Standard FOV for static camera

  /// Camera roll angle in degrees (for cockpit-style banking tilt)
  double rollAngle = 0.0;

  /// Y-offset added to the look-at target for flight pitch following.
  double targetPitchOffset = 0.0;

  /// Smooth camera interpolation speed
  final double _cameraLerpSpeed = 8.0;

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
  /// When rollAngle != 0, the up vector is rotated around the view direction
  /// to create cockpit-style camera tilt during flight banking.
  Matrix4 getViewMatrix() {
    final up = _getCameraUpVector();

    if (_target != null) {
      // Look-at mode: camera looks at target (with optional pitch offset)
      final effectiveTarget = targetPitchOffset != 0.0
          ? Vector3(_target!.x, _target!.y + targetPitchOffset, _target!.z)
          : _target!;
      return makeViewMatrix(
        transform.position,
        effectiveTarget,
        up,
      );
    } else {
      // Free-look mode: use camera's forward direction
      final forward = transform.forward;
      final lookAt = transform.position + forward;
      return makeViewMatrix(
        transform.position,
        lookAt,
        up,
      );
    }
  }

  /// Compute the camera up vector, rotated by rollAngle for banking tilt.
  ///
  /// Uses Rodrigues' rotation formula to rotate world-up around the
  /// view direction axis by rollAngle degrees.
  Vector3 _getCameraUpVector() {
    if (rollAngle == 0.0) return Vector3(0, 1, 0);

    // Determine view direction
    Vector3 viewDir;
    if (_target != null) {
      viewDir = (_target! - transform.position).normalized();
    } else {
      viewDir = transform.forward;
    }

    // Rodrigues' rotation: rotate worldUp around viewDir by rollAngle
    final rollRad = radians(rollAngle);
    final cosA = math.cos(rollRad);
    final sinA = math.sin(rollRad);
    final worldUp = Vector3(0, 1, 0);
    final dot = viewDir.dot(worldUp);
    final cross = viewDir.cross(worldUp);

    return worldUp * cosA + cross * sinA + viewDir * (dot * (1 - cosA));
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

  /// Get the current target position
  Vector3 getTarget() {
    return _target ?? Vector3.zero();
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

  // ==================== CAMERA MODE MANAGEMENT ====================

  /// Get current camera mode
  CameraMode get mode => _mode;

  /// Set camera mode
  void setMode(CameraMode newMode) {
    if (_mode == newMode) return;

    _mode = newMode;

    // Adjust FOV based on mode
    if (_mode == CameraMode.thirdPerson) {
      fov = _thirdPersonFOV;
    } else {
      fov = _staticFOV;
    }
  }

  /// Toggle between camera modes
  void toggleMode() {
    if (_mode == CameraMode.static) {
      setMode(CameraMode.thirdPerson);
    } else {
      setMode(CameraMode.static);
    }
  }

  /// Update camera in third-person mode to follow a target
  ///
  /// Parameters:
  /// - targetPosition: Position of the player/target to follow
  /// - targetRotation: Y-axis rotation of the player (in degrees)
  /// - dt: Delta time for smooth interpolation
  void updateThirdPersonFollow(Vector3 targetPosition, double targetRotation, double dt) {
    if (_mode != CameraMode.thirdPerson) return;

    // Calculate desired camera position behind the player
    // Add 180 degrees to position camera behind instead of in front
    final rotationRad = radians(targetRotation + 180.0);

    // Position behind player based on their rotation
    final offsetX = -math.sin(rotationRad) * _thirdPersonDistance;
    final offsetZ = -math.cos(rotationRad) * _thirdPersonDistance;

    final desiredPosition = Vector3(
      targetPosition.x + offsetX,
      targetPosition.y + _thirdPersonHeight,
      targetPosition.z + offsetZ,
    );

    // Smooth interpolation to desired position
    final lerpFactor = math.min(1.0, _cameraLerpSpeed * dt);
    transform.position = Vector3(
      transform.position.x + (desiredPosition.x - transform.position.x) * lerpFactor,
      transform.position.y + (desiredPosition.y - transform.position.y) * lerpFactor,
      transform.position.z + (desiredPosition.z - transform.position.z) * lerpFactor,
    );

    // Set camera to look at a point slightly above the player
    final lookAtPoint = Vector3(
      targetPosition.x,
      targetPosition.y + 1.0,  // Look at player's upper body/head area
      targetPosition.z,
    );

    _target = lookAtPoint;

    // Set the pitch angle for third-person view
    transform.rotation.x = _thirdPersonPitch;
    transform.rotation.y = targetRotation; // Camera faces same direction as player (towards the player from behind)
  }

  /// Set third-person camera distance from player
  void setThirdPersonDistance(double distance) {
    _thirdPersonDistance = distance.clamp(3.0, 15.0);
  }

  /// Set third-person camera height above player
  void setThirdPersonHeight(double height) {
    _thirdPersonHeight = height.clamp(1.0, 10.0);
  }

  /// Set third-person camera pitch angle
  void setThirdPersonPitch(double pitch) {
    _thirdPersonPitch = pitch.clamp(0.0, 60.0);
  }
}
