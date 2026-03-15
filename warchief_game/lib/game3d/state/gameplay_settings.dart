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
  static const String _keyUiFontFamily       = 'gameplay_ui_font_family';
  static const String _keyCombatFontFamily   = 'gameplay_combat_font_family';
  static const String _keyQueueFontFamily    = 'gameplay_queue_font_family';
  static const String _keyUiFontScale        = 'gameplay_ui_font_scale';
  static const String _keyQueueFontScale     = 'gameplay_queue_font_scale';
  static const String _keyCombatDamageColor       = 'gameplay_combat_damage_color';
  static const String _keyCombatHealColor         = 'gameplay_combat_heal_color';
  static const String _keyCombatKillColor         = 'gameplay_combat_kill_color';
  static const String _keyCombatShadow            = 'gameplay_combat_shadow';
  static const String _keyQueueTextColor          = 'gameplay_queue_text_color';
  static const String _keyTargetEnemyColor        = 'gameplay_target_enemy_color';
  static const String _keyTargetAllyColor         = 'gameplay_target_ally_color';
  static const String _keyTargetAcquiredColor     = 'gameplay_target_acquired_color';
  static const String _keyTargetLineWidth         = 'gameplay_target_line_width';
  static const String _keyTargetSizeScale         = 'gameplay_target_size_scale';
  static const String _keyTargetAcquiredScale     = 'gameplay_target_acquired_scale';
  static const String _keyTargetAcquiredDuration  = 'gameplay_target_acquired_duration';
  static const String _keyQueueExitDuration        = 'gameplay_queue_exit_duration';

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

  /// Font family for all game interface text. 'Default' means no override.
  String uiFontFamily;

  /// Font family for floating combat numbers (damage/heal).
  String combatFontFamily;

  /// Font family for the ability queue text overlay.
  String queueFontFamily;

  /// Scale factor for interface text size (1.0 = default).
  double uiFontScale;

  /// Scale factor for the ability queue text size (1.0 = default).
  double queueFontScale;

  /// ARGB color value for floating damage numbers (default: bright yellow).
  int combatDamageColor;

  /// ARGB color value for floating heal numbers (default: bright green).
  int combatHealColor;

  /// ARGB color value for killing-blow numbers at peak (default: bright red).
  int combatKillColor;

  /// Whether floating combat numbers have a drop shadow.
  bool combatShadow;

  /// ARGB color value for ability queue text when not on cooldown.
  int queueTextColor;

  /// ARGB color for the enemy/hostile target rectangle (default red).
  int targetEnemyColor;

  /// ARGB color for the ally target rectangle (default green).
  int targetAllyColor;

  /// ARGB color for the "target acquired" flash rectangle (default yellow).
  int targetAcquiredColor;

  /// Line thickness of target indicator rectangles (world units, default 0.10).
  double targetLineWidth;

  /// Multiplier applied to the base entity size when sizing indicators (default 1.0).
  double targetSizeScale;

  /// Multiplier for the acquired-flash rectangle relative to the main indicator (default 1.3).
  double targetAcquiredScale;

  /// How long the acquired-flash rectangle stays visible in seconds (default 2.0).
  double targetAcquiredDuration;

  /// Duration of the fade-out exit animation for queue entries that have
  /// finished executing, in seconds (default 1.0).
  double queueExitDuration;

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
    this.uiFontFamily      = 'Default',
    this.combatFontFamily  = 'Bangers',
    this.queueFontFamily   = 'Bangers',
    this.uiFontScale       = 1.0,
    this.queueFontScale    = 1.0,
    this.combatDamageColor       = 0xFFFFDD00,
    this.combatHealColor         = 0xFF44FF44,
    this.combatKillColor         = 0xFFFF2222,
    this.combatShadow            = true,
    this.queueTextColor          = 0xFFFFFFFF,
    this.targetEnemyColor        = 0xFFFF3333,
    this.targetAllyColor         = 0xFF33FF44,
    this.targetAcquiredColor     = 0xFFFFF200,
    this.targetLineWidth         = 0.10,
    this.targetSizeScale         = 1.0,
    this.targetAcquiredScale     = 1.3,
    this.targetAcquiredDuration  = 2.0,
    this.queueExitDuration       = 1.0,
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
      showAbilityRanges  = prefs.getBool(_keyShowAbilityRanges)    ?? false;
      uiFontFamily       = prefs.getString(_keyUiFontFamily)         ?? 'Default';
      combatFontFamily   = prefs.getString(_keyCombatFontFamily)     ?? 'Bangers';
      queueFontFamily    = prefs.getString(_keyQueueFontFamily)      ?? 'Bangers';
      uiFontScale        = prefs.getDouble(_keyUiFontScale)          ?? 1.0;
      queueFontScale     = prefs.getDouble(_keyQueueFontScale)       ?? 1.0;
      combatDamageColor       = prefs.getInt(_keyCombatDamageColor)       ?? 0xFFFFDD00;
      combatHealColor         = prefs.getInt(_keyCombatHealColor)         ?? 0xFF44FF44;
      combatKillColor         = prefs.getInt(_keyCombatKillColor)         ?? 0xFFFF2222;
      combatShadow            = prefs.getBool(_keyCombatShadow)           ?? true;
      queueTextColor          = prefs.getInt(_keyQueueTextColor)          ?? 0xFFFFFFFF;
      targetEnemyColor        = prefs.getInt(_keyTargetEnemyColor)        ?? 0xFFFF3333;
      targetAllyColor         = prefs.getInt(_keyTargetAllyColor)         ?? 0xFF33FF44;
      targetAcquiredColor     = prefs.getInt(_keyTargetAcquiredColor)     ?? 0xFFFFF200;
      targetLineWidth         = prefs.getDouble(_keyTargetLineWidth)      ?? 0.10;
      targetSizeScale         = prefs.getDouble(_keyTargetSizeScale)      ?? 1.0;
      targetAcquiredScale     = prefs.getDouble(_keyTargetAcquiredScale)  ?? 1.3;
      targetAcquiredDuration  = prefs.getDouble(_keyTargetAcquiredDuration) ?? 2.0;
      queueExitDuration       = prefs.getDouble(_keyQueueExitDuration)      ?? 1.0;
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
      await prefs.setString(_keyUiFontFamily,       uiFontFamily);
      await prefs.setString(_keyCombatFontFamily,   combatFontFamily);
      await prefs.setString(_keyQueueFontFamily,    queueFontFamily);
      await prefs.setDouble(_keyUiFontScale,        uiFontScale);
      await prefs.setDouble(_keyQueueFontScale,     queueFontScale);
      await prefs.setInt(_keyCombatDamageColor,          combatDamageColor);
      await prefs.setInt(_keyCombatHealColor,            combatHealColor);
      await prefs.setInt(_keyCombatKillColor,            combatKillColor);
      await prefs.setBool(_keyCombatShadow,              combatShadow);
      await prefs.setInt(_keyQueueTextColor,             queueTextColor);
      await prefs.setInt(_keyTargetEnemyColor,           targetEnemyColor);
      await prefs.setInt(_keyTargetAllyColor,            targetAllyColor);
      await prefs.setInt(_keyTargetAcquiredColor,        targetAcquiredColor);
      await prefs.setDouble(_keyTargetLineWidth,         targetLineWidth);
      await prefs.setDouble(_keyTargetSizeScale,         targetSizeScale);
      await prefs.setDouble(_keyTargetAcquiredScale,     targetAcquiredScale);
      await prefs.setDouble(_keyTargetAcquiredDuration,  targetAcquiredDuration);
      await prefs.setDouble(_keyQueueExitDuration,        queueExitDuration);
      debugPrint('[GameplaySettings] Saved');
    } catch (e) {
      debugPrint('[GameplaySettings] Error saving: $e');
    }
  }
}
