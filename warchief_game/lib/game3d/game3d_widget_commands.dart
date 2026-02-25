part of 'game3d_widget.dart';

/// Default positions for draggable panels (used if config not available)
const Map<String, Offset> _defaultPositions = {
  'instructions': Offset(10, 10),
  'combat_hud': Offset(300, 500),
  'monster_abilities': Offset(10, 300),
  'ai_chat': Offset(10, 450),
  'minimap': Offset(1410, 8),
};

/// Pixels before drag activates (prevents micro-drags from interfering with taps)
const double _dragThreshold = 5.0;

mixin _WidgetCommandsMixin on _GameStateBase {
  // ==================== ALLY COMMAND STATE ====================

  /// Track previous command key states to detect key press (not hold)
  bool _attackKeyWasPressed = false;
  bool _holdKeyWasPressed = false;
  bool _formationKeyWasPressed = false;

  /// Track SHIFT+key state for formation panel toggling
  bool _shiftFormationWasPressed = false;

  /// Drag state tracking for panels
  final Map<String, bool> _isDragging = {};
  final Map<String, Offset> _dragStartPos = {};

  // ==================== PANEL DRAGGING ====================

  /// Check if an interface is visible (defaults to true if config not available)
  bool _isVisible(String id) {
    return globalInterfaceConfig?.isVisible(id) ?? true;
  }

  /// Get position for an interface (from config manager or defaults)
  Offset _getPos(String id) {
    return globalInterfaceConfig?.getPosition(id) ?? _defaultPositions[id] ?? Offset.zero;
  }

  /// Update position for an interface (saves to config manager)
  void _updatePos(String id, Offset delta, Size screenSize, Size widgetSize) {
    Offset current = _getPos(id);
    double newX = (current.dx + delta.dx).clamp(0.0, screenSize.width - widgetSize.width);
    double newY = (current.dy + delta.dy).clamp(0.0, screenSize.height - widgetSize.height);
    globalInterfaceConfig?.setPosition(id, Offset(newX, newY));
  }

  /// Build a draggable panel (like AbilitiesModal pattern)
  Widget _draggable(String id, Widget child, {double width = 200, double height = 100}) {
    final pos = _getPos(id);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      // Use Listener for drag to avoid gesture arena conflicts with child buttons
      child: Listener(
        behavior: HitTestBehavior.translucent, // Allow children to also receive hit tests
        onPointerDown: (event) {
          // Record drag start position
          _isDragging[id] = false;
          _dragStartPos[id] = event.position;
        },
        onPointerMove: (event) {
          // Only process drag when primary button (left mouse) is pressed
          if (event.buttons == 1) {
            final startPos = _dragStartPos[id];
            if (startPos != null) {
              // Check if we've exceeded the drag threshold
              if (!(_isDragging[id] ?? false)) {
                final distance = (event.position - startPos).distance;
                if (distance >= _dragThreshold) {
                  _isDragging[id] = true;
                }
              }
              // Only apply movement if we're in drag mode
              if (_isDragging[id] ?? false) {
                _updatePos(id, event.delta, MediaQuery.of(context).size, Size(width, height));
              }
            }
          }
        },
        onPointerUp: (event) {
          // Reset drag state
          _isDragging[id] = false;
          _dragStartPos.remove(id);
        },
        onPointerCancel: (event) {
          // Reset drag state
          _isDragging[id] = false;
          _dragStartPos.remove(id);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: child,
        ),
      ),
    );
  }

  // ==================== ALLY COMMANDS ====================

  /// Handle ally command input (T=Attack, G=Hold, R=Formation)
  ///
  /// F key now toggles the unified AllyCommandsPanel (handled in _onKeyEvent).
  void _handleAllyCommands() {
    if (inputManager == null) return;

    final shiftPressed = inputManager!.isShiftPressed();
    final attackPressed = inputManager!.isActionPressed(GameAction.petAttack);
    final holdPressed = inputManager!.isActionPressed(GameAction.petStay);
    final formationPressed = inputManager!.isActionPressed(GameAction.cycleFormation);

    // Without SHIFT - execute commands directly
    if (!shiftPressed) {
      // T key - Attack command (toggle)
      if (attackPressed && !_attackKeyWasPressed) {
        _setAllyCommand(AllyCommand.attack);
        print('[ALLY CMD] All allies: ATTACK');
      }
      _attackKeyWasPressed = attackPressed;

      // G key - Hold command (toggle)
      if (holdPressed && !_holdKeyWasPressed) {
        _setAllyCommand(AllyCommand.hold);
        print('[ALLY CMD] All allies: HOLD');
      }
      _holdKeyWasPressed = holdPressed;

      // R key - Cycle formation
      if (formationPressed && !_formationKeyWasPressed) {
        _cycleFormation();
      }
      _formationKeyWasPressed = formationPressed;
    }
  }

  /// Cycle through available formations
  void _cycleFormation() {
    final formations = FormationType.values;
    final currentIndex = formations.indexOf(gameState.currentFormation);
    final nextIndex = (currentIndex + 1) % formations.length;
    gameState.currentFormation = formations[nextIndex];
    gameState.invalidateTacticalPositions();
    print('[FORMATION] Changed to: ${gameState.currentFormation.name}');
  }

  /// Set command for all allies
  void _setAllyCommand(AllyCommand command) {
    setState(() {
      for (final ally in gameState.allies) {
        // If same command, toggle it off
        if (ally.currentCommand == command) {
          ally.currentCommand = AllyCommand.none;
          ally.movementMode = AllyMovementMode.followPlayer;
        } else {
          ally.currentCommand = command;
          ally.commandTimer = 0.0;
        }
      }
    });
    // Track ally commands for goals
    GoalSystem.processEvent(gameState, 'ally_command_issued');
  }

  /// Get the current command active across allies (for UI display)
  AllyCommand _getCurrentAllyCommand() {
    if (gameState.allies.isEmpty) return AllyCommand.none;
    // Return the first non-none command, or none if all allies have none
    for (final ally in gameState.allies) {
      if (ally.currentCommand != AllyCommand.none) {
        return ally.currentCommand;
      }
    }
    return AllyCommand.none;
  }

  // ==================== MONSTER ABILITY METHODS ====================

  /// Activate Monster Ability 1: Dark Strike (melee sword attack)
  void _activateMonsterAbility1() {
    if (gameState.monsterAbility1Cooldown > 0 || gameState.monsterHealth <= 0) return;
    if (gameState.monsterAbility1Active) return; // Already swinging

    setState(() {
      gameState.monsterAbility1Cooldown = gameState.monsterAbility1CooldownMax;
      gameState.monsterAbility1Active = true;
      gameState.monsterAbility1ActiveTime = 0.0;
      gameState.monsterAbility1HitRegistered = false;
    });
    print('Monster uses Dark Strike! (sword attack)');
  }

  /// Activate Monster Ability 2: Shadow Bolt (ranged projectile)
  void _activateMonsterAbility2() {
    if (gameState.monsterAbility2Cooldown > 0 || gameState.monsterHealth <= 0) return;
    if (gameState.monsterTransform == null || gameState.playerTransform == null) return;

    final shadowBolt = AbilitiesConfig.monsterShadowBolt;

    // Create shadow bolt projectile aimed at player
    final direction = (gameState.playerTransform!.position - gameState.monsterTransform!.position).normalized();
    final projectileMesh = Mesh.cube(
      size: shadowBolt.projectileSize,
      color: shadowBolt.color,
    );
    final projectileTransform = Transform3d(
      position: gameState.monsterTransform!.position.clone() + Vector3(0, 1, 0),
      scale: Vector3(1, 1, 1),
    );

    setState(() {
      gameState.monsterProjectiles.add(Projectile(
        mesh: projectileMesh,
        transform: projectileTransform,
        velocity: direction * shadowBolt.projectileSpeed,
        lifetime: 5.0,
      ));
      gameState.monsterAbility2Cooldown = gameState.monsterAbility2CooldownMax;
    });
    print('Monster casts ${shadowBolt.name}!');
  }

  /// Activate Monster Ability 3: Dark Healing (restore health)
  void _activateMonsterAbility3() {
    if (gameState.monsterAbility3Cooldown > 0 || gameState.monsterHealth <= 0) return;

    final darkHeal = AbilitiesConfig.monsterDarkHeal;

    final oldHealth = gameState.monsterHealth;
    setState(() {
      gameState.monsterHealth = math.min(gameState.monsterMaxHealth.toDouble(), gameState.monsterHealth + darkHeal.healAmount);
      gameState.monsterAbility3Cooldown = gameState.monsterAbility3CooldownMax;
    });
    final healedAmount = gameState.monsterHealth - oldHealth;
    if (healedAmount > 0 && gameState.monsterTransform != null) {
      final pos = gameState.monsterTransform!.position.clone();
      pos.y += 2.0;
      gameState.damageIndicators.add(DamageIndicator(
        damage: healedAmount,
        worldPosition: pos,
        isHeal: true,
      ));
    }
    print('[HEAL] Monster uses ${darkHeal.name}! Restored ${healedAmount.toStringAsFixed(1)} HP (${gameState.monsterHealth.toStringAsFixed(0)}/${gameState.monsterMaxHealth})');
  }

  // ==================== AI CHAT LOGGING ====================

  /// Add a message to the Monster AI chat log
  void _logMonsterAI(String text, {required bool isInput}) {
    setState(() {
      gameState.monsterAIChat.add(AIChatMessage(
        text: text,
        isInput: isInput,
      ));

      // Keep only last 50 messages to avoid memory issues
      if (gameState.monsterAIChat.length > 50) {
        gameState.monsterAIChat.removeAt(0);
      }
    });
  }

  // ==================== ALLY MANAGEMENT ====================

  /// Manually activate an ally's ability (called from UI button)
  void _activateAllyAbility(Ally ally) {
    if (ally.abilityCooldown > 0 || ally.health <= 0) {
      print('Ally ability on cooldown or ally is dead');
      return;
    }

    setState(() {
      // Force the ally to use their ability
      AISystem.executeAllyDecision(ally, 'ATTACK', gameState);
      print('Manually activated ally ability ${ally.abilityIndex}');
    });
  }

  /// Change an ally's strategy
  void _changeAllyStrategy(Ally ally, AllyStrategyType newStrategy) {
    setState(() {
      ally.strategyType = newStrategy;
      // Update follow distance based on new strategy
      ally.followBufferDistance = ally.strategy.followDistance;
      print('Ally strategy changed to: ${ally.strategy.name}');
    });
  }

  /// Change the formation type for all allies
  void _changeFormation(FormationType newFormation) {
    setState(() {
      gameState.currentFormation = newFormation;
      gameState.invalidateTacticalPositions();
      print('[FORMATION] Changed to: ${newFormation.name}');
    });
  }

  /// Add a new ally with a random ability
  void _addAlly() {
    debugPrint('_addAlly called! Current allies: ${gameState.allies.length}');
    setState(() {
      // Generate random ability (0, 1, or 2)
      final random = math.Random();
      final randomAbility = random.nextInt(3);

      // Create ally mesh (smaller, brighter blue than player)
      final allyMesh = Mesh.cube(
        size: 0.8, // 0.8x player size
        color: Vector3(0.4, 0.7, 1.0), // Brighter blue than player (0.3, 0.5, 0.8)
      );

      // Position ally near player (offset to avoid overlap)
      final allyCount = gameState.allies.length;
      final angle = (allyCount * 60.0) * (math.pi / 180.0); // Space out in circle
      final offsetX = math.cos(angle) * 2.0;
      final offsetZ = math.sin(angle) * 2.0;

      // Calculate ally position with terrain height
      final allyX = gameState.playerTransform != null
          ? gameState.playerTransform!.position.x + offsetX
          : 2.0 + offsetX;
      final allyZ = gameState.playerTransform != null
          ? gameState.playerTransform!.position.z + offsetZ
          : 2.0 + offsetZ;

      // Get terrain height at ally position (add half size so bottom sits on terrain)
      const double allySize = 0.8;
      double allyY = 0.4 + allySize / 2 + _terrainBuffer; // Default fallback
      if (gameState.infiniteTerrainManager != null) {
        final terrainHeight = gameState.infiniteTerrainManager!.getTerrainHeight(allyX, allyZ);
        allyY = terrainHeight + allySize / 2 + _terrainBuffer;
      }

      final allyPosition = Vector3(allyX, allyY, allyZ);

      final allyTransform = Transform3d(
        position: allyPosition,
        scale: Vector3(1, 1, 1),
      );

      // Create ally object
      final ally = Ally(
        mesh: allyMesh,
        transform: allyTransform,
        rotation: 0.0,
        abilityIndex: randomAbility,
        health: 50.0,
        maxHealth: 50.0,
        abilityCooldown: 0.0,
        abilityCooldownMax: 5.0,
        aiTimer: 0.0,
      );

      gameState.allies.add(ally);

      // Initialize aura for the new ally
      final allyIndex = gameState.allies.length; // 1-based for config manager
      _updateAllyAuraColor(ally, allyIndex);

      final abilityNames = ['Sword', 'Fireball', 'Heal'];
      print('Ally added! Ability: ${abilityNames[randomAbility]} (Total: ${gameState.allies.length})');
    });
  }

  /// Remove the most recently added ally
  void _removeAlly() {
    if (gameState.allies.isEmpty) {
      print('No allies to remove!');
      return;
    }

    setState(() {
      gameState.allies.removeLast();
      print('Ally removed! Remaining: ${gameState.allies.length}');
    });
  }

  // ==================== AURA MANAGEMENT ====================

  /// Update the player's aura mesh color from the active action bar config.
  void _updatePlayerAuraColor() {
    final config = globalActionBarConfigManager?.getConfig(0);
    if (config == null) return;

    final color = AuraSystem.computeAuraColor(config);
    final newMesh = AuraSystem.createOrUpdateAuraMesh(
      color: color,
      radius: 1.2,
      existing: gameState.playerAuraMesh,
      lastColor: gameState.lastPlayerAuraColor,
    );
    gameState.playerAuraMesh = newMesh;
    if (color != null) {
      gameState.lastPlayerAuraColor = color.clone();
    }
  }

  /// Update an ally's aura mesh color from their action bar config.
  void _updateAllyAuraColor(Ally ally, int allyConfigIndex) {
    final config = globalActionBarConfigManager?.getConfig(allyConfigIndex);
    if (config == null) return;

    final color = AuraSystem.computeAuraColor(config);
    final newMesh = AuraSystem.createOrUpdateAuraMesh(
      color: color,
      radius: 0.8,
      existing: ally.auraMesh,
      lastColor: ally.lastAuraColor,
    );
    ally.auraMesh = newMesh;
    if (color != null) {
      ally.lastAuraColor = color.clone();
    }
  }

  /// Position all aura discs at their unit's base on terrain each frame.
  void _updateAuraPositions() {
    // Player aura — update position in-place to avoid Vector3 allocation
    if (gameState.playerAuraTransform != null && gameState.playerTransform != null) {
      double auraY = 0.02;
      if (gameState.infiniteTerrainManager != null) {
        auraY = gameState.infiniteTerrainManager!.getTerrainHeight(
          gameState.playerTransform!.position.x,
          gameState.playerTransform!.position.z,
        ) + 0.02;
      }
      gameState.playerAuraTransform!.position.x = gameState.playerTransform!.position.x;
      gameState.playerAuraTransform!.position.y = auraY;
      gameState.playerAuraTransform!.position.z = gameState.playerTransform!.position.z;
    }

    // Ally auras — update position in-place
    for (final ally in gameState.allies) {
      if (ally.auraMesh != null) {
        double auraY = 0.02;
        if (gameState.infiniteTerrainManager != null) {
          auraY = gameState.infiniteTerrainManager!.getTerrainHeight(
            ally.transform.position.x,
            ally.transform.position.z,
          ) + 0.02;
        }
        ally.auraTransform.position.x = ally.transform.position.x;
        ally.auraTransform.position.y = auraY;
        ally.auraTransform.position.z = ally.transform.position.z;
      }
    }
  }

  /// Refresh all aura colors (call when action bar config changes).
  void _refreshAllAuraColors() {
    _updatePlayerAuraColor();
    for (int i = 0; i < gameState.allies.length; i++) {
      _updateAllyAuraColor(gameState.allies[i], i + 1);
    }
  }
}
