import 'package:flutter/material.dart';
import '../data/abilities/abilities.dart';
import '../data/abilities/ability_types.dart';
import '../state/combo_config.dart';

// ==================== CONSTANTS ====================

const Color _kAccent   = Color(0xFF4cc9f0);
const Color _kGold     = Color(0xFFFFD700);
const Color _kGreen    = Color(0xFF4CAF50);
const Color _kRed      = Color(0xFFEF5350);
const Color _kSubtle   = Color(0xFF252542);

/// Resolves an ally abilityIndex to the matching AbilityRegistry category.
String allyIndexToCategory(int abilityIndex) {
  switch (abilityIndex) {
    case 0: return 'warrior';
    case 1: return 'mage';
    default: return 'ally';
  }
}

/// Side-panel body showing all combo sequences available for a character.
///
/// Displays three sections:
/// 1. Melee Combo — any N same-category hits triggers a reward.
/// 2. GCD Primer Chains — casting ability A primes follow-up abilities.
/// 3. Chain Combo — a specific ability opens a 7-hit chain window.
class CombosPanel extends StatefulWidget {
  /// AbilityRegistry category string, e.g. 'player', 'warrior', 'mage'.
  final String category;
  final ComboConfig? comboConfig;

  const CombosPanel({
    super.key,
    required this.category,
    required this.comboConfig,
  });

  @override
  State<CombosPanel> createState() => _CombosPanelState();
}

class _CombosPanelState extends State<CombosPanel> {
  bool _meleeExpanded  = true;
  bool _primerExpanded = true;
  bool _chainExpanded  = true;

  List<AbilityData> get _abilities =>
      AbilityRegistry.getByCategory(widget.category);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMeleeSection(),
          _buildPrimerSection(),
          _buildChainSection(),
        ],
      ),
    );
  }

  // ==================== MELEE COMBO ====================

  Widget _buildMeleeSection() {
    final cfg = widget.comboConfig?.getCategoryConfig(widget.category);
    return _buildSection(
      label: 'MELEE COMBO',
      icon: Icons.sports_martial_arts,
      expanded: _meleeExpanded,
      onToggle: () => setState(() => _meleeExpanded = !_meleeExpanded),
      child: cfg == null
          ? _emptyNote('No melee combo defined for this class.')
          : _buildMeleeContent(cfg),
    );
  }

  Widget _buildMeleeContent(Map<String, dynamic> cfg) {
    final threshold = (cfg['threshold'] as num?)?.toInt() ?? 3;
    final effect    = cfg['effect'] as String? ?? '?';

    final desc = _effectDescription(cfg, effect);
    final window = widget.comboConfig?.comboWindow ?? 4.0;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sequence pills
          Row(
            children: [
              for (int i = 0; i < threshold; i++) ...[
                _hitPill(i + 1),
                if (i < threshold - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.arrow_forward, size: 11,
                        color: Colors.white38),
                  ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.bolt, size: 13, color: _kGold),
              ),
              _effectPill(effect),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text('Window: ${window.toStringAsFixed(1)}s of inactivity resets.',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  // ==================== GCD PRIMER CHAINS ====================

  Widget _buildPrimerSection() {
    final primers = _abilities.where((a) => a.comboPrimes.isNotEmpty).toList();
    return _buildSection(
      label: 'GCD PRIMER CHAINS',
      icon: Icons.link,
      expanded: _primerExpanded,
      onToggle: () => setState(() => _primerExpanded = !_primerExpanded),
      child: primers.isEmpty
          ? _emptyNote('No GCD primer chains for this class.')
          : Column(
              children: primers
                  .map((a) => _buildPrimerRow(a))
                  .toList(),
            ),
    );
  }

  Widget _buildPrimerRow(AbilityData ability) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _kSubtle,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Trigger ability
          Flexible(
            child: Text(
              ability.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 11, color: _kAccent),
          ),
          // Primed abilities
          Flexible(
            flex: 2,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: ability.comboPrimes
                  .map((name) => _primedPill(name))
                  .toList(),
            ),
          ),
          const SizedBox(width: 6),
          // GCD badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.15),
              border: Border.all(color: _kGold.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '−0.5s',
              style: TextStyle(color: _kGold, fontSize: 9,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CHAIN COMBO ====================

  Widget _buildChainSection() {
    final chainPrimers =
        _abilities.where((a) => a.enablesComboChain).toList();
    return _buildSection(
      label: 'CHAIN COMBO',
      icon: Icons.electric_bolt,
      expanded: _chainExpanded,
      onToggle: () => setState(() => _chainExpanded = !_chainExpanded),
      child: chainPrimers.isEmpty
          ? _emptyNote('No chain combo defined for this class.')
          : Column(
              children: chainPrimers
                  .map((a) => _buildChainRow(a))
                  .toList(),
            ),
    );
  }

  Widget _buildChainRow(AbilityData ability) {
    final window = widget.comboConfig?.chainWindow ?? 7.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _kSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.electric_bolt, size: 13, color: _kGold),
              const SizedBox(width: 4),
              Text(
                'Cast  ${ability.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.arrow_forward, size: 11, color: Colors.white38),
              const SizedBox(width: 4),
              const Text(
                '7 consecutive hits → Chain reward',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Window: ${window.toStringAsFixed(1)}s to land all 7 hits.',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _buildSection({
    required String label,
    required IconData icon,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header (tap to collapse)
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                    color: _kAccent.withValues(alpha: 0.3), width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 13, color: _kAccent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: _kAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ),
        if (expanded) child,
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _emptyNote(String text) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      );

  Widget _hitPill(int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.15),
          border: Border.all(color: _kAccent.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Hit $n',
          style: const TextStyle(
              color: _kAccent, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );

  Widget _effectPill(String effect) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: _kGold.withValues(alpha: 0.2),
          border: Border.all(color: _kGold.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          effect.toUpperCase(),
          style: const TextStyle(
              color: _kGold, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );

  Widget _primedPill(String name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _kGreen.withValues(alpha: 0.15),
          border: Border.all(color: _kGreen.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          name,
          style: const TextStyle(
              color: _kGreen, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );

  String _effectDescription(Map<String, dynamic> cfg, String effect) {
    switch (effect) {
      case 'knockback':
        final force = (cfg['knockbackForce'] as num?)?.toDouble() ?? 0;
        return 'Knockback: ${force.toStringAsFixed(1)} force';
      case 'heal':
        final amount = (cfg['amount'] as num?)?.toDouble() ?? 0;
        return 'Heal: $amount HP';
      case 'slow':
        final dur = (cfg['duration'] as num?)?.toDouble() ?? 0;
        final str = (cfg['strength'] as num?)?.toDouble() ?? 0;
        return 'Slow: ${(str * 100).round()}% for ${dur.toStringAsFixed(1)}s';
      case 'haste':
        final dur = (cfg['duration'] as num?)?.toDouble() ?? 0;
        final str = (cfg['strength'] as num?)?.toDouble() ?? 0;
        return 'Haste: +${(str * 100).round()}% speed for ${dur.toStringAsFixed(1)}s';
      case 'strength':
        final dur = (cfg['duration'] as num?)?.toDouble() ?? 0;
        final str = (cfg['strength'] as num?)?.toDouble() ?? 0;
        return 'Strength: +${(str * 100).round()}% dmg for ${dur.toStringAsFixed(1)}s';
      case 'redMana':
        final amount = (cfg['amount'] as num?)?.toDouble() ?? 0;
        return 'Restore ${amount.toStringAsFixed(0)} red mana';
      case 'aoe':
        final dmg = (cfg['damage'] as num?)?.toDouble() ?? 0;
        final rad = (cfg['radius'] as num?)?.toDouble() ?? 0;
        return 'AoE: ${dmg.toStringAsFixed(0)} dmg, ${rad.toStringAsFixed(1)} radius';
      case 'regen':
        final heal = (cfg['healPerTick'] as num?)?.toDouble() ?? 0;
        final dur  = (cfg['duration'] as num?)?.toDouble() ?? 0;
        return 'Regen: ${heal.toStringAsFixed(1)}/tick for ${dur.toStringAsFixed(1)}s';
      default:
        return effect;
    }
  }
}
