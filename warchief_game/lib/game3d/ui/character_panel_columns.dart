import 'package:flutter/material.dart';
import '../ai/ally_strategy.dart';
import '../../models/ally.dart';
import '../../models/item.dart';
import '../../models/inventory.dart';
import 'paper_doll_painter.dart';
import 'item_tooltip.dart';

// Re-export stats column and tooltip so consumers only need one import
export 'character_panel_stats.dart' show buildStatsColumn;
export 'item_tooltip.dart' show buildItemTooltip, EquipSlotHover;

/// Attribute color constants used for color-coding attribute-to-combat-stat links.
///
/// Brawn (Indian Red) -> Damage
/// Yar (Teal) -> Dodge, Haste
/// Valor (Gold) -> Armor, Block
/// Auspice (Mauve) -> Crit
/// Chuff (Burlywood) -> standalone
/// X (Gray) -> standalone
/// Zeal (Tomato) -> standalone
class AttrColors {
  static const brawn = Color(0xFFCD5C5C);
  static const yar = Color(0xFF20B2AA);
  static const valor = Color(0xFFFFD700);
  static const auspice = Color(0xFFE0B0FF);
  static const chuff = Color(0xFFDEB887);
  static const x = Color(0xFF808080);
  static const zeal = Color(0xFFFF6347);
}

// ---------------------------------------------------------------------------
// LEFT COLUMN: Attributes
// ---------------------------------------------------------------------------

/// Builds the left column showing 7 attributes with color-coded accent bars
/// and proportional fill indicators.
Widget buildAttributesColumn({
  required bool isPlayer,
  required int allyIndex,
}) {
  final auspice = isPlayer ? 14 : 8 + (allyIndex * 2);
  final brawn = isPlayer ? 25 : 15 + (allyIndex * 3);
  final chuff = isPlayer ? 18 : 12 + (allyIndex * 2);
  final xVal = isPlayer ? 7 : 3 + allyIndex;
  final yar = isPlayer ? 20 : 14 + (allyIndex * 2);
  final zeal = isPlayer ? 16 : 10 + (allyIndex * 2);
  final valor = isPlayer ? 22 : 16 + (allyIndex * 2);

  final attrs = <_AttrData>[
    _AttrData('Auspice', auspice, AttrColors.auspice),
    _AttrData('Brawn', brawn, AttrColors.brawn),
    _AttrData('Chuff', chuff, AttrColors.chuff),
    _AttrData('X', xVal, AttrColors.x),
    _AttrData('Yar', yar, AttrColors.yar),
    _AttrData('Zeal', zeal, AttrColors.zeal),
    _AttrData('Valor', valor, AttrColors.valor),
  ];

  // Reason: maxVal used to normalize fill bars proportionally across attributes
  final maxVal = attrs.fold<int>(0, (m, a) => a.value > m ? a.value : m);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('Attributes'),
        const SizedBox(height: 8),
        ...attrs.map((a) => _buildAttrRow(a, maxVal)),
      ],
    ),
  );
}

/// Single attribute row: colored accent bar | name | fill bar | value
Widget _buildAttrRow(_AttrData attr, int maxVal) {
  final fillFraction = maxVal > 0 ? attr.value / maxVal : 0.0;

  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        // Colored accent bar
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: attr.color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 6),
        // Attribute name
        SizedBox(
          width: 52,
          child: Text(
            attr.name,
            style: TextStyle(
              color: attr.color.withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
        ),
        // Proportional fill bar
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fillFraction.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: attr.color.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Numeric value
        SizedBox(
          width: 24,
          child: Text(
            '${attr.value}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// CENTER COLUMN: Paper Doll
// ---------------------------------------------------------------------------

/// Builds the center column with the rotatable cube portrait and
/// equipment slots arranged in two rows below the paper doll.
///
/// Layout:
///   Helm (centered)
///   RotatableCubePortrait (120x120 for player, 100x100 for ally)
///   Row 1: Back, Gloves, Armor, Legs, Boots
///   Row 2: Ring 1, Main Hand, Talisman, Off Hand, Ring 2
///   Ally Status (for ally views only, below equipment)
///
/// Equipment slots are shown for ALL characters (player and allies).
Widget buildPaperDollColumn({
  required bool isPlayer,
  required int currentIndex,
  required Ally? ally,
  required double cubeRotation,
  required Color portraitColor,
  required Inventory inventory,
  void Function(EquipmentSlot slot, Item item)? onEquipItem,
  void Function(EquipmentSlot slot, Item item)? onUnequipItem,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      children: [
        // Helm - top center
        _equipSlot(EquipmentSlot.helm, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
        const SizedBox(height: 8),
        // Central cube portrait (smaller for allies to leave room for status)
        RotatableCubePortrait(
          color: portraitColor,
          size: isPlayer ? 120 : 100,
          rotation: cubeRotation,
        ),
        const SizedBox(height: 8),
        // Row 1: Back, Gloves, Armor, Legs, Boots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _equipSlot(EquipmentSlot.back, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
            const SizedBox(width: 4),
            _equipSlot(EquipmentSlot.gloves, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
            const SizedBox(width: 4),
            _equipSlot(EquipmentSlot.armor, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
            const SizedBox(width: 4),
            _equipSlot(EquipmentSlot.legs, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
            const SizedBox(width: 4),
            _equipSlot(EquipmentSlot.boots, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
          ],
        ),
        const SizedBox(height: 4),
        // Row 2: Ring 1, Main Hand, Talisman, Off Hand, Ring 2
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _equipSlot(EquipmentSlot.ring1, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
            const SizedBox(width: 4),
            _equipSlot(EquipmentSlot.mainHand, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
            const SizedBox(width: 4),
            _equipSlot(EquipmentSlot.talisman, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
            const SizedBox(width: 4),
            _equipSlot(EquipmentSlot.offHand, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
            const SizedBox(width: 4),
            _equipSlot(EquipmentSlot.ring2, inventory, onEquipItem: onEquipItem, onUnequipItem: onUnequipItem),
          ],
        ),
        const SizedBox(height: 4),
        // Drag hint
        Text(
          '\u2190 drag to rotate \u2192',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
        // Ally status info below equipment (compact)
        if (!isPlayer && ally != null) ...[
          const SizedBox(height: 8),
          _buildAllyStatusCompact(ally),
        ],
      ],
    ),
  );
}

/// Compact ally status info shown below equipment slots.
Widget _buildAllyStatusCompact(Ally ally) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF252542)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _allyStatusChip(Icons.psychology, ally.strategy.name),
        _allyStatusChip(Icons.assignment, _commandName(ally.currentCommand)),
        _allyStatusChip(Icons.auto_fix_high, _abilityName(ally.abilityIndex)),
      ],
    ),
  );
}

/// Compact chip showing an ally status value.
Widget _allyStatusChip(IconData icon, String value) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: const Color(0xFF4cc9f0), size: 11),
      const SizedBox(width: 3),
      Text(
        value,
        style: const TextStyle(color: Colors.white70, fontSize: 9),
      ),
    ],
  );
}

/// Builds a single 44x44 equipment slot with rarity color and rich tooltip.
///
/// Wraps the slot in a [DragTarget<Item>] so items can be dragged from
/// the bag panel to equip. Shows a green glow when a valid item hovers.
/// Equipped items are wrapped in [Draggable<EquipmentDragData>] so they
/// can be dragged to the bag panel to unequip.
Widget _equipSlot(
  EquipmentSlot slot,
  Inventory inventory, {
  void Function(EquipmentSlot slot, Item item)? onEquipItem,
  void Function(EquipmentSlot slot, Item item)? onUnequipItem,
}) {
  final item = inventory.getEquipped(slot);
  final hasItem = item != null;
  final borderColor = hasItem ? item.rarity.color : const Color(0xFF3a3a3a);
  final bgColor = hasItem
      ? item.rarity.color.withValues(alpha: 0.15)
      : const Color(0xFF1a1a1a);

  return DragTarget<Item>(
    onWillAcceptWithDetails: (details) {
      return slot.canAcceptItem(details.data);
    },
    onAcceptWithDetails: (details) {
      onEquipItem?.call(slot, details.data);
    },
    builder: (context, candidateData, rejectedData) {
      final isHovering = candidateData.isNotEmpty;

      Widget slotContent = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isHovering
                ? const Color(0xFF4CAF50)
                : borderColor,
            width: isHovering ? 2 : (hasItem ? 2 : 1),
          ),
          boxShadow: isHovering
              ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : hasItem
                  ? [
                      BoxShadow(
                        color: item.rarity.color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              slot.icon,
              color: hasItem ? item.rarity.color : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(height: 1),
            Text(
              slot.displayName,
              style: TextStyle(
                color: hasItem ? Colors.white70 : Colors.grey.shade700,
                fontSize: 7,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

      // Wrap equipped items in Draggable so they can be dragged to bag
      if (hasItem && onUnequipItem != null) {
        slotContent = Draggable<EquipmentDragData>(
          data: EquipmentDragData(slot: slot, item: item),
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.rarity.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: item.rarity.color, width: 2),
              ),
              child: Center(
                child: Icon(slot.icon, color: item.rarity.color, size: 20),
              ),
            ),
          ),
          childWhenDragging: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF3a3a3a), width: 1),
            ),
          ),
          child: slotContent,
        );
      }

      // Wrap in EquipSlotHover for rich tooltip on hover
      return EquipSlotHover(
        item: item,
        slotName: slot.displayName,
        child: slotContent,
      );
    },
  );
}

/// Reusable section title matching existing character_panel style.
Widget sectionTitle(String title) {
  return Row(
    children: [
      Container(
        width: 3,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFF4cc9f0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4cc9f0),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ],
  );
}

String _commandName(AllyCommand command) {
  switch (command) {
    case AllyCommand.none: return 'AI Control';
    case AllyCommand.follow: return 'Following';
    case AllyCommand.attack: return 'Attacking';
    case AllyCommand.hold: return 'Holding';
    case AllyCommand.defensive: return 'Defensive';
  }
}

String _movementModeName(AllyMovementMode mode) {
  switch (mode) {
    case AllyMovementMode.stationary: return 'Stationary';
    case AllyMovementMode.followPlayer: return 'Following';
    case AllyMovementMode.commanded: return 'Commanded';
    case AllyMovementMode.tactical: return 'Tactical';
  }
}

String _abilityName(int index) {
  switch (index) {
    case 0: return 'Sword Strike';
    case 1: return 'Fireball';
    case 2: return 'Heal';
    default: return 'Unknown';
  }
}

/// Internal data class for attribute display.
class _AttrData {
  final String name;
  final int value;
  final Color color;

  const _AttrData(this.name, this.value, this.color);
}
