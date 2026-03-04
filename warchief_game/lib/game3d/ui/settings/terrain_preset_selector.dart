import 'package:flutter/material.dart';

import '../../state/terrain_presets.dart';

/// Grid of terrain preset cards for the Scenario settings tab.
///
/// Displays each [TerrainPreset] as a compact card with name, description,
/// roughness tag, and an elevation profile bar.  Tapping a card calls
/// [onChanged] with the selected preset's [TerrainPreset.id].
class TerrainPresetSelector extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onChanged;

  const TerrainPresetSelector({
    Key? key,
    required this.selectedId,
    required this.onChanged,
  }) : super(key: key);

  static const _accent   = Color(0xFF4cc9f0);
  static const _cardBg   = Color(0xFF252542);
  static const _dimText  = Colors.white54;

  // Roughness → badge colour
  static Color _roughnessColor(String label) {
    switch (label) {
      case 'Smooth':     return const Color(0xFF4FC3F7);
      case 'Gentle':     return const Color(0xFF81C784);
      case 'Moderate':   return const Color(0xFFFFB74D);
      case 'Rough':      return const Color(0xFFFF8A65);
      case 'Very Rough': return const Color(0xFFEF5350);
      case 'Extreme':    return const Color(0xFF9C27B0);
      default:           return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2-column grid
        for (int row = 0; row < (kTerrainPresets.length / 2).ceil(); row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (int col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(child: _buildCard(row * 2 + col)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCard(int index) {
    if (index >= kTerrainPresets.length) return const SizedBox.shrink();
    final preset   = kTerrainPresets[index];
    final selected = preset.id == selectedId;
    final badgeCol = _roughnessColor(preset.roughnessLabel);

    return GestureDetector(
      onTap: () => onChanged(preset.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.12)
              : _cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _accent : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + selected tick
            Row(
              children: [
                Expanded(
                  child: Text(
                    preset.name,
                    style: TextStyle(
                      color: selected ? _accent : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: _accent, size: 14),
              ],
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              preset.description,
              style: const TextStyle(color: _dimText, fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Bottom row: roughness badge + elevation bars
            Row(
              children: [
                _roughnessBadge(preset.roughnessLabel, badgeCol),
                const Spacer(),
                _elevationBars(preset),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roughnessBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Five vertical bars whose heights sketch a stylised terrain silhouette
  /// using the preset's normalizedHeight as the scale.
  Widget _elevationBars(TerrainPreset preset) {
    // Profile shapes per preset: 5 relative bar heights (0–1)
    final profile = _profileFor(preset.id);
    const barW = 4.0;
    const maxBarH = 18.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Container(
            width: barW,
            height: maxBarH * profile[i] * preset.normalizedHeight + 2,
            decoration: BoxDecoration(
              color: _accent.withValues(
                  alpha: 0.3 + 0.5 * profile[i] * preset.normalizedHeight),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2)),
            ),
          ),
        ],
      ],
    );
  }

  static List<double> _profileFor(String id) {
    switch (id) {
      case 'flat':           return [0.05, 0.08, 0.06, 0.07, 0.05];
      case 'ancient_plains': return [0.20, 0.35, 0.50, 0.30, 0.15];
      case 'rolling_hills':  return [0.40, 0.65, 0.85, 0.60, 0.45];
      case 'desert_dunes':   return [0.30, 0.75, 1.00, 0.55, 0.25];
      case 'highlands':      return [0.50, 0.70, 0.90, 0.80, 0.60];
      case 'craggy_wastes':  return [0.60, 0.90, 0.70, 1.00, 0.55];
      case 'mountains':      return [0.40, 0.70, 1.00, 0.85, 0.50];
      default:               return [0.40, 0.60, 0.80, 0.60, 0.40];
    }
  }
}
