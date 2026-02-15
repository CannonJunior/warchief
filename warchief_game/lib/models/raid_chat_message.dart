/// Alert severity for raid chat messages.
enum RaidAlertType {
  info,      // Cyan — general information
  warning,   // Yellow — attention needed
  critical,  // Red — immediate danger
  success,   // Green — positive outcome
}

/// Category of raid chat alert (for throttling and filtering).
enum RaidAlertCategory {
  mana,      // Mana-related alerts
  health,    // Health-related alerts
  cooldown,  // Ability cooldown alerts
  aggro,     // Aggro/threat alerts
  rotation,  // Macro rotation status
  phase,     // Boss phase changes
}

/// A single message in the Raid Chat channel.
///
/// These are system-generated alerts during combat — players don't
/// type into Raid Chat. Messages are color-coded by [type] and
/// throttled by [category] to avoid spam.
class RaidChatMessage {
  final String senderName;        // "Warchief", ally name, "System"
  final String text;
  final RaidAlertType type;
  final RaidAlertCategory category;
  final DateTime timestamp;

  RaidChatMessage({
    required this.senderName,
    required this.text,
    this.type = RaidAlertType.info,
    this.category = RaidAlertCategory.rotation,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Format timestamp as [HH:MM].
  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '[$h:$m]';
  }

  @override
  String toString() => '$formattedTime $senderName: $text';
}
