import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vector_math/vector_math.dart' hide Colors;
import 'stance_types.dart';

/// Registry of all available stances, loaded from `assets/data/stance_config.json`.
///
/// Access the singleton via [globalStanceRegistry] after calling [initialize].
class StanceRegistry {
  static const String _assetPath = 'assets/data/stance_config.json';

  /// All registered stances keyed by [StanceId].
  final Map<StanceId, StanceData> _stances = {};

  /// Default stance for new characters, loaded from config.
  StanceId defaultStance = StanceId.none;

  /// Ordered list of selectable stances (excludes [StanceId.none]).
  List<StanceData> get selectableStances =>
      _stances.values.where((s) => s.id != StanceId.none).toList();

  /// All stances including [StanceId.none].
  List<StanceData> get allStances => _stances.values.toList();

  /// Look up a stance by its id. Returns [StanceData.none] if not found.
  StanceData getStance(StanceId id) => _stances[id] ?? StanceData.none;

  /// Load stance definitions from the JSON asset.
  Future<void> initialize() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final stancesJson = json['stances'] as Map<String, dynamic>;

      // Always register the "none" stance
      _stances[StanceId.none] = StanceData.none;

      for (final entry in stancesJson.entries) {
        final id = _parseStanceId(entry.key);
        if (id == null) {
          print('[STANCE] Warning: unknown stance key "${entry.key}"');
          continue;
        }
        final data = entry.value as Map<String, dynamic>;
        _stances[id] = _parseStance(id, data);
      }

      // Load default stance from config
      final defaultKey = json['defaultStance'] as String?;
      if (defaultKey != null) {
        defaultStance = _parseStanceId(defaultKey) ?? StanceId.none;
      }

      print('[STANCE] Loaded ${_stances.length} stances (including none), default: ${defaultStance.name}');
    } catch (e) {
      print('[STANCE] Error loading stance config: $e');
      // Ensure none is always available
      _stances[StanceId.none] = StanceData.none;
    }
  }

  /// Parse a JSON key like "drunken_master" into a [StanceId].
  static StanceId? _parseStanceId(String key) {
    switch (key) {
      case 'none': return StanceId.none;
      case 'drunken_master': return StanceId.drunkenMaster;
      case 'blood_weave': return StanceId.bloodWeave;
      case 'tide': return StanceId.tide;
      case 'phantom_dance': return StanceId.phantomDance;
      case 'fury_of_the_ancestors': return StanceId.furyOfTheAncestors;
      default: return null;
    }
  }

  /// Map an icon name string from config to a Flutter [IconData].
  static IconData _parseIcon(String? iconName) {
    switch (iconName) {
      case 'liquor': return Icons.liquor;
      case 'water_drop': return Icons.water_drop;
      case 'waves': return Icons.waves;
      case 'blur_on': return Icons.blur_on;
      case 'bolt': return Icons.bolt;
      default: return Icons.help_outline;
    }
  }

  /// Parse a single stance definition from its JSON map.
  static StanceData _parseStance(StanceId id, Map<String, dynamic> data) {
    final colorList = (data['color'] as List<dynamic>?) ?? [0.5, 0.5, 0.5];
    return StanceData(
      id: id,
      name: data['name'] as String? ?? id.name,
      description: data['description'] as String? ?? '',
      icon: _parseIcon(data['icon'] as String?),
      color: Vector3(
        (colorList[0] as num).toDouble(),
        (colorList[1] as num).toDouble(),
        (colorList[2] as num).toDouble(),
      ),
      damageMultiplier: (data['damageMultiplier'] as num?)?.toDouble() ?? 1.0,
      damageTakenMultiplier: (data['damageTakenMultiplier'] as num?)?.toDouble() ?? 1.0,
      movementSpeedMultiplier: (data['movementSpeedMultiplier'] as num?)?.toDouble() ?? 1.0,
      cooldownMultiplier: (data['cooldownMultiplier'] as num?)?.toDouble() ?? 1.0,
      manaRegenMultiplier: (data['manaRegenMultiplier'] as num?)?.toDouble() ?? 1.0,
      manaCostMultiplier: (data['manaCostMultiplier'] as num?)?.toDouble() ?? 1.0,
      healingMultiplier: (data['healingMultiplier'] as num?)?.toDouble() ?? 1.0,
      maxHealthMultiplier: (data['maxHealthMultiplier'] as num?)?.toDouble() ?? 1.0,
      castTimeMultiplier: (data['castTimeMultiplier'] as num?)?.toDouble() ?? 1.0,
      healthDrainPerSecond: (data['healthDrainPerSecond'] as num?)?.toDouble() ?? 0.0,
      damageTakenToManaRatio: (data['damageTakenToManaRatio'] as num?)?.toDouble() ?? 0.0,
      usesHpForMana: data['usesHpForMana'] as bool? ?? false,
      hpForManaRatio: (data['hpForManaRatio'] as num?)?.toDouble() ?? 0.0,
      convertsManaRegenToHeal: data['convertsManaRegenToHeal'] as bool? ?? false,
      rerollInterval: (data['rerollInterval'] as num?)?.toDouble() ?? 0.0,
      hasRandomModifiers: data['hasRandomModifiers'] as bool? ?? false,
      rerollDamageMin: (data['rerollDamageMin'] as num?)?.toDouble() ?? 0.70,
      rerollDamageMax: (data['rerollDamageMax'] as num?)?.toDouble() ?? 1.30,
      rerollDamageTakenMin: (data['rerollDamageTakenMin'] as num?)?.toDouble() ?? 0.70,
      rerollDamageTakenMax: (data['rerollDamageTakenMax'] as num?)?.toDouble() ?? 1.30,
      switchCooldown: (data['switchCooldown'] as num?)?.toDouble() ?? 1.5,
    );
  }
}

/// Global singleton — set once from game3d_widget.dart during init.
StanceRegistry? globalStanceRegistry;
