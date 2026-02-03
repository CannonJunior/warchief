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
  bool isVisible;
  Offset position;
  final Offset defaultPosition;

  InterfaceConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
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
    // Combat HUD (always visible, not toggleable)
    _interfaces['combat_hud'] = InterfaceConfig(
      id: 'combat_hud',
      name: 'Combat HUD',
      description: 'Player and target frames with action bar',
      icon: Icons.sports_martial_arts,
      isVisible: true,
      position: const Offset(0, 0), // Centered at bottom
      defaultPosition: const Offset(0, 0),
    );

    // Party Frames
    _interfaces['party_frames'] = InterfaceConfig(
      id: 'party_frames',
      name: 'Party Frames',
      description: 'Allied unit health and status',
      icon: Icons.group,
      isVisible: true,
      position: const Offset(0, 0), // Left of combat HUD
      defaultPosition: const Offset(0, 0),
    );

    // Monster Abilities Panel (Boss frame)
    _interfaces['monster_abilities'] = InterfaceConfig(
      id: 'monster_abilities',
      name: 'Boss Abilities',
      description: 'Boss monster health and abilities',
      icon: Icons.dangerous,
      isVisible: true,
      position: const Offset(10, 140), // Bottom-left
      defaultPosition: const Offset(10, 140),
    );

    // AI Chat Panel
    _interfaces['ai_chat'] = InterfaceConfig(
      id: 'ai_chat',
      name: 'AI Chat',
      description: 'Monster AI decision log',
      icon: Icons.chat,
      isVisible: true,
      position: const Offset(10, 10), // Bottom-left corner
      defaultPosition: const Offset(10, 10),
    );

    // Formation Panel
    _interfaces['formation_panel'] = InterfaceConfig(
      id: 'formation_panel',
      name: 'Formation Panel',
      description: 'Ally formation selector (SHIFT+R)',
      icon: Icons.grid_view,
      isVisible: true,
      position: const Offset(-200, 260), // Right side (negative = from right)
      defaultPosition: const Offset(-200, 260),
    );

    // Attack Command Panel
    _interfaces['attack_panel'] = InterfaceConfig(
      id: 'attack_panel',
      name: 'Attack Panel',
      description: 'Ally attack command (SHIFT+T)',
      icon: Icons.flash_on,
      isVisible: false,
      position: const Offset(-200, 350),
      defaultPosition: const Offset(-200, 350),
    );

    // Hold Command Panel
    _interfaces['hold_panel'] = InterfaceConfig(
      id: 'hold_panel',
      name: 'Hold Panel',
      description: 'Ally hold command (SHIFT+G)',
      icon: Icons.pan_tool,
      isVisible: false,
      position: const Offset(-350, 350),
      defaultPosition: const Offset(-350, 350),
    );

    // Follow Command Panel
    _interfaces['follow_panel'] = InterfaceConfig(
      id: 'follow_panel',
      name: 'Follow Panel',
      description: 'Ally follow command (SHIFT+F)',
      icon: Icons.directions_walk,
      isVisible: false,
      position: const Offset(-500, 350),
      defaultPosition: const Offset(-500, 350),
    );

    // Instructions Overlay
    _interfaces['instructions'] = InterfaceConfig(
      id: 'instructions',
      name: 'Instructions',
      description: 'Control hints and camera info',
      icon: Icons.help_outline,
      isVisible: true,
      position: const Offset(10, 10), // Top-left
      defaultPosition: const Offset(10, 10),
    );
  }

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
