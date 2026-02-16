import 'item.dart';
import '../game3d/data/abilities/ability_types.dart' show ManaColor;

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

  Inventory({this.bagSize = 60}) : _bag = List.filled(60, null);

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

  /// Equip an item to a specific slot, returning the previously equipped item.
  ///
  /// Unlike [equip], this allows placing an item in a specific slot
  /// (e.g., a ring in ring2 instead of its default ring1 slot).
  /// The caller is responsible for validating slot compatibility.
  Item? equipToSlot(EquipmentSlot slot, Item item) {
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
    int brawn = 0, yar = 0, auspice = 0, valor = 0;
    int chuff = 0, xVal = 0, zeal = 0;
    int armor = 0, damage = 0, critChance = 0;
    int health = 0;
    int maxBlueMana = 0, maxRedMana = 0, maxWhiteMana = 0;
    int blueManaRegen = 0, redManaRegen = 0, whiteManaRegen = 0;
    int haste = 0, melt = 0;

    for (final item in _equipment.values) {
      if (item != null) {
        brawn += item.stats.brawn;
        yar += item.stats.yar;
        auspice += item.stats.auspice;
        valor += item.stats.valor;
        chuff += item.stats.chuff;
        xVal += item.stats.x;
        zeal += item.stats.zeal;
        armor += item.stats.armor;
        damage += item.stats.damage;
        critChance += item.stats.critChance;
        health += item.stats.health;
        maxBlueMana += item.stats.maxBlueMana;
        maxRedMana += item.stats.maxRedMana;
        maxWhiteMana += item.stats.maxWhiteMana;
        blueManaRegen += item.stats.blueManaRegen;
        redManaRegen += item.stats.redManaRegen;
        whiteManaRegen += item.stats.whiteManaRegen;
        haste += item.stats.haste;
        melt += item.stats.melt;
      }
    }

    return ItemStats(
      brawn: brawn,
      yar: yar,
      auspice: auspice,
      valor: valor,
      chuff: chuff,
      x: xVal,
      zeal: zeal,
      armor: armor,
      damage: damage,
      critChance: critChance,
      health: health,
      maxBlueMana: maxBlueMana,
      maxRedMana: maxRedMana,
      maxWhiteMana: maxWhiteMana,
      blueManaRegen: blueManaRegen,
      redManaRegen: redManaRegen,
      whiteManaRegen: whiteManaRegen,
      haste: haste,
      melt: melt,
    );
  }

  /// Mana colors the character is attuned to via equipped items.
  Set<ManaColor> get manaAttunements {
    final result = <ManaColor>{};
    for (final item in _equipment.values) {
      if (item != null) result.addAll(item.manaAttunement);
    }
    return result;
  }

  /// Count non-empty bag slots
  int get usedBagSlots => _bag.where((item) => item != null).length;

  /// Count empty bag slots
  int get freeBagSlots => _bag.where((item) => item == null).length;
}
