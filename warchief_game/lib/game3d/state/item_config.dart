import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import '../../models/item.dart';

/// Manages item creation configuration loaded from a JSON asset file.
///
/// Provides power level calculation, sentience thresholds, and stat weights.
/// Follows the same pattern as [ManaConfig] (rootBundle.loadString, ChangeNotifier, global singleton).
class ItemConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/item_config.json';

  /// Defaults loaded from JSON asset file
  Map<String, dynamic> _defaults = {};

  // ==================== POWER LEVEL GETTERS ====================

  /// Maximum power level shown on the display bar
  double get maxDisplayLevel =>
      _resolveDouble('powerLevel.maxDisplayLevel', 200.0);

  /// Threshold power level required to unlock "imbued" sentience
  double get imbuedThreshold =>
      _resolveDouble('sentience.thresholds.imbued', 40.0);

  /// Threshold power level required to unlock "sentient" sentience
  double get sentientThreshold =>
      _resolveDouble('sentience.thresholds.sentient', 100.0);

  /// Get the weight for a specific stat name
  double getStatWeight(String statName) =>
      _resolveDouble('powerLevel.weights.$statName', 1.0);

  /// Get the rarity bonus for a specific rarity name
  double getRarityBonus(String rarityName) =>
      _resolveDouble('powerLevel.rarityBonus.$rarityName', 0.0);

  // ==================== POWER LEVEL CALCULATION ====================

  /// Calculate the power level of an item based on its stats and rarity.
  ///
  /// Sums (stat * weight) for all 12 stats, then adds the rarity bonus.
  double calculatePowerLevel(ItemStats stats, ItemRarity rarity) {
    double total = 0.0;

    total += stats.brawn * getStatWeight('brawn');
    total += stats.yar * getStatWeight('yar');
    total += stats.auspice * getStatWeight('auspice');
    total += stats.valor * getStatWeight('valor');
    total += stats.chuff * getStatWeight('chuff');
    total += stats.x * getStatWeight('x');
    total += stats.zeal * getStatWeight('zeal');
    total += stats.armor * getStatWeight('armor');
    total += stats.damage * getStatWeight('damage');
    total += stats.critChance * getStatWeight('critChance');
    total += stats.health * getStatWeight('health');
    total += stats.mana * getStatWeight('mana');

    total += getRarityBonus(rarity.name);

    return total;
  }

  // ==================== INITIALIZATION ====================

  /// Load defaults from the bundled JSON asset file.
  Future<void> initialize() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _defaults = jsonDecode(jsonString) as Map<String, dynamic>;
      notifyListeners();
      print('[ItemConfig] Loaded defaults from $_assetPath');
    } catch (e) {
      print('[ItemConfig] Failed to load defaults: $e (using hardcoded fallbacks)');
      _defaults = {};
    }
  }

  // ==================== RESOLUTION HELPERS ====================

  /// Resolve a double value from the nested defaults map using dot-notation.
  double _resolveDouble(String dotKey, double fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toDouble();
    return fallback;
  }

  /// Resolve a dot-notation key from a nested map.
  ///
  /// Example: `_resolveFromNestedMap(map, 'powerLevel.weights.brawn')`
  /// looks up `map['powerLevel']['weights']['brawn']`.
  static dynamic _resolveFromNestedMap(Map<String, dynamic> map, String dotKey) {
    final parts = dotKey.split('.');
    dynamic current = map;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}

/// Global item config instance (initialized in game3d_widget.dart)
ItemConfig? globalItemConfig;
