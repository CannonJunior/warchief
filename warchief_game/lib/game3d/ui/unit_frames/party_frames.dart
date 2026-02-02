import 'package:flutter/material.dart';
import '../../../models/ally.dart';
import 'unit_frame.dart';

/// Vertical stack of party/ally frames (left side of screen)
class PartyFrames extends StatelessWidget {
  final List<Ally> allies;
  final int? selectedIndex;
  final void Function(int index)? onAllySelected;
  final void Function(Ally ally)? onAllyAbilityActivate;

  const PartyFrames({
    Key? key,
    required this.allies,
    this.selectedIndex,
    this.onAllySelected,
    this.onAllyAbilityActivate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (allies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF252542),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\u{1F46A}', // family emoji
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(width: 6),
                Text(
                  'PARTY',
                  style: TextStyle(
                    color: Color(0xFF4cc9f0),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          // Ally frames
          ...allies.asMap().entries.map((entry) {
            final index = entry.key;
            final ally = entry.value;
            return _buildAllyFrame(ally, index);
          }),
        ],
      ),
    );
  }

  Widget _buildAllyFrame(Ally ally, int index) {
    final isSelected = selectedIndex == index;
    final abilityNames = ['Sword', 'Fireball', 'Heal'];
    final abilityName = ally.abilityIndex < abilityNames.length
        ? abilityNames[ally.abilityIndex]
        : 'Unknown';

    // Class colors based on ability
    final classColors = [
      const Color(0xFFC79C6E), // Warrior (brown/tan)
      const Color(0xFF3FC7EB), // Mage (light blue)
      const Color(0xFFFF7C0A), // Druid/Healer (orange)
    ];
    final classColor = ally.abilityIndex < classColors.length
        ? classColors[ally.abilityIndex]
        : Colors.grey;

    return GestureDetector(
      onTap: () => onAllySelected?.call(index),
      onDoubleTap: () => onAllyAbilityActivate?.call(ally),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4cc9f0).withValues(alpha: 0.15)
              : const Color(0xFF252542).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4cc9f0)
                : const Color(0xFF404060),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Class color bar
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: classColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and ability
                  Row(
                    children: [
                      Text(
                        'Ally ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($abilityName)',
                        style: TextStyle(
                          color: classColor,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Health bar
                  _buildHealthBar(ally.health, ally.maxHealth),
                  const SizedBox(height: 3),
                  // Ability cooldown bar
                  _buildCooldownBar(ally.abilityCooldown, ally.abilityCooldownMax),
                ],
              ),
            ),
            // Command indicator
            _buildCommandIndicator(ally.currentCommand),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBar(double health, double maxHealth) {
    final fraction = (health / maxHealth).clamp(0.0, 1.0);
    Color barColor;
    if (fraction > 0.5) {
      barColor = const Color(0xFF4CAF50);
    } else if (fraction > 0.25) {
      barColor = const Color(0xFFFFA726);
    } else {
      barColor = const Color(0xFFEF5350);
    }

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d14),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Center(
            child: Text(
              '${health.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCooldownBar(double cooldown, double maxCooldown) {
    final fraction = maxCooldown > 0 ? (1 - cooldown / maxCooldown).clamp(0.0, 1.0) : 1.0;
    final isReady = cooldown <= 0;

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d14),
        borderRadius: BorderRadius.circular(1),
      ),
      child: FractionallySizedBox(
        widthFactor: fraction,
        child: Container(
          decoration: BoxDecoration(
            color: isReady ? const Color(0xFF4cc9f0) : const Color(0xFF606080),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildCommandIndicator(AllyCommand command) {
    IconData icon;
    Color color;

    switch (command) {
      case AllyCommand.attack:
        icon = Icons.flash_on;
        color = const Color(0xFFFF4444);
        break;
      case AllyCommand.follow:
        icon = Icons.directions_walk;
        color = const Color(0xFF4CAF50);
        break;
      case AllyCommand.hold:
        icon = Icons.pan_tool;
        color = const Color(0xFFFFA726);
        break;
      case AllyCommand.none:
      default:
        return const SizedBox(width: 16);
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: color, size: 12),
    );
  }
}
