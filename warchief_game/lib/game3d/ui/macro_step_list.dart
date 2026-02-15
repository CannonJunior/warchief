import 'package:flutter/material.dart';
import '../../models/macro.dart';
import '../data/abilities/abilities.dart';

/// Extracted widget for macro step list + add-step form.
///
/// Renders numbered step cards with reorder/delete, and an inline
/// "Add Step" form at the bottom. Keeps the main panel under 500 lines.
class MacroStepList extends StatefulWidget {
  final List<MacroStep> steps;
  final void Function(List<MacroStep>) onStepsChanged;

  const MacroStepList({
    Key? key,
    required this.steps,
    required this.onStepsChanged,
  }) : super(key: key);

  @override
  State<MacroStepList> createState() => _MacroStepListState();
}

class _MacroStepListState extends State<MacroStepList> {
  MacroActionType _addActionType = MacroActionType.ability;
  String? _addAbilityName;
  double _addDelay = 0.0;
  double _addWaitDuration = 1.0;
  String? _addCondition;

  /// All available ability names for the dropdown.
  /// Includes PlayerAbilities (Sword, Fireball, etc.) + all potential abilities.
  List<String> get _abilityNames {
    final abilities = [
      ...PlayerAbilities.all,
      ...AbilityRegistry.potentialAbilities,
    ];
    return abilities.map((a) => a.name).toList()..sort();
  }

  static const List<String> _conditions = [
    '(none)',
    'has_mana',
    'target_exists',
    'health_above_50',
    'health_below_50',
    'health_below_30',
  ];

  void _moveStep(int from, int direction) {
    final to = from + direction;
    if (to < 0 || to >= widget.steps.length) return;
    final updated = List<MacroStep>.from(widget.steps);
    final step = updated.removeAt(from);
    updated.insert(to, step);
    widget.onStepsChanged(updated);
  }

  void _deleteStep(int index) {
    final updated = List<MacroStep>.from(widget.steps);
    updated.removeAt(index);
    widget.onStepsChanged(updated);
  }

  void _addStep() {
    MacroStep step;
    if (_addActionType == MacroActionType.wait) {
      step = MacroStep(
        actionType: MacroActionType.wait,
        actionName: '',
        delay: _addWaitDuration,
        condition: _addCondition == '(none)' ? null : _addCondition,
      );
    } else {
      if (_addAbilityName == null || _addAbilityName!.isEmpty) return;
      step = MacroStep(
        actionType: MacroActionType.ability,
        actionName: _addAbilityName!,
        delay: _addDelay,
        condition: _addCondition == '(none)' ? null : _addCondition,
      );
    }
    final updated = List<MacroStep>.from(widget.steps)..add(step);
    widget.onStepsChanged(updated);
  }

  /// Icon for action type.
  IconData _actionIcon(MacroActionType type) {
    switch (type) {
      case MacroActionType.ability:
        return Icons.flash_on;
      case MacroActionType.wait:
        return Icons.timer;
      default:
        return Icons.help_outline;
    }
  }

  /// Short label for a condition.
  String _conditionLabel(String? condition) {
    if (condition == null) return '';
    switch (condition) {
      case 'has_mana':
        return 'MANA';
      case 'target_exists':
        return 'TARGET';
      case 'health_above_50':
        return 'HP>50%';
      case 'health_below_50':
        return 'HP<50%';
      case 'health_below_30':
        return 'HP<30%';
      default:
        return condition.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step list
        ...List.generate(widget.steps.length, (i) => _buildStepCard(i)),

        if (widget.steps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'No steps yet. Add one below.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 6),

        // Add step form
        _buildAddStepForm(),
      ],
    );
  }

  Widget _buildStepCard(int index) {
    final step = widget.steps[index];
    final isWait = step.actionType == MacroActionType.wait;
    final label =
        isWait ? 'Wait ${step.delay.toStringAsFixed(1)}s' : step.actionName;

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Step number badge
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Action icon
          Icon(
            _actionIcon(step.actionType),
            size: 14,
            color: isWait ? Colors.grey : Colors.cyanAccent,
          ),
          const SizedBox(width: 4),
          // Label
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Condition badge
          if (step.condition != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _conditionLabel(step.condition),
                style: const TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Reorder buttons
          InkWell(
            onTap: index > 0 ? () => _moveStep(index, -1) : null,
            child: Icon(Icons.arrow_upward,
                size: 14,
                color: index > 0 ? Colors.white54 : Colors.white12),
          ),
          InkWell(
            onTap: index < widget.steps.length - 1
                ? () => _moveStep(index, 1)
                : null,
            child: Icon(Icons.arrow_downward,
                size: 14,
                color: index < widget.steps.length - 1
                    ? Colors.white54
                    : Colors.white12),
          ),
          const SizedBox(width: 2),
          // Delete button
          InkWell(
            onTap: () => _deleteStep(index),
            child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStepForm() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADD STEP',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),

          // Action type dropdown
          Row(
            children: [
              const Text('Type: ',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 4),
              _buildDropdown<MacroActionType>(
                value: _addActionType,
                items: [MacroActionType.ability, MacroActionType.wait],
                labelBuilder: (v) =>
                    v == MacroActionType.ability ? 'Ability' : 'Wait',
                onChanged: (v) => setState(() {
                  _addActionType = v;
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Ability selector or wait duration
          if (_addActionType == MacroActionType.ability) ...[
            Row(
              children: [
                const Text('Ability: ',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildAbilityDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Delay: ',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(width: 4),
                SizedBox(
                  width: 50,
                  height: 24,
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      hintText: '0',
                      hintStyle: const TextStyle(color: Colors.white24),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _addDelay = double.tryParse(v) ?? 0.0,
                  ),
                ),
                const Text(' sec',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Text('Duration: ',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(width: 4),
                SizedBox(
                  width: 50,
                  height: 24,
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      hintText: '1.0',
                      hintStyle: const TextStyle(color: Colors.white24),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _addWaitDuration = double.tryParse(v) ?? 1.0,
                  ),
                ),
                const Text(' sec',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ],
          const SizedBox(height: 4),

          // Condition dropdown
          Row(
            children: [
              const Text('Condition: ',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 4),
              _buildDropdown<String>(
                value: _addCondition ?? '(none)',
                items: _conditions,
                labelBuilder: (v) => v,
                onChanged: (v) => setState(() {
                  _addCondition = v;
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Add button
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add, size: 14),
              label:
                  const Text('Add', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.withOpacity(0.3),
                foregroundColor: Colors.cyanAccent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generic dropdown builder.
  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T) onChanged,
  }) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    style:
                        const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        dropdownColor: const Color(0xFF1a1a2e),
        underline: const SizedBox.shrink(),
        isDense: true,
        iconSize: 16,
        iconEnabledColor: Colors.white54,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  /// Searchable ability dropdown.
  Widget _buildAbilityDropdown() {
    final names = _abilityNames;
    final selected = _addAbilityName ?? (names.isNotEmpty ? names.first : null);

    // Ensure selected is in the list
    if (selected != null && !names.contains(selected)) {
      _addAbilityName = names.isNotEmpty ? names.first : null;
    } else if (_addAbilityName == null && names.isNotEmpty) {
      _addAbilityName = names.first;
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButton<String>(
        value: _addAbilityName,
        items: names
            .map((name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                    name,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _addAbilityName = v);
        },
        dropdownColor: const Color(0xFF1a1a2e),
        underline: const SizedBox.shrink(),
        isDense: true,
        isExpanded: true,
        iconSize: 16,
        iconEnabledColor: Colors.white54,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
