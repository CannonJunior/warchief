import 'package:flutter/material.dart';
import '../../models/console_log_entry.dart';

/// Console Log tab content — displays all player actions for troubleshooting.
///
/// Messages are color-coded by [ConsoleLogLevel]:
/// - info  → green (normal actions)
/// - warn  → yellow (blocked actions, partial implementations)
/// - error → red (failures, unimplemented abilities)
///
/// Each entry shows: [HH:MM:SS] message
class ConsoleLogTab extends StatelessWidget {
  final List<ConsoleLogEntry> messages;

  const ConsoleLogTab({Key? key, required this.messages}) : super(key: key);

  /// Get color for a [ConsoleLogLevel].
  static Color colorForLevel(ConsoleLogLevel level) {
    switch (level) {
      case ConsoleLogLevel.info:
        return const Color(0xFF44DD44);
      case ConsoleLogLevel.warn:
        return const Color(0xFFDDDD44);
      case ConsoleLogLevel.error:
        return const Color(0xFFFF4444);
    }
  }

  /// Get prefix label for a [ConsoleLogLevel].
  static String prefixForLevel(ConsoleLogLevel level) {
    switch (level) {
      case ConsoleLogLevel.info:
        return 'INFO';
      case ConsoleLogLevel.warn:
        return 'WARN';
      case ConsoleLogLevel.error:
        return 'ERR ';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No actions logged yet',
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
        color: Colors.black.withValues(alpha: 0.4),
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

  /// Build a single console log entry.
  Widget _buildEntry(ConsoleLogEntry entry) {
    final color = colorForLevel(entry.level);
    final prefix = prefixForLevel(entry.level);

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
            // Level prefix
            TextSpan(
              text: '$prefix ',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            // Message text
            TextSpan(
              text: entry.message,
              style: TextStyle(color: color.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}
