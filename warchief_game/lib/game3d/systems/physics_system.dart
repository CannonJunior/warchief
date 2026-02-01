import '../state/game_state.dart';

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
    if (gameState.playerTransform == null) return;

    // Apply gravity
    gameState.verticalVelocity -= gameState.gravity * dt;

    // Apply vertical movement
    gameState.playerTransform!.position.y += gameState.verticalVelocity * dt;

    // Check ground collision
    _checkGroundCollision(gameState);
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
  static void _checkGroundCollision(GameState gameState) {
    if (gameState.playerTransform == null) return;

    // Get terrain height at player's current X,Z position
    final terrainHeight = _getTerrainHeight(
      gameState,
      gameState.playerTransform!.position.x,
      gameState.playerTransform!.position.z,
    );

    if (gameState.playerTransform!.position.y <= terrainHeight) {
      gameState.playerTransform!.position.y = terrainHeight;
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
    if (gameState.playerTransform == null) return 0.0;

    final terrainHeight = _getTerrainHeight(
      gameState,
      gameState.playerTransform!.position.x,
      gameState.playerTransform!.position.z,
    );

    return gameState.playerTransform!.position.y - terrainHeight;
  }
}
