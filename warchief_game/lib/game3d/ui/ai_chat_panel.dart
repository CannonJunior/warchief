import 'package:flutter/material.dart';
import '../../models/ai_chat_message.dart';

/// AI Chat Panel displaying the Monster AI chat log interface
class AIChatPanel extends StatelessWidget {
  final List<AIChatMessage> messages;

  const AIChatPanel({
    Key? key,
    required this.messages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator
          Row(
            children: [
              Icon(Icons.drag_indicator, color: Colors.cyan.withValues(alpha: 0.5), size: 14),
              const SizedBox(width: 4),
              const Text(
                'MONSTER AI CHAT',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                reverse: true, // Latest messages at bottom
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final reversedIndex = messages.length - 1 - index;
                  final message = messages[reversedIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.isInput ? '→ ' : '← ',
                          style: TextStyle(
                            color: message.isInput ? Colors.yellow : Colors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: message.isInput ? Colors.yellow.shade200 : Colors.green.shade200,
                              fontSize: 8,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
