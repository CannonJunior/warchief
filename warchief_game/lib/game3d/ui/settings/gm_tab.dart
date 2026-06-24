import 'package:flutter/material.dart';
import '../../state/gameplay_settings.dart';

/// GM (Game Master) tab — test/debug toggles for development features.
///
/// Each toggle enables a keyboard shortcut or behavior that is useful for
/// testing but not intended for normal gameplay. All toggles default to off
/// and persist via [GameplaySettings].
class GmTab extends StatefulWidget {
  const GmTab({super.key});

  @override
  State<GmTab> createState() => _GmTabState();
}

class _GmTabState extends State<GmTab> {
  @override
  Widget build(BuildContext context) {
    final settings = globalGameplaySettings;
    if (settings == null) {
      return const Center(
        child: Text('Settings not loaded', style: TextStyle(color: Colors.white54)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFFFF9800), size: 20),
              SizedBox(width: 8),
              Text(
                'Game Master',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Test features and debug shortcuts. These are development tools '
            'and may be removed in future builds.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Keyboard Shortcuts'),
          const SizedBox(height: 10),
          _buildToggleRow(
            icon: Icons.air,
            label: 'Zephyr Key (Z)',
            description: 'Press Z to trigger a zephyr wind storm',
            value: settings.gmZephyrKey,
            onChanged: (v) {
              settings.gmZephyrKey = v;
              settings.save();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFF9800),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value
              ? const Color(0xFFFF9800).withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: value ? const Color(0xFFFF9800) : Colors.white38,
              size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: value ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFF9800),
            activeTrackColor: const Color(0xFFFF9800).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
