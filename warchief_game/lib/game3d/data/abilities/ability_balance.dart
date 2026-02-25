import 'package:flutter/material.dart';
import 'ability_types.dart';

/// Display colors for each ManaColor, matching mana bar gradient midpoints.
extension ManaColorDisplay on ManaColor {
  /// The UI display color for this mana type.
  Color get displayColor => switch (this) {
    ManaColor.none  => Colors.grey,
    ManaColor.blue  => const Color(0xFF4080FF),
    ManaColor.red   => const Color(0xFFFF4040),
    ManaColor.white => const Color(0xFFE0E0E0),
    ManaColor.green => const Color(0xFF40CC40),
    ManaColor.black => const Color(0xFF8020C0),
  };
}

/// Computes a balance score for an ability, clamped to [-1.0, 1.0].
///
/// Pure function of ability stats. Score 0 = balanced, positive = strong,
/// negative = weak. Calibrated so Fireball (12 dmg, 2.5s CD, 15 blue) ~ 0.0,
/// Backstab (55 dmg, 6s CD, no mana) ~ 0.3+, and utility-only abilities
/// score negative since they lack direct combat output.
///
/// Args:
///   ability (AbilityData): The ability to evaluate.
///
/// Returns:
///   double: Balance score in [-1.0, 1.0].
double computeBalanceScore(AbilityData ability) {
  // --- Power components (normalized to 0-1 range) ---
  final targetMultiplier = 1.0 + (ability.maxTargets - 1) * 0.3;

  // Reason: Damage normalized against 110 (Crushing Blow is the ceiling)
  final dmgPower = (ability.damage / 110.0) * targetMultiplier;

  // Reason: Healing slightly less impactful than damage in combat scoring
  final healPower = (ability.healAmount / 80.0) * 0.9 * targetMultiplier;

  final aoePower = (ability.aoeRadius / 40.0) * 0.15;

  final statusPower = _statusEffectValue(ability.statusEffect) *
      (ability.statusDuration / 30.0);

  final knockbackPower = (ability.knockbackForce / 5.0) * 0.1;

  final piercingPower = ability.piercing ? 0.05 : 0.0;

  // Reason: DoT total damage contribution spread over ticks
  final dotPower = ability.dotTicks > 0
      ? (ability.damage * ability.dotTicks / 110.0) * 0.15
      : 0.0;

  final totalPower = dmgPower + healPower + aoePower + statusPower +
      knockbackPower + piercingPower + dotPower;

  // --- Cost components (normalized) ---

  // Reason: 240s is the longest CD in the game (Aspect of the Beast = 120s,
  // with headroom for future abilities)
  final cdCost = ability.cooldown / 240.0;

  final manaCostNorm = ability.manaCost / 80.0;
  final secondaryManaCostNorm = ability.secondaryManaCost / 80.0;

  // Reason: Requiring two mana pools is a constraint penalty
  final dualManaTax = ability.requiresDualMana ? 0.08 : 0.0;

  final castCost = (ability.castTime / 5.0) * 0.2;
  final windupCost = (ability.windupTime / 5.0) * 0.15;

  final stationaryCost = ability.requiresStationary ? 0.05 : 0.0;

  final windupMovementPenalty = ability.hasWindup
      ? (1.0 - ability.windupMovementSpeed) * 0.05
      : 0.0;

  final totalCost = cdCost + manaCostNorm + secondaryManaCostNorm +
      dualManaTax + castCost + windupCost + stationaryCost +
      windupMovementPenalty;

  // --- Balance computation ---
  // Reason: 0.55 slope calibrated so a moderate ability with matching cost
  // lands near zero; 2.5 amplifies differences into the -1..1 range
  final expectedPower = totalCost * 0.55;
  final rawScore = totalPower - expectedPower;

  return (rawScore * 2.5).clamp(-1.0, 1.0);
}

/// Maps a StatusEffect to its relative combat value (0.0-0.3 range).
///
/// Hard CC (stun, freeze) is worth the most; soft debuffs and DoTs the least.
///
/// Args:
///   effect (StatusEffect): The effect to evaluate.
///
/// Returns:
///   double: Relative value of the effect.
double _statusEffectValue(StatusEffect effect) => switch (effect) {
  StatusEffect.none     => 0.0,
  StatusEffect.stun     => 0.3,
  StatusEffect.freeze   => 0.25,
  StatusEffect.root     => 0.2,
  StatusEffect.silence  => 0.2,
  StatusEffect.fear     => 0.2,
  StatusEffect.blind    => 0.15,
  StatusEffect.shield   => 0.15,
  StatusEffect.strength => 0.15,
  StatusEffect.haste    => 0.15,
  StatusEffect.slow     => 0.1,
  StatusEffect.burn     => 0.1,
  StatusEffect.poison   => 0.1,
  StatusEffect.bleed    => 0.1,
  StatusEffect.weakness          => 0.1,
  StatusEffect.regen             => 0.1,
  // Vulnerability debuffs — low balance value (passive exposure, no direct CC)
  StatusEffect.vulnerablePhysical   => 0.05,
  StatusEffect.vulnerableFire       => 0.05,
  StatusEffect.vulnerableFrost      => 0.05,
  StatusEffect.vulnerableLightning  => 0.05,
  StatusEffect.vulnerableNature     => 0.05,
  StatusEffect.vulnerableShadow     => 0.05,
  StatusEffect.vulnerableArcane     => 0.05,
  StatusEffect.vulnerableHoly       => 0.05,
};

/// Returns a color for the given balance score.
///
/// Interpolates: red (-1) -> yellow (0) -> green (+1).
///
/// Args:
///   score (double): Balance score in [-1.0, 1.0].
///
/// Returns:
///   Color: The indicator color.
Color balanceScoreColor(double score) {
  final clamped = score.clamp(-1.0, 1.0);
  if (clamped < 0) {
    // Red -> Yellow (-1 -> 0)
    final t = clamped + 1.0; // 0..1
    return Color.lerp(
      const Color(0xFFFF4040),
      const Color(0xFFFFCC40),
      t,
    )!;
  } else {
    // Yellow -> Green (0 -> 1)
    return Color.lerp(
      const Color(0xFFFFCC40),
      const Color(0xFF40CC40),
      clamped,
    )!;
  }
}

/// Returns a human-readable label for the given balance score.
///
/// Args:
///   score (double): Balance score in [-1.0, 1.0].
///
/// Returns:
///   String: Short label like "BALANCED" or "STRONG".
String balanceScoreLabel(double score) {
  if (score <= -0.6) return 'WEAK';
  if (score <= -0.2) return 'BELOW AVG';
  if (score <= 0.2)  return 'BALANCED';
  if (score <= 0.5)  return 'ABOVE AVG';
  if (score <= 0.8)  return 'STRONG';
  return 'OP';
}
