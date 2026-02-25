part of 'game3d_widget.dart';

mixin _WidgetUIHelpersMixin on _GameStateBase {
  // ==================== TARGET DATA BUILDERS ====================

  /// Get target data for current target (for CombatHUD)
  Map<String, dynamic> _getTargetData() {
    final target = gameState.getCurrentTarget();

    if (target == null) {
      // No target selected
      return {
        'hasTarget': false,
        'name': null,
        'health': 0.0,
        'maxHealth': 1.0,
        'mana': 0.0,
        'maxMana': 0.0,
        'level': null,
        'color': const Color(0xFF666666),
        'isFriendly': false,
      };
    }

    if (target['type'] == 'player') {
      return {
        'hasTarget': true,
        'name': 'Warchief',
        'health': gameState.playerHealth,
        'maxHealth': gameState.playerMaxHealth,
        'mana': gameState.blueMana,
        'maxMana': gameState.maxBlueMana,
        'level': 10,
        'color': const Color(0xFF4D80CC),
        'isFriendly': true,
      };
    }

    if (target['type'] == 'boss') {
      return {
        'hasTarget': true,
        'name': 'Boss Monster',
        'health': gameState.monsterHealth,
        'maxHealth': gameState.monsterMaxHealth.toDouble(),
        'mana': 100.0,
        'maxMana': 100.0,
        'level': 15,
        'color': const Color(0xFF9933CC), // Purple for boss
        'isFriendly': false,
      };
    } else if (target['type'] == 'dummy') {
      final dummy = gameState.targetDummy;
      return {
        'hasTarget': true,
        'name': 'Target Dummy',
        'health': dummy?.displayHealth ?? 100000,
        'maxHealth': dummy?.maxHealth ?? 100000,
        'mana': 0.0,
        'maxMana': 0.0,
        'level': 0,
        'color': const Color(0xFFC19A6B), // Burlywood/wooden color
        'isFriendly': false,
      };
    } else if (target['type'] == 'ally') {
      final ally = target['entity'] as Ally?;
      if (ally == null) {
        return {
          'hasTarget': false,
          'name': null,
          'health': 0.0,
          'maxHealth': 1.0,
          'mana': 0.0,
          'maxMana': 0.0,
          'level': null,
          'color': const Color(0xFF666666),
          'isFriendly': false,
        };
      }
      final allyIndex = int.tryParse((target['id'] as String).substring(5)) ?? 0;
      return {
        'hasTarget': true,
        'name': 'Ally ${allyIndex + 1}',
        'health': ally.health,
        'maxHealth': ally.maxHealth,
        'mana': ally.blueMana,
        'maxMana': ally.maxBlueMana,
        'level': 10,
        'color': const Color(0xFF66CC66), // Green for allies
        'isFriendly': true,
      };
    } else {
      final minion = target['entity'] as Monster?;
      if (minion == null) {
        return {
          'hasTarget': false,
          'name': null,
          'health': 0.0,
          'maxHealth': 1.0,
          'mana': 0.0,
          'maxMana': 0.0,
          'level': null,
          'color': const Color(0xFF666666),
          'isFriendly': false,
        };
      }

      // Get color based on archetype
      Color archetypeColor;
      switch (minion.definition.archetype) {
        case MonsterArchetype.dps:
          archetypeColor = const Color(0xFFFF6B6B); // Red
          break;
        case MonsterArchetype.support:
          archetypeColor = const Color(0xFF9933FF); // Purple
          break;
        case MonsterArchetype.healer:
          archetypeColor = const Color(0xFF66CC66); // Green
          break;
        case MonsterArchetype.tank:
          archetypeColor = const Color(0xFFFFAA33); // Orange
          break;
        case MonsterArchetype.boss:
          archetypeColor = const Color(0xFFFF0000); // Bright red
          break;
      }

      return {
        'hasTarget': true,
        'name': minion.definition.name,
        'health': minion.health,
        'maxHealth': minion.maxHealth,
        'mana': minion.mana,
        'maxMana': minion.maxMana,
        'level': minion.definition.monsterPower,
        'color': archetypeColor,
        'isFriendly': false,
      };
    }
  }

  /// Get target-of-target data for the ToT unit frame.
  /// Returns null if no target-of-target exists.
  Map<String, dynamic>? _getTargetOfTargetData() {
    final tot = gameState.getTargetOfTarget();
    if (tot == null || tot == 'none') return null;

    if (tot == 'player') {
      return {
        'name': 'You',
        'health': gameState.playerHealth,
        'maxHealth': gameState.playerMaxHealth,
        'level': 10,
        'color': const Color(0xFF4D80CC),
        'isFriendly': true,
      };
    }

    if (tot.startsWith('ally_')) {
      final index = int.tryParse(tot.substring(5));
      if (index != null && index < gameState.allies.length) {
        final ally = gameState.allies[index];
        return {
          'name': 'Ally ${index + 1}',
          'health': ally.health,
          'maxHealth': ally.maxHealth,
          'level': 5 + index + 1,
          'color': const Color(0xFF66CC66),
          'isFriendly': true,
        };
      }
    }

    // Check minions
    final minion = gameState.minions.where((m) => m.instanceId == tot).firstOrNull;
    if (minion != null) {
      return {
        'name': minion.definition.name,
        'health': minion.health,
        'maxHealth': minion.maxHealth,
        'level': minion.definition.monsterPower,
        'color': Color(minion.healthBarColor),
        'isFriendly': false,
      };
    }

    return null;
  }

  // ==================== WIDGET BUILDERS ====================

  /// Build Combat HUD with current target data
  Widget _buildCombatHUD() {
    final targetData = _getTargetData();
    final totData = _getTargetOfTargetData();

    // Determine friendly/enemy colors for target frame
    final isFriendly = targetData['isFriendly'] as bool? ?? false;
    final targetBorderColor = isFriendly
        ? const Color(0xFF4CAF50) // Green border for friendlies
        : const Color(0xFFFF6B6B); // Red border for enemies
    final targetHealthColor = isFriendly
        ? const Color(0xFF66BB6A) // Green health for friendlies
        : const Color(0xFFEF5350); // Red health for enemies

    // Determine active character info for player frame
    final isWarchief = gameState.isWarchiefActive;
    final activeAlly = gameState.activeAlly;
    final activeName = isWarchief
        ? 'Warchief'
        : 'Ally ${gameState.activeCharacterIndex}';
    final activeHealth = isWarchief
        ? gameState.playerHealth
        : (activeAlly?.health ?? 0);
    final activeMaxHealth = isWarchief
        ? gameState.playerMaxHealth
        : (activeAlly?.maxHealth ?? 50);
    final activeLevel = isWarchief
        ? 10
        : (5 + gameState.activeCharacterIndex);
    final activePortraitColor = isWarchief
        ? const Color(0xFF4D80CC)
        : const Color(0xFF66CC66);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CombatHUD(
          playerName: activeName,
          playerHealth: activeHealth,
          playerMaxHealth: activeMaxHealth,
          playerLevel: activeLevel,
          playerPortraitWidget: CubePortrait(
            color: activePortraitColor,
            size: 36,
            hasDirectionIndicator: true,
            indicatorColor: isWarchief ? Colors.red : Colors.green,
          ),
          gameState: gameState, // For mana bar display
          targetName: targetData['name'] as String?,
          targetHealth: targetData['health'] as double,
          targetMaxHealth: targetData['maxHealth'] as double,
          targetMana: targetData['mana'] as double,
          targetMaxMana: targetData['maxMana'] as double,
          targetLevel: targetData['level'] as int?,
          hasTarget: targetData['hasTarget'] as bool,
          targetPortraitWidget: targetData['hasTarget'] as bool
              ? CubePortrait(
                  color: targetData['color'] as Color,
                  size: 36,
                  hasDirectionIndicator: true,
                  indicatorColor: Colors.green,
                )
              : null,
          abilityCooldowns: gameState.activeAbilityCooldowns,
          abilityCooldownMaxes: gameState.activeAbilityCooldownMaxes,
          onAbility1Pressed: _activateAbility1,
          onAbility2Pressed: _activateAbility2,
          onAbility3Pressed: _activateAbility3,
          onAbility4Pressed: _activateAbility4,
          onAbility5Pressed: _activateAbility5,
          onAbility6Pressed: _activateAbility6,
          onAbility7Pressed: _activateAbility7,
          onAbility8Pressed: _activateAbility8,
          onAbility9Pressed: _activateAbility9,
          onAbility10Pressed: _activateAbility10,
          actionBarConfig: globalActionBarConfigManager?.activeConfig,
          targetBorderColor: targetBorderColor,
          targetHealthColor: targetHealthColor,
          totName: totData?['name'] as String?,
          totHealth: (totData?['health'] as num?)?.toDouble() ?? 0.0,
          totMaxHealth: (totData?['maxHealth'] as num?)?.toDouble() ?? 1.0,
          totLevel: totData?['level'] as int?,
          totPortraitWidget: totData != null
              ? CubePortrait(
                  color: totData['color'] as Color,
                  size: 24,
                  hasDirectionIndicator: false,
                )
              : null,
          totBorderColor: totData != null
              ? ((totData['isFriendly'] as bool)
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF6B6B))
              : const Color(0xFF888888),
          totHealthColor: totData != null
              ? ((totData['isFriendly'] as bool)
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFEF5350))
              : const Color(0xFF4CAF50),
          onAbilityDropped: _handleAbilityDropped,
          onStateChanged: () => setState(() {}),
        ),
      ],
    );
  }

  /// Build ally control button (+/- ally)
  Widget _buildAllyControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('Button "$label" tapped!');
          onPressed();
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build command panel with close button
  Widget _buildCommandPanelWithClose({
    required Widget child,
    required VoidCallback onClose,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF252542),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Close button row
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 2),
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFFF6B6B),
                  size: 12,
                ),
              ),
            ),
          ),
          // Panel content
          child,
        ],
      ),
    );
  }
}
