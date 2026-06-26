import 'package:flutter/foundation.dart';
import '../data/stances/stance_types.dart';
import '../data/stances/stance_mechanics.dart';
import '../data/abilities/ability_types.dart';
import '../state/stance_runtime_state.dart';

/// Per-frame update logic for advanced stance mechanics.
///
/// Called from `game3d_widget_update.dart` each frame. Handles timer decay,
/// stack decay, beat pulses, heat management, pressure decay, and
/// stagnation tracking.
class StanceRuntimeSystem {
  StanceRuntimeSystem._();

  /// Main update — dispatches to the active stance's update logic.
  static void update(
    double dt,
    StanceId activeStance,
    StanceData stanceData,
    StanceRuntimeState state,
  ) {
    final m = stanceData.mechanics;
    if (m == null) return;

    switch (activeStance) {
      case StanceId.cadence:
        _updateCadence(dt, m, state);
      case StanceId.tempest:
        _updateTempest(dt, m, state);
      case StanceId.warden:
        _updateWarden(dt, m, state);
      case StanceId.crucible:
        _updateCrucible(dt, m, state);
      case StanceId.momentum:
        _updateMomentum(dt, m, state);
      case StanceId.pressure:
        _updatePressure(dt, m, state);
      case StanceId.flux:
        _updateFlux(dt, m, state);
      default:
        break;
    }
  }

  // ==================== CADENCE ====================

  static void _updateCadence(
    double dt,
    StanceMechanics m,
    StanceRuntimeState s,
  ) {
    if (m.rhythmPulseInterval <= 0) return;
    s.cadenceBeatTimer += dt;
    if (s.cadenceBeatTimer >= m.rhythmPulseInterval) {
      s.cadenceBeatTimer -= m.rhythmPulseInterval;
    }
  }

  /// Check if an ability cast is within the beat window.
  /// Returns true if on-beat.
  static bool checkCadenceBeat(StanceMechanics m, StanceRuntimeState s) {
    if (m.rhythmPulseInterval <= 0) return false;
    final distToBeat = s.cadenceBeatTimer < m.rhythmPulseInterval / 2
        ? s.cadenceBeatTimer
        : m.rhythmPulseInterval - s.cadenceBeatTimer;
    final onBeat = distToBeat <= m.rhythmBeatWindow;
    if (onBeat) {
      s.cadenceGrooveStacks =
          (s.cadenceGrooveStacks + 1).clamp(0, m.grooveMaxStacks);
      s.cadenceLastCastOnBeat = true;
    } else {
      s.cadenceGrooveStacks = 0;
      s.cadenceLastCastOnBeat = false;
    }
    return onBeat;
  }

  // ==================== TEMPEST ====================

  static void _updateTempest(
    double dt,
    StanceMechanics m,
    StanceRuntimeState s,
  ) {
    if (s.tempestInCancelWindow) {
      s.tempestCancelTimer += dt;
      if (s.tempestCancelTimer >= m.cancelWindowDuration) {
        s.tempestInCancelWindow = false;
        s.tempestChainDepth = 0;
        s.tempestCancelTimer = 0.0;
      }
    }
  }

  /// Called when an ability lands a hit in Tempest stance.
  static void onTempestHit(StanceMechanics m, StanceRuntimeState s) {
    if (m.cancelWindowDuration <= 0) return;
    s.tempestInCancelWindow = true;
    s.tempestCancelTimer = 0.0;
    if (s.tempestChainDepth < m.cancelMaxChain) {
      s.tempestChainDepth++;
    }
  }

  /// Called when an ability is cast during a cancel window.
  /// Returns true if the cast should skip GCD.
  static bool consumeTempestCancel(StanceMechanics m, StanceRuntimeState s) {
    if (!s.tempestInCancelWindow) return false;
    s.tempestInCancelWindow = false;
    s.tempestCancelTimer = 0.0;
    return true;
  }

  /// Get the damage scale for the current chain position.
  static double getTempestChainScale(StanceMechanics m, StanceRuntimeState s) {
    if (s.tempestChainDepth <= 0 || m.cancelChainDamageScale.isEmpty) {
      return 1.0;
    }
    final idx =
        (s.tempestChainDepth - 1).clamp(0, m.cancelChainDamageScale.length - 1);
    return m.cancelChainDamageScale[idx];
  }

  // ==================== WARDEN ====================

  static void _updateWarden(
    double dt,
    StanceMechanics m,
    StanceRuntimeState s,
  ) {
    // Decay movement input window
    if (s.wardenInputTimer > 0) {
      s.wardenInputTimer -= dt;
      if (s.wardenInputTimer <= 0) {
        s.wardenInputTimer = 0.0;
        s.wardenLastDirection = WardenDirection.stationary;
      }
    }

    // Combat timer: 5s without an ability firing = out of combat
    if (s.wardenInCombat) {
      s.wardenCombatTimer += dt;
      if (s.wardenCombatTimer >= 5.0) {
        s.wardenInCombat = false;
        s.wardenCombatTimer = 0.0;
      }
    }

    // Predator's Eye: accumulate stationary time out of combat
    if (!s.wardenInCombat &&
        s.wardenLastDirection == WardenDirection.stationary) {
      s.wardenPredatorTimer += dt;
      if (s.wardenPredatorTimer >= m.predatorActivationTime &&
          !s.wardenInPredatorMode) {
        s.wardenInPredatorMode = true;
        debugPrint('[STANCE] Warden: Predator\'s Eye activated');
      }
    } else {
      s.wardenPredatorTimer = 0.0;
      if (s.wardenInCombat) {
        s.wardenInPredatorMode = false;
      }
    }
  }

  /// Record a WASD movement input for Warden.
  static void recordWardenInput(
    StanceMechanics m,
    StanceRuntimeState s,
    WardenDirection dir,
  ) {
    s.wardenLastDirection = dir;
    s.wardenInputTimer = m.movementInputWindow;
    if (dir != WardenDirection.none && dir != WardenDirection.stationary) {
      s.wardenPredatorTimer = 0.0;
      s.wardenInPredatorMode = false;
    }
  }

  // ==================== CRUCIBLE ====================

  static void _updateCrucible(
    double dt,
    StanceMechanics m,
    StanceRuntimeState s,
  ) {
    // Overheat timer
    if (s.crucibleOverheated) {
      s.crucibleOverheatTimer -= dt;
      if (s.crucibleOverheatTimer <= 0) {
        s.crucibleOverheated = false;
        s.crucibleOverheatTimer = 0.0;
        s.crucibleHeatStacks = 0;
        s.crucibleAtZeroHeat = true;
        debugPrint('[STANCE] Crucible: Overheat ended, heat reset');
      }
      return;
    }

    // Heat decay
    if (s.crucibleHeatStacks > 0 && m.heatDecayRate > 0) {
      s.crucibleHeatDecayTimer += dt;
      final decayInterval = 1.0 / m.heatDecayRate;
      if (s.crucibleHeatDecayTimer >= decayInterval) {
        s.crucibleHeatDecayTimer -= decayInterval;
        s.crucibleHeatStacks--;
        if (s.crucibleHeatStacks <= 0) {
          s.crucibleHeatStacks = 0;
          s.crucibleAtZeroHeat = true;
        }
      }
    }
  }

  /// Called when an ability is cast in Crucible stance. Returns true if
  /// the cast triggers Overheat.
  static bool onCrucibleCast(StanceMechanics m, StanceRuntimeState s) {
    if (s.crucibleOverheated) return true;
    s.crucibleAtZeroHeat = false;
    s.crucibleHeatStacks += m.heatPerCast;
    s.crucibleHeatDecayTimer = 0.0;
    if (s.crucibleHeatStacks >= m.heatMaxStacks) {
      s.crucibleOverheated = true;
      s.crucibleOverheatTimer = m.overheatSilenceDuration;
      debugPrint('[STANCE] Crucible: OVERHEAT! Silenced for ${m.overheatSilenceDuration}s');
      return true;
    }
    return false;
  }

  /// Called when a crit lands — reduces heat by 1.
  static void onCrucibleCrit(StanceRuntimeState s) {
    if (s.crucibleHeatStacks > 0) {
      s.crucibleHeatStacks--;
      if (s.crucibleHeatStacks <= 0) {
        s.crucibleAtZeroHeat = true;
      }
    }
  }

  // ==================== MOMENTUM ====================

  static void _updateMomentum(
    double dt,
    StanceMechanics m,
    StanceRuntimeState s,
  ) {
    if (s.momentumStacks > 0 && m.momentumDecayInterval > 0) {
      s.momentumDecayTimer += dt;
      if (s.momentumDecayTimer >= m.momentumDecayInterval) {
        s.momentumDecayTimer -= m.momentumDecayInterval;
        s.momentumStacks--;
        if (s.momentumStacks < 0) s.momentumStacks = 0;
      }
    }
  }

  /// Called when an ability hits in Momentum stance.
  /// [isAoeMultiHit] true if the ability hit 3+ targets.
  /// [isComboprimed] true if the ability was combo-primed.
  static void onMomentumHit(
    StanceMechanics m,
    StanceRuntimeState s,
    AbilityType abilityType, {
    bool isAoeMultiHit = false,
    bool isComboPrimed = false,
  }) {
    int stacks = 1;
    if (isAoeMultiHit) stacks = 2;
    if (isComboPrimed) stacks = 2;
    s.momentumStacks =
        (s.momentumStacks + stacks).clamp(0, m.momentumMaxStacks);
    s.momentumDecayTimer = 0.0;
    s.momentumLastAbilityType = abilityType;
  }

  // ==================== PRESSURE ====================

  static void _updatePressure(
    double dt,
    StanceMechanics m,
    StanceRuntimeState s,
  ) {
    s.pressureLastHitTimer += dt;
    if (m.pressureDecayPerSecond <= 0) return;
    final decay = m.pressureDecayPerSecond * dt;
    final toRemove = <int>[];
    for (final entry in s.pressurePerTarget.entries) {
      final targetId = entry.key;
      final isActive = targetId == s.pressureCurrentTargetId;
      final effectiveDecay = isActive ? decay : decay * 3.0;
      s.pressurePerTarget[targetId] = entry.value - effectiveDecay;
      if (s.pressurePerTarget[targetId]! <= 0) {
        toRemove.add(targetId);
      }
    }
    for (final id in toRemove) {
      s.pressurePerTarget.remove(id);
      s.pressureDamageSchools.remove(id);
    }
  }

  /// Called when an ability hits a target in Pressure stance.
  /// Returns true if the target BREAKS (reaches 100% pressure).
  static bool onPressureHit(
    StanceMechanics m,
    StanceRuntimeState s,
    int targetId,
    DamageSchool school, {
    bool isMelee = true,
    bool isDot = false,
    bool hasWindup = false,
  }) {
    double amount;
    if (isDot) {
      amount = m.pressurePerDot;
    } else if (isMelee) {
      amount = m.pressurePerMelee;
    } else {
      amount = m.pressurePerRanged;
    }
    if (hasWindup) amount += m.pressureWindupBonus;

    // Combo bonus for consecutive hits
    if (s.pressureLastHitTimer < 1.5 &&
        targetId == s.pressureCurrentTargetId) {
      amount += m.pressureComboBonus;
    }

    s.pressureCurrentTargetId = targetId;
    s.pressureLastHitTimer = 0.0;
    s.recordPressureSchool(targetId, school);

    final current = s.pressurePerTarget[targetId] ?? 0.0;
    final next = (current + amount).clamp(0.0, 1.0);
    s.pressurePerTarget[targetId] = next;

    if (next >= 1.0) {
      s.pressurePerTarget.remove(targetId);
      s.pressureDamageSchools.remove(targetId);
      debugPrint('[STANCE] Pressure: TARGET $targetId BREAK! '
          'Dominant school: ${s.getDominantSchool(targetId)?.name ?? 'physical'}');
      return true;
    }
    return false;
  }

  // ==================== FLUX ====================

  static void _updateFlux(
    double dt,
    StanceMechanics m,
    StanceRuntimeState s,
  ) {
    // Transition bonus timer
    if (s.fluxTransitionBonusAvailable) {
      s.fluxTransitionTimer += dt;
      if (s.fluxTransitionTimer >= m.transitionBonusWindow) {
        s.fluxTransitionBonusAvailable = false;
      }
    }

    // Memory timer
    if (s.fluxMemoryAbilityName != null) {
      s.fluxMemoryTimer += dt;
      if (s.fluxMemoryTimer >= m.fluxMemoryDuration) {
        s.fluxMemoryAbilityName = null;
        s.fluxMemoryTimer = 0.0;
      }
    }

    // Weave window
    if (s.fluxSwitchCount > 0) {
      s.fluxWeaveWindowTimer += dt;
      if (s.fluxWeaveWindowTimer >= m.weaveWindow) {
        s.fluxSwitchCount = 0;
        s.fluxWeaveWindowTimer = 0.0;
      }
    }

    // Weave active timer
    if (s.fluxWeaveActive) {
      s.fluxWeaveActiveTimer += dt;
      if (s.fluxWeaveActiveTimer >= m.weaveBonusDuration) {
        s.fluxWeaveActive = false;
        s.fluxWeaveActiveTimer = 0.0;
      }
    }

    // Stagnation penalty
    s.fluxStagnationTimer += dt;
    if (s.fluxStagnationTimer >= m.stagnationPenaltyTime && !s.fluxStagnant) {
      s.fluxStagnant = true;
      debugPrint('[STANCE] Flux: Stagnation penalty active (-${(m.stagnationDamageReduction * 100).round()}% damage)');
    }

    // Check weave state trigger
    if (s.fluxSwitchCount >= m.weaveThreshold && !s.fluxWeaveActive) {
      s.fluxWeaveActive = true;
      s.fluxWeaveActiveTimer = 0.0;
      s.fluxSwitchCount = 0;
      s.fluxWeaveWindowTimer = 0.0;
      debugPrint('[STANCE] Flux: WEAVE STATE activated!');
    }
  }

  /// Called when an ability is cast in Flux stance.
  /// Returns true if the transition bonus was consumed.
  static bool consumeFluxTransition(StanceMechanics m, StanceRuntimeState s) {
    if (!s.fluxTransitionBonusAvailable) return false;
    s.fluxTransitionBonusAvailable = false;
    return true;
  }

  /// Record the last ability used in Flux for the Memory mechanic.
  static void recordFluxMemory(
    StanceMechanics m,
    StanceRuntimeState s,
    String abilityName,
  ) {
    s.fluxMemoryAbilityName = abilityName;
    s.fluxMemoryTimer = 0.0;
  }
}
