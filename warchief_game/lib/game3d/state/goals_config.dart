import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Manages goals configuration with JSON asset defaults and
/// SharedPreferences overrides.
///
/// Architecture:
/// - JSON asset file (`assets/data/goals_config.json`) = shipped defaults
/// - SharedPreferences = sparse user overrides (only changed fields)
/// - Runtime = overrides merged on top of defaults
///
/// Follows the same pattern as [ManaConfig].
class GoalsConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/goals_config.json';
  static const String _storageKey = 'goals_config_overrides';

  /// Defaults loaded from JSON asset file.
  Map<String, dynamic> _defaults = {};

  /// Sparse user overrides stored in SharedPreferences.
  Map<String, dynamic> _overrides = {};

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

  /// Load defaults from JSON asset, then overrides from SharedPreferences.
  Future<void> initialize() async {
    await _loadDefaults();
    await _loadOverrides();
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

  Future<void> _loadOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        _overrides = Map<String, dynamic>.from(
          jsonDecode(json) as Map<String, dynamic>,
        );
        notifyListeners();
        print('[GoalsConfig] Loaded ${_overrides.length} overrides');
      }
    } catch (e) {
      print('[GoalsConfig] Failed to load overrides: $e');
    }
  }

  Future<void> _saveOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_overrides));
    } catch (e) {
      print('[GoalsConfig] Failed to save overrides: $e');
    }
  }

  // ==================== OVERRIDE MANAGEMENT ====================

  void setOverride(String key, dynamic value) {
    _overrides[key] = value;
    notifyListeners();
    _saveOverrides();
  }

  void clearOverride(String key) {
    _overrides.remove(key);
    notifyListeners();
    _saveOverrides();
  }

  void clearAllOverrides() {
    _overrides.clear();
    notifyListeners();
    _saveOverrides();
  }

  bool hasOverride(String key) => _overrides.containsKey(key);

  Map<String, dynamic> get overrides => Map.unmodifiable(_overrides);

  dynamic getDefault(String key) => _resolveFromNestedMap(_defaults, key);

  // ==================== RESOLUTION HELPERS ====================

  /// Resolve a double: override -> default -> hardcoded fallback.
  double _resolveDouble(String dotKey, double fallback) {
    if (_overrides.containsKey(dotKey)) {
      final val = _overrides[dotKey];
      if (val is num) return val.toDouble();
    }
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toDouble();
    return fallback;
  }

  /// Resolve an int: override -> default -> hardcoded fallback.
  int _resolveInt(String dotKey, int fallback) {
    if (_overrides.containsKey(dotKey)) {
      final val = _overrides[dotKey];
      if (val is num) return val.toInt();
    }
    final val = _resolveFromNestedMap(_defaults, dotKey);
    if (val is num) return val.toInt();
    return fallback;
  }

  /// Resolve a string: override -> default -> hardcoded fallback.
  String _resolveString(String dotKey, String fallback) {
    if (_overrides.containsKey(dotKey)) {
      final val = _overrides[dotKey];
      if (val is String) return val;
    }
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
