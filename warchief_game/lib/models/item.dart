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
    }
  }
}

/// Item stats that can be modified by equipment
class ItemStats {
  final int strength;
  final int agility;
  final int intelligence;
  final int stamina;
  final int spirit;
  final int armor;
  final int damage;
  final int critChance;
  final int health;
  final int mana;

  const ItemStats({
    this.strength = 0,
    this.agility = 0,
    this.intelligence = 0,
    this.stamina = 0,
    this.spirit = 0,
    this.armor = 0,
    this.damage = 0,
    this.critChance = 0,
    this.health = 0,
    this.mana = 0,
  });

  factory ItemStats.fromJson(Map<String, dynamic> json) {
    return ItemStats(
      strength: json['strength'] ?? 0,
      agility: json['agility'] ?? 0,
      intelligence: json['intelligence'] ?? 0,
      stamina: json['stamina'] ?? 0,
      spirit: json['spirit'] ?? 0,
      armor: json['armor'] ?? 0,
      damage: json['damage'] ?? 0,
      critChance: json['critChance'] ?? 0,
      health: json['health'] ?? 0,
      mana: json['mana'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (strength != 0) 'strength': strength,
    if (agility != 0) 'agility': agility,
    if (intelligence != 0) 'intelligence': intelligence,
    if (stamina != 0) 'stamina': stamina,
    if (spirit != 0) 'spirit': spirit,
    if (armor != 0) 'armor': armor,
    if (damage != 0) 'damage': damage,
    if (critChance != 0) 'critChance': critChance,
    if (health != 0) 'health': health,
    if (mana != 0) 'mana': mana,
  };

  /// Get non-zero stats as a list of (name, value) pairs
  List<MapEntry<String, int>> get nonZeroStats {
    final stats = <MapEntry<String, int>>[];
    if (strength != 0) stats.add(MapEntry('Strength', strength));
    if (agility != 0) stats.add(MapEntry('Agility', agility));
    if (intelligence != 0) stats.add(MapEntry('Intelligence', intelligence));
    if (stamina != 0) stats.add(MapEntry('Stamina', stamina));
    if (spirit != 0) stats.add(MapEntry('Spirit', spirit));
    if (armor != 0) stats.add(MapEntry('Armor', armor));
    if (damage != 0) stats.add(MapEntry('Damage', damage));
    if (critChance != 0) stats.add(MapEntry('Crit Chance', critChance));
    if (health != 0) stats.add(MapEntry('Health', health));
    if (mana != 0) stats.add(MapEntry('Mana', mana));
    return stats;
  }
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
    );
  }
}
