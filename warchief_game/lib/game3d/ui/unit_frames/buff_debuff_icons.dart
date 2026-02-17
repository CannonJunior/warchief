import 'package:flutter/material.dart';
import '../../../models/active_effect.dart';
import '../../data/abilities/ability_types.dart';
import '../../data/abilities/abilities.dart' show AbilityRegistry;

/// Reusable widget that displays buff/debuff icons for an entity.
///
/// Shows two rows:
/// - Top row: buffs (haste, shield, regen, strength)
/// - Bottom row: debuffs (everything else)
///
/// Each icon is a small square with the ability's color as background,
/// the ability type icon from the Abilities Codex, and a progress ring
/// showing remaining duration. Hovering shows the ability name.
class BuffDebuffIcons extends StatelessWidget {
  final List<ActiveEffect> effects;
  final double iconSize;
  final double? maxWidth;

  const BuffDebuffIcons({
    Key? key,
    required this.effects,
    this.iconSize = 14,
    this.maxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();

    final buffs = effects.where((e) => e.isBuff).toList();
    final debuffs = effects.where((e) => e.isDebuff).toList();

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (buffs.isNotEmpty) _buildRow(buffs),
        if (buffs.isNotEmpty && debuffs.isNotEmpty)
          const SizedBox(height: 2),
        if (debuffs.isNotEmpty) _buildRow(debuffs),
      ],
    );

    if (maxWidth != null) {
      content = SizedBox(width: maxWidth, child: content);
    }

    return content;
  }

  Widget _buildRow(List<ActiveEffect> rowEffects) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: rowEffects
          .map((e) => _buildIcon(e))
          .toList(),
    );
  }

  Widget _buildIcon(ActiveEffect effect) {
    // Look up the source ability for icon and color
    final ability = effect.sourceName.isNotEmpty
        ? AbilityRegistry.findByName(effect.sourceName)
        : null;

    final Color color;
    final IconData icon;
    if (ability != null) {
      color = ability.flutterColor;
      icon = ability.typeIcon;
    } else {
      // Fallback for effects without a matching ability
      color = ActiveEffect.colorFor(effect.type);
      icon = ActiveEffect.iconFor(effect.type);
    }

    final tooltipName = effect.sourceName.isNotEmpty
        ? effect.sourceName
        : effect.type.name;

    return Tooltip(
      message: tooltipName,
      waitDuration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: iconSize,
        height: iconSize,
        child: Stack(
          children: [
            // Background square
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: color.withValues(alpha: 0.8),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize * 0.65,
                ),
              ),
            ),
            // Progress ring overlay (shows remaining duration)
            CustomPaint(
              size: Size(iconSize, iconSize),
              painter: _ProgressRingPainter(
                progress: effect.progress,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a circular progress ring showing remaining duration.
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return; // Full = no ring needed

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 0.5;

    // Draw expired portion as dark overlay
    final expiredSweep = (1.0 - progress) * 2 * 3.14159;
    final startAngle = -3.14159 / 2; // Start from top

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Reason: sweep from top clockwise for the expired portion
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      expiredSweep,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      (progress - oldDelegate.progress).abs() > 0.05;
}
