import 'package:flutter/material.dart';
import 'cooldown_clock_painter.dart';

/// Reusable ability button with cooldown animation
class AbilityButton extends StatelessWidget {
  final String label;
  final Color color;
  final double cooldown;
  final double maxCooldown;
  final VoidCallback? onPressed;

  const AbilityButton({
    Key? key,
    required this.label,
    required this.color,
    required this.cooldown,
    required this.maxCooldown,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOnCooldown = cooldown > 0;
    final progress = isOnCooldown ? (1.0 - (cooldown / maxCooldown)) : 1.0;

    return InkWell(
      onTap: isOnCooldown || onPressed == null ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: Colors.white30, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Base color
            Container(
              decoration: BoxDecoration(
                color: isOnCooldown ? Colors.grey.shade700 : color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Cooldown clock animation
            if (isOnCooldown)
              CustomPaint(
                size: Size(60, 60),
                painter: CooldownClockPainter(progress: progress),
              ),
            // Label
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isOnCooldown ? Colors.white38 : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Cooldown text
            if (isOnCooldown)
              Positioned(
                bottom: 4,
                right: 4,
                child: Text(
                  cooldown.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
