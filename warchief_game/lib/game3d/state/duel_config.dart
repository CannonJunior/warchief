import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Global duel config instance — initialized in game3d_widget_init.dart
DuelConfig? globalDuelConfig;

/// Manages duel arena configuration loaded from JSON asset.
///
/// Follows the same pattern as [ManaConfig] / [WindConfig]: JSON asset file
/// provides shipped defaults with dot-notation getters for all values.
class DuelConfig {
  static const String _assetPath = 'assets/data/duel_config.json';

  Map<String, dynamic>? _data;

  // Reason: cache parsed lists so per-frame callers (DuelSystem._gearDamageMult,
  // _startDuel gear scaling) get O(1) field access instead of re-parsing JSON.
  List<String> _gearTierNames           = const ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'];
  List<double> _gearTierHealthMults     = const [1.0, 1.2, 1.5, 1.85, 2.3];
  List<double> _gearTierManaMults       = const [1.0, 1.2, 1.5, 1.85, 2.3];
  List<double> _gearTierDamageMults     = const [1.0, 1.1, 1.25, 1.45, 1.7];

  // ==================== ARENA GETTERS ====================

  double get arenaOffsetX =>
      (_data?['arena']?['offsetX'] as num?)?.toDouble() ?? 200.0;
  double get arenaOffsetZ =>
      (_data?['arena']?['offsetZ'] as num?)?.toDouble() ?? 200.0;
  double get separationDistance =>
      (_data?['arena']?['separationDistance'] as num?)?.toDouble() ?? 20.0;

  // ==================== DUEL GETTERS ====================

  double get maxDurationSeconds =>
      (_data?['duel']?['maxDurationSeconds'] as num?)?.toDouble() ?? 120.0;
  double get manaRegenPerSecond =>
      (_data?['duel']?['manaRegenPerSecond'] as num?)?.toDouble() ?? 5.0;
  int get historyMaxEntries =>
      (_data?['duel']?['historyMaxEntries'] as num?)?.toInt() ?? 200;
  double get gcdSeconds =>
      (_data?['duel']?['gcdSeconds'] as num?)?.toDouble() ?? 1.0;
  double get comboWindowSeconds =>
      (_data?['duel']?['comboWindowSeconds'] as num?)?.toDouble() ?? 3.0;

  // ==================== COMBATANT GETTERS ====================

  double get challengerHealth =>
      (_data?['challengers']?['health'] as num?)?.toDouble() ?? 100.0;
  double get challengerManaPool =>
      (_data?['challengers']?['manaPool'] as num?)?.toDouble() ?? 100.0;
  double get enemyFactionHealth =>
      (_data?['enemyFaction']?['health'] as num?)?.toDouble() ?? 100.0;
  double get enemyFactionManaPool =>
      (_data?['enemyFaction']?['manaPool'] as num?)?.toDouble() ?? 60.0;

  // ==================== GEAR TIER GETTERS ====================

  List<String> get gearTierNames           => _gearTierNames;
  List<double> get gearTierHealthMultipliers => _gearTierHealthMults;
  List<double> get gearTierManaMultipliers   => _gearTierManaMults;
  List<double> get gearTierDamageMultipliers => _gearTierDamageMults;

  // ==================== INITIALIZATION ====================

  /// Load config from JSON asset and cache all derived lists.
  Future<void> initialize() async {
    try {
      final str = await rootBundle.loadString(_assetPath);
      _data = jsonDecode(str) as Map<String, dynamic>;
      print('[DuelConfig] Loaded from $_assetPath');
    } catch (e) {
      print('[DuelConfig] Failed to load: $e (using fallbacks)');
      _data = {};
    }
    _buildCache();
  }

  void _buildCache() {
    List<double> parseDoubles(dynamic raw, List<double> fallback) {
      if (raw is List) return [for (final e in raw) (e as num).toDouble()];
      return fallback;
    }

    final tiers = _data?['gearTiers'];
    final namesRaw = tiers?['names'];
    if (namesRaw is List) _gearTierNames = namesRaw.cast<String>();

    _gearTierHealthMults = parseDoubles(
        tiers?['healthMultipliers'], const [1.0, 1.2, 1.5, 1.85, 2.3]);
    _gearTierManaMults   = parseDoubles(
        tiers?['manaMultipliers'],   const [1.0, 1.2, 1.5, 1.85, 2.3]);
    _gearTierDamageMults = parseDoubles(
        tiers?['damageMultipliers'], const [1.0, 1.1, 1.25, 1.45, 1.7]);
  }
}
