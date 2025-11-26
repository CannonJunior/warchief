import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';

/// Football - Represents the game ball in flight or on ground
///
/// The football can be:
/// - In flight (passing play)
/// - Carried by ball carrier
/// - Loose (fumble)
/// - On the ground (incomplete pass, out of bounds)
///
/// Physics model includes:
/// - 3D trajectory with arc and gravity
/// - Spin/rotation for visual effect
/// - Collision detection with receivers/defenders
/// - Bounce physics for incomplete passes
class Football {
  /// Current position in world space
  Vector3 position;

  /// Current velocity vector (direction and speed)
  Vector3 velocity;

  /// Rotation (for visual spin effect)
  Vector3 rotation;

  /// Rotation velocity (degrees per second for each axis)
  Vector3 rotationVelocity;

  /// Football mesh (brown ellipsoid or simplified cube)
  Mesh mesh;

  /// Transform for rendering
  Transform3d transform;

  /// Football state
  FootballState state;

  /// Time in flight (seconds)
  double timeInFlight;

  /// Maximum flight time before auto-incomplete (seconds)
  final double maxFlightTime;

  /// Who threw the ball (for scoring/stats)
  String? thrownBy;

  /// Target receiver (if any)
  String? targetReceiver;

  /// Pass accuracy (0.0 - 1.0) affects trajectory wobble
  double passAccuracy;

  /// Whether the ball has bounced (for incomplete passes)
  bool hasBounced;

  /// Bounce count (ball is dead after 2 bounces)
  int bounceCount;

  /// Whether ball is catchable (false after bounce or out of bounds)
  bool isCatchable;

  Football({
    required this.position,
    required this.velocity,
    Vector3? rotation,
    Vector3? rotationVelocity,
    required this.mesh,
    required this.transform,
    this.state = FootballState.inFlight,
    this.timeInFlight = 0.0,
    this.maxFlightTime = 5.0,
    this.thrownBy,
    this.targetReceiver,
    this.passAccuracy = 1.0,
    this.hasBounced = false,
    this.bounceCount = 0,
    this.isCatchable = true,
  })  : rotation = rotation ?? Vector3.zero(),
        rotationVelocity = rotationVelocity ?? Vector3(0, 720, 0); // Default spin

  /// Update football physics
  ///
  /// Parameters:
  /// - deltaTime: Time since last update (seconds)
  /// - gravity: Gravity constant
  ///
  /// Returns: true if ball is still active, false if it should be removed
  bool update(double deltaTime, double gravity) {
    if (state == FootballState.carried || state == FootballState.dead) {
      return state != FootballState.dead;
    }

    // Update time in flight
    timeInFlight += deltaTime;

    // Check if ball has been in flight too long (auto-incomplete)
    if (timeInFlight > maxFlightTime && state == FootballState.inFlight) {
      state = FootballState.incomplete;
      isCatchable = false;
      return true; // Keep ball visible for a moment
    }

    // Apply gravity to velocity
    velocity.y -= gravity * deltaTime;

    // Update position based on velocity
    position.add(velocity * deltaTime);

    // Apply pass accuracy wobble (imperfect throws drift slightly)
    if (passAccuracy < 1.0 && state == FootballState.inFlight) {
      final wobble = (1.0 - passAccuracy) * 0.5;
      final random = math.Random();
      position.x += (random.nextDouble() - 0.5) * wobble * deltaTime;
    }

    // Update rotation for spin effect
    rotation.add(rotationVelocity * deltaTime);

    // Check if ball hit the ground (Y <= ground level)
    if (position.y <= 0.1) {
      _handleGroundBounce(gravity);
    }

    // Update transform for rendering
    transform.position = position.clone();
    transform.rotation = rotation.clone();

    return true; // Ball is still active
  }

  /// Handle ball bouncing off the ground
  void _handleGroundBounce(double gravity) {
    hasBounced = true;
    bounceCount++;
    isCatchable = false; // Ball is dead once it touches ground

    if (bounceCount >= 2) {
      // Ball is dead after second bounce
      state = FootballState.dead;
      velocity = Vector3.zero();
      position.y = 0.1; // Rest on ground
      return;
    }

    // Bounce with reduced velocity
    velocity.y = velocity.y.abs() * 0.4; // Bounce to 40% height
    velocity.x *= 0.7; // Reduce horizontal velocity
    velocity.z *= 0.7;
    position.y = 0.1; // Reset to ground level

    // Change rotation on bounce
    final random = math.Random();
    rotationVelocity.x = (random.nextDouble() - 0.5) * 360;
    rotationVelocity.z = (random.nextDouble() - 0.5) * 360;

    // Mark as incomplete if this was a pass
    if (state == FootballState.inFlight) {
      state = FootballState.incomplete;
    }
  }

  /// Check if football is within catching range of a position
  ///
  /// Parameters:
  /// - receiverPos: Position of the receiver
  /// - catchingRange: Maximum distance for a catch
  ///
  /// Returns: true if within catching range
  bool isWithinCatchingRange(Vector3 receiverPos, double catchingRange) {
    if (!isCatchable || state != FootballState.inFlight) {
      return false;
    }

    final distance = (position - receiverPos).length;
    return distance <= catchingRange;
  }

  /// Mark ball as caught
  void markAsCaught(String caughtBy) {
    state = FootballState.caught;
    velocity = Vector3.zero();
    isCatchable = false;
  }

  /// Mark ball as incomplete
  void markAsIncomplete() {
    state = FootballState.incomplete;
    isCatchable = false;
  }

  /// Mark ball as fumbled
  void markAsFumbled() {
    state = FootballState.fumbled;
    isCatchable = true; // Fumbles can be recovered
    // Add some random velocity for fumble bounce
    final random = math.Random();
    velocity = Vector3(
      (random.nextDouble() - 0.5) * 3.0,
      2.0, // Bounce up
      (random.nextDouble() - 0.5) * 3.0,
    );
    rotationVelocity = Vector3(
      (random.nextDouble() - 0.5) * 720,
      (random.nextDouble() - 0.5) * 720,
      (random.nextDouble() - 0.5) * 720,
    );
  }

  /// Factory: Create a football for a pass
  ///
  /// Parameters:
  /// - startPos: Starting position (QB's hand)
  /// - targetPos: Target position (receiver's projected position)
  /// - passSpeed: Speed of the pass (yards/second)
  /// - arcHeight: Height multiplier for arc (0.0 = bullet pass, 1.0 = high arc)
  /// - accuracy: Pass accuracy (0.0 - 1.0)
  ///
  /// Returns: Football instance
  static Football createPass({
    required Vector3 startPos,
    required Vector3 targetPos,
    required double passSpeed,
    double arcHeight = 0.3,
    double accuracy = 0.9,
    String? thrownBy,
    String? targetReceiver,
  }) {
    // Calculate direction to target
    final direction = (targetPos - startPos).normalized();
    final distance = (targetPos - startPos).length;

    // Calculate flight time based on distance and speed
    final flightTime = distance / passSpeed;

    // Calculate velocity components
    final horizontalVelocity = direction * passSpeed;

    // Calculate vertical velocity for arc
    // Use projectile motion: vy = (h + 0.5*g*t^2) / t
    const gravity = 20.0; // From config
    final arcHeightValue = distance * arcHeight; // Arc height based on distance
    final verticalVelocity = (arcHeightValue + 0.5 * gravity * flightTime * flightTime) / flightTime;

    final velocity = Vector3(
      horizontalVelocity.x,
      verticalVelocity,
      horizontalVelocity.z,
    );

    // Create football mesh (brown ellipsoid-like)
    final mesh = Mesh.cube(
      size: 0.3,
      color: Vector3(0.6, 0.4, 0.2), // Brown leather
    );

    final transform = Transform3d(
      position: startPos.clone(),
      scale: Vector3(0.4, 0.3, 0.6), // Ellipsoid shape (elongated)
    );

    return Football(
      position: startPos.clone(),
      velocity: velocity,
      rotation: Vector3.zero(),
      rotationVelocity: Vector3(0, 720, 360), // Spiral spin
      mesh: mesh,
      transform: transform,
      state: FootballState.inFlight,
      thrownBy: thrownBy,
      targetReceiver: targetReceiver,
      passAccuracy: accuracy,
    );
  }

  @override
  String toString() {
    return 'Football(state: $state, pos: ${position.storage}, '
        'vel: ${velocity.storage}, catchable: $isCatchable)';
  }
}

/// Football State
enum FootballState {
  carried, // Being carried by ball carrier
  inFlight, // In the air (pass)
  caught, // Just caught by receiver
  incomplete, // Incomplete pass (hit ground)
  fumbled, // Loose ball (fumble)
  dead, // Play is over, ball is dead
}
