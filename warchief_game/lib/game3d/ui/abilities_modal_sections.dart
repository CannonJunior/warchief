part of 'abilities_modal.dart';

// ==================== ABILITY SECTIONS EXTENSION ====================

extension _AbilitiesModalSections on _AbilitiesModalState {
  /// Collect all available categories (built-in + custom).
  Set<String> _getAllCategories() {
    final categories = <String>{...AbilityRegistry.categories};
    final customAbilities = globalCustomAbilityManager?.getAll() ?? [];
    for (final ability in customAbilities) {
      categories.add(ability.category);
    }
    final customOptions = globalCustomOptionsManager?.getCustomValues('category') ?? [];
    categories.addAll(customOptions);
    return categories;
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

  /// Build a reorderable category section with drag-to-reorder ability cards.
  ///
  /// Uses ReorderableListView.builder wrapped in a SizedBox so it can live
  /// inside the outer scroll view (shrinkWrap + NeverScrollable physics).
  Widget _buildReorderableCategorySection(String category) {
    final orderedAbilities = globalAbilityOrderManager?.getOrderedAbilities(category)
        ?? AbilitiesConfig.getAbilitiesByCategory(category);
    final filtered = orderedAbilities
        .where((a) => _enabledTypes.contains(a.type))
        .toList();
    if (filtered.isEmpty) return SizedBox.shrink();

    final hasCustomOrder = globalAbilityOrderManager?.hasCustomOrder(category) ?? false;
    final categoryColor = _getCategoryColor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCategoryHeader(
                category.toUpperCase(),
                categoryColor,
              ),
            ),
            if (hasCustomOrder)
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'Custom order — click to reset',
                  child: InkWell(
                    onTap: () {
                      globalAbilityOrderManager?.clearOrder(category);
                      setState(() {});
                    },
                    child: Icon(Icons.restart_alt, color: Colors.orange, size: 16),
                  ),
                ),
              ),
          ],
        ),
        // Reason: ReorderableListView needs a bounded height; we calculate it
        // from item count. Each card is ~100px tall (content + margin).
        SizedBox(
          height: filtered.length * 100.0,
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: filtered.length,
            onReorder: (oldIndex, newIndex) {
              // Reason: ReorderableListView passes newIndex as if the item
              // at oldIndex was already removed, so adjust when moving down.
              if (newIndex > oldIndex) newIndex--;
              final reordered = List<AbilityData>.from(filtered);
              final item = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, item);
              // Save the full category order (including filtered-out types)
              // by rebuilding from the unfiltered ordered list
              final fullOrdered = globalAbilityOrderManager
                  ?.getOrderedAbilities(category) ?? [];
              final fullReordered = <AbilityData>[];
              final reorderedNames = reordered.map((a) => a.name).toSet();
              int reorderedIdx = 0;
              for (final a in fullOrdered) {
                if (reorderedNames.contains(a.name)) {
                  fullReordered.add(reordered[reorderedIdx++]);
                } else {
                  fullReordered.add(a);
                }
              }
              globalAbilityOrderManager?.setOrder(
                  category, fullReordered.map((a) => a.name).toList());
              setState(() {});
            },
            itemBuilder: (context, index) {
              final ability = filtered[index];
              final isCustom = globalCustomAbilityManager?.hasAbility(ability.name) ?? false;
              // Slot badge: show 1-10 for the first 10 items
              final slotNumber = index < 10 ? index + 1 : null;
              return Row(
                key: ValueKey(ability.name),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: EdgeInsets.only(top: 12, right: 4),
                      child: Icon(Icons.drag_indicator,
                          color: Colors.white38, size: 20),
                    ),
                  ),
                  // Slot number badge
                  if (slotNumber != null)
                    Padding(
                      padding: EdgeInsets.only(top: 12, right: 4),
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          slotNumber == 10 ? '0' : '$slotNumber',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (slotNumber == null)
                    SizedBox(width: 24),
                  // Ability card
                  Expanded(
                    child: isCustom
                        ? _buildCustomAbilityCard(ability)
                        : _buildAbilityCard(
                            ability,
                            categoryColor.withOpacity(0.3),
                            draggable: !(widget.gameState?.isActiveSummoned ?? false),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  /// Build the "+ Add New Ability" button
  Widget _buildAddNewAbilityButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCreatingNew = true;
          _editingAbility = _createBlankAbility();
          _editingStance = null;
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

    // Add custom-only categories (those not already in built-in list)
    final customOnlyCategories = (globalCustomAbilityManager?.usedCategories ?? <String>{})
        .where((c) => !AbilityRegistry.categories.contains(c))
        .toList();
    loadableCategories.addAll(customOnlyCategories);

    // Ensure selected class is still valid
    if (!loadableCategories.contains(_selectedLoadClass) && loadableCategories.isNotEmpty) {
      _selectedLoadClass = loadableCategories.first;
    }

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
                final count = AbilityRegistry.getByCategory(category).length +
                    (globalCustomAbilityManager?.getByCategory(category).length ?? 0);
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

    // Use user-defined order if available, otherwise default registry + custom
    final abilities = globalAbilityOrderManager?.getOrderedAbilities(category)
        ?? <AbilityData>[
          ...AbilityRegistry.getByCategory(category),
          ...(globalCustomAbilityManager?.getByCategory(category) ?? []),
        ];
    if (abilities.isEmpty) return;

    for (int i = 0; i < 10; i++) {
      if (i < abilities.length) {
        config.setSlotAbility(i, abilities[i].name);
      }
    }

    print('[CODEX] Loaded ${category} class abilities to action bar '
        '(${abilities.length > 10 ? 10 : abilities.length} abilities)');

    // Notify parent to update character mesh color
    widget.onClassLoaded?.call(category);

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
}
