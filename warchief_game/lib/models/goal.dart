/// Where a goal comes from — determines narrative framing.
enum GoalSource {
  warriorSpirit,  // Internal advisor
  villageChief,   // Named NPC leaders
  villager,       // Common folk requests
  adversary,      // Enemy taunts/challenges
  selfDiscovery,  // Player actions trigger awareness
}

/// How a goal measures completion.
enum GoalTrackingType {
  counter,    // "Defeat 5 gnolls" -> count kills
  threshold,  // "Reach 50 white mana" -> check max value
  discovery,  // "Find the ley line nexus" -> visit location
  mastery,    // "Land 10 consecutive sword strikes" -> streak tracking
  narrative,  // "Survive a derecho" -> flag
}

/// Goal lifecycle state.
enum GoalStatus {
  available,  // Offered but not accepted
  active,     // Player accepted, tracking progress
  completed,  // Conditions met, awaiting reflection
  reflected,  // Player discussed with Warrior Spirit (optional)
  abandoned,  // Player chose to drop it
}

/// Goal category for UI grouping and color coding.
enum GoalCategory {
  combat,       // Fighting-related
  exploration,  // Discovering places/things
  mastery,      // Skill improvement
  community,    // Building/ally/village related
  spirit,       // Warrior Spirit philosophical goals
}

/// Parse a [GoalSource] from a JSON string.
GoalSource parseGoalSource(String value) {
  switch (value) {
    case 'warriorSpirit': return GoalSource.warriorSpirit;
    case 'villageChief': return GoalSource.villageChief;
    case 'villager': return GoalSource.villager;
    case 'adversary': return GoalSource.adversary;
    case 'selfDiscovery': return GoalSource.selfDiscovery;
    default: return GoalSource.warriorSpirit;
  }
}

/// Parse a [GoalTrackingType] from a JSON string.
GoalTrackingType parseGoalTrackingType(String value) {
  switch (value) {
    case 'counter': return GoalTrackingType.counter;
    case 'threshold': return GoalTrackingType.threshold;
    case 'discovery': return GoalTrackingType.discovery;
    case 'mastery': return GoalTrackingType.mastery;
    case 'narrative': return GoalTrackingType.narrative;
    default: return GoalTrackingType.counter;
  }
}

/// Parse a [GoalCategory] from a JSON string.
GoalCategory parseGoalCategory(String value) {
  switch (value) {
    case 'combat': return GoalCategory.combat;
    case 'exploration': return GoalCategory.exploration;
    case 'mastery': return GoalCategory.mastery;
    case 'community': return GoalCategory.community;
    case 'spirit': return GoalCategory.spirit;
    default: return GoalCategory.combat;
  }
}

/// Definition of a goal type (from config JSON).
///
/// Immutable template that describes what a goal is, how it's tracked,
/// and what happens on completion. Instances of [Goal] reference a
/// definition to know their rules.
class GoalDefinition {
  final String id;
  final String name;
  final String description;
  final GoalCategory category;
  final GoalTrackingType trackingType;
  final GoalSource defaultSource;
  final String trackingEventId;
  final int targetValue;
  final String? spiritReflection;
  final Map<String, dynamic> rewards;

  const GoalDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.trackingType,
    required this.defaultSource,
    required this.trackingEventId,
    required this.targetValue,
    this.spiritReflection,
    this.rewards = const {},
  });

  /// Parse a [GoalDefinition] from a JSON map and its config ID.
  factory GoalDefinition.fromJson(String id, Map<String, dynamic> json) {
    return GoalDefinition(
      id: id,
      name: json['name'] as String? ?? id,
      description: json['description'] as String? ?? '',
      category: parseGoalCategory(json['category'] as String? ?? 'combat'),
      trackingType: parseGoalTrackingType(
          json['tracking_type'] as String? ?? 'counter'),
      defaultSource: parseGoalSource(
          json['default_source'] as String? ?? 'warriorSpirit'),
      trackingEventId: json['tracking_event'] as String? ?? '',
      targetValue: (json['target_value'] as num?)?.toInt() ?? 1,
      spiritReflection: json['spirit_reflection'] as String?,
      rewards: json['rewards'] is Map
          ? Map<String, dynamic>.from(json['rewards'] as Map)
          : {},
    );
  }
}

/// Runtime goal instance — a player's active/completed/abandoned goal.
///
/// Mutable state that tracks the player's progress toward a
/// [GoalDefinition]. Each goal instance has a unique ID, a source
/// (who offered it), and current progress.
class Goal {
  final String instanceId;
  final GoalDefinition definition;
  GoalStatus status;
  GoalSource source;
  String? sourceNpcName;
  int currentValue;
  DateTime acceptedAt;
  DateTime? completedAt;
  String? completionNarrative;

  Goal({
    required this.instanceId,
    required this.definition,
    required this.status,
    required this.source,
    this.sourceNpcName,
    required this.currentValue,
    required this.acceptedAt,
    this.completedAt,
    this.completionNarrative,
  });

  /// Progress as a fraction (0.0 to 1.0).
  double get progress =>
      definition.targetValue > 0
          ? (currentValue / definition.targetValue).clamp(0.0, 1.0)
          : 0.0;

  /// Whether the goal's target has been met.
  bool get isComplete => currentValue >= definition.targetValue;
}
