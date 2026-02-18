import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../data/abilities/ability_types.dart' show ManaColor;

/// Mana bar widget showing blue mana, red mana, and Ley Line/Power Node proximity
class ManaBar extends StatelessWidget {
  final GameState gameState;
  final double width;
  final double height;

  const ManaBar({
    Key? key,
    required this.gameState,
    this.width = 200,
    this.height = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final attunements = gameState.activeManaAttunements;

    final blueManaPercent = gameState.activeMaxBlueMana > 0
        ? gameState.activeBlueMana / gameState.activeMaxBlueMana : 0.0;
    final redManaPercent = gameState.activeMaxRedMana > 0
        ? gameState.activeRedMana / gameState.activeMaxRedMana : 0.0;
    final whiteManaPercent = gameState.activeMaxWhiteMana > 0
        ? gameState.activeWhiteMana / gameState.activeMaxWhiteMana
        : 0.0;
    final leyLineInfo = gameState.currentLeyLineInfo;
    final isNearLeyLine = leyLineInfo?.isInRange ?? false;
    final isOnPowerNode = gameState.isOnPowerNode;
    final blueRegenRate = gameState.currentManaRegenRate;
    final redRegenRate = gameState.currentRedManaRegenRate;
    final whiteRegenRate = gameState.currentWhiteManaRegenRate;

    final hasBlue = attunements.contains(ManaColor.blue);
    final hasRed = attunements.contains(ManaColor.red);
    final hasWhite = attunements.contains(ManaColor.white);
    final hasGreen = attunements.contains(ManaColor.green);
    final greenManaPercent = gameState.activeMaxGreenMana > 0
        ? gameState.activeGreenMana / gameState.activeMaxGreenMana : 0.0;
    final greenRegenRate = gameState.currentGreenManaRegenRate;

    // Border color: purple for power node, blue for ley line, gray default
    final borderColor = isOnPowerNode
        ? const Color(0xFFAA40FF).withOpacity(0.9)
        : isNearLeyLine
            ? const Color(0xFF4080FF).withOpacity(0.8)
            : const Color(0xFF1A1A3A);

    final children = <Widget>[];

    if (hasBlue) {
      children.add(_buildManaBar(
        percent: blueManaPercent,
        current: gameState.activeBlueMana,
        max: gameState.activeMaxBlueMana,
        colors: const [Color(0xFF2060CC), Color(0xFF4080FF), Color(0xFF60A0FF)],
        isRegenerating: blueRegenRate > 0,
      ));
    }
    if (hasRed) {
      children.add(_buildManaBar(
        percent: redManaPercent,
        current: gameState.activeRedMana,
        max: gameState.activeMaxRedMana,
        colors: const [Color(0xFFCC2020), Color(0xFFFF4040), Color(0xFFFF6060)],
        isRegenerating: redRegenRate > 0,
      ));
    }
    if (hasWhite) {
      children.add(_buildManaBar(
        percent: whiteManaPercent,
        current: gameState.activeWhiteMana,
        max: gameState.activeMaxWhiteMana,
        colors: const [Color(0xFFA0A0B0), Color(0xFFE0E0E0), Color(0xFFF0F0FF)],
        isRegenerating: whiteRegenRate > 0,
      ));
    }
    if (hasGreen) {
      children.add(_buildManaBar(
        percent: greenManaPercent,
        current: gameState.activeGreenMana,
        max: gameState.activeMaxGreenMana,
        colors: const [Color(0xFF208020), Color(0xFF40CC40), Color(0xFF60FF60)],
        isRegenerating: greenRegenRate > 0,
      ));
    }

    // Info widgets gated by attunement
    if (hasGreen && greenRegenRate > 0) {
      children.add(_buildGreenManaInfo(greenRegenRate));
    }
    if (hasWhite && whiteRegenRate > 0) {
      children.add(_buildWindInfo(whiteRegenRate));
    } else if (isOnPowerNode && (hasBlue || hasRed)) {
      children.add(_buildPowerNodeInfo(blueRegenRate, redRegenRate));
    } else if (hasBlue && isNearLeyLine && leyLineInfo != null) {
      children.add(_buildLeyLineInfo(leyLineInfo, blueRegenRate));
    }

    // No attunement message
    if (attunements.isEmpty) {
      children.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          'No Mana Attunement',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 9,
            fontStyle: FontStyle.italic,
          ),
        ),
      ));
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: borderColor,
          width: (isNearLeyLine || isOnPowerNode) ? 2 : 1,
        ),
        boxShadow: isOnPowerNode
            ? [
                BoxShadow(
                  color: const Color(0xFFAA40FF).withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : isNearLeyLine
                ? [
                    BoxShadow(
                      color: const Color(0xFF4080FF).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildManaBar({
    required double percent,
    required double current,
    required double max,
    required List<Color> colors,
    required bool isRegenerating,
  }) {
    return Container(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            // Background
            Container(
              color: const Color(0xFF0A0A1A),
            ),
            // Mana fill
            FractionallySizedBox(
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Shimmer effect when regenerating
            if (isRegenerating)
              _buildRegenShimmer(percent),
            // Text overlay
            Center(
              child: Text(
                '${current.toInt()} / ${max.toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegenShimmer(double manaPercent) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      left: (width * manaPercent) - 5,
      top: 0,
      bottom: 0,
      child: Container(
        width: 10,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreenManaInfo(double regenRate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nature icon (green circle)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF40CC40),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF40CC40).withOpacity(0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '+${regenRate.toStringAsFixed(1)}/s',
            style: const TextStyle(
              color: Color(0xFF80FF80),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Nature',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindInfo(double regenRate) {
    final windStrength = gameState.windState.windStrengthPercent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wind icon (silver-white circle)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE0E0E0).withOpacity(0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '+${regenRate.toStringAsFixed(1)}/s',
            style: const TextStyle(
              color: Color(0xFFD0D0E0),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Wind (${windStrength.toStringAsFixed(0)}%)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeyLineInfo(dynamic leyLineInfo, double regenRate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ley Line icon (blue circle)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF4080FF),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4080FF).withOpacity(0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '+${regenRate.toStringAsFixed(1)}/s',
            style: const TextStyle(
              color: Color(0xFF80B0FF),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Ley Line (${leyLineInfo.distance.toStringAsFixed(1)}m)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerNodeInfo(double blueRegenRate, double redRegenRate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFAA40FF).withOpacity(0.1),
            const Color(0xFFAA40FF).withOpacity(0.2),
            const Color(0xFFAA40FF).withOpacity(0.1),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Power Node icon (purple diamond shape)
          Container(
            width: 10,
            height: 10,
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFAA40FF),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFAA40FF).withOpacity(0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Blue mana regen
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF4080FF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Text(
            '+${blueRegenRate.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Color(0xFF80B0FF),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          // Red mana regen
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4040),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Text(
            '+${redRegenRate.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Color(0xFFFF8080),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Power Node',
            style: TextStyle(
              color: const Color(0xFFCC80FF),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact mana bar for unit frames or other small displays
class CompactManaBar extends StatelessWidget {
  final double current;
  final double max;
  final double width;
  final double height;
  final bool showText;
  final bool isRedMana; // If true, shows red color instead of blue

  const CompactManaBar({
    Key? key,
    required this.current,
    required this.max,
    this.width = 100,
    this.height = 6,
    this.showText = false,
    this.isRedMana = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    final colors = isRedMana
        ? const [Color(0xFFCC2020), Color(0xFFFF4040)]
        : const [Color(0xFF2060CC), Color(0xFF4080FF)];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: const Color(0xFF1A1A3A),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                ),
              ),
            ),
            if (showText)
              Center(
                child: Text(
                  '${current.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dual compact mana bars showing both blue and red mana
class DualCompactManaBar extends StatelessWidget {
  final double blueCurrent;
  final double blueMax;
  final double redCurrent;
  final double redMax;
  final double width;
  final double height;

  const DualCompactManaBar({
    Key? key,
    required this.blueCurrent,
    required this.blueMax,
    required this.redCurrent,
    required this.redMax,
    this.width = 100,
    this.height = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompactManaBar(
          current: blueCurrent,
          max: blueMax,
          width: width,
          height: height,
          isRedMana: false,
        ),
        const SizedBox(height: 1),
        CompactManaBar(
          current: redCurrent,
          max: redMax,
          width: width,
          height: height,
          isRedMana: true,
        ),
      ],
    );
  }
}
