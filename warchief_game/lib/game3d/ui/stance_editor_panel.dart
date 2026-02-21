import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import '../data/stances/stances.dart';

/// Tooltip text for every stance editor field.
const Map<String, String> _tooltips = {
  'name': 'Unique identifier for this stance. Cannot be changed.',
  'description': 'Flavor text shown in stance tooltips and cards.',
  'damageMultiplier': 'Multiplier to all outgoing damage (1.0 = baseline).',
  'damageTakenMultiplier': 'Multiplier to all incoming damage (1.0 = baseline).',
  'movementSpeedMultiplier': 'Multiplier to movement speed (1.0 = baseline).',
  'cooldownMultiplier': 'Multiplier to ability cooldowns (lower = faster).',
  'manaRegenMultiplier': 'Multiplier to all mana regeneration rates.',
  'manaCostMultiplier': 'Multiplier to ability mana costs.',
  'healingMultiplier': 'Multiplier to all healing done.',
  'maxHealthMultiplier': 'Multiplier to maximum health pool.',
  'castTimeMultiplier': 'Multiplier to cast/windup times (lower = faster).',
  'healthDrainPerSecond': 'Fraction of max HP drained per second (e.g. 0.02 = 2%).',
  'damageTakenToManaRatio': 'Fraction of damage taken converted to mana.',
  'usesHpForMana': 'When true, abilities cost HP instead of mana.',
  'hpForManaRatio': 'HP-to-mana conversion ratio when usesHpForMana is true.',
  'convertsManaRegenToHeal': 'When true, mana regen heals HP instead.',
  'rerollInterval': 'Seconds between random modifier re-rolls.',
  'hasRandomModifiers': 'When true, damage/damageTaken are randomized.',
  'rerollDamageMin': 'Minimum value for random damage multiplier roll.',
  'rerollDamageMax': 'Maximum value for random damage multiplier roll.',
  'rerollDamageTakenMin': 'Minimum value for random damage taken multiplier roll.',
  'rerollDamageTakenMax': 'Maximum value for random damage taken multiplier roll.',
  'switchCooldown': 'Seconds before you can switch to another stance.',
  'colorR': 'Red component of stance color (0.0–1.0).',
  'colorG': 'Green component of stance color (0.0–1.0).',
  'colorB': 'Blue component of stance color (0.0–1.0).',
};

/// Side-panel editor for modifying stance stats.
///
/// Displays all StanceData fields as editable inputs, grouped into sections.
/// Save persists changes as overrides via StanceOverrideManager.
/// Restore Defaults clears overrides and reverts to JSON config values.
/// Opened by double-clicking a stance card in the Abilities Codex.
class StanceEditorPanel extends StatefulWidget {
  final StanceData stance;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  const StanceEditorPanel({
    Key? key,
    required this.stance,
    required this.onClose,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<StanceEditorPanel> createState() => _StanceEditorPanelState();
}

class _StanceEditorPanelState extends State<StanceEditorPanel> {
  // Controllers for text fields
  late TextEditingController _descriptionCtrl;

  // Multipliers
  late TextEditingController _damageMultCtrl;
  late TextEditingController _damageTakenMultCtrl;
  late TextEditingController _moveSpeedMultCtrl;
  late TextEditingController _cooldownMultCtrl;
  late TextEditingController _manaRegenMultCtrl;
  late TextEditingController _manaCostMultCtrl;
  late TextEditingController _healingMultCtrl;
  late TextEditingController _maxHealthMultCtrl;
  late TextEditingController _castTimeMultCtrl;

  // Passives
  late TextEditingController _healthDrainCtrl;
  late TextEditingController _dmgToManaRatioCtrl;
  late TextEditingController _hpForManaRatioCtrl;
  late TextEditingController _rerollIntervalCtrl;
  late TextEditingController _rerollDmgMinCtrl;
  late TextEditingController _rerollDmgMaxCtrl;
  late TextEditingController _rerollDmgTakenMinCtrl;
  late TextEditingController _rerollDmgTakenMaxCtrl;

  // Booleans
  late bool _usesHpForMana;
  late bool _convertsManaRegenToHeal;
  late bool _hasRandomModifiers;

  // Switching
  late TextEditingController _switchCooldownCtrl;

  // Visual
  late TextEditingController _colorRCtrl;
  late TextEditingController _colorGCtrl;
  late TextEditingController _colorBCtrl;

  static const _bg = Color(0xFF1a1a2e);
  static const _sectionBg = Color(0xFF252542);
  static const _accent = Colors.cyan;
  static const double _panelWidth = 320.0;

  @override
  void initState() {
    super.initState();
    _populateFromStance(widget.stance);
  }

  @override
  void didUpdateWidget(StanceEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stance.id != widget.stance.id) {
      _populateFromStance(widget.stance);
    }
  }

  void _populateFromStance(StanceData s) {
    // Reason: Show effective values (with overrides) in the editor
    final effective = globalStanceOverrideManager?.getEffectiveStance(s) ?? s;

    _descriptionCtrl = TextEditingController(text: effective.description);

    _damageMultCtrl = TextEditingController(text: effective.damageMultiplier.toString());
    _damageTakenMultCtrl = TextEditingController(text: effective.damageTakenMultiplier.toString());
    _moveSpeedMultCtrl = TextEditingController(text: effective.movementSpeedMultiplier.toString());
    _cooldownMultCtrl = TextEditingController(text: effective.cooldownMultiplier.toString());
    _manaRegenMultCtrl = TextEditingController(text: effective.manaRegenMultiplier.toString());
    _manaCostMultCtrl = TextEditingController(text: effective.manaCostMultiplier.toString());
    _healingMultCtrl = TextEditingController(text: effective.healingMultiplier.toString());
    _maxHealthMultCtrl = TextEditingController(text: effective.maxHealthMultiplier.toString());
    _castTimeMultCtrl = TextEditingController(text: effective.castTimeMultiplier.toString());

    _healthDrainCtrl = TextEditingController(text: effective.healthDrainPerSecond.toString());
    _dmgToManaRatioCtrl = TextEditingController(text: effective.damageTakenToManaRatio.toString());
    _hpForManaRatioCtrl = TextEditingController(text: effective.hpForManaRatio.toString());
    _rerollIntervalCtrl = TextEditingController(text: effective.rerollInterval.toString());
    _rerollDmgMinCtrl = TextEditingController(text: effective.rerollDamageMin.toString());
    _rerollDmgMaxCtrl = TextEditingController(text: effective.rerollDamageMax.toString());
    _rerollDmgTakenMinCtrl = TextEditingController(text: effective.rerollDamageTakenMin.toString());
    _rerollDmgTakenMaxCtrl = TextEditingController(text: effective.rerollDamageTakenMax.toString());

    _usesHpForMana = effective.usesHpForMana;
    _convertsManaRegenToHeal = effective.convertsManaRegenToHeal;
    _hasRandomModifiers = effective.hasRandomModifiers;

    _switchCooldownCtrl = TextEditingController(text: effective.switchCooldown.toString());

    _colorRCtrl = TextEditingController(text: effective.color.x.toStringAsFixed(2));
    _colorGCtrl = TextEditingController(text: effective.color.y.toStringAsFixed(2));
    _colorBCtrl = TextEditingController(text: effective.color.z.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _damageMultCtrl.dispose();
    _damageTakenMultCtrl.dispose();
    _moveSpeedMultCtrl.dispose();
    _cooldownMultCtrl.dispose();
    _manaRegenMultCtrl.dispose();
    _manaCostMultCtrl.dispose();
    _healingMultCtrl.dispose();
    _maxHealthMultCtrl.dispose();
    _castTimeMultCtrl.dispose();
    _healthDrainCtrl.dispose();
    _dmgToManaRatioCtrl.dispose();
    _hpForManaRatioCtrl.dispose();
    _rerollIntervalCtrl.dispose();
    _rerollDmgMinCtrl.dispose();
    _rerollDmgMaxCtrl.dispose();
    _rerollDmgTakenMinCtrl.dispose();
    _rerollDmgTakenMaxCtrl.dispose();
    _switchCooldownCtrl.dispose();
    _colorRCtrl.dispose();
    _colorGCtrl.dispose();
    _colorBCtrl.dispose();
    super.dispose();
  }

  /// Build the override map from current controller values.
  /// Only includes fields that differ from the original stance.
  Map<String, dynamic> _buildOverrideMap() {
    final original = widget.stance;
    final overrides = <String, dynamic>{};

    void checkStr(String key, String val, String orig) {
      if (val != orig) overrides[key] = val;
    }
    void checkDbl(String key, String val, double orig) {
      final p = double.tryParse(val);
      if (p != null && p != orig) overrides[key] = p;
    }

    checkStr('description', _descriptionCtrl.text, original.description);

    checkDbl('damageMultiplier', _damageMultCtrl.text, original.damageMultiplier);
    checkDbl('damageTakenMultiplier', _damageTakenMultCtrl.text, original.damageTakenMultiplier);
    checkDbl('movementSpeedMultiplier', _moveSpeedMultCtrl.text, original.movementSpeedMultiplier);
    checkDbl('cooldownMultiplier', _cooldownMultCtrl.text, original.cooldownMultiplier);
    checkDbl('manaRegenMultiplier', _manaRegenMultCtrl.text, original.manaRegenMultiplier);
    checkDbl('manaCostMultiplier', _manaCostMultCtrl.text, original.manaCostMultiplier);
    checkDbl('healingMultiplier', _healingMultCtrl.text, original.healingMultiplier);
    checkDbl('maxHealthMultiplier', _maxHealthMultCtrl.text, original.maxHealthMultiplier);
    checkDbl('castTimeMultiplier', _castTimeMultCtrl.text, original.castTimeMultiplier);

    checkDbl('healthDrainPerSecond', _healthDrainCtrl.text, original.healthDrainPerSecond);
    checkDbl('damageTakenToManaRatio', _dmgToManaRatioCtrl.text, original.damageTakenToManaRatio);
    checkDbl('hpForManaRatio', _hpForManaRatioCtrl.text, original.hpForManaRatio);
    checkDbl('rerollInterval', _rerollIntervalCtrl.text, original.rerollInterval);
    checkDbl('rerollDamageMin', _rerollDmgMinCtrl.text, original.rerollDamageMin);
    checkDbl('rerollDamageMax', _rerollDmgMaxCtrl.text, original.rerollDamageMax);
    checkDbl('rerollDamageTakenMin', _rerollDmgTakenMinCtrl.text, original.rerollDamageTakenMin);
    checkDbl('rerollDamageTakenMax', _rerollDmgTakenMaxCtrl.text, original.rerollDamageTakenMax);

    if (_usesHpForMana != original.usesHpForMana) {
      overrides['usesHpForMana'] = _usesHpForMana;
    }
    if (_convertsManaRegenToHeal != original.convertsManaRegenToHeal) {
      overrides['convertsManaRegenToHeal'] = _convertsManaRegenToHeal;
    }
    if (_hasRandomModifiers != original.hasRandomModifiers) {
      overrides['hasRandomModifiers'] = _hasRandomModifiers;
    }

    checkDbl('switchCooldown', _switchCooldownCtrl.text, original.switchCooldown);

    final r = double.tryParse(_colorRCtrl.text) ?? original.color.x;
    final g = double.tryParse(_colorGCtrl.text) ?? original.color.y;
    final b = double.tryParse(_colorBCtrl.text) ?? original.color.z;
    if (r != original.color.x || g != original.color.y || b != original.color.z) {
      overrides['color'] = [r, g, b];
    }

    return overrides;
  }

  void _onSave() {
    final overrides = _buildOverrideMap();
    globalStanceOverrideManager?.setOverrides(widget.stance.id.name, overrides);
    print('[StanceEditor] Saved ${overrides.length} overrides for ${widget.stance.name}');
    widget.onSaved();
  }

  void _onRestore() {
    globalStanceOverrideManager?.clearOverrides(widget.stance.id.name);
    setState(() => _populateFromStance(widget.stance));
    print('[StanceEditor] Restored defaults for ${widget.stance.name}');
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final hasOverrides = globalStanceOverrideManager?.hasOverrides(widget.stance.id.name) ?? false;

    return Container(
      width: _panelWidth,
      height: 600,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(hasOverrides),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentitySection(),
                  _buildMultipliersSection(),
                  _buildPassivesSection(),
                  _buildSwitchingSection(),
                  _buildVisualSection(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ==================== HEADER / FOOTER ====================

  Widget _buildHeader(bool hasOverrides) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6), topRight: Radius.circular(6)),
      ),
      child: Row(
        children: [
          if (hasOverrides)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.edit, color: Colors.yellow, size: 14),
            ),
          Expanded(
            child: Text(widget.stance.name,
              style: const TextStyle(color: _accent, fontSize: 14,
                fontWeight: FontWeight.bold, letterSpacing: 1),
              overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 18),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            onPressed: widget.onClose),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildButton('Save', _accent, _onSave)),
          const SizedBox(width: 8),
          Expanded(child: _buildButton('Restore Defaults', Colors.orange, _onRestore)),
        ],
      ),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ==================== SECTIONS ====================

  Widget _buildSection(String title, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: _sectionBg, borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(title, style: TextStyle(color: color, fontSize: 10,
              fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return _buildSection('IDENTITY', Colors.white70, [
      _buildReadOnlyField('Name', widget.stance.name, 'name'),
      _buildTextField('Description', _descriptionCtrl, 'description', multiline: true),
    ]);
  }

  Widget _buildMultipliersSection() {
    return _buildSection('MULTIPLIERS', Colors.red.shade300, [
      _buildNumericRow('Damage', _damageMultCtrl, 'damageMultiplier'),
      _buildNumericRow('Damage Taken', _damageTakenMultCtrl, 'damageTakenMultiplier'),
      _buildNumericRow('Move Speed', _moveSpeedMultCtrl, 'movementSpeedMultiplier'),
      _buildNumericRow('Cooldowns', _cooldownMultCtrl, 'cooldownMultiplier'),
      _buildNumericRow('Mana Regen', _manaRegenMultCtrl, 'manaRegenMultiplier'),
      _buildNumericRow('Mana Costs', _manaCostMultCtrl, 'manaCostMultiplier'),
      _buildNumericRow('Healing', _healingMultCtrl, 'healingMultiplier'),
      _buildNumericRow('Max Health', _maxHealthMultCtrl, 'maxHealthMultiplier'),
      _buildNumericRow('Cast Time', _castTimeMultCtrl, 'castTimeMultiplier'),
    ]);
  }

  Widget _buildPassivesSection() {
    return _buildSection('PASSIVES', Colors.purple.shade300, [
      _buildNumericRow('HP Drain/s', _healthDrainCtrl, 'healthDrainPerSecond'),
      _buildNumericRow('Dmg→Mana Ratio', _dmgToManaRatioCtrl, 'damageTakenToManaRatio'),
      _buildNumericRow('HP→Mana Ratio', _hpForManaRatioCtrl, 'hpForManaRatio'),
      _buildSwitchRow('Uses HP for Mana', _usesHpForMana,
          (v) => setState(() => _usesHpForMana = v), 'usesHpForMana'),
      _buildSwitchRow('Regen → Heal', _convertsManaRegenToHeal,
          (v) => setState(() => _convertsManaRegenToHeal = v), 'convertsManaRegenToHeal'),
      _buildSwitchRow('Random Modifiers', _hasRandomModifiers,
          (v) => setState(() => _hasRandomModifiers = v), 'hasRandomModifiers'),
      _buildNumericRow('Reroll Interval', _rerollIntervalCtrl, 'rerollInterval'),
      _buildNumericRow('Reroll Dmg Min', _rerollDmgMinCtrl, 'rerollDamageMin'),
      _buildNumericRow('Reroll Dmg Max', _rerollDmgMaxCtrl, 'rerollDamageMax'),
      _buildNumericRow('Reroll DT Min', _rerollDmgTakenMinCtrl, 'rerollDamageTakenMin'),
      _buildNumericRow('Reroll DT Max', _rerollDmgTakenMaxCtrl, 'rerollDamageTakenMax'),
    ]);
  }

  Widget _buildSwitchingSection() {
    return _buildSection('SWITCHING', Colors.orange.shade300, [
      _buildNumericRow('Switch Cooldown', _switchCooldownCtrl, 'switchCooldown'),
    ]);
  }

  Widget _buildVisualSection() {
    return _buildSection('VISUAL', Colors.blue.shade300, [
      _buildColorRow('Color (RGB)', _colorRCtrl, _colorGCtrl, _colorBCtrl),
    ]);
  }

  // ==================== FIELD WIDGETS ====================

  Widget _withTooltip(String tooltipKey, Widget child) {
    final tip = _tooltips[tooltipKey];
    if (tip == null) return child;
    return Tooltip(
      message: tip,
      preferBelow: false,
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      decoration: BoxDecoration(
        color: const Color(0xDD1a1a2e),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.cyan.withOpacity(0.5)),
      ),
      waitDuration: const Duration(milliseconds: 400),
      child: child,
    );
  }

  Widget _buildReadOnlyField(String label, String value, String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          Expanded(child: Text(value,
            style: const TextStyle(color: Colors.white70, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      String tooltipKey, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(width: 80, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          Expanded(
            child: TextField(
              controller: ctrl, maxLines: multiline ? 2 : 1,
              style: _inputStyle, decoration: _inputDecoration),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericRow(String label, TextEditingController ctrl, String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          Expanded(
            child: TextField(
              controller: ctrl, keyboardType: TextInputType.number,
              style: _inputStyle, decoration: _inputDecoration),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, TextEditingController rCtrl,
      TextEditingController gCtrl, TextEditingController bCtrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: _labelStyle)),
          _colorField('R', rCtrl, 'colorR'),
          const SizedBox(width: 4),
          _colorField('G', gCtrl, 'colorG'),
          const SizedBox(width: 4),
          _colorField('B', bCtrl, 'colorB'),
        ],
      ),
    );
  }

  Widget _colorField(String hint, TextEditingController ctrl, String tooltipKey) {
    return Expanded(
      child: _withTooltip(tooltipKey,
        TextField(
          controller: ctrl, keyboardType: TextInputType.number,
          style: _inputStyle, decoration: _inputDecoration.copyWith(hintText: hint)),
      ),
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged,
      String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 150, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          SizedBox(
            height: 24,
            child: Switch(
              value: value, onChanged: onChanged,
              activeColor: _accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
        ],
      ),
    );
  }

  // ==================== STYLES ====================

  TextStyle get _labelStyle => const TextStyle(
    color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold);

  TextStyle get _inputStyle => const TextStyle(color: Colors.white, fontSize: 11);

  InputDecoration get _inputDecoration => const InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    filled: true, fillColor: Colors.black38,
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white24),
      borderRadius: BorderRadius.all(Radius.circular(3))),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white24),
      borderRadius: BorderRadius.all(Radius.circular(3))),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.cyan),
      borderRadius: BorderRadius.all(Radius.circular(3))),
  );
}
