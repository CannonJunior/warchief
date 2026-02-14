import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../../models/ally.dart';
import '../../models/inventory.dart';
import 'character_panel_columns.dart' show AttrColors;

/// Builds the right column with resource bars, combat stats, and gear bonuses.
///
/// Uses real gameState mana values instead of hardcoded values.
/// Combat stats are color-tinted to match their related attributes
/// (Brawn->Damage, Valor->Armor/Block, Auspice->Crit, Yar->Dodge/Haste).
Widget buildStatsColumn({
  required bool isPlayer,
  required int currentIndex,
  required Ally? ally,
  required GameState gameState,
}) {
  final health = isPlayer
      ? gameState.playerHealth
      : (ally?.health ?? 0);
  final maxHealth = isPlayer
      ? gameState.playerMaxHealth
      : (ally?.maxHealth ?? 100);

  // Use real mana values from gameState
  final blueMana = isPlayer ? gameState.blueMana : 60.0;
  final maxBlueMana = isPlayer ? gameState.maxBlueMana : 100.0;
  final redMana = isPlayer ? gameState.redMana : 0.0;
  final maxRedMana = isPlayer ? gameState.maxRedMana : 100.0;
  final whiteMana = isPlayer ? gameState.whiteMana : 0.0;
  final maxWhiteMana = isPlayer ? gameState.maxWhiteMana : 100.0;

  // Combat stats
  final damage = isPlayer
      ? '45-52'
      : '${20 + (currentIndex * 5)}-${28 + (currentIndex * 5)}';
  final armor = isPlayer ? '120' : '${60 + (currentIndex * 15)}';
  final crit = isPlayer ? '15%' : '${8 + currentIndex * 2}%';
  final haste = isPlayer ? '8%' : '${4 + currentIndex}%';
  final block = isPlayer ? '22%' : '${10 + currentIndex * 3}%';
  final dodge = isPlayer ? '5%' : '${3 + currentIndex}%';

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resources section
        _sectionTitle('Resources'),
        const SizedBox(height: 6),
        _compactResourceBar('Health', health, maxHealth,
            const Color(0xFF4CAF50)),
        const SizedBox(height: 4),
        _compactResourceBar('Blue', blueMana, maxBlueMana,
            const Color(0xFF2196F3)),
        const SizedBox(height: 4),
        _compactResourceBar('Red', redMana, maxRedMana,
            const Color(0xFFE53935)),
        const SizedBox(height: 4),
        _compactResourceBar('White', whiteMana, maxWhiteMana,
            const Color(0xFFE0E0E0)),
        const SizedBox(height: 14),

        // Combat stats section
        _sectionTitle('Combat'),
        const SizedBox(height: 6),
        _combatStatRow('Damage', damage, AttrColors.brawn),
        _combatStatRow('Armor', armor, AttrColors.valor),
        _combatStatRow('Crit', crit, AttrColors.auspice),
        _combatStatRow('Haste', haste, AttrColors.yar),
        _combatStatRow('Block', block, AttrColors.valor),
        _combatStatRow('Dodge', dodge, AttrColors.yar),
        if (!isPlayer && ally != null) ...[
          _combatStatRow(
            'Cooldown',
            '${ally.abilityCooldownMax.toInt()}s',
            const Color(0xFF4cc9f0),
          ),
        ],
        const SizedBox(height: 14),

        // Gear bonus section (player only)
        if (isPlayer) _buildGearBonusSection(gameState.playerInventory),
      ],
    ),
  );
}

/// Compact resource bar for the right column.
Widget _compactResourceBar(
  String label,
  double current,
  double max,
  Color color,
) {
  final pct = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

  return Row(
    children: [
      SizedBox(
        width: 40,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ),
      Expanded(
        child: Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey.shade800, width: 0.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 4),
      SizedBox(
        width: 28,
        child: Text(
          '${current.toInt()}',
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.white70, fontSize: 9),
        ),
      ),
    ],
  );
}

/// Combat stat row with attribute-matching color tint.
Widget _combatStatRow(String label, String value, Color tintColor) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 10,
              decoration: BoxDecoration(
                color: tintColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 11,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

/// Gear bonus section showing total equipped item stats.
Widget _buildGearBonusSection(Inventory inventory) {
  final bonuses = inventory.totalEquippedStats.nonZeroStats;

  if (bonuses.isEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Gear Bonus'),
        const SizedBox(height: 4),
        Text(
          'No bonuses',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Compact display: "+5 Str, +3 Agi" style
  final bonusText = bonuses
      .map((e) => '+${e.value} ${_abbreviateStat(e.key)}')
      .join(', ');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('Gear Bonus'),
      const SizedBox(height: 4),
      Text(
        bonusText,
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 10,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

/// Abbreviate stat names for compact gear bonus display.
String _abbreviateStat(String stat) {
  switch (stat) {
    case 'Brawn': return 'Brn';
    case 'Yar': return 'Yar';
    case 'Auspice': return 'Aus';
    case 'Valor': return 'Val';
    case 'Chuff': return 'Chf';
    case 'X': return 'X';
    case 'Zeal': return 'Zl';
    case 'Armor': return 'Arm';
    case 'Damage': return 'Dmg';
    case 'Crit Chance': return 'Crit';
    case 'Health': return 'HP';
    case 'Mana': return 'Mana';
    default: return stat;
  }
}

/// Reusable section title matching existing character_panel style.
Widget _sectionTitle(String title) {
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
