import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/item.dart';

/// Database for loading and accessing items from JSON data
class ItemDatabase {
  static ItemDatabase? _instance;
  static ItemDatabase get instance => _instance ??= ItemDatabase._();

  ItemDatabase._();

  final Map<String, Item> _items = {};
  bool _isLoaded = false;

  /// Whether the database has been loaded
  bool get isLoaded => _isLoaded;

  /// Load items from assets
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/items.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final itemsList = jsonData['items'] as List<dynamic>;

      for (final itemJson in itemsList) {
        final item = Item.fromJson(itemJson as Map<String, dynamic>);
        _items[item.id] = item;
      }

      _isLoaded = true;
      print('[ItemDatabase] Loaded ${_items.length} items');
    } catch (e) {
      print('[ItemDatabase] Failed to load items: $e');
      // Load fallback items if JSON fails
      _loadFallbackItems();
      _isLoaded = true;
    }
  }

  /// Load fallback items in case JSON loading fails
  void _loadFallbackItems() {
    final fallbackItems = [
      const Item(
        id: 'iron_sword',
        name: 'Iron Sword',
        description: 'A basic sword.',
        type: ItemType.weapon,
        rarity: ItemRarity.common,
        slot: EquipmentSlot.mainHand,
        stats: ItemStats(damage: 12, brawn: 2),
      ),
      const Item(
        id: 'wooden_shield',
        name: 'Wooden Shield',
        description: 'A basic shield.',
        type: ItemType.armor,
        rarity: ItemRarity.common,
        slot: EquipmentSlot.offHand,
        stats: ItemStats(armor: 25, health: 2),
      ),
      const Item(
        id: 'health_potion',
        name: 'Health Potion',
        description: 'Restores health.',
        type: ItemType.consumable,
        rarity: ItemRarity.common,
        maxStack: 20,
        stackSize: 5,
      ),
    ];

    for (final item in fallbackItems) {
      _items[item.id] = item;
    }
  }

  /// Get item by ID
  Item? getItem(String id) => _items[id];

  /// Get all items
  List<Item> get allItems => _items.values.toList();

  /// Get items by type
  List<Item> getItemsByType(ItemType type) {
    return _items.values.where((item) => item.type == type).toList();
  }

  /// Get items by rarity
  List<Item> getItemsByRarity(ItemRarity rarity) {
    return _items.values.where((item) => item.rarity == rarity).toList();
  }

  /// Get equippable items for a specific slot
  List<Item> getItemsForSlot(EquipmentSlot slot) {
    return _items.values.where((item) => item.slot == slot).toList();
  }

  /// Create a new item instance from an ID (for adding to inventory)
  Item? createItem(String id, {int stackSize = 1}) {
    final template = _items[id];
    if (template == null) return null;

    if (template.isStackable) {
      return template.copyWithStackSize(stackSize);
    }
    return template;
  }
}
