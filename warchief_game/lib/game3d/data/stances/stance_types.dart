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

  // Combat interaction modifiers
  final double spellPushbackInflicted;
  final double spellPushbackResistance;
  final double ccDurationInflicted;
  final double ccDurationReceived;
  final double lifestealRatio;
  final double dodgeChance;
  final double manaCostDisruption;

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
    this.spellPushbackInflicted = 0.0,
    this.spellPushbackResistance = 0.0,
    this.ccDurationInflicted = 1.0,
    this.ccDurationReceived = 1.0,
    this.lifestealRatio = 0.0,
    this.dodgeChance = 0.0,
    this.manaCostDisruption = 0.0,
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

  /// Returns a copy of this stance with specified fields replaced.
  StanceData copyWith({
    StanceId? id,
    String? name,
    String? description,
    IconData? icon,
    Vector3? color,
    double? damageMultiplier,
    double? damageTakenMultiplier,
    double? movementSpeedMultiplier,
    double? cooldownMultiplier,
    double? manaRegenMultiplier,
    double? manaCostMultiplier,
    double? healingMultiplier,
    double? maxHealthMultiplier,
    double? castTimeMultiplier,
    double? healthDrainPerSecond,
    double? damageTakenToManaRatio,
    bool? usesHpForMana,
    double? hpForManaRatio,
    bool? convertsManaRegenToHeal,
    double? rerollInterval,
    bool? hasRandomModifiers,
    double? rerollDamageMin,
    double? rerollDamageMax,
    double? rerollDamageTakenMin,
    double? rerollDamageTakenMax,
    double? spellPushbackInflicted,
    double? spellPushbackResistance,
    double? ccDurationInflicted,
    double? ccDurationReceived,
    double? lifestealRatio,
    double? dodgeChance,
    double? manaCostDisruption,
    double? switchCooldown,
  }) {
    return StanceData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      damageMultiplier: damageMultiplier ?? this.damageMultiplier,
      damageTakenMultiplier: damageTakenMultiplier ?? this.damageTakenMultiplier,
      movementSpeedMultiplier: movementSpeedMultiplier ?? this.movementSpeedMultiplier,
      cooldownMultiplier: cooldownMultiplier ?? this.cooldownMultiplier,
      manaRegenMultiplier: manaRegenMultiplier ?? this.manaRegenMultiplier,
      manaCostMultiplier: manaCostMultiplier ?? this.manaCostMultiplier,
      healingMultiplier: healingMultiplier ?? this.healingMultiplier,
      maxHealthMultiplier: maxHealthMultiplier ?? this.maxHealthMultiplier,
      castTimeMultiplier: castTimeMultiplier ?? this.castTimeMultiplier,
      healthDrainPerSecond: healthDrainPerSecond ?? this.healthDrainPerSecond,
      damageTakenToManaRatio: damageTakenToManaRatio ?? this.damageTakenToManaRatio,
      usesHpForMana: usesHpForMana ?? this.usesHpForMana,
      hpForManaRatio: hpForManaRatio ?? this.hpForManaRatio,
      convertsManaRegenToHeal: convertsManaRegenToHeal ?? this.convertsManaRegenToHeal,
      rerollInterval: rerollInterval ?? this.rerollInterval,
      hasRandomModifiers: hasRandomModifiers ?? this.hasRandomModifiers,
      rerollDamageMin: rerollDamageMin ?? this.rerollDamageMin,
      rerollDamageMax: rerollDamageMax ?? this.rerollDamageMax,
      rerollDamageTakenMin: rerollDamageTakenMin ?? this.rerollDamageTakenMin,
      rerollDamageTakenMax: rerollDamageTakenMax ?? this.rerollDamageTakenMax,
      spellPushbackInflicted: spellPushbackInflicted ?? this.spellPushbackInflicted,
      spellPushbackResistance: spellPushbackResistance ?? this.spellPushbackResistance,
      ccDurationInflicted: ccDurationInflicted ?? this.ccDurationInflicted,
      ccDurationReceived: ccDurationReceived ?? this.ccDurationReceived,
      lifestealRatio: lifestealRatio ?? this.lifestealRatio,
      dodgeChance: dodgeChance ?? this.dodgeChance,
      manaCostDisruption: manaCostDisruption ?? this.manaCostDisruption,
      switchCooldown: switchCooldown ?? this.switchCooldown,
    );
  }

  /// Apply a sparse override map to produce a new StanceData.
  ///
  /// Keys match field names. Handles doubles, bools, strings,
  /// and [r,g,b] lists for Vector3 color.
  StanceData applyOverrides(Map<String, dynamic> overrides) {
    if (overrides.isEmpty) return this;

    T ov<T>(String key, T fallback) {
      final v = overrides[key];
      if (v == null) return fallback;
      if (v is T) return v;
      if (fallback is double && v is num) return v.toDouble() as T;
      if (fallback is bool && v is bool) return v as T;
      return fallback;
    }

    Vector3 colorOv = color;
    if (overrides.containsKey('color')) {
      final c = overrides['color'];
      if (c is List && c.length >= 3) {
        colorOv = Vector3(
          (c[0] as num).toDouble(),
          (c[1] as num).toDouble(),
          (c[2] as num).toDouble(),
        );
      }
    }

    return copyWith(
      description: ov<String>('description', description),
      color: colorOv,
      damageMultiplier: ov<double>('damageMultiplier', damageMultiplier),
      damageTakenMultiplier: ov<double>('damageTakenMultiplier', damageTakenMultiplier),
      movementSpeedMultiplier: ov<double>('movementSpeedMultiplier', movementSpeedMultiplier),
      cooldownMultiplier: ov<double>('cooldownMultiplier', cooldownMultiplier),
      manaRegenMultiplier: ov<double>('manaRegenMultiplier', manaRegenMultiplier),
      manaCostMultiplier: ov<double>('manaCostMultiplier', manaCostMultiplier),
      healingMultiplier: ov<double>('healingMultiplier', healingMultiplier),
      maxHealthMultiplier: ov<double>('maxHealthMultiplier', maxHealthMultiplier),
      castTimeMultiplier: ov<double>('castTimeMultiplier', castTimeMultiplier),
      healthDrainPerSecond: ov<double>('healthDrainPerSecond', healthDrainPerSecond),
      damageTakenToManaRatio: ov<double>('damageTakenToManaRatio', damageTakenToManaRatio),
      usesHpForMana: ov<bool>('usesHpForMana', usesHpForMana),
      hpForManaRatio: ov<double>('hpForManaRatio', hpForManaRatio),
      convertsManaRegenToHeal: ov<bool>('convertsManaRegenToHeal', convertsManaRegenToHeal),
      rerollInterval: ov<double>('rerollInterval', rerollInterval),
      hasRandomModifiers: ov<bool>('hasRandomModifiers', hasRandomModifiers),
      rerollDamageMin: ov<double>('rerollDamageMin', rerollDamageMin),
      rerollDamageMax: ov<double>('rerollDamageMax', rerollDamageMax),
      rerollDamageTakenMin: ov<double>('rerollDamageTakenMin', rerollDamageTakenMin),
      rerollDamageTakenMax: ov<double>('rerollDamageTakenMax', rerollDamageTakenMax),
      spellPushbackInflicted: ov<double>('spellPushbackInflicted', spellPushbackInflicted),
      spellPushbackResistance: ov<double>('spellPushbackResistance', spellPushbackResistance),
      ccDurationInflicted: ov<double>('ccDurationInflicted', ccDurationInflicted),
      ccDurationReceived: ov<double>('ccDurationReceived', ccDurationReceived),
      lifestealRatio: ov<double>('lifestealRatio', lifestealRatio),
      dodgeChance: ov<double>('dodgeChance', dodgeChance),
      manaCostDisruption: ov<double>('manaCostDisruption', manaCostDisruption),
      switchCooldown: ov<double>('switchCooldown', switchCooldown),
    );
  }

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
    if (spellPushbackInflicted > 0) lines.add('${(spellPushbackInflicted * 100).round()}% spell pushback per hit');
    if (spellPushbackResistance > 0) {
      if (spellPushbackResistance >= 1.0) {
        lines.add('Immune to spell pushback');
      } else {
        lines.add('${(spellPushbackResistance * 100).round()}% pushback resistance');
      }
    }
    add('CC duration inflicted', ccDurationInflicted);
    add('CC duration received', ccDurationReceived);
    if (lifestealRatio > 0) lines.add('${(lifestealRatio * 100).round()}% lifesteal');
    if (dodgeChance > 0) lines.add('${(dodgeChance * 100).round()}% dodge chance');
    if (manaCostDisruption > 0) lines.add('${(manaCostDisruption * 100).round()}% mana disruption');
    if (switchCooldown > 2.0) lines.add('${switchCooldown.toStringAsFixed(0)}s lock-in on activation');

    return lines;
  }
}
