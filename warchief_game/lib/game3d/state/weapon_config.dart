import 'dart:convert';
import 'package:flutter/services.dart';

/// JSON config loader for the weapon system.
///
/// Provides access to weapon type definitions, armor effectiveness matrix,
/// stance synergies, and combo modifiers. All values are config-driven.
class WeaponConfig {
  static const String _assetPath = 'assets/data/weapon_config.json';
  Map<String, dynamic> _data = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> initialize() async {
    final jsonStr = await rootBundle.loadString(_assetPath);
    _data = json.decode(jsonStr) as Map<String, dynamic>;
    _loaded = true;
  }

  // ==================== WEAPON TYPE LOOKUPS ====================

  Map<String, dynamic>? getWeaponType(String weaponType) {
    final types = _data['weaponTypes'] as Map<String, dynamic>?;
    return types?[weaponType] as Map<String, dynamic>?;
  }

  double getCooldownMultiplier(String weaponType) {
    final cfg = getWeaponType(weaponType);
    return (cfg?['cooldownMultiplier'] as num?)?.toDouble() ?? 1.0;
  }

  double getDamageMultiplier(String weaponType) {
    final cfg = getWeaponType(weaponType);
    return (cfg?['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
  }

  int getComboThresholdModifier(String weaponType) {
    final cfg = getWeaponType(weaponType);
    return cfg?['comboThresholdModifier'] as int? ?? 0;
  }

  double getComboWindowBonus(String weaponType) {
    final cfg = getWeaponType(weaponType);
    return (cfg?['comboWindowBonus'] as num?)?.toDouble() ?? 0.0;
  }

  String getSpecialMechanic(String weaponType) {
    final cfg = getWeaponType(weaponType);
    return cfg?['specialMechanic'] as String? ?? 'none';
  }

  Map<String, dynamic>? getSpecialMechanicConfig(String weaponType) {
    final cfg = getWeaponType(weaponType);
    if (cfg == null) return null;
    final mechanic = cfg['specialMechanic'] as String? ?? 'none';
    if (mechanic == 'none') return null;
    return cfg['${mechanic}Config'] as Map<String, dynamic>?;
  }

  // ==================== ARMOR EFFECTIVENESS ====================

  double getArmorEffectiveness(String weaponCategory, String armorCategory) {
    final matrix = _data['armorEffectiveness'] as Map<String, dynamic>?;
    if (matrix == null) return 1.0;
    final row = matrix[weaponCategory] as Map<String, dynamic>?;
    if (row == null) return 1.0;
    return (row[armorCategory] as num?)?.toDouble() ?? 1.0;
  }

  // ==================== STANCE SYNERGIES ====================

  Map<String, dynamic>? getStanceSynergy(String key) {
    final synergies = _data['stanceSynergies'] as Map<String, dynamic>?;
    return synergies?[key] as Map<String, dynamic>?;
  }

  // ==================== COMBO MODIFIERS ====================

  Map<String, dynamic>? getComboModifier(String weaponCategory) {
    final mods = _data['comboModifiers'] as Map<String, dynamic>?;
    return mods?[weaponCategory] as Map<String, dynamic>?;
  }

  int getComboThresholdMod(String weaponCategory) {
    final mods = getComboModifier(weaponCategory);
    return mods?['thresholdMod'] as int? ?? 0;
  }

  double getComboWindowMod(String weaponCategory) {
    final mods = getComboModifier(weaponCategory);
    return (mods?['windowBonus'] as num?)?.toDouble() ?? 0.0;
  }

  int getChainThresholdMod(String weaponCategory) {
    final mods = getComboModifier(weaponCategory);
    return mods?['chainThresholdMod'] as int? ?? 0;
  }

  // ==================== SPELL MODIFIER RATIO ====================

  double get spellModifierRatio =>
      (_data['spellModifierRatio'] as num?)?.toDouble() ?? 0.30;
}

WeaponConfig? globalWeaponConfig;
