part of 'minion_frames.dart';

// ==================== MINION FRAME WIDGET BUILDERS ====================

extension _MinionFrameWidgets on MinionFrames {
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

    // Active status effects — use ability icon/color when available
    for (final effect in monster.activeEffects) {
      final ability = effect.sourceName.isNotEmpty
          ? AbilityRegistry.findByName(effect.sourceName)
          : null;
      final icon = ability?.typeIcon ?? ActiveEffect.iconFor(effect.type);
      final color = ability?.flutterColor ?? ActiveEffect.colorFor(effect.type);
      final name = effect.sourceName.isNotEmpty ? effect.sourceName : effect.type.name;
      buffs.add(_buildBuffIcon(icon, color, name));
    }

    if (buffs.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 0, runSpacing: 2, children: buffs);
  }

  Widget _buildBuffIcon(IconData icon, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 200),
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: color, width: 0.5),
        ),
        child: Icon(icon, color: color, size: 8),
      ),
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
    // Reason: color transitions give visual urgency at low HP independent of archetype tint
    final Color barColor;
    if (fraction > 0.5) {
      barColor = archetypeColor;
    } else if (fraction > 0.25) {
      barColor = const Color(0xFFFFA726); // Orange for medium health
    } else {
      barColor = const Color(0xFFEF5350); // Red for low health
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
              color: isReady ? const Color(0xFF4cc9f0) : const Color(0xFF303030),
              border: Border.all(
                color: isReady ? const Color(0xFF4cc9f0) : const Color(0xFF505050),
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
        return const Color(0xFFFF6B6B); // Red
      case MonsterArchetype.support:
        return const Color(0xFF9933FF); // Purple
      case MonsterArchetype.healer:
        return const Color(0xFF66CC66); // Green
      case MonsterArchetype.tank:
        return const Color(0xFFFFAA33); // Orange
      case MonsterArchetype.boss:
        return const Color(0xFFFF0000); // Bright red
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
