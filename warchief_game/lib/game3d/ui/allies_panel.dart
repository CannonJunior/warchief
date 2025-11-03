import 'package:flutter/material.dart';
import '../../models/ally.dart';
import 'cooldown_clock_painter.dart';

/// Allies Panel displaying all allies with health bars, ability buttons, and add/remove buttons
class AlliesPanel extends StatelessWidget {
  final List<Ally> allies;
  final void Function(Ally) onActivateAllyAbility;
  final VoidCallback onAddAlly;
  final VoidCallback onRemoveAlly;

  const AlliesPanel({
    Key? key,
    required this.allies,
    required this.onActivateAllyAbility,
    required this.onAddAlly,
    required this.onRemoveAlly,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final abilityNames = ['Sword', 'Fireball', 'Heal'];
    final abilityColors = [
      Color(0xFFB3B3CC), // Gray (sword)
      Color(0xFFFF6600), // Orange (fireball)
      Color(0xFF80FF4D), // Green (heal)
    ];

    return Positioned(
      top: 120,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Ally management buttons
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ALLIES (${allies.length})',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    // Add Ally button
                    ElevatedButton(
                      onPressed: onAddAlly,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size(50, 30),
                      ),
                      child: Text(
                        '+ Ally',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Remove Ally button
                    ElevatedButton(
                      onPressed: allies.isEmpty ? null : onRemoveAlly,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.grey.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size(50, 30),
                      ),
                      child: Text(
                        '- Ally',
                        style: TextStyle(
                          color: allies.isEmpty ? Colors.white38 : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Individual ally displays
          ...allies.asMap().entries.map((entry) {
            final index = entry.key;
            final ally = entry.value;

            return Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Ally label
                  Text(
                    'ALLY ${index + 1}',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  // Health bar
                  Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade600, width: 2),
                    ),
                    child: Stack(
                      children: [
                        // Health fill
                        FractionallySizedBox(
                          widthFactor: (ally.health / ally.maxHealth).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: ally.health > 25 ? Colors.green :
                                     ally.health > 12 ? Colors.orange : Colors.red,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Health text
                        Center(
                          child: Text(
                            '${ally.health.toStringAsFixed(0)} / ${ally.maxHealth.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  // Ability display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        abilityNames[ally.abilityIndex],
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                      SizedBox(width: 6),
                      InkWell(
                        onTap: ally.abilityCooldown > 0 || ally.health <= 0
                            ? null
                            : () => onActivateAllyAbility(ally),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30, width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Stack(
                            children: [
                              // Base color
                              Container(
                                decoration: BoxDecoration(
                                  color: ally.abilityCooldown > 0
                                      ? Colors.grey.shade700
                                      : abilityColors[ally.abilityIndex],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              // Cooldown clock animation
                              if (ally.abilityCooldown > 0)
                                CustomPaint(
                                  size: Size(40, 40),
                                  painter: CooldownClockPainter(
                                    progress: 1.0 - (ally.abilityCooldown / ally.abilityCooldownMax),
                                  ),
                                ),
                              // Ability number label
                              Center(
                                child: Text(
                                  '${ally.abilityIndex + 1}',
                                  style: TextStyle(
                                    color: ally.abilityCooldown > 0
                                        ? Colors.white38
                                        : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
