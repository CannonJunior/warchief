/// AIChatMessage - Represents an AI chat message (input or output)
class AIChatMessage {
  final String text;
  final bool isInput; // true = input to AI, false = output from AI
  final DateTime timestamp;

  AIChatMessage({
    required this.text,
    required this.isInput,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
