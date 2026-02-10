import 'package:flutter/material.dart';
import '../ai/ally_strategy.dart';
import '../../models/ally.dart';
import '../../models/item.dart';
import '../../models/inventory.dart';
import 'paper_doll_painter.dart';

// Re-export stats column so consumers only need one import
export 'character_panel_stats.dart' show buildStatsColumn;

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

/// Builds the center column with the rotatable cube portrait surrounded
/// by 10 equipment slots in a humanoid silhouette pattern.
///
/// For ally views, shows ally info instead of equipment.
Widget buildPaperDollColumn({
  required bool isPlayer,
  required int currentIndex,
  required Ally? ally,
  required double cubeRotation,
  required Color portraitColor,
  required Inventory inventory,
}) {
  if (!isPlayer && ally != null) {
    return _buildAllyCenter(ally, currentIndex, portraitColor, cubeRotation);
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      children: [
        // Paper doll area: cube with surrounding equipment slots
        SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Central cube portrait
              Positioned(
                top: 70,
                child: RotatableCubePortrait(
                  color: portraitColor,
                  size: 120,
                  rotation: cubeRotation,
                ),
              ),
              // Equipment slots in humanoid silhouette
              // Helm - top center
              Positioned(
                top: 4,
                child: _equipSlot(EquipmentSlot.helm, inventory),
              ),
              // Back - left of head
              Positioned(
                top: 56,
                left: 10,
                child: _equipSlot(EquipmentSlot.back, inventory),
              ),
              // Gloves - right of head
              Positioned(
                top: 56,
                right: 10,
                child: _equipSlot(EquipmentSlot.gloves, inventory),
              ),
              // Main Hand - left of torso
              Positioned(
                top: 118,
                left: 10,
                child: _equipSlot(EquipmentSlot.mainHand, inventory),
              ),
              // Off Hand - right of torso
              Positioned(
                top: 118,
                right: 10,
                child: _equipSlot(EquipmentSlot.offHand, inventory),
              ),
              // Armor - below cube
              Positioned(
                top: 198,
                child: _equipSlot(EquipmentSlot.armor, inventory),
              ),
              // Legs - below armor
              Positioned(
                top: 250,
                child: _equipSlot(EquipmentSlot.legs, inventory),
              ),
              // Ring1 - left bottom
              Positioned(
                bottom: 8,
                left: 24,
                child: _equipSlot(EquipmentSlot.ring1, inventory),
              ),
              // Ring2 - right bottom
              Positioned(
                bottom: 8,
                right: 24,
                child: _equipSlot(EquipmentSlot.ring2, inventory),
              ),
              // Boots - bottom center
              Positioned(
                bottom: 0,
                child: _equipSlot(EquipmentSlot.boots, inventory),
              ),
            ],
          ),
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
      ],
    ),
  );
}

/// Builds ally info for the center column when viewing an ally.
Widget _buildAllyCenter(
  Ally ally,
  int currentIndex,
  Color portraitColor,
  double cubeRotation,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Column(
      children: [
        const SizedBox(height: 16),
        // Ally cube portrait (rotatable)
        RotatableCubePortrait(
          color: portraitColor,
          size: 100,
          rotation: cubeRotation,
        ),
        const SizedBox(height: 12),
        // Drag hint
        Text(
          '\u2190 drag to rotate \u2192',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        sectionTitle('Ally Status'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF252542)),
          ),
          child: Column(
            children: [
              _allyInfoRow('Strategy', ally.strategy.name, Icons.psychology),
              const SizedBox(height: 6),
              _allyInfoRow('Command', _commandName(ally.currentCommand),
                  Icons.assignment),
              const SizedBox(height: 6),
              _allyInfoRow('Mode', _movementModeName(ally.movementMode),
                  Icons.directions_walk),
              const SizedBox(height: 6),
              _allyInfoRow('Ability', _abilityName(ally.abilityIndex),
                  Icons.auto_fix_high),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _allyInfoRow(String label, String value, IconData icon) {
  return Row(
    children: [
      Icon(icon, color: const Color(0xFF4cc9f0), size: 14),
      const SizedBox(width: 6),
      SizedBox(
        width: 60,
        child: Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

/// Builds a single 44x44 equipment slot with rarity color and tooltip.
Widget _equipSlot(EquipmentSlot slot, Inventory inventory) {
  final item = inventory.getEquipped(slot);
  final hasItem = item != null;
  final borderColor = hasItem ? item.rarity.color : const Color(0xFF3a3a3a);
  final bgColor = hasItem
      ? item.rarity.color.withValues(alpha: 0.15)
      : const Color(0xFF1a1a1a);

  return Tooltip(
    message: hasItem
        ? '${item.name}\n${item.rarity.displayName} ${item.type.name}'
        : 'Empty ${slot.displayName} slot',
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: hasItem ? 2 : 1,
        ),
        boxShadow: hasItem
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
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

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
