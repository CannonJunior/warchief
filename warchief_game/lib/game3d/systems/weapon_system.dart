import 'dart:math';

import '../../models/item.dart';
import '../data/weapon_types.dart';
import '../data/stances/stance_types.dart';
import '../state/game_state.dart';
import '../state/weapon_config.dart';

/// Weapon System — resolves weapon-derived modifiers for abilities, damage,
/// combos, and stance synergies.
///
/// All values are read from [globalWeaponConfig] (weapon_config.json).
/// Returns neutral modifiers when no weapon is equipped or config is missing.
class WeaponSystem {
  WeaponSystem._();

  static final _rng = Random();

  // ==================== ACTIVE MODIFIERS ====================

  /// Get the weapon modifiers for the currently equipped mainHand weapon.
  static WeaponModifiers getActiveModifiers(GameState gs) {
    final item = gs.playerInventory.getEquipped(EquipmentSlot.mainHand);
    if (item == null || item.weaponType == null) return WeaponModifiers.neutral;
    return _resolveModifiers(item.weaponType!, item.weaponCategory ?? WeaponCategory.none);
  }

  /// Get modifiers for a specific weapon type (for tooltips/UI).
  static WeaponModifiers getModifiersForType(WeaponType type, WeaponCategory cat) {
    return _resolveModifiers(type, cat);
  }

  static WeaponModifiers _resolveModifiers(WeaponType type, WeaponCategory cat) {
    final cfg = globalWeaponConfig;
    if (cfg == null || !cfg.isLoaded) return WeaponModifiers.neutral;

    final typeCfg = cfg.getWeaponType(type.name);
    if (typeCfg == null) return WeaponModifiers.neutral;

    return WeaponModifiers(
      cooldownMultiplier: (typeCfg['cooldownMultiplier'] as num?)?.toDouble() ?? 1.0,
      damageMultiplier: (typeCfg['damageMultiplier'] as num?)?.toDouble() ?? 1.0,
      comboThresholdMod: typeCfg['comboThresholdModifier'] as int? ?? 0,
      comboWindowBonus: (typeCfg['comboWindowBonus'] as num?)?.toDouble() ?? 0.0,
      specialMechanic: typeCfg['specialMechanic'] as String? ?? 'none',
      specialConfig: _extractSpecialConfig(typeCfg),
      category: cat,
      type: type,
    );
  }

  static Map<String, dynamic> _extractSpecialConfig(Map<String, dynamic> typeCfg) {
    final mechanic = typeCfg['specialMechanic'] as String? ?? 'none';
    if (mechanic == 'none') return const {};
    final config = typeCfg['${mechanic}Config'];
    return config is Map<String, dynamic> ? config : const {};
  }

  // ==================== ARMOR EFFECTIVENESS ====================

  /// Compute weapon-vs-armor damage multiplier.
  /// Only applies to DamageSchool.physical — spells use vulnerability system.
  static double getArmorEffectiveness(
    WeaponCategory weaponCat,
    ArmorCategory armorCat,
  ) {
    if (weaponCat == WeaponCategory.none) return 1.0;
    final cfg = globalWeaponConfig;
    if (cfg == null || !cfg.isLoaded) return 1.0;
    return cfg.getArmorEffectiveness(weaponCat.name, armorCat.name);
  }

  // ==================== STANCE SYNERGIES ====================

  /// Get stance synergy bonuses for the weapon+stance combination.
  static WeaponStanceSynergy? getStanceSynergy(
    WeaponCategory category,
    StanceId stance,
  ) {
    if (category == WeaponCategory.none) return null;
    final cfg = globalWeaponConfig;
    if (cfg == null || !cfg.isLoaded) return null;

    final key = '${category.name}_${stance.name}';
    final raw = cfg.getStanceSynergy(key);
    if (raw == null) return null;
    return WeaponStanceSynergy(raw);
  }

  // ==================== COMBO MODIFIERS ====================

  /// Get combo system modifications for the equipped weapon category.
  static int getComboThresholdMod(WeaponCategory category) {
    if (category == WeaponCategory.none) return 0;
    final cfg = globalWeaponConfig;
    if (cfg == null || !cfg.isLoaded) return 0;
    return cfg.getComboThresholdMod(category.name);
  }

  static double getComboWindowMod(WeaponCategory category) {
    if (category == WeaponCategory.none) return 0.0;
    final cfg = globalWeaponConfig;
    if (cfg == null || !cfg.isLoaded) return 0.0;
    return cfg.getComboWindowMod(category.name);
  }

  static int getChainThresholdMod(WeaponCategory category) {
    if (category == WeaponCategory.none) return 0;
    final cfg = globalWeaponConfig;
    if (cfg == null || !cfg.isLoaded) return 0;
    return cfg.getChainThresholdMod(category.name);
  }

  static Map<String, dynamic>? getComboChainBonuses(WeaponCategory category) {
    if (category == WeaponCategory.none) return null;
    final cfg = globalWeaponConfig;
    if (cfg == null || !cfg.isLoaded) return null;
    return cfg.getComboModifier(category.name);
  }

  // ==================== SPECIAL MECHANICS ====================

  /// Apply special weapon mechanic damage modifier.
  /// Called from the damage pipeline after base damage is computed.
  static double applySpecialMechanicDamage(
    WeaponModifiers mods,
    double baseDamage,
    ArmorCategory targetArmor,
    GameState gs,
  ) {
    var damage = baseDamage;

    switch (mods.specialMechanic) {
      case 'halfSwording':
        // Reason: longsword half-swording grants armor bypass after consecutive
        // hits vs plate, simulating thrusting into armor gaps.
        if (targetArmor == ArmorCategory.plate) {
          final required = mods.specialConfig['consecutiveHitsRequired'] as int? ?? 3;
          if (gs.meleeComboCount >= required) {
            final bonus = (mods.specialConfig['vsPlateBonus'] as num?)?.toDouble() ?? 0.20;
            damage *= 1.0 + bonus;
          }
        }

      case 'armorPierce':
        if (targetArmor == ArmorCategory.plate) {
          final ignore = (mods.specialConfig['armorIgnorePercent'] as num?)?.toDouble() ?? 0.20;
          damage *= 1.0 + ignore;
        }

      case 'unpredictable':
        final minVar = (mods.specialConfig['damageVarianceMin'] as num?)?.toDouble() ?? 0.80;
        final maxVar = (mods.specialConfig['damageVarianceMax'] as num?)?.toDouble() ?? 1.20;
        damage *= minVar + _rng.nextDouble() * (maxVar - minVar);

      case 'firstStrike':
        final minRange = (mods.specialConfig['minRange'] as num?)?.toDouble() ?? 4.0;
        final bonus = (mods.specialConfig['openerDamageBonus'] as num?)?.toDouble() ?? 0.40;
        if (gs.meleeComboCount == 0 && _distanceToTarget(gs) >= minRange) {
          damage *= 1.0 + bonus;
        }

      case 'versatileStrike':
        final cycle = mods.specialConfig['cycleLength'] as int? ?? 3;
        final bonus = (mods.specialConfig['bonusDamageOnCycle'] as num?)?.toDouble() ?? 0.15;
        if (gs.meleeComboCount > 0 && gs.meleeComboCount % cycle == 0) {
          damage *= 1.0 + bonus;
        }
    }

    return damage;
  }

  /// Get the max-targets bonus from weapon special mechanics.
  static int getMaxTargetsBonus(WeaponModifiers mods) {
    switch (mods.specialMechanic) {
      case 'cleave':
        return mods.specialConfig['bonusMaxTargets'] as int? ?? 0;
      case 'sweepingBlow':
        return mods.specialConfig['bonusMaxTargets'] as int? ?? 0;
      default:
        return 0;
    }
  }

  /// Get stun duration bonus from concussive force mechanic.
  static double getStunDurationBonus(WeaponModifiers mods) {
    if (mods.specialMechanic != 'concussiveForce') return 0.0;
    return (mods.specialConfig['stunDurationBonus'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get dodge reduction for the target from parry bypass / wrap around.
  static double getDodgeReduction(WeaponModifiers mods) {
    switch (mods.specialMechanic) {
      case 'parryBypass':
        return (mods.specialConfig['dodgeReduction'] as num?)?.toDouble() ?? 0.0;
      case 'wrapAround':
        return (mods.specialConfig['targetDodgeReduction'] as num?)?.toDouble() ?? 0.0;
      default:
        return 0.0;
    }
  }

  /// Get shield effectiveness reduction from shield breaker mechanic.
  static double getShieldReduction(WeaponModifiers mods) {
    if (mods.specialMechanic != 'shieldBreaker') return 0.0;
    return (mods.specialConfig['shieldEffectivenessReduction'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get armor bypass percent from hook shield mechanic.
  static double getArmorBypass(WeaponModifiers mods) {
    if (mods.specialMechanic != 'hookShield') return 0.0;
    return (mods.specialConfig['armorBypassPercent'] as num?)?.toDouble() ?? 0.0;
  }

  // ==================== HELPERS ====================

  /// Get the equipped weapon category from game state.
  static WeaponCategory getEquippedCategory(GameState gs) {
    final item = gs.playerInventory.getEquipped(EquipmentSlot.mainHand);
    return item?.weaponCategory ?? WeaponCategory.none;
  }

  /// Get the equipped weapon type from game state.
  static WeaponType getEquippedType(GameState gs) {
    final item = gs.playerInventory.getEquipped(EquipmentSlot.mainHand);
    return item?.weaponType ?? WeaponType.none;
  }

  static double _distanceToTarget(GameState gs) {
    final playerPos = gs.playerTransform?.position;
    final targetPos = gs.monsterTransform?.position;
    if (playerPos == null || targetPos == null) return 0.0;
    return (targetPos - playerPos).length;
  }
}
