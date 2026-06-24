import 'package:flutter/material.dart';
import '../../../models/ally.dart';
import 'buff_debuff_icons.dart';

/// Vertical stack of party/ally frames (left side of screen)
class PartyFrames extends StatelessWidget {
  final List<Ally> allies;
  final int? selectedIndex;
  final void Function(int index)? onAllySelected;
  final void Function(Ally ally)? onAllyAbilityActivate;
  /// Display mode: 'list' (full rows), 'compact' (narrow rows), 'grid' (square icons).
  final String displayMode;

  const PartyFrames({
    super.key,
    required this.allies,
    this.selectedIndex,
    this.onAllySelected,
    this.onAllyAbilityActivate,
    this.displayMode = 'list',
  });

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
          _buildHeader(),
          if (displayMode == 'grid')
            _buildGrid()
          else
            ...allies.asMap().entries.map((entry) {
              return displayMode == 'compact'
                  ? _buildCompactAllyFrame(entry.value, entry.key)
                  : _buildAllyFrame(entry.value, entry.key);
            }),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('\u{1F46A}', style: TextStyle(fontSize: 12)),
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
    );
  }

  Widget _buildAllyFrame(Ally ally, int index) {
    final isSelected = selectedIndex == index;
    final abilityNames = ['Sword', 'Fireball', 'Heal'];
    final abilityName = ally.abilityIndex < abilityNames.length
        ? abilityNames[ally.abilityIndex]
        : 'Unknown';

    // Class colors based on ability
    const classColors = [
      Color(0xFFC79C6E), // Warrior (brown/tan)
      Color(0xFF3FC7EB), // Mage (light blue)
      Color(0xFFFF7C0A), // Druid/Healer (orange)
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          Expanded(
                            child: Text(
                              '($abilityName)',
                              style: TextStyle(
                                color: classColor,
                                fontSize: 9,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
            // Buff/debuff icons below the ally info
            if (ally.activeEffects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: BuffDebuffIcons(
                  effects: ally.activeEffects,
                  iconSize: 12,
                  maxWidth: 144,
                ),
              ),
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
              health.toStringAsFixed(0),
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

  // ==================== COMPACT VIEW ====================

  Widget _buildCompactAllyFrame(Ally ally, int index) {
    final isSelected = selectedIndex == index;
    final classColor = _classColor(ally);
    final healthFrac = (ally.health / ally.maxHealth).clamp(0.0, 1.0);
    final isDead = ally.health <= 0;

    final Color barColor;
    if (healthFrac > 0.5) {
      barColor = const Color(0xFF4CAF50);
    } else if (healthFrac > 0.25) {
      barColor = const Color(0xFFFFA726);
    } else {
      barColor = const Color(0xFFEF5350);
    }

    return GestureDetector(
      onTap: () => onAllySelected?.call(index),
      onDoubleTap: () => onAllyAbilityActivate?.call(ally),
      child: Opacity(
        opacity: isDead ? 0.4 : 1.0,
        child: Container(
          width: 130,
          height: 16,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4cc9f0).withValues(alpha: 0.15)
                : const Color(0xFF252542).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isSelected ? const Color(0xFF4cc9f0) : const Color(0xFF404060),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: isDead ? Colors.grey : classColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    bottomLeft: Radius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: healthFrac,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(2),
                            bottomRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        ally.name.isNotEmpty ? ally.name : 'Ally ${index + 1}',
                        style: TextStyle(
                          color: isDead ? Colors.grey : Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== GRID VIEW ====================

  Widget _buildGrid() {
    return SizedBox(
      width: 160,
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          for (int i = 0; i < allies.length; i++)
            _buildGridIcon(allies[i], i),
        ],
      ),
    );
  }

  Widget _buildGridIcon(Ally ally, int index) {
    final isSelected = selectedIndex == index;
    final classColor = _classColor(ally);
    final healthFrac = (ally.health / ally.maxHealth).clamp(0.0, 1.0);
    final isDead = ally.health <= 0;
    final classIcon = _classIcon(ally);

    Color borderColor;
    double borderWidth;
    if (isSelected) {
      borderColor = const Color(0xFF4cc9f0);
      borderWidth = 2;
    } else {
      borderColor = const Color(0xFF404060);
      borderWidth = 1;
    }

    final label = ally.name.isNotEmpty ? ally.name : 'Ally ${index + 1}';

    return Tooltip(
      message: '$label\n'
          'HP: ${ally.health.toStringAsFixed(0)} / ${ally.maxHealth.toStringAsFixed(0)}',
      waitDuration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () => onAllySelected?.call(index),
        onDoubleTap: () => onAllyAbilityActivate?.call(ally),
        child: Opacity(
          opacity: isDead ? 0.35 : 1.0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4cc9f0).withValues(alpha: 0.15)
                  : const Color(0xFF252542),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 28 * healthFrac,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (healthFrac > 0.5
                              ? const Color(0xFF4CAF50)
                              : healthFrac > 0.25
                                  ? const Color(0xFFFFA726)
                                  : const Color(0xFFEF5350))
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    isDead ? Icons.close : classIcon,
                    color: isDead
                        ? Colors.grey
                        : classColor.withValues(alpha: 0.9),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SHARED HELPERS ====================

  Color _classColor(Ally ally) {
    const classColors = [
      Color(0xFFC79C6E), // Warrior (brown/tan)
      Color(0xFF3FC7EB), // Mage (light blue)
      Color(0xFFFF7C0A), // Druid/Healer (orange)
    ];
    return ally.abilityIndex < classColors.length
        ? classColors[ally.abilityIndex]
        : Colors.grey;
  }

  IconData _classIcon(Ally ally) {
    const classIcons = [
      Icons.shield,           // Warrior
      Icons.auto_fix_high,    // Mage
      Icons.favorite,         // Healer
    ];
    return ally.abilityIndex < classIcons.length
        ? classIcons[ally.abilityIndex]
        : Icons.person;
  }
}
