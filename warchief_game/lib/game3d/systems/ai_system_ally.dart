part of 'ai_system.dart';

/// Ally AI - movement, follow-mode, decision-making, and projectiles
class _AllyAI {
  _AllyAI._(); // Private constructor to prevent instantiation

  // Reason: shared RNG instance avoids re-seeding overhead on every follow update
  static final math.Random _rng = math.Random();

  // ==================== ALLY MOVEMENT ====================

  /// Updates ally movement along current paths (every frame)
  ///
  /// Ally Y position is set to terrain height for proper terrain following.
  static void updateAllyMovement(double dt, GameState gameState) {
    if (gameState.playerTransform == null) return;

    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue;
      // Skip the active player-controlled ally
      if (!gameState.isWarchiefActive && ally == gameState.activeAlly) continue;

      const double allySize = 0.8; // Ally mesh size

      // Handle different movement modes
      switch (ally.movementMode) {
        case AllyMovementMode.stationary:
          // Still apply terrain height even when stationary
          _applyTerrainHeight(gameState, ally.transform, unitSize: allySize);
          break;

        case AllyMovementMode.followPlayer:
          _updateAllyFollowMode(dt, ally, gameState);
          break;

        case AllyMovementMode.commanded:
        case AllyMovementMode.tactical:
          // Follow current path if exists
          if (ally.currentPath != null) {
            // Apply wind modifier to ally movement speed
            double allySpeed = ally.moveSpeed;
            if (globalWindState != null && ally.currentPath!.progress < 1.0) {
              final tangent = ally.currentPath!.getTangentAt(ally.currentPath!.progress);
              final windMod = globalWindState!.getMovementModifier(tangent.x, tangent.z);
              allySpeed *= windMod;
            }
            final distance = allySpeed * dt;
            final newPos = ally.currentPath!.advance(distance);

            if (newPos != null) {
              ally.transform.position.x = newPos.x;
              ally.transform.position.z = newPos.z;
              ally.isMoving = true;

              // Update rotation to face movement direction
              final tangent = ally.currentPath!.getTangentAt(ally.currentPath!.progress);
              ally.rotation = math.atan2(-tangent.x, -tangent.z) * (180 / math.pi);
              ally.directionIndicatorTransform?.rotation.y = ally.rotation;
            } else {
              // Path completed
              ally.currentPath = null;
              ally.isMoving = false;
            }
          }
          // Apply terrain height
          _applyTerrainHeight(gameState, ally.transform, unitSize: allySize);
          break;
      }
    }
  }

  /// Helper to update ally in follow mode
  ///
  /// Ally Y position is set to terrain height for proper terrain following.
  static void _updateAllyFollowMode(double dt, Ally ally, GameState gameState) {
    final playerPos = gameState.playerTransform!.position;
    final dx = ally.transform.position.x - playerPos.x;
    final dz = ally.transform.position.z - playerPos.z;
    final distSq = dx * dx + dz * dz;
    final playerVelocity = gameState.playerMovementTracker.getVelocity();
    final playerIsMoving = playerVelocity.length2 > 0.01; // 0.1^2

    // If player is moving and ally is too far, create follow path
    // Reduced from 1.3x to 1.1x for more responsive following
    final followThreshold = ally.followBufferDistance * 1.1;
    if (playerIsMoving && distSq > followThreshold * followThreshold) {
      // Calculate target position - predict where player will be
      final predictedPlayerPos = playerPos + playerVelocity * 0.5; // 0.5s prediction
      final toAlly = (ally.transform.position - predictedPlayerPos).normalized();
      final targetPos = predictedPlayerPos + toAlly * ally.followBufferDistance;

      // Create smooth path to target
      ally.currentPath = BezierPath.interception(
        start: ally.transform.position,
        target: targetPos,
        velocity: playerVelocity, // Use player velocity for better interception
      );
      ally.isMoving = true;
    }

    // If ally is very far from player (>2x buffer), immediately start following
    final farThreshold = ally.followBufferDistance * 2.0;
    if (distSq > farThreshold * farThreshold && ally.currentPath == null) {
      final toPlayer = (playerPos - ally.transform.position).normalized();
      final targetPos = playerPos - toPlayer * ally.followBufferDistance;
      ally.currentPath = BezierPath.interception(
        start: ally.transform.position,
        target: targetPos,
        velocity: null,
      );
      ally.isMoving = true;
    }

    // If player stopped and ally is close enough, stop and re-randomize buffer
    if (!playerIsMoving && distSq <= followThreshold * followThreshold) {
      ally.currentPath = null;
      ally.isMoving = false;
      // Re-randomize buffer distance for next movement (3-5 units)
      ally.followBufferDistance = _rng.nextDouble() * 2.0 + 3.0;
    }

    // Continue moving along existing path if one exists
    if (ally.currentPath != null) {
      // Apply wind modifier to follow movement speed
      double followSpeed = ally.moveSpeed;
      if (globalWindState != null && ally.currentPath!.progress < 1.0) {
        final tangent = ally.currentPath!.getTangentAt(ally.currentPath!.progress);
        final windMod = globalWindState!.getMovementModifier(tangent.x, tangent.z);
        followSpeed *= windMod;
      }
      final distance = followSpeed * dt;
      final newPos = ally.currentPath!.advance(distance);

      if (newPos != null) {
        ally.transform.position.x = newPos.x;
        ally.transform.position.z = newPos.z;

        // Update rotation
        final tangent = ally.currentPath!.getTangentAt(ally.currentPath!.progress);
        ally.rotation = math.atan2(-tangent.x, -tangent.z) * (180 / math.pi);
        ally.directionIndicatorTransform?.rotation.y = ally.rotation;
      } else {
        ally.currentPath = null;
        ally.isMoving = false;
      }
    }

    // Apply terrain height (ally size is 0.8)
    _applyTerrainHeight(gameState, ally.transform, unitSize: 0.8);
  }

  // ==================== ALLY AI ====================

  /// Updates ally AI using behavior tree (decision making and execution)
  static void updateAllyAI(double dt, GameState gameState) {
    for (final ally in gameState.allies) {
      if (ally.health <= 0) continue; // Skip dead allies
      // Skip the active player-controlled ally
      if (!gameState.isWarchiefActive && ally == gameState.activeAlly) continue;

      ally.aiTimer += dt;

      // AI thinks on interval (reduced to 1 second for responsiveness)
      if (ally.aiTimer >= ally.aiInterval) {
        ally.aiTimer = 0.0;

        if (gameState.playerTransform != null) {
          // Use behavior tree for decision making
          AllyBehaviorEvaluator.evaluate(ally, gameState);
        }
      }

      // Update ally's direction indicator based on current state
      // Only auto-face monster if in combat (not following player)
      if (ally.directionIndicatorTransform != null) {
        if (ally.movementMode == AllyMovementMode.tactical &&
            gameState.monsterTransform != null &&
            gameState.monsterHealth > 0) {
          // In combat - face monster
          final toMonster = gameState.monsterTransform!.position - ally.transform.position;
          ally.rotation = math.atan2(-toMonster.x, -toMonster.z) * (180 / math.pi);
        }
        // Otherwise rotation is set by movement direction in updateAllyMovement
        ally.directionIndicatorTransform!.rotation.y = ally.rotation;
      }
    }
  }

  // ==================== ALLY PROJECTILES ====================

  /// Updates ally projectiles
  static void updateAllyProjectiles(double dt, GameState gameState) {
    final allyFireball = AbilitiesConfig.allyFireball;

    for (final ally in gameState.allies) {
      ally.projectiles.removeWhere((projectile) {
        // Apply wind force to ally projectile velocity
        if (globalWindState != null) {
          final windForce = globalWindState!.getProjectileForce();
          projectile.velocity.x += windForce[0] * dt;
          projectile.velocity.z += windForce[1] * dt;
        }
        projectile.transform.position += projectile.velocity * dt;
        projectile.lifetime -= dt;

        // Check collision with monster using unified combat system
        final hitRegistered = CombatSystem.checkAndDamageMonster(
          gameState,
          attackerPosition: projectile.transform.position,
          damage: allyFireball.damage,
          attackType: allyFireball.name,
          impactColor: allyFireball.impactColor,
          impactSize: allyFireball.impactSize,
        );

        if (hitRegistered) return true;

        return projectile.lifetime <= 0;
      });
    }
  }
}
