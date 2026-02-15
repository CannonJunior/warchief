/// Types of combat log events.
enum CombatLogType { damage, heal, buff, debuff, death, ability }

/// A single combat log entry recording an ability use or effect.
class CombatLogEntry {
  /// Who performed the action (e.g. "Player", "Ally 1", "Monster").
  final String source;

  /// The ability or action name (e.g. "Sword", "Fireball", "Heal").
  final String action;

  /// Category of this event.
  final CombatLogType type;

  /// Damage or healing amount (null for buff/debuff/ability-only entries).
  final double? amount;

  /// Who was affected (e.g. "Monster", "Player", "Ally 2").
  final String? target;

  /// When this event occurred.
  final DateTime timestamp;

  CombatLogEntry({
    required this.source,
    required this.action,
    required this.type,
    this.amount,
    this.target,
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
