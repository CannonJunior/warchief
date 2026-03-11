import 'package:flutter/material.dart';
import '../../../models/duel_result.dart';
import '../../data/duel/duel_definitions.dart';
import '../../data/abilities/ability_types.dart';

part 'duel_history_chart.dart';
part 'duel_history_stats.dart';

// ── Constants shared across methods ──────────────────────────────────────────

const _surface = Color(0xFF16213e);
const _text    = Color(0xFFe0e0e0);
const _subtext = Color(0xFF9e9e9e);
const _red     = Color(0xFFef5350);
const _green   = Color(0xFF4caf50);
const _blue    = Colors.blueAccent;

// ─────────────────────────────────────────────────────────────────────────────

/// Detail view shown when a history row is tapped.
///
/// Displays:
///  • 2-line health chart (blue = challenger party, red = enemy party)
///  • Optional per-combatant individual HP lines (toggle when party > 1)
///  • DPS / HPS statistics for each side
///  • Ability-usage breakdown sorted by frequency
class DuelHistoryDetail extends StatefulWidget {
  final DuelResult result;
  final VoidCallback onBack;

  const DuelHistoryDetail({
    super.key,
    required this.result,
    required this.onBack,
  });

  @override
  State<DuelHistoryDetail> createState() => _DuelHistoryDetailState();
}

class _DuelHistoryDetailState extends State<DuelHistoryDetail> {
  bool _showIndividual = false;

  bool get _hasMultiple =>
      widget.result.challengerClasses.length > 1 ||
      widget.result.enemyTypes.length > 1;

  // ── Health timeline reconstruction (party totals) ─────────────────────────

  List<_HealthPoint> _buildTimeline() {
    final chalMax  = widget.result.challengerMaxHp;
    final enemyMax = widget.result.enemyMaxHp;
    // Reason: old records pre-dating this field have 0; skip rather than divide-by-zero.
    if (chalMax <= 0 || enemyMax <= 0) return [];

    double chalHp  = chalMax;
    double enemyHp = enemyMax;
    final points   = <_HealthPoint>[_HealthPoint(0, 1.0, 1.0)];

    for (final event in widget.result.events) {
      if (event.type == 'damage') {
        if (event.actorId == 'challenger') {
          enemyHp = (enemyHp - event.value).clamp(0.0, enemyMax);
        } else {
          chalHp = (chalHp - event.value).clamp(0.0, chalMax);
        }
        points.add(_HealthPoint(event.timeSeconds, chalHp / chalMax, enemyHp / enemyMax));
      } else if (event.type == 'heal') {
        if (event.actorId == 'challenger') {
          chalHp = (chalHp + event.value).clamp(0.0, chalMax);
        } else {
          enemyHp = (enemyHp + event.value).clamp(0.0, enemyMax);
        }
        points.add(_HealthPoint(event.timeSeconds, chalHp / chalMax, enemyHp / enemyMax));
      }
    }
    points.add(_HealthPoint(
        widget.result.durationSeconds, chalHp / chalMax, enemyHp / enemyMax));
    return points;
  }

  // ── Per-combatant timeline (individual HP toggle) ─────────────────────────

  List<_ChartSeries> _buildIndividualSeries() {
    final result    = widget.result;
    final chalSize  = result.challengerClasses.length;
    final enemySize = result.enemyTypes.length;
    final chalMax   = result.challengerMaxHp;
    final enemyMax  = result.enemyMaxHp;
    if (chalMax <= 0 || enemyMax <= 0) return [];

    // Reason: equal-HP distribution approximates per-combatant max HP;
    // per-combatant HP is not stored in DuelResult to keep the JSON compact.
    final chalHpPer  = chalMax / chalSize;
    final enemyHpPer = enemyMax / enemySize;

    final chalHps  = List.filled(chalSize,  chalHpPer);
    final enemyHps = List.filled(enemySize, enemyHpPer);
    final chalPts  = List.generate(chalSize,  (_) => [_ChartPoint(0.0, 1.0)]);
    final enemyPts = List.generate(enemySize, (_) => [_ChartPoint(0.0, 1.0)]);

    for (final ev in result.events) {
      if (ev.type == 'damage') {
        if (ev.actorId == 'challenger') {
          final i = (ev.targetIndex ?? 0).clamp(0, enemySize - 1);
          enemyHps[i] = (enemyHps[i] - ev.value).clamp(0, enemyHpPer);
          enemyPts[i].add(_ChartPoint(ev.timeSeconds, enemyHps[i] / enemyHpPer));
        } else {
          final i = (ev.targetIndex ?? 0).clamp(0, chalSize - 1);
          chalHps[i] = (chalHps[i] - ev.value).clamp(0, chalHpPer);
          chalPts[i].add(_ChartPoint(ev.timeSeconds, chalHps[i] / chalHpPer));
        }
      } else if (ev.type == 'heal') {
        if (ev.actorId == 'challenger') {
          final i = (ev.targetIndex ?? 0).clamp(0, chalSize - 1);
          chalHps[i] = (chalHps[i] + ev.value).clamp(0, chalHpPer);
          chalPts[i].add(_ChartPoint(ev.timeSeconds, chalHps[i] / chalHpPer));
        } else {
          final i = (ev.targetIndex ?? 0).clamp(0, enemySize - 1);
          enemyHps[i] = (enemyHps[i] + ev.value).clamp(0, enemyHpPer);
          enemyPts[i].add(_ChartPoint(ev.timeSeconds, enemyHps[i] / enemyHpPer));
        }
      }
    }

    final dur = result.durationSeconds;
    for (int i = 0; i < chalSize;  i++) {
      chalPts[i].add(_ChartPoint(dur, chalHps[i]  / chalHpPer));
    }
    for (int i = 0; i < enemySize; i++) {
      enemyPts[i].add(_ChartPoint(dur, enemyHps[i] / enemyHpPer));
    }

    final chalColors  = <Color>[Colors.blue, Colors.lightBlue, Colors.cyan, Colors.indigo, Colors.teal];
    final enemyColors = <Color>[_red, Colors.orange, Colors.deepOrange, Colors.amber, Colors.pink];
    final names = DuelDefinitions.allDisplayNames;

    return [
      for (int i = 0; i < chalSize; i++)
        _ChartSeries(
            points: chalPts[i],
            color: chalColors[i % chalColors.length],
            label: names[result.challengerClasses[i]] ?? result.challengerClasses[i]),
      for (int i = 0; i < enemySize; i++)
        _ChartSeries(
            points: enemyPts[i],
            color: enemyColors[i % enemyColors.length],
            label: names[result.enemyTypes[i]] ?? result.enemyTypes[i]),
    ];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final result     = widget.result;
    final chalLabel  = _partyLabel(result.challengerClasses);
    final enemyLabel = _partyLabel(result.enemyTypes);
    final dur        = result.durationSeconds;
    final safeDur    = dur > 0 ? dur : 1.0;

    return Column(children: [
      _buildDetailHeader(chalLabel, enemyLabel),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildHealthChart(dur),
            const SizedBox(height: 12),
            _buildStatsRow(safeDur),
            const SizedBox(height: 12),
            _buildPerCharacterSection(safeDur),
            const SizedBox(height: 12),
            _buildAbilityBreakdown(),
          ]),
        ),
      ),
    ]);
  }

  // ── Detail header (back + title) ──────────────────────────────────────────

  Widget _buildDetailHeader(String chalLabel, String enemyLabel) {
    final result = widget.result;
    final winnerLabel = result.winnerId == 'challenger'
        ? 'Blue Side Wins'
        : result.winnerId == 'enemy'
            ? 'Red Side Wins'
            : 'Draw';
    final winnerColor = result.winnerId == 'challenger'
        ? _blue
        : result.winnerId == 'enemy'
            ? _red
            : Colors.amber;

    return Container(
      height: 44,
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(children: [
        IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_ios, size: 13, color: _subtext),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          tooltip: 'Back to history',
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$chalLabel  vs  $enemyLabel',
                  style: const TextStyle(
                      color: _text, fontSize: 10, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              Text(
                '$winnerLabel  ·  ${result.durationSeconds.toStringAsFixed(0)}s',
                style: TextStyle(color: winnerColor, fontSize: 9),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Health chart ──────────────────────────────────────────────────────────

  Widget _buildHealthChart(double dur) {
    final safeDur = dur > 0 ? dur : 1.0;
    Widget chartContent;

    if (_showIndividual && _hasMultiple) {
      final series = _buildIndividualSeries();
      chartContent = series.isEmpty
          ? const Center(
              child: Text('No chart data\n(recorded before v2 format)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _subtext, fontSize: 9)))
          : CustomPaint(
              painter: _IndividualChartPainter(series: series, duration: safeDur));
    } else {
      final timeline = _buildTimeline();
      chartContent = timeline.length < 2
          ? const Center(
              child: Text('No chart data\n(recorded before v2 format)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _subtext, fontSize: 9)))
          : CustomPaint(
              painter: _HealthChartPainter(timeline: timeline, duration: safeDur));
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Legend row + optional party/individual toggle
        Row(children: [
          const Text('HP over time',
              style: TextStyle(
                  color: _subtext, fontSize: 9, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (!_showIndividual || !_hasMultiple) ...[
            _legendDot(_blue),
            const SizedBox(width: 3),
            const Text('Blue', style: TextStyle(color: _subtext, fontSize: 8)),
            const SizedBox(width: 10),
            _legendDot(_red),
            const SizedBox(width: 3),
            const Text('Red', style: TextStyle(color: _subtext, fontSize: 8)),
            if (_hasMultiple) const SizedBox(width: 8),
          ],
          if (_hasMultiple) _buildToggleChip(),
        ]),
        const SizedBox(height: 6),
        SizedBox(height: 130, child: chartContent),
        const SizedBox(height: 2),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('0s', style: TextStyle(color: _subtext, fontSize: 7)),
          Text('${dur.toStringAsFixed(0)}s',
              style: const TextStyle(color: _subtext, fontSize: 7)),
        ]),
      ]),
    );
  }

  Widget _buildToggleChip() {
    return GestureDetector(
      onTap: () => setState(() => _showIndividual = !_showIndividual),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _showIndividual ? _blue.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(color: _subtext.withValues(alpha: 0.5), width: 0.8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          _showIndividual ? 'Individual' : 'Party',
          style: TextStyle(
              color: _showIndividual ? _blue : _subtext, fontSize: 8),
        ),
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
