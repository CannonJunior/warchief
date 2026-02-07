/// UI Layout Configuration
///
/// Centralized configuration for all UI element positions and spacing.
/// Edit values in this file to reposition HUD elements without touching widget code.
class UIConfig {
  UIConfig._(); // Private constructor

  // ==================== PLAYER HUD POSITIONING ====================

  /// Player HUD vertical position from top of screen
  static const double playerHudTop = 120.0;

  /// Player HUD horizontal position from right of screen
  static const double playerHudRight = 20.0;

  // ==================== ALLIES PANEL POSITIONING ====================

  /// Allies panel vertical position from top of screen
  /// Note: Should be below Player HUD to avoid overlap
  static const double alliesPanelTop = 300.0;

  /// Allies panel horizontal position from right of screen
  static const double alliesPanelRight = 20.0;

  // ==================== MONSTER HUD POSITIONING ====================

  /// Monster HUD vertical position from top of screen
  static const double monsterHudTop = 360.0;

  /// Monster HUD horizontal position from left of screen
  static const double monsterHudLeft = 10.0;

  // ==================== AI CHAT PANEL POSITIONING ====================

  /// AI Chat panel vertical position from top of screen
  static const double aiChatPanelTop = 640.0;

  /// AI Chat panel horizontal position from left of screen
  static const double aiChatPanelLeft = 10.0;

  // ==================== SPACING CONSTANTS ====================

  /// Standard spacing between UI elements
  static const double standardSpacing = 12.0;

  /// Small spacing for compact layouts
  static const double smallSpacing = 8.0;

  /// Large spacing for separated sections
  static const double largeSpacing = 20.0;

  // ==================== SIZE CONSTANTS ====================

  /// Standard health bar width
  static const double healthBarWidth = 200.0;

  /// Standard health bar height
  static const double healthBarHeight = 24.0;

  /// Ally health bar width (smaller)
  static const double allyHealthBarWidth = 150.0;

  /// Ally health bar height
  static const double allyHealthBarHeight = 20.0;

  /// Standard ability button size
  static const double abilityButtonSize = 50.0;

  /// Ally ability button size (smaller)
  static const double allyAbilityButtonSize = 40.0;

  /// Action bar ability button size (matches AbilityButton default)
  /// Used by both the action bar hotkeys and the Abilities Codex icons
  static const double actionBarButtonSize = 48.0;
}
