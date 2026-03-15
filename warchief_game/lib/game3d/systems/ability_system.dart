import 'package:flutter/foundation.dart' show debugPrint;
import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;
import 'dart:ui' show Color;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../state/abilities_config.dart';
import '../state/action_bar_config.dart' show globalActionBarConfig;
import '../state/gameplay_settings.dart' show globalGameplaySettings;
import '../state/ability_override_manager.dart';
import '../state/wind_state.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../models/projectile.dart';
import '../../models/impact_effect.dart';
import 'combat_system.dart';
import 'goal_system.dart';
import '../../models/combat_log_entry.dart';
import '../../models/console_log_entry.dart';
import '../ui/damage_indicators.dart';
import '../../models/active_effect.dart';
import '../utils/bezier_path.dart';

part 'ability_system_core.dart';
part 'ability_system_mana.dart';
part 'ability_system_dispatch.dart';
part 'ability_system_cast_effects.dart';
part 'ability_system_implementations.dart';
part 'ability_system_windwalker.dart';
part 'ability_system_interactions.dart';
part 'ability_system_updates.dart';

/// Internal mana type enumeration used only within the ability system.
enum _ManaType { none, blue, red, white, green, black }

/// Ability System — handles all player ability logic.
///
/// Public API: [update], [executeSlotAbility], [getCooldownForSlot],
/// and [handleAbilityNInput] (1–10). All implementation details are in
/// the part files (ability_system_core.dart, _dispatch.dart, etc.).
class AbilitySystem {
  AbilitySystem._(); // Prevent instantiation — static-only utility class.

  // ==================== PUBLIC API ====================

  /// Main per-frame entry point — call once per update tick.
  static void update(double dt, GameState gameState) {
    _updateCooldowns(dt, gameState);
    _updateCastingState(dt, gameState);
    _updateWindupState(dt, gameState);
    _updateChannelingState(dt, gameState);
    _updateSpiritChannelState(dt, gameState);
    _updateAbility1(dt, gameState);
    _updateAbility2(dt, gameState);
    _updateAbility3(dt, gameState);
    _updateAbility4(dt, gameState);
    _updateImpactEffects(dt, gameState);
    _updateExecutingLabel(dt, gameState);
    _updateExitingQueueLabels(dt, gameState);
    _drainAbilityQueue(gameState);
  }

  /// Execute the ability in a given action bar slot.
  static void executeSlotAbility(int slotIndex, GameState gameState) =>
      _executeSlotAbility(slotIndex, gameState);

  /// Get remaining cooldown for a slot (public for macro pre-checks).
  static double getCooldownForSlot(int slotIndex, GameState gameState) {
    final cds = gameState.activeAbilityCooldowns;
    if (slotIndex < 0 || slotIndex >= cds.length) return 0;
    return cds[slotIndex];
  }

  /// Recompute [GameState.abilityQueuePrimedSlots] from the current queue tail.
  /// Public so widget-layer ESC-dequeue can trigger the refresh without importing
  /// the internal dispatch file.
  static void refreshQueuePrimedSlots(GameState gameState) =>
      _refreshQueuePrimedSlots(gameState);

  // ==================== INPUT HANDLERS ====================

  // Reason: tracks which slots have a key currently held so that the per-frame
  // isActionPressed poll only triggers the ability once per physical key press,
  // not every frame the key is held.
  static final Set<int> _slotsCurrentlyHeld = {};

  static void _handleAbilityInput(int slot, bool pressed, GameState gameState) {
    if (!pressed) {
      _slotsCurrentlyHeld.remove(slot);
      return;
    }
    if (_slotsCurrentlyHeld.contains(slot)) return; // already fired this press
    _slotsCurrentlyHeld.add(slot);
    executeSlotAbility(slot, gameState);
  }

  static void handleAbility1Input(bool pressed, GameState gameState) =>
      _handleAbilityInput(0, pressed, gameState);
  static void handleAbility2Input(bool pressed, GameState gameState) =>
      _handleAbilityInput(1, pressed, gameState);
  static void handleAbility3Input(bool pressed, GameState gameState) =>
      _handleAbilityInput(2, pressed, gameState);
  static void handleAbility4Input(bool pressed, GameState gameState) =>
      _handleAbilityInput(3, pressed, gameState);
  static void handleAbility5Input(bool pressed, GameState gameState) =>
      _handleAbilityInput(4, pressed, gameState);
  static void handleAbility6Input(bool pressed, GameState gameState) =>
      _handleAbilityInput(5, pressed, gameState);
  static void handleAbility7Input(bool pressed, GameState gameState) =>
      _handleAbilityInput(6, pressed, gameState);
  static void handleAbility8Input(bool pressed, GameState gameState) =>
      _handleAbilityInput(7, pressed, gameState);
  static void handleAbility9Input(bool pressed, GameState gameState) =>
      _handleAbilityInput(8, pressed, gameState);
  static void handleAbility10Input(bool pressed, GameState gameState) =>
      _handleAbilityInput(9, pressed, gameState);
}
