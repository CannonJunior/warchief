import 'package:flutter/material.dart';

/// WoW-style horizontal unit frame with portrait, name, health bar, and power bar
class UnitFrame extends StatelessWidget {
  final String name;
  final double health;
  final double maxHealth;
  final double? power; // mana, energy, rage, etc.
  final double? maxPower;
  final Color healthColor;
  final Color powerColor;
  final Color borderColor;
  final bool isPlayer; // true = portrait on left, false = portrait on right (mirrored for target)
  final String? portraitIcon; // emoji or icon
  final int? level;
  final double width;

  const UnitFrame({
    Key? key,
    required this.name,
    required this.health,
    required this.maxHealth,
    this.power,
    this.maxPower,
    this.healthColor = const Color(0xFF4CAF50), // Green
    this.powerColor = const Color(0xFF2196F3), // Blue (mana)
    this.borderColor = const Color(0xFF1a1a2e),
    this.isPlayer = true,
    this.portraitIcon,
    this.level,
    this.width = 220,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final portrait = _buildPortrait();
    final bars = _buildBars();

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isPlayer
            ? [portrait, Expanded(child: bars)]
            : [Expanded(child: bars), portrait],
      ),
    );
  }

  Widget _buildPortrait() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        border: Border(
          right: isPlayer
              ? BorderSide(color: borderColor, width: 2)
              : BorderSide.none,
          left: !isPlayer
              ? BorderSide(color: borderColor, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Stack(
        children: [
          // Portrait icon/image
          Center(
            child: Text(
              portraitIcon ?? (isPlayer ? '\u{1F9D9}' : '\u{1F47E}'), // wizard vs alien
              style: const TextStyle(fontSize: 28),
            ),
          ),
          // Level badge
          if (level != null)
            Positioned(
              bottom: 0,
              left: isPlayer ? 0 : null,
              right: isPlayer ? null : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.only(
                    topRight: isPlayer ? const Radius.circular(4) : Radius.zero,
                    topLeft: !isPlayer ? const Radius.circular(4) : Radius.zero,
                  ),
                ),
                child: Text(
                  '$level',
                  style: const TextStyle(
                    color: Color(0xFFFFD700), // Gold
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBars() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment:
            isPlayer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name
          Text(
            name.toUpperCase(),
            style: TextStyle(
              color: isPlayer ? const Color(0xFF4cc9f0) : const Color(0xFFFF6B6B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Health bar
          _buildBar(
            value: health,
            maxValue: maxHealth,
            color: _getHealthColor(),
            height: 16,
            showText: true,
          ),
          // Power bar (if applicable)
          if (power != null && maxPower != null) ...[
            const SizedBox(height: 3),
            _buildBar(
              value: power!,
              maxValue: maxPower!,
              color: powerColor,
              height: 10,
              showText: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBar({
    required double value,
    required double maxValue,
    required Color color,
    required double height,
    required bool showText,
  }) {
    final fraction = (value / maxValue).clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d14),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Fill
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.9),
                    color,
                    color.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Text
          if (showText)
            Center(
              child: Text(
                '${value.toStringAsFixed(0)} / ${maxValue.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: height > 14 ? 10 : 8,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 2),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getHealthColor() {
    final fraction = health / maxHealth;
    if (fraction > 0.5) return healthColor;
    if (fraction > 0.25) return const Color(0xFFFFA726); // Orange
    return const Color(0xFFEF5350); // Red
  }
}

/// Compact unit frame for party/ally display
class CompactUnitFrame extends StatelessWidget {
  final String name;
  final double health;
  final double maxHealth;
  final Color classColor;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;

  const CompactUnitFrame({
    Key? key,
    required this.name,
    required this.health,
    required this.maxHealth,
    this.classColor = const Color(0xFF4CAF50),
    this.isSelected = false,
    this.onTap,
    this.width = 150,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fraction = (health / maxHealth).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 32,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFF4cc9f0) : const Color(0xFF252542),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Class color indicator
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: classColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  bottomLeft: Radius.circular(3),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Health bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0d0d14),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: fraction,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getHealthColor(fraction),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Health percentage
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '${(fraction * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _getHealthColor(fraction),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(double fraction) {
    if (fraction > 0.5) return const Color(0xFF4CAF50);
    if (fraction > 0.25) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }
}
