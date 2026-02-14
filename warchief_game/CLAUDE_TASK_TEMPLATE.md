# Claude Code Task Template

Use this template when creating new implementation tasks for Claude Code sessions.

## Task Structure

```
Implement [feature name]:

### Context
- What this feature does and why
- Design philosophy constraints
- Related systems it integrates with

### Research
- Read existing .md files FIRST (GOALS_SYSTEM_DESIGN.md, AI_INTEGRATION.md, etc.)
- Only explore codebase for files NOT already documented
- Check TASK.md for related completed work

### Files to Create
| File | Purpose | Pattern to Follow |
|------|---------|-------------------|
| path/to/file.dart | Description | existing_pattern.dart |

### Files to Modify
| File | Change |
|------|--------|
| path/to/file.dart | What to add/change |

### Implementation Details
- Specific code structure, enums, classes
- Config JSON structure
- UI layout description
- Event hook points

### Verification
1. `flutter build web` compiles clean
2. Feature-specific checks
3. Fallback behavior works
```

## Key Patterns Reference

| Pattern | Source File | Usage |
|---------|-----------|-------|
| Config class | `lib/game3d/state/mana_config.dart` | `_resolve()`, `loadFromAsset()`, global singleton |
| Draggable panel | `lib/game3d/ui/building_panel.dart` | `_xPos/_yPos`, `GestureDetector.onPanUpdate` |
| Chat messages | `lib/models/ai_chat_message.dart` | `text + isInput + timestamp` |
| Ollama calls | `lib/ai/ollama_client.dart` | `generate(model, prompt, temperature)` |
| Section headers | `lib/game3d/ui/building_panel.dart:212` | `_buildSectionHeader(label)` |
| Keyboard toggle | `lib/game3d/game3d_widget.dart` | `KeyDownEvent` -> `setState(() { flag = !flag; })` |
| Event system | `lib/game3d/systems/combat_system.dart` | `checkAndApplyDamage` as hook point |

## Token Efficiency Guidelines

1. Read existing .md files before exploring codebase
2. Don't re-explore files that are documented in .md context files
3. Use Glob/Grep for targeted searches, not broad exploration
4. Create .md context files for any new system you build
5. Keep plans under 500 lines — split into phases if needed

## Anti-Patterns to Avoid

- Never hardcode values that should be in JSON config
- Never create files over 500 lines
- Never put LLM calls in critical game loop paths
- Never skip fallback behavior for external services
- Never import game_state.dart from system files that game_state imports (circular)
