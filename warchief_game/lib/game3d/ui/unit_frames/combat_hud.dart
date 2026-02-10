import 'package:flutter/material.dart';
import '../ability_button.dart';
import '../mana_bar.dart';
import 'unit_frame.dart';
import 'vs_indicator.dart';
import '../../state/action_bar_config.dart';
import '../../state/game_state.dart';
import '../../data/abilities/ability_types.dart';

/// Main combat HUD with player frame, target frame, VS indicator, and action bars
/// Positioned at bottom-center of screen
class CombatHUD extends StatelessWidget {
  // Player data
  final String playerName;
  final double playerHealth;
  final double playerMaxHealth;
  final double? playerPower;
  final double? playerMaxPower;
  final int playerLevel;
  final Widget? playerPortraitWidget; // Custom portrait widget (e.g., 3D cube)

  // Mana data (for Ley Line-based mana system)
  final GameState? gameState; // For mana bar display

  // Target data
  final String? targetName;
  final double targetHealth;
  final double targetMaxHealth;
  final double targetMana;
  final double targetMaxMana;
  final int? targetLevel;
  final bool hasTarget;
  final Widget? targetPortraitWidget; // Custom portrait widget (e.g., 3D cube)

  // Ability cooldowns (slots 1-10)
  final double ability1Cooldown;
  final double ability1CooldownMax;
  final double ability2Cooldown;
  final double ability2CooldownMax;
  final double ability3Cooldown;
  final double ability3CooldownMax;
  final double ability4Cooldown;
  final double ability4CooldownMax;
  final double ability5Cooldown;
  final double ability5CooldownMax;
  final double ability6Cooldown;
  final double ability6CooldownMax;
  final double ability7Cooldown;
  final double ability7CooldownMax;
  final double ability8Cooldown;
  final double ability8CooldownMax;
  final double ability9Cooldown;
  final double ability9CooldownMax;
  final double ability10Cooldown;
  final double ability10CooldownMax;

  // Callbacks
  final VoidCallback onAbility1Pressed;
  final VoidCallback onAbility2Pressed;
  final VoidCallback onAbility3Pressed;
  final VoidCallback? onAbility4Pressed;
  final VoidCallback? onAbility5Pressed;
  final VoidCallback? onAbility6Pressed;
  final VoidCallback? onAbility7Pressed;
  final VoidCallback? onAbility8Pressed;
  final VoidCallback? onAbility9Pressed;
  final VoidCallback? onAbility10Pressed;

  // Action bar configuration (for drag-and-drop)
  final ActionBarConfig? actionBarConfig;
  final Function(int slotIndex, String abilityName)? onAbilityDropped;

  const CombatHUD({
    Key? key,
    required this.playerName,
    required this.playerHealth,
    required this.playerMaxHealth,
    this.playerPower,
    this.playerMaxPower,
    this.playerLevel = 1,
    this.playerPortraitWidget,
    this.gameState,
    this.targetName,
    required this.targetHealth,
    required this.targetMaxHealth,
    this.targetMana = 0.0,
    this.targetMaxMana = 0.0,
    this.targetLevel,
    this.hasTarget = true,
    this.targetPortraitWidget,
    required this.ability1Cooldown,
    required this.ability1CooldownMax,
    required this.ability2Cooldown,
    required this.ability2CooldownMax,
    required this.ability3Cooldown,
    required this.ability3CooldownMax,
    required this.ability4Cooldown,
    required this.ability4CooldownMax,
    this.ability5Cooldown = 0.0,
    this.ability5CooldownMax = 5.0,
    this.ability6Cooldown = 0.0,
    this.ability6CooldownMax = 5.0,
    this.ability7Cooldown = 0.0,
    this.ability7CooldownMax = 5.0,
    this.ability8Cooldown = 0.0,
    this.ability8CooldownMax = 5.0,
    this.ability9Cooldown = 0.0,
    this.ability9CooldownMax = 5.0,
    this.ability10Cooldown = 0.0,
    this.ability10CooldownMax = 5.0,
    required this.onAbility1Pressed,
    required this.onAbility2Pressed,
    required this.onAbility3Pressed,
    this.onAbility4Pressed,
    this.onAbility5Pressed,
    this.onAbility6Pressed,
    this.onAbility7Pressed,
    this.onAbility8Pressed,
    this.onAbility9Pressed,
    this.onAbility10Pressed,
    this.actionBarConfig,
    this.onAbilityDropped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Unit frames row (Player - VS - Target)
        _buildUnitFramesRow(),
        const SizedBox(height: 8),
        // Action bar
        _buildActionBar(),
      ],
    );
  }

  Widget _buildUnitFramesRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, // Align at top
      children: [
        // Player frame with mana bar below
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player frame (portrait on left)
            UnitFrame(
              name: playerName,
              health: playerHealth,
              maxHealth: playerMaxHealth,
              power: playerPower,
              maxPower: playerMaxPower,
              isPlayer: true,
              level: playerLevel,
              portraitWidget: playerPortraitWidget,
              borderColor: const Color(0xFF4cc9f0),
              healthColor: const Color(0xFF4CAF50),
              powerColor: const Color(0xFF2196F3),
              width: 200,
            ),
            // Mana bar below player frame (same width)
            if (gameState != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ManaBar(
                  gameState: gameState!,
                  width: 200,
                  height: 14,
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // VS indicator
        if (hasTarget) const VSIndicator(inCombat: true),
        if (hasTarget) const SizedBox(width: 12),
        // Target frame with mana bar below (mirrored layout)
        if (hasTarget)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UnitFrame(
                name: targetName ?? 'Unknown',
                health: targetHealth,
                maxHealth: targetMaxHealth,
                isPlayer: false,
                level: targetLevel,
                portraitWidget: targetPortraitWidget,
                borderColor: const Color(0xFFFF6B6B),
                healthColor: const Color(0xFFEF5350),
                width: 200,
              ),
              // Target mana bar below target frame (same width as player's)
              if (targetMaxMana > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildTargetManaBar(),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildTargetManaBar() {
    final manaPercent = targetMaxMana > 0
        ? (targetMana / targetMaxMana).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF1A1A3A),
          width: 1,
        ),
      ),
      child: Container(
        height: 14,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: [
              // Background
              Container(color: const Color(0xFF0A0A1A)),
              // Mana fill
              FractionallySizedBox(
                widthFactor: manaPercent,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2060CC),
                        Color(0xFF4080FF),
                        Color(0xFF60A0FF),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Text overlay
              Center(
                child: Text(
                  '${targetMana.toInt()} / ${targetMaxMana.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if an ability in a slot is out of range of current target
  bool _isSlotOutOfRange(int slotIndex, double? distanceToTarget) {
    if (actionBarConfig == null || distanceToTarget == null) return false;
    final abilityData = actionBarConfig!.getSlotAbilityData(slotIndex);
    if (abilityData.isSelfCast) return false;
    if (abilityData.range <= 0) return false;
    return distanceToTarget > abilityData.range;
  }

  Widget _buildActionBar() {
    // Get colors from action bar config if available
    final slotColors = List.generate(10, (i) =>
      actionBarConfig?.getSlotColor(i) ?? const Color(0xFFB3B3CC));

    // Compute distance to current target once for range checking
    final distanceToTarget = gameState?.getDistanceToCurrentTarget();

    // Define slot data for all 10 slots
    final slots = [
      (label: '1', cooldown: ability1Cooldown, maxCooldown: ability1CooldownMax, onPressed: onAbility1Pressed),
      (label: '2', cooldown: ability2Cooldown, maxCooldown: ability2CooldownMax, onPressed: onAbility2Pressed),
      (label: '3', cooldown: ability3Cooldown, maxCooldown: ability3CooldownMax, onPressed: onAbility3Pressed),
      (label: '4', cooldown: ability4Cooldown, maxCooldown: ability4CooldownMax, onPressed: onAbility4Pressed),
      (label: '5', cooldown: ability5Cooldown, maxCooldown: ability5CooldownMax, onPressed: onAbility5Pressed),
      (label: '6', cooldown: ability6Cooldown, maxCooldown: ability6CooldownMax, onPressed: onAbility6Pressed),
      (label: '7', cooldown: ability7Cooldown, maxCooldown: ability7CooldownMax, onPressed: onAbility7Pressed),
      (label: '8', cooldown: ability8Cooldown, maxCooldown: ability8CooldownMax, onPressed: onAbility8Pressed),
      (label: '9', cooldown: ability9Cooldown, maxCooldown: ability9CooldownMax, onPressed: onAbility9Pressed),
      (label: '0', cooldown: ability10Cooldown, maxCooldown: ability10CooldownMax, onPressed: onAbility10Pressed),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF252542),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Slots 1-5
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final slot = slots[i];
              return Padding(
                padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                child: _buildDraggableSlot(
                  slotIndex: i,
                  label: slot.label,
                  color: slotColors[i],
                  cooldown: slot.cooldown,
                  maxCooldown: slot.maxCooldown,
                  onPressed: slot.onPressed ?? () {},
                  isOutOfRange: _isSlotOutOfRange(i, distanceToTarget),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          // Row 2: Slots 6-10
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final slotIdx = i + 5;
              final slot = slots[slotIdx];
              return Padding(
                padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                child: _buildDraggableSlot(
                  slotIndex: slotIdx,
                  label: slot.label,
                  color: slotColors[slotIdx],
                  cooldown: slot.cooldown,
                  maxCooldown: slot.maxCooldown,
                  onPressed: slot.onPressed ?? () {},
                  isOutOfRange: _isSlotOutOfRange(slotIdx, distanceToTarget),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Build an action bar slot that accepts ability drops
  Widget _buildDraggableSlot({
    required int slotIndex,
    required String label,
    required Color color,
    required double cooldown,
    required double maxCooldown,
    required VoidCallback onPressed,
    bool isOutOfRange = false,
  }) {
    // Get the ability name for this slot's tooltip
    final abilityName = actionBarConfig?.getSlotAbility(slotIndex);

    // If no drag support, just show normal button
    if (onAbilityDropped == null) {
      return AbilityButton(
        label: label,
        color: color,
        cooldown: cooldown,
        maxCooldown: maxCooldown,
        onPressed: onPressed,
        isOutOfRange: isOutOfRange,
        tooltipText: abilityName,
      );
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        onAbilityDropped!(slotIndex, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: Colors.yellow.withValues(alpha: 0.8),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              AbilityButton(
                label: label,
                color: isHovering ? Colors.yellow.shade700 : color,
                cooldown: cooldown,
                maxCooldown: maxCooldown,
                onPressed: onPressed,
                isOutOfRange: isOutOfRange,
                tooltipText: abilityName,
              ),
              // Drop indicator overlay
              if (isHovering)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.yellow,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Target frame for monster/boss (standalone, for top of screen if needed)
class TargetFrame extends StatelessWidget {
  final String name;
  final double health;
  final double maxHealth;
  final int? level;
  final String? subtitle;
  final List<AbilityButtonData>? abilities;
  final VoidCallback? onPauseToggle;
  final VoidCallback? onTap; // Click to target
  final bool isPaused;
  final bool isTargeted; // Whether this is the current target
  final Widget? portraitWidget; // Custom portrait widget (e.g., 3D cube)

  const TargetFrame({
    Key? key,
    required this.name,
    required this.health,
    required this.maxHealth,
    this.level,
    this.subtitle,
    this.abilities,
    this.onPauseToggle,
    this.onTap,
    this.isPaused = false,
    this.isTargeted = false,
    this.portraitWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isTargeted
              ? const Color(0xFF2a2a1e) // Yellowish tint when targeted
              : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isTargeted
                ? const Color(0xFFFFD700) // Gold border when targeted
                : const Color(0xFFFF6B6B),
            width: isTargeted ? 3 : 2,
          ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              // Boss icon / portrait
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF252542),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFFF6B6B),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: portraitWidget ?? const Text('\u{1F47E}', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
              if (level != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Lv.$level',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Health bar
          _buildHealthBar(),
          // Abilities
          if (abilities != null && abilities!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: abilities!.map((ability) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AbilityButton(
                    label: ability.label,
                    color: ability.color,
                    cooldown: ability.cooldown,
                    maxCooldown: ability.maxCooldown,
                    onPressed: ability.onPressed,
                    size: 36,
                  ),
                );
              }).toList(),
            ),
          ],
          // Pause button
          if (onPauseToggle != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onPauseToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaused
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                      : const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isPaused
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF6B6B),
                    width: 1,
                  ),
                ),
                child: Text(
                  isPaused ? 'Resume AI' : 'Pause AI',
                  style: TextStyle(
                    color: isPaused
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF6B6B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildHealthBar() {
    final fraction = (health / maxHealth).clamp(0.0, 1.0);
    Color barColor;
    if (fraction > 0.5) {
      barColor = const Color(0xFFEF5350);
    } else if (fraction > 0.25) {
      barColor = const Color(0xFFFFA726);
    } else {
      barColor = const Color(0xFF4CAF50); // Low health = good for player
    }

    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d14),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black54, width: 1),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    barColor.withValues(alpha: 0.9),
                    barColor,
                    barColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Center(
            child: Text(
              '${health.toStringAsFixed(0)} / ${maxHealth.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for ability button configuration
class AbilityButtonData {
  final String label;
  final Color color;
  final double cooldown;
  final double maxCooldown;
  final VoidCallback onPressed;

  const AbilityButtonData({
    required this.label,
    required this.color,
    required this.cooldown,
    required this.maxCooldown,
    required this.onPressed,
  });
}

/// Isometric cube portrait widget - renders a 3D-looking cube for character portraits
class CubePortrait extends StatelessWidget {
  final Color color;
  final double size;
  final bool hasDirectionIndicator;
  final Color? indicatorColor;

  const CubePortrait({
    Key? key,
    required this.color,
    this.size = 36,
    this.hasDirectionIndicator = true,
    this.indicatorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate face colors (lighter top, darker sides)
    final topColor = Color.lerp(color, Colors.white, 0.3)!;
    final rightColor = Color.lerp(color, Colors.black, 0.2)!;
    final leftColor = Color.lerp(color, Colors.black, 0.35)!;

    // Isometric projection factors
    final cubeWidth = size * 0.7;
    final cubeHeight = size * 0.4;
    final sideHeight = size * 0.5;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IsometricCubePainter(
          topColor: topColor,
          leftColor: leftColor,
          rightColor: rightColor,
          cubeWidth: cubeWidth,
          cubeHeight: cubeHeight,
          sideHeight: sideHeight,
          hasIndicator: hasDirectionIndicator,
          indicatorColor: indicatorColor ?? Colors.red,
        ),
      ),
    );
  }
}

class _IsometricCubePainter extends CustomPainter {
  final Color topColor;
  final Color leftColor;
  final Color rightColor;
  final double cubeWidth;
  final double cubeHeight;
  final double sideHeight;
  final bool hasIndicator;
  final Color indicatorColor;

  _IsometricCubePainter({
    required this.topColor,
    required this.leftColor,
    required this.rightColor,
    required this.cubeWidth,
    required this.cubeHeight,
    required this.sideHeight,
    required this.hasIndicator,
    required this.indicatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Define the 6 vertices of the visible isometric cube
    final top = Offset(centerX, centerY - sideHeight * 0.6);
    final topLeft = Offset(centerX - cubeWidth / 2, centerY - cubeHeight / 2);
    final topRight = Offset(centerX + cubeWidth / 2, centerY - cubeHeight / 2);
    final center = Offset(centerX, centerY + cubeHeight * 0.1);
    final bottomLeft = Offset(centerX - cubeWidth / 2, centerY + sideHeight * 0.4);
    final bottomRight = Offset(centerX + cubeWidth / 2, centerY + sideHeight * 0.4);
    final bottom = Offset(centerX, centerY + sideHeight * 0.7);

    // Draw left face
    final leftPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = leftColor);

    // Draw right face
    final rightPath = Path()
      ..moveTo(topRight.dx, topRight.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = rightColor);

    // Draw top face
    final topPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(topLeft.dx, topLeft.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor);

    // Draw direction indicator (small triangle on top)
    if (hasIndicator) {
      final indicatorSize = cubeWidth * 0.3;
      final indicatorY = top.dy - 2;
      final indicatorPath = Path()
        ..moveTo(centerX, indicatorY - indicatorSize * 0.5)
        ..lineTo(centerX - indicatorSize * 0.4, indicatorY + indicatorSize * 0.3)
        ..lineTo(centerX + indicatorSize * 0.4, indicatorY + indicatorSize * 0.3)
        ..close();
      canvas.drawPath(indicatorPath, Paint()..color = indicatorColor);
    }

    // Draw subtle edge lines
    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(topPath, edgePaint);
    canvas.drawPath(leftPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
