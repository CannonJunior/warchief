import 'package:flutter/material.dart';
import '../../state/cc_config.dart';

/// CC (Crowd Control) Tuning tab — read-only display of CC system config values.
///
/// Reads from [globalCcConfig] to show the current tuning for diminishing
/// returns, airborne physics, sleep, charm, banish, and gravity well.
class CcTuningTab extends StatelessWidget {
  const CcTuningTab({super.key});

  // Reason: amber/orange theme consistent with GM tab's debug/tuning aesthetic
  static const Color _accent = Color(0xFFFFAB00);

  @override
  Widget build(BuildContext context) {
    final cc = globalCcConfig;
    if (cc == null) {
      return const Center(
        child: Text(
          'CC config not loaded',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_clock, color: _accent, size: 20),
              SizedBox(width: 8),
              Text(
                'CC Tuning',
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
            'Crowd-control system parameters loaded from cc_config.json. '
            'These values are read-only for now.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // ==================== DIMINISHING RETURNS ====================
          _buildSectionHeader('Diminishing Returns'),
          const SizedBox(height: 10),
          _buildToggleRow(
            icon: Icons.repeat,
            label: 'DR Enabled',
            description: 'Apply diminishing returns to repeated CC on same target',
            value: cc.drEnabled,
          ),
          _buildSliderRow(
            icon: Icons.timer,
            label: 'DR Window',
            description: 'Seconds before DR resets on a target',
            value: cc.drWindow,
            min: 5.0,
            max: 30.0,
            unit: 's',
          ),

          const SizedBox(height: 16),

          // ==================== AIRBORNE ====================
          _buildSectionHeader('Airborne'),
          const SizedBox(height: 10),
          _buildSliderRow(
            icon: Icons.arrow_downward,
            label: 'Gravity Acceleration',
            description: 'How fast airborne units fall back down',
            value: cc.airborneGravityAccel,
            min: 4.0,
            max: 20.0,
            unit: '',
          ),
          _buildSliderRow(
            icon: Icons.heart_broken,
            label: 'Fall Damage per Unit',
            description: 'Damage dealt per height unit on landing',
            value: cc.airborneFallDamagePerUnit,
            min: 0.0,
            max: 15.0,
            unit: '',
          ),
          _buildSliderRow(
            icon: Icons.sports_martial_arts,
            label: 'Juggle Window',
            description: 'Seconds after landing when re-launch is easier',
            value: cc.airborneJuggleWindow,
            min: 0.0,
            max: 2.0,
            unit: 's',
          ),

          const SizedBox(height: 16),

          // ==================== SLEEP ====================
          _buildSectionHeader('Sleep'),
          const SizedBox(height: 10),
          _buildSliderRow(
            icon: Icons.bedtime,
            label: 'Regen Percent',
            description: 'HP regen per second while sleeping (% of max)',
            value: cc.sleepRegenPercent,
            min: 0.0,
            max: 5.0,
            unit: '%',
          ),

          const SizedBox(height: 16),

          // ==================== CHARM ====================
          _buildSectionHeader('Charm'),
          const SizedBox(height: 10),
          _buildSliderRow(
            icon: Icons.favorite,
            label: 'Walk Speed',
            description: 'Movement speed multiplier while charmed',
            value: cc.charmWalkSpeed,
            min: 0.2,
            max: 1.0,
            unit: 'x',
          ),

          const SizedBox(height: 16),

          // ==================== BANISH ====================
          _buildSectionHeader('Banish'),
          const SizedBox(height: 10),
          _buildSliderRow(
            icon: Icons.hourglass_top,
            label: 'Cooldown Tick Rate',
            description: 'Multiplier for ability cooldown ticks while banished',
            value: cc.banishCooldownTickRate,
            min: 1.0,
            max: 5.0,
            unit: 'x',
          ),

          const SizedBox(height: 16),

          // ==================== GRAVITY WELL ====================
          _buildSectionHeader('Gravity Well'),
          const SizedBox(height: 10),
          _buildSliderRow(
            icon: Icons.cyclone,
            label: 'Pull Speed',
            description: 'How fast units are pulled toward the well center',
            value: cc.gravityWellPullSpeed,
            min: 0.5,
            max: 5.0,
            unit: '',
          ),
        ],
      ),
    );
  }

  // ==================== WIDGET BUILDERS ====================

  Widget _buildSectionHeader(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _accent,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: _accent.withValues(alpha: 0.3),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? _accent.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? _accent : Colors.white38, size: 18),
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
          // Reason: read-only indicator instead of interactive Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: value
                  ? _accent.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value ? 'ON' : 'OFF',
              style: TextStyle(
                color: value ? _accent : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required String unit,
  }) {
    // Reason: clamp protects against config values outside slider range
    final clamped = value.clamp(min, max);
    final fraction = (max > min) ? (clamped - min) / (max - min) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)}$unit',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 8),
          // Reason: read-only progress bar instead of interactive Slider
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: _accent.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$min$unit',
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
              Text(
                '$max$unit',
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
