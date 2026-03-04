import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loads a curated core set of project documentation into a single cached
/// string for the Warrior Spirit's system prompt.
///
/// Call [initialize] once at startup (fire-and-forget is fine); subsequent
/// calls to [initialize] are no-ops. Read [content] to get the combined text.
///
/// Only 5 focused docs are loaded (~38 K chars / ~9.5 K tokens) so the
/// system prompt stays within qwen2.5:7b's practical prefill budget.
/// Large/niche docs (PLATFORM_DESIGN, GAME_STATE_ENTITIES, RENDERING_PIPELINE,
/// ALLY_AND_MONSTER_AI, TASK.md) are intentionally excluded.
class SpiritKnowledgeBase {
  SpiritKnowledgeBase._();

  static String _content = '';
  static bool _loaded = false;

  /// Combined markdown content of all loaded documentation files.
  /// Empty string until [initialize] completes.
  static String get content => _content;

  /// True once [initialize] has successfully finished.
  static bool get isLoaded => _loaded;

  // Curated core set — project rules + the four most-queried system docs.
  // Ordered from general to specific so the model sees conventions first.
  // Reason: full 14-doc set is ~157 K chars; this subset is ~38 K chars
  // (~9.5 K tokens) which fits comfortably in qwen2.5:7b's prefill budget.
  static const List<(String, String)> _docs = [
    ('Project CLAUDE',  'assets/docs/root_CLAUDE.md'),
    ('Game CLAUDE',     'assets/docs/game_CLAUDE.md'),
    ('AI Architecture', 'assets/docs/AI_ARCHITECTURE.md'),
    ('Abilities Guide', 'assets/docs/ABILITIES_GUIDE.md'),
    ('Combat AI Guide', 'assets/docs/COMBAT_AI_GUIDE.md'),
  ];

  /// Load all documentation files and cache them.
  ///
  /// Safe to call multiple times; only the first call does real work.
  /// Missing files are skipped with a debug warning so a single bad path
  /// never prevents the rest of the docs from loading.
  static Future<void> initialize() async {
    if (_loaded) return;

    final buffer = StringBuffer();
    int loaded = 0;

    for (final (title, path) in _docs) {
      try {
        final text = await rootBundle.loadString(path);
        buffer
          ..writeln('# $title')
          ..writeln()
          ..writeln(text)
          ..writeln()
          ..writeln('---')
          ..writeln();
        loaded++;
      } catch (e) {
        debugPrint('[SpiritKnowledgeBase] Skipped $path: $e');
      }
    }

    _content = buffer.toString();
    _loaded = true;
    debugPrint(
        '[SpiritKnowledgeBase] Ready: $loaded/${_docs.length} docs, '
        '${_content.length} chars');
  }
}
