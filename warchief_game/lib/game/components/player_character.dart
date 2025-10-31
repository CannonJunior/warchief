import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../controllers/input_manager.dart';
import '../../models/game_action.dart';

/// Player character component
///
/// Represents the player's character in the game world.
/// Handles movement, rotation, and basic character state.
class PlayerCharacter extends PositionComponent with HasGameRef {
  /// Movement speed in pixels per second
  double moveSpeed = 150.0;

  /// Rotation speed in radians per second
  double rotationSpeed = 3.0;

  /// Current velocity
  Vector2 velocity = Vector2.zero();

  /// Current rotation angle (in radians)
  double rotationAngle = 0.0;

  /// Is the character jumping?
  bool isJumping = false;

  /// Jump timer (for animation)
  double jumpTimer = 0.0;
  final double jumpDuration = 0.5;

  /// Character stats
  double health = 100.0;
  double maxHealth = 100.0;

  /// Reference to input manager
  final InputManager inputManager;

  /// Visual representation (for now, a simple colored circle)
  late CircleComponent _visual;

  PlayerCharacter({
    required this.inputManager,
    Vector2? initialPosition,
  }) : super(
          position: initialPosition ?? Vector2.zero(),
          size: Vector2.all(32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create visual representation
    _visual = CircleComponent(
      radius: 16,
      paint: Paint()..color = Colors.blue,
      anchor: Anchor.center,
    );
    add(_visual);

    // Add a direction indicator
    final directionIndicator = RectangleComponent(
      size: Vector2(20, 4),
      paint: Paint()..color = Colors.white,
      anchor: Anchor.centerLeft,
    );
    add(directionIndicator);

    // Bind input actions
    _bindInputActions();
  }

  /// Bind input manager actions to character movement
  void _bindInputActions() {
    // Continuous movement actions (called every frame while key is held)
    inputManager.bindContinuousAction(
      GameAction.moveForward,
      _moveForward,
    );
    inputManager.bindContinuousAction(
      GameAction.moveBackward,
      _moveBackward,
    );
    inputManager.bindContinuousAction(
      GameAction.strafeLeft,
      _strafeLeft,
    );
    inputManager.bindContinuousAction(
      GameAction.strafeRight,
      _strafeRight,
    );
    inputManager.bindContinuousAction(
      GameAction.rotateLeft,
      _rotateLeft,
    );
    inputManager.bindContinuousAction(
      GameAction.rotateRight,
      _rotateRight,
    );

    // One-time action (triggered once on key press)
    inputManager.bindAction(
      GameAction.jump,
      _jump,
    );
  }

  /// Movement methods
  void _moveForward() {
    final direction = Vector2(math.cos(rotationAngle), math.sin(rotationAngle));
    velocity = direction * moveSpeed;
  }

  void _moveBackward() {
    final direction = Vector2(math.cos(rotationAngle), math.sin(rotationAngle));
    velocity = -direction * (moveSpeed * 0.5); // Backward at half speed
  }

  void _strafeLeft() {
    final direction =
        Vector2(math.cos(rotationAngle - math.pi / 2), math.sin(rotationAngle - math.pi / 2));
    velocity = direction * moveSpeed;
  }

  void _strafeRight() {
    final direction =
        Vector2(math.cos(rotationAngle + math.pi / 2), math.sin(rotationAngle + math.pi / 2));
    velocity = direction * moveSpeed;
  }

  void _rotateLeft() {
    // Rotate counter-clockwise
    rotationAngle -= rotationSpeed * 0.016; // Approximate dt
  }

  void _rotateRight() {
    // Rotate clockwise
    rotationAngle += rotationSpeed * 0.016; // Approximate dt
  }

  void _jump() {
    if (!isJumping) {
      isJumping = true;
      jumpTimer = 0.0;
      debugPrint('Player jumped!');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply velocity to position
    if (velocity.length > 0) {
      position += velocity * dt;

      // Reset velocity (will be set again by input if key is still pressed)
      velocity = Vector2.zero();
    }

    // Update rotation
    angle = rotationAngle;

    // Handle jumping
    if (isJumping) {
      jumpTimer += dt;
      if (jumpTimer >= jumpDuration) {
        isJumping = false;
        jumpTimer = 0.0;
      }

      // Simple jump animation: change scale
      final jumpProgress = jumpTimer / jumpDuration;
      final jumpScale = 1.0 + (math.sin(jumpProgress * math.pi) * 0.2);
      scale = Vector2.all(jumpScale);
    } else {
      scale = Vector2.all(1.0);
    }

    // Keep player within game bounds (simple boundary check)
    if (position.x < -800) position.x = -800;
    if (position.x > 800) position.x = 800;
    if (position.y < -450) position.y = -450;
    if (position.y > 450) position.y = 450;
  }

  /// Take damage
  void takeDamage(double amount) {
    health = (health - amount).clamp(0.0, maxHealth);
    if (health <= 0) {
      _onDeath();
    }
  }

  /// Heal
  void heal(double amount) {
    health = (health + amount).clamp(0.0, maxHealth);
  }

  /// Called when player dies
  void _onDeath() {
    debugPrint('Player died!');
    // TODO: Implement death handling
  }

  /// Get health percentage (for UI)
  double get healthPercent => health / maxHealth;
}
