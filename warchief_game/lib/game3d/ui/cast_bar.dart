import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../state/gameplay_settings.dart';

/// Cast bar widget that shows the progress of spell casts and melee windups
///
/// Displays:
/// - A progress bar filling from left to right
/// - The ability name being cast/wound up
/// - Different colors for casts (blue) vs windups (orange)
class CastBar extends StatelessWidget {
  final GameState gameState;

  const CastBar({
    Key? key,
    required this.gameState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show if not casting, winding up, or channeling
    if (!gameState.isCasting && !gameState.isWindingUp && !gameState.isChanneling) {
      return const SizedBox.shrink();
    }

    // Reason: Channel bar can be hidden via settings; cast/windup bars always show
    if (gameState.isChanneling && !(globalGameplaySettings?.showChannelBar ?? true)) {
      return const SizedBox.shrink();
    }

    final bool isChannel = gameState.isChanneling;
    final bool isCast = !isChannel && gameState.isCasting;

    double progress;
    String abilityName;
    double totalTime;
    double currentTime;
    String label;

    if (isChannel) {
      // Reason: Channeling bar drains from full to empty (progress = remaining fraction)
      progress = gameState.channelPercentage;
      abilityName = gameState.channelingAbilityName;
      totalTime = gameState.channelDuration;
      currentTime = gameState.channelProgress;
      label = 'Channeling';
    } else if (isCast) {
      progress = gameState.castPercentage;
      abilityName = gameState.castingAbilityName;
      totalTime = gameState.currentCastTime;
      currentTime = gameState.castProgress;
      label = 'Casting';
    } else {
      progress = gameState.windupPercentage;
      abilityName = gameState.windupAbilityName;
      totalTime = gameState.currentWindupTime;
      currentTime = gameState.windupProgress;
      label = 'Winding Up';
    }

    // Colors
    final barColor = isChannel
        ? const Color(0xFF9B59B6) // Purple for channels
        : isCast
            ? const Color(0xFF4A90D9) // Blue for casts
            : const Color(0xFFD97B4A); // Orange for windups
    final bgColor = isChannel
        ? const Color(0xFF3A1A5C) // Dark purple bg
        : isCast
            ? const Color(0xFF1A3A5C) // Dark blue bg
            : const Color(0xFF5C3A1A); // Dark orange bg

    return Positioned(
      bottom: 140, // Above action bar
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 280,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: barColor.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: barColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                // Background
                Container(
                  color: bgColor,
                ),
                // Progress bar
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          barColor.withOpacity(0.8),
                          barColor,
                          barColor.withOpacity(0.9),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Shimmer effect on progress edge
                Positioned(
                  left: (280 * progress) - 5,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Text overlay
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ability name
                      Text(
                        abilityName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time remaining
                      Text(
                        '${(totalTime - currentTime).toStringAsFixed(1)}s',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Label (Casting/Winding Up)
                Positioned(
                  top: 2,
                  left: 6,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: barColor.withOpacity(0.8),
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact cast bar for showing in a smaller format (e.g., on unit frames)
class CompactCastBar extends StatelessWidget {
  final double progress;
  final String abilityName;
  final bool isCast; // true = cast, false = windup
  final double width;
  final double height;

  const CompactCastBar({
    Key? key,
    required this.progress,
    required this.abilityName,
    this.isCast = true,
    this.width = 120,
    this.height = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final barColor = isCast
        ? const Color(0xFF4A90D9)
        : const Color(0xFFD97B4A);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: barColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Stack(
          children: [
            // Progress bar
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                color: barColor,
              ),
            ),
            // Text
            Center(
              child: Text(
                abilityName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
