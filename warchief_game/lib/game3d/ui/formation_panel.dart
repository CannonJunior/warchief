import 'package:flutter/material.dart';
import '../ai/tactical_positioning.dart';

/// Formation Panel displaying current formation and cycle button (draggable version)
class FormationPanel extends StatelessWidget {
  final FormationType currentFormation;
  final VoidCallback onCycleFormation;
  final VoidCallback? onNextFormation;
  final VoidCallback? onPrevFormation;

  const FormationPanel({
    Key? key,
    required this.currentFormation,
    required this.onCycleFormation,
    this.onNextFormation,
    this.onPrevFormation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(currentFormation.color), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Formation icon/indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Color(currentFormation.color).withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Color(currentFormation.color), width: 1),
            ),
            child: Center(
              child: Text(
                currentFormation.shortLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          // Formation name and description
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FORMATION',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                currentFormation.name,
                style: TextStyle(
                  color: Color(currentFormation.color),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(width: 12),
          // Cycle button
          Tooltip(
            message: 'Cycle Formation (R)\n${currentFormation.description}',
            child: InkWell(
              onTap: onCycleFormation,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white30, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 14,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'R',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
}

/// Compact formation selector with all formation types
class FormationSelector extends StatelessWidget {
  final FormationType currentFormation;
  final void Function(FormationType) onFormationChanged;

  const FormationSelector({
    Key? key,
    required this.currentFormation,
    required this.onFormationChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FORMATION (R)',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: FormationType.values.map((formation) {
              final isSelected = currentFormation == formation;
              return Padding(
                padding: EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: '${formation.name}\n${formation.description}',
                  child: InkWell(
                    onTap: () => onFormationChanged(formation),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 28,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(formation.color)
                            : Color(formation.color).withOpacity(0.3),
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
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
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
}
