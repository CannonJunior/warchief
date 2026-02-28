/// Data models for duel arena results and event logging.
///
/// All types support JSON round-trip for SharedPreferences persistence.

// ==================== END CONDITION ====================

/// Determines when a duel is considered over.
///
/// [firstKill]          — ends the moment any combatant reaches 0 HP.
/// [totalAnnihilation]  — ends when every member of one side is dead.
enum DuelEndCondition { firstKill, totalAnnihilation }

const Map<DuelEndCondition, String> duelEndConditionLabels = {
  DuelEndCondition.firstKill:         'First Kill',
  DuelEndCondition.totalAnnihilation: 'Total Annihilation',
};

// ==================== DUEL EVENT ====================

/// A single timestamped event that occurred during a duel.
class DuelEvent {
  final double timeSeconds;

  /// One of: 'damage' | 'heal' | 'ability_used' | 'status' | 'death'
  final String type;

  /// One of: 'challenger' | 'enemy'
  final String actorId;

  final double value;

  /// Ability name, status name, or other descriptive detail.
  final String detail;

  const DuelEvent({
    required this.timeSeconds,
    required this.type,
    required this.actorId,
    required this.value,
    required this.detail,
  });

  Map<String, dynamic> toJson() => {
        'timeSeconds': timeSeconds,
        'type': type,
        'actorId': actorId,
        'value': value,
        'detail': detail,
      };

  factory DuelEvent.fromJson(Map<String, dynamic> json) => DuelEvent(
        timeSeconds: (json['timeSeconds'] as num).toDouble(),
        type: json['type'] as String,
        actorId: json['actorId'] as String,
        value: (json['value'] as num).toDouble(),
        detail: json['detail'] as String,
      );
}

// ==================== DUEL COMBATANT STATS ====================

/// Running statistics for one combatant during/after a duel.
class DuelCombatantStats {
  DuelCombatantStats();

  double totalDamageDealt = 0;
  double totalHealingDone = 0;

  /// Map from ability name to number of times used.
  final Map<String, int> abilitiesUsed = {};

  Map<String, dynamic> toJson() => {
        'totalDamageDealt': totalDamageDealt,
        'totalHealingDone': totalHealingDone,
        'abilitiesUsed': abilitiesUsed,
      };

  factory DuelCombatantStats.fromJson(Map<String, dynamic> json) {
    final stats = DuelCombatantStats();
    stats.totalDamageDealt = (json['totalDamageDealt'] as num).toDouble();
    stats.totalHealingDone = (json['totalHealingDone'] as num).toDouble();
    final used = json['abilitiesUsed'] as Map<String, dynamic>? ?? {};
    used.forEach((k, v) => stats.abilitiesUsed[k] = (v as num).toInt());
    return stats;
  }
}

// ==================== DUEL RESULT ====================

/// Immutable snapshot of a completed duel, persisted to SharedPreferences.
class DuelResult {
  /// Unique ID: millisecondsSinceEpoch as string.
  final String id;

  final int timestamp;

  /// First challenger class — kept for backward-compat display in history.
  final String challengerClass;

  /// First enemy type — kept for backward-compat display in history.
  final String enemyFactionType;

  /// Full challenger party composition (new; old records fall back to [challengerClass]).
  final List<String> challengerClasses;

  /// Full enemy party composition (new; old records fall back to [enemyFactionType]).
  final List<String> enemyTypes;

  /// Gear tier per challenger slot (new; old records fall back to [0]).
  final List<int> challengerGearTiers;

  /// Gear tier per enemy slot (new; old records fall back to [0]).
  final List<int> enemyGearTiers;

  /// One of: 'challenger' | 'enemy' | 'draw'
  final String winnerId;

  final double durationSeconds;

  final DuelEndCondition endCondition;

  final List<DuelEvent> events;
  final DuelCombatantStats challengerStats;
  final DuelCombatantStats enemyStats;

  DuelResult({
    required this.id,
    required this.timestamp,
    required this.challengerClass,
    required this.enemyFactionType,
    required this.challengerClasses,
    required this.enemyTypes,
    required this.challengerGearTiers,
    required this.enemyGearTiers,
    required this.winnerId,
    required this.durationSeconds,
    required this.endCondition,
    required this.events,
    required this.challengerStats,
    required this.enemyStats,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'challengerClass': challengerClass,
        'enemyFactionType': enemyFactionType,
        'challengerClasses': challengerClasses,
        'enemyTypes': enemyTypes,
        'challengerGearTiers': challengerGearTiers,
        'enemyGearTiers': enemyGearTiers,
        'winnerId': winnerId,
        'durationSeconds': durationSeconds,
        'endCondition': endCondition.name,
        'events': events.map((e) => e.toJson()).toList(),
        'challengerStats': challengerStats.toJson(),
        'enemyStats': enemyStats.toJson(),
      };

  factory DuelResult.fromJson(Map<String, dynamic> json) {
    // Reason: backward-compat — records written before multi-party support
    // only stored the first class name; reconstruct single-element lists.
    final chalClass   = json['challengerClass']   as String;
    final enemyType   = json['enemyFactionType']  as String;
    return DuelResult(
      id:               json['id'] as String,
      timestamp:        (json['timestamp'] as num).toInt(),
      challengerClass:  chalClass,
      enemyFactionType: enemyType,
      challengerClasses: (json['challengerClasses'] as List<dynamic>?)
              ?.cast<String>() ?? [chalClass],
      enemyTypes: (json['enemyTypes'] as List<dynamic>?)
              ?.cast<String>() ?? [enemyType],
      challengerGearTiers: (json['challengerGearTiers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt()).toList() ?? [0],
      enemyGearTiers: (json['enemyGearTiers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt()).toList() ?? [0],
      winnerId:         json['winnerId'] as String,
      durationSeconds:  (json['durationSeconds'] as num).toDouble(),
      endCondition:     DuelEndCondition.values.firstWhere(
              (e) => e.name == json['endCondition'],
              orElse: () => DuelEndCondition.totalAnnihilation),
      events: (json['events'] as List<dynamic>)
              .map((e) => DuelEvent.fromJson(e as Map<String, dynamic>))
              .toList(),
      challengerStats: DuelCombatantStats.fromJson(
              json['challengerStats'] as Map<String, dynamic>),
      enemyStats: DuelCombatantStats.fromJson(
              json['enemyStats'] as Map<String, dynamic>),
    );
  }
}
