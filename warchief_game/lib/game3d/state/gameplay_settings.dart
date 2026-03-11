import 'package:flutter/foundation.dart' show debugPrint;
/// Gameplay Settings — global toggles for optional game mechanics.
///
/// Persists to SharedPreferences so settings survive across sessions.
/// Access via the [globalGameplaySettings] singleton, initialized in
/// game3d_widget.dart alongside other config singletons.

import 'package:shared_preferences/shared_preferences.dart';

/// Global singleton — set in game3d_widget.dart during initialization.
GameplaySettings? globalGameplaySettings;

class GameplaySettings {
  static const String _keyAttunementRequired = 'gameplay_attunement_required';
  static const String _keyManaSourceVisibility = 'gameplay_mana_source_visibility';
  static const String _keyShowDamageNumbers = 'gameplay_show_damage_numbers';
  static const String _keyShowHealNumbers = 'gameplay_show_heal_numbers';
  static const String _keyShowChannelBar = 'gameplay_show_channel_bar';
  static const String _keyDamageNumberScale = 'gameplay_damage_number_scale';
  static const String _keyShowFpsCounter = 'gameplay_show_fps_counter';
  static const String _keyShowDebugInfo = 'gameplay_show_debug_info';
  static const String _keyShowAbilityRanges = 'gameplay_show_ability_ranges';

  /// When true, characters must equip a Talisman that attunes them to a
  /// mana color before they can regenerate, spend, or see that mana pool.
  /// When false, all characters have access to all three mana pools
  /// unconditionally (pre-talisman behavior).
  bool attunementRequired;

  /// When true, mana source visuals (Ley Lines for blue, wind particles
  /// for white) are hidden unless the active character is attuned to the
  /// corresponding color.  When false, all mana sources are always visible.
  bool manaSourceVisibilityGated;

  /// Show floating damage numbers above targets.
  bool showDamageNumbers;

  /// Show floating green heal numbers above healed units.
  bool showHealNumbers;

  /// Show the channeling progress bar during channeled abilities.
  bool showChannelBar;

  /// Scale factor for damage/heal number font size (1.0 = default).
  double damageNumberScale;

  /// Show a live FPS counter in the top-right corner of the game viewport.
  bool showFpsCounter;

  /// Show an extended debug overlay with frame time, entity counts, etc.
  bool showDebugInfo;

  /// When true, hovering a hotkey shows a range circle around the active unit.
  bool showAbilityRanges;

  GameplaySettings({
    this.attunementRequired = true,
    this.manaSourceVisibilityGated = false,
    this.showDamageNumbers = true,
    this.showHealNumbers = true,
    this.showChannelBar = true,
    this.damageNumberScale = 1.0,
    this.showFpsCounter = false,
    this.showDebugInfo = false,
    this.showAbilityRanges = false,
  });

  /// Load saved settings from persistent storage.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      attunementRequired = prefs.getBool(_keyAttunementRequired) ?? true;
      manaSourceVisibilityGated = prefs.getBool(_keyManaSourceVisibility) ?? false;
      showDamageNumbers = prefs.getBool(_keyShowDamageNumbers) ?? true;
      showHealNumbers = prefs.getBool(_keyShowHealNumbers) ?? true;
      showChannelBar = prefs.getBool(_keyShowChannelBar) ?? true;
      damageNumberScale = prefs.getDouble(_keyDamageNumberScale) ?? 1.0;
      showFpsCounter = prefs.getBool(_keyShowFpsCounter) ?? false;
      showDebugInfo = prefs.getBool(_keyShowDebugInfo) ?? false;
      showAbilityRanges = prefs.getBool(_keyShowAbilityRanges) ?? false;
      debugPrint('[GameplaySettings] Loaded: attunementRequired=$attunementRequired, '
          'manaSourceVisibilityGated=$manaSourceVisibilityGated, '
          'showDamageNumbers=$showDamageNumbers, showHealNumbers=$showHealNumbers, '
          'showChannelBar=$showChannelBar, damageNumberScale=$damageNumberScale, '
          'showFpsCounter=$showFpsCounter, showDebugInfo=$showDebugInfo');
    } catch (e) {
      debugPrint('[GameplaySettings] Error loading: $e');
    }
  }

  /// Persist current settings.
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAttunementRequired, attunementRequired);
      await prefs.setBool(_keyManaSourceVisibility, manaSourceVisibilityGated);
      await prefs.setBool(_keyShowDamageNumbers, showDamageNumbers);
      await prefs.setBool(_keyShowHealNumbers, showHealNumbers);
      await prefs.setBool(_keyShowChannelBar, showChannelBar);
      await prefs.setDouble(_keyDamageNumberScale, damageNumberScale);
      await prefs.setBool(_keyShowFpsCounter, showFpsCounter);
      await prefs.setBool(_keyShowDebugInfo, showDebugInfo);
      await prefs.setBool(_keyShowAbilityRanges, showAbilityRanges);
      debugPrint('[GameplaySettings] Saved');
    } catch (e) {
      debugPrint('[GameplaySettings] Error saving: $e');
    }
  }
}
