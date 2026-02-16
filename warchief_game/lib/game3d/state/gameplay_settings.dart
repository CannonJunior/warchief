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

  /// When true, characters must equip a Talisman that attunes them to a
  /// mana color before they can regenerate, spend, or see that mana pool.
  /// When false, all characters have access to all three mana pools
  /// unconditionally (pre-talisman behavior).
  bool attunementRequired;

  /// When true, mana source visuals (Ley Lines for blue, wind particles
  /// for white) are hidden unless the active character is attuned to the
  /// corresponding color.  When false, all mana sources are always visible.
  bool manaSourceVisibilityGated;

  GameplaySettings({
    this.attunementRequired = true,
    this.manaSourceVisibilityGated = false,
  });

  /// Load saved settings from persistent storage.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      attunementRequired = prefs.getBool(_keyAttunementRequired) ?? true;
      manaSourceVisibilityGated = prefs.getBool(_keyManaSourceVisibility) ?? false;
      print('[GameplaySettings] Loaded: attunementRequired=$attunementRequired, '
          'manaSourceVisibilityGated=$manaSourceVisibilityGated');
    } catch (e) {
      print('[GameplaySettings] Error loading: $e');
    }
  }

  /// Persist current settings.
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAttunementRequired, attunementRequired);
      await prefs.setBool(_keyManaSourceVisibility, manaSourceVisibilityGated);
      print('[GameplaySettings] Saved');
    } catch (e) {
      print('[GameplaySettings] Error saving: $e');
    }
  }
}
