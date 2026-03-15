part of 'duel_history_detail.dart';

// ── Stats, per-character breakdown, and ability breakdown ─────────────────────

extension _DuelHistoryStats on _DuelHistoryDetailState {
  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(double safeDur) {
    final cs = widget.result.challengerStats;
    final es = widget.result.enemyStats;
    return Row(children: [
      Expanded(child: _statBlock('Blue Side', _blue,
          dps: cs.totalDamageDealt / safeDur,
          hps: cs.totalHealingDone / safeDur,
          totalDmg:  cs.totalDamageDealt,
          totalHeal: cs.totalHealingDone,
          killingBlows: cs.killingBlows,
          deaths: cs.deaths,
          ccCasts: cs.ccAndUtilityCasts)),
      const SizedBox(width: 8),
      Expanded(child: _statBlock('Red Side', _red,
          dps: es.totalDamageDealt / safeDur,
          hps: es.totalHealingDone / safeDur,
          totalDmg:  es.totalDamageDealt,
          totalHeal: es.totalHealingDone,
          killingBlows: es.killingBlows,
          deaths: es.deaths,
          ccCasts: es.ccAndUtilityCasts)),
    ]);
  }

  Widget _statBlock(String label, Color color, {
    required double dps,
    required double hps,
    required double totalDmg,
    required double totalHeal,
    int killingBlows = 0,
    int deaths       = 0,
    int ccCasts      = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text('DPS: ${dps.toStringAsFixed(1)}',
            style: const TextStyle(color: _text, fontSize: 10)),
        Text('HPS: ${hps.toStringAsFixed(1)}',
            style: TextStyle(
                color: hps > 0 ? _green : _subtext, fontSize: 10)),
        const Divider(color: Colors.white12, height: 8),
        Row(children: [
          Text('KB: $killingBlows',
              style: TextStyle(color: killingBlows > 0 ? Colors.amber : _subtext, fontSize: 9)),
          const SizedBox(width: 10),
          Text('Deaths: $deaths',
              style: TextStyle(color: deaths > 0 ? _red : _subtext, fontSize: 9)),
          const SizedBox(width: 10),
          Text('CC: $ccCasts',
              style: TextStyle(color: ccCasts > 0 ? Colors.purpleAccent : _subtext, fontSize: 9)),
        ]),
        const Divider(color: Colors.white12, height: 8),
        Text('Total dmg: ${totalDmg.toStringAsFixed(0)}',
            style: const TextStyle(color: _subtext, fontSize: 9)),
        if (totalHeal > 0)
          Text('Total heal: ${totalHeal.toStringAsFixed(0)}',
              style: const TextStyle(color: _subtext, fontSize: 9)),
      ]),
    );
  }

  // ── Per-character breakdown ───────────────────────────────────────────────

  /// Per-class stat row: DPS / HPS / KB / CC, computed from per-ability maps.
  Widget _buildPerCharacterSection(double safeDur) {
    final result = widget.result;
    // Reason: check either side — enemy monsters may have per-ability data even
    // when the challenger had none (e.g. buff-only classes deal no direct damage).
    final hasData =
        result.challengerStats.perAbilityDamage.isNotEmpty ||
        result.challengerStats.perAbilityHealing.isNotEmpty ||
        result.enemyStats.perAbilityDamage.isNotEmpty       ||
        result.enemyStats.perAbilityHealing.isNotEmpty;
    if (!hasData) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Per Character',
          style: TextStyle(
              color: _subtext, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _charColumn(result.challengerClasses,
            result.challengerStats, safeDur, _blue)),
        const SizedBox(width: 8),
        Expanded(child: _charColumn(result.enemyTypes,
            result.enemyStats, safeDur, _red)),
      ]),
    ]);
  }

  Widget _charColumn(List<String> types, DuelCombatantStats stats,
      double safeDur, Color color) {
    final rows  = <Widget>[];
    final names = DuelDefinitions.allDisplayNames;
    // Pre-compute how many of each class appear so we can split stats evenly.
    final countByType = <String, int>{};
    for (final type in types) {
      countByType[type] = (countByType[type] ?? 0) + 1;
    }
    final indexByType = <String, int>{};
    for (final type in types) {
      indexByType[type] = (indexByType[type] ?? 0) + 1;
      final count    = countByType[type]!;
      final idx      = indexByType[type]!;
      final abilities = DuelDefinitions.getAbilities(type);
      double dmg = 0, heal = 0;
      int kills = 0, cc = 0;
      for (final a in abilities) {
        // Reason: stats are aggregated per side; divide evenly when the same
        // class appears multiple times so each row reflects one combatant's share.
        dmg  += (stats.perAbilityDamage[a.name]  ?? 0) / count;
        heal += (stats.perAbilityHealing[a.name] ?? 0) / count;
        kills += ((stats.killingBlowsByAbility[a.name] ?? 0) / count).round();
        final uses = stats.abilitiesUsed[a.name] ?? 0;
        if (uses > 0 && _isAbilityUtil(a)) cc += (uses / count).round();
      }
      // Disambiguate with #N suffix only when two or more of the same class share a side.
      final baseName = names[type] ?? type;
      final label    = count > 1 ? '$baseName #$idx' : baseName;
      rows.add(_charRow(label, color, dmg / safeDur, heal / safeDur, kills, cc));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  Widget _charRow(String label, Color color,
      double dps, double hps, int kills, int cc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(3)),
      child: Row(children: [
        Container(width: 3, height: 18, margin: const EdgeInsets.only(right: 5), color: color),
        Expanded(child: Text(label,
            style: const TextStyle(color: _text, fontSize: 9),
            overflow: TextOverflow.ellipsis)),
        _miniStat('DPS', dps.toStringAsFixed(1), _text),
        _miniStat('HPS', hps > 0 ? hps.toStringAsFixed(1) : '—', _green),
        _miniStat('KB',  '$kills', kills > 0 ? Colors.amber : _subtext),
        _miniStat('CC',  '$cc',    cc    > 0 ? Colors.purpleAccent : _subtext),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color valueColor) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(label, style: const TextStyle(color: _subtext, fontSize: 7)),
      Text(value, style: TextStyle(color: valueColor, fontSize: 9,
          fontWeight: FontWeight.bold)),
    ]),
  );

  /// True when an ability has a CC/debuff/utility effect worth counting.
  bool _isAbilityUtil(AbilityData a) =>
      a.statusEffect == StatusEffect.stun      ||
      a.statusEffect == StatusEffect.root      ||
      a.statusEffect == StatusEffect.slow      ||
      a.statusEffect == StatusEffect.blind     ||
      a.statusEffect == StatusEffect.fear      ||
      a.statusEffect == StatusEffect.silence   ||
      a.statusEffect == StatusEffect.freeze    ||
      a.statusEffect == StatusEffect.interrupt ||
      a.type == AbilityType.debuff             ||
      a.type == AbilityType.utility            ||
      a.type == AbilityType.buff;

  // ── Ability breakdown ─────────────────────────────────────────────────────

  Widget _buildAbilityBreakdown() {
    final result     = widget.result;
    final chalAbils  = _sortedAbilities(result.challengerStats.abilitiesUsed);
    final enemyAbils = _sortedAbilities(result.enemyStats.abilitiesUsed);
    if (chalAbils.isEmpty && enemyAbils.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Ability Breakdown',
          style: TextStyle(
              color: _subtext, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      // Reason: side headers prevent confusion when one column is sparse or empty;
      // particularly important when the enemy side is a monster/minion archetype.
      Row(children: [
        Expanded(child: Text('Blue Side',
            style: TextStyle(color: _blue.withValues(alpha: 0.8), fontSize: 9,
                fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Expanded(child: Text('Red Side',
            style: TextStyle(color: _red.withValues(alpha: 0.8), fontSize: 9,
                fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _abilityColumn(chalAbils, _blue)),
        const SizedBox(width: 8),
        Expanded(child: _abilityColumn(enemyAbils, _red)),
      ]),
    ]);
  }

  Widget _abilityColumn(List<MapEntry<String, int>> entries, Color color) {
    if (entries.isEmpty) {
      return const Text('—',
          style: TextStyle(color: _subtext, fontSize: 9));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Container(
                      width: 3,
                      height: 10,
                      margin: const EdgeInsets.only(right: 5),
                      color: color),
                  Expanded(
                    child: Text(e.key,
                        style: const TextStyle(color: _text, fontSize: 9),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('×${e.value}',
                      style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ]),
              ))
          .toList(),
    );
  }

  List<MapEntry<String, int>> _sortedAbilities(Map<String, int> map) =>
      (map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .take(8)
          .toList();

  // ── Label helpers ─────────────────────────────────────────────────────────

  String _partyLabel(List<String> types) {
    if (types.isEmpty) return 'Unknown';
    final first = DuelDefinitions.allDisplayNames[types.first] ?? types.first;
    return types.length > 1 ? '$first ×${types.length}' : first;
  }
}
