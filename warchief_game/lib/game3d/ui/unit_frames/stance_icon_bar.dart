import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../state/game_state.dart';
import '../../data/stances/stances.dart';

/// Clickable stance icon bar displayed above the player health bar.
///
/// Shows all available stances (None + 5 exotic) as compact icons in a row.
/// The active stance is prominently highlighted with a glowing colored border
/// and slightly larger size. Clicking an icon switches to that stance.
class StanceIconBar extends StatelessWidget {
  final GameState gameState;
  final VoidCallback? onStateChanged;

  const StanceIconBar({
    Key? key,
    required this.gameState,
    this.onStateChanged,
  }) : super(key: key);

  Color _v3ToColor(Vector3 v) {
    return Color.fromRGBO(
      (v.x * 255).clamp(0, 255).toInt(),
      (v.y * 255).clamp(0, 255).toInt(),
      (v.z * 255).clamp(0, 255).toInt(),
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final registry = globalStanceRegistry;
    if (registry == null) return const SizedBox.shrink();

    final allStances = [StanceData.none, ...registry.selectableStances];
    final currentId = gameState.isWarchiefActive
        ? gameState.playerStance
        : (gameState.activeAlly?.currentStance ?? StanceId.none);
    final cooldownActive = gameState.stanceSwitchCooldown > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d1a).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF252542),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: allStances.map((stance) {
          final isActive = stance.id == currentId;
          return _buildStanceIcon(stance, isActive, cooldownActive);
        }).toList(),
      ),
    );
  }

  Widget _buildStanceIcon(StanceData stance, bool isActive, bool cooldownActive) {
    final color = _v3ToColor(stance.color);
    final isNone = stance.id == StanceId.none;
    final iconColor = isActive
        ? (isNone ? Colors.white : color)
        : Colors.grey.shade600;
    final size = isActive ? 30.0 : 24.0;

    return GestureDetector(
      onTap: () {
        if (!isActive && !cooldownActive) {
          gameState.switchStance(stance.id);
          onStateChanged?.call();
        }
      },
      child: Tooltip(
        message: _tooltipText(stance, isActive, cooldownActive),
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive
                ? (isNone
                    ? Colors.grey.shade800.withValues(alpha: 0.6)
                    : color.withValues(alpha: 0.2))
                : Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(isActive ? 6 : 4),
            border: Border.all(
              color: isActive
                  ? (isNone ? Colors.grey.shade400 : color)
                  : Colors.grey.shade800,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive && !isNone
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              stance.icon,
              color: iconColor,
              size: isActive ? 16 : 12,
            ),
          ),
        ),
      ),
    );
  }

  String _tooltipText(StanceData stance, bool isActive, bool cooldownActive) {
    final buffer = StringBuffer(stance.name);
    if (isActive) buffer.write(' (Active)');
    if (cooldownActive) {
      buffer.write(' — ${gameState.stanceSwitchCooldown.toStringAsFixed(1)}s cooldown');
    }
    if (stance.id != StanceId.none) {
      buffer.write('\n${stance.description}');
      final mods = stance.modifierSummary;
      if (mods.isNotEmpty) {
        buffer.write('\n${mods.join(', ')}');
      }
    }
    return buffer.toString();
  }
}
