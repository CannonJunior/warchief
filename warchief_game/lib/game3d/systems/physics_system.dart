import 'dart:math' as math;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../state/wind_config.dart';

/// Physics System - Handles gravity, jumping, and vertical movement
///
/// Manages all physics-related calculations including:
/// - Gravity application
/// - Jump mechanics (including double jump)
/// - Vertical velocity updates
/// - Ground collision detection (terrain-aware)
/// - Jump state management
class PhysicsSystem {
  PhysicsSystem._(); // Private constructor to prevent instantiation

  /// Get terrain height at position, with fallback to groundLevel
  static double _getTerrainHeight(GameState gameState, double x, double z) {
    if (gameState.infiniteTerrainManager != null) {
      return gameState.infiniteTerrainManager!.getTerrainHeight(x, z);
    }
    return gameState.groundLevel;
  }

  /// Updates physics state for the player
  ///
  /// Applies gravity, updates vertical position, and handles ground collision.
  /// Should be called every frame with the time delta.
  ///
  /// Parameters:
  /// - dt: Time elapsed since last frame (in seconds)
  /// - gameState: Current game state to update
  static void update(double dt, GameState gameState) {
    if (gameState.activeTransform == null) return;

    // Flight mode — bypass normal gravity and ground collision (Warchief only)
    if (gameState.isFlying) {
      _updateFlight(dt, gameState);
      return;
    }

    // Apply gravity
    gameState.verticalVelocity -= gameState.gravity * dt;

    // Apply vertical movement
    gameState.activeTransform!.position.y += gameState.verticalVelocity * dt;

    // Check ground collision
    _checkGroundCollision(gameState);
  }

  /// Handles flight physics: pitch-based altitude change, altitude tracking,
  /// and ground collision ending flight.
  static void _updateFlight(double dt, GameState gameState) {
    if (gameState.playerTransform == null) return;

    final pitchRad = gameState.flightPitchAngle * (math.pi / 180.0);
    final speed = gameState.flightSpeed;

    // Vertical movement from pitch
    final verticalDelta = speed * math.sin(pitchRad) * dt;
    gameState.playerTransform!.position.y += verticalDelta;

    // Reset vertical velocity so landing from flight doesn't carry momentum
    gameState.verticalVelocity = 0.0;

    // Compute altitude above terrain
    final terrainHeight = _getTerrainHeight(
      gameState,
      gameState.playerTransform!.position.x,
      gameState.playerTransform!.position.z,
    );
    final groundY = terrainHeight + GameConfig.playerSize / 2 + _terrainBuffer;
    gameState.flightAltitude =
        gameState.playerTransform!.position.y - terrainHeight;

    // Ground collision ends flight
    if (gameState.playerTransform!.position.y <= groundY) {
      gameState.playerTransform!.position.y = groundY;
      gameState.flightAltitude = 0.0;
      gameState.endFlight();
      // Restore grounded state
      gameState.isJumping = false;
      gameState.isGrounded = true;
      gameState.jumpsRemaining = gameState.maxJumps;
    }
  }

  /// Handles jump input from the player
  ///
  /// Processes jump key presses and manages double jump mechanic.
  /// Only triggers jump on new key press (not when held).
  ///
  /// Parameters:
  /// - jumpKeyIsPressed: Whether the jump key is currently pressed
  /// - gameState: Current game state to update
  static void handleJumpInput(bool jumpKeyIsPressed, GameState gameState) {
    // Only trigger jump on new key press, not when held
    if (jumpKeyIsPressed && !gameState.jumpKeyWasPressed && gameState.jumpsRemaining > 0) {
      gameState.verticalVelocity = gameState.jumpForce;
      gameState.isJumping = true;
      gameState.isGrounded = false;
      gameState.jumpsRemaining--;
    }

    // Track jump key state for next frame
    gameState.jumpKeyWasPressed = jumpKeyIsPressed;
  }

  /// Checks for and handles ground collision with terrain
  ///
  /// Queries terrain height at player's X,Z position and checks if player
  /// has fallen below the terrain surface. If so:
  /// - Resets position to terrain height
  /// - Stops vertical velocity
  /// - Sets grounded state
  /// - Resets available jumps
  ///
  /// Parameters:
  /// - gameState: Current game state to update
  /// Small buffer to ensure units are visually above terrain surface
  static const double _terrainBuffer = 0.15;

  static void _checkGroundCollision(GameState gameState) {
    if (gameState.activeTransform == null) return;

    // Get terrain height at active character's current X,Z position
    final terrainHeight = _getTerrainHeight(
      gameState,
      gameState.activeTransform!.position.x,
      gameState.activeTransform!.position.z,
    );

    // Character mesh is centered, so add half height + buffer to sit above terrain
    final groundY = terrainHeight + GameConfig.playerSize / 2 + _terrainBuffer;

    if (gameState.activeTransform!.position.y <= groundY) {
      gameState.activeTransform!.position.y = groundY;
      gameState.verticalVelocity = 0.0;
      gameState.isJumping = false;
      gameState.isGrounded = true;
      gameState.jumpsRemaining = gameState.maxJumps; // Reset jumps when landing
    }
  }

  /// Gets the player's current height above terrain
  ///
  /// Returns:
  /// - Height above terrain surface (in world units)
  /// - 0.0 if player transform is null
  static double getPlayerHeight(GameState gameState) {
    if (gameState.activeTransform == null) return 0.0;

    final terrainHeight = _getTerrainHeight(
      gameState,
      gameState.activeTransform!.position.x,
      gameState.activeTransform!.position.z,
    );

    return gameState.activeTransform!.position.y - terrainHeight;
  }
}
