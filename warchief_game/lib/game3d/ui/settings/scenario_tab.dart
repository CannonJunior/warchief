import 'package:flutter/material.dart';

import '../../state/scenario_config.dart';
import '../../data/monsters/minion_definitions.dart';
import '../../../models/monster_ontology.dart';

/// Scenario tab in the Settings panel.
///
/// Lets the user configure which entities and world features are present at
/// game start.  All changes persist to SharedPreferences via [ScenarioConfig]
/// and take effect on the next page reload.
class ScenarioTab extends StatefulWidget {
  const ScenarioTab({Key? key}) : super(key: key);

  @override
  State<ScenarioTab> createState() => _ScenarioTabState();
}

class _ScenarioTabState extends State<ScenarioTab> {
  static const _accent = Color(0xFF4cc9f0);
  static const _cardBg = Color(0xFF252542);
  static const _dimText = Colors.white54;

  ScenarioConfig? get _cfg => globalScenarioConfig;

  // ==================== COMPUTED STATS ====================

  int get _totalMinions =>
      _cfg?.minionSpawns.fold(0, (sum, s) => (sum ?? 0) + s.count) ?? 0;

  int get _totalMP {
    final spawns = _cfg?.minionSpawns ?? [];
    int total = 0;
    for (final s in spawns) {
      final def = MinionDefinitions.getById(s.definitionId);
      if (def != null) total += def.monsterPower * s.count;
    }
    return total;
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    if (_cfg == null) {
      return const Center(
        child: Text('Scenario config not loaded',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scenario',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _reloadNote(),
          const SizedBox(height: 16),

          // ── Warchief ──────────────────────────────────────────────────
          _sectionHeader('Warchief', Icons.person_pin),
          const SizedBox(height: 8),
          _infoRow('1 Warchief', 'Player-controlled hero. Always present.'),
          const SizedBox(height: 16),

          // ── Allies ────────────────────────────────────────────────────
          _sectionHeader('Allies', Icons.group),
          const SizedBox(height: 8),
          _counterRow(
            label: 'Starting Allies',
            hint: 'Friendly heroes that spawn alongside the Warchief.',
            value: _cfg!.initialAllyCount,
            min: 0,
            max: 20,
            onDecrement: () => setState(() => _cfg!.setInitialAllyCount(_cfg!.initialAllyCount - 1)),
            onIncrement: () => setState(() => _cfg!.setInitialAllyCount(_cfg!.initialAllyCount + 1)),
          ),
          const SizedBox(height: 16),

          // ── Boss Monster ──────────────────────────────────────────────
          _sectionHeader('Boss Monster', Icons.whatshot),
          const SizedBox(height: 8),
          _toggleRow(
            label: 'Spawn Boss Monster',
            hint: 'A powerful enemy that guards the field.',
            value: _cfg!.spawnBossMonster,
            onChanged: (v) => setState(() => _cfg!.setSpawnBossMonster(v)),
          ),
          const SizedBox(height: 16),

          // ── Minions ───────────────────────────────────────────────────
          _sectionHeader('Minions', Icons.pest_control),
          const SizedBox(height: 8),
          _toggleRow(
            label: 'Spawn Minions',
            hint: 'Enable or disable the entire minion army.',
            value: _cfg!.spawnMinions,
            onChanged: (v) => setState(() => _cfg!.setSpawnMinions(v)),
          ),
          const SizedBox(height: 8),
          ..._buildMinionRows(),
          _minionSummaryRow(),
          const SizedBox(height: 16),

          // ── Buildings ─────────────────────────────────────────────────
          _sectionHeader('Buildings', Icons.home_work),
          const SizedBox(height: 8),
          _toggleRow(
            label: "Spawn Warchief's Home",
            hint: 'Longhouse placed near player start. Provides health & mana regen aura.',
            value: _cfg!.spawnWarchiefHome,
            onChanged: (v) => setState(() => _cfg!.setSpawnWarchiefHome(v)),
          ),
          const SizedBox(height: 16),

          // ── World ─────────────────────────────────────────────────────
          _sectionHeader('World', Icons.public),
          const SizedBox(height: 8),
          _counterRow(
            label: 'Ley Line Seed',
            hint: 'Controls the random layout of ley lines and power nodes.',
            value: _cfg!.leyLineSeed,
            min: 1,
            max: 9999,
            step: 1,
            onDecrement: () => setState(() => _cfg!.setLeyLineSeed(_cfg!.leyLineSeed - 1)),
            onIncrement: () => setState(() => _cfg!.setLeyLineSeed(_cfg!.leyLineSeed + 1)),
          ),
          _counterRow(
            label: 'Ley Line Site Count',
            hint: 'Number of power nodes distributed across the world.',
            value: _cfg!.leyLineSiteCount,
            min: 1,
            max: 200,
            step: 5,
            onDecrement: () => setState(() => _cfg!.setLeyLineSiteCount(_cfg!.leyLineSiteCount - 5)),
            onIncrement: () => setState(() => _cfg!.setLeyLineSiteCount(_cfg!.leyLineSiteCount + 5)),
          ),
          _worldSizeRow(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== SECTION HEADER ====================

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

  // ==================== RELOAD NOTE ====================

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
            activeColor: _accent,
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
          // Type color dot
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
