import '../../ai/ollama_client.dart';
import '../../models/goal.dart';
import '../../models/ai_chat_message.dart';
import '../state/game_state.dart';
import '../state/goals_config.dart';
import '../systems/goal_system.dart';

/// Warrior Spirit — Ollama-powered narrative advisor for the goals system.
///
/// Hybrid architecture:
/// - **Deterministic**: Goal selection, event tracking, completion detection
/// - **LLM (Ollama)**: Narrative framing, reflective dialogue, free-form chat
/// - **Fallback**: Static text when Ollama is unavailable (no crashes)
///
/// The Warrior Spirit periodically checks if new goals should be suggested,
/// and provides narrative framing for suggestions and completions.
class WarriorSpirit {
  static final OllamaClient _client = OllamaClient();
  static bool _isAvailable = false;
  static double _checkAccumulator = 0;
  static bool _greetingSent = false;
  static double _greetingTimer = 0;

  /// Initialize — check Ollama availability at startup.
  static Future<void> init() async {
    _isAvailable = await _client.isAvailable();
    _checkAccumulator = 0;
    _greetingSent = false;
    _greetingTimer = 0;
    print('[WARRIOR SPIRIT] Ollama available: $_isAvailable');
  }

  /// Periodic update — send greeting and check if we should suggest a goal.
  ///
  /// Called every frame from the game loop. Accumulates dt and only
  /// acts when the check interval has elapsed.
  static Future<void> update(GameState gameState, double dt) async {
    // Send initial greeting after 10 seconds
    if (!_greetingSent) {
      _greetingTimer += dt;
      if (_greetingTimer >= 10.0) {
        _greetingSent = true;
        final greeting = globalGoalsConfig?.warriorSpiritGreeting ??
            'The flame stirs, Warchief.';
        gameState.warriorSpiritMessages.add(AIChatMessage(
          text: greeting,
          isInput: false,
        ));
        print('[WARRIOR SPIRIT] Greeting sent');
      }
    }

    // Periodic goal suggestion check
    _checkAccumulator += dt;
    final interval = globalGoalsConfig?.goalCheckInterval ?? 120.0;
    if (_checkAccumulator < interval) return;
    _checkAccumulator = 0;

    final maxActive = globalGoalsConfig?.maxActiveGoals ?? 5;
    if (gameState.activeGoals.length >= maxActive) return;

    // Don't suggest if there's already a pending suggestion
    if (gameState.pendingSpiritGoal != null) return;

    final available = GoalSystem.checkForNewGoals(gameState);
    if (available.isEmpty) return;

    // Deterministic goal selection based on game state
    final suggestion = _selectGoalToSuggest(gameState, available);
    if (suggestion == null) return;

    // Use LLM to frame the suggestion narratively (or fallback)
    final narrative = await _narrateGoalSuggestion(gameState, suggestion);

    gameState.warriorSpiritMessages.add(AIChatMessage(
      text: narrative,
      isInput: false,
    ));
    gameState.pendingSpiritGoal = suggestion;
    print('[WARRIOR SPIRIT] Suggested goal: ${suggestion.name}');
  }

  /// Deterministic goal selection based on current game state.
  ///
  /// Priority: combat goals if enemies present, mastery if practicing,
  /// exploration if exploring, community if near buildings.
  static GoalDefinition? _selectGoalToSuggest(
    GameState gameState,
    List<GoalDefinition> available,
  ) {
    // Prioritize combat goals if enemies are alive
    if (gameState.aliveMinions.isNotEmpty) {
      final combat = available
          .where((g) => g.category == GoalCategory.combat)
          .toList();
      if (combat.isNotEmpty) return combat.first;
    }

    // Prioritize mastery goals if player is flying
    if (gameState.isFlying) {
      final mastery = available
          .where((g) => g.category == GoalCategory.mastery)
          .toList();
      if (mastery.isNotEmpty) return mastery.first;
    }

    // Prioritize community goals if near buildings
    if (gameState.buildings.isNotEmpty) {
      final community = available
          .where((g) => g.category == GoalCategory.community)
          .toList();
      if (community.isNotEmpty) return community.first;
    }

    // Default: return first available goal
    return available.first;
  }

  /// Use LLM to narratively frame a goal suggestion.
  static Future<String> _narrateGoalSuggestion(
    GameState gameState,
    GoalDefinition goal,
  ) async {
    if (!_isAvailable) {
      return _fallbackSuggestion(goal);
    }

    final personality = globalGoalsConfig?.warriorSpiritPersonality ??
        'You are an ancient warrior spirit.';
    final prompt = '''$personality

The warchief is ${_describeState(gameState)}.

Suggest this goal to them in 1-2 sentences, in character:
Goal: ${goal.name} — ${goal.description}

Speak as the Warrior Spirit. Be brief, evocative, not flowery.''';

    try {
      final response = await _client.generate(
        model: globalGoalsConfig?.warriorSpiritModel ?? 'llama3.2',
        prompt: prompt,
        temperature: globalGoalsConfig?.warriorSpiritTemperature ?? 0.8,
      );

      // Fallback if LLM returns garbage
      if (response == 'HOLD_POSITION' || response.length < 10) {
        return _fallbackSuggestion(goal);
      }
      return response;
    } catch (e) {
      print('[WARRIOR SPIRIT] LLM error: $e');
      return _fallbackSuggestion(goal);
    }
  }

  /// Player sends a message to the Warrior Spirit.
  ///
  /// Returns the Spirit's response (LLM-generated or fallback).
  static Future<String> chat(
    GameState gameState,
    String playerMessage,
  ) async {
    if (!_isAvailable) {
      return 'The spirit is silent. (Ollama unavailable)';
    }

    final personality = globalGoalsConfig?.warriorSpiritPersonality ??
        'You are an ancient warrior spirit.';
    final activeGoals = gameState.activeGoals
        .map((g) =>
            '- ${g.definition.name}: ${(g.progress * 100).toInt()}%')
        .join('\n');

    final goalsSection = activeGoals.isNotEmpty
        ? 'Active goals:\n$activeGoals'
        : 'No active goals.';

    final prompt = '''$personality

Current state: ${_describeState(gameState)}
$goalsSection

The warchief says: "$playerMessage"

Respond as the Warrior Spirit in 1-3 sentences. Be wise, brief, and in character.''';

    try {
      return await _client.generate(
        model: globalGoalsConfig?.warriorSpiritModel ?? 'llama3.2',
        prompt: prompt,
        temperature: globalGoalsConfig?.warriorSpiritTemperature ?? 0.8,
      );
    } catch (e) {
      print('[WARRIOR SPIRIT] Chat error: $e');
      return 'The spirit flickers. Try again.';
    }
  }

  /// Describe current game state for LLM context.
  static String _describeState(GameState gameState) {
    final hp = gameState.playerHealth.toInt();
    final maxHp = gameState.playerMaxHealth.toInt();
    final enemies = gameState.aliveMinions.length;
    final allies = gameState.allies.where((a) => a.health > 0).length;
    final flying = gameState.isFlying ? ', flying' : '';
    return 'health $hp/$maxHp, $enemies enemies alive, $allies allies$flying';
  }

  /// Fallback suggestion when Ollama is unavailable.
  static String _fallbackSuggestion(GoalDefinition goal) {
    switch (goal.defaultSource) {
      case GoalSource.warriorSpirit:
        return 'I sense a challenge ahead: ${goal.description}';
      case GoalSource.villageChief:
        return 'The village chief asks: ${goal.description}';
      case GoalSource.villager:
        return 'A villager whispers: ${goal.description}';
      case GoalSource.adversary:
        return 'Your enemy taunts: "${goal.description}"';
      case GoalSource.selfDiscovery:
        return 'Something stirs within you... ${goal.description}';
    }
  }
}
