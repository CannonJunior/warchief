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
          // Health circles
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(4, (index) {
              return Container(
                margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  border: Border.all(color: Colors.red.shade900, width: 3),
                ),
              );
            }),
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
