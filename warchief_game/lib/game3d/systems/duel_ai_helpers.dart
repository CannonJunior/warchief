part of 'duel_system.dart';

// ── Role detection + effective range ─────────────────────────────────────────

/// Preferred engagement distance, factoring in both strategy and ability type.
///
/// Ranged combatants prefer ~80 % of their longest ranged ability's range so
/// they remain clearly within firing distance without over-committing.
/// The strategy base is used as a floor so Support ranged units don't creep in.
double _effectiveRange(List<AbilityData> abilities, DuelStrategy strategy) {
  final base = _preferredDistance(strategy);
  // Reason: single pass accumulates both the ranged count and max range to
  // avoid calling _isRangedCombatant (a second full pass) separately.
  int rangedCount = 0;
  double maxRange = 0;
  for (final a in abilities) {
    if (a.projectileSpeed > 0 || a.type == AbilityType.ranged) {
      rangedCount++;
      if (a.range > maxRange) maxRange = a.range;
    }
  }
  if (rangedCount * 2 <= abilities.length) return base;
  return maxRange > 0 ? math.max(base, maxRange * 0.8) : math.max(base, 8.0);
}

/// Map an Ollama text hint to a DuelStrategy override, falling back to [base].
DuelStrategy _applyOllamaHint(String? hint, DuelStrategy base) {
  switch (hint) {
    case 'aggressive': return DuelStrategy.aggressive;
    case 'defensive':  return DuelStrategy.defensive;
    case 'balanced':   return DuelStrategy.balanced;
    default:           return base;
  }
}

/// True when this combatant is primarily a healer or a ranged DPS —
/// these are "vulnerable" and should kite away from attackers while
/// teammates attempt to peel off enemies that dive them.
bool _isVulnerableCombatant(List<AbilityData> abilities) {
  if (abilities.isEmpty) return false;
  // Reason: single pass counts both healer and ranged abilities, avoiding the
  // extra full traversal that _isRangedCombatant would add as a second pass.
  int healCount = 0, rangedCount = 0;
  for (final a in abilities) {
    if (a.type == AbilityType.heal || a.healAmount > 0) healCount++;
    if (a.projectileSpeed > 0 || a.type == AbilityType.ranged) rangedCount++;
  }
  return healCount * 2 > abilities.length || rangedCount * 2 > abilities.length;
}

/// True when [a] is a spell-type ability that can be stopped by an interrupt.
///
/// Spells require magical concentration: ranged projectiles, channeled casts,
/// heal casts, or any ability with a cast time. Physical strikes are never spells.
bool _isSpellAbility(AbilityData a) =>
    a.type == AbilityType.ranged   ||
    a.type == AbilityType.channeled ||
    a.type == AbilityType.heal     ||
    a.castTime > 0;

/// True when [a] carries a meaningful crowd-control effect that can slow,
/// stop, or interrupt an attacker.
bool _isCcAbility(AbilityData a) {
  switch (a.statusEffect) {
    case StatusEffect.stun:
    case StatusEffect.root:
    case StatusEffect.slow:
    case StatusEffect.blind:
    case StatusEffect.fear:
    case StatusEffect.silence:
    case StatusEffect.interrupt:
      return a.statusDuration > 0 || a.statusStrength > 0;
    default:
      return false;
  }
}

/// Priority score for CC selection — higher means use first.
/// Reason: hard CCs (stun/root) completely halt an attacker and are more
/// valuable for protecting a vulnerable ally than soft CCs (slow).
int _ccPriority(AbilityData a) {
  switch (a.statusEffect) {
    case StatusEffect.stun:      return 100;
    case StatusEffect.silence:   return 95;
    case StatusEffect.root:      return 90;
    case StatusEffect.fear:      return 80;
    case StatusEffect.interrupt: return 75;
    case StatusEffect.blind:     return 70;
    case StatusEffect.slow:      return 60;
    default:                     return 0;
  }
}

/// Carries the result of a peel decision: which enemy to CC and which
/// ability index (within the peeling combatant's ability list) to fire.
class _PeelDecision {
  final Ally   enemy;
  final int    abilityIdx;
  /// 0-based index of [enemy] within the opposing party list.
  final int    enemyIdx;
  _PeelDecision(this.enemy, this.abilityIdx, this.enemyIdx);
}

/// Scan [ownParty] for vulnerable allies that are under immediate threat.
///
/// Returns a [_PeelDecision] when a sturdy combatant ([self]) should redirect
/// a CC ability onto an enemy that is diving a healer or ranged ally.
///
/// Returns null when:
///   - no vulnerable ally exists in [ownParty] (besides self)
///   - no enemy is within [peelTriggerRange] of a vulnerable ally
///   - [self] has no ready CC ability in range of the threat
_PeelDecision? _findPeelTarget(
  Ally self,
  List<Ally> ownParty,
  List<List<AbilityData>> ownPartyAbilities,
  List<Ally> enemies,
  List<AbilityData> selfAbilities,
) {
  final peelRange = globalDuelConfig?.peelTriggerRange ?? 5.0;

  for (int pi = 0; pi < ownParty.length; pi++) {
    final ally = ownParty[pi];
    if (ally.health <= 0 || identical(ally, self)) continue;
    final allyAbils = pi < ownPartyAbilities.length
        ? ownPartyAbilities[pi] : <AbilityData>[];
    if (!_isVulnerableCombatant(allyAbils)) continue;

    // Find the enemy physically closest to this vulnerable ally.
    // Reason: track index here so _PeelDecision can return it without a later indexOf.
    Ally? threat;
    int   threatIdx  = -1;
    double threatDist = double.infinity;
    for (int ei = 0; ei < enemies.length; ei++) {
      final e = enemies[ei];
      if (e.health <= 0) continue;
      final ex = e.transform.position.x - ally.transform.position.x;
      final ez = e.transform.position.z - ally.transform.position.z;
      final d  = math.sqrt(ex * ex + ez * ez);
      if (d < threatDist) { threatDist = d; threat = e; threatIdx = ei; }
    }
    if (threat == null || threatDist > peelRange) continue;

    // Distance from self to the threat (needed for melee CC range check).
    final sx = threat.transform.position.x - self.transform.position.x;
    final sz = threat.transform.position.z - self.transform.position.z;
    final selfToThreat = math.sqrt(sx * sx + sz * sz);

    // Choose the highest-priority ready CC ability that can reach the threat.
    int bestIdx   = -1;
    int bestScore = -1;
    for (int ai = 0; ai < selfAbilities.length; ai++) {
      final a = selfAbilities[ai];
      if (!_abilityReady(self, a, ai)) continue;
      if (!_isCcAbility(a)) continue;
      // Ranged / debuff CC can reach any distance; melee CC needs proximity.
      final isRangedCc = a.projectileSpeed > 0 ||
          a.type == AbilityType.ranged || a.type == AbilityType.debuff;
      final maxReach = a.range > 0 ? a.range + 1.0 : 3.0;
      if (!isRangedCc && selfToThreat > maxReach) continue;
      final score = _ccPriority(a);
      if (score > bestScore) { bestScore = score; bestIdx = ai; }
    }
    if (bestIdx >= 0) return _PeelDecision(threat, bestIdx, threatIdx);
  }
  return null;
}

/// Role-aware movement for a single combatant each frame.
///
/// Priority (highest to lowest):
///   1. Vulnerable combatant under immediate threat → kite away from threat
///      with a lateral strafe blend so the path isn't predictable
///   2. Too far from target → close in at full speed
///   3. Defensive melee too close → gentle separation
///   4. At preferred range → lateral strafe to avoid being a stationary target
void _handleMovement(
  double dt,
  Ally self,
  Ally target,
  Ally? nearestThreat,
  double nearestThreatDist,
  List<AbilityData> abilities,
  DuelStrategy strategy,
  int combatantIdx,
  double slowFactor,
) {
  final dx   = target.transform.position.x - self.transform.position.x;
  final dz   = target.transform.position.z - self.transform.position.z;
  final dist = math.sqrt(dx * dx + dz * dz);

  final isVulnerable = _isVulnerableCombatant(abilities);
  final preferred    = _effectiveRange(abilities, strategy);
  // Reason: vulnerable combatants start retreating at 70 % of preferred range
  // (configurable) versus 45 % for melee, giving healers and ranged more time
  // to escape before an attacker reaches melee distance.
  final kiteThreshold = isVulnerable
      ? preferred * (globalDuelConfig?.kiteThresholdMultiplier ?? 0.7)
      : preferred * 0.45;
  // Apply slow multiplier from CC system.
  final spd = self.moveSpeed * slowFactor;

  if (nearestThreat != null && nearestThreatDist < kiteThreshold && isVulnerable) {
    // Threat-aware kite: retreat from whichever enemy is physically closest,
    // not necessarily the current damage target.
    final tx   = nearestThreat.transform.position.x - self.transform.position.x;
    final tz   = nearestThreat.transform.position.z - self.transform.position.z;
    final tlen = math.sqrt(tx * tx + tz * tz);
    if (tlen > 0.01) {
      // Blend retreat vector with 25 % lateral strafe so the kite path
      // curves and is harder for the attacker to intercept directly.
      final backX   = -(tx / tlen);
      final backZ   = -(tz / tlen);
      final strafeX = -tz / tlen;
      final strafeZ =  tx / tlen;
      final side    = (combatantIdx % 2 == 0) ? 1.0 : -1.0;
      self.transform.position.x += (backX + strafeX * side * 0.25) * spd * dt;
      self.transform.position.z += (backZ + strafeZ * side * 0.25) * spd * dt;
    }
  } else if (dist > preferred + 0.5) {
    self.transform.position.x += (dx / dist) * spd * dt;
    self.transform.position.z += (dz / dist) * spd * dt;
  } else if (!isVulnerable && strategy == DuelStrategy.defensive
             && dist < preferred - 1.5 && dist > 0.01) {
    self.transform.position.x -= (dx / dist) * spd * 0.5 * dt;
    self.transform.position.z -= (dz / dist) * spd * 0.5 * dt;
  } else if (dist > 0.01) {
    final strafeX = -dz / dist;
    final strafeZ =  dx / dist;
    final side    = (combatantIdx % 2 == 0) ? 1.0 : -1.0;
    self.transform.position.x += strafeX * side * spd * 0.35 * dt;
    self.transform.position.z += strafeZ * side * spd * 0.35 * dt;
  }
}

// ── Strategy helpers ──────────────────────────────────────────────────────────

/// Base preferred engagement distance by strategy (role-agnostic floor).
double _preferredDistance(DuelStrategy strategy) {
  switch (strategy) {
    case DuelStrategy.berserker:   return 1.5;
    case DuelStrategy.aggressive:  return 2.5;
    case DuelStrategy.balanced:    return 2.5;
    case DuelStrategy.defensive:   return 6.0;
    case DuelStrategy.support:     return 7.0;
  }
}

/// Priority score for ability selection (higher = use sooner).
/// Reason: strategy priority shapes decision-making without expensive tree evaluation.
int _abilityPriority(AbilityData ability, DuelStrategy strategy, Ally self) {
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

// ── Ability helpers ───────────────────────────────────────────────────────────

bool _abilityReady(Ally ally, AbilityData ability, int index) {
  if (index >= ally.abilityCooldowns.length) return false;
  if (ally.abilityCooldowns[index] > 0) return false;
  return _canAffordMana(ally, ability);
}

void _regenMana(double dt, Ally ally) {
  final rate = globalDuelConfig?.manaRegenPerSecond ?? 5.0;
  ally.blueMana  = (ally.blueMana  + rate * dt).clamp(0, ally.maxBlueMana);
  ally.redMana   = (ally.redMana   + rate * dt).clamp(0, ally.maxRedMana);
  ally.whiteMana = (ally.whiteMana + rate * dt).clamp(0, ally.maxWhiteMana);
  ally.greenMana = (ally.greenMana + rate * dt).clamp(0, ally.maxGreenMana);
  ally.blackMana = (ally.blackMana + rate * dt).clamp(0, ally.maxBlackMana);
}

void _tickCooldowns(double dt, Ally ally, int count) {
  for (int i = 0; i < count && i < ally.abilityCooldowns.length; i++) {
    if (ally.abilityCooldowns[i] > 0) {
      ally.abilityCooldowns[i] = (ally.abilityCooldowns[i] - dt).clamp(0, double.infinity);
    }
  }
}

bool _canAffordMana(Ally ally, AbilityData ability) {
  if (ability.manaColor == ManaColor.none || ability.manaCost <= 0) return true;
  if (_manaPool(ally, ability.manaColor) < ability.manaCost) return false;
  if (ability.secondaryManaColor != ManaColor.none && ability.secondaryManaCost > 0) {
    return _manaPool(ally, ability.secondaryManaColor) >= ability.secondaryManaCost;
  }
  return true;
}

void _deductMana(Ally ally, AbilityData ability) {
  if (ability.manaColor != ManaColor.none && ability.manaCost > 0) {
    _setManaPool(ally, ability.manaColor,
        _manaPool(ally, ability.manaColor) - ability.manaCost);
  }
  if (ability.secondaryManaColor != ManaColor.none && ability.secondaryManaCost > 0) {
    _setManaPool(ally, ability.secondaryManaColor,
        _manaPool(ally, ability.secondaryManaColor) - ability.secondaryManaCost);
  }
}

double _manaPool(Ally ally, ManaColor color) {
  switch (color) {
    case ManaColor.blue:  return ally.blueMana;
    case ManaColor.red:   return ally.redMana;
    case ManaColor.white: return ally.whiteMana;
    case ManaColor.green: return ally.greenMana;
    case ManaColor.black: return ally.blackMana;
    case ManaColor.none:  return double.infinity;
  }
}

void _setManaPool(Ally ally, ManaColor color, double value) {
  switch (color) {
    case ManaColor.blue:  ally.blueMana  = value.clamp(0, ally.maxBlueMana);  break;
    case ManaColor.red:   ally.redMana   = value.clamp(0, ally.maxRedMana);   break;
    case ManaColor.white: ally.whiteMana = value.clamp(0, ally.maxWhiteMana); break;
    case ManaColor.green: ally.greenMana = value.clamp(0, ally.maxGreenMana); break;
    case ManaColor.black: ally.blackMana = value.clamp(0, ally.maxBlackMana); break;
    case ManaColor.none:  break;
  }
}

// ── In-flight projectile wrapper ──────────────────────────────────────────────
// Top-level private: DuelSystem static methods reference it without nesting (Dart lacks nested classes).
class _DuelProj {
  final Projectile p;
  final Ally target;
  final String actorId;
  final double gearMult;
  final int targetIndex; // 0-based index within the target's own side's party
  _DuelProj(this.p, this.target, this.actorId, this.gearMult, this.targetIndex);
}

// ── Ollama strategy advisor ───────────────────────────────────────────────────

/// Decrements the advisory timer and fires an async LLM query every 3 s.
void _duelTickAdvisor(double dt, DuelManager mgr,
    List<Ally> challengers, List<Ally> enemies) {
  mgr.ollamaAdvisoryTimer -= dt;
  if (mgr.ollamaAdvisoryTimer > 0) return;
  mgr.ollamaAdvisoryTimer = 3.0;
  _duelQueryStrategy(mgr, challengers, enemies);
}

/// Fire-and-forget: asks qwen2.5:3b for a one-word strategy hint.
/// Reason: small model (<2 GB RAM) returns quickly; 3-second cadence keeps
/// latency invisible to the game loop while giving the LLM meaningful HP data.
Future<void> _duelQueryStrategy(DuelManager mgr,
    List<Ally> challengers, List<Ally> enemies) async {
  final chalHp    = challengers.fold(0.0, (s, c) => s + c.health);
  final chalMaxHp = challengers.fold(0.0, (s, c) => s + c.maxHealth);
  final enemHp    = enemies.fold(0.0, (s, e) => s + e.health);
  final enemMaxHp = enemies.fold(0.0, (s, e) => s + e.maxHealth);
  final chalPct   = chalMaxHp > 0 ? (chalHp / chalMaxHp * 100).round() : 0;
  final enemPct   = enemMaxHp > 0 ? (enemHp / enemMaxHp * 100).round() : 0;
  const prefix    = 'Reply one word only: aggressive, defensive, or balanced.\n';
  final prompt    = '${prefix}Blue HP: $chalPct%  Red HP: $enemPct%  '
      'Time: ${mgr.elapsedSeconds.round()}s\nBest strategy for blue side?';
  try {
    final raw  = await DuelSystem._ollamaClient.generate(
        model: 'qwen3.5:0.8b', prompt: prompt, temperature: 0.1);
    final word = raw.trim().split(RegExp(r'\W+')).first.toLowerCase();
    if (word == 'aggressive' || word == 'defensive' || word == 'balanced') {
      mgr.ollamaStrategyHint = word;
    }
  } catch (_) { /* Ollama unavailable — keep current hint */ }
}
