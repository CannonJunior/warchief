import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import '../state/game_state.dart';
import '../state/duel_manager.dart';
import '../state/duel_config.dart';
import '../data/abilities/ability_types.dart';
import '../../models/ally.dart';
import '../../models/duel_result.dart';
import '../../models/projectile.dart';
import '../../models/impact_effect.dart';
import '../ui/damage_indicators.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../ai/ollama_client.dart';

part 'duel_ai_helpers.dart';

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

  /// In-flight projectile entries awaiting collision with a duel target.
  /// Reason: isolated from gameState.fireballs so clearing on duel reset is trivial.
  static final List<_DuelProj> _inFlight = [];

  /// Shared Ollama client for periodic strategy queries (fire-and-forget async).
  static final OllamaClient _ollamaClient = OllamaClient();

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

    // Snap combatants to terrain surface (AI moves XZ only; Y drifts without this).
    final terrMgr = gameState.infiniteTerrainManager;
    for (final c in gameState.duelCombatants) {
      if (c.health <= 0) continue;
      c.transform.position.y = (terrMgr?.getTerrainHeight(
          c.transform.position.x, c.transform.position.z) ?? gameState.groundLevel) + 0.55;
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

    // Advance in-flight duel projectiles and resolve collisions.
    _tickProjectiles(dt, manager, gameState);

    // Periodically query Ollama for challenger strategy advice.
    _tickOllamaAdvisor(dt, manager, challengers, enemies);

    // Run AI for every alive challenger
    for (int i = 0; i < chalSize; i++) {
      if (challengers[i].health <= 0) continue;
      final abilities = i < manager.challengerPartyAbilities.length
          ? manager.challengerPartyAbilities[i] : <AbilityData>[];
      final gearDmgMult = i < manager.challengerDamageMults.length
          ? manager.challengerDamageMults[i] : 1.0;
      // Reason: GCD index = combatant's position in the flat combatantGcds list.
      _runAI(dt, challengers[i], enemies, challengers,
          'challenger', abilities, manager, manager.challengerStrategy, gearDmgMult, i, gameState);
    }

    // Run AI for every alive enemy
    for (int i = 0; i < enemySize; i++) {
      if (enemies[i].health <= 0) continue;
      final abilities = i < manager.enemyPartyAbilities.length
          ? manager.enemyPartyAbilities[i] : <AbilityData>[];
      final gearDmgMult = i < manager.enemyDamageMults.length
          ? manager.enemyDamageMults[i] : 1.0;
      _runAI(dt, enemies[i], challengers, enemies,
          'enemy', abilities, manager, manager.enemyStrategy, gearDmgMult, chalSize + i, gameState);
    }

    // ── Win / draw check ──────────────────────────────────────────────────────
    // Reason: firstKill ends on ANY death; totalAnnihilation ends when ALL of
    // one side is dead.  Winner logic is identical — just the threshold differs.
    final maxDur    = globalDuelConfig?.maxDurationSeconds ?? 120.0;
    final timedOut  = manager.elapsedSeconds >= maxDur;
    final firstKill = manager.endCondition == DuelEndCondition.firstKill;
    // Reason: replace any()/every() closures with a single integer count pass
    // per side — avoids 4 closure allocations per frame during active duels.
    int chalAlive = 0, enemyAlive = 0;
    for (int i = 0; i < chalSize; i++) { if (challengers[i].health > 0) chalAlive++; }
    for (int i = 0; i < enemySize; i++) { if (enemies[i].health > 0) enemyAlive++; }
    final chalDead  = firstKill ? chalAlive  < chalSize  : chalAlive  == 0;
    final enemyDead = firstKill ? enemyAlive < enemySize : enemyAlive == 0;

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
      // Reason: sum of party max HPs stored so the detail view can reconstruct
      // the health-over-time chart purely from recorded damage/heal events.
      final chalMaxHp  = challengers.fold(0.0, (s, c) => s + c.maxHealth);
      final enemMaxHp  = enemies.fold(0.0, (s, e) => s + e.maxHealth);
      manager.finalizeDuel(winnerId, manager.elapsedSeconds,
          challengerMaxHp: chalMaxHp, enemyMaxHp: enemMaxHp);
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

  /// Remove all in-flight duel projectiles (call on duel start/cancel).
  static void clearProjectiles(GameState gameState) {
    _inFlight.clear();
    gameState.duelProjectiles.clear();
  }

  // ==================== GCD TICK ====================

  /// Decrement per-combatant GCD, combo-window, and CC timers each frame.
  static void _tickGcds(double dt, DuelManager manager) {
    // Reason: all five parallel timer lists share the same flat combatant
    // index scheme and are always the same length (set at duel start).
    // A single loop improves cache locality over five separate passes.
    final n = manager.combatantGcds.length;
    for (int i = 0; i < n; i++) {
      if (manager.combatantGcds[i] > 0) {
        manager.combatantGcds[i] =
            (manager.combatantGcds[i] - dt).clamp(0.0, double.infinity);
      }
      if (manager.combatantComboWindows[i] > 0) {
        manager.combatantComboWindows[i] =
            (manager.combatantComboWindows[i] - dt).clamp(0.0, double.infinity);
      }
      // Hard CC (stun / root / fear / silence).
      if (manager.combatantCcRemaining[i] > 0) {
        manager.combatantCcRemaining[i] =
            (manager.combatantCcRemaining[i] - dt).clamp(0.0, double.infinity);
      }
      // Slow: restore factor to 1.0 when duration expires.
      if (manager.combatantSlowRemaining[i] > 0) {
        manager.combatantSlowRemaining[i] =
            (manager.combatantSlowRemaining[i] - dt).clamp(0.0, double.infinity);
        if (manager.combatantSlowRemaining[i] <= 0) {
          manager.combatantSlowFactor[i] = 1.0;
        }
      }
      // Interrupt spell-lockout.
      if (manager.combatantInterruptLockout[i] > 0) {
        manager.combatantInterruptLockout[i] =
            (manager.combatantInterruptLockout[i] - dt).clamp(0.0, double.infinity);
      }
    }
  }

  // ==================== PROJECTILE TICK ====================

  /// Move in-flight duel projectiles; apply damage + visual feedback on hit.
  static void _tickProjectiles(double dt, DuelManager mgr, GameState gs) {
    if (_inFlight.isEmpty) return;
    _inFlight.removeWhere((dp) {
      dp.p.lifetime -= dt;
      final tx = dp.target.transform.position.x - dp.p.transform.position.x;
      final tz = dp.target.transform.position.z - dp.p.transform.position.z;
      final dist = math.sqrt(tx * tx + tz * tz);
      final hit = dist < 0.9 && dp.target.health > 0;
      if (hit) {
        final dmg = dp.p.damage * dp.gearMult;
        dp.target.health = (dp.target.health - dmg).clamp(0, dp.target.maxHealth);
        final stats = dp.actorId == 'challenger' ? mgr.challengerStats : mgr.enemyStats;
        stats.perAbilityDamage[dp.p.abilityName] =
            (stats.perAbilityDamage[dp.p.abilityName] ?? 0) + dmg;
        mgr.recordEvent(DuelEvent(timeSeconds: mgr.elapsedSeconds,
            type: 'damage', actorId: dp.actorId, value: dmg, detail: dp.p.abilityName,
            targetIndex: dp.targetIndex));
        if (dp.target.health <= 0) {
          // Track killing blow and victim death for the richer stats model.
          final killerStats = dp.actorId == 'challenger' ? mgr.challengerStats : mgr.enemyStats;
          final victimStats = dp.actorId == 'challenger' ? mgr.enemyStats : mgr.challengerStats;
          killerStats.killingBlows++;
          killerStats.killingBlowsByAbility[dp.p.abilityName] =
              (killerStats.killingBlowsByAbility[dp.p.abilityName] ?? 0) + 1;
          victimStats.deaths++;
          mgr.recordEvent(DuelEvent(timeSeconds: mgr.elapsedSeconds, type: 'death',
              actorId: dp.actorId == 'challenger' ? 'enemy' : 'challenger',
              value: 0, detail: '${dp.target.name} defeated'));
        }
        gs.damageIndicators.add(DamageIndicator(damage: dmg,
            worldPosition: dp.target.transform.position.clone(),
            isKillingBlow: dp.target.health <= 0));
        gs.impactEffects.add(ImpactEffect(
            mesh: Mesh.cube(size: dp.p.impactSize, color: dp.p.impactColor),
            transform: Transform3d(position: dp.target.transform.position.clone(),
                scale: Vector3(1, 1, 1)), lifetime: 0.4));
      } else if (dp.p.lifetime > 0 && dist > 0.01) {
        final spd = dp.p.speed * dt;
        dp.p.transform.position.x += (tx / dist) * spd;
        dp.p.transform.position.z += (tz / dist) * spd;
      }
      if (hit || dp.p.lifetime <= 0) gs.duelProjectiles.remove(dp.p);
      return hit || dp.p.lifetime <= 0;
    });
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
    GameState gameState,
  ) {
    if (self.health <= 0) return;
    // Hard CC (stun / root / fear / silence / blind): cannot move or cast.
    if (manager.isCced(combatantIdx)) return;
    // ── Target selection: weakest alive enemy (single-pass, tracks index) ─────
    // Reason: track targetIdx here so we never need enemies.indexOf(target) later.
    Ally? target;
    int   targetIdx = -1;
    for (int ti = 0; ti < enemies.length; ti++) {
      final e = enemies[ti];
      if (e.health <= 0) continue;
      if (target == null || e.health < target.health) { target = e; targetIdx = ti; }
    }
    if (target == null) return;

    // ── Nearest physical threat for kiting / peel decisions ──────────────────
    // Reason: kiting retreats from the physically closest enemy, not just the
    // chosen damage target, so healers/ranged correctly escape melee divers.
    Ally? nearestThreat;
    double nearestThreatDist = double.infinity;
    for (final e in enemies) {
      if (e.health <= 0) continue;
      final ex = e.transform.position.x - self.transform.position.x;
      final ez = e.transform.position.z - self.transform.position.z;
      final d  = math.sqrt(ex * ex + ez * ez);
      if (d < nearestThreatDist) { nearestThreatDist = d; nearestThreat = e; }
    }

    // ── Movement: role-aware via helper (kite / approach / strafe) ───────────
    _handleMovement(dt, self, target, nearestThreat, nearestThreatDist,
        abilities, strategy, combatantIdx, manager.slowFactorFor(combatantIdx));

    // Reason: Ollama LLM hint overrides base strategy for the challenger side,
    // allowing the advisory model to shift posture mid-fight based on HP state.
    final effectiveStrategy = actorId == 'challenger'
        ? _applyOllamaHint(manager.ollamaStrategyHint, strategy)
        : strategy;

    // Reason: combo primers bypass GCD and open a window for follow-up abilities.
    final gcdActive     = combatantIdx < manager.combatantGcds.length && manager.combatantGcds[combatantIdx] > 0;
    final inComboWindow = combatantIdx < manager.combatantComboWindows.length && manager.combatantComboWindows[combatantIdx] > 0;
    // ── Ability selection ─────────────────────────────────────────────────────
    int? chosenIdx;
    // Reason: interrupt lockout prevents casting spell-type abilities (ranged /
    // channeled / heal) but leaves physical strikes available — simulates a
    // successful kick/counterspell that disrupts magical concentration.
    final interrupted = manager.isInterrupted(combatantIdx);

    if (effectiveStrategy == DuelStrategy.balanced) {
      // Greedy: first usable ability in list order (original behaviour)
      for (int i = 0; i < abilities.length; i++) {
        if (!_abilityReady(self, abilities[i], i)) continue;
        // Skip non-exempt abilities while GCD is active
        if (gcdActive && !abilities[i].enablesComboChain && !inComboWindow) continue;
        // Skip spell-type abilities while interrupt-locked
        if (interrupted && _isSpellAbility(abilities[i])) continue;
        chosenIdx = i;
        break;
      }
    } else {
      // Priority-scored: highest-scoring usable ability wins
      int bestScore = -1;
      for (int i = 0; i < abilities.length; i++) {
        if (!_abilityReady(self, abilities[i], i)) continue;
        if (gcdActive && !abilities[i].enablesComboChain && !inComboWindow) continue;
        if (interrupted && _isSpellAbility(abilities[i])) continue;
        final score = _abilityPriority(abilities[i], effectiveStrategy, self);
        if (score > bestScore) {
          bestScore = score;
          chosenIdx = i;
        }
      }
    }

    if (chosenIdx == null) return;

    // ── Peel override: redirect CC at enemies diving vulnerable allies ─────────
    // Reason: sturdy combatants sacrifice their normal rotation to protect
    // healers and ranged who cannot survive being dived in melee.
    if (!_isVulnerableCombatant(abilities)) {
      final ownAbilityLists = actorId == 'challenger'
          ? manager.challengerPartyAbilities : manager.enemyPartyAbilities;
      final peel = _findPeelTarget(self, ownParty, ownAbilityLists, enemies, abilities);
      if (peel != null) {
        target    = peel.enemy;
        targetIdx = peel.enemyIdx;
        chosenIdx = peel.abilityIdx;
      }
    }

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
    // Track CC / interrupt / debuff / utility casts for the stats model.
    // Reason: _isCcAbility covers stun/root/slow/blind/fear/silence; debuff/utility/buff
    // types cover non-status-effect support abilities (buffs, purges, movement tools).
    if (_isCcAbility(ability) ||
        ability.type == AbilityType.debuff ||
        ability.type == AbilityType.utility ||
        ability.type == AbilityType.buff) {
      stats.ccAndUtilityCasts++;
    }
    manager.recordEvent(DuelEvent(timeSeconds: manager.elapsedSeconds,
        type: 'ability_used', actorId: actorId, value: 0, detail: ability.name));

    // ── Apply heal or damage ──────────────────────────────────────────────────
    if (ability.type == AbilityType.heal) {
      final heal = ability.healAmount;
      if (heal > 0) {
        // Support: heal lowest-HP ally (single-pass scan).
        Ally healTarget = self;
        if (strategy == DuelStrategy.support && ownParty.length > 1) {
          for (final a in ownParty) {
            if (a.health <= 0) continue;
            if (a.health < healTarget.health) healTarget = a;
          }
        }
        healTarget.health = (healTarget.health + heal).clamp(0, healTarget.maxHealth);
        stats.perAbilityHealing[ability.name] =
            (stats.perAbilityHealing[ability.name] ?? 0) + heal;
        manager.recordEvent(DuelEvent(timeSeconds: manager.elapsedSeconds,
            type: 'heal', actorId: actorId, value: heal, detail: ability.name,
            targetIndex: ownParty.indexOf(healTarget)));
        gameState.damageIndicators.add(DamageIndicator(damage: heal,
            worldPosition: healTarget.transform.position.clone(), isHeal: true));
      }
    } else if (ability.damage > 0) {
      // Ranged: launch a flying projectile.  Melee: apply damage instantly.
      if (ability.projectileSpeed > 0 || ability.type == AbilityType.ranged) {
        final tdx = target.transform.position.x - self.transform.position.x;
        final tdz = target.transform.position.z - self.transform.position.z;
        final tlen = math.sqrt(tdx * tdx + tdz * tdz);
        final dir = tlen > 0.01 ? Vector3(tdx / tlen, 0, tdz / tlen) : Vector3(1, 0, 0);
        final spd = ability.projectileSpeed > 0 ? ability.projectileSpeed : 10.0;
        final startPos = Vector3(self.transform.position.x + dir.x,
            self.transform.position.y, self.transform.position.z + dir.z);
        final proj = Projectile(
          mesh: Mesh.cube(
              size: ability.projectileSize > 0 ? ability.projectileSize : 0.3,
              color: ability.color),
          transform: Transform3d(position: startPos, scale: Vector3(1, 1, 1)),
          velocity: dir * spd, speed: spd,
          damage: ability.damage, abilityName: ability.name,
          impactColor: ability.impactColor,
          impactSize: ability.impactSize > 0 ? ability.impactSize : 0.4,
        );
        _inFlight.add(_DuelProj(proj, target, actorId, gearDamageMult, targetIdx));
        gameState.duelProjectiles.add(proj);
      } else {
        // Instant melee damage with floating number feedback
        final dmg = ability.damage * gearDamageMult;
        target.health = (target.health - dmg).clamp(0, target.maxHealth);
        stats.perAbilityDamage[ability.name] =
            (stats.perAbilityDamage[ability.name] ?? 0) + dmg;
        manager.recordEvent(DuelEvent(timeSeconds: manager.elapsedSeconds,
            type: 'damage', actorId: actorId, value: dmg, detail: ability.name,
            targetIndex: targetIdx));
        if (target.health <= 0) {
          stats.killingBlows++;
          stats.killingBlowsByAbility[ability.name] =
              (stats.killingBlowsByAbility[ability.name] ?? 0) + 1;
          final victimStats = actorId == 'challenger' ? manager.enemyStats : manager.challengerStats;
          victimStats.deaths++;
          manager.recordEvent(DuelEvent(timeSeconds: manager.elapsedSeconds,
              type: 'death', actorId: actorId == 'challenger' ? 'enemy' : 'challenger',
              value: 0, detail: '${target.name} defeated'));
        }
        gameState.damageIndicators.add(DamageIndicator(damage: dmg,
            worldPosition: target.transform.position.clone(),
            isMelee: true, isKillingBlow: target.health <= 0));
      }
    }

    // ── Apply status effect (CC / slow) to the damage target ─────────────────
    // Reason: both regular attacks and peel-redirected abilities can carry CC;
    // applying here covers both cases without duplicating logic in each branch.
    if (ability.type != AbilityType.heal &&
        ability.statusEffect != StatusEffect.none &&
        (ability.statusDuration > 0 || ability.statusStrength > 0)) {
      if (targetIdx >= 0) {
        final tIdx = targetIdx;
        // Reason: flat index maps challengers (0..chalSize-1) then enemies
        // (chalSize..total-1) — matches the layout set up in _startDuel.
        final flatIdx = actorId == 'challenger'
            ? manager.challengerPartySize + tIdx : tIdx;
        switch (ability.statusEffect) {
          case StatusEffect.stun:
          case StatusEffect.root:
          case StatusEffect.fear:
          case StatusEffect.silence:
          case StatusEffect.blind:
            manager.applyCc(flatIdx, ability.statusDuration);
            break;
          case StatusEffect.slow:
          case StatusEffect.freeze:
            final factor = ability.statusStrength > 0
                ? (1.0 - ability.statusStrength) : 0.5;
            manager.applySlow(flatIdx, ability.statusDuration, factor);
            break;
          case StatusEffect.interrupt:
            // Reason: use config lockout duration so it's tunable without
            // recompiling; ability.statusDuration serves as a fallback default.
            final lockout = globalDuelConfig?.interruptLockoutSeconds
                ?? ability.statusDuration;
            manager.applyInterrupt(flatIdx, lockout);
            manager.recordEvent(DuelEvent(timeSeconds: manager.elapsedSeconds,
                type: 'status', actorId: actorId, value: lockout,
                detail: 'interrupted:${ability.name}'));
            break;
          default:
            break;
        }
      }
    }
  }

  // ==================== OLLAMA STRATEGY ADVISOR ====================

  static void _tickOllamaAdvisor(double dt, DuelManager mgr,
      List<Ally> challengers, List<Ally> enemies) =>
      _duelTickAdvisor(dt, mgr, challengers, enemies);

}
