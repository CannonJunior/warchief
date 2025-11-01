# Ally and Monster AI System Documentation

## Overview
This document describes the AI system architecture for both Ally NPCs and Monster enemies in the Warchief game, including Ollama LLM integration for intelligent decision-making.

## System Architecture

### 1. Character Types

#### **Player Character**
- **Health**: 100 HP
- **Abilities**:
  - Ability 1 (Q/1): Fireball - Ranged projectile attack
  - Ability 2 (E/2): Shield - Defensive buff (placeholder)
  - Ability 3 (R/3): Heal - Restores 20-30 HP
- **Control**: Manual keyboard/mouse input
- **Size**: 1.0 (base scale)
- **Color**: Blue (0.3, 0.5, 0.8)

#### **Ally NPCs**
- **Health**: 50 HP
- **Abilities**: ONE random ability from player's set
  - 33% chance: Fireball (ranged attack)
  - 33% chance: Shield (defensive)
  - 33% chance: Heal (restoration)
- **Control**: AI + Ollama LLM
- **Size**: 0.8 (80% of player size)
- **Color**: Brighter blue (0.4, 0.7, 1.0) - 30% brighter than player
- **Max Count**: Unlimited (managed by add/remove buttons)

#### **Monster Enemy**
- **Health**: 100 HP
- **Abilities**:
  - M1: Dark Strike - Melee attack (< 5.0 units)
  - M2: Shadow Bolt - Ranged purple projectile (4.0-12.0 units)
  - M3: Dark Healing - Restores 25 HP when health < 50
- **Control**: AI + Ollama LLM
- **Size**: 1.2 (120% of player size)
- **Color**: Purple (0.5, 0.2, 0.5)

---

## AI Decision-Making System

### Decision Loop Architecture

```dart
class AIEntity {
  double aiTimer = 0.0;
  double aiInterval; // How often to "think"

  void update(double dt) {
    aiTimer += dt;

    if (aiTimer >= aiInterval) {
      aiTimer = 0.0;
      makeDecision(); // Call Ollama or rule-based AI
    }
  }
}
```

### Decision Intervals
- **Monster**: 2.0 seconds (aggressive, fast decisions)
- **Allies**: 3.0 seconds (cooperative, measured decisions)

---

## Ollama LLM Integration

### Setup Requirements

1. **Install Ollama**: https://ollama.ai/download
2. **Pull Models**:
   ```bash
   ollama pull llama2  # For allies (cooperative)
   ollama pull mistral # For monster (aggressive)
   ```
3. **Start Ollama Server**:
   ```bash
   ollama serve  # Runs on http://localhost:11434
   ```

### API Endpoint Structure

```dart
// POST request to Ollama
final url = 'http://localhost:11434/api/generate';
final headers = {'Content-Type': 'application/json'};
final body = json.encode({
  'model': 'llama2',  // or 'mistral'
  'prompt': constructPrompt(gameState),
  'stream': false,
});
```

---

## Ollama Prompts

### Ally Prompt Template

```dart
String constructAllyPrompt(AllyGameState state) {
  return '''
You are a friendly AI ally in a 3D combat game. Make tactical decisions to help your team.

CURRENT SITUATION:
- Your Health: ${state.allyHealth}/${state.allyMaxHealth}
- Your Position: (${state.allyX}, ${state.allyZ})
- Your Ability: ${state.abilityName}
- Ability Cooldown: ${state.abilityCooldown > 0 ? '${state.abilityCooldown.toStringAsFixed(1)}s' : 'READY'}

PLAYER (Your Leader):
- Health: ${state.playerHealth}/${state.playerMaxHealth}
- Position: (${state.playerX}, ${state.playerZ})
- Distance: ${state.distanceToPlayer.toStringAsFixed(1)} units

MONSTER (Enemy):
- Health: ${state.monsterHealth}/${state.monsterMaxHealth}
- Position: (${state.monsterX}, ${state.monsterZ})
- Distance: ${state.distanceToMonster.toStringAsFixed(1)} units

OTHER ALLIES:
${state.otherAllies.map((a) => '- Ally ${a.id}: ${a.health}HP, ${a.abilityName}').join('\n')}

YOUR ABILITY:
${_getAbilityDescription(state.abilityIndex)}

TACTICAL CONSIDERATIONS:
- Stay near player (optimal range: 3-8 units)
- Support player against monster
- Use abilities when cooldown is ready
- Avoid getting too close to monster (danger < 4 units)
- Prioritize healing player if their health < 40%

DECISION OPTIONS:
1. MOVE_TO_PLAYER - Move closer to player
2. MOVE_TO_MONSTER - Move toward monster (offensive)
3. RETREAT - Move away from danger
4. USE_ABILITY - Use your ${state.abilityName} ability
5. HOLD_POSITION - Stay where you are

Respond with ONLY ONE of these exact commands: MOVE_TO_PLAYER, MOVE_TO_MONSTER, RETREAT, USE_ABILITY, or HOLD_POSITION
''';
}
```

### Monster Prompt Template

```dart
String constructMonsterPrompt(MonsterGameState state) {
  return '''
You are an aggressive AI monster in a 3D combat game. Your goal is to defeat the player and their allies.

CURRENT SITUATION:
- Your Health: ${state.monsterHealth}/${state.monsterMaxHealth}
- Your Position: (${state.monsterX}, ${state.monsterZ})

YOUR ABILITIES:
- M1 (Dark Strike): Melee attack when < 5 units from target
- M2 (Shadow Bolt): Ranged projectile, best at 4-12 units
- M3 (Dark Healing): Restore 25 HP, use when health < 50%

COOLDOWNS:
- M1: ${state.ability1Cooldown > 0 ? '${state.ability1Cooldown.toStringAsFixed(1)}s' : 'READY'}
- M2: ${state.ability2Cooldown > 0 ? '${state.ability2Cooldown.toStringAsFixed(1)}s' : 'READY'}
- M3: ${state.ability3Cooldown > 0 ? '${state.ability3Cooldown.toStringAsFixed(1)}s' : 'READY'}

PLAYER (Primary Target):
- Health: ${state.playerHealth}/${state.playerMaxHealth}
- Position: (${state.playerX}, ${state.playerZ})
- Distance: ${state.distanceToPlayer.toStringAsFixed(1)} units

ALLIES (Secondary Targets):
${state.allies.map((a) => '- Ally ${a.id}: ${a.health}HP, Distance: ${a.distance.toStringAsFixed(1)} units').join('\n')}

TACTICAL ANALYSIS:
- Optimal Range: 4-8 units (for Shadow Bolt)
- Melee Range: < 5 units (for Dark Strike)
- Healing Threshold: < 50% health
- Total Threats: ${state.allies.length + 1} enemies

DECISION OPTIONS:
1. MOVE_TOWARD_PLAYER - Close distance with player
2. RETREAT - Create distance (< 3 units is too close)
3. USE_ABILITY_1 - Dark Strike (melee)
4. USE_ABILITY_2 - Shadow Bolt (ranged)
5. USE_ABILITY_3 - Dark Healing (self-heal)
6. SWITCH_TARGET_ALLY_X - Attack ally X instead

Respond with ONLY ONE command: MOVE_TOWARD_PLAYER, RETREAT, USE_ABILITY_1, USE_ABILITY_2, USE_ABILITY_3, or SWITCH_TARGET_ALLY_[index]
''';
}
```

---

## Implementation Code Structure

### Ollama HTTP Client (Dart)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaClient {
  static const String baseUrl = 'http://localhost:11434';

  Future<String> generate({
    required String model,
    required String prompt,
    double temperature = 0.7,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': model,
          'prompt': prompt,
          'stream': false,
          'temperature': temperature,
        }),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] as String;
      } else {
        print('Ollama error: ${response.statusCode}');
        return 'HOLD_POSITION'; // Fallback
      }
    } catch (e) {
      print('Ollama connection error: $e');
      return 'HOLD_POSITION'; // Fallback
    }
  }
}
```

### AI Decision Handler

```dart
class AIDecisionHandler {
  final OllamaClient ollama = OllamaClient();

  Future<void> makeAllyDecision(Ally ally, GameState state) async {
    final prompt = constructAllyPrompt(
      AllyGameState.from(ally, state)
    );

    final decision = await ollama.generate(
      model: 'llama2',
      prompt: prompt,
      temperature: 0.7, // Some creativity
    );

    executeAllyDecision(ally, decision, state);
  }

  Future<void> makeMonsterDecision(Monster monster, GameState state) async {
    final prompt = constructMonsterPrompt(
      MonsterGameState.from(monster, state)
    );

    final decision = await ollama.generate(
      model: 'mistral',
      prompt: prompt,
      temperature: 0.8, // More aggressive
    );

    executeMonsterDecision(monster, decision, state);
  }

  void executeAllyDecision(Ally ally, String decision, GameState state) {
    final command = decision.trim().toUpperCase();

    if (command.contains('MOVE_TO_PLAYER')) {
      moveTowardTarget(ally, state.playerPosition);
    } else if (command.contains('MOVE_TO_MONSTER')) {
      moveTowardTarget(ally, state.monsterPosition);
    } else if (command.contains('RETREAT')) {
      moveAwayFromDanger(ally, state);
    } else if (command.contains('USE_ABILITY')) {
      activateAllyAbility(ally, state);
    }
    // HOLD_POSITION - do nothing
  }

  void executeMonsterDecision(Monster monster, String decision, GameState state) {
    final command = decision.trim().toUpperCase();

    if (command.contains('MOVE_TOWARD_PLAYER')) {
      moveTowardTarget(monster, state.playerPosition);
    } else if (command.contains('RETREAT')) {
      moveAwayFromTarget(monster, state.playerPosition);
    } else if (command.contains('USE_ABILITY_1')) {
      activateMonsterAbility1(monster);
    } else if (command.contains('USE_ABILITY_2')) {
      activateMonsterAbility2(monster);
    } else if (command.contains('USE_ABILITY_3')) {
      activateMonsterAbility3(monster);
    }
  }
}
```

---

## Model Context Protocol (MCP)

### What is MCP?

MCP is a standardized protocol for LLMs to interact with external tools and data sources. In our game context:

1. **Game State Tool**: Provides real-time game state to LLM
2. **Action Executor**: Translates LLM decisions into game actions
3. **Observation System**: Feeds game events back to LLM

### MCP Implementation (Conceptual)

```json
{
  "mcp_server": {
    "name": "warchief-game-ai",
    "version": "1.0",
    "tools": [
      {
        "name": "get_game_state",
        "description": "Get current game state for AI decision",
        "parameters": {
          "entity_id": "string",
          "entity_type": "ally|monster"
        }
      },
      {
        "name": "execute_action",
        "description": "Execute game action",
        "parameters": {
          "entity_id": "string",
          "action": "MOVE_TO_PLAYER|RETREAT|USE_ABILITY|etc"
        }
      },
      {
        "name": "get_nearby_entities",
        "description": "Query entities within radius",
        "parameters": {
          "position": {"x": "number", "z": "number"},
          "radius": "number"
        }
      }
    ]
  }
}
```

---

## Optimization Strategies

### 1. Caching & Performance

```dart
class AIOptimizer {
  // Cache recent decisions to avoid redundant LLM calls
  Map<String, CachedDecision> decisionCache = {};

  Future<String> getDecisionWithCache(
    String entityId,
    String prompt,
    GameState state,
  ) async {
    final cacheKey = '${entityId}_${state.hashCode}';
    final cached = decisionCache[cacheKey];

    // Use cached decision if game state similar and recent
    if (cached != null &&
        DateTime.now().difference(cached.timestamp).inSeconds < 2) {
      return cached.decision;
    }

    final decision = await ollama.generate(
      model: getModelForEntity(entityId),
      prompt: prompt,
    );

    decisionCache[cacheKey] = CachedDecision(
      decision: decision,
      timestamp: DateTime.now(),
    );

    return decision;
  }
}
```

### 2. Fallback Rule-Based AI

When Ollama is unavailable or slow, use simple rules:

```dart
String fallbackAllyDecision(Ally ally, GameState state) {
  // Emergency healing
  if (state.playerHealth < 30 && ally.abilityIndex == 2) {
    return 'USE_ABILITY';
  }

  // Stay near player
  if (state.distanceToPlayer > 8.0) {
    return 'MOVE_TO_PLAYER';
  }

  // Attack if ability ready and monster close
  if (ally.abilityCooldown == 0 && state.distanceToMonster < 10.0) {
    return 'USE_ABILITY';
  }

  return 'HOLD_POSITION';
}

String fallbackMonsterDecision(Monster monster, GameState state) {
  // Heal if low health
  if (monster.health < 50 && monster.ability3Cooldown == 0) {
    return 'USE_ABILITY_3';
  }

  // Maintain optimal range
  if (state.distanceToPlayer > 8.0) {
    return 'MOVE_TOWARD_PLAYER';
  } else if (state.distanceToPlayer < 3.0) {
    return 'RETREAT';
  }

  // Use ranged attack at medium range
  if (state.distanceToPlayer < 12.0 && monster.ability2Cooldown == 0) {
    return 'USE_ABILITY_2';
  }

  return 'HOLD_POSITION';
}
```

### 3. Prompt Optimization

**Current Prompt Size**: ~500-800 tokens
**Optimized Approach**:
- Use shorter variable names in prompts
- Remove redundant explanations
- Use abbreviations: HP instead of "Health Points"
- Compress position data: `P(5,3)` instead of `Position: (5.2, 3.7)`

### 4. Model Selection

- **Llama2** (Allies): 7B parameter model
  - Faster inference (~1-2 seconds)
  - Good at cooperative tactics
  - Less memory usage

- **Mistral** (Monster): 7B parameter model
  - Slightly more aggressive
  - Better at multi-target decisions
  - Good strategic planning

**Alternative**: Use `llama2:7b-chat-q4_0` (quantized) for even faster inference

---

## Current Implementation Status

### ✅ Implemented
- Ally class structure
- Monster AI with basic rule-based decisions
- Monster abilities (M1, M2, M3)
- Cooldown system
- Health management

### 🚧 Partially Implemented
- Ally state management (need to add to game widget)
- Ally rendering (need to implement)
- Add/remove ally buttons (need to add to UI)
- Ally AI loop (need to implement)

### ❌ Not Yet Implemented
- Ollama HTTP client
- Ollama prompt construction
- LLM decision parsing
- MCP tool integration
- Decision caching
- Error handling for Ollama failures

---

## Next Steps for Full Implementation

1. **Add HTTP package** to `pubspec.yaml`:
   ```yaml
   dependencies:
     http: ^1.1.0
   ```

2. **Create `lib/ai/ollama_client.dart`**: Implement HTTP client

3. **Create `lib/ai/ai_decision_handler.dart`**: Implement decision logic

4. **Add ally state to game widget**: List<Ally> allies = []

5. **Implement ally AI loop** in game update method

6. **Add add/remove buttons** to UI

7. **Test with Ollama server** running locally

---

## Testing Ollama Locally

```bash
# Terminal 1: Start Ollama
ollama serve

# Terminal 2: Pull models
ollama pull llama2
ollama pull mistral

# Terminal 3: Test API
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "Say hello in 5 words",
  "stream": false
}'

# Should return:
# {"model":"llama2","created_at":"...","response":"Hello there, how are you","done":true}
```

---

## Configuration File (Optional)

Create `lib/config/ai_config.dart`:

```dart
class AIConfig {
  // Ollama settings
  static const String ollamaBaseUrl = 'http://localhost:11434';
  static const String allyModel = 'llama2';
  static const String monsterModel = 'mistral';
  static const Duration ollamaTimeout = Duration(seconds: 5);

  // AI behavior
  static const double allyAIInterval = 3.0; // seconds
  static const double monsterAIInterval = 2.0; // seconds
  static const double decisionCacheTimeout = 2.0; // seconds

  // LLM parameters
  static const double allyTemperature = 0.7; // Balanced
  static const double monsterTemperature = 0.8; // More random
  static const int maxTokens = 50; // Short responses

  // Fallback behavior
  static const bool useFallbackAI = true; // When Ollama fails
  static const bool verboseLogging = true; // Debug mode
}
```

---

## Performance Metrics to Monitor

1. **LLM Response Time**: Should be < 2 seconds
2. **Decision Quality**: Track win/loss rates
3. **CPU Usage**: Monitor Ollama process
4. **Memory Usage**: ~2-4GB for 7B models
5. **Frame Rate**: Should stay > 30 FPS during AI decisions

---

## Conclusion

This system provides:
- **Intelligent AI** via Ollama LLMs
- **Fallback mechanisms** for reliability
- **Optimization strategies** for performance
- **Clear architecture** for maintainability

The ally system is **designed** and **structured** - remaining implementation is primarily:
1. HTTP integration
2. UI buttons
3. Rendering logic
4. Testing with Ollama server
