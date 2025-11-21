import 'package:flutter/material.dart';
import '../state/game_state.dart';
import 'ability_button.dart';

/// Player HUD displaying health circles and ability buttons
class PlayerHud extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onAbility1Pressed;
  final VoidCallback onAbility2Pressed;
  final VoidCallback onAbility3Pressed;

  const PlayerHud({
    Key? key,
    required this.gameState,
    required this.onAbility1Pressed,
    required this.onAbility2Pressed,
    required this.onAbility3Pressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Player label
          Text(
            'PLAYER',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8),
          // Health bar
          Container(
            width: 200,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade600, width: 2),
            ),
            child: Stack(
              children: [
                // Health fill
                FractionallySizedBox(
                  widthFactor: (gameState.playerHealth / gameState.playerMaxHealth).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: gameState.playerHealth > 50 ? Colors.green :
                             gameState.playerHealth > 25 ? Colors.orange : Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Health text
                Center(
                  child: Text(
                    '${gameState.playerHealth.toStringAsFixed(0)} / ${gameState.playerMaxHealth.toStringAsFixed(0)}',
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AbilityButton(
                label: '1',
                color: Color(0xFFB3B3CC), // Gray (sword)
                cooldown: gameState.ability1Cooldown,
                maxCooldown: gameState.ability1CooldownMax,
                onPressed: onAbility1Pressed,
              ),
              SizedBox(width: 10),
              AbilityButton(
                label: '2',
                color: Color(0xFFFF6600), // Orange (fireball)
                cooldown: gameState.ability2Cooldown,
                maxCooldown: gameState.ability2CooldownMax,
                onPressed: onAbility2Pressed,
              ),
              SizedBox(width: 10),
              AbilityButton(
                label: '3',
                color: Color(0xFF80FF4D), // Green (heal)
                cooldown: gameState.ability3Cooldown,
                maxCooldown: gameState.ability3CooldownMax,
                onPressed: onAbility3Pressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
