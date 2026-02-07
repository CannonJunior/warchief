import 'package:flutter/material.dart';
import '../../models/damage_event.dart';

/// DPS Panel - Shows damage statistics during target dummy testing
///
/// Opened with SHIFT+D, this panel displays:
/// - Overall DPS meter
/// - Horizontal bar chart of damage by ability
/// - Boxplots showing damage distribution
/// - Hit rate and critical hit rate
class DpsPanel extends StatefulWidget {
  final VoidCallback onClose;
  final DpsTracker dpsTracker;

  const DpsPanel({
    Key? key,
    required this.onClose,
    required this.dpsTracker,
  }) : super(key: key);

  @override
  State<DpsPanel> createState() => _DpsPanelState();
}

class _DpsPanelState extends State<DpsPanel> {
  double _xPos = 100.0;
  double _yPos = 100.0;

  @override
  Widget build(BuildContext context) {
    final stats = widget.dpsTracker.getAllAbilityStats();
    final totalDamage = widget.dpsTracker.totalDamage;

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPos += details.delta.dx;
            _yPos += details.delta.dy;
            _xPos = _xPos.clamp(0.0, MediaQuery.of(context).size.width - 420);
            _yPos = _yPos.clamp(0.0, MediaQuery.of(context).size.height - 500);
          });
        },
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF6B35), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverallStats(),
                      const SizedBox(height: 16),
                      _buildDamageChart(stats, totalDamage),
                      const SizedBox(height: 16),
                      _buildAbilityDetails(stats),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.drag_indicator, color: Color(0xFFFF6B35), size: 20),
              const SizedBox(width: 8),
              const Icon(Icons.analytics, color: Color(0xFFFF6B35), size: 20),
              const SizedBox(width: 8),
              const Text(
                'DPS METER',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '[SHIFT+D]',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    final tracker = widget.dpsTracker;
    final dps = tracker.overallDps;
    final duration = tracker.sessionDuration;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF252542)),
      ),
      child: Column(
        children: [
          // Big DPS number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dps.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'DPS',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Secondary stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Total Damage', tracker.totalDamage.toStringAsFixed(0), Colors.white),
              _buildStatBox('Duration', '${duration.toStringAsFixed(1)}s', Colors.cyan),
              _buildStatBox('Attacks', '${tracker.totalAttacks}', Colors.amber),
            ],
          ),
          const SizedBox(height: 8),
          // Hit/Crit rates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Hit Rate', '${tracker.hitRate.toStringAsFixed(1)}%', Colors.green),
              _buildStatBox('Crit Rate', '${tracker.critRate.toStringAsFixed(1)}%', Colors.orange),
              _buildStatBox('Crits', '${tracker.totalCrits}', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDamageChart(List<AbilityDamageStats> stats, double totalDamage) {
    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Attack the Target Dummy to see damage breakdown',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Damage Breakdown'),
        const SizedBox(height: 8),
        ...stats.map((stat) => _buildDamageBar(stat, totalDamage)),
      ],
    );
  }

  Widget _buildDamageBar(AbilityDamageStats stat, double totalDamage) {
    final percentage = totalDamage > 0 ? (stat.totalDamage / totalDamage) : 0.0;
    final dpsContribution = stat.dpsContribution(widget.dpsTracker.sessionDuration);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: stat.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stat.abilityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '${stat.totalDamage.toStringAsFixed(0)} (${(percentage * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Damage bar
          Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    '${dpsContribution.toStringAsFixed(1)} DPS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityDetails(List<AbilityDamageStats> stats) {
    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ability Details'),
        const SizedBox(height: 8),
        ...stats.map((stat) => _buildAbilityDetailCard(stat)),
      ],
    );
  }

  Widget _buildAbilityDetailCard(AbilityDamageStats stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: stat.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat.abilityName,
                style: TextStyle(
                  color: stat.color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${stat.hitCount} hits / ${stat.totalAttempts} attempts',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Boxplot visualization
          _buildBoxplot(stat),
          const SizedBox(height: 8),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Min', stat.minDamage.toStringAsFixed(0)),
              _buildMiniStat('Avg', stat.avgDamage.toStringAsFixed(1)),
              _buildMiniStat('Max', stat.maxDamage.toStringAsFixed(0)),
              _buildMiniStat('Hit%', '${stat.hitRate.toStringAsFixed(0)}%'),
              _buildMiniStat('Crit%', '${stat.critRate.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoxplot(AbilityDamageStats stat) {
    if (stat.hitCount == 0 || stat.maxDamage == 0) {
      return Container(
        height: 24,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
          ),
        ),
      );
    }

    // Normalize positions (0-1)
    final range = stat.maxDamage - stat.minDamage;
    final double minPos = 0;
    final double maxPos = 1;
    final double q1Pos = range > 0 ? (stat.q1Damage - stat.minDamage) / range : 0.5;
    final double medianPos = range > 0 ? (stat.medianDamage - stat.minDamage) / range : 0.5;
    final double q3Pos = range > 0 ? (stat.q3Damage - stat.minDamage) / range : 0.5;

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Stack(
            children: [
              // Whisker line (min to max)
              Positioned(
                left: minPos * width,
                right: (1 - maxPos) * width,
                top: 11,
                child: Container(
                  height: 2,
                  color: stat.color.withValues(alpha: 0.5),
                ),
              ),
              // Min whisker cap
              Positioned(
                left: minPos * width - 1,
                top: 6,
                child: Container(
                  width: 2,
                  height: 12,
                  color: stat.color.withValues(alpha: 0.5),
                ),
              ),
              // Max whisker cap
              Positioned(
                left: maxPos * width - 1,
                top: 6,
                child: Container(
                  width: 2,
                  height: 12,
                  color: stat.color.withValues(alpha: 0.5),
                ),
              ),
              // IQR box (Q1 to Q3)
              Positioned(
                left: q1Pos * width,
                width: (q3Pos - q1Pos).clamp(0.02, 1.0) * width,
                top: 4,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.3),
                    border: Border.all(color: stat.color, width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Median line
              Positioned(
                left: medianPos * width - 1,
                top: 2,
                child: Container(
                  width: 2,
                  height: 20,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFFF6B35),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
