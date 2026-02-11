import 'package:flutter/material.dart';
import '../../models/item.dart';

/// Stateful wrapper providing rich hover tooltip for equipment slots.
///
/// Shows a detailed tooltip (matching the bag panel style) when the user
/// hovers over an equipment slot that contains an item.
class EquipSlotHover extends StatefulWidget {
  final Item? item;
  final String slotName;
  final Widget child;

  const EquipSlotHover({
    Key? key,
    required this.item,
    required this.slotName,
    required this.child,
  }) : super(key: key);

  @override
  State<EquipSlotHover> createState() => _EquipSlotHoverState();
}

class _EquipSlotHoverState extends State<EquipSlotHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_isHovered && widget.item != null)
            Positioned(
              bottom: 48,
              left: -68,
              child: buildItemTooltip(widget.item!),
            ),
          if (_isHovered && widget.item == null)
            Positioned(
              bottom: 48,
              left: -40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: const Color(0xFF3a3a3a), width: 1),
                ),
                child: Text(
                  'Empty ${widget.slotName} slot',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Builds a rich item tooltip matching the bag panel tooltip style.
///
/// Shared between equipment slots and bag slots for consistent display.
/// Shows name (rarity-colored), rarity/type, slot, stats, description,
/// level requirement, and sell value.
Widget buildItemTooltip(Item item) {
  return Container(
    width: 180,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF1a1a2e).withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: item.rarity.color, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.8),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.name,
          style: TextStyle(
            color: item.rarity.color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${item.rarity.displayName} ${_capitalizeWord(item.type.name)}',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
          ),
        ),
        if (item.slot != null)
          Text(
            item.slot!.displayName,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
        const SizedBox(height: 6),
        ...item.stats.nonZeroStats.map((stat) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '+${stat.value} ${stat.key}',
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 11,
            ),
          ),
        )),
        const SizedBox(height: 4),
        if (item.description.isNotEmpty)
          Text(
            item.description,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        if (item.levelRequirement > 1) ...[
          const SizedBox(height: 4),
          Text(
            'Requires Level ${item.levelRequirement}',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Sell: ${item.sellValue} gold',
          style: TextStyle(
            color: Colors.yellow.shade700,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

String _capitalizeWord(String word) {
  if (word.isEmpty) return word;
  return '${word[0].toUpperCase()}${word.substring(1)}';
}
