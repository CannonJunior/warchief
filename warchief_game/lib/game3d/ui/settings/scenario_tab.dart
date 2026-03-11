import 'package:flutter/material.dart';

import '../../state/scenario_config.dart';
import '../../data/monsters/minion_definitions.dart';
import '../../../models/monster_ontology.dart';
import 'terrain_preset_selector.dart';

part 'scenario_tab_widgets.dart';

// Reason: top-level so the part-file extension can reference them directly.
const _accent  = Color(0xFF4cc9f0);
const _cardBg  = Color(0xFF252542);
const _dimText = Colors.white54;

/// Scenario tab — configure terrain, entities, and world at game start.
/// Changes persist via [ScenarioConfig] and apply on the next page reload.
class ScenarioTab extends StatefulWidget {
  const ScenarioTab({super.key});

  @override
  State<ScenarioTab> createState() => _ScenarioTabState();
}

class _ScenarioTabState extends State<ScenarioTab> {
  ScenarioConfig? get _cfg => globalScenarioConfig;

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

          // ── Terrain Type ──────────────────────────────────────────────
          _sectionHeader('Terrain', Icons.terrain),
          const SizedBox(height: 8),
          TerrainPresetSelector(
            selectedId: _cfg!.terrainPreset,
            onChanged: (id) => setState(() => _cfg!.setTerrainPreset(id)),
          ),
          const SizedBox(height: 16),

          // ── Warchief ──────────────────────────────────────────────────
          _sectionHeader('Warchief', Icons.person_pin),
          const SizedBox(height: 8),
          _infoRow('1 Warchief', 'Player-controlled hero. Always present.'),

          // ── Allies ────────────────────────────────────────────────────
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),

          // ── Abilities Codex ───────────────────────────────────────────
          _sectionHeader('Abilities Codex', Icons.menu_book),
          const SizedBox(height: 8),
          _abilitiesCodexRow(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
