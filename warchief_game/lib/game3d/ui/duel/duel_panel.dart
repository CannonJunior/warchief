import 'dart:math' show max;
import 'package:flutter/material.dart';
import '../../state/duel_manager.dart';
import '../../data/duel/duel_definitions.dart';
import '../../../models/duel_result.dart';

part 'duel_panel_setup.dart';
part 'duel_panel_recents.dart';

/// Draggable 3-tab panel for the Duel Arena balance testing tool.
///
/// Tabs:
///  0 — Setup   : configure up to 5 characters per side, gear quality,
///                and strategy; start/reset duel
///  1 — Active  : live stats, event log, reset-cooldowns, cancel
///  2 — History : scrollable past results, clear button
class DuelPanel extends StatefulWidget {
  final DuelManager manager;

  /// Called when the user presses "Start Duel".  The panel builds a
  /// [DuelSetupConfig] from its local state and passes it to the handler.
  final void Function(DuelSetupConfig setup) onStartDuel;

  final VoidCallback onCancelDuel;

  /// Resets all ability cooldowns for every active duel combatant.
  final VoidCallback onResetCooldowns;

  const DuelPanel({
    Key? key,
    required this.manager,
    required this.onStartDuel,
    required this.onCancelDuel,
    required this.onResetCooldowns,
  }) : super(key: key);

  @override
  State<DuelPanel> createState() => _DuelPanelState();
}

class _DuelPanelState extends State<DuelPanel> {
  int _tabIndex = 0;

  // ── Setup-tab state ────────────────────────────────────────────────────────
  int _chalPartySize  = 1;
  int _enemyPartySize = 1;

  List<String?> _chalClasses  = [null];
  List<String?> _enemyTypes   = [null];
  List<int>     _chalGearTiers  = [0];
  List<int>     _enemyGearTiers = [0];

  DuelStrategy     _chalStrategy  = DuelStrategy.balanced;
  DuelStrategy     _enemyStrategy = DuelStrategy.balanced;

  DuelEndCondition _endCondition = DuelEndCondition.totalAnnihilation;
  bool             _showRecents  = false;

  // ── Colour palette ─────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF16213e);
  static const _accent  = Color(0xFF533483);
  static const _text    = Color(0xFFe0e0e0);
  static const _subtext = Color(0xFF9e9e9e);
  static const _red     = Color(0xFFef5350);
  static const _green   = Color(0xFF4caf50);

  @override
  void didUpdateWidget(DuelPanel old) {
    super.didUpdateWidget(old);
    if (widget.manager.phase == DuelPhase.active && _tabIndex != 1) {
      setState(() => _tabIndex = 1);
    }
  }

  // ── Party-array sync helpers ───────────────────────────────────────────────

  void _setPartySize(bool isChallenger, int n) {
    setState(() {
      if (isChallenger) {
        _chalPartySize = n;
        while (_chalClasses.length < n)   _chalClasses.add(null);
        while (_chalGearTiers.length < n) _chalGearTiers.add(0);
      } else {
        _enemyPartySize = n;
        while (_enemyTypes.length < n)     _enemyTypes.add(null);
        while (_enemyGearTiers.length < n) _enemyGearTiers.add(0);
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 560,
        height: 640,
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accent, width: 1),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: const Text('Duel Arena',
          style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTabBar() {
    const labels = ['Setup', 'Active', 'History'];
    return Container(
      height: 32,
      color: _surface,
      child: Row(
        children: List.generate(3, (i) {
          final selected = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _accent : Colors.transparent,
                  border: Border(
                      bottom: BorderSide(color: selected ? Colors.white30 : Colors.transparent)),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        color: selected ? Colors.white : _subtext,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:  return _buildSetupTab();    // defined in part file
      case 1:  return _buildActiveTab();
      case 2:  return _buildHistoryTab();
      default: return const SizedBox.shrink();
    }
  }

  // ── Active Tab ─────────────────────────────────────────────────────────────

  Widget _buildActiveTab() {
    final mgr   = widget.manager;
    final phase = mgr.phase;
    if (phase == DuelPhase.idle) {
      return const Center(
        child: Text('No duel in progress.', style: TextStyle(color: _subtext, fontSize: 12)),
      );
    }

    final chalName  = _partyLabel(
        mgr.selectedChallengerClass, mgr.challengerPartySize, isChallenger: true);
    final enemyName = _partyLabel(
        mgr.selectedEnemyType, mgr.enemyPartySize, isChallenger: false);
    final elapsed = mgr.elapsedSeconds;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.timer, color: _subtext, size: 14),
            const SizedBox(width: 4),
            Text('${elapsed.toStringAsFixed(1)}s',
                style: const TextStyle(color: _text, fontSize: 12)),
            const Spacer(),
            if (phase == DuelPhase.completed) _winnerBanner(mgr),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _statBlock(chalName,
                mgr.challengerStats.totalDamageDealt,
                mgr.challengerStats.totalHealingDone, Colors.blueAccent,
                gcd: mgr.challengerMaxGcd)),
            const SizedBox(width: 8),
            Expanded(child: _statBlock(enemyName,
                mgr.enemyStats.totalDamageDealt,
                mgr.enemyStats.totalHealingDone, _red,
                gcd: mgr.enemyMaxGcd)),
          ]),
          const SizedBox(height: 10),
          _sectionLabel('Event Log'),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(4)),
              child: ListView.builder(
                padding: const EdgeInsets.all(6),
                reverse: true,
                itemCount: mgr.currentEvents.length > 50 ? 50 : mgr.currentEvents.length,
                itemBuilder: (context, i) {
                  final idx = mgr.currentEvents.length - 1 - i;
                  return _eventRow(mgr.currentEvents[idx]);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (phase == DuelPhase.active) ...[
            SizedBox(
              width: double.infinity,
              height: 28,
              child: OutlinedButton(
                onPressed: () => setState(widget.onResetCooldowns),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Reset Cooldowns', style: TextStyle(fontSize: 10)),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton(
                onPressed: () {
                  widget.onCancelDuel();
                  setState(() => _tabIndex = 0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Cancel Duel', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── History Tab ────────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    final history = widget.manager.history;
    if (history.isEmpty) {
      return const Center(
        child: Text('No duel history yet.', style: TextStyle(color: _subtext, fontSize: 12)),
      );
    }
    return Column(children: [
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          itemCount: history.length,
          itemBuilder: (_, i) => _historyRow(history[i]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: double.infinity,
          height: 28,
          child: ElevatedButton(
            onPressed: () {
              setState(() => widget.manager.history.clear());
              widget.manager.saveHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Clear History', style: TextStyle(fontSize: 10)),
          ),
        ),
      ),
    ]);
  }

  // ── Shared widget helpers ──────────────────────────────────────────────────

  Widget _statBlock(String name, double dmg, double heal, Color color, {double gcd = 0.0}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('Dmg: ${dmg.toStringAsFixed(0)}', style: const TextStyle(color: _text, fontSize: 10)),
          Text('Heal: ${heal.toStringAsFixed(0)}', style: const TextStyle(color: _green, fontSize: 10)),
          // Reason: show GCD countdown only when it's actually ticking — a
          // permanent "GCD: 0.0s" label when idle would add visual noise.
          if (gcd > 0)
            Text('GCD: ${gcd.toStringAsFixed(1)}s',
                style: const TextStyle(color: Colors.amber, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _eventRow(DuelEvent event) {
    final isChallenger = event.actorId == 'challenger';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        SizedBox(width: 36,
            child: Text('[${event.timeSeconds.toStringAsFixed(1)}]',
                style: const TextStyle(color: _subtext, fontSize: 9))),
        Container(width: 6, height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isChallenger ? Colors.blueAccent : _red,
            )),
        Expanded(
          child: Text(
            '${event.detail}${event.value > 0 ? " (${event.value.toStringAsFixed(0)})" : ""}',
            style: TextStyle(color: _eventTypeColor(event.type), fontSize: 9),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Color _eventTypeColor(String type) {
    switch (type) {
      case 'damage':       return Colors.redAccent;
      case 'heal':         return _green;
      case 'ability_used': return Colors.amber;
      case 'death':        return Colors.purpleAccent;
      default:             return _text;
    }
  }

  Widget _historyRow(DuelResult result) {
    final dt = DateTime.fromMillisecondsSinceEpoch(result.timestamp);
    final dateStr = '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    final winnerIcon = result.winnerId == 'challenger'
        ? Icons.emoji_events
        : result.winnerId == 'enemy'
            ? Icons.close
            : Icons.balance;
    final winnerColor = result.winnerId == 'challenger'
        ? _green
        : result.winnerId == 'enemy'
            ? _red
            : Colors.amber;
    final chalName  = DuelDefinitions.allDisplayNames[result.challengerClass]  ?? result.challengerClass;
    final enemyName = DuelDefinitions.allDisplayNames[result.enemyFactionType] ?? result.enemyFactionType;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(4)),
      child: Row(children: [
        Text(dateStr, style: const TextStyle(color: _subtext, fontSize: 9)),
        const SizedBox(width: 6),
        Expanded(
          child: Text('$chalName vs $enemyName',
              style: const TextStyle(color: _text, fontSize: 10),
              overflow: TextOverflow.ellipsis),
        ),
        Icon(winnerIcon, color: winnerColor, size: 14),
        const SizedBox(width: 4),
        Text('${result.durationSeconds.toStringAsFixed(0)}s',
            style: const TextStyle(color: _subtext, fontSize: 9)),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(color: _subtext, fontSize: 10, fontWeight: FontWeight.bold));

  Widget _winnerBanner(DuelManager mgr) {
    if (mgr.phase != DuelPhase.completed) return const SizedBox.shrink();
    final winner = mgr.history.isNotEmpty ? mgr.history.first.winnerId : 'unknown';
    final label  = winner == 'challenger' ? 'Blue Side Wins!'
        : winner == 'enemy' ? 'Red Side Wins!' : 'Draw!';
    final color  = winner == 'challenger' ? _green
        : winner == 'enemy' ? _red : Colors.amber;
    return Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold));
  }

  /// Build a display label for a duel side: "Warrior" or "Warrior ×3".
  String _partyLabel(String? firstName, int partySize, {required bool isChallenger}) {
    final base = DuelDefinitions.allDisplayNames[firstName]
        ?? firstName
        ?? (isChallenger ? 'Challengers' : 'Enemies');
    return partySize > 1 ? '$base ×$partySize' : base;
  }
}
