part of 'abilities_modal.dart';

// ==================== ABILITY FILTERS EXTENSION ====================

extension _AbilitiesModalFilters on _AbilitiesModalState {
  /// Build the non-scrolling category filter bar.
  Widget _buildCategoryFilter() {
    final allCategories = _getAllCategories();
    final enabledCount = _enabledCategories.length;
    final totalCount = allCategories.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: Colors.cyan.withOpacity(0.3), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsed bar: label + count + expand toggle + All/None
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.cyan, size: 16),
              const SizedBox(width: 6),
              Text(
                'Categories',
                style: TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: enabledCount == totalCount
                      ? Colors.cyan.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$enabledCount/$totalCount',
                  style: TextStyle(
                    color: enabledCount == totalCount ? Colors.cyan : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // All button
              GestureDetector(
                onTap: () => setState(() => _enabledCategories = _getAllCategories()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
                  ),
                  child: Text('All', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 4),
              // None button
              GestureDetector(
                onTap: () => setState(() => _enabledCategories = {}),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.red.withOpacity(0.4), width: 1),
                  ),
                  child: Text('None', style: TextStyle(color: Colors.red.shade300, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              // Expand/collapse toggle
              GestureDetector(
                onTap: () => setState(() => _filterExpanded = !_filterExpanded),
                child: Icon(
                  _filterExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.cyan,
                  size: 18,
                ),
              ),
            ],
          ),
          // Expanded: category chips
          if (_filterExpanded) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: allCategories.map((cat) => _buildFilterChip(cat)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// A single tappable category chip with checkbox state.
  Widget _buildFilterChip(String category) {
    final isEnabled = _enabledCategories.contains(category);
    final color = _getCategoryColor(category);
    final label = category[0].toUpperCase() + category.substring(1);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isEnabled) {
            _enabledCategories.remove(category);
          } else {
            _enabledCategories.add(category);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.6) : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnabled ? Icons.check_box : Icons.check_box_outline_blank,
              color: isEnabled ? color : Colors.white38,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? color : Colors.white38,
                fontSize: 10,
                fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the non-scrolling ability type filter bar.
  Widget _buildTypeFilter() {
    final enabledCount = _enabledTypes.length;
    final totalCount = AbilityType.values.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: Colors.orange.withOpacity(0.3), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsed bar: label + count + expand toggle + All/None
          Row(
            children: [
              Icon(Icons.category, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              Text(
                'Types',
                style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: enabledCount == totalCount
                      ? Colors.orange.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$enabledCount/$totalCount',
                  style: TextStyle(
                    color: enabledCount == totalCount ? Colors.orange : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // All button
              GestureDetector(
                onTap: () => setState(() => _enabledTypes = Set<AbilityType>.from(AbilityType.values)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
                  ),
                  child: Text('All', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 4),
              // None button
              GestureDetector(
                onTap: () => setState(() => _enabledTypes = {}),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.red.withOpacity(0.4), width: 1),
                  ),
                  child: Text('None', style: TextStyle(color: Colors.red.shade300, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              // Expand/collapse toggle
              GestureDetector(
                onTap: () => setState(() => _typeFilterExpanded = !_typeFilterExpanded),
                child: Icon(
                  _typeFilterExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.orange,
                  size: 18,
                ),
              ),
            ],
          ),
          // Expanded: type chips
          if (_typeFilterExpanded) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: AbilityType.values.map((type) => _buildTypeFilterChip(type)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// A single tappable type chip with checkbox state.
  Widget _buildTypeFilterChip(AbilityType type) {
    final isEnabled = _enabledTypes.contains(type);
    final color = _getTypeColor(type);
    final label = type.toString().split('.').last;
    final capitalLabel = label[0].toUpperCase() + label.substring(1);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isEnabled) {
            _enabledTypes.remove(type);
          } else {
            _enabledTypes.add(type);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.7) : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnabled ? Icons.check_box : Icons.check_box_outline_blank,
              color: isEnabled ? color : Colors.white38,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              capitalLabel,
              style: TextStyle(
                color: isEnabled ? color : Colors.white38,
                fontSize: 10,
                fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
