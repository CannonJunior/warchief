import 'package:flutter/material.dart';
import '../state/game_state.dart';

/// Compact flight buff icon shown above the player UnitFrame when flying.
///
/// Displays a wing glyph with altitude readout and mana drain info.
/// Pulses gently; turns red when White Mana drops below the low-mana threshold.
class FlightBuffIcon extends StatefulWidget {
  final GameState gameState;

  const FlightBuffIcon({Key? key, required this.gameState}) : super(key: key);

  @override
  State<FlightBuffIcon> createState() => _FlightBuffIconState();
}

class _FlightBuffIconState extends State<FlightBuffIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gameState;
    final lowMana = gs.whiteMana < 33.0;
    final altitude = gs.flightAltitude;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final opacity = 0.7 + _pulseController.value * 0.3;
        final glowColor = lowMana
            ? Colors.red.withValues(alpha: 0.6 + _pulseController.value * 0.4)
            : Colors.white.withValues(alpha: 0.3 + _pulseController.value * 0.4);

        return Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: lowMana
                ? const Color(0xFF3A1A1A).withValues(alpha: 0.9)
                : const Color(0xFF1A1A2E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: lowMana
                  ? Colors.red.withValues(alpha: 0.7)
                  : const Color(0xFF4CC9F0).withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Opacity(
            opacity: opacity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Wing icon
                Text(
                  '\u{1F54A}', // Dove / wing glyph
                  style: TextStyle(
                    fontSize: 14,
                    color: lowMana ? Colors.red.shade300 : Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                // Flight info
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FLYING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: lowMana ? Colors.red.shade200 : const Color(0xFF4CC9F0),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Alt: ${altitude.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 8,
                          color: lowMana ? Colors.red.shade100 : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Low mana warning
                if (lowMana)
                  Text(
                    'LOW',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade300,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
