import 'package:flutter/material.dart';
import '../../models/ally.dart';
import '../ai/tactical_positioning.dart';

/// Unified Ally Commands Panel - opened/closed with the F key.
///
/// Contains:
/// - Formation selector (top section)
/// - Attack, Hold, Follow command buttons (bottom section)
class AllyCommandsPanel extends StatefulWidget {
  final VoidCallback onClose;
  final FormationType currentFormation;
  final void Function(FormationType) onFormationChanged;
  final AllyCommand currentCommand;
  final void Function(AllyCommand) onCommandChanged;
  final int allyCount;

  const AllyCommandsPanel({
    Key? key,
    required this.onClose,
    required this.currentFormation,
    required this.onFormationChanged,
    required this.currentCommand,
    required this.onCommandChanged,
    required this.allyCount,
  }) : super(key: key);

  @override
  State<AllyCommandsPanel> createState() => _AllyCommandsPanelState();
}

class _AllyCommandsPanelState extends State<AllyCommandsPanel> {
  double _xPos = 800.0;
  double _yPos = 150.0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF4cc9f0), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(screenSize),
            _buildFormationSection(),
            Container(height: 1, color: const Color(0xFF252542)),
            _buildCommandsSection(),
          ],
        ),
      ),
    );
  }

  /// Draggable header bar
  Widget _buildHeader(Size screenSize) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _xPos += details.delta.dx;
          _yPos += details.delta.dy;
          _xPos = _xPos.clamp(0.0, screenSize.width - 220);
          _yPos = _yPos.clamp(0.0, screenSize.height - 300);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator,
                color: Color(0xFF4cc9f0), size: 16),
            const SizedBox(width: 6),
            const Text(
              'COMMANDS',
              style: TextStyle(
                color: Color(0xFF4cc9f0),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Text(
              '[F]',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: widget.onClose,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(3),
                ),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formation selector section
  Widget _buildFormationSection() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FORMATION (R)',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: FormationType.values.map((formation) {
              final isSelected = widget.currentFormation == formation;
              return Tooltip(
                message: '${formation.name}\n${formation.description}',
                child: InkWell(
                  onTap: () => widget.onFormationChanged(formation),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 36,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(formation.color)
                          : Color(formation.color).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white30,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        formation.shortLabel,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Attack, Hold, Follow command buttons section
  Widget _buildCommandsSection() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ALLY COMMANDS',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.allyCount} allies',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCommandButton(
            label: 'ATTACK',
            hotkey: 'T',
            icon: Icons.sports_martial_arts,
            color: Colors.red,
            command: AllyCommand.attack,
          ),
          const SizedBox(height: 4),
          _buildCommandButton(
            label: 'HOLD',
            hotkey: 'G',
            icon: Icons.front_hand,
            color: Colors.orange,
            command: AllyCommand.hold,
          ),
          const SizedBox(height: 4),
          _buildCommandButton(
            label: 'FOLLOW',
            hotkey: 'F',
            icon: Icons.directions_walk,
            color: Colors.green,
            command: AllyCommand.follow,
          ),
        ],
      ),
    );
  }

  Widget _buildCommandButton({
    required String label,
    required String hotkey,
    required IconData icon,
    required Color color,
    required AllyCommand command,
  }) {
    final isActive = widget.currentCommand == command;

    return InkWell(
      onTap: () => widget.onCommandChanged(command),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.4),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? color : color.withValues(alpha: 0.7),
                size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? color : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (isActive)
              const Icon(Icons.check, color: Colors.white, size: 14),
            if (!isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  hotkey,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
