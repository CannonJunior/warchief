import 'package:flutter/material.dart';
import '../state/abilities_config.dart';
import '../state/action_bar_config.dart';

/// Abilities Panel - Draggable panel displaying all available abilities in the game
///
/// Opened with the 'P' key, this panel shows:
/// - Currently assigned abilities (Player, Monster, Allies)
/// - All potential future abilities organized by category
/// - Draggable icons that can be dropped onto the action bar
class AbilitiesModal extends StatefulWidget {
  final VoidCallback onClose;

  const AbilitiesModal({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AbilitiesModal> createState() => _AbilitiesModalState();
}

class _AbilitiesModalState extends State<AbilitiesModal> {
  double _xPos = 50.0;
  double _yPos = 50.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPos += details.delta.dx;
            _yPos += details.delta.dy;
            // Clamp position to screen bounds
            _xPos = _xPos.clamp(0.0, MediaQuery.of(context).size.width - 750);
            _yPos = _yPos.clamp(0.0, MediaQuery.of(context).size.height - 600);
          });
        },
        child: Container(
          width: 750, // Wider to accommodate drag icons
          height: 600,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyan, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header (draggable area)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.drag_indicator, color: Colors.cyan, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ABILITIES CODEX',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Hint about drag-and-drop
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app, color: Colors.orange, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Drag icons to action bar',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Press P to close',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Currently Assigned Abilities
                      _buildSection(
                        'CURRENTLY ASSIGNED ABILITIES',
                        Colors.green,
                        [
                          _buildCategoryHeader('Player Abilities', Colors.blue),
                          ...AbilitiesConfig.playerAbilities.map((ability) =>
                            _buildAbilityCard(ability, Colors.blue.shade900, draggable: true)),

                          SizedBox(height: 16),
                          _buildCategoryHeader('Monster Abilities', Colors.purple),
                          ...AbilitiesConfig.monsterAbilities.map((ability) =>
                            _buildAbilityCard(ability, Colors.purple.shade900, draggable: false)),

                          SizedBox(height: 16),
                          _buildCategoryHeader('Ally Abilities', Colors.cyan),
                          ...AbilitiesConfig.allyAbilities.map((ability) =>
                            _buildAbilityCard(ability, Colors.cyan.shade900, draggable: false)),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Potential Future Abilities
                      _buildSection(
                        'POTENTIAL FUTURE ABILITIES',
                        Colors.orange,
                        [
                          ...AbilitiesConfig.categories.map((category) {
                            final abilities = AbilitiesConfig.getAbilitiesByCategory(category);
                            if (abilities.isEmpty) return SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCategoryHeader(
                                  category.toUpperCase(),
                                  _getCategoryColor(category),
                                ),
                                ...abilities.map((ability) =>
                                  _buildAbilityCard(ability, _getCategoryColor(category).withOpacity(0.3), draggable: true)),
                                SizedBox(height: 16),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
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

  Widget _buildSection(String title, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

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
    // Convert Vector3 color to Flutter Color
    final abilityColor = Color.fromRGBO(
      (ability.color.x * 255).round(),
      (ability.color.y * 255).round(),
      (ability.color.z * 255).round(),
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
          // Ability info card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Ability name
                      Expanded(
                        flex: 2,
                        child: Text(
                          ability.name,
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
                          color: _getTypeColor(ability.type),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ability.type.toString().split('.').last.toUpperCase(),
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
                    ability.description,
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
                      if (ability.damage > 0)
                        _buildStat('DMG', ability.damage.toStringAsFixed(0), Colors.red.shade300),
                      if (ability.healAmount > 0)
                        _buildStat('HEAL', ability.healAmount.toStringAsFixed(0), Colors.green.shade300),
                      _buildStat('CD', '${ability.cooldown.toStringAsFixed(1)}s', Colors.blue.shade300),
                      if (ability.range > 0)
                        _buildStat('RANGE', ability.range.toStringAsFixed(0), Colors.orange.shade300),
                      if (ability.duration > 0)
                        _buildStat('DUR', '${ability.duration.toStringAsFixed(1)}s', Colors.purple.shade300),
                      if (ability.aoeRadius > 0)
                        _buildStat('AOE', ability.aoeRadius.toStringAsFixed(0), Colors.yellow.shade300),
                      if (ability.statusEffect != StatusEffect.none)
                        _buildStat('FX', ability.statusEffect.toString().split('.').last.toUpperCase(), Colors.pink.shade300),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a draggable ability icon that matches action bar button size (60x60)
  Widget _buildDraggableAbilityIcon(AbilityData ability, Color abilityColor) {
    const double iconSize = 60.0;

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
              _getAbilityTypeIcon(ability.type),
              color: Colors.white.withOpacity(0.9),
              size: 28,
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
                  _getAbilityTypeIcon(ability.type),
                  color: Colors.white,
                  size: 28,
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

  /// Get an icon for the ability type
  IconData _getAbilityTypeIcon(AbilityType type) {
    switch (type) {
      case AbilityType.melee:
        return Icons.sports_martial_arts;
      case AbilityType.ranged:
        return Icons.gps_fixed;
      case AbilityType.heal:
        return Icons.favorite;
      case AbilityType.buff:
        return Icons.arrow_upward;
      case AbilityType.debuff:
        return Icons.arrow_downward;
      case AbilityType.aoe:
        return Icons.blur_circular;
      case AbilityType.dot:
        return Icons.local_fire_department;
      case AbilityType.channeled:
        return Icons.stream;
      case AbilityType.summon:
        return Icons.pets;
      case AbilityType.utility:
        return Icons.build;
    }
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
      default:
        return Colors.white;
    }
  }
}
