part of 'game3d_widget.dart';

mixin _WidgetUpdateMixin on _GameStateBase {
  void _render() {
    if (renderer == null || camera == null) {
      print('Render skipped - renderer: ${renderer != null}, camera: ${camera != null}');
      return;
    }

    RenderSystem.render(renderer!, camera!, gameState);
  }

  void _update(double dt, double gameTimeSec) {
    if (inputManager == null || camera == null || gameState.activeTransform == null) return;

    // Refresh per-frame caches before any system reads them
    gameState.refreshAliveMinions();

    // Process player and camera input
    InputSystem.update(dt, inputManager!, camera!, gameState);

    // Handle jump input
    final jumpKeyIsPressed = inputManager!.isActionPressed(GameAction.jump);
    PhysicsSystem.handleJumpInput(jumpKeyIsPressed, gameState);

    // Update physics (gravity, vertical movement, ground collision)
    PhysicsSystem.update(dt, gameState);

    // Track player movement for AI prediction using rAF timestamp (no DateTime.now() overhead)
    if (gameState.playerTransform != null) {
      gameState.playerMovementTracker.update(
        gameState.playerTransform!.position,
        gameTimeSec,
      );
    }

    // Update infinite terrain (chunk loading/unloading based on active character position)
    if (gameState.infiniteTerrainManager != null && gameState.activeTransform != null && camera != null) {
      gameState.infiniteTerrainManager!.update(
        gameState.activeTransform!.position,
        camera!.position,
      );
    }

    // ===== ABILITY SYSTEM =====
    // Update player ability cooldowns and effects
    AbilitySystem.update(dt, gameState);

    // Update mana regeneration based on Ley Line proximity
    gameState.updateManaRegen(dt);

    // Update wind simulation and White Mana regeneration
    gameState.updateWindAndWhiteMana(dt);

    // Update green mana regeneration (grass proximity, ally proximity, spirit beings)
    gameState.updateGreenManaRegen(dt);

    // Advance comet orbital phase and update black mana regeneration
    globalCometState?.update(dt);
    final cometPos = gameState.activeTransform?.position;
    if (cometPos != null) {
      gameState.updateBlackManaRegen(dt, cometPos.x, cometPos.z);
    }

    // Tick and expire active status effects on all entities
    gameState.updateActiveEffects(dt);

    // Update stance timers (Fury drain, Drunken re-rolls, switch cooldown)
    gameState.updateStanceTimers(dt);

    // Apply building aura effects (health + mana regen near buildings)
    BuildingSystem.applyBuildingAuras(gameState, dt);

    // Update minimap state (elapsed time for sun orbits, ping decay)
    gameState.minimapState.update(dt);

    // Update Warrior Spirit (periodic goal suggestion check)
    WarriorSpirit.update(gameState, dt);

    // Update macro execution engine (spell rotations + raid chat alerts)
    MacroSystem.update(dt, gameState);

    // Decay melee combo timer; break combo if window expires
    MeleeComboSystem.update(dt, gameState);

    // Track flight duration for mastery goals
    if (gameState.isFlying) {
      _flightDurationAccum += dt;
      GoalSystem.processEvent(gameState, 'flight_duration',
          metadata: {'value': _flightDurationAccum.toInt()});
    } else {
      _flightDurationAccum = 0;
    }

    // Track power node visits for exploration goals
    if (gameState.isOnPowerNode && gameState.playerTransform != null) {
      final px = gameState.playerTransform!.position.x;
      final pz = gameState.playerTransform!.position.z;
      final nodeKey = '${px.toInt()}_${pz.toInt()}';
      if (!gameState.visitedPowerNodes.contains(nodeKey)) {
        gameState.visitedPowerNodes.add(nodeKey);
        GoalSystem.processEvent(gameState, 'visit_power_node');
        print('[GOALS] Visited new power node: $nodeKey');
      }
    }

    // Tick summoned unit durations and despawn expired ones
    gameState.tickSummonDurations(dt);

    // Update AI systems (monster AI, ally AI, projectiles)
    AISystem.update(
      dt,
      gameState,
      logMonsterAI: _logMonsterAI,
      activateMonsterAbility1: _activateMonsterAbility1,
      activateMonsterAbility2: _activateMonsterAbility2,
      activateMonsterAbility3: _activateMonsterAbility3,
    );

    // Update duel arena system (automated combatant AI + win detection)
    DuelSystem.update(dt, gameState);

    // Animate duel arena banner (drop, flutter, victory flag)
    gameState.duelBannerState?.update(dt, globalWindState);

    // Apply wind drift to allies and monster (normal units have no wind resistance)
    _applyWindDrift(dt);

    // Update dust devil swirls: move columns, apply unit lift
    _updateDustDevils(dt);

    // Handle player ability input (slots 1-10)
    AbilitySystem.handleAbility1Input(inputManager!.isActionPressed(GameAction.actionBar1), gameState);
    AbilitySystem.handleAbility2Input(inputManager!.isActionPressed(GameAction.actionBar2), gameState);
    AbilitySystem.handleAbility3Input(inputManager!.isActionPressed(GameAction.actionBar3), gameState);
    AbilitySystem.handleAbility4Input(inputManager!.isActionPressed(GameAction.actionBar4), gameState);
    AbilitySystem.handleAbility5Input(inputManager!.isActionPressed(GameAction.actionBar5), gameState);
    AbilitySystem.handleAbility6Input(inputManager!.isActionPressed(GameAction.actionBar6), gameState);
    AbilitySystem.handleAbility7Input(inputManager!.isActionPressed(GameAction.actionBar7), gameState);
    AbilitySystem.handleAbility8Input(inputManager!.isActionPressed(GameAction.actionBar8), gameState);
    AbilitySystem.handleAbility9Input(inputManager!.isActionPressed(GameAction.actionBar9), gameState);
    AbilitySystem.handleAbility10Input(inputManager!.isActionPressed(GameAction.actionBar10), gameState);
    // ===== END ABILITY SYSTEM =====

    // ===== ALLY COMMAND SYSTEM =====
    _handleAllyCommands();

    // Update Warchief direction indicator position and rotation
    if (gameState.directionIndicatorTransform != null && gameState.playerTransform != null) {
      gameState.directionIndicatorTransform!.position.x = gameState.playerTransform!.position.x;
      gameState.directionIndicatorTransform!.position.y =
          gameState.playerTransform!.position.y + GameConfig.playerSize / 2 + 0.1;
      gameState.directionIndicatorTransform!.position.z = gameState.playerTransform!.position.z;
      gameState.directionIndicatorTransform!.rotation.y = gameState.playerRotation + 180;
    }

    // Update active ally direction indicator when controlling an ally
    if (!gameState.isWarchiefActive) {
      final activeAlly = gameState.activeAlly;
      if (activeAlly != null && activeAlly.directionIndicatorTransform != null) {
        activeAlly.directionIndicatorTransform!.position.x = activeAlly.transform.position.x;
        activeAlly.directionIndicatorTransform!.position.y =
            activeAlly.transform.position.y + 0.8 / 2 + 0.1;
        activeAlly.directionIndicatorTransform!.position.z = activeAlly.transform.position.z;
        activeAlly.directionIndicatorTransform!.rotation.y = activeAlly.rotation + 180;
      }
    }

    // Update shadow position, rotation, and scale based on active character height and light direction
    if (gameState.shadowTransform != null && gameState.activeTransform != null) {
      // Light direction (from upper-right-front) - normalized direction from where light is coming
      final lightDirX = 0.5; // Light from right
      final lightDirZ = 0.3; // Light from front

      // Calculate shadow offset based on character height above terrain (higher = further from character)
      final playerHeight = PhysicsSystem.getPlayerHeight(gameState);
      final shadowOffsetX = playerHeight * lightDirX;
      final shadowOffsetZ = playerHeight * lightDirZ;

      // Position shadow with offset from active character
      gameState.shadowTransform!.position.x = gameState.activeTransform!.position.x + shadowOffsetX;
      gameState.shadowTransform!.position.z = gameState.activeTransform!.position.z + shadowOffsetZ;

      // Set shadow Y to terrain height at shadow position (slightly above to avoid z-fighting)
      if (gameState.infiniteTerrainManager != null) {
        final shadowTerrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(
          gameState.shadowTransform!.position.x,
          gameState.shadowTransform!.position.z,
        );
        gameState.shadowTransform!.position.y = shadowTerrainHeight + 0.01;
      }

      // Rotate shadow to match active character rotation
      gameState.shadowTransform!.rotation.y = gameState.activeRotation;

      // Shadow gets larger the higher the player is (scale factor includes base size adjustment)
      final scaleFactor = 1.0 + playerHeight * 0.15;
      gameState.shadowTransform!.scale = Vector3(scaleFactor, 1, scaleFactor);
    }

    // Update aura positions — place at each unit's base on terrain
    _updateAuraPositions();

    // Update floating damage indicators
    updateDamageIndicators(gameState.damageIndicators, dt);

    // Update camera based on mode — follows the active character
    if (camera!.mode == CameraMode.thirdPerson) {
      // Third-person mode: Camera follows active character from behind
      camera!.updateThirdPersonFollow(
        gameState.activeTransform!.position,
        gameState.activeRotation,
        dt,
      );
    } else {
      // Static mode: Camera orbits around active character with smoothing
      final currentTarget = camera!.getTarget();
      final distanceFromTarget = (gameState.activeTransform!.position - currentTarget).length;

      // Update camera target smoothly when active character moves away from center
      if (distanceFromTarget > 0.1) {
        // Smoothly interpolate camera target toward active character position
        final newTarget = currentTarget + (gameState.activeTransform!.position - currentTarget) * 0.05;
        camera!.setTarget(newTarget);
      }
    }

    // Flight camera: roll from banking, pitch offset from pitch angle.
    // SHIFT suppresses camera angle changes so the player can look around.
    if (gameState.isFlying) {
      final shiftHeld = inputManager!.isShiftPressed();
      if (shiftHeld) {
        camera!.rollAngle = 0.0;
        camera!.targetPitchOffset = 0.0;
      } else {
        camera!.rollAngle = gameState.flightBankAngle;
        final pitchRad = gameState.flightPitchAngle * (math.pi / 180.0);
        camera!.targetPitchOffset = math.sin(pitchRad) * 5.0;
      }
    } else {
      camera!.rollAngle = 0.0;
      camera!.targetPitchOffset = 0.0;
    }
  }

  /// Update dust devil swirl columns: move them along wind, apply unit lift.
  ///
  /// Lazily initializes [globalWindSwirlState] on first call.
  void _updateDustDevils(double dt) {
    final wind = globalWindState;
    if (wind == null) return;
    globalWindSwirlState ??= WindSwirlState();
    globalWindSwirlState!.update(dt, gameState, wind);
  }

  /// Apply passive wind drift to non-player units during strong derechos.
  ///
  /// Player drift is handled in input_system.dart (respects active stance resistance).
  /// Normal units — allies and monster — have no wind resistance and are always fully pushed.
  void _applyWindDrift(double dt) {
    final wind = globalWindState;
    if (wind == null) return;
    final drift = wind.getWindDrift(dt); // resistance defaults to 0.0 for normal units
    if (drift[0] == 0.0 && drift[1] == 0.0) return;

    for (final ally in gameState.allies) {
      ally.transform.position.x += drift[0];
      ally.transform.position.z += drift[1];
    }
    if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
      gameState.monsterTransform!.position.x += drift[0];
      gameState.monsterTransform!.position.z += drift[1];
    }
  }
}
