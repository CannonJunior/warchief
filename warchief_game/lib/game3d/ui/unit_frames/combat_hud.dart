import 'package:flutter/material.dart';
import '../ability_button.dart';
import '../mana_bar.dart';
import 'unit_frame.dart';
import 'vs_indicator.dart';
import 'buff_debuff_icons.dart';
import 'stance_icon_bar.dart';
import '../../state/action_bar_config.dart';
import '../../state/game_state.dart';
import '../../data/abilities/ability_types.dart';
import '../flight_buff_icon.dart';

part 'combat_hud_action_bar.dart';
part 'combat_hud_portraits.dart';

/// Main combat HUD with player frame, target frame, VS indicator, and action bars
/// Positioned at bottom-center of screen
class CombatHUD extends StatelessWidget {
  // Player data
  final String playerName;
  final double playerHealth;
  final double playerMaxHealth;
  final double? playerPower;
  final double? playerMaxPower;
  final int playerLevel;
  final Widget? playerPortraitWidget; // Custom portrait widget (e.g., 3D cube)

  // Mana data (for Ley Line-based mana system)
  final GameState? gameState; // For mana bar display

  // Target data
  final String? targetName;
  final double targetHealth;
  final double targetMaxHealth;
  final double targetMana;
  final double targetMaxMana;
  final int? targetLevel;
  final bool hasTarget;
  final Widget? targetPortraitWidget; // Custom portrait widget (e.g., 3D cube)

  // Ability cooldowns (slots 0-9)
  final List<double> abilityCooldowns;
  final List<double> abilityCooldownMaxes;

  // Callbacks
  final VoidCallback onAbility1Pressed;
  final VoidCallback onAbility2Pressed;
  final VoidCallback onAbility3Pressed;
  final VoidCallback? onAbility4Pressed;
  final VoidCallback? onAbility5Pressed;
  final VoidCallback? onAbility6Pressed;
  final VoidCallback? onAbility7Pressed;
  final VoidCallback? onAbility8Pressed;
  final VoidCallback? onAbility9Pressed;
  final VoidCallback? onAbility10Pressed;

  // Target frame colors (friendly = green, enemy = red)
  final Color targetBorderColor;
  final Color targetHealthColor;

  // Target of Target (ToT) data
  final String? totName;
  final double totHealth;
  final double totMaxHealth;
  final int? totLevel;
  final Widget? totPortraitWidget;
  final Color totBorderColor;
  final Color totHealthColor;

  // Action bar configuration (for drag-and-drop)
  final ActionBarConfig? actionBarConfig;
  final Function(int slotIndex, String abilityName)? onAbilityDropped;

  // Callback when stance or other state changes (triggers parent rebuild)
  final VoidCallback? onStateChanged;

  const CombatHUD({
    Key? key,
    required this.playerName,
    required this.playerHealth,
    required this.playerMaxHealth,
    this.playerPower,
    this.playerMaxPower,
    this.playerLevel = 1,
    this.playerPortraitWidget,
    this.gameState,
    this.targetName,
    required this.targetHealth,
    required this.targetMaxHealth,
    this.targetMana = 0.0,
    this.targetMaxMana = 0.0,
    this.targetLevel,
    this.hasTarget = true,
    this.targetPortraitWidget,
    required this.abilityCooldowns,
    required this.abilityCooldownMaxes,
    required this.onAbility1Pressed,
    required this.onAbility2Pressed,
    required this.onAbility3Pressed,
    this.onAbility4Pressed,
    this.onAbility5Pressed,
    this.onAbility6Pressed,
    this.onAbility7Pressed,
    this.onAbility8Pressed,
    this.onAbility9Pressed,
    this.onAbility10Pressed,
    this.targetBorderColor = const Color(0xFFFF6B6B),
    this.targetHealthColor = const Color(0xFFEF5350),
    this.totName,
    this.totHealth = 0.0,
    this.totMaxHealth = 1.0,
    this.totLevel,
    this.totPortraitWidget,
    this.totBorderColor = const Color(0xFF888888),
    this.totHealthColor = const Color(0xFF4CAF50),
    this.actionBarConfig,
    this.onAbilityDropped,
    this.onStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Unit frames row (Player - VS - Target)
        _buildUnitFramesRow(),
        const SizedBox(height: 8),
        // Action bar
        _buildActionBar(),
      ],
    );
  }

  Widget _buildUnitFramesRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, // Align at top
      children: [
        // Player frame with buff/debuff icons ABOVE (prevents layout shift)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buff/debuff icons above the player frame so they don't shift the layout
            if (gameState != null && gameState!.activeCharacterActiveEffects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: BuffDebuffIcons(
                  effects: gameState!.activeCharacterActiveEffects,
                  maxWidth: 200,
                ),
              ),
            // Flight buff icon (above player frame when flying)
            if (gameState != null && gameState!.isFlying)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: FlightBuffIcon(gameState: gameState!),
              ),
            // Stance icon bar (above player health bar)
            if (gameState != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: StanceIconBar(
                  gameState: gameState!,
                  onStateChanged: onStateChanged,
                ),
              ),
            // Player frame (portrait on left)
            UnitFrame(
              name: playerName,
              health: playerHealth,
              maxHealth: playerMaxHealth,
              power: playerPower,
              maxPower: playerMaxPower,
              isPlayer: true,
              level: playerLevel,
              portraitWidget: playerPortraitWidget,
              borderColor: const Color(0xFF4cc9f0),
              healthColor: const Color(0xFF4CAF50),
              powerColor: const Color(0xFF2196F3),
              width: 200,
            ),
            // Mana bar below player frame (same width)
            if (gameState != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ManaBar(
                  gameState: gameState!,
                  width: 200,
                  height: 14,
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // VS indicator
        if (hasTarget) const VSIndicator(inCombat: true),
        if (hasTarget) const SizedBox(width: 12),
        // Target frame with buff/debuff icons ABOVE (prevents layout shift)
        if (hasTarget)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buff/debuff icons above the target frame so they don't shift the layout
              if (gameState != null && gameState!.currentTargetActiveEffects.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: BuffDebuffIcons(
                    effects: gameState!.currentTargetActiveEffects,
                    maxWidth: 200,
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  UnitFrame(
                    name: targetName ?? 'Unknown',
                    health: targetHealth,
                    maxHealth: targetMaxHealth,
                    isPlayer: false,
                    level: targetLevel,
                    portraitWidget: targetPortraitWidget,
                    borderColor: targetBorderColor,
                    healthColor: targetHealthColor,
                    width: 200,
                  ),
                  // Target mana bar below target frame (same width as player's)
                  if (targetMaxMana > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildTargetManaBar(),
                    ),
                  // Target of Target (33% smaller unit frame)
                  if (totName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: UnitFrame(
                        name: totName!,
                        health: totHealth,
                        maxHealth: totMaxHealth,
                        isPlayer: false,
                        level: totLevel,
                        portraitWidget: totPortraitWidget,
                        borderColor: totBorderColor,
                        healthColor: totHealthColor,
                        width: 133,
                      ),
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTargetManaBar() {
    final manaPercent = targetMaxMana > 0
        ? (targetMana / targetMaxMana).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF1A1A3A),
          width: 1,
        ),
      ),
      child: SizedBox(
        height: 14,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: [
              // Background
              Container(color: const Color(0xFF0A0A1A)),
              // Mana fill
              FractionallySizedBox(
                widthFactor: manaPercent,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2060CC),
                        Color(0xFF4080FF),
                        Color(0xFF60A0FF),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Text overlay
              Center(
                child: Text(
                  '${targetMana.toInt()} / ${targetMaxMana.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
