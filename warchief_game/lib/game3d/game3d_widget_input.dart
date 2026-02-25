part of 'game3d_widget.dart';

mixin _WidgetInputMixin on _GameStateBase {
  // ==================== INPUT HELPERS ====================

  /// Check if a text input field currently has focus.
  /// EditableText is the inner widget that TextField/TextFormField use for input.
  bool _isTextFieldFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final context = focus.context;
    if (context == null) return false;
    // The focused widget itself is EditableText when a TextField has focus
    if (context.widget is EditableText) return true;
    // Also check ancestors in case focus is on a child of EditableText
    bool found = false;
    context.visitAncestorElements((element) {
      if (element.widget is EditableText) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  // ==================== KEYBOARD INPUT ====================

  void _onKeyEvent(KeyEvent event) {
    // Handle P key for abilities modal (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyP) {
      if (!_isVisible('abilities_codex')) return;
      print('P key detected! Toggling abilities modal.');
      setState(() {
        gameState.abilitiesModalOpen = !gameState.abilitiesModalOpen;
      });
      return;
    }

    // Handle C key for character panel (only on key down, not repeat)
    // Opens to the active party member's tab
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (!_isVisible('character_panel')) return;
      print('C key detected! Toggling character panel (active: ${gameState.activeCharacterIndex}).');
      setState(() {
        gameState.characterPanelOpen = !gameState.characterPanelOpen;
        if (!gameState.characterPanelOpen) {
          gameState.characterPanelSelectedIndex = null;
        }
      });
      return;
    }

    // Handle B key for bag panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyB) {
      if (!_isVisible('bag_panel')) return;
      print('B key detected! Toggling bag panel.');
      setState(() {
        gameState.bagPanelOpen = !gameState.bagPanelOpen;
      });
      return;
    }

    // Handle M key for minimap toggle (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyM) {
      if (!_isVisible('minimap')) return;
      setState(() {
        gameState.minimapOpen = !gameState.minimapOpen;
      });
      return;
    }

    // Handle F key for ally commands panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyF) {
      if (!_isVisible('ally_commands')) return;
      if (gameState.allies.isNotEmpty) {
        print('F key detected! Toggling ally commands panel.');
        setState(() {
          gameState.allyCommandPanelOpen = !gameState.allyCommandPanelOpen;
        });
      }
      return;
    }

    // Handle G key for goals panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyG) {
      // Reason: G was previously unbound. Only intercept without shift
      // so T (attack) and G (hold) commands still work with shift combos.
      if (!HardwareKeyboard.instance.isShiftPressed) {
        setState(() {
          gameState.goalsPanelOpen = !gameState.goalsPanelOpen;
        });
        return;
      }
    }

    // Handle R key for Macro Builder panel (only on key down)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyR) {
      if (!_isVisible('rotation_builder')) return;
      setState(() {
        gameState.macroPanelOpen = !gameState.macroPanelOpen;
      });
      return;
    }

    // Handle ` (backtick) key for Chat panel (only on key down)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backquote) {
      setState(() {
        gameState.chatPanelOpen = !gameState.chatPanelOpen;
      });
      return;
    }

    // Handle H key for building panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyH) {
      setState(() {
        if (gameState.buildingPanelOpen) {
          // Close if already open
          gameState.buildingPanelOpen = false;
          gameState.selectedBuilding = null;
        } else {
          // Open if near a building
          final nearest = gameState.getNearestBuilding(
            globalBuildingConfig?.interactionRange ?? 5.0,
          );
          if (nearest != null) {
            gameState.selectedBuilding = nearest;
            gameState.buildingPanelOpen = true;
            print('[BUILDING] Opened panel for ${nearest.definition.name}');
          }
        }
      });
      return;
    }

    // Handle X key for stances: Shift+X cycles, X toggles selector panel
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyX) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if (isShiftPressed) {
        // Shift+X: cycle to next stance
        setState(() {
          gameState.cycleStance();
        });
      } else {
        // X: toggle stance selector panel
        setState(() {
          gameState.stanceSelectorOpen = !gameState.stanceSelectorOpen;
        });
      }
      return;
    }

    // Handle SHIFT+D for DPS testing panel (only on key down, not repeat)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyD) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if (isShiftPressed) {
        if (!_isVisible('dps_panel')) return;
        print('SHIFT+D detected! Toggling DPS panel.');
        setState(() {
          gameState.dpsPanelOpen = !gameState.dpsPanelOpen;
          if (gameState.dpsPanelOpen) {
            // Spawn target dummy when opening DPS panel
            gameState.spawnTargetDummy(gameState.infiniteTerrainManager);
            // Auto-target the dummy
            gameState.setTarget(TargetDummy.instanceId);
          } else {
            // Despawn target dummy when closing DPS panel
            gameState.despawnTargetDummy();
            // Clear target if it was the dummy
            if (gameState.currentTargetId == TargetDummy.instanceId) {
              gameState.clearTarget();
            }
          }
        });
        return;
      }
    }

    // Handle Tab/Shift+Tab for target cycling (WoW-style)
    // Shift+Tab = cycle friendly targets, Tab = cycle enemy targets
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

      if (isShiftPressed) {
        // Shift+Tab = cycle friendly targets
        setState(() {
          gameState.tabToNextFriendlyTarget();
          debugPrint('Shift+Tab: friendly target -> ${gameState.currentTargetId}');
        });
        return;
      }

      final playerX = gameState.activeTransform?.position.x ?? 0.0;
      final playerZ = gameState.activeTransform?.position.z ?? 0.0;
      final playerRotation = gameState.activeRotation;

      setState(() {
        gameState.tabToNextTarget(playerX, playerZ, playerRotation);
        final target = gameState.getCurrentTarget();
        if (target != null) {
          final name = target['type'] == 'boss' ? 'Boss Monster' :
            (target['entity'] as Monster?)?.definition.name ?? 'Unknown';
          debugPrint('Tab target: $name');
        } else {
          debugPrint('No targets available');
        }
      });
      return;
    }

    // Handle [ and ] keys for party cycling or panel carousel
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.bracketLeft) {
      setState(() {
        if (gameState.characterPanelOpen) {
          // Cycle panel carousel
          final total = 1 + gameState.allies.length;
          final current = gameState.characterPanelSelectedIndex ?? gameState.activeCharacterIndex;
          gameState.characterPanelSelectedIndex = (current - 1 + total) % total;
        } else {
          // Cycle active controlled character
          gameState.cycleActiveCharacterPrev();
          _updateActiveActionBarConfig();
        }
      });
      return;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.bracketRight) {
      setState(() {
        if (gameState.characterPanelOpen) {
          // Cycle panel carousel
          final total = 1 + gameState.allies.length;
          final current = gameState.characterPanelSelectedIndex ?? gameState.activeCharacterIndex;
          gameState.characterPanelSelectedIndex = (current + 1) % total;
        } else {
          // Cycle active controlled character
          gameState.cycleActiveCharacterNext();
          _updateActiveActionBarConfig();
        }
      });
      return;
    }

    // Handle Escape key to close any open modal/panel or clear target
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (gameState.abilitiesModalOpen) {
        setState(() { gameState.abilitiesModalOpen = false; });
        return;
      }
      if (gameState.characterPanelOpen) {
        setState(() {
          gameState.characterPanelOpen = false;
          gameState.characterPanelSelectedIndex = null;
        });
        return;
      }
      if (gameState.bagPanelOpen) {
        setState(() { gameState.bagPanelOpen = false; });
        return;
      }
      if (gameState.allyCommandPanelOpen) {
        setState(() { gameState.allyCommandPanelOpen = false; });
        return;
      }
      if (gameState.dpsPanelOpen) {
        setState(() {
          gameState.dpsPanelOpen = false;
          gameState.despawnTargetDummy();
          if (gameState.currentTargetId == TargetDummy.instanceId) {
            gameState.clearTarget();
          }
        });
        return;
      }
      if (gameState.buildingPanelOpen) {
        setState(() {
          gameState.buildingPanelOpen = false;
          gameState.selectedBuilding = null;
        });
        return;
      }
      if (gameState.goalsPanelOpen) {
        setState(() { gameState.goalsPanelOpen = false; });
        return;
      }
      if (gameState.macroPanelOpen) {
        setState(() { gameState.macroPanelOpen = false; });
        return;
      }
      if (gameState.chatPanelOpen) {
        setState(() { gameState.chatPanelOpen = false; });
        return;
      }
      if (gameState.warriorSpiritPanelOpen) {
        setState(() { gameState.warriorSpiritPanelOpen = false; });
        return;
      }
      // Clear target if no modal is open
      if (gameState.currentTargetId != null) {
        setState(() {
          gameState.clearTarget();
          debugPrint('Target cleared');
        });
        return;
      }
    }

    if (inputManager != null) {
      inputManager!.handleKeyEvent(event);
    }
  }

  // ==================== MOUSE INPUT ====================

  /// Handle left-click on the game world for entity picking (click-to-select).
  ///
  /// Projects all entity positions to screen space and selects the closest
  /// entity to the click point within [GameConfig.clickSelectionRadius].
  /// Clicking empty space clears the current target.
  void _handleWorldClick(PointerDownEvent event) {
    // Only process primary (left) mouse button
    if (event.buttons != 1) return;
    if (camera == null) return;

    // Reclaim keyboard focus from any active text field
    _gameFocusNode.requestFocus();

    final clickPos = event.localPosition;
    final viewMatrix = camera!.getViewMatrix();
    final projMatrix = camera!.getProjectionMatrix();
    final screenSize = MediaQuery.of(context).size;

    final pickedId = EntityPickingSystem.pickEntity(
      clickPos: clickPos,
      viewMatrix: viewMatrix,
      projMatrix: projMatrix,
      screenSize: screenSize,
      gameState: gameState,
      selectionRadius: GameConfig.clickSelectionRadius,
    );

    setState(() {
      gameState.setTarget(pickedId);
      if (pickedId != null) {
        debugPrint('Click-selected: $pickedId');
      }
    });
  }

  /// Handle ping created from clicking the minimap.
  ///
  /// Creates a [MinimapPing] at the given world XZ position and adds it
  /// to the minimap state. The ping is visible on both the minimap
  /// (expanding rings) and in the 3D world view (diamond icon).
  void _handleMinimapPing(double worldX, double worldZ) {
    final config = globalMinimapConfig;
    final colorList = config?.pingDefaultColor ?? [1.0, 0.9, 0.3, 1.0];
    final color = Color.fromRGBO(
      (colorList[0] * 255).round(),
      (colorList[1] * 255).round(),
      (colorList[2] * 255).round(),
      colorList.length > 3 ? colorList[3] : 1.0,
    );

    setState(() {
      gameState.minimapState.addPing(MinimapPing(
        worldX: worldX,
        worldZ: worldZ,
        createTime: gameState.minimapState.elapsedTime,
        color: color,
      ));
    });
    print('[MINIMAP] Ping at world ($worldX, $worldZ)');
  }

  // ==================== ABILITY ACTIVATION ====================

  // Ability activation methods (for clickable buttons)
  void _activateAbility1() {
    setState(() { AbilitySystem.handleAbility1Input(true, gameState); });
  }

  void _activateAbility2() {
    setState(() { AbilitySystem.handleAbility2Input(true, gameState); });
  }

  void _activateAbility3() {
    setState(() { AbilitySystem.handleAbility3Input(true, gameState); });
  }

  void _activateAbility4() {
    setState(() { AbilitySystem.handleAbility4Input(true, gameState); });
  }

  void _activateAbility5() {
    setState(() { AbilitySystem.handleAbility5Input(true, gameState); });
  }

  void _activateAbility6() {
    setState(() { AbilitySystem.handleAbility6Input(true, gameState); });
  }

  void _activateAbility7() {
    setState(() { AbilitySystem.handleAbility7Input(true, gameState); });
  }

  void _activateAbility8() {
    setState(() { AbilitySystem.handleAbility8Input(true, gameState); });
  }

  void _activateAbility9() {
    setState(() { AbilitySystem.handleAbility9Input(true, gameState); });
  }

  void _activateAbility10() {
    setState(() { AbilitySystem.handleAbility10Input(true, gameState); });
  }

  /// Update the action bar config manager to match the active character
  void _updateActiveActionBarConfig() {
    globalActionBarConfigManager?.setActiveIndex(gameState.activeCharacterIndex);
    final activeIdx = gameState.activeCharacterIndex;
    final name = activeIdx == 0 ? 'Warchief' : 'Ally $activeIdx';
    print('[PARTY] Active character: $name');
  }

  /// Handle ability dropped from Abilities Codex onto action bar slot
  void _handleAbilityDropped(int slotIndex, String abilityName) {
    final config = globalActionBarConfig;
    if (config != null) {
      config.setSlotAbility(slotIndex, abilityName);
      print('[ActionBar] Assigned "$abilityName" to slot ${slotIndex + 1}');
      _refreshAllAuraColors(); // Update aura glow to reflect new ability loadout
      setState(() {}); // Refresh UI to show new ability
    }
  }

  /// Handle class loaded to action bar — update active character mesh color
  void _handleClassLoaded(String category) {
    final color = AuraSystem.getCategoryColorVec3(category);
    if (gameState.isWarchiefActive) {
      gameState.playerMesh = PlayerMesh.createSimpleCharacter(bodyColor: color);
    } else {
      final ally = gameState.activeAlly;
      if (ally != null) {
        ally.mesh = Mesh.cube(size: 0.8, color: color);
      }
    }
    _refreshAllAuraColors();
    setState(() {});
  }
}
