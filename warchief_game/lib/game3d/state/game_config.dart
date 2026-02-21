import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:convert';

/// Game configuration loaded from JSON with runtime override support.
///
/// Architecture:
/// - JSON asset file (`assets/data/game_config.json`) = shipped defaults
/// - SharedPreferences = sparse user overrides (only changed fields)
/// - Runtime = overrides merged on top of defaults via dot-notation getters
///
/// Static getters delegate to the global instance for backward compatibility.
/// All existing `GameConfig.fieldName` call sites work without changes.
class GameConfig extends ChangeNotifier {
  static const String _assetPath = 'assets/data/game_config.json';
  static const String _storageKey = 'game_config_overrides';

  /// Defaults loaded from JSON asset file.
  Map<String, dynamic> _defaults = {};

  /// Sparse user overrides stored in SharedPreferences.
  Map<String, dynamic> _overrides = {};

  /// Internal shorthand for the global instance.
  /// Auto-creates if needed so field initializers work before initState().
  static GameConfig get _i {
    globalGameConfig ??= GameConfig();
    return globalGameConfig!;
  }

  // ==================== TERRAIN CONFIGURATION ====================

  static int get terrainGridSize =>
      _i._resolveInt('terrain.gridSize', 50);
  static double get terrainTileSize =>
      _i._resolve('terrain.tileSize', 1.0);
  static double get terrainMaxHeight =>
      _i._resolve('terrain.maxHeight', 3.0);
  static double get terrainNoiseScale =>
      _i._resolve('terrain.noiseScale', 0.03);
  static int get terrainNoiseOctaves =>
      _i._resolveInt('terrain.noiseOctaves', 2);
  static double get terrainNoisePersistence =>
      _i._resolve('terrain.noisePersistence', 0.5);

  // ==================== PLAYER CONFIGURATION ====================

  static double get playerSpeed =>
      _i._resolve('player.speed', 5.0);
  static double get playerRotationSpeed =>
      _i._resolve('player.rotationSpeed', 180.0);
  static double get playerSize =>
      _i._resolve('player.size', 0.5);
  static Vector3 get playerStartPosition => Vector3(
        _i._resolve('player.startPositionX', 10.0),
        _i._resolve('player.startPositionY', 0.5),
        _i._resolve('player.startPositionZ', 2.0),
      );
  static double get playerStartRotation =>
      _i._resolve('player.startRotation', 180.0);
  static double get playerDirectionIndicatorSize =>
      _i._resolve('player.directionIndicatorSize', 0.5);

  // ==================== MONSTER CONFIGURATION ====================

  static double get monsterMaxHealth =>
      _i._resolve('monster.maxHealth', 100.0);
  static double get monsterSize =>
      _i._resolve('monster.size', 1.2);
  static Vector3 get monsterStartPosition => Vector3(
        _i._resolve('monster.startPositionX', 18.0),
        _i._resolve('monster.startPositionY', 0.5),
        _i._resolve('monster.startPositionZ', 18.0),
      );
  static double get monsterStartRotation =>
      _i._resolve('monster.startRotation', 180.0);
  static double get monsterDirectionIndicatorSize =>
      _i._resolve('monster.directionIndicatorSize', 0.5);
  static double get monsterAiInterval =>
      _i._resolve('monster.aiInterval', 2.0);
  static double get monsterMoveThresholdMin =>
      _i._resolve('monster.moveThresholdMin', 5.0);
  static double get monsterMoveThresholdMax =>
      _i._resolve('monster.moveThresholdMax', 12.0);
  static double get monsterHealThreshold =>
      _i._resolve('monster.healThreshold', 50.0);

  // ==================== MONSTER ABILITIES ====================

  static double get monsterAbility1CooldownMax =>
      _i._resolve('monsterAbilities.ability1CooldownMax', 2.0);
  static double get monsterAbility1Damage =>
      _i._resolve('monsterAbilities.ability1Damage', 15.0);
  static double get monsterAbility1Range =>
      _i._resolve('monsterAbilities.ability1Range', 3.0);
  static double get monsterAbility1Duration =>
      _i._resolve('monsterAbilities.ability1Duration', 0.4);
  static double get monsterSwordWidth =>
      _i._resolve('monsterAbilities.swordWidth', 0.5);
  static double get monsterSwordHeight =>
      _i._resolve('monsterAbilities.swordHeight', 2.5);
  static Vector3 get monsterSwordColor => Vector3(
        _i._resolve('monsterAbilities.swordColorR', 0.4),
        _i._resolve('monsterAbilities.swordColorG', 0.1),
        _i._resolve('monsterAbilities.swordColorB', 0.5),
      );
  static Vector3 get monsterAbility1ImpactColor => Vector3(
        _i._resolve('monsterAbilities.ability1ImpactColorR', 0.6),
        _i._resolve('monsterAbilities.ability1ImpactColorG', 0.2),
        _i._resolve('monsterAbilities.ability1ImpactColorB', 0.8),
      );
  static double get monsterAbility1ImpactSize =>
      _i._resolve('monsterAbilities.ability1ImpactSize', 0.6);
  static double get monsterAbility2CooldownMax =>
      _i._resolve('monsterAbilities.ability2CooldownMax', 4.0);
  static double get monsterAbility2ProjectileSize =>
      _i._resolve('monsterAbilities.ability2ProjectileSize', 0.5);
  static double get monsterAbility2Damage =>
      _i._resolve('monsterAbilities.ability2Damage', 12.0);
  static Vector3 get monsterAbility2ImpactColor => Vector3(
        _i._resolve('monsterAbilities.ability2ImpactColorR', 0.5),
        _i._resolve('monsterAbilities.ability2ImpactColorG', 0.0),
        _i._resolve('monsterAbilities.ability2ImpactColorB', 0.5),
      );
  static double get monsterAbility3CooldownMax =>
      _i._resolve('monsterAbilities.ability3CooldownMax', 8.0);
  static double get monsterAbility3HealAmount =>
      _i._resolve('monsterAbilities.ability3HealAmount', 25.0);

  // ==================== ALLY CONFIGURATION ====================

  static double get allyMaxHealth =>
      _i._resolve('ally.maxHealth', 50.0);
  static double get allySize =>
      _i._resolve('ally.size', 0.8);
  static double get allyAbilityCooldownMax =>
      _i._resolve('ally.abilityCooldownMax', 5.0);
  static double get allyAiInterval =>
      _i._resolve('ally.aiInterval', 1.0);
  static double get allyMoveThreshold =>
      _i._resolve('ally.moveThreshold', 10.0);
  static double get allySwordDamage =>
      _i._resolve('ally.swordDamage', 10.0);
  static double get allyFireballDamage =>
      _i._resolve('ally.fireballDamage', 15.0);
  static double get allyHealAmount =>
      _i._resolve('ally.healAmount', 15.0);
  static double get allyFireballSize =>
      _i._resolve('ally.fireballSize', 0.3);

  // ==================== PLAYER ABILITIES ====================

  static double get ability1CooldownMax =>
      _i._resolve('playerAbilities.ability1CooldownMax', 1.5);
  static double get ability1Duration =>
      _i._resolve('playerAbilities.ability1Duration', 0.3);
  static double get ability1Range =>
      _i._resolve('playerAbilities.ability1Range', 2.0);
  static double get ability1Damage =>
      _i._resolve('playerAbilities.ability1Damage', 25.0);
  static Vector3 get ability1ImpactColor => Vector3(
        _i._resolve('playerAbilities.ability1ImpactColorR', 0.8),
        _i._resolve('playerAbilities.ability1ImpactColorG', 0.8),
        _i._resolve('playerAbilities.ability1ImpactColorB', 0.9),
      );
  static double get ability1ImpactSize =>
      _i._resolve('playerAbilities.ability1ImpactSize', 0.5);
  static double get ability2CooldownMax =>
      _i._resolve('playerAbilities.ability2CooldownMax', 3.0);
  static double get ability2ProjectileSpeed =>
      _i._resolve('playerAbilities.ability2ProjectileSpeed', 10.0);
  static double get ability2ProjectileSize =>
      _i._resolve('playerAbilities.ability2ProjectileSize', 0.4);
  static double get ability2Damage =>
      _i._resolve('playerAbilities.ability2Damage', 20.0);
  static Vector3 get ability2ProjectileColor => Vector3(
        _i._resolve('playerAbilities.ability2ProjectileColorR', 1.0),
        _i._resolve('playerAbilities.ability2ProjectileColorG', 0.4),
        _i._resolve('playerAbilities.ability2ProjectileColorB', 0.0),
      );
  static double get ability3CooldownMax =>
      _i._resolve('playerAbilities.ability3CooldownMax', 10.0);
  static double get ability3HealAmount =>
      _i._resolve('playerAbilities.ability3HealAmount', 20.0);

  // ==================== CLICK SELECTION ====================

  static double get clickSelectionRadius =>
      _i._resolve('selection.clickSelectionRadius', 60.0);

  // ==================== PROJECTILE CONFIGURATION ====================

  static double get projectileLifetime =>
      _i._resolve('projectile.lifetime', 5.0);
  static double get collisionThreshold =>
      _i._resolve('projectile.collisionThreshold', 1.0);

  // ==================== VISUAL EFFECTS ====================

  static double get impactEffectSize =>
      _i._resolve('effects.impactSize', 0.6);
  static double get impactEffectDuration =>
      _i._resolve('effects.impactDuration', 0.3);
  static double get impactEffectGrowthScale =>
      _i._resolve('effects.impactGrowthScale', 1.5);
  static double get fireballImpactSize =>
      _i._resolve('effects.fireballImpactSize', 0.8);
  static Vector3 get fireballImpactColor => Vector3(
        _i._resolve('effects.fireballImpactColorR', 1.0),
        _i._resolve('effects.fireballImpactColorG', 0.5),
        _i._resolve('effects.fireballImpactColorB', 0.0),
      );
  static double get allyFireballImpactSize =>
      _i._resolve('effects.allyFireballImpactSize', 0.6);
  static Vector3 get allyFireballImpactColor => Vector3(
        _i._resolve('effects.allyFireballImpactColorR', 1.0),
        _i._resolve('effects.allyFireballImpactColorG', 0.4),
        _i._resolve('effects.allyFireballImpactColorB', 0.0),
      );
  static double get allySwordImpactSize =>
      _i._resolve('effects.allySwordImpactSize', 0.5);
  static double get monsterProjectileImpactSize =>
      _i._resolve('effects.monsterProjectileImpactSize', 0.5);

  // ==================== PHYSICS ====================

  static double get gravity =>
      _i._resolve('physics.gravity', 20.0);
  static double get jumpVelocity =>
      _i._resolve('physics.jumpVelocity', 10.0);
  static double get groundLevel =>
      _i._resolve('physics.groundLevel', 0.5);

  // ==================== INITIALIZATION ====================

  /// Load defaults from JSON asset, then overrides from SharedPreferences.
  Future<void> initialize() async {
    await _loadDefaults();
    await _loadOverrides();
  }

  Future<void> _loadDefaults() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _defaults = jsonDecode(jsonString) as Map<String, dynamic>;
      print('[GameConfig] Loaded defaults from $_assetPath');
    } catch (e) {
      print('[GameConfig] Failed to load defaults: $e (using fallbacks)');
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
        print('[GameConfig] Loaded ${_overrides.length} overrides');
      }
    } catch (e) {
      print('[GameConfig] Failed to load overrides: $e');
    }
  }

  Future<void> _saveOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_overrides));
    } catch (e) {
      print('[GameConfig] Failed to save overrides: $e');
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
  double _resolve(String dotKey, double fallback) {
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

/// Global game config instance (initialized in game3d_widget.dart).
GameConfig? globalGameConfig;
