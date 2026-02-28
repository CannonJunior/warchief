part of 'duel_panel.dart';

// ── Aggregated stats for one unique matchup pulled from history ───────────────

class _MatchupRecord {
  final List<String> chalClasses;
  final List<String> enemyTypes;
  final List<int>    chalGearTiers;
  final List<int>    enemyGearTiers;
  int wins = 0, total = 0;
  double totalDur = 0;

  _MatchupRecord(this.chalClasses, this.enemyTypes, this.chalGearTiers, this.enemyGearTiers);

  void add(DuelResult r) {
    total++;
    if (r.winnerId == 'challenger') wins++;
    totalDur += r.durationSeconds;
  }

  int    get winPct => total > 0 ? (wins * 100 / total).round() : 0;
  double get avgDur => total > 0 ? totalDur / total : 0;
}

// ==================== RECENTS + PAST PERFORMANCE ====================

extension _DuelPanelRecents on _DuelPanelState {
  // ── Past performance for the currently-selected matchup ───────────────────

  Widget _buildPastPerformance() {
    final chalReady  = _chalClasses.sublist(0, _chalPartySize).any((c) => c != null);
    final enemyReady = _enemyTypes.sublist(0, _enemyPartySize).any((e) => e != null);
    if (!chalReady || !enemyReady) return const SizedBox.shrink();

    final key     = _matchupKey(
        _chalClasses.sublist(0, _chalPartySize).whereType<String>().toList(),
        _enemyTypes.sublist(0, _enemyPartySize).whereType<String>().toList());
    final matched = widget.manager.history
        .where((r) => _matchupKey(r.challengerClasses, r.enemyTypes) == key)
        .toList();
    if (matched.isEmpty) return const SizedBox.shrink();

    final wins   = matched.where((r) => r.winnerId == 'challenger').length;
    final total  = matched.length;
    final avgDur = matched.fold(0.0, (s, r) => s + r.durationSeconds) / total;
    final pct    = (wins * 100 / total).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0d1520),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(children: [
          const Icon(Icons.bar_chart, color: Color(0xFF9e9e9e), size: 12),
          const SizedBox(width: 4),
          Text('$total past duel${total == 1 ? '' : 's'} · ',
              style: const TextStyle(color: Color(0xFF9e9e9e), fontSize: 9)),
          Text('$pct% blue wins',
              style: TextStyle(
                  color: pct >= 50 ? Colors.blueAccent : const Color(0xFFef5350),
                  fontSize: 9, fontWeight: FontWeight.bold)),
          Text(' · avg ${avgDur.toStringAsFixed(0)}s',
              style: const TextStyle(color: Color(0xFF9e9e9e), fontSize: 9)),
        ]),
      ),
    );
  }

  // ── Recent configurations (collapsible) ───────────────────────────────────

  Widget _buildRecentsSection() {
    final recents = _recentConfigs();
    if (recents.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GestureDetector(
        onTap: () => setState(() => _showRecents = !_showRecents),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(children: [
            const Icon(Icons.history, color: Color(0xFF9e9e9e), size: 12),
            const SizedBox(width: 4),
            Text('Recent Configurations (${recents.length})',
                style: const TextStyle(color: Color(0xFF9e9e9e), fontSize: 10)),
            const Spacer(),
            Icon(_showRecents ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF9e9e9e), size: 14),
          ]),
        ),
      ),
      if (_showRecents) ...recents.map(_recentConfigCard),
    ]);
  }

  List<_MatchupRecord> _recentConfigs() {
    final map = <String, _MatchupRecord>{};
    for (final r in widget.manager.history) {
      final k = _matchupKey(r.challengerClasses, r.enemyTypes);
      (map[k] ??= _MatchupRecord(
              r.challengerClasses, r.enemyTypes,
              r.challengerGearTiers, r.enemyGearTiers))
          .add(r);
    }
    return map.values.take(8).toList();
  }

  Widget _recentConfigCard(_MatchupRecord rec) {
    final chalName  = _partyLabel(
        rec.chalClasses.isNotEmpty ? rec.chalClasses.first : null,
        rec.chalClasses.length, isChallenger: true);
    final enemyName = _partyLabel(
        rec.enemyTypes.isNotEmpty ? rec.enemyTypes.first : null,
        rec.enemyTypes.length, isChallenger: false);

    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1520),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$chalName  vs  $enemyName',
                style: const TextStyle(color: Color(0xFFe0e0e0), fontSize: 10),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${rec.total} duel${rec.total == 1 ? '' : 's'} · '
              '${rec.winPct}% blue wins · avg ${rec.avgDur.toStringAsFixed(0)}s',
              style: const TextStyle(color: Color(0xFF9e9e9e), fontSize: 9),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _loadConfig(rec),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF533483),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('Load',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  void _loadConfig(_MatchupRecord rec) {
    setState(() {
      _showRecents   = false;
      _chalPartySize = rec.chalClasses.length;
      while (_chalClasses.length   < _chalPartySize) _chalClasses.add(null);
      while (_chalGearTiers.length < _chalPartySize) _chalGearTiers.add(0);
      for (int i = 0; i < _chalPartySize; i++) {
        _chalClasses[i]  = rec.chalClasses[i];
        if (i < rec.chalGearTiers.length) _chalGearTiers[i] = rec.chalGearTiers[i];
      }
      _enemyPartySize = rec.enemyTypes.length;
      while (_enemyTypes.length    < _enemyPartySize) _enemyTypes.add(null);
      while (_enemyGearTiers.length < _enemyPartySize) _enemyGearTiers.add(0);
      for (int i = 0; i < _enemyPartySize; i++) {
        _enemyTypes[i]   = rec.enemyTypes[i];
        if (i < rec.enemyGearTiers.length) _enemyGearTiers[i] = rec.enemyGearTiers[i];
      }
    });
  }

  // ── Matchup key (preserves party slot order) ───────────────────────────────

  String _matchupKey(List<String> chalClasses, List<String> enemyTypes) =>
      '${chalClasses.join(',')}|${enemyTypes.join(',')}';
}
