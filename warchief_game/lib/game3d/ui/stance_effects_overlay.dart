import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../data/stances/stances.dart';

/// Full-screen overlay for stance visual effects.
///
/// Renders two effects:
/// - **Drunken Master re-roll pulse**: Brief purple tint flash when modifiers re-roll.
/// - **Fury of the Ancestors vignette**: Red radial gradient that intensifies as HP drops.
class StanceEffectsOverlay extends StatelessWidget {
  final GameState gameState;

  const StanceEffectsOverlay({Key? key, required this.gameState})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stance = gameState.activeStance;
    final children = <Widget>[];

    // Drunken Master: brief purple tint pulse on re-roll
    if (gameState.drunkenRerollPulseTimer > 0) {
      // Reason: alpha fades from 0.15 to 0 over 0.4s for a quick flash
      final alpha = (gameState.drunkenRerollPulseTimer / 0.4) * 0.15;
      children.add(
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Color.fromRGBO(153, 76, 178, alpha.clamp(0.0, 0.15)),
            ),
          ),
        ),
      );
    }

    // Fury of the Ancestors: red vignette that intensifies as HP drops
    if (stance.healthDrainPerSecond > 0) {
      final maxHp = gameState.activeMaxHealth;
      final currentHp = gameState.activeHealth;
      final hpFraction = maxHp > 0 ? (currentHp / maxHp) : 1.0;
      // Reason: vignette opacity scales from 0.0 (full HP) to 0.6 (near death)
      // Starts becoming visible below 80% HP
      final intensity = ((1.0 - hpFraction) * 0.75).clamp(0.0, 0.6);

      if (intensity > 0.02) {
        children.add(
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Color.fromRGBO(180, 20, 20, intensity * 0.5),
                      Color.fromRGBO(120, 0, 0, intensity),
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Stack(children: children);
  }
}
