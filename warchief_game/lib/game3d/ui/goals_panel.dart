import 'package:flutter/material.dart';
import '../../models/goal.dart';
import '../state/goals_config.dart';

/// Goals Panel — Draggable panel showing active goals with progress bars.
///
/// Opened with the 'G' key. Shows:
/// - Active goals grouped by category with color accent
/// - Progress bar with current/target count
/// - Completed goals with checkmark
/// - Pending spirit goal at bottom with accept/decline buttons
///
/// Follows the same draggable pattern as [BuildingPanel].
class GoalsPanel extends StatefulWidget {
  final List<Goal> goals;
  final GoalDefinition? pendingGoal;
  final void Function(GoalDefinition) onAcceptGoal;
  final VoidCallback onDeclineGoal;
  final VoidCallback onClose;

  const GoalsPanel({
    Key? key,
    required this.goals,
    required this.pendingGoal,
    required this.onAcceptGoal,
    required this.onDeclineGoal,
    required this.onClose,
  }) : super(key: key);

  @override
  State<GoalsPanel> createState() => _GoalsPanelState();
}

class _GoalsPanelState extends State<GoalsPanel> {
  double _xPos = 80.0;
  double _yPos = 80.0;

  @override
  Widget build(BuildContext context) {
    // Group active goals by category
    final activeGoals = widget.goals
        .where((g) =>
            g.status == GoalStatus.active || g.status == GoalStatus.completed)
        .toList();

    final grouped = <GoalCategory, List<Goal>>{};
    for (final goal in activeGoals) {
      grouped.putIfAbsent(goal.definition.category, () => []).add(goal);
    }

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPos += details.delta.dx;
            _yPos += details.delta.dy;
          });
        },
        child: Container(
          width: 300,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF3a3a5c),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bar
              _buildHeader(),

              // Body content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grouped active goals
                      if (grouped.isEmpty && widget.pendingGoal == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No active goals.\nThe Warrior Spirit may suggest one soon.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),

                      for (final category in GoalCategory.values)
                        if (grouped.containsKey(category))
                          _buildCategorySection(category, grouped[category]!),

                      // Pending spirit goal suggestion
                      if (widget.pendingGoal != null) ...[
                        const SizedBox(height: 8),
                        _buildSectionHeader('SPIRIT SUGGESTS'),
                        const SizedBox(height: 6),
                        _buildPendingGoal(widget.pendingGoal!),
                      ],
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

  /// Build the header bar with title and close button.
  Widget _buildHeader() {
    final activeCount = widget.goals
        .where((g) => g.status == GoalStatus.active)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF252542),
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, color: Color(0xFFD4A76A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GOALS ($activeCount active)',
              style: const TextStyle(
                color: Color(0xFFD4A76A),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFFFF6B6B),
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a category section with goals.
  Widget _buildCategorySection(GoalCategory category, List<Goal> goals) {
    final colorList = globalGoalsConfig?.getCategoryColor(category.name) ??
        [0.5, 0.5, 0.5, 1.0];
    final color = Color.fromRGBO(
      (colorList[0] * 255).round(),
      (colorList[1] * 255).round(),
      (colorList[2] * 255).round(),
      1.0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                category.name.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Goals in this category
          for (final goal in goals) _buildGoalRow(goal, color),
        ],
      ),
    );
  }

  /// Build a single goal row with progress bar.
  Widget _buildGoalRow(Goal goal, Color categoryColor) {
    final isCompleted = goal.status == GoalStatus.completed ||
        goal.status == GoalStatus.reflected;
    final progress = goal.progress;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Opacity(
        opacity: isCompleted ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50),
                      size: 12)
                else
                  const SizedBox(width: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    goal.definition.name,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  '${goal.currentValue}/${goal.definition.targetValue}',
                  style: TextStyle(
                    color: isCompleted
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFAAAAAA),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFF2a2a4a),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? const Color(0xFF4CAF50) : categoryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the pending goal suggestion with accept/decline buttons.
  Widget _buildPendingGoal(GoalDefinition goal) {
    final colorList = globalGoalsConfig?.getCategoryColor(goal.category.name) ??
        [0.7, 0.4, 0.9, 1.0];
    final color = Color.fromRGBO(
      (colorList[0] * 255).round(),
      (colorList[1] * 255).round(),
      (colorList[2] * 255).round(),
      1.0,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.name,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            goal.description,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                'Accept',
                const Color(0xFF4CAF50),
                () => widget.onAcceptGoal(goal),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                'Decline',
                const Color(0xFF666666),
                widget.onDeclineGoal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build an accept/decline button.
  Widget _buildActionButton(
      String label, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Build a section header label.
  Widget _buildSectionHeader(String label) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: const Color(0xFF3a3a5c)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: const Color(0xFF3a3a5c)),
        ),
      ],
    );
  }
}
