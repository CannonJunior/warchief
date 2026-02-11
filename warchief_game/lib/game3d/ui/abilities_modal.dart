import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import '../state/abilities_config.dart';
import '../state/ability_override_manager.dart';
import '../state/custom_options_manager.dart';
import '../state/custom_ability_manager.dart';
import '../state/action_bar_config.dart';
import '../data/abilities/abilities.dart' show AbilityRegistry;
import 'ability_editor_panel.dart';
import 'ui_config.dart';

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
  AbilityData? _editingAbility;
  bool _isCreatingNew = false;

  /// Currently selected class in the "Load Class" dropdown
  String _selectedLoadClass = 'warrior';

  @override
  Widget build(BuildContext context) {
    // Total width includes editor panel when open
    final totalWidth = _editingAbility != null ? 750.0 + 8.0 + 320.0 : 750.0;

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPos += details.delta.dx;
            _yPos += details.delta.dy;
            // Clamp position to screen bounds (account for editor panel width)
            _xPos = _xPos.clamp(0.0, MediaQuery.of(context).size.width - totalWidth);
            _yPos = _yPos.clamp(0.0, MediaQuery.of(context).size.height - 600);
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main codex panel
            Container(
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
                            // Hint about double-click to edit
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.cyan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.cyan, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, color: Colors.cyan, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Double-click to edit',
                                    style: TextStyle(
                                      color: Colors.cyan,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
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
                          // "+ Add New Ability" button at the top
                          _buildAddNewAbilityButton(),

                          SizedBox(height: 12),

                          // "Load Class" dropdown + button
                          _buildLoadClassRow(),

                          SizedBox(height: 16),

                          // Custom Abilities (user-created)
                          ..._buildCustomAbilitiesSection(),

                          SizedBox(height: 24),

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
                              // Custom categories added via "+ Add New" in editor
                              ..._buildCustomCategorySections(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Editor panel (side-by-side)
            if (_editingAbility != null) ...[
              SizedBox(width: 8),
              AbilityEditorPanel(
                ability: _editingAbility!,
                isNewAbility: _isCreatingNew,
                onClose: () {
                  setState(() {
                    _editingAbility = null;
                    _isCreatingNew = false;
                  });
                },
                onSaved: () {
                  setState(() {
                    // Refresh the codex to show updated values
                    if (_isCreatingNew) {
                      _editingAbility = null;
                      _isCreatingNew = false;
                    }
                  });
                },
              ),
            ],
          ],
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
                      ],
                    ),
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
              _getAbilityTypeIcon(ability.type),
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
                  _getAbilityTypeIcon(ability.type),
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
      case 'windwalker':
        return Colors.white;
      default:
        // Custom categories get a distinct teal color
        return Colors.tealAccent;
    }
  }

  /// Build the "+ Add New Ability" button
  Widget _buildAddNewAbilityButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCreatingNew = true;
          _editingAbility = _createBlankAbility();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text(
              '+ ADD NEW ABILITY',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the "Load Class" row: dropdown of classes + Load button
  Widget _buildLoadClassRow() {
    // Reason: AbilityRegistry.categories includes built-in classes (warrior, mage, etc.)
    // Filter to only classes that have abilities a player can equip (exclude player/monster/ally)
    final loadableCategories = AbilityRegistry.categories
        .where((c) => c != 'player' && c != 'monster' && c != 'ally')
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          Text(
            'Load Class:',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          // Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 1),
            ),
            child: DropdownButton<String>(
              value: _selectedLoadClass,
              dropdownColor: Colors.grey.shade900,
              underline: const SizedBox.shrink(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              iconEnabledColor: Colors.cyan,
              isDense: true,
              items: loadableCategories.map((category) {
                final count = AbilityRegistry.getByCategory(category).length;
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    '${category[0].toUpperCase()}${category.substring(1)} ($count)',
                    style: TextStyle(
                      color: _getCategoryColor(category),
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLoadClass = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Load button
          GestureDetector(
            onTap: () => _loadClassToActionBar(_selectedLoadClass),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getCategoryColor(_selectedLoadClass).withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getCategoryColor(_selectedLoadClass),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Load to Action Bar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Load the first 10 abilities from a class into the 10 action bar slots
  void _loadClassToActionBar(String category) {
    final config = globalActionBarConfig;
    if (config == null) return;

    final abilities = AbilityRegistry.getByCategory(category);
    if (abilities.isEmpty) return;

    for (int i = 0; i < 10; i++) {
      if (i < abilities.length) {
        config.setSlotAbility(i, abilities[i].name);
      }
    }

    print('[CODEX] Loaded ${category} class abilities to action bar '
        '(${abilities.length > 10 ? 10 : abilities.length} abilities)');

    // Refresh UI
    setState(() {});
  }

  /// Create a blank AbilityData template for the "create new" editor
  AbilityData _createBlankAbility() {
    return AbilityData(
      name: '',
      description: 'A new custom ability.',
      type: AbilityType.melee,
      cooldown: 1.0,
      color: Vector3(1.0, 1.0, 1.0),
      impactColor: Vector3(1.0, 1.0, 1.0),
      category: 'general',
    );
  }

  /// Build the CUSTOM ABILITIES section showing user-created abilities
  List<Widget> _buildCustomAbilitiesSection() {
    final customAbilities = globalCustomAbilityManager?.getAll() ?? [];
    if (customAbilities.isEmpty) return [];

    // Group by category
    final byCategory = <String, List<AbilityData>>{};
    for (final ability in customAbilities) {
      byCategory.putIfAbsent(ability.category, () => []).add(ability);
    }

    return [
      _buildSection(
        'CUSTOM ABILITIES',
        Colors.green,
        [
          ...byCategory.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryHeader(
                  entry.key.toUpperCase(),
                  _getCategoryColor(entry.key),
                ),
                ...entry.value.map((ability) =>
                  _buildCustomAbilityCard(ability)),
                SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    ];
  }

  /// Build a card for a custom ability (includes delete option)
  Widget _buildCustomAbilityCard(AbilityData ability) {
    final isEditing = _editingAbility?.name == ability.name;

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
          // Draggable icon
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: _buildDraggableAbilityIcon(ability, abilityColor),
          ),
          // Ability card - double-tap to edit
          Expanded(
            child: GestureDetector(
              onDoubleTap: () {
                setState(() {
                  // Custom abilities open in create mode (full save, not overrides)
                  _isCreatingNew = true;
                  _editingAbility = ability;
                });
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isEditing ? Colors.cyan : Colors.green.withOpacity(0.5),
                    width: isEditing ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.green, size: 12),
                        SizedBox(width: 4),
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
                        SizedBox(width: 8),
                        // Delete button
                        GestureDetector(
                          onTap: () => _confirmDeleteAbility(ability.name),
                          child: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      ability.description,
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    SizedBox(height: 8),
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirm before deleting a custom ability
  void _confirmDeleteAbility(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.red, width: 2),
        ),
        title: Text('Delete Ability', style: TextStyle(color: Colors.red, fontSize: 14)),
        content: Text(
          'Remove custom ability "$name"?\nThis cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              globalCustomAbilityManager?.removeAbility(name);
              Navigator.of(ctx).pop();
              setState(() {
                if (_editingAbility?.name == name) {
                  _editingAbility = null;
                  _isCreatingNew = false;
                }
              });
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Build sections for custom categories added via the editor's "+ Add New"
  List<Widget> _buildCustomCategorySections() {
    final customCategories = globalCustomOptionsManager?.getCustomValues('category') ?? [];
    if (customCategories.isEmpty) return [];

    // Find abilities assigned to custom categories (via overrides)
    final allAbilities = [
      ...AbilitiesConfig.playerAbilities,
      ...AbilitiesConfig.potentialAbilities,
    ];

    final sections = <Widget>[];
    for (final category in customCategories) {
      // Check if any abilities have been assigned to this custom category via overrides
      final matchingAbilities = allAbilities.where((ability) {
        final effective = globalAbilityOverrideManager?.getEffectiveAbility(ability) ?? ability;
        return effective.category == category;
      }).toList();

      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryHeader(
              '${category.toUpperCase()} (Custom)',
              _getCategoryColor(category),
            ),
            if (matchingAbilities.isEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'No abilities assigned yet. Edit an ability and set its category to "$category".',
                  style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            ...matchingAbilities.map((ability) =>
              _buildAbilityCard(ability, _getCategoryColor(category).withOpacity(0.3), draggable: true)),
            SizedBox(height: 16),
          ],
        ),
      );
    }
    return sections;
  }
}
