import 'dart:math' as math;
import '../state/game_state.dart';
import '../state/duel_manager.dart';
import '../state/duel_config.dart';
import '../data/abilities/ability_types.dart';
import '../../models/ally.dart';
import '../../models/duel_result.dart';

/// Per-frame duel orchestration system.
///
/// Supports 1–5 combatants per side. Combatant layout in [GameState.duelCombatants]:
///   indices 0 .. challengerPartySize-1       → challenger party (blue side)
///   indices challengerPartySize .. chalSize+enemySize-1 → enemy party (red side)
///
/// AI uses a priority-based ability selector influenced by [DuelStrategy].
/// Gear tier applies a damage multiplier sourced from [duel_config.json].
class DuelSystem {
  DuelSystem._();

  // ==================== MAIN UPDATE ====================

  static void update(double dt, GameState gameState) {
    final manager = gameState.duelManager;
    if (manager == null || manager.phase != DuelPhase.active) return;

    // Reason: use cached party lists set at duel start — avoids two sublist()
    // allocations every frame.
    final challengers = manager.challengerParty;
    final enemies     = manager.enemyParty;
    if (challengers.isEmpty || enemies.isEmpty) return;

    final chalSize  = challengers.length;
    final enemySize = enemies.length;

    manager.elapsedSeconds += dt;

    // Snap every alive combatant to the terrain surface each frame.
    // Reason: the AI moves combatants in XZ only; without Y correction they
    // sink into or float above hilly terrain as they walk toward each other.
    final terrMgr = gameState.infiniteTerrainManager;
    for (final c in gameState.duelCombatants) {
      if (c.health <= 0) continue;
      final th = terrMgr != null
          ? terrMgr.getTerrainHeight(c.transform.position.x, c.transform.position.z)
          : gameState.groundLevel;
      c.transform.position.y = th + 0.4 + 0.15; // half cube-size(0.8) + terrain buffer
    }

    // Regen mana + tick ability cooldowns + tick GCDs — skip dead combatants.
    for (int i = 0; i < chalSize; i++) {
      if (challengers[i].health <= 0) continue;
      _regenMana(dt, challengers[i]);
      final abilityCount = i < manager.challengerPartyAbilities.length
          ? manager.challengerPartyAbilities[i].length : 0;
      _tickCooldowns(dt, challengers[i], abilityCount);
    }
    for (int i = 0; i < enemySize; i++) {
      if (enemies[i].health <= 0) continue;
      _regenMana(dt, enemies[i]);
      final abilityCount = i < manager.enemyPartyAbilities.length
          ? manager.enemyPartyAbilities[i].length : 0;
      _tickCooldowns(dt, enemies[i], abilityCount);
    }

    // Tick per-combatant GCD + combo-window timers.
    // Reason: stored centrally on the manager so the Active tab can read them
    // for display without polling the individual Ally objects.
    _tickGcds(dt, manager);

    // Run AI for every alive challenger
    for (int i = 0; i < chalSize; i++) {
      if (challengers[i].health <= 0) continue;
      final abilities = i < manager.challengerPartyAbilities.length
          ? manager.challengerPartyAbilities[i] : <AbilityData>[];
      final gearDmgMult = i < manager.challengerDamageMults.length
          ? manager.challengerDamageMults[i] : 1.0;
      // Reason: GCD index = combatant's position in the flat combatantGcds list.
      _runAI(dt, challengers[i], enemies, challengers,
          'challenger', abilities, manager, manager.challengerStrategy, gearDmgMult, i);
    }

    // Run AI for every alive enemy
    for (int i = 0; i < enemySize; i++) {
      if (enemies[i].health <= 0) continue;
      final abilities = i < manager.enemyPartyAbilities.length
          ? manager.enemyPartyAbilities[i] : <AbilityData>[];
      final gearDmgMult = i < manager.enemyDamageMults.length
          ? manager.enemyDamageMults[i] : 1.0;
      _runAI(dt, enemies[i], challengers, enemies,
          'enemy', abilities, manager, manager.enemyStrategy, gearDmgMult, chalSize + i);
    }

    // ── Win / draw check ──────────────────────────────────────────────────────
    // Reason: firstKill ends on ANY death; totalAnnihilation ends when ALL of
    // one side is dead.  Winner logic is identical — just the threshold differs.
    final maxDur    = globalDuelConfig?.maxDurationSeconds ?? 120.0;
    final timedOut  = manager.elapsedSeconds >= maxDur;
    final firstKill = manager.endCondition == DuelEndCondition.firstKill;
    final chalDead  = firstKill
        ? challengers.any((c) => c.health <= 0)
        : challengers.every((c) => c.health <= 0);
    final enemyDead = firstKill
        ? enemies.any((e) => e.health <= 0)
        : enemies.every((e) => e.health <= 0);

    if (chalDead || enemyDead || timedOut) {
      String winnerId;
      if (chalDead && enemyDead) {
        winnerId = 'draw';
      } else if (chalDead) {
        winnerId = 'enemy';
      } else if (enemyDead) {
        winnerId = 'challenger';
      } else {
        // Timeout: award victory to whichever side has more total HP remaining
        final chalHp  = challengers.fold(0.0, (s, c) => s + c.health);
        final enemyHp = enemies.fold(0.0, (s, e) => s + e.health);
        winnerId = chalHp >= enemyHp ? 'challenger' : 'enemy';
      }
      manager.finalizeDuel(winnerId, manager.elapsedSeconds);
      gameState.duelBannerState?.notifyWinner(winnerId);
    }
  }

  // ==================== RESET ====================

  /// Zero out every ability cooldown for every combatant in the list.
  static void resetCooldowns(List<Ally> combatants) {
    for (final c in combatants) {
      for (int i = 0; i < c.abilityCooldowns.length; i++) {
        c.abilityCooldowns[i] = 0.0;
      }
    }
  }

  // ==================== GCD TICK ====================

  /// Decrement per-combatant GCD and combo-window timers each frame.
  static void _tickGcds(double dt, DuelManager manager) {
    for (int i = 0; i < manager.combatantGcds.length; i++) {
      if (manager.combatantGcds[i] > 0) {
        manager.combatantGcds[i] =
            (manager.combatantGcds[i] - dt).clamp(0.0, double.infinity);
      }
    }
    for (int i = 0; i < manager.combatantComboWindows.length; i++) {
      if (manager.combatantComboWindows[i] > 0) {
        manager.combatantComboWindows[i] =
            (manager.combatantComboWindows[i] - dt).clamp(0.0, double.infinity);
      }
    }
  }

  // ==================== AI ====================

  static void _runAI(
    double dt,
    Ally self,
    List<Ally> enemies,    // opposing party (damage targets)
    List<Ally> ownParty,   // own party (heal targets for Support strategy)
    String actorId,
    List<AbilityData> abilities,
    DuelManager manager,
    DuelStrategy strategy,
    double gearDamageMult,
    int combatantIdx,      // index into manager.combatantGcds / combatantComboWindows
  ) {
    if (self.health <= 0) return;

    // ── Target selection: weakest alive enemy ────────────────────────────────
    // Reason: single-pass scan avoids the .where().toList() allocation that
    // would otherwise occur for every alive combatant every frame.
    Ally? target;
    for (final e in enemies) {
      if (e.health <= 0) continue;
      if (target == null || e.health < target.health) target = e;
    }
    if (target == null) return;

    // ── Movement ─────────────────────────────────────────────────────────────
    final dx   = target.transform.position.x - self.transform.position.x;
    final dz   = target.transform.position.z - self.transform.position.z;
    final dist = math.sqrt(dx * dx + dz * dz);
    final preferred = _preferredDistance(strategy);

    if (dist > preferred + 0.5) {
      final spd = self.moveSpeed * dt;
      self.transform.position.x += (dx / dist) * spd;
      self.transform.position.z += (dz / dist) * spd;
    } else if (strategy == DuelStrategy.defensive && dist < preferred - 1.5 && dist > 0.01) {
      // Kite backwards: keep defensive units at preferred range
      final spd = self.moveSpeed * 0.5 * dt;
      self.transform.position.x -= (dx / dist) * spd;
      self.transform.position.z -= (dz / dist) * spd;
    }

    // ── GCD / combo-window state ──────────────────────────────────────────────
    // Reason: combo-primer abilities (enablesComboChain=true) bypass the GCD
    // and open a window for the follow-up ability to also bypass it, mirroring
    // the main game's melee combo system.
    final gcdActive     = combatantIdx < manager.combatantGcds.length
        && manager.combatantGcds[combatantIdx] > 0;
    final inComboWindow = combatantIdx < manager.combatantComboWindows.length
        && manager.combatantComboWindows[combatantIdx] > 0;

    // ── Ability selection ─────────────────────────────────────────────────────
    int? chosenIdx;
    if (strategy == DuelStrategy.balanced) {
      // Greedy: first usable ability in list order (original behaviour)
      for (int i = 0; i < abilities.length; i++) {
        if (!_abilityReady(self, abilities[i], i)) continue;
        // Skip non-exempt abilities while GCD is active
        if (gcdActive && !abilities[i].enablesComboChain && !inComboWindow) continue;
        chosenIdx = i;
        break;
      }
    } else {
      // Priority-scored: highest-scoring usable ability wins
      int bestScore = -1;
      for (int i = 0; i < abilities.length; i++) {
        if (!_abilityReady(self, abilities[i], i)) continue;
        if (gcdActive && !abilities[i].enablesComboChain && !inComboWindow) continue;
        final score = _abilityPriority(abilities[i], strategy, self);
        if (score > bestScore) {
          bestScore = score;
          chosenIdx = i;
        }
      }
    }

    if (chosenIdx == null) return;

    final ability = abilities[chosenIdx];

    // Apply individual ability cooldown + deduct mana
    if (chosenIdx < self.abilityCooldowns.length) {
      self.abilityCooldowns[chosenIdx] = ability.cooldown;
    }
    _deductMana(self, ability);

    // ── GCD / combo-window update after ability fires ─────────────────────────
    if (ability.enablesComboChain) {
      // Combo primer: open combo window, do NOT apply GCD.
      final windowDur = globalDuelConfig?.comboWindowSeconds ?? 3.0;
      if (combatantIdx < manager.combatantComboWindows.length) {
        manager.combatantComboWindows[combatantIdx] = windowDur;
      }
    } else if (inComboWindow) {
      // Combo follow-up during window: close window, do NOT apply GCD.
      if (combatantIdx < manager.combatantComboWindows.length) {
        manager.combatantComboWindows[combatantIdx] = 0.0;
      }
    } else {
      // Normal ability: apply shared GCD.
      final gcdDur = globalDuelConfig?.gcdSeconds ?? 1.0;
      if (combatantIdx < manager.combatantGcds.length) {
        manager.combatantGcds[combatantIdx] = gcdDur;
      }
    }

    // Record ability used
    final stats = actorId == 'challenger' ? manager.challengerStats : manager.enemyStats;
    stats.abilitiesUsed[ability.name] = (stats.abilitiesUsed[ability.name] ?? 0) + 1;
    manager.recordEvent(DuelEvent(
      timeSeconds: manager.elapsedSeconds,
      type: 'ability_used',
      actorId: actorId,
      value: 0,
      detail: ability.name,
    ));

    // ── Apply heal or damage ──────────────────────────────────────────────────
    if (ability.type == AbilityType.heal) {
      final heal = ability.healAmount;
      if (heal > 0) {
        // Support strategy: heal lowest-HP alive ally; others always self-heal.
        // Reason: single-pass scan replaces .where().reduce() iterable wrapper.
        Ally healTarget = self;
        if (strategy == DuelStrategy.support && ownParty.length > 1) {
          for (final a in ownParty) {
            if (a.health <= 0) continue;
            if (a.health < healTarget.health) healTarget = a;
          }
        }
        healTarget.health = (healTarget.health + heal).clamp(0, healTarget.maxHealth);
        manager.recordEvent(DuelEvent(
          timeSeconds: manager.elapsedSeconds,
          type: 'heal',
          actorId: actorId,
          value: heal,
          detail: ability.name,
        ));
      }
    } else if (ability.damage > 0) {
      final dmg = ability.damage * gearDamageMult;
      target.health = (target.health - dmg).clamp(0, target.maxHealth);
      manager.recordEvent(DuelEvent(
        timeSeconds: manager.elapsedSeconds,
        type: 'damage',
        actorId: actorId,
        value: dmg,
        detail: ability.name,
      ));
      if (target.health <= 0) {
        manager.recordEvent(DuelEvent(
          timeSeconds: manager.elapsedSeconds,
          type: 'death',
          actorId: actorId == 'challenger' ? 'enemy' : 'challenger',
          value: 0,
          detail: '${target.name} defeated',
        ));
      }
    }
  }

  // ==================== STRATEGY HELPERS ====================

  /// Preferred engagement distance by strategy.
  static double _preferredDistance(DuelStrategy strategy) {
    switch (strategy) {
      case DuelStrategy.berserker:   return 1.5;
      case DuelStrategy.aggressive:  return 2.5;
      case DuelStrategy.balanced:    return 2.5;
      case DuelStrategy.defensive:   return 6.0;
      case DuelStrategy.support:     return 7.0;
    }
  }

  /// Scoring function: higher = use this ability sooner.
  /// Reason: strategy priority shapes decision-making without expensive tree evaluation.
  static int _abilityPriority(AbilityData ability, DuelStrategy strategy, Ally self) {
    final hpFraction = self.maxHealth > 0 ? self.health / self.maxHealth : 1.0;
    switch (strategy) {
      case DuelStrategy.aggressive:
        // Heals only when critical; otherwise maximum damage output
        if (ability.type == AbilityType.heal) return hpFraction < 0.2 ? 60 : -1;
        return ability.damage.round();
      case DuelStrategy.berserker:
        // Never heal; pure damage at all costs
        if (ability.type == AbilityType.heal) return -1;
        return ability.damage.round() + 100;
      case DuelStrategy.defensive:
        // Heal aggressively when below 50 %; otherwise use any damage ability
        if (ability.type == AbilityType.heal) return hpFraction < 0.5 ? 120 : 20;
        return 30;
      case DuelStrategy.support:
        // Heal very early; low damage priority
        if (ability.type == AbilityType.heal) return hpFraction < 0.75 ? 120 : 50;
        return 10;
      case DuelStrategy.balanced:
        return 50; // Unused: balanced uses greedy order selection
    }
  }

  // ==================== ABILITY HELPERS ====================

  static bool _abilityReady(Ally ally, AbilityData ability, int index) {
    if (index >= ally.abilityCooldowns.length) return false;
    if (ally.abilityCooldowns[index] > 0) return false;
    return _canAffordMana(ally, ability);
  }

  static void _regenMana(double dt, Ally ally) {
    final rate = globalDuelConfig?.manaRegenPerSecond ?? 5.0;
    ally.blueMana  = (ally.blueMana  + rate * dt).clamp(0, ally.maxBlueMana);
    ally.redMana   = (ally.redMana   + rate * dt).clamp(0, ally.maxRedMana);
    ally.whiteMana = (ally.whiteMana + rate * dt).clamp(0, ally.maxWhiteMana);
    ally.greenMana = (ally.greenMana + rate * dt).clamp(0, ally.maxGreenMana);
    ally.blackMana = (ally.blackMana + rate * dt).clamp(0, ally.maxBlackMana);
  }

  static void _tickCooldowns(double dt, Ally ally, int count) {
    for (int i = 0; i < count && i < ally.abilityCooldowns.length; i++) {
      if (ally.abilityCooldowns[i] > 0) {
        ally.abilityCooldowns[i] = (ally.abilityCooldowns[i] - dt).clamp(0, double.infinity);
      }
    }
  }

  static bool _canAffordMana(Ally ally, AbilityData ability) {
    if (ability.manaColor == ManaColor.none || ability.manaCost <= 0) return true;
    if (_manaPool(ally, ability.manaColor) < ability.manaCost) return false;
    if (ability.secondaryManaColor != ManaColor.none && ability.secondaryManaCost > 0) {
      return _manaPool(ally, ability.secondaryManaColor) >= ability.secondaryManaCost;
    }
    return true;
  }

  static void _deductMana(Ally ally, AbilityData ability) {
    if (ability.manaColor != ManaColor.none && ability.manaCost > 0) {
      _setManaPool(ally, ability.manaColor,
          _manaPool(ally, ability.manaColor) - ability.manaCost);
    }
    if (ability.secondaryManaColor != ManaColor.none && ability.secondaryManaCost > 0) {
      _setManaPool(ally, ability.secondaryManaColor,
          _manaPool(ally, ability.secondaryManaColor) - ability.secondaryManaCost);
    }
  }

  static double _manaPool(Ally ally, ManaColor color) {
    switch (color) {
      case ManaColor.blue:  return ally.blueMana;
      case ManaColor.red:   return ally.redMana;
      case ManaColor.white: return ally.whiteMana;
      case ManaColor.green: return ally.greenMana;
      case ManaColor.black: return ally.blackMana;
      case ManaColor.none:  return double.infinity;
    }
  }

  static void _setManaPool(Ally ally, ManaColor color, double value) {
    switch (color) {
      case ManaColor.blue:  ally.blueMana  = value.clamp(0, ally.maxBlueMana);  break;
      case ManaColor.red:   ally.redMana   = value.clamp(0, ally.maxRedMana);   break;
      case ManaColor.white: ally.whiteMana = value.clamp(0, ally.maxWhiteMana); break;
      case ManaColor.green: ally.greenMana = value.clamp(0, ally.maxGreenMana); break;
      case ManaColor.black: ally.blackMana = value.clamp(0, ally.maxBlackMana); break;
      case ManaColor.none:  break;
    }
  }
}
