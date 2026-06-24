import 'package:flutter/material.dart';
import '../../../models/monster.dart';
import '../../../models/monster_ontology.dart';
import '../../../models/active_effect.dart';
import '../../data/abilities/abilities.dart' show AbilityRegistry;

part 'minion_frame_widgets.dart';

/// Vertical stack of minion frames (right side of boss frame)
/// Symmetric to PartyFrames for allies
class MinionFrames extends StatelessWidget {
  final List<Monster> minions;
  final int? selectedIndex;
  final String? targetedMinionId;
  final void Function(int index)? onMinionSelected;
  /// Display mode: 'list' (full rows), 'compact' (narrow rows), 'grid' (square icons).
  final String displayMode;

  const MinionFrames({
    super.key,
    required this.minions,
    this.selectedIndex,
    this.targetedMinionId,
    this.onMinionSelected,
    this.displayMode = 'list',
  });

  @override
  Widget build(BuildContext context) {
    if (minions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2e1a1a).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF422525),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),
          // Body switches on display mode
          if (displayMode == 'grid')
            _buildGrid()
          else
            ..._buildList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final aliveCount = minions.where((m) => m.isAlive).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'MINIONS',
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$aliveCount/${minions.length}',
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildList() {
    final isCompact = displayMode == 'compact';
    final groupedMinions = _groupByArchetype(minions);
    return groupedMinions.entries.map((entry) {
      return _buildArchetypeGroup(entry.key, entry.value, compact: isCompact);
    }).toList();
  }

  // ==================== GRID VIEW ====================

  Widget _buildGrid() {
    return SizedBox(
      width: 150,
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        alignment: WrapAlignment.end,
        children: [
          for (int i = 0; i < minions.length; i++)
            _buildGridIcon(minions[i], i),
        ],
      ),
    );
  }

  Widget _buildGridIcon(Monster monster, int index) {
    final isTargeted = targetedMinionId == monster.instanceId;
    final isDead = !monster.isAlive;
    final archetypeColor = _getArchetypeColor(monster.definition.archetype);
    final archetypeIcon = _getArchetypeIcon(monster.definition.archetype);
    final healthFrac = (monster.health / monster.maxHealth).clamp(0.0, 1.0);

    Color borderColor;
    double borderWidth;
    if (isTargeted) {
      borderColor = const Color(0xFFFFD700);
      borderWidth = 2;
    } else {
      borderColor = const Color(0xFF403030);
      borderWidth = 1;
    }

    return Tooltip(
      message: '${monster.definition.name}\n'
          'HP: ${monster.health.toStringAsFixed(0)} / ${monster.maxHealth.toStringAsFixed(0)}\n'
          '${monster.definition.archetype.name.toUpperCase()}',
      waitDuration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () => onMinionSelected?.call(index),
        child: Opacity(
          opacity: isDead ? 0.35 : 1.0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isTargeted
                  ? const Color(0xFF3D3D00).withValues(alpha: 0.4)
                  : const Color(0xFF2a2020),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Stack(
              children: [
                // Health fill from bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 28 * healthFrac,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (healthFrac > 0.5
                              ? archetypeColor
                              : healthFrac > 0.25
                                  ? const Color(0xFFFFA726)
                                  : const Color(0xFFEF5350))
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Archetype icon centered
                Center(
                  child: Icon(
                    isDead ? Icons.close : archetypeIcon,
                    color: isDead
                        ? Colors.grey
                        : archetypeColor.withValues(alpha: 0.9),
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

  /// Group minions by their archetype for organized display
  Map<MonsterArchetype, List<_IndexedMonster>> _groupByArchetype(List<Monster> monsters) {
    final grouped = <MonsterArchetype, List<_IndexedMonster>>{};

    for (int i = 0; i < monsters.length; i++) {
      final monster = monsters[i];
      final archetype = monster.definition.archetype;
      grouped.putIfAbsent(archetype, () => []);
      grouped[archetype]!.add(_IndexedMonster(i, monster));
    }

    // Sort by archetype priority: Tank > Healer > Support > DPS
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => _archetypePriority(a.key).compareTo(_archetypePriority(b.key)));

    return Map.fromEntries(sortedEntries);
  }

  int _archetypePriority(MonsterArchetype archetype) {
    switch (archetype) {
      case MonsterArchetype.tank:
        return 0;
      case MonsterArchetype.healer:
        return 1;
      case MonsterArchetype.support:
        return 2;
      case MonsterArchetype.dps:
        return 3;
      case MonsterArchetype.boss:
        return -1;
    }
  }

  Widget _buildArchetypeGroup(MonsterArchetype archetype, List<_IndexedMonster> monsters, {bool compact = false}) {
    final archetypeColor = _getArchetypeColor(archetype);
    final archetypeIcon = _getArchetypeIcon(archetype);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Archetype header
        Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(archetypeIcon, color: archetypeColor, size: 10),
              const SizedBox(width: 4),
              Text(
                archetype.name.toUpperCase(),
                style: TextStyle(
                  color: archetypeColor.withValues(alpha: 0.8),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${monsters.where((m) => m.monster.isAlive).length})',
                style: TextStyle(
                  color: archetypeColor.withValues(alpha: 0.6),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        // Minion frames
        ...monsters.map((indexed) => compact
            ? _buildCompactMinionFrame(indexed.monster, indexed.index)
            : _buildMinionFrame(indexed.monster, indexed.index)),
      ],
    );
  }

  Widget _buildCompactMinionFrame(Monster monster, int index) {
    final isTargeted = targetedMinionId == monster.instanceId;
    final isDead = !monster.isAlive;
    final archetypeColor = _getArchetypeColor(monster.definition.archetype);
    final healthFrac = (monster.health / monster.maxHealth).clamp(0.0, 1.0);

    Color borderColor;
    double borderWidth;
    if (isTargeted) {
      borderColor = const Color(0xFFFFD700);
      borderWidth = 2;
    } else {
      borderColor = const Color(0xFF403030);
      borderWidth = 1;
    }

    final Color barColor;
    if (healthFrac > 0.5) {
      barColor = archetypeColor;
    } else if (healthFrac > 0.25) {
      barColor = const Color(0xFFFFA726);
    } else {
      barColor = const Color(0xFFEF5350);
    }

    return GestureDetector(
      onTap: () => onMinionSelected?.call(index),
      child: Opacity(
        opacity: isDead ? 0.4 : 1.0,
        child: Container(
          width: 120,
          height: 16,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: isTargeted
                ? const Color(0xFF3D3D00).withValues(alpha: 0.3)
                : const Color(0xFF2a2020).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            children: [
              // Archetype color bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: isDead ? Colors.grey : archetypeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    bottomLeft: Radius.circular(2),
                  ),
                ),
              ),
              // Health fill + name overlay
              Expanded(
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: healthFrac,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.35),
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
                        monster.definition.name,
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

  Widget _buildMinionFrame(Monster monster, int index) {
    final isSelected = selectedIndex == index;
    final isTargeted = targetedMinionId == monster.instanceId;
    final isDead = !monster.isAlive;
    final archetypeColor = _getArchetypeColor(monster.definition.archetype);
    final isCaster = monster.definition.archetype == MonsterArchetype.healer ||
                     monster.definition.archetype == MonsterArchetype.support;

    // Targeted minion gets yellow border, selected gets archetype color
    Color borderColor;
    int borderWidth;
    if (isTargeted) {
      borderColor = const Color(0xFFFFD700); // Gold/yellow for target
      borderWidth = 2;
    } else if (isSelected) {
      borderColor = archetypeColor;
      borderWidth = 2;
    } else {
      borderColor = const Color(0xFF403030);
      borderWidth = 1;
    }

    return GestureDetector(
      onTap: () => onMinionSelected?.call(index),
      child: Opacity(
        opacity: isDead ? 0.4 : 1.0,
        child: Container(
          width: 150, // Slightly wider for more info
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isTargeted
                ? const Color(0xFF3D3D00).withValues(alpha: 0.3)
                : isSelected
                    ? archetypeColor.withValues(alpha: 0.2)
                    : const Color(0xFF2a2020).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: borderColor,
              width: borderWidth.toDouble(),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Name + AI State + Buffs
              Row(
                children: [
                  // Archetype color bar
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isDead ? Colors.grey : archetypeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Name
                  Expanded(
                    child: Text(
                      monster.definition.name,
                      style: TextStyle(
                        color: isDead ? Colors.grey : Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Buff/Debuff indicators
                  _buildBuffIndicators(monster),
                  const SizedBox(width: 2),
                  // AI state indicator
                  _buildAIStateIndicator(monster.aiState),
                ],
              ),
              const SizedBox(height: 3),
              // Health bar with numbers
              _buildHealthBar(monster.health, monster.maxHealth, archetypeColor),
              // Mana bar for casters
              if (isCaster) ...[
                const SizedBox(height: 2),
                _buildManaBar(monster.mana, monster.maxMana),
              ],
              // Cast bar if casting
              if (monster.isAbilityActive && monster.activeAbilityIndex >= 0) ...[
                const SizedBox(height: 2),
                _buildCastBar(monster),
              ],
              const SizedBox(height: 2),
              // Bottom row: Ability cooldowns + Combat status
              Row(
                children: [
                  _buildAbilityCooldowns(monster),
                  const Spacer(),
                  if (monster.isInCombat)
                    _buildCombatIndicator(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Helper class to track minion with its original index
class _IndexedMonster {
  final int index;
  final Monster monster;

  _IndexedMonster(this.index, this.monster);
}
