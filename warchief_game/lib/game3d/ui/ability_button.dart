import 'package:flutter/material.dart';
import 'cooldown_clock_painter.dart';

/// Reusable ability button with cooldown animation
class AbilityButton extends StatelessWidget {
  final String label;
  final Color color;
  final double cooldown;
  final double maxCooldown;
  final VoidCallback? onPressed;
  final double size;
  final bool isOutOfRange;
  final String? tooltipText;

  const AbilityButton({
    Key? key,
    required this.label,
    required this.color,
    required this.cooldown,
    required this.maxCooldown,
    this.onPressed,
    this.size = 48,
    this.isOutOfRange = false,
    this.tooltipText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOnCooldown = cooldown > 0;
    final isDisabled = isOnCooldown || (isOutOfRange && !isOnCooldown);
    final progress = isOnCooldown ? (1.0 - (cooldown / maxCooldown)) : 1.0;
    final fontSize = size > 50 ? 24.0 : (size > 35 ? 16.0 : 12.0);
    final cooldownFontSize = size > 50 ? 10.0 : 8.0;

    final button = InkWell(
      onTap: isDisabled || onPressed == null ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
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
                color: isOnCooldown
                    ? Colors.grey.shade700
                    : isOutOfRange
                        ? Colors.grey.shade800
                        : color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Out-of-range red tint overlay
            if (isOutOfRange && !isOnCooldown)
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            // Cooldown clock animation
            if (isOnCooldown)
              CustomPaint(
                size: Size(size, size),
                painter: CooldownClockPainter(progress: progress),
              ),
            // Label
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isOnCooldown
                      ? Colors.white38
                      : isOutOfRange
                          ? Colors.white30
                          : Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Cooldown text
            if (isOnCooldown)
              Positioned(
                bottom: 2,
                right: 2,
                child: Text(
                  cooldown.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: cooldownFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (tooltipText != null && tooltipText!.isNotEmpty) {
      return Tooltip(
        message: tooltipText!,
        preferBelow: false,
        verticalOffset: size / 2 + 4,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.cyan, width: 1),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        waitDuration: const Duration(milliseconds: 300),
        child: button,
      );
    }

    return button;
  }
}
