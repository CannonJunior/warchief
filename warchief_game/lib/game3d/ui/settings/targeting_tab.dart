import 'package:flutter/material.dart';
import '../../state/gameplay_settings.dart';

/// Settings tab for configuring the 3D target indicator rectangles:
/// color (enemy, ally, acquired flash), line width, size scale, and
/// acquired-flash duration.
class TargetingTab extends StatefulWidget {
  const TargetingTab({super.key});

  @override
  State<TargetingTab> createState() => _TargetingTabState();
}

class _TargetingTabState extends State<TargetingTab> {
  static const Color _kAccent = Color(0xFF4cc9f0);

  GameplaySettings? get _s => globalGameplaySettings;
  void _save() => _s?.save();

  // ── Preset palettes ────────────────────────────────────────────────────
  static const _enemyColors = [
    0xFFFF3333, 0xFFFF6600, 0xFFFF0066, 0xFFFF44AA,
    0xFFFFFFFF, 0xFF00FFFF, 0xFFFF2222,
  ];
  static const _allyColors = [
    0xFF33FF44, 0xFF00FF99, 0xFF44FFCC, 0xFFAAFF44,
    0xFFFFFFFF, 0xFF44FFFF, 0xFF00DD66,
  ];
  static const _acquiredColors = [
    0xFFFFF200, 0xFFFFD700, 0xFFFFFFFF, 0xFF00FFFF,
    0xFFFF8800, 0xFFFF44FF, 0xFF88FF00,
  ];

  @override
  Widget build(BuildContext context) {
    if (_s == null) {
      return const Center(
        child: Text('Settings not available',
            style: TextStyle(color: Colors.white54)),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Targeting',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure the 3D target rectangles that appear on the ground.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // ── Geometry ──────────────────────────────────────────────────
          _buildSectionHeader('Geometry', Icons.crop_square),
          const SizedBox(height: 12),
          _buildCard(children: [
            const Text(
              'Controls the overall size and line thickness of all target rectangles.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 14),
            _buildSliderRow(
              label: 'Size',
              value: _s!.targetSizeScale,
              min: 0.5, max: 2.5, divisions: 20,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => setState(() { _s!.targetSizeScale = v; _save(); }),
            ),
            const SizedBox(height: 10),
            _buildSliderRow(
              label: 'Line Width',
              value: _s!.targetLineWidth,
              min: 0.03, max: 0.30, divisions: 18,
              format: (v) => v.toStringAsFixed(2),
              onChanged: (v) => setState(() { _s!.targetLineWidth = v; _save(); }),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Colors ────────────────────────────────────────────────────
          _buildSectionHeader('Colors', Icons.palette_outlined),
          const SizedBox(height: 12),
          _buildCard(children: [
            const Text(
              'Rectangle color by target type.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 14),
            _buildColorRow(
              label: 'Enemy',
              value: _s!.targetEnemyColor,
              palette: _enemyColors,
              onChanged: (v) => setState(() { _s!.targetEnemyColor = v; _save(); }),
            ),
            const SizedBox(height: 10),
            _buildColorRow(
              label: 'Ally',
              value: _s!.targetAllyColor,
              palette: _allyColors,
              onChanged: (v) => setState(() { _s!.targetAllyColor = v; _save(); }),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Acquired Flash ────────────────────────────────────────────
          _buildSectionHeader('Acquired Flash', Icons.flash_on_outlined),
          const SizedBox(height: 12),
          _buildCard(children: [
            const Text(
              'The larger rectangle shown briefly when a new target is selected.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 14),
            _buildColorRow(
              label: 'Color',
              value: _s!.targetAcquiredColor,
              palette: _acquiredColors,
              onChanged: (v) => setState(() { _s!.targetAcquiredColor = v; _save(); }),
            ),
            const SizedBox(height: 14),
            _buildSliderRow(
              label: 'Flash Size',
              value: _s!.targetAcquiredScale,
              min: 1.0, max: 2.5, divisions: 15,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => setState(() { _s!.targetAcquiredScale = v; _save(); }),
            ),
            const SizedBox(height: 10),
            _buildSliderRow(
              label: 'Duration',
              value: _s!.targetAcquiredDuration,
              min: 0.5, max: 6.0, divisions: 11,
              format: (v) => '${v.toStringAsFixed(1)}s',
              onChanged: (v) => setState(() { _s!.targetAcquiredDuration = v; _save(); }),
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Builders ────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _kAccent, size: 16),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: _kAccent, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
              height: 1,
              color: _kAccent.withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _kAccent,
              inactiveTrackColor: _kAccent.withValues(alpha: 0.2),
              thumbColor: _kAccent,
              overlayColor: _kAccent.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 46,
          child: Text(
            format(value),
            textAlign: TextAlign.right,
            style: const TextStyle(
                color: _kAccent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildColorRow({
    required String label,
    required int value,
    required List<int> palette,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: palette.map((c) {
              final selected = c == value;
              return GestureDetector(
                onTap: () => onChanged(c),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(c),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      width: selected ? 2.5 : 1,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(
                            color: Color(c).withValues(alpha: 0.6),
                            blurRadius: 6)]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Selected-color preview
        Container(
          width: 32,
          height: 24,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Color(value),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }
}
