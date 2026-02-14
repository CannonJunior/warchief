import 'package:flutter/material.dart';
import '../../models/building.dart';
import '../../rendering3d/ley_lines.dart';
import '../systems/building_system.dart';

/// Building Panel - Draggable info/upgrade panel for a selected building.
///
/// Opened with the 'H' key when near a building. Shows:
/// - Building name and tier
/// - Aura effects (health regen, mana regen, radius)
/// - Ley line bonus if applicable
/// - Upgrade button (if higher tier available)
///
/// Follows the same draggable pattern as [CharacterPanel].
class BuildingPanel extends StatefulWidget {
  final Building building;
  final LeyLineManager? leyLineManager;
  final VoidCallback onClose;
  final VoidCallback onUpgrade;

  const BuildingPanel({
    Key? key,
    required this.building,
    required this.leyLineManager,
    required this.onClose,
    required this.onUpgrade,
  }) : super(key: key);

  @override
  State<BuildingPanel> createState() => _BuildingPanelState();
}

class _BuildingPanelState extends State<BuildingPanel> {
  double _xPos = 120.0;
  double _yPos = 100.0;

  @override
  Widget build(BuildContext context) {
    final building = widget.building;
    final tierDef = building.tierDef;
    final leyBonus = BuildingSystem.getLeyLineBonus(
      building, widget.leyLineManager,
    );
    final hasLeyBonus = leyBonus > 1.0;

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
          width: 280,
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
              _buildHeader(building),

              // Body content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier name
                    Text(
                      'Tier ${tierDef.tier}: ${tierDef.name}',
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      building.definition.description,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Aura Effects section
                    _buildSectionHeader('AURA EFFECTS'),
                    const SizedBox(height: 6),
                    _buildStatRow(
                      'Health Regen',
                      '+${_fmt(tierDef.healthRegen * leyBonus)}/s',
                      const Color(0xFF4CAF50),
                    ),
                    _buildStatRow(
                      'Mana Regen',
                      '+${_fmt(tierDef.manaRegen * leyBonus)}/s',
                      const Color(0xFF42A5F5),
                    ),
                    _buildStatRow(
                      'Aura Radius',
                      '${_fmt(tierDef.auraRadius)}',
                      const Color(0xFFCCCCCC),
                    ),

                    // Ley Line Bonus
                    if (hasLeyBonus) ...[
                      const SizedBox(height: 4),
                      _buildStatRow(
                        'Ley Line Bonus',
                        '${leyBonus.toStringAsFixed(1)}x',
                        const Color(0xFF9C27B0),
                      ),
                    ],

                    // Upgrade section
                    if (building.canUpgrade) ...[
                      const SizedBox(height: 12),
                      _buildSectionHeader('UPGRADE'),
                      const SizedBox(height: 8),
                      _buildUpgradeButton(building),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the header bar with title and close button.
  Widget _buildHeader(Building building) {
    // Category icon
    IconData categoryIcon;
    switch (building.definition.category) {
      case 'residential':
        categoryIcon = Icons.home;
        break;
      case 'military':
        categoryIcon = Icons.shield;
        break;
      case 'production':
        categoryIcon = Icons.build;
        break;
      default:
        categoryIcon = Icons.house;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF252542),
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          Icon(categoryIcon, color: const Color(0xFFD4A76A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              building.definition.name,
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

  /// Build a stat row: label on left, value on right with color accent.
  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the upgrade button showing next tier info.
  Widget _buildUpgradeButton(Building building) {
    final nextTier = building.definition.getTier(building.currentTier + 1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onUpgrade,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4CAF50), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Upgrade to ${nextTier.name} (Tier ${nextTier.tier})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+${_fmt(nextTier.healthRegen)} HP/s, '
                '+${_fmt(nextTier.manaRegen)} MP/s',
                style: const TextStyle(
                  color: Color(0xFFAED581),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format a double for display (1 decimal place, no trailing zeros).
  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}
