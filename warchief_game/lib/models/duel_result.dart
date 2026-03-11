/// Data models for duel arena results and event logging.
///
/// All types support JSON round-trip for SharedPreferences persistence.
library;

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

  /// 0-based index of the target within its own side's party list.
  /// Null for non-targeted events (ability_used) or pre-v3 records.
  final int? targetIndex;

  const DuelEvent({
    required this.timeSeconds,
    required this.type,
    required this.actorId,
    required this.value,
    required this.detail,
    this.targetIndex,
  });

  Map<String, dynamic> toJson() => {
        'timeSeconds': timeSeconds,
        'type': type,
        'actorId': actorId,
        'value': value,
        'detail': detail,
        if (targetIndex != null) 'targetIndex': targetIndex,
      };

  factory DuelEvent.fromJson(Map<String, dynamic> json) => DuelEvent(
        timeSeconds: (json['timeSeconds'] as num).toDouble(),
        type: json['type'] as String,
        actorId: json['actorId'] as String,
        value: (json['value'] as num).toDouble(),
        detail: json['detail'] as String,
        targetIndex: json['targetIndex'] as int?,
      );
}

// ==================== DUEL COMBATANT STATS ====================

/// Running statistics for one combatant during/after a duel.
class DuelCombatantStats {
  DuelCombatantStats();

  double totalDamageDealt = 0;
  double totalHealingDone = 0;

  /// Number of enemy combatants killed by this side.
  int killingBlows = 0;

  /// Number of this side's combatants that died during the duel.
  int deaths = 0;

  /// Number of CC, interrupt, debuff, or utility ability casts by this side.
  int ccAndUtilityCasts = 0;

  /// Map from ability name to number of times used.
  final Map<String, int> abilitiesUsed = {};

  /// Map from ability name to total damage dealt by that ability.
  /// Used by DuelMetrics to compute per-ability efficiency ratings.
  final Map<String, double> perAbilityDamage = {};

  /// Map from ability name to total healing done by that ability.
  final Map<String, double> perAbilityHealing = {};

  /// Map from ability name to number of killing blows delivered by that ability.
  /// Enables per-class kill attribution in the history detail view.
  final Map<String, int> killingBlowsByAbility = {};

  Map<String, dynamic> toJson() => {
        'totalDamageDealt': totalDamageDealt,
        'totalHealingDone': totalHealingDone,
        'killingBlows':     killingBlows,
        'deaths':           deaths,
        'ccAndUtilityCasts': ccAndUtilityCasts,
        'abilitiesUsed':    abilitiesUsed,
        'perAbilityDamage': perAbilityDamage,
        'perAbilityHealing': perAbilityHealing,
        'killingBlowsByAbility': killingBlowsByAbility,
      };

  factory DuelCombatantStats.fromJson(Map<String, dynamic> json) {
    final stats = DuelCombatantStats();
    stats.totalDamageDealt   = (json['totalDamageDealt']   as num).toDouble();
    stats.totalHealingDone   = (json['totalHealingDone']   as num).toDouble();
    // Reason: backward-compatible defaults for records saved before these fields.
    stats.killingBlows       = (json['killingBlows']       as num?)?.toInt() ?? 0;
    stats.deaths             = (json['deaths']             as num?)?.toInt() ?? 0;
    stats.ccAndUtilityCasts  = (json['ccAndUtilityCasts']  as num?)?.toInt() ?? 0;
    final used = json['abilitiesUsed'] as Map<String, dynamic>? ?? {};
    used.forEach((k, v) => stats.abilitiesUsed[k] = (v as num).toInt());
    final dmg = json['perAbilityDamage'] as Map<String, dynamic>? ?? {};
    dmg.forEach((k, v) => stats.perAbilityDamage[k] = (v as num).toDouble());
    final heal = json['perAbilityHealing'] as Map<String, dynamic>? ?? {};
    heal.forEach((k, v) => stats.perAbilityHealing[k] = (v as num).toDouble());
    final kb = json['killingBlowsByAbility'] as Map<String, dynamic>? ?? {};
    kb.forEach((k, v) => stats.killingBlowsByAbility[k] = (v as num).toInt());
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

  /// Sum of all challenger party members' max HP at duel start.
  /// Used to reconstruct the health chart from damage/heal events.
  /// Zero for records saved before this field was added.
  final double challengerMaxHp;

  /// Sum of all enemy party members' max HP at duel start.
  final double enemyMaxHp;

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
    this.challengerMaxHp = 0.0,
    this.enemyMaxHp      = 0.0,
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
        'challengerMaxHp': challengerMaxHp,
        'enemyMaxHp': enemyMaxHp,
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
      challengerMaxHp: (json['challengerMaxHp'] as num?)?.toDouble() ?? 0.0,
      enemyMaxHp:      (json['enemyMaxHp']      as num?)?.toDouble() ?? 0.0,
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
