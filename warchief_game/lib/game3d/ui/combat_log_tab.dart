import 'package:flutter/material.dart';
import '../../models/combat_log_entry.dart';

/// Combat Log tab content — displays damage, healing, and ability events.
///
/// Messages are color-coded by [CombatLogType]:
/// - damage → red
/// - heal → green
/// - buff → yellow
/// - debuff → purple
/// - death → grey
/// - ability → cyan
///
/// Each entry shows: [HH:MM:SS] Action → Target: amount
class CombatLogTab extends StatelessWidget {
  final List<CombatLogEntry> messages;

  const CombatLogTab({Key? key, required this.messages}) : super(key: key);

  /// Get color for a [CombatLogType].
  static Color colorForType(CombatLogType type) {
    switch (type) {
      case CombatLogType.damage:
        return const Color(0xFFFF4444);
      case CombatLogType.heal:
        return const Color(0xFF44FF44);
      case CombatLogType.buff:
        return const Color(0xFFFFD700);
      case CombatLogType.debuff:
        return const Color(0xFFAA44FF);
      case CombatLogType.death:
        return const Color(0xFF888888);
      case CombatLogType.ability:
        return const Color(0xFF4CC9F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No combat events yet',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final reversedIndex = messages.length - 1 - index;
          final entry = messages[reversedIndex];
          return _buildEntry(entry);
        },
      ),
    );
  }

  /// Build a single combat log entry.
  Widget _buildEntry(CombatLogEntry entry) {
    final color = colorForType(entry.type);

    // Build display text based on type
    String displayText;
    switch (entry.type) {
      case CombatLogType.damage:
        final amountStr = entry.amount?.toStringAsFixed(1) ?? '0';
        displayText = '${entry.action} \u2192 ${entry.target ?? "?"}: $amountStr dmg';
        break;
      case CombatLogType.heal:
        final amountStr = entry.amount?.toStringAsFixed(1) ?? '0';
        displayText = '${entry.action} \u2192 ${entry.target ?? "?"}: +$amountStr HP';
        break;
      case CombatLogType.buff:
      case CombatLogType.debuff:
        displayText = '${entry.action} \u2192 ${entry.target ?? "?"}';
        break;
      case CombatLogType.death:
        displayText = '${entry.target ?? entry.source} died';
        break;
      case CombatLogType.ability:
        displayText = '${entry.source} used ${entry.action}';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
          children: [
            // Timestamp
            TextSpan(
              text: '${entry.formattedTime} ',
              style: TextStyle(color: color.withValues(alpha: 0.5)),
            ),
            // Event text
            TextSpan(
              text: displayText,
              style: TextStyle(color: color.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}
