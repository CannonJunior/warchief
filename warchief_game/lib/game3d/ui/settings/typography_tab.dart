import 'package:flutter/material.dart';
import '../../state/gameplay_settings.dart';

/// Available font families the user can choose from.
/// 'Default' means no override (Flutter's system default).
const List<String> kAvailableFonts = [
  'Default',
  'Bangers',
  'Arial',
  'Georgia',
  'Trebuchet MS',
  'Courier New',
];

/// All typography and display-text settings consolidated in one tab:
/// font family, size, color, and effects for each text category,
/// plus show/hide toggles for floating numbers.
class TypographyTab extends StatefulWidget {
  const TypographyTab({super.key});

  @override
  State<TypographyTab> createState() => _TypographyTabState();
}

class _TypographyTabState extends State<TypographyTab> {
  GameplaySettings? get _s => globalGameplaySettings;

  void _save() => _s?.save();

  // ── Preset palettes per category ────────────────────────────────────────
  static const _damageColors = [
    0xFFFFDD00, 0xFFFFAA00, 0xFFFF6600, 0xFFFFFFFF,
    0xFFFF88CC, 0xFF88DDFF, 0xFFCCFF44,
  ];
  static const _healColors = [
    0xFF44FF44, 0xFF00FF99, 0xFF00FFCC, 0xFF88FFAA,
    0xFFFFFFFF, 0xFFAAFFFF, 0xFF44EE88,
  ];
  static const _killColors = [
    0xFFFF2222, 0xFFFF6600, 0xFFFF00FF, 0xFFFF44AA,
    0xFFFFDD00, 0xFFFFFFFF, 0xFFAA00FF,
  ];
  static const _queueColors = [
    0xFFFFFFFF, 0xFFFFDD00, 0xFF4cc9f0, 0xFFAAFFAA,
    0xFFFFAA44, 0xFFFF88CC, 0xFFCCCCCC,
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
            'Typography',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Font, size, color, and effects for every text category in the game.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // ── Interface Text ─────────────────────────────────────────────
          _buildSectionHeader('Interface Text', Icons.dashboard_outlined),
          const SizedBox(height: 12),
          _buildCard(children: [
            const Text(
              'Applies to all game UI panels, labels, and overlays.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 14),
            _buildFontRow(_s!.uiFontFamily,
                (v) => setState(() { _s!.uiFontFamily = v; _save(); })),
            const SizedBox(height: 14),
            _buildSizeRow(_s!.uiFontScale,
                (v) => setState(() { _s!.uiFontScale = v; _save(); })),
          ]),
          const SizedBox(height: 20),

          // ── Combat Text ────────────────────────────────────────────────
          _buildSectionHeader('Combat Text', Icons.bolt_outlined),
          const SizedBox(height: 12),
          _buildCard(children: [
            const Text(
              'Floating damage and heal numbers above units.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 14),
            _buildToggleRow(
              'Show Damage Numbers',
              _s!.showDamageNumbers,
              (v) => setState(() { _s!.showDamageNumbers = v; _save(); }),
            ),
            const SizedBox(height: 10),
            _buildToggleRow(
              'Show Heal Numbers',
              _s!.showHealNumbers,
              (v) => setState(() { _s!.showHealNumbers = v; _save(); }),
            ),
            const SizedBox(height: 10),
            _buildToggleRow(
              'Show Channel Bar',
              _s!.showChannelBar,
              (v) => setState(() { _s!.showChannelBar = v; _save(); }),
            ),
            const SizedBox(height: 14),
            _buildFontRow(_s!.combatFontFamily,
                (v) => setState(() { _s!.combatFontFamily = v; _save(); })),
            const SizedBox(height: 14),
            _buildSizeRow(_s!.damageNumberScale,
                (v) => setState(() { _s!.damageNumberScale = v; _save(); })),
            const SizedBox(height: 14),
            _buildColorRow(
              'Damage Color',
              _s!.combatDamageColor,
              _damageColors,
              (v) => setState(() { _s!.combatDamageColor = v; _save(); }),
            ),
            const SizedBox(height: 10),
            _buildColorRow(
              'Heal Color',
              _s!.combatHealColor,
              _healColors,
              (v) => setState(() { _s!.combatHealColor = v; _save(); }),
            ),
            const SizedBox(height: 10),
            _buildColorRow(
              'Kill Color',
              _s!.combatKillColor,
              _killColors,
              (v) => setState(() { _s!.combatKillColor = v; _save(); }),
            ),
            const SizedBox(height: 14),
            _buildToggleRow(
              'Drop Shadow',
              _s!.combatShadow,
              (v) => setState(() { _s!.combatShadow = v; _save(); }),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Ability Queue Text ─────────────────────────────────────────
          _buildSectionHeader('Ability Queue Text', Icons.queue_outlined),
          const SizedBox(height: 12),
          _buildCard(children: [
            const Text(
              'Queued ability names shown below the active unit. '
              'Abilities on cooldown appear dimmed.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 14),
            _buildFontRow(_s!.queueFontFamily,
                (v) => setState(() { _s!.queueFontFamily = v; _save(); })),
            const SizedBox(height: 14),
            _buildSizeRow(_s!.queueFontScale,
                (v) => setState(() { _s!.queueFontScale = v; _save(); })),
            const SizedBox(height: 14),
            _buildColorRow(
              'Text Color',
              _s!.queueTextColor,
              _queueColors,
              (v) => setState(() { _s!.queueTextColor = v; _save(); }),
            ),
            const SizedBox(height: 14),
            _buildDurationRow(
              'Exit Fade',
              _s!.queueExitDuration,
              (v) => setState(() { _s!.queueExitDuration = v; _save(); }),
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Shared builders ────────────────────────────────────────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: const Color(0xFF4cc9f0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildFontRow(String current, ValueChanged<String> onChanged) {
    return Row(
      children: [
        const SizedBox(
          width: 80,
          child:
              Text('Font', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFF4cc9f0).withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: kAvailableFonts.contains(current) ? current : 'Default',
                isExpanded: true,
                dropdownColor: const Color(0xFF1a1a2e),
                style:
                    const TextStyle(color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Color(0xFF4cc9f0), size: 18),
                items: kAvailableFonts
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(
                            f,
                            style: TextStyle(
                              fontFamily: f == 'Default' ? null : f,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Live preview
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Abc 123',
            style: TextStyle(
              fontFamily: current == 'Default' ? null : current,
              color: const Color(0xFF4cc9f0),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeRow(double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        const SizedBox(
          width: 80,
          child:
              Text('Size', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF4cc9f0),
              inactiveTrackColor:
                  const Color(0xFF4cc9f0).withValues(alpha: 0.2),
              thumbColor: const Color(0xFF4cc9f0),
              overlayColor: const Color(0xFF4cc9f0).withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF4cc9f0),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Slider for a time duration value (0.0 – 3.0 s).
  Widget _buildDurationRow(String label, double value, ValueChanged<double> onChanged) {
    return Row(children: [
      SizedBox(
        width: 80,
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ),
      Expanded(
        child: SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF4cc9f0),
            inactiveTrackColor: const Color(0xFF4cc9f0).withValues(alpha: 0.2),
            thumbColor: const Color(0xFF4cc9f0),
            overlayColor: const Color(0xFF4cc9f0).withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(0.0, 3.0),
            min: 0.0,
            max: 3.0,
            divisions: 30,
            onChanged: onChanged,
          ),
        ),
      ),
      SizedBox(
        width: 44,
        child: Text(
          '${value.toStringAsFixed(1)}s',
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Color(0xFF4cc9f0),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ]);
  }

  Widget _buildColorRow(
    String label,
    int currentValue,
    List<int> palette,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: palette.map((colorValue) {
              final isSelected = colorValue == currentValue;
              return GestureDetector(
                onTap: () => onChanged(colorValue),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(colorValue).withValues(alpha: 0.6),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Preview swatch of selected color
        Container(
          width: 32,
          height: 24,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Color(currentValue),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4cc9f0), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4cc9f0),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF4cc9f0).withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
