part of 'game3d_widget.dart';

mixin _WidgetUIMixin on _GameStateBase {
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _gameFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        // Let text fields handle their own input, but allow Escape through
        // so the user can always close panels and return to the game.
        if (_isTextFieldFocused()) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            _gameFocusNode.requestFocus();
            _onKeyEvent(event);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
        _onKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Container(
        color: Colors.transparent, // Transparent to show canvas behind
        child: Stack(
          children: [
            // Canvas will be created and appended to body in initState.
            // Listener captures left-clicks for entity picking and right-clicks
            // for WoW-style pointer-lock camera rotation.
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                if (event.buttons == 2) {
                  // Right mouse button — start pointer-lock camera drag.
                  // Guard: don't grab pointer if a text field is focused so that
                  // right-clicking in chat/editor fields is unaffected.
                  if (!_isTextFieldFocused()) _startCameraDrag();
                } else {
                  _handleWorldClick(event);
                }
              },
              // Safety net: if the browser delivers a pointer-up event before
              // the html.document.onMouseUp subscription fires, end the drag.
              onPointerUp: (event) {
                if (event.buttons == 0 && _isRightDragging) _endCameraDrag();
              },
              child: SizedBox.expand(),
            ),

            // Floating damage indicators (world-space positioned)
            DamageIndicatorOverlay(
              indicators: gameState.damageIndicators,
              camera: camera,
              canvasWidth: 1600,
              canvasHeight: 900,
            ),

            // World-space ping indicators (from minimap pings)
            if (gameState.minimapState.pings.isNotEmpty && camera != null)
              MinimapPingWorldOverlay(
                pings: gameState.minimapState.pings,
                elapsedTime: gameState.minimapState.elapsedTime,
                viewMatrix: camera?.getViewMatrix(),
                projMatrix: camera?.getProjectionMatrix(),
                screenSize: MediaQuery.of(context).size,
              ),

            // Channeled ability visual effects (life drain, blizzard, etc.)
            ChannelEffectOverlay(
              gameState: gameState,
              camera: camera,
            ),

            // Stance visual effects (Drunken pulse, Fury vignette)
            StanceEffectsOverlay(gameState: gameState),

            // Minimap (draggable, replaces standalone WindIndicator)
            if (gameState.minimapOpen && _isVisible('minimap'))
              _draggable('minimap',
                MinimapWidget(
                  gameState: gameState,
                  windState: gameState.windState,
                  camera: camera,
                  onPingCreated: _handleMinimapPing,
                ),
                width: 180, height: 200,
              ),

            // Stance selector (left side, vertically centered)
            Positioned(
              left: 12,
              top: MediaQuery.of(context).size.height * 0.35,
              child: StanceSelector(
                gameState: gameState,
                onStateChanged: () => setState(() {}),
              ),
            ),

            // Instructions overlay (draggable)
            if (_isVisible('instructions'))
              _draggable('instructions',
                InstructionsOverlay(
                  camera: camera,
                  gameState: gameState,
                ),
                width: 220, height: 200,
              ),

            // ========== NEW WOW-STYLE UNIT FRAMES (All Draggable) ==========

            // Combat HUD (draggable) - Row with fixed-width side panels
            if (_isVisible('combat_hud'))
              _draggable('combat_hud',
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end, // Bottom-align all
                  children: [
                    // Party section - fixed width container so CombatHUD doesn't shift
                    if (_isVisible('party_frames'))
                      SizedBox(
                        width: 172, // Fixed width: buttons (~160) + padding (12)
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          verticalDirection: VerticalDirection.up, // Grow upward
                          children: [
                            // Bottom: Ally control buttons (always at bottom-right of this section)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildAllyControlButton(
                                    icon: Icons.add,
                                    label: '+Ally',
                                    color: const Color(0xFF4CAF50),
                                    onPressed: _addAlly,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildAllyControlButton(
                                    icon: Icons.remove,
                                    label: '-Ally',
                                    color: const Color(0xFFEF5350),
                                    onPressed: _removeAlly,
                                  ),
                                ],
                              ),
                            ),
                            // Party frames above buttons (grows upward)
                            if (gameState.allies.isNotEmpty)
                              const SizedBox(height: 6),
                            if (gameState.allies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: PartyFrames(
                                  allies: gameState.allies,
                                  onAllySelected: (index) {
                                    print('Ally $index selected');
                                  },
                                  onAllyAbilityActivate: _activateAllyAbility,
                                ),
                              ),
                          ],
                        ),
                      ),
                    // CombatHUD - center anchor
                    _buildCombatHUD(),
                    // Minion section - fixed width container
                    if (_isVisible('minion_frames'))
                      SizedBox(
                        width: 172, // Fixed width to match party section
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          verticalDirection: VerticalDirection.up, // Grow upward
                          children: [
                            // Minion frames (grows upward from bottom)
                            if (gameState.minions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: MinionFrames(
                                  minions: gameState.minions,
                                  targetedMinionId: gameState.currentTargetId,
                                  onMinionSelected: (index) {
                                    // Set the clicked minion as current target
                                    if (index < gameState.minions.length) {
                                      final minion = gameState.minions[index];
                                      setState(() {
                                        gameState.setTarget(minion.instanceId);
                                        debugPrint('Targeted minion: ${minion.definition.name}');
                                      });
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                width: 400, height: 180,
              ),

            // Boss/Target abilities panel (draggable)
            if (_isVisible('monster_abilities'))
              _draggable('monster_abilities',
                TargetFrame(
                  name: 'Boss Monster',
                  health: gameState.monsterHealth,
                  maxHealth: gameState.monsterMaxHealth.toDouble(),
                  level: 15,
                  subtitle: 'Elite',
                  isPaused: gameState.monsterPaused,
                  isTargeted: gameState.currentTargetId == 'boss',
                  portraitWidget: const CubePortrait(
                    color: Color(0xFF9933CC),
                    size: 24,
                    hasDirectionIndicator: true,
                    indicatorColor: Colors.green,
                  ),
                  onTap: () {
                    setState(() {
                      gameState.setTarget('boss');
                      debugPrint('Targeted: Boss Monster');
                    });
                  },
                  onPauseToggle: () {
                    setState(() {
                      gameState.monsterPaused = !gameState.monsterPaused;
                    });
                    print('Monster AI ${gameState.monsterPaused ? 'paused' : 'resumed'}');
                  },
                  abilities: [
                    AbilityButtonData(
                      label: 'M1',
                      color: const Color(0xFF8B4513),
                      cooldown: gameState.monsterAbility1Cooldown,
                      maxCooldown: gameState.monsterAbility1CooldownMax,
                      onPressed: _activateMonsterAbility1,
                    ),
                    AbilityButtonData(
                      label: 'M2',
                      color: const Color(0xFF4B0082),
                      cooldown: gameState.monsterAbility2Cooldown,
                      maxCooldown: gameState.monsterAbility2CooldownMax,
                      onPressed: _activateMonsterAbility2,
                    ),
                    AbilityButtonData(
                      label: 'M3',
                      color: const Color(0xFF006400),
                      cooldown: gameState.monsterAbility3Cooldown,
                      maxCooldown: gameState.monsterAbility3CooldownMax,
                      onPressed: _activateMonsterAbility3,
                    ),
                  ],
                ),
                width: 200, height: 120,
              ),

            // AI Chat Panel (draggable)
            if (_isVisible('ai_chat'))
              _draggable('ai_chat',
                AIChatPanel(
                  messages: gameState.monsterAIChat,
                ),
                width: 300, height: 200,
              ),

            // Character Panel (Press C to toggle)
            // Reason: Rendered before command panels so they appear on top of the 750px-wide panel
            if (gameState.characterPanelOpen && _isVisible('character_panel'))
              CharacterPanel(
                gameState: gameState,
                initialIndex: gameState.characterPanelSelectedIndex ?? gameState.activeCharacterIndex,
                onClose: () {
                  setState(() {
                    gameState.characterPanelOpen = false;
                    gameState.characterPanelSelectedIndex = null;
                  });
                },
              ),

            // ========== ALLY COMMANDS PANEL (Press F to toggle) ==========
            if (gameState.allies.isNotEmpty && gameState.allyCommandPanelOpen && _isVisible('ally_commands'))
              AllyCommandsPanel(
                onClose: () {
                  setState(() {
                    gameState.allyCommandPanelOpen = false;
                  });
                },
                currentFormation: gameState.currentFormation,
                onFormationChanged: _changeFormation,
                currentCommand: _getCurrentAllyCommand(),
                onCommandChanged: _setAllyCommand,
                allyCount: gameState.allies.length,
              ),

            // Abilities Modal (Press P to toggle)
            if (gameState.abilitiesModalOpen && _isVisible('abilities_codex'))
              AbilitiesModal(
                onClose: () {
                  setState(() {
                    gameState.abilitiesModalOpen = false;
                  });
                  _gameFocusNode.requestFocus();
                },
                onClassLoaded: _handleClassLoaded,
                gameState: gameState,
              ),

            // Bag Panel (Press B to toggle)
            if (gameState.bagPanelOpen && _isVisible('bag_panel'))
              BagPanel(
                inventory: gameState.playerInventory,
                onClose: () {
                  setState(() {
                    gameState.bagPanelOpen = false;
                  });
                  _gameFocusNode.requestFocus();
                },
                onItemClick: (index, item) {
                  if (item != null) {
                    print('[Bag] Clicked item at slot $index: ${item.name}');
                  }
                },
                onItemEquipped: () => setState(() {
                  gameState.invalidatePlayerAttunementCache();
                }),
                onUnequipToBag: (slot, item) {
                  setState(() {
                    final inventory = gameState.playerInventory;
                    final oldMaxHealth = gameState.playerMaxHealth;
                    inventory.unequip(slot);
                    inventory.addToBag(item);
                    // Reason: adjust health by delta so removing +30 HP gear
                    // removes 30 from current health
                    final healthDelta = gameState.playerMaxHealth - oldMaxHealth;
                    gameState.playerHealth = (gameState.playerHealth + healthDelta)
                        .clamp(0.0, gameState.playerMaxHealth);
                    gameState.invalidatePlayerAttunementCache();
                  });
                },
                onItemCreated: (item) {
                  setState(() {
                    gameState.playerInventory.addToBag(item);
                  });
                },
              ),

            // DPS Panel (Press SHIFT+D to toggle)
            if (gameState.dpsPanelOpen && _isVisible('dps_panel'))
              DpsPanel(
                dpsTracker: gameState.dpsTracker,
                onClose: () {
                  setState(() {
                    gameState.dpsPanelOpen = false;
                    gameState.despawnTargetDummy();
                    if (gameState.currentTargetId == TargetDummy.instanceId) {
                      gameState.clearTarget();
                    }
                  });
                },
              ),

            // Building Panel (Press H near a building to toggle)
            if (gameState.buildingPanelOpen && gameState.selectedBuilding != null)
              BuildingPanel(
                building: gameState.selectedBuilding!,
                leyLineManager: gameState.leyLineManager,
                onClose: () {
                  setState(() {
                    gameState.buildingPanelOpen = false;
                    gameState.selectedBuilding = null;
                  });
                },
                onUpgrade: () {
                  setState(() {
                    BuildingSystem.upgradeBuilding(gameState.selectedBuilding!);
                  });
                },
              ),

            // Goals Panel (Press G to toggle)
            if (gameState.goalsPanelOpen)
              GoalsPanel(
                goals: gameState.goals,
                pendingGoal: gameState.pendingSpiritGoal,
                onAcceptGoal: (def) => setState(() {
                  gameState.goals.add(GoalSystem.acceptGoal(def));
                  gameState.pendingSpiritGoal = null;
                }),
                onDeclineGoal: () => setState(() {
                  gameState.pendingSpiritGoal = null;
                }),
                onClose: () => setState(() {
                  gameState.goalsPanelOpen = false;
                }),
              ),

            // Macro Builder Panel (Press R to toggle)
            if (gameState.macroPanelOpen && _isVisible('rotation_builder'))
              MacroBuilderPanel(
                gameState: gameState,
                onClose: () => setState(() { gameState.macroPanelOpen = false; }),
                onMacroStarted: () => setState(() {}),
              ),

            // Chat Panel (Press ` to toggle — Spirit + Raid tabs)
            if (gameState.chatPanelOpen)
              ChatPanel(
                spiritMessages: gameState.warriorSpiritMessages,
                onSendSpiritMessage: (msg) async {
                  gameState.warriorSpiritMessages.add(
                    AIChatMessage(text: msg, isInput: true));
                  setState(() {});
                  final reply = await WarriorSpirit.chat(gameState, msg);
                  gameState.warriorSpiritMessages.add(
                    AIChatMessage(text: reply, isInput: false));
                  if (mounted) setState(() {});
                },
                raidMessages: gameState.raidChatMessages,
                combatLogMessages: gameState.combatLogMessages,
                consoleLogMessages: gameState.consoleLogMessages,
                initialTab: gameState.chatPanelActiveTab,
                onTabChanged: (tab) {
                  gameState.chatPanelActiveTab = tab;
                },
                onClose: () => setState(() {
                  gameState.chatPanelOpen = false;
                }),
              ),

            // Warrior Spirit Panel (Press V to toggle — standalone)
            if (gameState.warriorSpiritPanelOpen && !gameState.chatPanelOpen)
              WarriorSpiritPanel(
                messages: gameState.warriorSpiritMessages,
                onSendMessage: (msg) async {
                  gameState.warriorSpiritMessages.add(
                    AIChatMessage(text: msg, isInput: true));
                  setState(() {});
                  final reply = await WarriorSpirit.chat(gameState, msg);
                  gameState.warriorSpiritMessages.add(
                    AIChatMessage(text: reply, isInput: false));
                  if (mounted) setState(() {});
                },
                onClose: () => setState(() {
                  gameState.warriorSpiritPanelOpen = false;
                }),
              ),

            // Duel Arena Panel (Press U to toggle)
            if (gameState.duelPanelOpen && gameState.duelManager != null)
              _draggable('duel_panel',
                DuelPanel(
                  manager: gameState.duelManager!,
                  onStartDuel: _startDuel,
                  onCancelDuel: _cancelDuel,
                  onResetCooldowns: _duelResetCooldowns,
                ),
                width: 560, height: 640,
              ),

            // Cast Bar (shows when casting or winding up)
            CastBar(gameState: gameState),
          ],
        ),
      ),
    );
  }
}
