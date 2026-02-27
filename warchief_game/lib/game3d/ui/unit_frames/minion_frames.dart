import 'package:flutter/material.dart';
import '../../../models/monster.dart';
import '../../../models/monster_ontology.dart';
import '../../../models/active_effect.dart';
import '../../data/abilities/ability_types.dart';
import '../../data/abilities/abilities.dart' show AbilityRegistry;

part 'minion_frame_widgets.dart';

/// Vertical stack of minion frames (right side of boss frame)
/// Symmetric to PartyFrames for allies
class MinionFrames extends StatelessWidget {
  final List<Monster> minions;
  final int? selectedIndex;
  final String? targetedMinionId; // Currently targeted minion (yellow border)
  final void Function(int index)? onMinionSelected;

  const MinionFrames({
    Key? key,
    required this.minions,
    this.selectedIndex,
    this.targetedMinionId,
    this.onMinionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (minions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group minions by archetype for organized display
    final groupedMinions = _groupByArchetype(minions);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2e1a1a).withValues(alpha: 0.8), // Darker red tint
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF422525),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end, // Align to right for symmetry
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                    '${minions.where((m) => m.isAlive).length}/${minions.length}',
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Minion frames grouped by archetype
          ...groupedMinions.entries.map((entry) {
            return _buildArchetypeGroup(entry.key, entry.value);
          }),
        ],
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

  Widget _buildArchetypeGroup(MonsterArchetype archetype, List<_IndexedMonster> monsters) {
    final archetypeColor = _getArchetypeColor(archetype);
    final archetypeIcon = _getArchetypeIcon(archetype);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Archetype header (compact)
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
        ...monsters.map((indexed) => _buildMinionFrame(indexed.monster, indexed.index)),
      ],
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
