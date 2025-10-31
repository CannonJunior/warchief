import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/game_action.dart';

/// Input manager that handles all keyboard input and keybindings
///
/// This class manages the mapping between keyboard keys and game actions,
/// tracks which keys are currently pressed, and provides callbacks for actions.
class InputManager {
  /// Current keybindings (action -> key)
  final Map<GameAction, LogicalKeyboardKey> _keyBindings = {};

  /// Reverse lookup (key -> action)
  final Map<LogicalKeyboardKey, GameAction> _keyToAction = {};

  /// Set of currently pressed keys
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  /// Callbacks for game actions (action -> callback)
  final Map<GameAction, VoidCallback> _actionCallbacks = {};

  /// Callbacks for continuous actions (called every frame while key is pressed)
  final Map<GameAction, VoidCallback> _continuousCallbacks = {};

  InputManager() {
    _initializeDefaultBindings();
  }

  /// Initialize default keybindings
  void _initializeDefaultBindings() {
    for (final action in GameAction.values) {
      _keyBindings[action] = action.defaultKey;
    }
    _rebuildLookup();
  }

  /// Rebuild the reverse lookup map (key -> action)
  void _rebuildLookup() {
    _keyToAction.clear();
    _keyBindings.forEach((action, key) {
      _keyToAction[key] = action;
    });
  }

  /// Bind a callback to a game action (triggered once on key press)
  void bindAction(GameAction action, VoidCallback callback) {
    _actionCallbacks[action] = callback;
  }

  /// Bind a continuous callback (called every frame while key is held)
  void bindContinuousAction(GameAction action, VoidCallback callback) {
    _continuousCallbacks[action] = callback;
  }

  /// Unbind a callback from an action
  void unbindAction(GameAction action) {
    _actionCallbacks.remove(action);
  }

  /// Unbind a continuous callback
  void unbindContinuousAction(GameAction action) {
    _continuousCallbacks.remove(action);
  }

  /// Handle a keyboard event
  KeyEventResult handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      // Check if this is a new key press (not a repeat)
      if (!_pressedKeys.contains(key)) {
        _pressedKeys.add(key);

        // Trigger action callback if bound
        final action = _keyToAction[key];
        if (action != null && _actionCallbacks.containsKey(action)) {
          _actionCallbacks[action]!();
          return KeyEventResult.handled;
        }
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(key);
    }

    return KeyEventResult.ignored;
  }

  /// Update method - called every frame to handle continuous actions
  ///
  /// This should be called from the game's update loop.
  void update(double dt) {
    // Process continuous callbacks for pressed keys
    for (final key in _pressedKeys) {
      final action = _keyToAction[key];
      if (action != null && _continuousCallbacks.containsKey(action)) {
        _continuousCallbacks[action]!();
      }
    }
  }

  /// Check if a specific action's key is currently pressed
  bool isActionPressed(GameAction action) {
    final key = _keyBindings[action];
    return key != null && _pressedKeys.contains(key);
  }

  /// Check if a specific key is currently pressed
  bool isKeyPressed(LogicalKeyboardKey key) {
    return _pressedKeys.contains(key);
  }

  /// Get the current key binding for an action
  LogicalKeyboardKey? getKeyForAction(GameAction action) {
    return _keyBindings[action];
  }

  /// Get the action bound to a specific key
  GameAction? getActionForKey(LogicalKeyboardKey key) {
    return _keyToAction[key];
  }

  /// Rebind an action to a new key
  ///
  /// Returns true if successful, false if the key is already bound to another action.
  bool rebindAction(GameAction action, LogicalKeyboardKey newKey) {
    // Check if key is already bound to a different action
    final existingAction = _keyToAction[newKey];
    if (existingAction != null && existingAction != action) {
      debugPrint(
          'Warning: Key ${newKey.keyLabel} already bound to ${existingAction.displayName}');
      return false;
    }

    _keyBindings[action] = newKey;
    _rebuildLookup();
    debugPrint('Rebound ${action.displayName} to ${newKey.keyLabel}');
    return true;
  }

  /// Reset all keybindings to defaults
  void resetToDefaults() {
    _initializeDefaultBindings();
    debugPrint('Reset all keybindings to defaults');
  }

  /// Get all currently pressed keys (for debugging)
  Set<LogicalKeyboardKey> get pressedKeys => Set.unmodifiable(_pressedKeys);

  /// Get all current keybindings (for settings UI)
  Map<GameAction, LogicalKeyboardKey> get keyBindings =>
      Map.unmodifiable(_keyBindings);
}
