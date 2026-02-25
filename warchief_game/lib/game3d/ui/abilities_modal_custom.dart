part of 'abilities_modal.dart';

// ==================== CUSTOM ABILITIES EXTENSION ====================

extension _AbilitiesModalCustom on _AbilitiesModalState {
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
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () {
                setState(() {
                  // Custom abilities open in create mode (full save, not overrides)
                  _isCreatingNew = true;
                  _editingAbility = ability;
                  _editingStance = null;
                });
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCategoryColor(ability.category).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isEditing ? Colors.cyan : _getCategoryColor(ability.category).withOpacity(0.5),
                    width: isEditing ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: _getCategoryColor(ability.category), size: 12),
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
                        if (ability.requiresMana)
                          _buildManaStat(ability.manaColor, ability.manaCost),
                        if (ability.requiresDualMana)
                          _buildManaStat(ability.secondaryManaColor, ability.secondaryManaCost),
                      ],
                    ),
                    SizedBox(height: 4),
                    _buildBalanceIndicator(ability),
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

  /// Build sections for custom categories added via the editor's "+ Add New",
  /// plus any custom abilities whose category isn't in the built-in list.
  List<Widget> _buildCustomCategorySections() {
    final builtInCategories = AbilitiesConfig.categories.toSet();

    // Collect all non-built-in categories that have custom abilities
    final customAbilities = globalCustomAbilityManager?.getAll() ?? [];
    final extraCategories = <String>{};
    for (final ability in customAbilities) {
      if (!builtInCategories.contains(ability.category)) {
        extraCategories.add(ability.category);
      }
    }

    // Also include custom categories from the options manager
    final customOptionCategories = globalCustomOptionsManager?.getCustomValues('category') ?? [];
    extraCategories.addAll(customOptionCategories);

    if (extraCategories.isEmpty) return [];

    // Find built-in abilities assigned to these categories (via overrides)
    final allBuiltIn = [
      ...AbilitiesConfig.playerAbilities,
      ...AbilitiesConfig.potentialAbilities,
    ];

    final sections = <Widget>[];
    for (final category in extraCategories) {
      if (!_enabledCategories.contains(category)) continue;
      // Built-in abilities overridden into this category
      final matchingBuiltIn = allBuiltIn.where((ability) {
        final effective = globalAbilityOverrideManager?.getEffectiveAbility(ability) ?? ability;
        return effective.category == category;
      }).toList();

      // Custom abilities in this category
      final matchingCustom = globalCustomAbilityManager?.getByCategory(category) ?? [];

      final hasAny = matchingBuiltIn.isNotEmpty || matchingCustom.isNotEmpty;

      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryHeader(
              '${category.toUpperCase()} (Custom)',
              _getCategoryColor(category),
            ),
            if (!hasAny)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'No abilities assigned yet. Edit an ability and set its category to "$category".',
                  style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            ...matchingBuiltIn
              .where((a) => _enabledTypes.contains(a.type))
              .map((ability) =>
                _buildAbilityCard(ability, _getCategoryColor(category).withOpacity(0.3),
                  draggable: !(widget.gameState?.isActiveSummoned ?? false))),
            ...matchingCustom
              .where((a) => _enabledTypes.contains(a.type))
              .map((ability) =>
                _buildCustomAbilityCard(ability)),
            SizedBox(height: 16),
          ],
        ),
      );
    }
    return sections;
  }
}
