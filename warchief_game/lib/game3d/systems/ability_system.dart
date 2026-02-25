import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;
import 'dart:ui' show Color;

import '../state/game_state.dart';
import '../state/game_config.dart';
import '../state/abilities_config.dart';
import '../state/action_bar_config.dart' show globalActionBarConfig;
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
    _updateAbility1(dt, gameState);
    _updateAbility2(dt, gameState);
    _updateAbility3(dt, gameState);
    _updateAbility4(dt, gameState);
    _updateImpactEffects(dt, gameState);
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

  // ==================== INPUT HANDLERS ====================

  static void handleAbility1Input(bool pressed, GameState gameState) {
    if (pressed && gameState.activeAbilityCooldowns[0] <= 0 && !gameState.ability1Active) {
      executeSlotAbility(0, gameState);
    }
  }

  static void handleAbility2Input(bool pressed, GameState gameState) {
    if (pressed && gameState.activeAbilityCooldowns[1] <= 0 && gameState.activeTransform != null) {
      executeSlotAbility(1, gameState);
    }
  }

  static void handleAbility3Input(bool pressed, GameState gameState) {
    if (pressed && gameState.activeAbilityCooldowns[2] <= 0 && !gameState.ability3Active) {
      executeSlotAbility(2, gameState);
    }
  }

  static void handleAbility4Input(bool pressed, GameState gameState) {
    if (pressed && gameState.activeAbilityCooldowns[3] <= 0 && !gameState.ability4Active) {
      executeSlotAbility(3, gameState);
    }
  }

  static void handleAbility5Input(bool pressed, GameState gameState) {
    if (pressed && gameState.activeAbilityCooldowns[4] <= 0) executeSlotAbility(4, gameState);
  }

  static void handleAbility6Input(bool pressed, GameState gameState) {
    if (pressed && gameState.activeAbilityCooldowns[5] <= 0) executeSlotAbility(5, gameState);
  }

  static void handleAbility7Input(bool pressed, GameState gameState) {
    if (pressed && gameState.activeAbilityCooldowns[6] <= 0) executeSlotAbility(6, gameState);
  }

  static void handleAbility8Input(bool pressed, GameState gameState) {
    if (pressed && gameState.activeAbilityCooldowns[7] <= 0) executeSlotAbility(7, gameState);
  }

  static void handleAbility9Input(bool pressed, GameState gameState) {
    if (pressed && gameState.activeAbilityCooldowns[8] <= 0) executeSlotAbility(8, gameState);
  }

  static void handleAbility10Input(bool pressed, GameState gameState) {
    if (pressed && gameState.activeAbilityCooldowns[9] <= 0) executeSlotAbility(9, gameState);
  }
}
