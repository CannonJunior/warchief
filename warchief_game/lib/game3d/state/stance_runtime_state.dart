import '../data/stances/stance_types.dart';
import '../data/abilities/ability_types.dart';

/// Runtime state for advanced stance mechanics.
///
/// Updated per-frame by [StanceRuntimeSystem]. One instance lives on
/// [GameState] and tracks the active stance's dynamic values (beat timers,
/// stacks, heat, pressure gauges, etc.).
class StanceRuntimeState {
  // ==================== CADENCE ====================
  double cadenceBeatTimer = 0.0;
  int cadenceGrooveStacks = 0;
  bool cadenceLastCastOnBeat = false;

  // ==================== TEMPEST ====================
  int tempestChainDepth = 0;
  double tempestCancelTimer = 0.0;
  bool tempestInCancelWindow = false;

  // ==================== WARDEN ====================
  WardenDirection wardenLastDirection = WardenDirection.none;
  double wardenInputTimer = 0.0;
  double wardenPredatorTimer = 0.0;
  bool wardenInPredatorMode = false;
  bool wardenInCombat = false;
  double wardenCombatTimer = 0.0;

  // ==================== CRUCIBLE ====================
  int crucibleHeatStacks = 0;
  double crucibleHeatDecayTimer = 0.0;
  bool crucibleOverheated = false;
  double crucibleOverheatTimer = 0.0;
  bool crucibleAtZeroHeat = true;

  // ==================== MOMENTUM ====================
  int momentumStacks = 0;
  double momentumDecayTimer = 0.0;
  AbilityType? momentumLastAbilityType;

  // ==================== PRESSURE ====================
  /// Pressure gauge per target entity ID.
  final Map<int, double> pressurePerTarget = {};
  /// Tracks which damage school was used most during pressure build.
  final Map<int, Map<DamageSchool, int>> pressureDamageSchools = {};
  double pressureLastHitTimer = 0.0;
  int? pressureCurrentTargetId;

  // ==================== FLUX ====================
  double fluxTransitionTimer = 0.0;
  bool fluxTransitionBonusAvailable = false;
  String? fluxMemoryAbilityName;
  double fluxMemoryTimer = 0.0;
  int fluxSwitchCount = 0;
  double fluxWeaveWindowTimer = 0.0;
  double fluxWeaveActiveTimer = 0.0;
  bool fluxWeaveActive = false;
  double fluxStagnationTimer = 0.0;
  bool fluxStagnant = false;

  /// Reset all state — called when switching to a different stance.
  void reset() {
    // Cadence
    cadenceBeatTimer = 0.0;
    cadenceGrooveStacks = 0;
    cadenceLastCastOnBeat = false;
    // Tempest
    tempestChainDepth = 0;
    tempestCancelTimer = 0.0;
    tempestInCancelWindow = false;
    // Warden
    wardenLastDirection = WardenDirection.none;
    wardenInputTimer = 0.0;
    wardenPredatorTimer = 0.0;
    wardenInPredatorMode = false;
    wardenInCombat = false;
    wardenCombatTimer = 0.0;
    // Crucible
    crucibleHeatStacks = 0;
    crucibleHeatDecayTimer = 0.0;
    crucibleOverheated = false;
    crucibleOverheatTimer = 0.0;
    crucibleAtZeroHeat = true;
    // Momentum
    momentumStacks = 0;
    momentumDecayTimer = 0.0;
    momentumLastAbilityType = null;
    // Pressure
    pressurePerTarget.clear();
    pressureDamageSchools.clear();
    pressureLastHitTimer = 0.0;
    pressureCurrentTargetId = null;
    // Flux
    fluxTransitionTimer = 0.0;
    fluxTransitionBonusAvailable = false;
    fluxMemoryAbilityName = null;
    fluxMemoryTimer = 0.0;
    fluxSwitchCount = 0;
    fluxWeaveWindowTimer = 0.0;
    fluxWeaveActiveTimer = 0.0;
    fluxWeaveActive = false;
    fluxStagnationTimer = 0.0;
    fluxStagnant = false;
  }

  /// Called when the player switches TO a stance.
  void onStanceEnter(StanceId id) {
    if (id == StanceId.flux) {
      fluxTransitionTimer = 0.0;
      fluxTransitionBonusAvailable = true;
      fluxStagnationTimer = 0.0;
      fluxStagnant = false;
      fluxSwitchCount++;
      fluxWeaveWindowTimer = 0.0;
    }
    if (id == StanceId.cadence) {
      cadenceBeatTimer = 0.0;
    }
  }

  /// Called when the player switches AWAY from a stance.
  void onStanceLeave(StanceId id) {
    if (id == StanceId.flux) {
      fluxTransitionBonusAvailable = false;
    }
    if (id == StanceId.tempest) {
      tempestChainDepth = 0;
      tempestCancelTimer = 0.0;
      tempestInCancelWindow = false;
    }
  }

  /// Get the dominant damage school for a target's pressure build.
  DamageSchool? getDominantSchool(int targetId) {
    final schools = pressureDamageSchools[targetId];
    if (schools == null || schools.isEmpty) return null;
    DamageSchool? best;
    int bestCount = 0;
    for (final entry in schools.entries) {
      if (entry.value > bestCount) {
        bestCount = entry.value;
        best = entry.key;
      }
    }
    return best;
  }

  /// Record a damage school hit for pressure tracking.
  void recordPressureSchool(int targetId, DamageSchool school) {
    pressureDamageSchools
        .putIfAbsent(targetId, () => {})
        .update(school, (v) => v + 1, ifAbsent: () => 1);
  }
}

/// Directional input state for Warden stance.
enum WardenDirection {
  none,
  forward,
  backward,
  strafeLeft,
  strafeRight,
  stationary,
  sprint,
}
