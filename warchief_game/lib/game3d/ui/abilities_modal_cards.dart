part of 'abilities_modal.dart';

// ==================== ABILITY CARDS EXTENSION ====================

extension _AbilitiesModalCards on _AbilitiesModalState {
  Widget _buildCategoryHeader(String title, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAbilityCard(AbilityData ability, Color backgroundColor, {bool draggable = false}) {
    // Use effective ability (with overrides) for display values
    final effective = globalAbilityOverrideManager?.getEffectiveAbility(ability) ?? ability;
    final hasOverrides = globalAbilityOverrideManager?.hasOverrides(ability.name) ?? false;
    final isEditing = _editingAbility?.name == ability.name;

    // Convert Vector3 color to Flutter Color
    final abilityColor = Color.fromRGBO(
      (effective.color.x * 255).round(),
      (effective.color.y * 255).round(),
      (effective.color.z * 255).round(),
      1.0,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Draggable ability icon (same size as action bar buttons: 60x60)
          if (draggable)
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: _buildDraggableAbilityIcon(ability, abilityColor),
            ),
          // Ability info card - double-tap to open editor
          Expanded(
            child: GestureDetector(
              onDoubleTap: () {
                setState(() {
                  _isCreatingNew = false;
                  _editingAbility = ability;
                  _editingStance = null;
                });
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isEditing ? Colors.cyan : (hasOverrides ? Colors.yellow.withOpacity(0.6) : Colors.white24),
                    width: isEditing ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Override indicator
                        if (hasOverrides)
                          Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.edit, color: Colors.yellow, size: 12),
                          ),
                        // Ability name
                        Expanded(
                          flex: 2,
                          child: Text(
                            effective.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Type badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTypeColor(effective.type),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            effective.type.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 6),

                    // Description
                    Text(
                      effective.description,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),

                    SizedBox(height: 8),

                    // Stats row
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (effective.damage > 0)
                          _buildStat('DMG', effective.damage.toStringAsFixed(0), Colors.red.shade300),
                        if (effective.healAmount > 0)
                          _buildStat('HEAL', effective.healAmount.toStringAsFixed(0), Colors.green.shade300),
                        _buildStat('CD', '${effective.cooldown.toStringAsFixed(1)}s', Colors.blue.shade300),
                        if (effective.range > 0)
                          _buildStat('RANGE', effective.range.toStringAsFixed(0), Colors.orange.shade300),
                        if (effective.duration > 0)
                          _buildStat('DUR', '${effective.duration.toStringAsFixed(1)}s', Colors.purple.shade300),
                        if (effective.aoeRadius > 0)
                          _buildStat('AOE', effective.aoeRadius.toStringAsFixed(0), Colors.yellow.shade300),
                        if (effective.statusEffect != StatusEffect.none)
                          _buildStat('FX', effective.statusEffect.toString().split('.').last.toUpperCase(), Colors.pink.shade300),
                        if (effective.requiresMana)
                          _buildManaStat(effective.manaColor, effective.manaCost),
                        if (effective.requiresDualMana)
                          _buildManaStat(effective.secondaryManaColor, effective.secondaryManaCost),
                      ],
                    ),
                    SizedBox(height: 4),
                    _buildBalanceIndicator(effective),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a draggable ability icon that matches action bar button size
  Widget _buildDraggableAbilityIcon(AbilityData ability, Color abilityColor) {
    const double iconSize = UIConfig.actionBarButtonSize;

    final iconWidget = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: abilityColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white30, width: 2),
        boxShadow: [
          BoxShadow(
            color: abilityColor.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ability type icon
          Center(
            child: Icon(
              ability.type.icon,
              color: Colors.white.withOpacity(0.9),
              size: 22,
            ),
          ),
          // Ability name (abbreviated)
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Text(
              _abbreviateName(ability.name),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Drag hint
          Positioned(
            top: 2,
            right: 2,
            child: Icon(
              Icons.drag_indicator,
              color: Colors.white.withOpacity(0.5),
              size: 12,
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: ability.name,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.1,
          child: Opacity(
            opacity: 0.9,
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: abilityColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  ability.type.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: iconWidget,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: iconWidget,
      ),
    );
  }

  /// Abbreviate ability name for icon display
  String _abbreviateName(String name) {
    if (name.length <= 6) return name;
    // Take first word or first 6 chars
    final words = name.split(' ');
    if (words.first.length <= 6) return words.first;
    return name.substring(0, 6);
  }

  Widget _buildStat(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Mana cost chip: colored circle + cost number
  Widget _buildManaStat(ManaColor color, double cost) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.displayColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 3),
        Text(
          cost.toStringAsFixed(0),
          style: TextStyle(
            color: color.displayColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Balance score indicator: colored dot + numeric score + label
  Widget _buildBalanceIndicator(AbilityData ability) {
    final score = computeBalanceScore(ability);
    final color = balanceScoreColor(score);
    final label = balanceScoreLabel(score);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          '${score.toStringAsFixed(2)} $label',
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(AbilityType type) {
    switch (type) {
      case AbilityType.melee:
        return Colors.red.shade700;
      case AbilityType.ranged:
        return Colors.orange.shade700;
      case AbilityType.heal:
        return Colors.green.shade700;
      case AbilityType.buff:
        return Colors.blue.shade700;
      case AbilityType.debuff:
        return Colors.purple.shade700;
      case AbilityType.aoe:
        return Colors.yellow.shade800;
      case AbilityType.dot:
        return Colors.pink.shade700;
      case AbilityType.channeled:
        return Colors.indigo.shade700;
      case AbilityType.summon:
        return Colors.teal.shade700;
      case AbilityType.utility:
        return Colors.grey.shade700;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'warrior':
        return Colors.red;
      case 'mage':
        return Colors.blue;
      case 'rogue':
        return Colors.grey;
      case 'healer':
        return Colors.green;
      case 'nature':
        return Colors.lightGreen;
      case 'necromancer':
        return Colors.purple;
      case 'elemental':
        return Colors.orange;
      case 'utility':
        return Colors.yellow;
      case 'windwalker':
        return Colors.white;
      case 'spiritkin':
        return const Color(0xFF80E030); // Yellow-green (nature+blood)
      case 'stormheart':
        return const Color(0xFFB0B0FF); // Blue-white (storm)
      case 'greenseer':
        return const Color(0xFF30FF80); // Bright green (oracle/life)
      default:
        // Custom categories get a distinct teal color
        return Colors.tealAccent;
    }
  }
}
