import 'package:flutter/services.dart';

/// Enumeration of all possible game actions
///
/// These actions can be bound to keyboard keys and
/// are used throughout the game for player input.
enum GameAction {
  // Movement
  moveForward,
  moveBackward,
  strafeLeft,
  strafeRight,
  rotateLeft,
  rotateRight,
  jump,

  // Camera Control
  cameraRotateLeft,
  cameraRotateRight,
  cameraZoomIn,
  cameraZoomOut,
  cameraPanLeft,
  cameraPanRight,
  cameraPitchUp,
  cameraPitchDown,
  cameraToggleMode,

  // Action Bar
  actionBar1,
  actionBar2,
  actionBar3,
  actionBar4,
  actionBar5,
  actionBar6,
  actionBar7,
  actionBar8,
  actionBar9,
  actionBar10,
  actionBar11,
  actionBar12,

  // Pet/NPC Control
  petAttack,
  petFollow,
  petStay,
  petPassive,
  petDefensive,
  petAggressive,
  cycleFormation,

  // Targeting
  tabTarget,
  tabTargetReverse,
  clearTarget,

  // UI
  toggleSettings,
  toggleInventory,
  toggleMap,
}

/// Extension to provide display names for game actions
extension GameActionExtension on GameAction {
  String get displayName {
    switch (this) {
      case GameAction.moveForward:
        return 'Move Forward';
      case GameAction.moveBackward:
        return 'Move Backward';
      case GameAction.strafeLeft:
        return 'Strafe Left';
      case GameAction.strafeRight:
        return 'Strafe Right';
      case GameAction.rotateLeft:
        return 'Rotate Left';
      case GameAction.rotateRight:
        return 'Rotate Right';
      case GameAction.jump:
        return 'Jump';
      case GameAction.cameraRotateLeft:
        return 'Camera Rotate Left';
      case GameAction.cameraRotateRight:
        return 'Camera Rotate Right';
      case GameAction.cameraZoomIn:
        return 'Camera Zoom In';
      case GameAction.cameraZoomOut:
        return 'Camera Zoom Out';
      case GameAction.cameraPanLeft:
        return 'Camera Pan Left';
      case GameAction.cameraPanRight:
        return 'Camera Pan Right';
      case GameAction.cameraPitchUp:
        return 'Camera Pitch Up';
      case GameAction.cameraPitchDown:
        return 'Camera Pitch Down';
      case GameAction.cameraToggleMode:
        return 'Toggle Camera Mode';
      case GameAction.actionBar1:
        return 'Action Bar 1';
      case GameAction.actionBar2:
        return 'Action Bar 2';
      case GameAction.actionBar3:
        return 'Action Bar 3';
      case GameAction.actionBar4:
        return 'Action Bar 4';
      case GameAction.actionBar5:
        return 'Action Bar 5';
      case GameAction.actionBar6:
        return 'Action Bar 6';
      case GameAction.actionBar7:
        return 'Action Bar 7';
      case GameAction.actionBar8:
        return 'Action Bar 8';
      case GameAction.actionBar9:
        return 'Action Bar 9';
      case GameAction.actionBar10:
        return 'Action Bar 10';
      case GameAction.actionBar11:
        return 'Action Bar 11';
      case GameAction.actionBar12:
        return 'Action Bar 12';
      case GameAction.petAttack:
        return 'Pet Attack';
      case GameAction.petFollow:
        return 'Pet Follow';
      case GameAction.petStay:
        return 'Pet Stay';
      case GameAction.petPassive:
        return 'Pet Passive';
      case GameAction.petDefensive:
        return 'Pet Defensive';
      case GameAction.petAggressive:
        return 'Pet Aggressive';
      case GameAction.cycleFormation:
        return 'Cycle Formation';
      case GameAction.tabTarget:
        return 'Tab Target';
      case GameAction.tabTargetReverse:
        return 'Previous Target';
      case GameAction.clearTarget:
        return 'Clear Target';
      case GameAction.toggleSettings:
        return 'Toggle Settings';
      case GameAction.toggleInventory:
        return 'Toggle Inventory';
      case GameAction.toggleMap:
        return 'Toggle Map';
    }
  }

  /// Default key binding for this action
  LogicalKeyboardKey get defaultKey {
    switch (this) {
      case GameAction.moveForward:
        return LogicalKeyboardKey.keyW;
      case GameAction.moveBackward:
        return LogicalKeyboardKey.keyS;
      case GameAction.strafeLeft:
        return LogicalKeyboardKey.keyQ;
      case GameAction.strafeRight:
        return LogicalKeyboardKey.keyE;
      case GameAction.rotateLeft:
        return LogicalKeyboardKey.keyA;
      case GameAction.rotateRight:
        return LogicalKeyboardKey.keyD;
      case GameAction.jump:
        return LogicalKeyboardKey.space;
      case GameAction.cameraRotateLeft:
        return LogicalKeyboardKey.keyJ;
      case GameAction.cameraRotateRight:
        return LogicalKeyboardKey.keyL;
      case GameAction.cameraZoomIn:
        return LogicalKeyboardKey.keyI;
      case GameAction.cameraZoomOut:
        return LogicalKeyboardKey.keyK;
      case GameAction.cameraPanLeft:
        return LogicalKeyboardKey.keyU;
      case GameAction.cameraPanRight:
        return LogicalKeyboardKey.keyO;
      case GameAction.cameraPitchUp:
        return LogicalKeyboardKey.keyN;
      case GameAction.cameraPitchDown:
        return LogicalKeyboardKey.keyM;
      case GameAction.cameraToggleMode:
        return LogicalKeyboardKey.keyV;
      case GameAction.actionBar1:
        return LogicalKeyboardKey.digit1;
      case GameAction.actionBar2:
        return LogicalKeyboardKey.digit2;
      case GameAction.actionBar3:
        return LogicalKeyboardKey.digit3;
      case GameAction.actionBar4:
        return LogicalKeyboardKey.digit4;
      case GameAction.actionBar5:
        return LogicalKeyboardKey.digit5;
      case GameAction.actionBar6:
        return LogicalKeyboardKey.digit6;
      case GameAction.actionBar7:
        return LogicalKeyboardKey.digit7;
      case GameAction.actionBar8:
        return LogicalKeyboardKey.digit8;
      case GameAction.actionBar9:
        return LogicalKeyboardKey.digit9;
      case GameAction.actionBar10:
        return LogicalKeyboardKey.digit0;
      case GameAction.actionBar11:
        return LogicalKeyboardKey.minus;
      case GameAction.actionBar12:
        return LogicalKeyboardKey.equal;
      case GameAction.petAttack:
        return LogicalKeyboardKey.keyT;
      case GameAction.petFollow:
        return LogicalKeyboardKey.keyF;
      case GameAction.petStay:
        return LogicalKeyboardKey.keyG;
      case GameAction.petPassive:
        return LogicalKeyboardKey.keyH;
      case GameAction.petDefensive:
        return LogicalKeyboardKey.keyJ;
      case GameAction.petAggressive:
        return LogicalKeyboardKey.keyK;
      case GameAction.cycleFormation:
        return LogicalKeyboardKey.keyR;
      case GameAction.tabTarget:
        return LogicalKeyboardKey.tab;
      case GameAction.tabTargetReverse:
        return LogicalKeyboardKey.tab; // Shift+Tab handled separately
      case GameAction.clearTarget:
        return LogicalKeyboardKey.escape;
      case GameAction.toggleSettings:
        return LogicalKeyboardKey.escape;
      case GameAction.toggleInventory:
        return LogicalKeyboardKey.keyI;
      case GameAction.toggleMap:
        return LogicalKeyboardKey.keyM;
    }
  }
}
