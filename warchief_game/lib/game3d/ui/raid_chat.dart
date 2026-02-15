import 'package:flutter/material.dart';
import '../../models/raid_chat_message.dart';

/// Raid Chat tab content — displays system-generated combat alerts.
///
/// Messages are color-coded by [RaidAlertType]:
/// - info → cyan
/// - warning → yellow
/// - critical → red
/// - success → green
///
/// Each message shows: [HH:MM] SenderName: text
class RaidChatTab extends StatelessWidget {
  final List<RaidChatMessage> messages;

  const RaidChatTab({Key? key, required this.messages}) : super(key: key);

  /// Get color for a [RaidAlertType].
  static Color colorForType(RaidAlertType type) {
    switch (type) {
      case RaidAlertType.info:
        return const Color(0xFF4CC9F0);
      case RaidAlertType.warning:
        return const Color(0xFFFFD700);
      case RaidAlertType.critical:
        return const Color(0xFFFF4444);
      case RaidAlertType.success:
        return const Color(0xFF44FF44);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No alerts yet',
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
          final message = messages[reversedIndex];
          return _buildMessage(message);
        },
      ),
    );
  }

  /// Build a single raid chat message.
  Widget _buildMessage(RaidChatMessage message) {
    final color = colorForType(message.type);
    final senderColor = color.withValues(alpha: 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
          children: [
            // Timestamp
            TextSpan(
              text: '${message.formattedTime} ',
              style: TextStyle(color: color.withValues(alpha: 0.5)),
            ),
            // Sender name
            TextSpan(
              text: '${message.senderName}: ',
              style: TextStyle(
                color: senderColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Message text
            TextSpan(
              text: message.text,
              style: TextStyle(color: color.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}
