# AI Integration Reference

## OllamaClient API

**File**: `lib/ai/ollama_client.dart`

```dart
class OllamaClient {
  static const String baseUrl = 'http://localhost:11434';
  static const Duration timeout = Duration(seconds: 5);

  Future<String> generate({
    required String model,
    required String prompt,
    double temperature = 0.7,
  }) async { ... }

  Future<bool> isAvailable() async { ... }
}
```

- `generate()` returns the LLM response text, or `'HOLD_POSITION'` on failure
- `isAvailable()` checks if Ollama server responds (2-second timeout)
- All calls are fire-and-forget safe — failures return fallback strings

## MCPTools Patterns

**File**: `lib/game3d/ai/mcp_tools.dart`

- `MCPToolResponse` — Structured response from MCP tool calls
- `AIContext` — Game state context for AI decision-making
- Tactical vs strategic context levels

## AIChatPanel UI

**File**: `lib/game3d/ui/ai_chat_panel.dart`

- Displays `List<AIChatMessage>` in a scrolling panel
- Messages styled with arrows: `->` (input/player) and `<-` (output/AI)
- `reverse: true` ListView so latest messages appear at bottom

## AIChatMessage Model

**File**: `lib/models/ai_chat_message.dart`

```dart
class AIChatMessage {
  final String text;
  final bool isInput;  // true = player message, false = AI response
  final DateTime timestamp;
}
```

## Warrior Spirit Integration

**File**: `lib/game3d/ai/warrior_spirit.dart`

The Warrior Spirit is a hybrid deterministic + LLM system:
- **Deterministic**: Goal selection, event tracking, completion detection
- **LLM (Ollama)**: Narrative framing, reflective dialogue, free-form chat
- **Fallback**: Static text when Ollama is unavailable

### Key methods:
- `WarriorSpirit.init()` — Check Ollama availability at startup
- `WarriorSpirit.update(gameState, dt)` — Periodic goal suggestion check
- `WarriorSpirit.chat(gameState, playerMessage)` — Player conversation
- `_narrateGoalSuggestion()` — LLM-generated goal framing
- `_fallbackSuggestion()` — Static text fallback

### Config-driven values (from `goals_config.json`):
- `warrior_spirit.model` — Ollama model name (default: "llama3.2")
- `warrior_spirit.temperature` — Creativity level (default: 0.8)
- `warrior_spirit.personality` — System prompt base text
- `warrior_spirit.goal_check_interval_seconds` — Seconds between auto-suggestions
- `warrior_spirit.max_active_goals` — Cap on simultaneous active goals

## Adding New AI-Driven Features

1. Create a new file in `lib/game3d/ai/` for the feature logic
2. Use `OllamaClient.generate()` for LLM calls with appropriate prompt
3. Always provide a fallback for when Ollama is unavailable
4. Store messages in `List<AIChatMessage>` on GameState
5. Create a UI panel in `lib/game3d/ui/` following the panel patterns
6. Wire keyboard toggle in `game3d_widget.dart._onKeyEvent()`
7. Add config values to a JSON file in `assets/data/`
8. Never put LLM in the critical path — all game logic must be deterministic
