import 'package:flutter/material.dart';
import '../../../models/monster.dart';
import '../../../models/monster_ontology.dart';

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

  Widget _buildBuffIndicators(Monster monster) {
    final buffs = <Widget>[];

    // Damage buff indicator
    if (monster.damageMultiplier > 1.0) {
      buffs.add(_buildBuffIcon(Icons.arrow_upward, const Color(0xFF4CAF50), 'DMG+'));
    } else if (monster.damageMultiplier < 1.0) {
      buffs.add(_buildBuffIcon(Icons.arrow_downward, const Color(0xFFEF5350), 'DMG-'));
    }

    // Damage reduction (shield) indicator
    if (monster.damageReduction > 0) {
      buffs.add(_buildBuffIcon(Icons.shield, const Color(0xFF2196F3), 'DEF'));
    }

    if (buffs.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buffs,
    );
  }

  Widget _buildBuffIcon(IconData icon, Color color, String tooltip) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Icon(icon, color: color, size: 8),
    );
  }

  Widget _buildManaBar(double mana, double maxMana) {
    final fraction = (mana / maxMana).clamp(0.0, 1.0);

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d0d),
        borderRadius: BorderRadius.circular(1),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3), // Blue for mana
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCastBar(Monster monster) {
    // Get ability being cast
    final abilityIndex = monster.activeAbilityIndex;
    if (abilityIndex < 0 || abilityIndex >= monster.definition.abilities.length) {
      return const SizedBox.shrink();
    }

    final ability = monster.definition.abilities[abilityIndex];
    final castProgress = ability.castTime > 0
        ? (monster.abilityActiveTime / ability.castTime).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d0d),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF9933FF), width: 0.5),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: castProgress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9933FF), Color(0xFFCC66FF)],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Center(
            child: Text(
              ability.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 5,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombatIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4444).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: Color(0xFFFF4444), size: 8),
          SizedBox(width: 1),
          Text(
            'COMBAT',
            style: TextStyle(
              color: Color(0xFFFF4444),
              fontSize: 6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(double health, double maxHealth, Color archetypeColor) {
    final fraction = (health / maxHealth).clamp(0.0, 1.0);
    Color barColor;
    if (fraction > 0.5) {
      barColor = archetypeColor;
    } else if (fraction > 0.25) {
      barColor = const Color(0xFFFFA726); // Orange for medium
    } else {
      barColor = const Color(0xFFEF5350); // Red for low
    }

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d0d),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF333333), width: 0.5),
      ),
      child: Stack(
        children: [
          // Health fill
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
          // HP text
          Center(
            child: Text(
              '${health.toStringAsFixed(0)} / ${maxHealth.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 6,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityCooldowns(Monster monster) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        monster.definition.abilities.length.clamp(0, 4), // Show max 4 abilities
        (i) {
          final isReady = monster.isAbilityReady(i);
          return Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isReady
                  ? const Color(0xFF4cc9f0)
                  : const Color(0xFF303030),
              border: Border.all(
                color: isReady
                    ? const Color(0xFF4cc9f0)
                    : const Color(0xFF505050),
                width: 0.5,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAIStateIndicator(MonsterAIState state) {
    IconData icon;
    Color color;

    switch (state) {
      case MonsterAIState.attacking:
        icon = Icons.flash_on;
        color = const Color(0xFFFF4444);
        break;
      case MonsterAIState.pursuing:
        icon = Icons.directions_run;
        color = const Color(0xFFFF8800);
        break;
      case MonsterAIState.supporting:
        icon = Icons.favorite;
        color = const Color(0xFF66CC66);
        break;
      case MonsterAIState.casting:
        icon = Icons.auto_fix_high;
        color = const Color(0xFF9933FF);
        break;
      case MonsterAIState.fleeing:
        icon = Icons.directions_walk;
        color = const Color(0xFFFFCC00);
        break;
      case MonsterAIState.dead:
        icon = Icons.close;
        color = Colors.grey;
        break;
      case MonsterAIState.idle:
      case MonsterAIState.patrol:
      default:
        return const SizedBox(width: 14);
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Icon(icon, color: color, size: 10),
    );
  }

  Color _getArchetypeColor(MonsterArchetype archetype) {
    switch (archetype) {
      case MonsterArchetype.dps:
        return const Color(0xFFFF6B6B);  // Red
      case MonsterArchetype.support:
        return const Color(0xFF9933FF);  // Purple
      case MonsterArchetype.healer:
        return const Color(0xFF66CC66);  // Green
      case MonsterArchetype.tank:
        return const Color(0xFFFFAA33);  // Orange
      case MonsterArchetype.boss:
        return const Color(0xFFFF0000);  // Bright red
    }
  }

  IconData _getArchetypeIcon(MonsterArchetype archetype) {
    switch (archetype) {
      case MonsterArchetype.dps:
        return Icons.flash_on;
      case MonsterArchetype.support:
        return Icons.auto_fix_high;
      case MonsterArchetype.healer:
        return Icons.favorite;
      case MonsterArchetype.tank:
        return Icons.shield;
      case MonsterArchetype.boss:
        return Icons.whatshot;
    }
  }
}

/// Helper class to track minion with its original index
class _IndexedMonster {
  final int index;
  final Monster monster;

  _IndexedMonster(this.index, this.monster);
}
