import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import '../state/game_state.dart';
import '../data/stances/stances.dart';

/// Compact stance selector widget displayed on the left side of the screen.
///
/// Always shows the current stance icon with colored glow. When expanded
/// (X key), shows all 5 stances in a vertical list for selection.
class StanceSelector extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onStateChanged;

  const StanceSelector({
    Key? key,
    required this.gameState,
    required this.onStateChanged,
  }) : super(key: key);

  Color _v3ToColor(Vector3 v, [double opacity = 1.0]) {
    return Color.fromRGBO(
      (v.x * 255).clamp(0, 255).toInt(),
      (v.y * 255).clamp(0, 255).toInt(),
      (v.z * 255).clamp(0, 255).toInt(),
      opacity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stance = gameState.activeStance;
    final isExpanded = gameState.stanceSelectorOpen;
    final registry = globalStanceRegistry;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current stance indicator (always visible)
        _buildCurrentStanceIcon(stance),

        // Expanded stance list
        if (isExpanded && registry != null) ...[
          const SizedBox(height: 4),
          _buildStanceList(registry),
        ],
      ],
    );
  }

  Widget _buildCurrentStanceIcon(StanceData stance) {
    final color = _v3ToColor(stance.color);
    final isNone = stance.id == StanceId.none;
    final cooldownActive = gameState.stanceSwitchCooldown > 0;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNone ? Colors.grey.shade600 : color,
          width: 2,
        ),
        boxShadow: isNone
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              stance.icon,
              color: isNone ? Colors.grey : color,
              size: 22,
            ),
          ),
          // Cooldown overlay
          if (cooldownActive)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    gameState.stanceSwitchCooldown.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStanceList(StanceRegistry registry) {
    final currentId = gameState.isWarchiefActive
        ? gameState.playerStance
        : (gameState.activeAlly?.currentStance ?? StanceId.none);

    final allStances = [StanceData.none, ...registry.selectableStances];

    return Container(
      width: 200,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4cc9f0), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4, left: 2),
            child: Text(
              'STANCES (X)',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...allStances.map((s) => _buildStanceCard(s, currentId == s.id)),
        ],
      ),
    );
  }

  Widget _buildStanceCard(StanceData stance, bool isActive) {
    final color = _v3ToColor(stance.color);
    final cooldownActive = gameState.stanceSwitchCooldown > 0;

    return GestureDetector(
      onTap: () {
        if (!isActive && !cooldownActive) {
          gameState.switchStance(stance.id);
          onStateChanged();
        }
      },
      child: Tooltip(
        message: _buildTooltipText(stance),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? color : Colors.grey.shade800,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                stance.icon,
                color: isActive ? color : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stance.name,
                      style: TextStyle(
                        color: isActive ? color : Colors.white70,
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (stance.id != StanceId.none)
                      Text(
                        stance.modifierSummary.take(2).join(', '),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTooltipText(StanceData stance) {
    if (stance.id == StanceId.none) return 'No stance — baseline stats';
    final lines = [stance.description, '', ...stance.modifierSummary];
    return lines.join('\n');
  }
}

/// Stance cards for the Abilities Modal (P key).
///
/// Shows all stances as horizontal cards with full descriptions.
class StanceCardsSection extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onStateChanged;

  const StanceCardsSection({
    Key? key,
    required this.gameState,
    required this.onStateChanged,
  }) : super(key: key);

  Color _v3ToColor(Vector3 v, [double opacity = 1.0]) {
    return Color.fromRGBO(
      (v.x * 255).clamp(0, 255).toInt(),
      (v.y * 255).clamp(0, 255).toInt(),
      (v.z * 255).clamp(0, 255).toInt(),
      opacity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final registry = globalStanceRegistry;
    if (registry == null) return const SizedBox.shrink();

    final currentId = gameState.isWarchiefActive
        ? gameState.playerStance
        : (gameState.activeAlly?.currentStance ?? StanceId.none);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'EXOTIC STANCES',
            style: TextStyle(
              color: Color(0xFF4cc9f0),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: registry.selectableStances
              .map((s) => _buildStanceDetailCard(s, currentId == s.id))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStanceDetailCard(StanceData stance, bool isActive) {
    final color = _v3ToColor(stance.color);

    return GestureDetector(
      onTap: () {
        if (!isActive && gameState.stanceSwitchCooldown <= 0) {
          gameState.switchStance(stance.id);
          onStateChanged();
        }
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade700,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(stance.icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stance.name,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              stance.description,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Modifier list
            ...stance.modifierSummary.map((line) {
              final isPositive = line.startsWith('+');
              final isNegative = line.startsWith('-');
              return Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  line,
                  style: TextStyle(
                    color: isPositive
                        ? const Color(0xFF66FF66)
                        : isNegative
                            ? const Color(0xFFFF6666)
                            : Colors.grey.shade300,
                    fontSize: 9,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
