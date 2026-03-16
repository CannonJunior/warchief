// ignore_for_file: invalid_use_of_protected_member
part of 'duel_panel.dart';

// ── Metrics tab ───────────────────────────────────────────────────────────────

extension _DuelPanelMetrics on _DuelPanelState {
  // ── Root ──────────────────────────────────────────────────────────────────

  Widget _buildMetricsTab() {
    final history = widget.manager.history;
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No duel history yet.\nRun some duels to see metrics.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _subtext, fontSize: 12),
          ),
        ),
      );
    }

    final charMetrics  = DuelMetrics.computeCharacterMetrics(history);
    final abilMetrics  = DuelMetrics.computeAbilityMetrics(history);
    final filtered     = _metricsAbilityFilter == null
        ? abilMetrics
        : abilMetrics
            .where((a) => a.characterType == _metricsAbilityFilter)
            .toList();

    // All unique character types that have any ability data
    final filterTypes = ({null, ...abilMetrics.map((a) => a.characterType)})
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _metricsSection('CHARACTER RATINGS', charMetrics.isEmpty
              ? const [_EmptyRow()]
              : charMetrics.map(_characterRow).toList()),
          const SizedBox(height: 12),
          Row(children: [
            const Expanded(
              child: Text('ABILITY RATINGS',
                  style: TextStyle(
                      color: _subtext,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8)),
            ),
            _filterDropdown(filterTypes),
          ]),
          const SizedBox(height: 4),
          filtered.isEmpty
              ? _emptyTableRow('No ability data for selected filter')
              : Column(children: filtered.map(_abilityRow).toList()),
          const SizedBox(height: 16),
          _buildClearHistoryButton(),
        ],
      ),
    );
  }

  Widget _buildClearHistoryButton() {
    return GestureDetector(
      onTap: () async {
        await widget.manager.clearHistory();
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF3a0d0d),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF7a2020), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Color(0xFFef5350), size: 13),
            SizedBox(width: 5),
            Text('Clear All History',
                style: TextStyle(
                    color: Color(0xFFef5350),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ── Character table ───────────────────────────────────────────────────────

  Widget _metricsSection(String title, List<Widget> rows) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title,
          style: const TextStyle(
              color: _subtext,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8)),
      const SizedBox(height: 4),
      // Column header
      _tableHeaderRow(const ['Class', 'Duels', 'Win%', 'DPS', 'HPS', 'KB', 'Score']),
      const SizedBox(height: 2),
      ...rows,
    ]);
  }

  Widget _tableHeaderRow(List<String> labels) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1520),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(children: [
        Expanded(flex: 5, child: _hdr(labels[0])),
        Expanded(flex: 2, child: _hdr(labels[1])),
        Expanded(flex: 2, child: _hdr(labels[2])),
        Expanded(flex: 3, child: _hdr(labels[3])),
        Expanded(flex: 3, child: _hdr(labels[4])),
        if (labels.length > 6) Expanded(flex: 2, child: _hdr(labels[5])),
        Expanded(flex: 5, child: _hdr(labels[labels.length > 6 ? 6 : 5])),
      ]),
    );
  }

  Widget _hdr(String label) => Text(label,
      style: const TextStyle(
          color: _subtext, fontSize: 9, fontWeight: FontWeight.bold));

  Widget _characterRow(CharacterMetric m) {
    final score   = m.overallScore;
    final barFrac = (score / 100.0).clamp(0.0, 1.0);
    final barColor = score >= 70
        ? _green
        : score >= 45
            ? Colors.amber
            : _red;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(children: [
        Expanded(
          flex: 5,
          child: Text(m.displayName,
              style: const TextStyle(
                  color: _text, fontSize: 10, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ),
        Expanded(flex: 2,
            child: _cell('${m.duels}')),
        Expanded(flex: 2,
            child: _cell('${(m.winRate * 100).round()}%')),
        Expanded(flex: 3,
            child: _cell(m.avgDps.toStringAsFixed(1))),
        Expanded(flex: 3,
            child: _cell(m.avgHps > 0
                ? m.avgHps.toStringAsFixed(1)
                : '—',
                color: m.avgHps > 0 ? _green : _subtext)),
        // KB column: average killing blows per duel
        Expanded(flex: 2,
            child: _cell(m.avgKbPerDuel > 0
                ? m.avgKbPerDuel.toStringAsFixed(1)
                : '—',
                color: m.avgKbPerDuel > 0 ? Colors.amber : _subtext)),
        // Score bar + number
        Expanded(
          flex: 5,
          child: Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: barFrac,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(barColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 28,
              child: Text(score.toStringAsFixed(0),
                  style: TextStyle(
                      color: barColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Ability table ─────────────────────────────────────────────────────────

  Widget _filterDropdown(List<String?> types) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButton<String?>(
        value: _metricsAbilityFilter,
        isDense: true,
        underline: const SizedBox.shrink(),
        dropdownColor: _surface,
        style: const TextStyle(color: _text, fontSize: 10),
        items: types.map((t) => DropdownMenuItem(
          value: t,
          child: Text(t == null
              ? 'All classes'
              : (DuelDefinitions.allDisplayNames[t] ?? t),
              style: const TextStyle(fontSize: 10)),
        )).toList(),
        onChanged: (v) => setState(() => _metricsAbilityFilter = v),
      ),
    );
  }

  Widget _abilityRow(AbilityMetric m) {
    final rating    = m.rating;
    final isHeal    = m.isHeal;
    final accentCol = isHeal ? _green : Colors.blueAccent;
    final output    = isHeal ? m.avgHealPerUse : m.avgDmgPerUse;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(children: [
        // Color accent bar
        Container(
            width: 3, height: 18,
            margin: const EdgeInsets.only(right: 6),
            color: accentCol),
        // Ability name
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.abilityName,
                  style: const TextStyle(
                      color: _text, fontSize: 10, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              Text(m.characterDisplayName,
                  style: const TextStyle(color: _subtext, fontSize: 8)),
            ],
          ),
        ),
        Expanded(flex: 2,
            child: _cell('${m.uses}×')),
        Expanded(
          flex: 3,
          child: _cell(
            output > 0 ? output.toStringAsFixed(1) : '—',
            color: isHeal ? _green : _text,
          ),
        ),
        // Rating column: output / cooldown, highlighted
        Expanded(
          flex: 3,
          child: Text(
            rating > 0 ? rating.toStringAsFixed(2) : '—',
            style: TextStyle(
              color: rating > 10
                  ? _green
                  : rating > 5
                      ? Colors.amber
                      : _subtext,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _cell(String text, {Color color = _text}) =>
      Text(text, style: TextStyle(color: color, fontSize: 10));

  Widget _emptyTableRow(String message) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: Text(message,
            style: const TextStyle(color: _subtext, fontSize: 10)),
      );
}

// ── Placeholder to satisfy the List<Widget> type when charMetrics is empty ───

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
