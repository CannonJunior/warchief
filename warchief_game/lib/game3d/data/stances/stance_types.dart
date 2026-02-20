import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

/// Unique identifier for each stance.
enum StanceId {
  none,
  drunkenMaster,
  bloodWeave,
  tide,
  phantomDance,
  furyOfTheAncestors,
}

/// Immutable data class holding all modifier values and passive mechanics
/// for a single stance. Loaded from `assets/data/stance_config.json`.
class StanceData {
  final StanceId id;
  final String name;
  final String description;
  final IconData icon;
  final Vector3 color;

  // Multiplicative modifiers (1.0 = no change)
  final double damageMultiplier;
  final double damageTakenMultiplier;
  final double movementSpeedMultiplier;
  final double cooldownMultiplier;
  final double manaRegenMultiplier;
  final double manaCostMultiplier;
  final double healingMultiplier;
  final double maxHealthMultiplier;
  final double castTimeMultiplier;

  // Unique passive mechanics
  final double healthDrainPerSecond;
  final double damageTakenToManaRatio;
  final bool usesHpForMana;
  final double hpForManaRatio;
  final bool convertsManaRegenToHeal;
  final double rerollInterval;
  final bool hasRandomModifiers;
  final double rerollDamageMin;
  final double rerollDamageMax;
  final double rerollDamageTakenMin;
  final double rerollDamageTakenMax;

  // Switching constraints
  final double switchCooldown;

  StanceData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.damageMultiplier = 1.0,
    this.damageTakenMultiplier = 1.0,
    this.movementSpeedMultiplier = 1.0,
    this.cooldownMultiplier = 1.0,
    this.manaRegenMultiplier = 1.0,
    this.manaCostMultiplier = 1.0,
    this.healingMultiplier = 1.0,
    this.maxHealthMultiplier = 1.0,
    this.castTimeMultiplier = 1.0,
    this.healthDrainPerSecond = 0.0,
    this.damageTakenToManaRatio = 0.0,
    this.usesHpForMana = false,
    this.hpForManaRatio = 0.0,
    this.convertsManaRegenToHeal = false,
    this.rerollInterval = 0.0,
    this.hasRandomModifiers = false,
    this.rerollDamageMin = 0.70,
    this.rerollDamageMax = 1.30,
    this.rerollDamageTakenMin = 0.70,
    this.rerollDamageTakenMax = 1.30,
    this.switchCooldown = 1.5,
  });

  /// The "no stance" neutral default — all modifiers at 1.0.
  static final StanceData none = StanceData(
    id: StanceId.none,
    name: 'None',
    description: 'No active stance. All stats are at baseline.',
    icon: Icons.person,
    color: Vector3(0.5, 0.5, 0.5),
  );

  /// Build a human-readable modifier summary for tooltips.
  ///
  /// Returns a list of strings like "+15% damage", "-20% healing".
  List<String> get modifierSummary {
    final lines = <String>[];
    void add(String label, double val) {
      if ((val - 1.0).abs() < 0.001) return;
      final pct = ((val - 1.0) * 100).round();
      final sign = pct > 0 ? '+' : '';
      lines.add('$sign$pct% $label');
    }

    add('damage', damageMultiplier);
    add('damage taken', damageTakenMultiplier);
    add('movement speed', movementSpeedMultiplier);
    add('cooldowns', cooldownMultiplier);
    add('mana regen', manaRegenMultiplier);
    add('mana costs', manaCostMultiplier);
    add('healing', healingMultiplier);
    add('max health', maxHealthMultiplier);
    add('cast time', castTimeMultiplier);

    if (hasRandomModifiers) lines.add('Damage & damage taken re-roll every ${rerollInterval.toStringAsFixed(0)}s');
    if (usesHpForMana) lines.add('Abilities cost HP instead of mana');
    if (convertsManaRegenToHeal) lines.add('Mana regen heals HP instead');
    if (damageTakenToManaRatio > 0) lines.add('${(damageTakenToManaRatio * 100).round()}% damage taken → mana');
    if (healthDrainPerSecond > 0) lines.add('Drains ${(healthDrainPerSecond * 100).toStringAsFixed(0)}% max HP/s');
    if (switchCooldown > 2.0) lines.add('${switchCooldown.toStringAsFixed(0)}s lock-in on activation');

    return lines;
  }
}
