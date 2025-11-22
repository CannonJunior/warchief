import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

/// Bezier Path - Smooth curve interpolation for entity movement
///
/// Provides quadratic and cubic Bezier curve calculations for smooth,
/// natural-looking movement paths in the game.
class BezierPath {
  /// Control points defining the curve
  final List<Vector3> controlPoints;

  /// Current progress along the curve (0.0 to 1.0)
  double _currentT = 0.0;

  /// Total length of the curve (approximated)
  double? _approximateLength;

  BezierPath({required this.controlPoints}) {
    assert(controlPoints.length >= 2, 'BezierPath requires at least 2 control points');
  }

  /// Creates a quadratic Bezier curve (3 control points)
  ///
  /// Parameters:
  /// - start: Starting position
  /// - control: Control point that defines the curve
  /// - end: Ending position
  factory BezierPath.quadratic({
    required Vector3 start,
    required Vector3 control,
    required Vector3 end,
  }) {
    return BezierPath(controlPoints: [start, control, end]);
  }

  /// Creates a cubic Bezier curve (4 control points)
  ///
  /// Parameters:
  /// - start: Starting position
  /// - control1: First control point
  /// - control2: Second control point
  /// - end: Ending position
  factory BezierPath.cubic({
    required Vector3 start,
    required Vector3 control1,
    required Vector3 control2,
    required Vector3 end,
  }) {
    return BezierPath(controlPoints: [start, control1, control2, end]);
  }

  /// Creates a smooth curved path for interception
  ///
  /// Parameters:
  /// - start: Current position
  /// - target: Target position to intercept
  /// - velocity: Current velocity vector (for smooth acceleration)
  factory BezierPath.interception({
    required Vector3 start,
    required Vector3 target,
    required Vector3? velocity,
  }) {
    // Create control points for a natural curved approach
    final toTarget = target - start;
    final distance = toTarget.length;

    // Control point offset perpendicular to direct path
    final perpendicular = Vector3(-toTarget.z, 0, toTarget.x).normalized();

    // First control point: offset from direct path based on velocity
    Vector3 control1;
    if (velocity != null && velocity.length > 0.01) {
      // Use velocity to create smooth transition
      control1 = start + velocity.normalized() * (distance * 0.3);
    } else {
      // Use perpendicular offset for curved approach
      control1 = start + toTarget * 0.3 + perpendicular * (distance * 0.15);
    }

    // Second control point: slight curve towards target
    final control2 = start + toTarget * 0.7 + perpendicular * (distance * 0.05);

    return BezierPath.cubic(
      start: start,
      control1: control1,
      control2: control2,
      end: target,
    );
  }

  /// Get position at parameter t (0.0 to 1.0) along the curve
  ///
  /// Parameters:
  /// - t: Parameter value (0.0 = start, 1.0 = end)
  ///
  /// Returns:
  /// - Position on the curve at parameter t
  Vector3 getPointAt(double t) {
    t = t.clamp(0.0, 1.0);

    if (controlPoints.length == 2) {
      // Linear interpolation
      return _lerp(controlPoints[0], controlPoints[1], t);
    } else if (controlPoints.length == 3) {
      // Quadratic Bezier
      return _quadraticBezier(controlPoints[0], controlPoints[1], controlPoints[2], t);
    } else if (controlPoints.length == 4) {
      // Cubic Bezier
      return _cubicBezier(controlPoints[0], controlPoints[1], controlPoints[2], controlPoints[3], t);
    } else {
      // For higher order curves, use De Casteljau's algorithm
      return _deCasteljau(controlPoints, t);
    }
  }

  /// Get tangent (direction) at parameter t
  ///
  /// Parameters:
  /// - t: Parameter value (0.0 to 1.0)
  ///
  /// Returns:
  /// - Normalized tangent vector at parameter t
  Vector3 getTangentAt(double t) {
    const epsilon = 0.001;
    final t1 = (t - epsilon).clamp(0.0, 1.0);
    final t2 = (t + epsilon).clamp(0.0, 1.0);

    final p1 = getPointAt(t1);
    final p2 = getPointAt(t2);

    return (p2 - p1).normalized();
  }

  /// Advance along the curve by a given distance
  ///
  /// Parameters:
  /// - distance: Distance to move along the curve
  /// - speed: Movement speed (units per second)
  ///
  /// Returns:
  /// - New position after advancing, or null if reached end
  Vector3? advance(double distance) {
    if (_approximateLength == null) {
      _approximateLength = _calculateApproximateLength();
    }

    // Convert distance to t parameter increment
    final deltaT = distance / _approximateLength!;
    _currentT += deltaT;

    if (_currentT >= 1.0) {
      _currentT = 1.0;
      return null; // Reached end of path
    }

    return getPointAt(_currentT);
  }

  /// Reset the path progress to the beginning
  void reset() {
    _currentT = 0.0;
  }

  /// Check if the path has been completed
  bool get isComplete => _currentT >= 1.0;

  /// Get the current progress (0.0 to 1.0)
  double get progress => _currentT;

  // ==================== PRIVATE HELPER METHODS ====================

  /// Linear interpolation between two points
  Vector3 _lerp(Vector3 p0, Vector3 p1, double t) {
    return p0 + (p1 - p0) * t;
  }

  /// Quadratic Bezier curve calculation
  Vector3 _quadraticBezier(Vector3 p0, Vector3 p1, Vector3 p2, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;

    return p0 * uu + p1 * (2 * u * t) + p2 * tt;
  }

  /// Cubic Bezier curve calculation
  Vector3 _cubicBezier(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final ttt = tt * t;
    final uuu = uu * u;

    return p0 * uuu + p1 * (3 * uu * t) + p2 * (3 * u * tt) + p3 * ttt;
  }

  /// De Casteljau's algorithm for general Bezier curves
  Vector3 _deCasteljau(List<Vector3> points, double t) {
    if (points.length == 1) {
      return points[0];
    }

    final newPoints = <Vector3>[];
    for (int i = 0; i < points.length - 1; i++) {
      newPoints.add(_lerp(points[i], points[i + 1], t));
    }

    return _deCasteljau(newPoints, t);
  }

  /// Calculate approximate length of the curve using sampling
  double _calculateApproximateLength() {
    const samples = 20;
    double length = 0.0;
    Vector3? previousPoint;

    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final point = getPointAt(t);

      if (previousPoint != null) {
        length += (point - previousPoint).length;
      }

      previousPoint = point;
    }

    return length;
  }

  /// Get approximate length of the entire curve
  double getLength() {
    _approximateLength ??= _calculateApproximateLength();
    return _approximateLength!;
  }
}
