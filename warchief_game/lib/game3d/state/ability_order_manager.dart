import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../data/abilities/ability_types.dart';
import '../data/abilities/abilities.dart' show AbilityRegistry;
import 'custom_ability_manager.dart';

/// Manages per-category ability ordering that persists via SharedPreferences.
///
/// Stores only categories the user has manually reordered. For unmodified
/// categories, falls back to the default registry order. Reconciles with
/// the current registry on each access (new abilities appended, removed
/// abilities pruned).
///
/// Follows existing manager pattern (ChangeNotifier + SharedPreferences + global).
class AbilityOrderManager extends ChangeNotifier {
  static const String _storageKey = 'ability_category_order';

  /// User-reordered category lists keyed by category name.
  /// Values are ordered lists of ability names.
  Map<String, List<String>> _orders = {};

  /// Returns abilities for a category in user-defined order.
  ///
  /// Reconciles the saved order with the current registry:
  /// - Abilities no longer in registry/custom are removed
  /// - New abilities not in the saved order are appended at end
  List<AbilityData> getOrderedAbilities(String category) {
    final registryAbilities = AbilityRegistry.getByCategory(category);
    final customAbilities =
        globalCustomAbilityManager?.getByCategory(category) ?? [];
    final allAbilities = <AbilityData>[...registryAbilities, ...customAbilities];

    final savedOrder = _orders[category];
    if (savedOrder == null || savedOrder.isEmpty) {
      return allAbilities;
    }

    // Build a lookup map for quick access
    final abilityMap = <String, AbilityData>{};
    for (final a in allAbilities) {
      abilityMap[a.name] = a;
    }

    // Rebuild the list: saved order first (pruning removed), then new ones
    final ordered = <AbilityData>[];
    final seen = <String>{};

    for (final name in savedOrder) {
      final ability = abilityMap[name];
      if (ability != null) {
        ordered.add(ability);
        seen.add(name);
      }
    }

    // Append any abilities not in the saved order (newly added)
    for (final a in allAbilities) {
      if (!seen.contains(a.name)) {
        ordered.add(a);
      }
    }

    return ordered;
  }

  /// Save a custom order for a category.
  ///
  /// [abilityNames] is the full ordered list of ability names.
  void setOrder(String category, List<String> abilityNames) {
    _orders[category] = List<String>.from(abilityNames);
    notifyListeners();
    _save();
  }

  /// Clear saved order for a category (revert to default).
  void clearOrder(String category) {
    _orders.remove(category);
    notifyListeners();
    _save();
  }

  /// Check if a category has a user-defined custom order.
  bool hasCustomOrder(String category) {
    return _orders.containsKey(category) &&
        _orders[category]!.isNotEmpty;
  }

  /// Load saved orders from SharedPreferences.
  Future<void> loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        _orders = decoded.map((key, value) => MapEntry(
            key,
            (value as List<dynamic>).map((e) => e as String).toList()));
        notifyListeners();
        print('[AbilityOrder] Loaded orders for ${_orders.length} categories');
      }
    } catch (e) {
      print('[AbilityOrder] Failed to load: $e');
    }
  }

  /// Save orders to SharedPreferences.
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_orders));
    } catch (e) {
      print('[AbilityOrder] Failed to save: $e');
    }
  }
}

/// Global ability order manager instance
AbilityOrderManager? globalAbilityOrderManager;
