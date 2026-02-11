import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/inventory.dart';
import 'item_tooltip.dart' show buildItemTooltip;
import 'item_editor_panel.dart';

/// Bag Panel - Draggable panel displaying player inventory
///
/// Opened with the 'B' key, this panel shows:
/// - Grid of bag slots (6x10 = 60 slots)
/// - Item tooltips on hover
/// - Item icons with rarity borders
/// - "+ ADD NEW ITEM" button to open the item editor
class BagPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Inventory inventory;
  final Function(int index, Item? item)? onItemClick;
  final VoidCallback? onItemEquipped;
  final void Function(EquipmentSlot slot, Item item)? onUnequipToBag;
  final Function(Item)? onItemCreated;

  const BagPanel({
    Key? key,
    required this.onClose,
    required this.inventory,
    this.onItemClick,
    this.onItemEquipped,
    this.onUnequipToBag,
    this.onItemCreated,
  }) : super(key: key);

  @override
  State<BagPanel> createState() => _BagPanelState();
}

class _BagPanelState extends State<BagPanel> {
  double _xPos = 450.0;
  double _yPos = 100.0;
  int? _hoveredSlot;
  bool _isEditorOpen = false;

  static const int columns = 6;
  static const int rows = 10;
  static const double slotSize = 48.0;
  static const double slotSpacing = 4.0;

  @override
  Widget build(BuildContext context) {
    final panelWidth = (slotSize + slotSpacing) * columns + 32;
    final panelHeight = (slotSize + slotSpacing) * rows + 150;
    // Reason: account for editor panel width when clamping drag bounds
    final totalWidth = _isEditorOpen ? panelWidth + 8 + 320 : panelWidth;

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPos += details.delta.dx;
            _yPos += details.delta.dy;
            _xPos = _xPos.clamp(0.0, MediaQuery.of(context).size.width - totalWidth);
            _yPos = _yPos.clamp(0.0, MediaQuery.of(context).size.height - panelHeight);
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main bag panel
            Container(
              width: panelWidth,
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB300), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildAddNewItemButton(),
                        const SizedBox(height: 8),
                        // Wrap grid in DragTarget to accept equipment drags
                        DragTarget<EquipmentDragData>(
                          onWillAcceptWithDetails: (details) => true,
                          onAcceptWithDetails: (details) {
                            final data = details.data;
                            widget.onUnequipToBag?.call(data.slot, data.item);
                            setState(() {});
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              decoration: candidateData.isNotEmpty
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFFB300)
                                            .withValues(alpha: 0.6),
                                        width: 2,
                                      ),
                                    )
                                  : null,
                              child: _buildBagGrid(),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Editor panel (side-by-side)
            if (_isEditorOpen) ...[
              const SizedBox(width: 8),
              ItemEditorPanel(
                onClose: () {
                  setState(() => _isEditorOpen = false);
                },
                onItemCreated: (item) {
                  widget.onItemCreated?.call(item);
                  setState(() => _isEditorOpen = false);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewItemButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _isEditorOpen = !_isEditorOpen);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Text(
              '+ ADD NEW ITEM',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.drag_indicator, color: Color(0xFFFFB300), size: 20),
              const SizedBox(width: 8),
              const Icon(Icons.inventory_2, color: Color(0xFFFFB300), size: 20),
              const SizedBox(width: 8),
              const Text(
                'BAG',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '[B]',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBagGrid() {
    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row < rows - 1 ? slotSpacing : 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(columns, (col) {
              final index = row * columns + col;
              return Padding(
                padding: EdgeInsets.only(right: col < columns - 1 ? slotSpacing : 0),
                child: _buildSlot(index),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildSlot(int index) {
    final item = widget.inventory.getBagItem(index);
    final isHovered = _hoveredSlot == index;

    Widget slotWidget = MouseRegion(
      onEnter: (_) => setState(() => _hoveredSlot = index),
      onExit: (_) => setState(() => _hoveredSlot = null),
      child: GestureDetector(
        onTap: () => widget.onItemClick?.call(index, item),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: slotSize,
              height: slotSize,
              decoration: BoxDecoration(
                color: item != null
                    ? const Color(0xFF2a2a4a)
                    : const Color(0xFF1a1a2a),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item != null
                      ? item.rarity.color.withValues(alpha: isHovered ? 1.0 : 0.7)
                      : (isHovered ? const Color(0xFF4a4a6a) : const Color(0xFF3a3a4a)),
                  width: item != null ? 2 : 1,
                ),
                boxShadow: isHovered && item != null
                    ? [
                        BoxShadow(
                          color: item.rarity.color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: item != null
                  ? _buildItemIcon(item)
                  : null,
            ),
            // Tooltip
            if (isHovered && item != null)
              Positioned(
                bottom: slotSize + 4,
                left: -60,
                child: buildItemTooltip(item),
              ),
          ],
        ),
      ),
    );

    // Wrap non-empty slots in Draggable for drag-to-equip
    if (item != null) {
      slotWidget = Draggable<Item>(
        data: item,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: slotSize,
            height: slotSize,
            decoration: BoxDecoration(
              color: item.rarity.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: item.rarity.color, width: 2),
            ),
            child: Center(
              child: Icon(
                _getItemIcon(item),
                color: item.rarity.color,
                size: 24,
              ),
            ),
          ),
        ),
        childWhenDragging: Container(
          width: slotSize,
          height: slotSize,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2a),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF3a3a4a),
              width: 1,
            ),
          ),
        ),
        onDragEnd: (details) {
          if (details.wasAccepted) {
            // Item was accepted by a DragTarget (equipment slot)
            setState(() {});
            widget.onItemEquipped?.call();
          }
        },
        child: slotWidget,
      );
    }

    return slotWidget;
  }

  Widget _buildItemIcon(Item item) {
    return Stack(
      children: [
        // Item icon
        Center(
          child: Icon(
            _getItemIcon(item),
            color: item.rarity.color,
            size: 24,
          ),
        ),
        // Stack count
        if (item.stackSize > 1)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '${item.stackSize}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getItemIcon(Item item) {
    switch (item.type) {
      case ItemType.weapon:
        return Icons.gavel;
      case ItemType.armor:
        if (item.slot == EquipmentSlot.helm) return Icons.face;
        if (item.slot == EquipmentSlot.armor) return Icons.checkroom;
        if (item.slot == EquipmentSlot.back) return Icons.wind_power;
        if (item.slot == EquipmentSlot.gloves) return Icons.back_hand;
        if (item.slot == EquipmentSlot.legs) return Icons.airline_seat_legroom_normal;
        if (item.slot == EquipmentSlot.boots) return Icons.skateboarding;
        if (item.slot == EquipmentSlot.offHand) return Icons.shield;
        return Icons.checkroom;
      case ItemType.accessory:
        if (item.slot == EquipmentSlot.talisman) return Icons.auto_awesome;
        return Icons.radio_button_unchecked;
      case ItemType.consumable:
        return Icons.science;
      case ItemType.material:
        return Icons.inventory;
      case ItemType.quest:
        return Icons.star;
    }
  }

  Widget _buildFooter() {
    final used = widget.inventory.usedBagSlots;
    final total = widget.inventory.bag.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$used / $total slots used',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 11,
          ),
        ),
        Row(
          children: [
            Icon(Icons.monetization_on, color: Colors.yellow.shade700, size: 14),
            const SizedBox(width: 4),
            Text(
              '1,234 Gold', // Placeholder
              style: TextStyle(
                color: Colors.yellow.shade700,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
