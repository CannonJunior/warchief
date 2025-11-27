import 'package:vector_math/vector_math.dart';
import '../../rendering3d/camera3d.dart';

/// Culling System - Optimizes rendering by skipping off-screen objects
///
/// Provides frustum culling and distance culling to avoid processing
/// objects that don't need to be animated or rendered.
class CullingSystem {
  CullingSystem._(); // Private constructor

  // ==================== FIELD BOUNDARIES ====================

  /// Football field dimensions (in units, matching FootballFieldGenerator)
  static const double fieldLength = 120.0; // 120 yards total (100 + 2x10 end zones)
  static const double fieldWidth = 53.3; // 53.3 yards wide

  /// Extra margin beyond field boundaries for culling (in units)
  static const double cullMargin = 20.0; // Objects 20 units outside field are culled

  /// Field bounds (pre-calculated)
  static const double minX = -(fieldWidth / 2 + cullMargin);
  static const double maxX = (fieldWidth / 2 + cullMargin);
  static const double minZ = -(fieldLength / 2 + cullMargin);
  static const double maxZ = (fieldLength / 2 + cullMargin);

  // ==================== DISTANCE CULLING ====================

  /// Maximum distance from camera before objects are culled
  /// Objects beyond this distance don't need AI updates or detailed rendering
  static const double maxRenderDistance = 100.0; // Units

  /// Distance beyond which to skip AI updates (but still render)
  static const double maxAIUpdateDistance = 80.0; // Units

  /// Check if a position is within field boundaries + margin
  ///
  /// Used for projectiles and objects that can go off-field.
  /// Football is exempt from this check.
  ///
  /// Parameters:
  /// - position: World position to check
  ///
  /// Returns:
  /// - true if position is within bounds, false if it should be culled
  static bool isWithinFieldBounds(Vector3 position) {
    return position.x >= minX &&
           position.x <= maxX &&
           position.z >= minZ &&
           position.z <= maxZ;
  }

  /// Check if a position is within camera render distance
  ///
  /// Objects beyond this distance can skip rendering entirely.
  ///
  /// Parameters:
  /// - position: World position to check
  /// - cameraPosition: Camera world position
  ///
  /// Returns:
  /// - true if within render distance, false if too far
  static bool isWithinRenderDistance(Vector3 position, Vector3 cameraPosition) {
    final distance = (position - cameraPosition).length;
    return distance <= maxRenderDistance;
  }

  /// Check if a position is within AI update distance
  ///
  /// Objects beyond this distance can skip AI/animation updates.
  ///
  /// Parameters:
  /// - position: World position to check
  /// - cameraPosition: Camera world position
  ///
  /// Returns:
  /// - true if AI should update, false if too far
  static bool shouldUpdateAI(Vector3 position, Vector3 cameraPosition) {
    final distance = (position - cameraPosition).length;
    return distance <= maxAIUpdateDistance;
  }

  /// Simple frustum culling check (AABB vs view frustum)
  ///
  /// This is a simplified frustum check using axis-aligned bounding box.
  /// For more accuracy, use proper frustum plane intersection.
  ///
  /// Parameters:
  /// - position: Object world position
  /// - camera: Camera for view matrix
  /// - radius: Object bounding sphere radius
  ///
  /// Returns:
  /// - true if potentially visible, false if definitely outside frustum
  static bool isInFrustum(Vector3 position, Camera3D camera, double radius) {
    // Get camera's view direction
    final viewMatrix = camera.getViewMatrix();

    // Transform position to view space
    final viewPos = viewMatrix.transform3(position);

    // Simple check: is it in front of camera and within reasonable bounds?
    // This is a very conservative check (few false negatives)

    // Behind camera check
    if (viewPos.z > -radius) {
      return false; // Behind camera
    }

    // Very rough side bounds check
    final aspectRatio = camera.aspectRatio;
    final fov = camera.fov * (3.14159 / 180.0); // Convert to radians
    final tanHalfFov = tan(fov / 2.0);

    final viewDistance = -viewPos.z;
    final viewHeight = tanHalfFov * viewDistance;
    final viewWidth = viewHeight * aspectRatio;

    // Check if object is within view bounds (with radius margin)
    if (viewPos.x.abs() > viewWidth + radius) return false;
    if (viewPos.y.abs() > viewHeight + radius) return false;

    return true;
  }

  /// Optimized culling check combining all methods
  ///
  /// This is the main method to use for most culling decisions.
  /// Returns a CullingResult indicating what operations can be skipped.
  ///
  /// Parameters:
  /// - position: Object world position
  /// - camera: Camera for frustum/distance checks
  /// - boundingRadius: Object bounding sphere radius (default 1.0)
  /// - isFootball: Special exemption for football (never culled)
  ///
  /// Returns:
  /// - CullingResult with flags for render, AI, and animation
  static CullingResult checkCulling({
    required Vector3 position,
    required Camera3D camera,
    double boundingRadius = 1.0,
    bool isFootball = false,
  }) {
    // Football is never culled
    if (isFootball) {
      return CullingResult(
        shouldRender: true,
        shouldUpdateAI: true,
        shouldAnimate: true,
        reason: 'football',
      );
    }

    // 1. Field bounds check (fastest)
    if (!isWithinFieldBounds(position)) {
      return CullingResult(
        shouldRender: false,
        shouldUpdateAI: false,
        shouldAnimate: false,
        reason: 'out_of_bounds',
      );
    }

    // 2. Camera distance check
    final cameraPos = camera.position;
    final distance = (position - cameraPos).length;

    if (distance > maxRenderDistance) {
      return CullingResult(
        shouldRender: false,
        shouldUpdateAI: false,
        shouldAnimate: false,
        reason: 'too_far',
      );
    }

    // 3. Frustum check (more expensive)
    final inFrustum = isInFrustum(position, camera, boundingRadius);
    if (!inFrustum) {
      return CullingResult(
        shouldRender: false,
        shouldUpdateAI: distance <= maxAIUpdateDistance,
        shouldAnimate: false,
        reason: 'out_of_frustum',
      );
    }

    // Object is visible and should be processed
    return CullingResult(
      shouldRender: true,
      shouldUpdateAI: distance <= maxAIUpdateDistance,
      shouldAnimate: true,
      reason: 'visible',
    );
  }
}

/// Result of culling checks
///
/// Indicates which operations should be performed on an object.
class CullingResult {
  /// Whether object should be rendered
  final bool shouldRender;

  /// Whether AI should be updated
  final bool shouldUpdateAI;

  /// Whether animation should be updated
  final bool shouldAnimate;

  /// Reason for culling decision (for debugging)
  final String reason;

  const CullingResult({
    required this.shouldRender,
    required this.shouldUpdateAI,
    required this.shouldAnimate,
    required this.reason,
  });
}

/// Helper function for tangent calculation
double tan(double radians) {
  return sin(radians) / cos(radians);
}

/// Helper function for sine
double sin(double radians) {
  return radians - (radians * radians * radians) / 6 +
         (radians * radians * radians * radians * radians) / 120;
}

/// Helper function for cosine
double cos(double radians) {
  return 1 - (radians * radians) / 2 + (radians * radians * radians * radians) / 24;
}
