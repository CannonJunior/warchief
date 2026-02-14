import '../../models/goal.dart';
import '../../models/ai_chat_message.dart';
import '../state/game_state.dart';
import '../state/goals_config.dart';

/// Goal System — Tracks goal progress, processes game events, checks completion.
///
/// All goal logic is deterministic. The LLM (Warrior Spirit) only handles
/// narrative framing — never game-critical decisions.
///
/// Usage:
/// ```dart
/// GoalSystem.processEvent(gameState, 'enemy_killed',
///   metadata: {'enemy_type': 'gnoll_marauder'});
/// ```
class GoalSystem {
  GoalSystem._();

  /// Process a game event and update all active goals.
  ///
  /// Called by combat, building, movement, and other systems when
  /// something trackable happens. Checks all active goals against
  /// the event and updates progress accordingly.
  static void processEvent(
    GameState gameState,
    String eventId, {
    Map<String, dynamic>? metadata,
  }) {
    for (final goal in gameState.goals) {
      if (goal.status != GoalStatus.active) continue;
      if (goal.definition.trackingEventId != eventId) continue;

      switch (goal.definition.trackingType) {
        case GoalTrackingType.counter:
          goal.currentValue++;
          break;
        case GoalTrackingType.threshold:
          final value = metadata?['value'] as int? ?? 0;
          if (value > goal.currentValue) goal.currentValue = value;
          break;
        case GoalTrackingType.mastery:
          final streak = metadata?['streak'] as int? ?? 0;
          if (streak > goal.currentValue) goal.currentValue = streak;
          break;
        case GoalTrackingType.discovery:
        case GoalTrackingType.narrative:
          goal.currentValue = 1;
          break;
      }

      // Check completion
      if (goal.isComplete && goal.status == GoalStatus.active) {
        goal.status = GoalStatus.completed;
        goal.completedAt = DateTime.now();
        _onGoalCompleted(gameState, goal);
      }
    }
  }

  /// Called when a goal is completed — adds Spirit reflection message.
  static void _onGoalCompleted(GameState gameState, Goal goal) {
    final reflection = goal.definition.spiritReflection ??
        'Another step on the path, Warchief.';
    gameState.warriorSpiritMessages.add(AIChatMessage(
      text: '${goal.definition.name} complete: $reflection',
      isInput: false,
    ));
    print('[GOAL] Completed: ${goal.definition.name}');
  }

  /// Check which goals could be offered based on current game state.
  ///
  /// Returns definitions for goals the player doesn't already have
  /// (active, completed, or abandoned).
  static List<GoalDefinition> checkForNewGoals(GameState gameState) {
    final config = globalGoalsConfig;
    if (config == null) return [];

    final existingIds = gameState.goals.map((g) => g.definition.id).toSet();
    final available = <GoalDefinition>[];

    for (final id in config.allGoalIds) {
      if (existingIds.contains(id)) continue;
      final json = config.getGoalDefinition(id);
      if (json == null) continue;
      available.add(GoalDefinition.fromJson(id, json));
    }

    return available;
  }

  /// Create and return a new active goal from a definition.
  static Goal acceptGoal(
    GoalDefinition definition, {
    GoalSource? source,
    String? sourceNpcName,
  }) {
    return Goal(
      instanceId: '${definition.id}_${DateTime.now().millisecondsSinceEpoch}',
      definition: definition,
      status: GoalStatus.active,
      source: source ?? definition.defaultSource,
      sourceNpcName: sourceNpcName,
      currentValue: 0,
      acceptedAt: DateTime.now(),
    );
  }

  /// Abandon a goal (player chose to drop it).
  static void abandonGoal(Goal goal) {
    goal.status = GoalStatus.abandoned;
    print('[GOAL] Abandoned: ${goal.definition.name}');
  }
}
