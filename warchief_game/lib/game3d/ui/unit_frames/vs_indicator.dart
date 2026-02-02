import 'package:flutter/material.dart';

/// VS indicator widget that sits between player and target frames
class VSIndicator extends StatelessWidget {
  final bool inCombat;
  final Color playerColor;
  final Color targetColor;

  const VSIndicator({
    Key? key,
    this.inCombat = true,
    this.playerColor = const Color(0xFF4cc9f0),
    this.targetColor = const Color(0xFFFF6B6B),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF252542),
            const Color(0xFF1a1a2e),
          ],
        ),
        border: Border.all(
          color: inCombat ? const Color(0xFFFF4444) : const Color(0xFF404060),
          width: 2,
        ),
        boxShadow: [
          if (inCombat)
            BoxShadow(
              color: const Color(0xFFFF4444).withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [playerColor, targetColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'VS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Combat status indicator (shows sword icons when in combat)
class CombatIndicator extends StatelessWidget {
  final bool inCombat;

  const CombatIndicator({
    Key? key,
    this.inCombat = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!inCombat) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4444).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF4444).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '\u{2694}', // crossed swords
            style: TextStyle(fontSize: 12),
          ),
          SizedBox(width: 4),
          Text(
            'IN COMBAT',
            style: TextStyle(
              color: Color(0xFFFF4444),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
