import 'package:flutter/foundation.dart' show debugPrint;
import '../../ai/ollama_client.dart';
import '../../models/console_log_entry.dart';
import '../../models/goal.dart';
import '../../models/ai_chat_message.dart';
import '../state/game_state.dart';
import '../state/goals_config.dart';
import '../systems/goal_system.dart';
import 'spirit_knowledge_base.dart';

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

  /// Persistent conversation history for the /api/chat endpoint.
  /// Capped at [_maxHistory] messages to prevent unbounded context growth.
  static final List<Map<String, dynamic>> _chatHistory = [];
  static const int _maxHistory = 20;

  /// Initialize — check Ollama availability and start loading project docs.
  static Future<void> init() async {
    _isAvailable = await _client.isAvailable();
    _checkAccumulator = 0;
    _greetingSent = false;
    _greetingTimer = 0;
    _chatHistory.clear();
    // Reason: load docs in the background so they're ready before the first
    // player message without blocking the game startup sequence.
    SpiritKnowledgeBase.initialize();
    debugPrint('[WARRIOR SPIRIT] Ollama available: $_isAvailable');
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
        debugPrint('[WARRIOR SPIRIT] Greeting sent');
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
    debugPrint('[WARRIOR SPIRIT] Suggested goal: ${suggestion.name}');
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
        model: globalGoalsConfig?.warriorSpiritModel ?? 'qwwen3.5:2b',
        prompt: prompt,
        temperature: globalGoalsConfig?.warriorSpiritTemperature ?? 0.8,
      );

      // Fallback if LLM returns garbage
      if (response == 'HOLD_POSITION' || response.length < 10) {
        return _fallbackSuggestion(goal);
      }
      return response;
    } catch (e) {
      debugPrint('[WARRIOR SPIRIT] LLM error: $e');
      return _fallbackSuggestion(goal);
    }
  }

  /// Player sends a message to the Warrior Spirit.
  ///
  /// Uses the Ollama /api/chat endpoint so the full project documentation
  /// (loaded by [SpiritKnowledgeBase]) is in the system prompt every turn,
  /// and the conversation history is maintained across messages.
  static Future<String> chat(
    GameState gameState,
    String playerMessage,
  ) async {
    if (!_isAvailable) {
      return 'The spirit is silent. (Ollama unavailable)';
    }

    // Add the user's message to the rolling history.
    _chatHistory.add({'role': 'user', 'content': playerMessage});
    // Reason: keep the history bounded so it doesn't grow the context
    // beyond the model's num_ctx budget over a long session.
    if (_chatHistory.length > _maxHistory) {
      _chatHistory.removeRange(0, _chatHistory.length - _maxHistory);
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _buildChatSystemPrompt(gameState)},
      ..._chatHistory,
    ];

    final model = globalGoalsConfig?.warriorSpiritModel ?? 'qwwen3.5:2b';
    try {
      final reply = await _client.chat(
        model: model,
        messages: messages,
        temperature: globalGoalsConfig?.warriorSpiritTemperature ?? 0.8,
      );
      // Reason: OllamaClient returns 'HTTP <code>: <body>' on non-200 responses
      // so we can surface the actual Ollama error to the player.
      if (reply.isEmpty || reply.startsWith('HTTP ')) {
        _chatHistory.removeLast();
        final detail = reply.isNotEmpty ? reply : 'empty response';
        gameState.addConsoleLog('[Spirit] Ollama error ($model): $detail', level: ConsoleLogLevel.error);
        return 'The spirit flickers. ($detail — verify model name in Settings > AI)';
      }
      _chatHistory.add({'role': 'assistant', 'content': reply});
      return reply;
    } catch (e) {
      debugPrint('[WARRIOR SPIRIT] Chat error: $e');
      _chatHistory.removeLast();
      gameState.addConsoleLog('[Spirit] Chat error: $e', level: ConsoleLogLevel.error);
      return 'The spirit flickers. ($e)';
    }
  }

  /// Player sends a message — streaming version.
  ///
  /// Yields content tokens as they arrive so the chat panel can update
  /// the UI incrementally rather than waiting for the full response.
  /// History management mirrors [chat]: the user message is prepended
  /// before the call and the completed reply is appended on stream end.
  static Stream<String> chatStream(
    GameState gameState,
    String playerMessage,
  ) async* {
    if (!_isAvailable) {
      yield 'The spirit is silent. (Ollama unavailable)';
      return;
    }

    _chatHistory.add({'role': 'user', 'content': playerMessage});
    if (_chatHistory.length > _maxHistory) {
      _chatHistory.removeRange(0, _chatHistory.length - _maxHistory);
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _buildChatSystemPrompt(gameState)},
      ..._chatHistory,
    ];

    final buffer = StringBuffer();
    bool hadContent = false;

    final model = globalGoalsConfig?.warriorSpiritModel ?? 'qwwen3.5:2b';
    try {
      await for (final chunk in _client.chatStream(
        model: model,
        messages: messages,
        temperature: globalGoalsConfig?.warriorSpiritTemperature ?? 0.8,
      )) {
        buffer.write(chunk);
        hadContent = true;
        yield chunk;
      }

      if (hadContent) {
        _chatHistory.add({'role': 'assistant', 'content': buffer.toString()});
      } else {
        // Ollama returned nothing — remove the user turn so history stays clean.
        _chatHistory.removeLast();
      }
    } catch (e) {
      debugPrint('[WARRIOR SPIRIT] chatStream error: $e');
      _chatHistory.removeLast();
      gameState.addConsoleLog('[Spirit] chatStream error: $e', level: ConsoleLogLevel.error);
      yield 'The spirit flickers. ($e)';
    }
  }

  /// Build the system prompt: personality + live game state + all project docs.
  ///
  /// Docs are appended only after [SpiritKnowledgeBase] has finished loading;
  /// early calls fall back to personality + state only.
  static String _buildChatSystemPrompt(GameState gameState) {
    final personality = globalGoalsConfig?.warriorSpiritPersonality ??
        'You are an ancient warrior spirit.';

    final activeGoals = gameState.activeGoals
        .map((g) => '- ${g.definition.name}: ${(g.progress * 100).toInt()}%')
        .join('\n');
    final goalsSection =
        activeGoals.isNotEmpty ? '\nActive goals:\n$activeGoals' : '';

    final docsSection = SpiritKnowledgeBase.isLoaded
        ? '\n\n=== PROJECT DOCUMENTATION ===\n\n${SpiritKnowledgeBase.content}'
        : '';

    return '$personality\n\nYou are also the keeper of knowledge about the '
        'Warchief codebase. When the developer asks about the code, '
        'architecture, or systems, answer accurately from the documentation. '
        'Be concise.\n\n'
        'Current game state: ${_describeState(gameState)}'
        '$goalsSection'
        '$docsSection';
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
