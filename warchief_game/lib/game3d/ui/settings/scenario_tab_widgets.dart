// ignore_for_file: invalid_use_of_protected_member
part of 'scenario_tab.dart';

extension _ScenarioTabWidgets on _ScenarioTabState {

  Widget _sectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 16),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: _accent, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
              height: 1, color: _accent.withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  Widget _reloadNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.refresh, color: Colors.amber, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Changes are saved immediately and apply on the next page reload.',
              style: TextStyle(color: Colors.amber, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INFO ROW ====================

  Widget _infoRow(String label, String hint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: _accent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text(hint,
                    style: const TextStyle(color: _dimText, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TOGGLE ROW ====================

  Widget _toggleRow({
    required String label,
    required String hint,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(hint,
                    style: const TextStyle(color: _dimText, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _accent,
            activeTrackColor: _accent.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  // ==================== COUNTER ROW ====================

  Widget _counterRow({
    required String label,
    required String hint,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    int min = 0,
    int max = 99,
    int step = 1,
  }) {
    final canDec = value - step >= min;
    final canInc = value + step <= max;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(hint,
                    style: const TextStyle(color: _dimText, fontSize: 11)),
              ],
            ),
          ),
          _stepButton(Icons.remove, canDec ? onDecrement : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$value',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
          _stepButton(Icons.add, canInc ? onIncrement : null),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback? onTap) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active
              ? _accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active
                  ? _accent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon,
            size: 14,
            color: active ? _accent : Colors.white.withValues(alpha: 0.25)),
      ),
    );
  }

  // ==================== MINION ROWS ====================

  List<Widget> _buildMinionRows() {
    final cfg = _cfg;
    if (cfg == null) return [];
    return cfg.minionSpawns.map((spawn) {
      final def = MinionDefinitions.getById(spawn.definitionId);
      if (def == null) return const SizedBox.shrink();
      return _minionRow(spawn, def);
    }).toList();
  }

  Widget _minionRow(MinionSpawnConfig spawn, MonsterDefinition def) {
    final archLabel = def.archetype.name[0].toUpperCase() +
        def.archetype.name.substring(1);
    final canDec = spawn.count > 0;
    final canInc = spawn.count < 99;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                (def.accentColor.x * 255).round(),
                (def.accentColor.y * 255).round(),
                (def.accentColor.z * 255).round(),
                1.0,
              ),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text('$archLabel · MP ${def.monsterPower}',
                    style: const TextStyle(color: _dimText, fontSize: 11)),
              ],
            ),
          ),
          _stepButton(
            Icons.remove,
            canDec
                ? () => setState(() =>
                    _cfg!.setMinionCount(spawn.definitionId, spawn.count - 1))
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('${spawn.count}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
          _stepButton(
            Icons.add,
            canInc
                ? () => setState(() =>
                    _cfg!.setMinionCount(spawn.definitionId, spawn.count + 1))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _minionSummaryRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$_totalMinions minions  ·  Monster Power: $_totalMP',
            style: const TextStyle(
                color: _accent, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ==================== ABILITIES CODEX ROW ====================

  Widget _abilitiesCodexRow() {
    final mode = _cfg?.abilitiesCodexMode ?? 'expanded';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Codex Mode',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          const Text('Controls which ability categories appear in the Abilities Codex panel.',
              style: TextStyle(color: _dimText, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            children: [
              _codexModeChip('expanded', 'Expanded', 'All classes', mode),
              const SizedBox(width: 8),
              _codexModeChip('development', 'Development', 'Warrior, Rogue, Boss', mode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _codexModeChip(String value, String label, String sub, String current) {
    final active = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _cfg!.setAbilitiesCodexMode(value)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: active ? _accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? _accent : Colors.white24, width: active ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: active ? _accent : Colors.white70,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              Text(sub, style: const TextStyle(color: _dimText, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== WORLD SIZE ROW ====================

  Widget _worldSizeRow() {
    final cfg = _cfg!;
    final size = cfg.leyLineWorldSize;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('World Size',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: 2),
                    Text('Radius of the ley line grid in world units.',
                        style: TextStyle(color: _dimText, fontSize: 11)),
                  ],
                ),
              ),
              Text('${size.round()}',
                  style: const TextStyle(
                      color: _accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _accent,
              inactiveTrackColor: _accent.withValues(alpha: 0.2),
              thumbColor: _accent,
              overlayColor: _accent.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: size.clamp(100.0, 2000.0),
              min: 100,
              max: 2000,
              divisions: 38,
              onChanged: (v) => setState(() => cfg.setLeyLineWorldSize(v)),
            ),
          ),
        ],
      ),
    );
  }
}
