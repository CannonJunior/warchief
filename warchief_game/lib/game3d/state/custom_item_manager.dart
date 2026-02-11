import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../models/item.dart';

/// Manages user-created custom items that persist via SharedPreferences.
///
/// Stores complete Item objects serialized as JSON.
/// Follows the [CustomAbilityManager] pattern (ChangeNotifier + SharedPreferences + global singleton).
class CustomItemManager extends ChangeNotifier {
  static const String _storageKey = 'custom_items';

  /// All user-created items keyed by ID
  Map<String, Map<String, dynamic>> _customItems = {};

  /// Get all custom items
  List<Item> getAll() {
    return _customItems.values
        .map((json) => Item.fromJson(json))
        .toList();
  }

  /// Find a custom item by ID
  Item? findById(String id) {
    final json = _customItems[id];
    if (json == null) return null;
    return Item.fromJson(json);
  }

  /// Total number of custom items
  int get count => _customItems.length;

  /// Generate a unique ID for a new custom item
  static String generateId() =>
      'custom_${DateTime.now().millisecondsSinceEpoch}';

  /// Save or update a custom item
  void saveItem(Item item) {
    _customItems[item.id] = item.toJson();
    notifyListeners();
    _save();
    print('[CustomItems] Saved custom item: ${item.name} (${item.id})');
  }

  /// Remove a custom item by ID
  void removeItem(String id) {
    _customItems.remove(id);
    notifyListeners();
    _save();
    print('[CustomItems] Removed custom item: $id');
  }

  // ==================== PERSISTENCE ====================

  /// Load custom items from SharedPreferences
  Future<void> loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        _customItems = decoded.map((key, value) =>
            MapEntry(key, Map<String, dynamic>.from(value as Map)));
        notifyListeners();
        print('[CustomItems] Loaded ${_customItems.length} custom items');
      }
    } catch (e) {
      print('[CustomItems] Failed to load: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_customItems));
    } catch (e) {
      print('[CustomItems] Failed to save: $e');
    }
  }
}

/// Global custom item manager instance (initialized in game3d_widget.dart)
CustomItemManager? globalCustomItemManager;
