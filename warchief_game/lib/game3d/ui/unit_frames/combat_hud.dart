import 'package:flutter/material.dart';
import '../ability_button.dart';
import 'unit_frame.dart';
import 'vs_indicator.dart';

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

  // Target data
  final String? targetName;
  final double targetHealth;
  final double targetMaxHealth;
  final int? targetLevel;
  final bool hasTarget;
  final Widget? targetPortraitWidget; // Custom portrait widget (e.g., 3D cube)

  // Ability cooldowns
  final double ability1Cooldown;
  final double ability1CooldownMax;
  final double ability2Cooldown;
  final double ability2CooldownMax;
  final double ability3Cooldown;
  final double ability3CooldownMax;
  final double ability4Cooldown;
  final double ability4CooldownMax;

  // Callbacks
  final VoidCallback onAbility1Pressed;
  final VoidCallback onAbility2Pressed;
  final VoidCallback onAbility3Pressed;
  final VoidCallback? onAbility4Pressed;

  const CombatHUD({
    Key? key,
    required this.playerName,
    required this.playerHealth,
    required this.playerMaxHealth,
    this.playerPower,
    this.playerMaxPower,
    this.playerLevel = 1,
    this.playerPortraitWidget,
    this.targetName,
    required this.targetHealth,
    required this.targetMaxHealth,
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
    required this.onAbility1Pressed,
    required this.onAbility2Pressed,
    required this.onAbility3Pressed,
    this.onAbility4Pressed,
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
        const SizedBox(width: 12),
        // VS indicator
        if (hasTarget) const VSIndicator(inCombat: true),
        if (hasTarget) const SizedBox(width: 12),
        // Target frame (portrait on right, mirrored)
        if (hasTarget)
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
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AbilityButton(
            label: '1',
            color: const Color(0xFFB3B3CC), // Gray (sword)
            cooldown: ability1Cooldown,
            maxCooldown: ability1CooldownMax,
            onPressed: onAbility1Pressed,
          ),
          const SizedBox(width: 6),
          AbilityButton(
            label: '2',
            color: const Color(0xFFFF6600), // Orange (fireball)
            cooldown: ability2Cooldown,
            maxCooldown: ability2CooldownMax,
            onPressed: onAbility2Pressed,
          ),
          const SizedBox(width: 6),
          AbilityButton(
            label: '3',
            color: const Color(0xFF80FF4D), // Green (heal)
            cooldown: ability3Cooldown,
            maxCooldown: ability3CooldownMax,
            onPressed: onAbility3Pressed,
          ),
          if (onAbility4Pressed != null) ...[
            const SizedBox(width: 6),
            AbilityButton(
              label: '4',
              color: const Color(0xFFE6B333), // Gold (dash attack)
              cooldown: ability4Cooldown,
              maxCooldown: ability4CooldownMax,
              onPressed: onAbility4Pressed!,
            ),
          ],
        ],
      ),
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
  final bool isPaused;
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
    this.isPaused = false,
    this.portraitWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF6B6B),
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
