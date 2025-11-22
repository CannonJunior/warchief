import 'package:flutter/material.dart';
import '../state/game_state.dart';
import 'ability_button.dart';
import 'ui_config.dart';

/// Monster HUD displaying health bar, ability buttons, and pause button
class MonsterHud extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onAbility1Pressed;
  final VoidCallback onAbility2Pressed;
  final VoidCallback onAbility3Pressed;
  final VoidCallback onPauseToggle;

  const MonsterHud({
    Key? key,
    required this.gameState,
    required this.onAbility1Pressed,
    required this.onAbility2Pressed,
    required this.onAbility3Pressed,
    required this.onPauseToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: UIConfig.monsterHudTop,
      left: UIConfig.monsterHudLeft,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monster label
            Text(
              'BOSS MONSTER',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8),
            // Health bar
            Container(
              width: UIConfig.healthBarWidth,
              height: UIConfig.healthBarHeight,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade600, width: 2),
              ),
              child: Stack(
                children: [
                  // Health fill
                  FractionallySizedBox(
                    widthFactor: (gameState.monsterHealth / gameState.monsterMaxHealth).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: gameState.monsterHealth > 50 ? Colors.green :
                               gameState.monsterHealth > 25 ? Colors.orange : Colors.red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Health text
                  Center(
                    child: Text(
                      '${gameState.monsterHealth.toStringAsFixed(0)} / ${gameState.monsterMaxHealth.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            // Ability buttons
            Row(
              children: [
                AbilityButton(
                  label: 'M1',
                  color: Color(0xFF9B59B6), // Purple
                  cooldown: gameState.monsterAbility1Cooldown,
                  maxCooldown: gameState.monsterAbility1CooldownMax,
                  onPressed: onAbility1Pressed,
                ),
                SizedBox(width: 8),
                AbilityButton(
                  label: 'M2',
                  color: Color(0xFF8E44AD), // Darker purple
                  cooldown: gameState.monsterAbility2Cooldown,
                  maxCooldown: gameState.monsterAbility2CooldownMax,
                  onPressed: onAbility2Pressed,
                ),
                SizedBox(width: 8),
                AbilityButton(
                  label: 'M3',
                  color: Color(0xFF6C3483), // Even darker purple
                  cooldown: gameState.monsterAbility3Cooldown,
                  maxCooldown: gameState.monsterAbility3CooldownMax,
                  onPressed: onAbility3Pressed,
                ),
              ],
            ),
            SizedBox(height: 12),
            // Pause button for monster AI
            ElevatedButton(
              onPressed: onPauseToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: gameState.monsterPaused ? Colors.green : Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                gameState.monsterPaused ? 'Resume Monster' : 'Pause Monster',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
