import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Manages goals configuration with JSON asset defaults.
///
/// Architecture:
/// - JSON asset file (`assets/data/goals_config.json`) = shipped defaults
/// - Runtime getters resolve values from the loaded defaults
///
/// Follows the same pattern as [BuildingConfig] and [ManaConfig].
class GoalsConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/goals_config.json';

  /// Defaults loaded from JSON asset file.
  Map<String, dynamic> _defaults = {};

  // ==================== WARRIOR SPIRIT GETTERS ====================

  /// Ollama model name for the Warrior Spirit.
  String get warriorSpiritModel =>
      _resolveString('warrior_spirit.model', 'llama3.2');

  /// Temperature (creativity level) for LLM generation.
  double get warriorSpiritTemperature =>
      _resolveDouble('warrior_spirit.temperature', 0.8);

  /// Base personality system prompt for the Warrior Spirit.
  String get warriorSpiritPersonality =>
      _resolveString('warrior_spirit.personality',
          'You are an ancient warrior spirit.');

  /// Initial greeting message from the Warrior Spirit.
  String get warriorSpiritGreeting =>
      _resolveString('warrior_spirit.greeting',
          'The flame stirs, Warchief. What weighs on your sword arm?');

  /// Seconds between automatic goal suggestion checks.
  double get goalCheckInterval =>
      _resolveDouble('warrior_spirit.goal_check_interval_seconds', 120.0);

  /// Maximum number of simultaneously active goals.
  int get maxActiveGoals =>
      _resolveInt('warrior_spirit.max_active_goals', 5);

  /// Reflection prompt template for completed goals.
  String get reflectionPromptTemplate =>
      _resolveString('warrior_spirit.reflection_prompt_template',
          'Reflect on this achievement in 1-2 sentences.');

  // ==================== GOAL CATEGORY ACCESS ====================

  /// Get category config (color, icon) for a goal category name.
  Map<String, dynamic>? getCategoryConfig(String categoryName) {
    final categories = _defaults['goal_categories'];
    if (categories is Map<String, dynamic> &&
        categories.containsKey(categoryName)) {
      return Map<String, dynamic>.from(categories[categoryName] as Map);
    }
    return null;
  }

  /// Get category color as a list of doubles [r, g, b, a].
  List<double> getCategoryColor(String categoryName) {
    final config = getCategoryConfig(categoryName);
    if (config != null && config['color'] is List) {
      return (config['color'] as List).cast<num>().map((n) => n.toDouble()).toList();
    }
    return [0.5, 0.5, 0.5, 1.0]; // Gray fallback
  }

  // ==================== GOAL DEFINITION ACCESS ====================

  /// Get the raw JSON definition for a goal by ID.
  ///
  /// Returns null if the goal is not found.
  Map<String, dynamic>? getGoalDefinition(String goalId) {
    final goals = _defaults['goals'];
    if (goals is Map<String, dynamic> && goals.containsKey(goalId)) {
      return Map<String, dynamic>.from(goals[goalId] as Map);
    }
    return null;
  }

  /// Get all available goal IDs.
  List<String> get allGoalIds {
    final goals = _defaults['goals'];
    if (goals is Map<String, dynamic>) {
      return goals.keys.toList();
    }
    return [];
  }

  // ==================== INITIALIZATION ====================

  /// Load defaults from JSON asset.
  Future<void> initialize() async {
    await _loadDefaults();
  }

  /// Load default values from the bundled JSON asset file.
  Future<void> _loadDefaults() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _defaults = jsonDecode(jsonString) as Map<String, dynamic>;
      print('[GoalsConfig] Loaded defaults from $_assetPath');
      final goalCount = allGoalIds.length;
      print('[GoalsConfig] $goalCount goal definitions loaded');
    } catch (e) {
      print('[GoalsConfig] Failed to load defaults: $e (using hardcoded fallbacks)');
      _defaults = {};
    }
  }

  // ==================== RESOLUTION HELPERS ====================

  /// Resolve a double value using dot-notation key.
  double _resolveDouble(String dotKey, double fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toDouble();
    return fallback;
  }

  /// Resolve an int value using dot-notation key.
  int _resolveInt(String dotKey, int fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toInt();
    return fallback;
  }

  /// Resolve a string value using dot-notation key.
  String _resolveString(String dotKey, String fallback) {
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is String) return val;
    return fallback;
  }

  /// Resolve a dot-notation key from a nested map.
  static dynamic _resolveFromNestedMap(
      Map<String, dynamic> map, String dotKey) {
    final parts = dotKey.split('.');
    dynamic current = map;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}

/// Global goals config instance (initialized in game3d_widget.dart).
GoalsConfig? globalGoalsConfig;
