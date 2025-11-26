import 'package:flutter/material.dart';
import '../state/abilities_config.dart';

/// Abilities Panel - Draggable panel displaying all available abilities in the game
///
/// Opened with the 'P' key, this panel shows:
/// - Currently assigned abilities (Player, Monster, Allies)
/// - All potential future abilities organized by category
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
            _xPos = _xPos.clamp(0.0, MediaQuery.of(context).size.width - 700);
            _yPos = _yPos.clamp(0.0, MediaQuery.of(context).size.height - 600);
          });
        },
        child: Container(
          width: 700,
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
                                _buildAbilityCard(ability, Colors.blue.shade900)),

                              SizedBox(height: 16),
                              _buildCategoryHeader('Monster Abilities', Colors.purple),
                              ...AbilitiesConfig.monsterAbilities.map((ability) =>
                                _buildAbilityCard(ability, Colors.purple.shade900)),

                              SizedBox(height: 16),
                              _buildCategoryHeader('Ally Abilities', Colors.cyan),
                              ...AbilitiesConfig.allyAbilities.map((ability) =>
                                _buildAbilityCard(ability, Colors.cyan.shade900)),
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
                                      _buildAbilityCard(ability, _getCategoryColor(category).withOpacity(0.3))),
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

  Widget _buildAbilityCard(AbilityData ability, Color backgroundColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
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
    );
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
