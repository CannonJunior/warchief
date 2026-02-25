/// Severity levels for console log messages.
enum ConsoleLogLevel { info, warn, error }

/// A single console log entry recording a player action or system event.
class ConsoleLogEntry {
  /// The log message text.
  final String message;

  /// Severity level (info, warn, error).
  final ConsoleLogLevel level;

  /// When this event occurred.
  final DateTime timestamp;

  ConsoleLogEntry({
    required this.message,
    this.level = ConsoleLogLevel.info,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Formatted time string for display: [HH:MM:SS].
  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '[$h:$m:$s]';
  }
}
