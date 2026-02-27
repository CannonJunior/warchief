import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Manages melee combo system configuration loaded from
/// `assets/data/combo_config.json`.
///
/// Exposes a per-category config map used by [MeleeComboSystem]
/// to determine thresholds and reward effects.
class ComboConfig {
  static const String _assetPath = 'assets/data/combo_config.json';

  Map<String, dynamic> _data = {};
  bool _loaded = false;

  // ==================== GLOBAL GETTERS ====================

  /// Seconds of inactivity after which an incomplete combo resets.
  double get comboWindow => (_data['comboWindow'] as num?)?.toDouble() ?? 4.0;

  /// Seconds after chain mode is activated during which 7 hits must land.
  double get chainWindow => (_data['chainWindow'] as num?)?.toDouble() ?? 7.0;

  // ==================== CATEGORY LOOKUP ====================

  /// Returns the raw config map for [category], or null if undefined.
  ///
  /// Keys present depend on the effect type:
  /// - All: `threshold` (int), `effect` (String)
  /// - knockback: `knockbackForce` (double)
  /// - slow / haste / strength: `duration` (double), `strength` (double)
  /// - redMana / heal / aoe: `amount` or `damage` (double), `radius` (double)
  /// - regen: `duration`, `healPerTick`, `tickInterval` (all double)
  Map<String, dynamic>? getCategoryConfig(String category) {
    final cats = _data['categories'];
    if (cats is! Map<String, dynamic>) return null;
    final cat = cats[category];
    return (cat is Map<String, dynamic>) ? cat : null;
  }

  // ==================== INITIALIZATION ====================

  /// Load defaults from JSON asset.
  Future<void> initialize() async {
    if (_loaded) return;
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _data = jsonDecode(jsonString) as Map<String, dynamic>;
      _loaded = true;
      print('[ComboConfig] Loaded from $_assetPath');
    } catch (e) {
      print('[ComboConfig] Failed to load: $e (using built-in fallbacks)');
      _data = {};
    }
  }
}

/// Global singleton — initialized in game3d_widget_init.dart.
ComboConfig? globalComboConfig;
