/// Interface Configuration - Manages UI panel visibility and positions
///
/// Handles:
/// - Storing which interfaces are visible
/// - Storing panel positions
/// - Persisting configuration to local storage
/// - Loading configuration on startup

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single UI interface/panel configuration
class InterfaceConfig {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String category;       // 'game_abilities' or 'ui_panels'
  final String? shortcutKey;   // e.g. 'P', 'C', 'B', 'SHIFT+D', 'M', 'F', null
  bool isVisible;
  Offset position;
  final Offset defaultPosition;

  InterfaceConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.shortcutKey,
    required this.isVisible,
    required this.position,
    required this.defaultPosition,
  });

  /// Create a copy with updated values
  InterfaceConfig copyWith({
    bool? isVisible,
    Offset? position,
  }) {
    return InterfaceConfig(
      id: id,
      name: name,
      description: description,
      icon: icon,
      category: category,
      shortcutKey: shortcutKey,
      isVisible: isVisible ?? this.isVisible,
      position: position ?? this.position,
      defaultPosition: defaultPosition,
    );
  }

  /// Reset position to default
  void resetPosition() {
    position = defaultPosition;
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'isVisible': isVisible,
      'positionX': position.dx,
      'positionY': position.dy,
    };
  }

  /// Update from JSON data
  void updateFromJson(Map<String, dynamic> json) {
    if (json['isVisible'] != null) {
      isVisible = json['isVisible'] as bool;
    }
    if (json['positionX'] != null && json['positionY'] != null) {
      position = Offset(
        (json['positionX'] as num).toDouble(),
        (json['positionY'] as num).toDouble(),
      );
    }
  }
}

/// Manages all interface configurations
class InterfaceConfigManager {
  static const String _storageKey = 'warchief_interface_config';

  /// All available interfaces
  final Map<String, InterfaceConfig> _interfaces = {};

  /// Callback when configuration changes
  final void Function()? onConfigChanged;

  InterfaceConfigManager({this.onConfigChanged}) {
    _initializeDefaults();
  }

  /// Initialize default interface configurations
  void _initializeDefaults() {
    // ===== GAME ABILITIES CATEGORY =====

    // Abilities Codex (Press P to toggle)
    _interfaces['abilities_codex'] = InterfaceConfig(
      id: 'abilities_codex',
      name: 'Abilities Codex',
      description: 'Browse and drag abilities to action bar',
      icon: Icons.auto_stories,
      category: 'game_abilities',
      shortcutKey: 'P',
      isVisible: true,
      position: const Offset(0, 0),
      defaultPosition: const Offset(0, 0),
    );

    // Character Panel (Press C to toggle)
    _interfaces['character_panel'] = InterfaceConfig(
      id: 'character_panel',
      name: 'Character Panel',
      description: 'Equipment, stats, and character info',
      icon: Icons.person,
      category: 'game_abilities',
      shortcutKey: 'C',
      isVisible: true,
      position: const Offset(0, 0),
      defaultPosition: const Offset(0, 0),
    );

    // Bag Panel (Press B to toggle)
    _interfaces['bag_panel'] = InterfaceConfig(
      id: 'bag_panel',
      name: 'Bag Panel',
      description: 'Inventory and item management',
      icon: Icons.backpack,
      category: 'game_abilities',
      shortcutKey: 'B',
      isVisible: true,
      position: const Offset(0, 0),
      defaultPosition: const Offset(0, 0),
    );

    // ===== UI PANELS CATEGORY =====

    // Instructions Overlay (top-left)
    _interfaces['instructions'] = InterfaceConfig(
      id: 'instructions',
      name: 'Instructions',
      description: 'Control hints and camera info',
      icon: Icons.help_outline,
      category: 'ui_panels',
      isVisible: true,
      position: const Offset(10, 10),
      defaultPosition: const Offset(10, 10),
    );

    // Combat HUD (bottom-center area)
    _interfaces['combat_hud'] = InterfaceConfig(
      id: 'combat_hud',
      name: 'Combat HUD',
      description: 'Player and target frames with action bar',
      icon: Icons.sports_martial_arts,
      category: 'ui_panels',
      isVisible: true,
      position: const Offset(300, 500),
      defaultPosition: const Offset(300, 500),
    );

    // Monster Abilities Panel (left side)
    _interfaces['monster_abilities'] = InterfaceConfig(
      id: 'monster_abilities',
      name: 'Boss Abilities',
      description: 'Boss monster health and abilities',
      icon: Icons.dangerous,
      category: 'ui_panels',
      isVisible: true,
      position: const Offset(10, 300),
      defaultPosition: const Offset(10, 300),
    );

    // AI Chat Panel (left side below monster)
    _interfaces['ai_chat'] = InterfaceConfig(
      id: 'ai_chat',
      name: 'AI Chat',
      description: 'Monster AI decision log',
      icon: Icons.chat,
      category: 'ui_panels',
      isVisible: true,
      position: const Offset(10, 450),
      defaultPosition: const Offset(10, 450),
    );

    // Party Frames (part of combat_hud)
    _interfaces['party_frames'] = InterfaceConfig(
      id: 'party_frames',
      name: 'Party Frames',
      description: 'Allied unit health and status (part of Combat HUD)',
      icon: Icons.group,
      category: 'ui_panels',
      isVisible: true,
      position: const Offset(0, 0),
      defaultPosition: const Offset(0, 0),
    );

    // Minion Frames (part of combat_hud)
    _interfaces['minion_frames'] = InterfaceConfig(
      id: 'minion_frames',
      name: 'Minion Frames',
      description: 'Adversary minion health and status (part of Combat HUD)',
      icon: Icons.pest_control,
      category: 'ui_panels',
      isVisible: true,
      position: const Offset(0, 0),
      defaultPosition: const Offset(0, 0),
    );

    // Minimap (fixed top-right, Press M to toggle)
    _interfaces['minimap'] = InterfaceConfig(
      id: 'minimap',
      name: 'Minimap',
      description: 'Overhead terrain map with entity tracking',
      icon: Icons.map,
      category: 'ui_panels',
      shortcutKey: 'M',
      isVisible: true,
      position: const Offset(0, 0),
      defaultPosition: const Offset(0, 0),
    );

    // DPS Panel (Press SHIFT+D to toggle)
    _interfaces['dps_panel'] = InterfaceConfig(
      id: 'dps_panel',
      name: 'DPS Panel',
      description: 'Damage-per-second testing with target dummy',
      icon: Icons.bar_chart,
      category: 'ui_panels',
      shortcutKey: 'SHIFT+D',
      isVisible: true,
      position: const Offset(0, 0),
      defaultPosition: const Offset(0, 0),
    );

    // Ally Commands (Press F to toggle)
    _interfaces['ally_commands'] = InterfaceConfig(
      id: 'ally_commands',
      name: 'Ally Commands',
      description: 'Formation and command controls for allies',
      icon: Icons.groups,
      category: 'ui_panels',
      shortcutKey: 'F',
      isVisible: true,
      position: const Offset(0, 0),
      defaultPosition: const Offset(0, 0),
    );
  }

  /// Category display labels
  static const Map<String, String> _categoryLabels = {
    'game_abilities': 'Game Abilities',
    'ui_panels': 'UI Panels',
  };

  /// Ordered list of category IDs
  static const List<String> _categoryOrder = ['game_abilities', 'ui_panels'];

  /// Get ordered category IDs
  List<String> get categories => _categoryOrder;

  /// Get human-readable label for a category ID
  String categoryLabel(String id) => _categoryLabels[id] ?? id;

  /// Get all interfaces belonging to a specific category
  List<InterfaceConfig> interfacesForCategory(String category) =>
      _interfaces.values.where((i) => i.category == category).toList();

  /// Get all interface configs
  List<InterfaceConfig> get allInterfaces => _interfaces.values.toList();

  /// Get a specific interface config
  InterfaceConfig? getInterface(String id) => _interfaces[id];

  /// Check if an interface is visible
  bool isVisible(String id) => _interfaces[id]?.isVisible ?? false;

  /// Get interface position
  Offset getPosition(String id) =>
      _interfaces[id]?.position ?? const Offset(0, 0);

  /// Set interface visibility
  void setVisibility(String id, bool visible) {
    if (_interfaces.containsKey(id)) {
      _interfaces[id]!.isVisible = visible;
      onConfigChanged?.call();
    }
  }

  /// Set interface position
  void setPosition(String id, Offset position) {
    if (_interfaces.containsKey(id)) {
      _interfaces[id]!.position = position;
      onConfigChanged?.call();
    }
  }

  /// Toggle interface visibility
  void toggleVisibility(String id) {
    if (_interfaces.containsKey(id)) {
      _interfaces[id]!.isVisible = !_interfaces[id]!.isVisible;
      onConfigChanged?.call();
    }
  }

  /// Reset all positions to defaults
  void resetAllPositions() {
    for (final config in _interfaces.values) {
      config.resetPosition();
    }
    onConfigChanged?.call();
  }

  /// Reset a specific interface position
  void resetPosition(String id) {
    _interfaces[id]?.resetPosition();
    onConfigChanged?.call();
  }

  /// Show all interfaces
  void showAll() {
    for (final config in _interfaces.values) {
      config.isVisible = true;
    }
    onConfigChanged?.call();
  }

  /// Hide all optional interfaces (keep combat HUD)
  void hideAllOptional() {
    for (final config in _interfaces.values) {
      if (config.id != 'combat_hud') {
        config.isVisible = false;
      }
    }
    onConfigChanged?.call();
  }

  /// Save configuration to persistent storage
  Future<bool> saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configList = _interfaces.values.map((i) => i.toJson()).toList();
      final jsonString = jsonEncode(configList);
      await prefs.setString(_storageKey, jsonString);
      print('[InterfaceConfig] Saved configuration');
      return true;
    } catch (e) {
      print('[InterfaceConfig] Error saving: $e');
      return false;
    }
  }

  /// Load configuration from persistent storage
  Future<bool> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        print('[InterfaceConfig] No saved configuration found, using defaults');
        return false;
      }

      final configList = jsonDecode(jsonString) as List<dynamic>;

      for (final item in configList) {
        final json = item as Map<String, dynamic>;
        final id = json['id'] as String?;
        if (id != null && _interfaces.containsKey(id)) {
          _interfaces[id]!.updateFromJson(json);
        }
      }

      print('[InterfaceConfig] Loaded configuration');
      onConfigChanged?.call();
      return true;
    } catch (e) {
      print('[InterfaceConfig] Error loading: $e');
      return false;
    }
  }

  /// Export current configuration as JSON string
  String exportConfig() {
    final configList = _interfaces.values.map((i) => i.toJson()).toList();
    return jsonEncode(configList);
  }
}
