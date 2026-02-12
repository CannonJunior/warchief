import 'package:flutter/material.dart';

/// Equipment slot types
enum EquipmentSlot {
  helm,
  armor,
  back,
  gloves,
  legs,
  boots,
  mainHand,
  offHand,
  ring1,
  ring2,
  talisman,
}

/// Item rarity levels
enum ItemRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Item types
enum ItemType {
  weapon,
  armor,
  accessory,
  consumable,
  material,
  quest,
}

/// Item sentience levels — gated by power thresholds in item_config.json
enum ItemSentience {
  inanimate,
  imbued,
  sentient,
}

/// Extension for ItemSentience to get display properties
extension ItemSentienceExtension on ItemSentience {
  String get displayName {
    switch (this) {
      case ItemSentience.inanimate: return 'Inanimate';
      case ItemSentience.imbued: return 'Imbued';
      case ItemSentience.sentient: return 'Sentient';
    }
  }

  Color get color {
    switch (this) {
      case ItemSentience.inanimate: return const Color(0xFF666666);
      case ItemSentience.imbued: return const Color(0xFF6B8EFF);
      case ItemSentience.sentient: return const Color(0xFFFF6BFF);
    }
  }
}

/// Extension for ItemRarity to get display properties
extension ItemRarityExtension on ItemRarity {
  String get displayName {
    switch (this) {
      case ItemRarity.common: return 'Common';
      case ItemRarity.uncommon: return 'Uncommon';
      case ItemRarity.rare: return 'Rare';
      case ItemRarity.epic: return 'Epic';
      case ItemRarity.legendary: return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case ItemRarity.common: return const Color(0xFF9d9d9d);
      case ItemRarity.uncommon: return const Color(0xFF1eff00);
      case ItemRarity.rare: return const Color(0xFF0070dd);
      case ItemRarity.epic: return const Color(0xFFa335ee);
      case ItemRarity.legendary: return const Color(0xFFff8000);
    }
  }
}

/// Extension for EquipmentSlot to get display properties
extension EquipmentSlotExtension on EquipmentSlot {
  String get displayName {
    switch (this) {
      case EquipmentSlot.helm: return 'Helm';
      case EquipmentSlot.armor: return 'Armor';
      case EquipmentSlot.back: return 'Back';
      case EquipmentSlot.gloves: return 'Gloves';
      case EquipmentSlot.legs: return 'Legs';
      case EquipmentSlot.boots: return 'Boots';
      case EquipmentSlot.mainHand: return 'Main Hand';
      case EquipmentSlot.offHand: return 'Off Hand';
      case EquipmentSlot.ring1: return 'Ring';
      case EquipmentSlot.ring2: return 'Ring';
      case EquipmentSlot.talisman: return 'Talisman';
    }
  }

  IconData get icon {
    switch (this) {
      case EquipmentSlot.helm: return Icons.face;
      case EquipmentSlot.armor: return Icons.checkroom;
      case EquipmentSlot.back: return Icons.wind_power;
      case EquipmentSlot.gloves: return Icons.back_hand;
      case EquipmentSlot.legs: return Icons.airline_seat_legroom_normal;
      case EquipmentSlot.boots: return Icons.skateboarding;
      case EquipmentSlot.mainHand: return Icons.gavel;
      case EquipmentSlot.offHand: return Icons.shield;
      case EquipmentSlot.ring1: return Icons.radio_button_unchecked;
      case EquipmentSlot.ring2: return Icons.radio_button_unchecked;
      case EquipmentSlot.talisman: return Icons.auto_awesome;
    }
  }

  /// Check if this equipment slot can accept a given item.
  ///
  /// Rings are interchangeable: ring1 and ring2 slots both accept
  /// items with either ring1 or ring2 slot designation.
  bool canAcceptItem(Item item) {
    if (item.slot == null) return false;
    if (item.slot == this) return true;
    // Reason: rings are interchangeable (WoW convention)
    if ((this == EquipmentSlot.ring1 || this == EquipmentSlot.ring2) &&
        (item.slot == EquipmentSlot.ring1 || item.slot == EquipmentSlot.ring2)) {
      return true;
    }
    return false;
  }
}

/// Item stats that can be modified by equipment.
///
/// Primary attributes match the game's 7-attribute system:
/// Brawn, Yar, Auspice, Valor, Chuff, X, Zeal.
/// Combat/derived stats: armor, damage, critChance, health.
/// Per-color mana: max mana bonuses and mana regeneration rate bonuses.
class ItemStats {
  final int brawn;
  final int yar;
  final int auspice;
  final int valor;
  final int chuff;
  final int x;
  final int zeal;
  final int armor;
  final int damage;
  final int critChance;
  final int health;
  final int maxBlueMana;
  final int maxRedMana;
  final int maxWhiteMana;
  final int blueManaRegen;
  final int redManaRegen;
  final int whiteManaRegen;

  const ItemStats({
    this.brawn = 0,
    this.yar = 0,
    this.auspice = 0,
    this.valor = 0,
    this.chuff = 0,
    this.x = 0,
    this.zeal = 0,
    this.armor = 0,
    this.damage = 0,
    this.critChance = 0,
    this.health = 0,
    this.maxBlueMana = 0,
    this.maxRedMana = 0,
    this.maxWhiteMana = 0,
    this.blueManaRegen = 0,
    this.redManaRegen = 0,
    this.whiteManaRegen = 0,
  });

  factory ItemStats.fromJson(Map<String, dynamic> json) {
    return ItemStats(
      brawn: json['brawn'] ?? 0,
      yar: json['yar'] ?? 0,
      auspice: json['auspice'] ?? 0,
      valor: json['valor'] ?? 0,
      chuff: json['chuff'] ?? 0,
      x: json['x'] ?? 0,
      zeal: json['zeal'] ?? 0,
      armor: json['armor'] ?? 0,
      damage: json['damage'] ?? 0,
      critChance: json['critChance'] ?? 0,
      health: json['health'] ?? 0,
      maxBlueMana: json['maxBlueMana'] ?? 0,
      maxRedMana: json['maxRedMana'] ?? 0,
      maxWhiteMana: json['maxWhiteMana'] ?? 0,
      blueManaRegen: json['blueManaRegen'] ?? 0,
      redManaRegen: json['redManaRegen'] ?? 0,
      whiteManaRegen: json['whiteManaRegen'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (brawn != 0) 'brawn': brawn,
    if (yar != 0) 'yar': yar,
    if (auspice != 0) 'auspice': auspice,
    if (valor != 0) 'valor': valor,
    if (chuff != 0) 'chuff': chuff,
    if (x != 0) 'x': x,
    if (zeal != 0) 'zeal': zeal,
    if (armor != 0) 'armor': armor,
    if (damage != 0) 'damage': damage,
    if (critChance != 0) 'critChance': critChance,
    if (health != 0) 'health': health,
    if (maxBlueMana != 0) 'maxBlueMana': maxBlueMana,
    if (maxRedMana != 0) 'maxRedMana': maxRedMana,
    if (maxWhiteMana != 0) 'maxWhiteMana': maxWhiteMana,
    if (blueManaRegen != 0) 'blueManaRegen': blueManaRegen,
    if (redManaRegen != 0) 'redManaRegen': redManaRegen,
    if (whiteManaRegen != 0) 'whiteManaRegen': whiteManaRegen,
  };

  /// Get non-zero stats as a list of (name, value) pairs
  List<MapEntry<String, int>> get nonZeroStats {
    final stats = <MapEntry<String, int>>[];
    if (brawn != 0) stats.add(MapEntry('Brawn', brawn));
    if (yar != 0) stats.add(MapEntry('Yar', yar));
    if (auspice != 0) stats.add(MapEntry('Auspice', auspice));
    if (valor != 0) stats.add(MapEntry('Valor', valor));
    if (chuff != 0) stats.add(MapEntry('Chuff', chuff));
    if (x != 0) stats.add(MapEntry('X', x));
    if (zeal != 0) stats.add(MapEntry('Zeal', zeal));
    if (armor != 0) stats.add(MapEntry('Armor', armor));
    if (damage != 0) stats.add(MapEntry('Damage', damage));
    if (critChance != 0) stats.add(MapEntry('Crit Chance', critChance));
    if (health != 0) stats.add(MapEntry('Health', health));
    if (maxBlueMana != 0) stats.add(MapEntry('Blue Mana', maxBlueMana));
    if (maxRedMana != 0) stats.add(MapEntry('Red Mana', maxRedMana));
    if (maxWhiteMana != 0) stats.add(MapEntry('White Mana', maxWhiteMana));
    if (blueManaRegen != 0) stats.add(MapEntry('Blue Regen', blueManaRegen));
    if (redManaRegen != 0) stats.add(MapEntry('Red Regen', redManaRegen));
    if (whiteManaRegen != 0) stats.add(MapEntry('White Regen', whiteManaRegen));
    return stats;
  }
}

/// Data class for dragging equipped items from equipment slots.
///
/// Carries both the source equipment slot and the item being dragged,
/// so the receiving DragTarget knows which slot to unequip.
class EquipmentDragData {
  final EquipmentSlot slot;
  final Item item;

  const EquipmentDragData({required this.slot, required this.item});
}

/// Represents an item in the game
class Item {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final ItemRarity rarity;
  final EquipmentSlot? slot; // null if not equippable
  final ItemStats stats;
  final int stackSize;
  final int maxStack;
  final String iconName; // For future icon loading
  final int sellValue;
  final int levelRequirement;
  final ItemSentience sentience;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    this.slot,
    this.stats = const ItemStats(),
    this.stackSize = 1,
    this.maxStack = 1,
    this.iconName = 'default',
    this.sellValue = 0,
    this.levelRequirement = 1,
    this.sentience = ItemSentience.inanimate,
  });

  /// Whether this item can be equipped
  bool get isEquippable => slot != null;

  /// Whether this item can stack
  bool get isStackable => maxStack > 1;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: ItemType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ItemType.material,
      ),
      rarity: ItemRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => ItemRarity.common,
      ),
      slot: json['slot'] != null
          ? EquipmentSlot.values.firstWhere(
              (s) => s.name == json['slot'],
              orElse: () => EquipmentSlot.mainHand,
            )
          : null,
      stats: json['stats'] != null
          ? ItemStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const ItemStats(),
      stackSize: json['stackSize'] ?? 1,
      maxStack: json['maxStack'] ?? 1,
      iconName: json['iconName'] ?? 'default',
      sellValue: json['sellValue'] ?? 0,
      levelRequirement: json['levelRequirement'] ?? 1,
      sentience: json['sentience'] != null
          ? ItemSentience.values.firstWhere(
              (s) => s.name == json['sentience'],
              orElse: () => ItemSentience.inanimate,
            )
          : ItemSentience.inanimate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'rarity': rarity.name,
    if (slot != null) 'slot': slot!.name,
    'stats': stats.toJson(),
    'stackSize': stackSize,
    'maxStack': maxStack,
    'iconName': iconName,
    'sellValue': sellValue,
    'levelRequirement': levelRequirement,
    'sentience': sentience.name,
  };

  /// Create a copy with modified stack size
  Item copyWithStackSize(int newStackSize) {
    return Item(
      id: id,
      name: name,
      description: description,
      type: type,
      rarity: rarity,
      slot: slot,
      stats: stats,
      stackSize: newStackSize.clamp(1, maxStack),
      maxStack: maxStack,
      iconName: iconName,
      sellValue: sellValue,
      levelRequirement: levelRequirement,
      sentience: sentience,
    );
  }
}
