import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

/// Movement Prediction - Predicts future positions of moving entities
///
/// Used for AI to anticipate player movement and create interception paths.
/// Tracks velocity history and predicts future positions based on movement patterns.
class MovementPredictor {
  /// History of positions for velocity calculation
  final List<Vector3> _positionHistory = [];

  /// Maximum history size
  static const int maxHistorySize = 5;

  /// Timestamps for position history
  final List<double> _timestamps = [];

  /// Current game time
  double _currentTime = 0.0;

  /// Add a new position to the history
  ///
  /// Parameters:
  /// - position: Current position
  /// - time: Current game time
  void update(Vector3 position, double time) {
    _positionHistory.add(position.clone());
    _timestamps.add(time);
    _currentTime = time;

    // Keep history size limited
    while (_positionHistory.length > maxHistorySize) {
      _positionHistory.removeAt(0);
      _timestamps.removeAt(0);
    }
  }

  /// Calculate current velocity based on position history
  ///
  /// Returns:
  /// - Velocity vector (units per second)
  Vector3 getVelocity() {
    if (_positionHistory.length < 2) {
      return Vector3.zero();
    }

    // Use most recent two positions for velocity
    final p1 = _positionHistory[_positionHistory.length - 2];
    final p2 = _positionHistory[_positionHistory.length - 1];
    final t1 = _timestamps[_timestamps.length - 2];
    final t2 = _timestamps[_timestamps.length - 1];

    final dt = t2 - t1;
    if (dt <= 0) {
      return Vector3.zero();
    }

    return (p2 - p1) / dt;
  }

  /// Calculate average velocity over entire history
  ///
  /// Returns:
  /// - Average velocity vector
  Vector3 getAverageVelocity() {
    if (_positionHistory.length < 2) {
      return Vector3.zero();
    }

    final p1 = _positionHistory.first;
    final p2 = _positionHistory.last;
    final t1 = _timestamps.first;
    final t2 = _timestamps.last;

    final dt = t2 - t1;
    if (dt <= 0) {
      return Vector3.zero();
    }

    return (p2 - p1) / dt;
  }

  /// Predict future position based on linear extrapolation
  ///
  /// Parameters:
  /// - timeAhead: Time in the future to predict (in seconds)
  ///
  /// Returns:
  /// - Predicted future position
  Vector3 predictLinear(double timeAhead) {
    if (_positionHistory.isEmpty) {
      return Vector3.zero();
    }

    final currentPos = _positionHistory.last;
    final velocity = getVelocity();

    return currentPos + velocity * timeAhead;
  }

  /// Predict future position with acceleration consideration
  ///
  /// Parameters:
  /// - timeAhead: Time in the future to predict (in seconds)
  ///
  /// Returns:
  /// - Predicted future position considering acceleration
  Vector3 predictWithAcceleration(double timeAhead) {
    if (_positionHistory.length < 3) {
      return predictLinear(timeAhead);
    }

    final currentPos = _positionHistory.last;
    final velocity = getVelocity();
    final acceleration = _getAcceleration();

    // Use kinematic equation: p = p0 + v*t + 0.5*a*t^2
    return currentPos + velocity * timeAhead + acceleration * (0.5 * timeAhead * timeAhead);
  }

  /// Calculate interception point for a moving target
  ///
  /// Parameters:
  /// - interceptorPos: Current position of the interceptor
  /// - interceptorSpeed: Speed of the interceptor
  ///
  /// Returns:
  /// - Predicted interception point, or null if unreachable
  Vector3? calculateInterceptionPoint(Vector3 interceptorPos, double interceptorSpeed) {
    if (_positionHistory.isEmpty) {
      return null;
    }

    final targetPos = _positionHistory.last;
    final targetVelocity = getVelocity();
    final targetSpeed = targetVelocity.length;

    // If target isn't moving, intercept current position
    if (targetSpeed < 0.01) {
      return targetPos;
    }

    // Iterative solution to find interception time
    const maxIterations = 10;
    double timeToIntercept = 0.0;

    for (int i = 0; i < maxIterations; i++) {
      final predictedTargetPos = targetPos + targetVelocity * timeToIntercept;
      final distanceToIntercept = (predictedTargetPos - interceptorPos).length;
      final newTimeToIntercept = distanceToIntercept / interceptorSpeed;

      // Check convergence
      if ((newTimeToIntercept - timeToIntercept).abs() < 0.01) {
        timeToIntercept = newTimeToIntercept;
        break;
      }

      timeToIntercept = newTimeToIntercept;
    }

    // Return predicted intercept position
    return targetPos + targetVelocity * timeToIntercept;
  }

  /// Get current acceleration vector
  Vector3 _getAcceleration() {
    if (_positionHistory.length < 3) {
      return Vector3.zero();
    }

    // Calculate acceleration from velocity change
    final v1 = (_positionHistory[_positionHistory.length - 2] - _positionHistory[_positionHistory.length - 3]) /
        (_timestamps[_timestamps.length - 2] - _timestamps[_timestamps.length - 3]);

    final v2 = (_positionHistory[_positionHistory.length - 1] - _positionHistory[_positionHistory.length - 2]) /
        (_timestamps[_timestamps.length - 1] - _timestamps[_timestamps.length - 2]);

    final dt = _timestamps.last - _timestamps[_timestamps.length - 2];

    if (dt <= 0) {
      return Vector3.zero();
    }

    return (v2 - v1) / dt;
  }

  /// Check if the target is moving
  bool get isMoving {
    return getVelocity().length > 0.01;
  }

  /// Get current position
  Vector3? get currentPosition {
    return _positionHistory.isNotEmpty ? _positionHistory.last : null;
  }

  /// Clear history
  void reset() {
    _positionHistory.clear();
    _timestamps.clear();
  }
}

/// Movement Tracker - Tracks player's movement history for the entire game
class PlayerMovementTracker {
  final MovementPredictor predictor = MovementPredictor();

  /// Update player position
  void update(Vector3 position, double time) {
    predictor.update(position, time);
  }

  /// Get predicted player position
  Vector3 predictPosition(double timeAhead) {
    return predictor.predictWithAcceleration(timeAhead);
  }

  /// Calculate where to aim to intercept the player
  Vector3? calculateInterception(Vector3 fromPosition, double projectileSpeed) {
    return predictor.calculateInterceptionPoint(fromPosition, projectileSpeed);
  }

  /// Get current player velocity
  Vector3 getVelocity() {
    return predictor.getVelocity();
  }

  /// Check if player is currently moving
  bool get isPlayerMoving => predictor.isMoving;
}
