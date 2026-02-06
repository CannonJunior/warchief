import 'item.dart';

/// Manages player equipment and bag inventory
class Inventory {
  /// Equipped items by slot
  final Map<EquipmentSlot, Item?> _equipment = {
    for (var slot in EquipmentSlot.values) slot: null,
  };

  /// Bag contents (list of items, null = empty slot)
  final List<Item?> _bag;

  /// Number of bag slots
  final int bagSize;

  Inventory({this.bagSize = 24}) : _bag = List.filled(24, null);

  /// Get equipped item in a slot
  Item? getEquipped(EquipmentSlot slot) => _equipment[slot];

  /// Equip an item, returning the previously equipped item (if any)
  Item? equip(Item item) {
    if (!item.isEquippable || item.slot == null) return null;

    final slot = item.slot!;
    final previousItem = _equipment[slot];
    _equipment[slot] = item;
    return previousItem;
  }

  /// Unequip an item from a slot, returning the item
  Item? unequip(EquipmentSlot slot) {
    final item = _equipment[slot];
    _equipment[slot] = null;
    return item;
  }

  /// Get all equipped items
  Map<EquipmentSlot, Item?> get equipment => Map.unmodifiable(_equipment);

  /// Get bag contents
  List<Item?> get bag => List.unmodifiable(_bag);

  /// Get item at bag index
  Item? getBagItem(int index) {
    if (index < 0 || index >= _bag.length) return null;
    return _bag[index];
  }

  /// Add item to bag, returns true if successful
  bool addToBag(Item item) {
    // First try to stack with existing items
    if (item.isStackable) {
      for (int i = 0; i < _bag.length; i++) {
        final existing = _bag[i];
        if (existing != null &&
            existing.id == item.id &&
            existing.stackSize < existing.maxStack) {
          final spaceAvailable = existing.maxStack - existing.stackSize;
          if (spaceAvailable >= item.stackSize) {
            _bag[i] = existing.copyWithStackSize(existing.stackSize + item.stackSize);
            return true;
          }
        }
      }
    }

    // Find empty slot
    for (int i = 0; i < _bag.length; i++) {
      if (_bag[i] == null) {
        _bag[i] = item;
        return true;
      }
    }

    return false; // Bag is full
  }

  /// Remove item from bag at index
  Item? removeFromBag(int index) {
    if (index < 0 || index >= _bag.length) return null;
    final item = _bag[index];
    _bag[index] = null;
    return item;
  }

  /// Set item at specific bag index
  void setBagItem(int index, Item? item) {
    if (index >= 0 && index < _bag.length) {
      _bag[index] = item;
    }
  }

  /// Swap two bag slots
  void swapBagSlots(int index1, int index2) {
    if (index1 < 0 || index1 >= _bag.length) return;
    if (index2 < 0 || index2 >= _bag.length) return;

    final temp = _bag[index1];
    _bag[index1] = _bag[index2];
    _bag[index2] = temp;
  }

  /// Get total stats from all equipped items
  ItemStats get totalEquippedStats {
    int strength = 0, agility = 0, intelligence = 0, stamina = 0;
    int spirit = 0, armor = 0, damage = 0, critChance = 0;
    int health = 0, mana = 0;

    for (final item in _equipment.values) {
      if (item != null) {
        strength += item.stats.strength;
        agility += item.stats.agility;
        intelligence += item.stats.intelligence;
        stamina += item.stats.stamina;
        spirit += item.stats.spirit;
        armor += item.stats.armor;
        damage += item.stats.damage;
        critChance += item.stats.critChance;
        health += item.stats.health;
        mana += item.stats.mana;
      }
    }

    return ItemStats(
      strength: strength,
      agility: agility,
      intelligence: intelligence,
      stamina: stamina,
      spirit: spirit,
      armor: armor,
      damage: damage,
      critChance: critChance,
      health: health,
      mana: mana,
    );
  }

  /// Count non-empty bag slots
  int get usedBagSlots => _bag.where((item) => item != null).length;

  /// Count empty bag slots
  int get freeBagSlots => _bag.where((item) => item == null).length;
}
