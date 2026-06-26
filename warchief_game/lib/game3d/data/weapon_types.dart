import '../../models/item.dart';

/// Resolved weapon modifiers for the currently equipped weapon.
///
/// Returned by [WeaponSystem.getActiveModifiers]. All values default to
/// neutral (1.0x multipliers, 0 additive mods) when no weapon is equipped.
class WeaponModifiers {
  final double cooldownMultiplier;
  final double damageMultiplier;
  final int comboThresholdMod;
  final double comboWindowBonus;
  final String specialMechanic;
  final Map<String, dynamic> specialConfig;
  final WeaponCategory category;
  final WeaponType type;

  const WeaponModifiers({
    this.cooldownMultiplier = 1.0,
    this.damageMultiplier = 1.0,
    this.comboThresholdMod = 0,
    this.comboWindowBonus = 0.0,
    this.specialMechanic = 'none',
    this.specialConfig = const {},
    this.category = WeaponCategory.none,
    this.type = WeaponType.none,
  });

  static const neutral = WeaponModifiers();
}

/// Resolved stance synergy bonuses for a weapon+stance combination.
class WeaponStanceSynergy {
  final Map<String, dynamic> raw;

  const WeaponStanceSynergy(this.raw);

  double? get cooldownBonus => (raw['cooldownBonus'] as num?)?.toDouble();
  int? get grooveStackBonus => raw['grooveStackBonus'] as int?;
  double? get cancelChainDamageBonus =>
      (raw['cancelChainDamageBonus'] as num?)?.toDouble();
  double? get damagePerStack =>
      (raw['damagePerStack'] as num?)?.toDouble();
  int? get maxStackBonus => raw['maxStackBonus'] as int?;
  double? get backwardKnockbackBonus =>
      (raw['backwardKnockbackBonus'] as num?)?.toDouble();
  double? get pressurePerHit =>
      (raw['pressurePerHit'] as num?)?.toDouble();
  double? get breakDamageBonus =>
      (raw['breakDamageBonus'] as num?)?.toDouble();
  int? get heatReduction => raw['heatReduction'] as int?;
  double? get coolDownPayoffBonus =>
      (raw['coolDownPayoffBonus'] as num?)?.toDouble();
  double? get switchCooldownReduction =>
      (raw['switchCooldownReduction'] as num?)?.toDouble();
  double? get transitionDamageBonus =>
      (raw['transitionDamageBonus'] as num?)?.toDouble();
  double? get beatWindowBonus =>
      (raw['beatWindowBonus'] as num?)?.toDouble();
  double? get rangeBonus =>
      (raw['rangeBonus'] as num?)?.toDouble();
  double? get forwardDamageBonus =>
      (raw['forwardDamageBonus'] as num?)?.toDouble();
  double? get predatorDamageBonus =>
      (raw['predatorDamageBonus'] as num?)?.toDouble();
  double? get splashRadiusBonus =>
      (raw['splashRadiusBonus'] as num?)?.toDouble();
}
