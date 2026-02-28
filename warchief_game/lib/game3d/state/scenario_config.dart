import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../data/monsters/minion_definitions.dart';

/// Global scenario config instance — initialized in game3d_widget_init.dart.
ScenarioConfig? globalScenarioConfig;

/// Configuration for which entities and world features are present at game start.
///
/// Follows the same JSON-defaults + SharedPreferences-overrides pattern as
/// [BuildingConfig] and [WindConfig].
///
/// Defaults are set at construction time so callers can read safe values
/// even before [initialize] completes its async I/O.
class ScenarioConfig {
  static const String _assetPath = 'assets/data/scenario_config.json';
  static const String _storageKey = 'scenario_config_v1';

  // ==================== STATE (defaults match JSON) ====================

  int _initialAllyCount = 0;
  bool _spawnBossMonster = true;
  bool _spawnWarchiefHome = true;
  bool _spawnMinions = true;
  List<MinionSpawnConfig> _minionSpawns = const [
    MinionSpawnConfig(definitionId: 'gnoll_marauder',   count: 8, spreadRadius: 5.0),
    MinionSpawnConfig(definitionId: 'satyr_hexblade',   count: 4, spreadRadius: 3.0),
    MinionSpawnConfig(definitionId: 'dryad_lifebinder', count: 2, spreadRadius: 2.0),
    MinionSpawnConfig(definitionId: 'minotaur_bulwark', count: 1, spreadRadius: 0.0),
  ];
  int _leyLineSeed = 42;
  double _leyLineWorldSize = 300.0;
  int _leyLineSiteCount = 30;

  bool _loaded = false;

  // ==================== GETTERS ====================

  int get initialAllyCount => _initialAllyCount;
  bool get spawnBossMonster => _spawnBossMonster;
  bool get spawnWarchiefHome => _spawnWarchiefHome;
  bool get spawnMinions => _spawnMinions;
  List<MinionSpawnConfig> get minionSpawns => _minionSpawns;
  int get leyLineSeed => _leyLineSeed;
  double get leyLineWorldSize => _leyLineWorldSize;
  int get leyLineSiteCount => _leyLineSiteCount;

  // ==================== INITIALIZATION ====================

  /// Load JSON defaults then SharedPreferences overrides.
  /// Safe to call multiple times — no-ops after first call.
  Future<void> initialize() async {
    if (_loaded) return;
    _loaded = true;

    // JSON defaults
    Map<String, dynamic> jsonData = {};
    try {
      final str = await rootBundle.loadString(_assetPath);
      jsonData = jsonDecode(str) as Map<String, dynamic>;
      print('[ScenarioConfig] Loaded from $_assetPath');
    } catch (e) {
      print('[ScenarioConfig] Failed to load JSON: $e (using hardcoded defaults)');
    }
    _applyMap(jsonData);

    // SharedPreferences overrides
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null) {
        _applyMap(jsonDecode(saved) as Map<String, dynamic>);
        print('[ScenarioConfig] Applied saved overrides');
      }
    } catch (e) {
      print('[ScenarioConfig] Failed to load overrides: $e');
    }
  }

  void _applyMap(Map<String, dynamic> data) {
    if (data['initial_ally_count'] is int)    _initialAllyCount  = data['initial_ally_count'];
    if (data['spawn_boss_monster'] is bool)   _spawnBossMonster  = data['spawn_boss_monster'];
    if (data['spawn_warchief_home'] is bool)  _spawnWarchiefHome = data['spawn_warchief_home'];
    if (data['spawn_minions'] is bool)        _spawnMinions      = data['spawn_minions'];
    if (data['ley_line_seed'] is int)         _leyLineSeed       = data['ley_line_seed'];
    if (data['ley_line_site_count'] is int)   _leyLineSiteCount  = data['ley_line_site_count'];
    if (data['ley_line_world_size'] is num)   _leyLineWorldSize  = (data['ley_line_world_size'] as num).toDouble();

    final rawSpawns = data['minion_spawns'];
    if (rawSpawns is List) {
      final parsed = <MinionSpawnConfig>[];
      for (final s in rawSpawns) {
        if (s is Map) {
          final id    = s['definition_id'] as String?;
          final cnt   = s['count'];
          final spread = s['spread_radius'];
          if (id != null && cnt is int) {
            parsed.add(MinionSpawnConfig(
              definitionId: id,
              count: cnt,
              spreadRadius: spread is num ? spread.toDouble() : 3.0,
            ));
          }
        }
      }
      if (parsed.isNotEmpty) _minionSpawns = parsed;
    }
  }

  // ==================== PERSISTENCE ====================

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'initial_ally_count':   _initialAllyCount,
        'spawn_boss_monster':   _spawnBossMonster,
        'spawn_warchief_home':  _spawnWarchiefHome,
        'spawn_minions':        _spawnMinions,
        'ley_line_seed':        _leyLineSeed,
        'ley_line_world_size':  _leyLineWorldSize,
        'ley_line_site_count':  _leyLineSiteCount,
        'minion_spawns': [
          for (final s in _minionSpawns)
            {
              'definition_id': s.definitionId,
              'count':         s.count,
              'spread_radius': s.spreadRadius,
            },
        ],
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      print('[ScenarioConfig] Failed to save: $e');
    }
  }

  // ==================== SETTERS ====================

  void setInitialAllyCount(int v)    { _initialAllyCount  = v.clamp(0, 20);  save(); }
  void setSpawnBossMonster(bool v)   { _spawnBossMonster  = v;               save(); }
  void setSpawnWarchiefHome(bool v)  { _spawnWarchiefHome = v;               save(); }
  void setSpawnMinions(bool v)       { _spawnMinions      = v;               save(); }
  void setLeyLineSeed(int v)         { _leyLineSeed       = v.clamp(1, 9999); save(); }
  void setLeyLineWorldSize(double v) { _leyLineWorldSize  = v.clamp(100.0, 2000.0); save(); }
  void setLeyLineSiteCount(int v)    { _leyLineSiteCount  = v.clamp(1, 200); save(); }

  /// Update the spawn count for a specific minion definition.
  void setMinionCount(String definitionId, int count) {
    final clamped = count.clamp(0, 99);
    final idx = _minionSpawns.indexWhere((s) => s.definitionId == definitionId);
    if (idx >= 0) {
      final existing = _minionSpawns[idx];
      final updated = MinionSpawnConfig(
        definitionId: existing.definitionId,
        count: clamped,
        spreadRadius: existing.spreadRadius,
      );
      _minionSpawns = [
        ..._minionSpawns.sublist(0, idx),
        updated,
        ..._minionSpawns.sublist(idx + 1),
      ];
    }
    save();
  }
}
