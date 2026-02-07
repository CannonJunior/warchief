import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import '../data/abilities/ability_types.dart';
import '../state/ability_override_manager.dart';

/// Side-panel editor for modifying ability stats
///
/// Displays all AbilityData fields as editable inputs, grouped into sections.
/// Save persists changes as overrides, Restore resets to original defaults.
/// Opened by double-clicking an ability card in the Abilities Codex.
class AbilityEditorPanel extends StatefulWidget {
  final AbilityData ability;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  const AbilityEditorPanel({
    Key? key,
    required this.ability,
    required this.onClose,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<AbilityEditorPanel> createState() => _AbilityEditorPanelState();
}

class _AbilityEditorPanelState extends State<AbilityEditorPanel> {
  // Controllers for text fields
  late TextEditingController _descriptionCtrl;
  late TextEditingController _damageCtrl;
  late TextEditingController _cooldownCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _rangeCtrl;
  late TextEditingController _healAmountCtrl;
  late TextEditingController _manaCostCtrl;
  late TextEditingController _projectileSpeedCtrl;
  late TextEditingController _projectileSizeCtrl;
  late TextEditingController _impactSizeCtrl;
  late TextEditingController _colorRCtrl;
  late TextEditingController _colorGCtrl;
  late TextEditingController _colorBCtrl;
  late TextEditingController _impactColorRCtrl;
  late TextEditingController _impactColorGCtrl;
  late TextEditingController _impactColorBCtrl;
  late TextEditingController _statusDurationCtrl;
  late TextEditingController _statusStrengthCtrl;
  late TextEditingController _aoeRadiusCtrl;
  late TextEditingController _maxTargetsCtrl;
  late TextEditingController _dotTicksCtrl;
  late TextEditingController _knockbackForceCtrl;
  late TextEditingController _castTimeCtrl;
  late TextEditingController _windupTimeCtrl;
  late TextEditingController _windupMovementSpeedCtrl;
  late TextEditingController _hitRadiusCtrl;

  // Dropdown values
  late AbilityType _selectedType;
  late ManaColor _selectedManaColor;
  late StatusEffect _selectedStatusEffect;
  late String _selectedCategory;
  late bool _piercing;
  late bool _requiresStationary;

  static const _bg = Color(0xFF1a1a2e);
  static const _sectionBg = Color(0xFF252542);
  static const _accent = Colors.cyan;
  static const double _panelWidth = 320.0;

  @override
  void initState() {
    super.initState();
    _populateFromAbility(widget.ability);
  }

  @override
  void didUpdateWidget(AbilityEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ability.name != widget.ability.name) {
      _populateFromAbility(widget.ability);
    }
  }

  void _populateFromAbility(AbilityData a) {
    // Get effective ability (with overrides applied) for initial values
    final effective = globalAbilityOverrideManager?.getEffectiveAbility(a) ?? a;

    _descriptionCtrl = TextEditingController(text: effective.description);
    _damageCtrl = TextEditingController(text: effective.damage.toString());
    _cooldownCtrl = TextEditingController(text: effective.cooldown.toString());
    _durationCtrl = TextEditingController(text: effective.duration.toString());
    _rangeCtrl = TextEditingController(text: effective.range.toString());
    _healAmountCtrl = TextEditingController(text: effective.healAmount.toString());
    _manaCostCtrl = TextEditingController(text: effective.manaCost.toString());
    _projectileSpeedCtrl = TextEditingController(text: effective.projectileSpeed.toString());
    _projectileSizeCtrl = TextEditingController(text: effective.projectileSize.toString());
    _impactSizeCtrl = TextEditingController(text: effective.impactSize.toString());
    _colorRCtrl = TextEditingController(text: effective.color.x.toStringAsFixed(2));
    _colorGCtrl = TextEditingController(text: effective.color.y.toStringAsFixed(2));
    _colorBCtrl = TextEditingController(text: effective.color.z.toStringAsFixed(2));
    _impactColorRCtrl = TextEditingController(text: effective.impactColor.x.toStringAsFixed(2));
    _impactColorGCtrl = TextEditingController(text: effective.impactColor.y.toStringAsFixed(2));
    _impactColorBCtrl = TextEditingController(text: effective.impactColor.z.toStringAsFixed(2));
    _statusDurationCtrl = TextEditingController(text: effective.statusDuration.toString());
    _statusStrengthCtrl = TextEditingController(text: effective.statusStrength.toString());
    _aoeRadiusCtrl = TextEditingController(text: effective.aoeRadius.toString());
    _maxTargetsCtrl = TextEditingController(text: effective.maxTargets.toString());
    _dotTicksCtrl = TextEditingController(text: effective.dotTicks.toString());
    _knockbackForceCtrl = TextEditingController(text: effective.knockbackForce.toString());
    _castTimeCtrl = TextEditingController(text: effective.castTime.toString());
    _windupTimeCtrl = TextEditingController(text: effective.windupTime.toString());
    _windupMovementSpeedCtrl = TextEditingController(text: effective.windupMovementSpeed.toString());
    _hitRadiusCtrl = TextEditingController(text: (effective.hitRadius ?? 0.0).toString());

    _selectedType = effective.type;
    _selectedManaColor = effective.manaColor;
    _selectedStatusEffect = effective.statusEffect;
    _selectedCategory = effective.category;
    _piercing = effective.piercing;
    _requiresStationary = effective.requiresStationary;
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _damageCtrl.dispose();
    _cooldownCtrl.dispose();
    _durationCtrl.dispose();
    _rangeCtrl.dispose();
    _healAmountCtrl.dispose();
    _manaCostCtrl.dispose();
    _projectileSpeedCtrl.dispose();
    _projectileSizeCtrl.dispose();
    _impactSizeCtrl.dispose();
    _colorRCtrl.dispose();
    _colorGCtrl.dispose();
    _colorBCtrl.dispose();
    _impactColorRCtrl.dispose();
    _impactColorGCtrl.dispose();
    _impactColorBCtrl.dispose();
    _statusDurationCtrl.dispose();
    _statusStrengthCtrl.dispose();
    _aoeRadiusCtrl.dispose();
    _maxTargetsCtrl.dispose();
    _dotTicksCtrl.dispose();
    _knockbackForceCtrl.dispose();
    _castTimeCtrl.dispose();
    _windupTimeCtrl.dispose();
    _windupMovementSpeedCtrl.dispose();
    _hitRadiusCtrl.dispose();
    super.dispose();
  }

  /// Build the override map from current controller values
  /// Only includes fields that differ from the original ability
  Map<String, dynamic> _buildOverrideMap() {
    final original = widget.ability;
    final overrides = <String, dynamic>{};

    void _checkString(String key, String ctrlValue, String originalValue) {
      if (ctrlValue != originalValue) overrides[key] = ctrlValue;
    }

    void _checkDouble(String key, String ctrlValue, double originalValue) {
      final parsed = double.tryParse(ctrlValue);
      if (parsed != null && parsed != originalValue) overrides[key] = parsed;
    }

    void _checkInt(String key, String ctrlValue, int originalValue) {
      final parsed = int.tryParse(ctrlValue);
      if (parsed != null && parsed != originalValue) overrides[key] = parsed;
    }

    _checkString('description', _descriptionCtrl.text, original.description);
    if (_selectedType != original.type) overrides['type'] = _selectedType.index;
    if (_selectedCategory != original.category) overrides['category'] = _selectedCategory;
    _checkDouble('damage', _damageCtrl.text, original.damage);
    _checkDouble('cooldown', _cooldownCtrl.text, original.cooldown);
    _checkDouble('duration', _durationCtrl.text, original.duration);
    _checkDouble('range', _rangeCtrl.text, original.range);
    _checkDouble('healAmount', _healAmountCtrl.text, original.healAmount);
    if (_selectedManaColor != original.manaColor) overrides['manaColor'] = _selectedManaColor.index;
    _checkDouble('manaCost', _manaCostCtrl.text, original.manaCost);
    _checkDouble('projectileSpeed', _projectileSpeedCtrl.text, original.projectileSpeed);
    _checkDouble('projectileSize', _projectileSizeCtrl.text, original.projectileSize);
    _checkDouble('impactSize', _impactSizeCtrl.text, original.impactSize);

    // Color (Vector3)
    final r = double.tryParse(_colorRCtrl.text) ?? original.color.x;
    final g = double.tryParse(_colorGCtrl.text) ?? original.color.y;
    final b = double.tryParse(_colorBCtrl.text) ?? original.color.z;
    if (r != original.color.x || g != original.color.y || b != original.color.z) {
      overrides['color'] = [r, g, b];
    }

    // Impact color (Vector3)
    final ir = double.tryParse(_impactColorRCtrl.text) ?? original.impactColor.x;
    final ig = double.tryParse(_impactColorGCtrl.text) ?? original.impactColor.y;
    final ib = double.tryParse(_impactColorBCtrl.text) ?? original.impactColor.z;
    if (ir != original.impactColor.x || ig != original.impactColor.y || ib != original.impactColor.z) {
      overrides['impactColor'] = [ir, ig, ib];
    }

    if (_selectedStatusEffect != original.statusEffect) {
      overrides['statusEffect'] = _selectedStatusEffect.index;
    }
    _checkDouble('statusDuration', _statusDurationCtrl.text, original.statusDuration);
    _checkDouble('statusStrength', _statusStrengthCtrl.text, original.statusStrength);
    _checkDouble('aoeRadius', _aoeRadiusCtrl.text, original.aoeRadius);
    _checkInt('maxTargets', _maxTargetsCtrl.text, original.maxTargets);
    _checkInt('dotTicks', _dotTicksCtrl.text, original.dotTicks);
    _checkDouble('knockbackForce', _knockbackForceCtrl.text, original.knockbackForce);
    _checkDouble('castTime', _castTimeCtrl.text, original.castTime);
    _checkDouble('windupTime', _windupTimeCtrl.text, original.windupTime);
    _checkDouble('windupMovementSpeed', _windupMovementSpeedCtrl.text, original.windupMovementSpeed);

    final hitRadiusParsed = double.tryParse(_hitRadiusCtrl.text);
    final originalHitRadius = original.hitRadius ?? 0.0;
    if (hitRadiusParsed != null && hitRadiusParsed != originalHitRadius) {
      overrides['hitRadius'] = hitRadiusParsed;
    }

    if (_piercing != original.piercing) overrides['piercing'] = _piercing;
    if (_requiresStationary != original.requiresStationary) {
      overrides['requiresStationary'] = _requiresStationary;
    }

    return overrides;
  }

  void _onSave() {
    final overrides = _buildOverrideMap();
    globalAbilityOverrideManager?.setOverrides(widget.ability.name, overrides);
    print('[Editor] Saved ${overrides.length} overrides for ${widget.ability.name}');
    widget.onSaved();
  }

  void _onRestore() {
    globalAbilityOverrideManager?.clearOverrides(widget.ability.name);
    setState(() {
      _populateFromAbility(widget.ability);
    });
    print('[Editor] Restored defaults for ${widget.ability.name}');
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final hasOverrides = globalAbilityOverrideManager?.hasOverrides(widget.ability.name) ?? false;

    return Container(
      width: _panelWidth,
      height: 600,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(hasOverrides),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentitySection(),
                  _buildCombatSection(),
                  _buildManaSection(),
                  _buildProjectileSection(),
                  _buildVisualSection(),
                  _buildStatusEffectSection(),
                  _buildAoeTargetingSection(),
                  _buildMechanicsSection(),
                ],
              ),
            ),
          ),
          // Footer buttons
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool hasOverrides) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Row(
        children: [
          if (hasOverrides)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.edit, color: Colors.yellow, size: 14),
            ),
          Expanded(
            child: Text(
              widget.ability.name,
              style: const TextStyle(
                color: _accent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: widget.onClose,
          ),
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
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildButton('Save', _accent, _onSave),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton('Restore Defaults', Colors.orange, _onRestore),
          ),
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
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==================== SECTIONS ====================

  Widget _buildSection(String title, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _sectionBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
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
    final categories = [
      'general', 'warrior', 'mage', 'rogue', 'healer',
      'nature', 'necromancer', 'elemental', 'utility',
    ];

    return _buildSection('IDENTITY', Colors.white70, [
      _buildReadOnlyField('Name', widget.ability.name),
      _buildTextField('Description', _descriptionCtrl, multiline: true),
      _buildDropdown<AbilityType>(
        'Type',
        AbilityType.values,
        _selectedType,
        (v) => setState(() => _selectedType = v!),
        (v) => v.toString().split('.').last,
      ),
      _buildDropdown<String>(
        'Category',
        categories,
        _selectedCategory,
        (v) => setState(() => _selectedCategory = v!),
        (v) => v,
      ),
    ]);
  }

  Widget _buildCombatSection() {
    return _buildSection('COMBAT', Colors.red.shade300, [
      _buildNumericRow('Damage', _damageCtrl),
      _buildNumericRow('Cooldown', _cooldownCtrl),
      _buildNumericRow('Duration', _durationCtrl),
      _buildNumericRow('Range', _rangeCtrl),
      _buildNumericRow('Heal Amount', _healAmountCtrl),
    ]);
  }

  Widget _buildManaSection() {
    return _buildSection('MANA', Colors.blue.shade300, [
      _buildDropdown<ManaColor>(
        'Mana Color',
        ManaColor.values,
        _selectedManaColor,
        (v) => setState(() => _selectedManaColor = v!),
        (v) => v.toString().split('.').last,
      ),
      _buildNumericRow('Mana Cost', _manaCostCtrl),
    ]);
  }

  Widget _buildProjectileSection() {
    return _buildSection('PROJECTILE', Colors.orange.shade300, [
      _buildNumericRow('Speed', _projectileSpeedCtrl),
      _buildNumericRow('Size', _projectileSizeCtrl),
    ]);
  }

  Widget _buildVisualSection() {
    return _buildSection('VISUAL', Colors.purple.shade300, [
      _buildNumericRow('Impact Size', _impactSizeCtrl),
      _buildColorRow('Color (RGB)', _colorRCtrl, _colorGCtrl, _colorBCtrl),
      _buildColorRow('Impact Color', _impactColorRCtrl, _impactColorGCtrl, _impactColorBCtrl),
    ]);
  }

  Widget _buildStatusEffectSection() {
    return _buildSection('STATUS EFFECT', Colors.pink.shade300, [
      _buildDropdown<StatusEffect>(
        'Effect',
        StatusEffect.values,
        _selectedStatusEffect,
        (v) => setState(() => _selectedStatusEffect = v!),
        (v) => v.toString().split('.').last,
      ),
      _buildNumericRow('Duration', _statusDurationCtrl),
      _buildNumericRow('Strength', _statusStrengthCtrl),
    ]);
  }

  Widget _buildAoeTargetingSection() {
    return _buildSection('AOE / TARGETING', Colors.yellow.shade300, [
      _buildNumericRow('AoE Radius', _aoeRadiusCtrl),
      _buildNumericRow('Max Targets', _maxTargetsCtrl),
      _buildNumericRow('DoT Ticks', _dotTicksCtrl),
    ]);
  }

  Widget _buildMechanicsSection() {
    return _buildSection('MECHANICS', Colors.green.shade300, [
      _buildNumericRow('Knockback Force', _knockbackForceCtrl),
      _buildNumericRow('Cast Time', _castTimeCtrl),
      _buildNumericRow('Windup Time', _windupTimeCtrl),
      _buildNumericRow('Windup Move Speed', _windupMovementSpeedCtrl),
      _buildNumericRow('Hit Radius', _hitRadiusCtrl),
      _buildSwitchRow('Piercing', _piercing, (v) => setState(() => _piercing = v)),
      _buildSwitchRow('Requires Stationary', _requiresStationary,
          (v) => setState(() => _requiresStationary = v)),
    ]);
  }

  // ==================== FIELD WIDGETS ====================

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: _labelStyle),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: _labelStyle),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: multiline ? 2 : 1,
              style: _inputStyle,
              decoration: _inputDecoration,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericRow(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: _labelStyle),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: _inputStyle,
              decoration: _inputDecoration,
            ),
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
          SizedBox(
            width: 110,
            child: Text(label, style: _labelStyle),
          ),
          _colorField('R', rCtrl),
          const SizedBox(width: 4),
          _colorField('G', gCtrl),
          const SizedBox(width: 4),
          _colorField('B', bCtrl),
        ],
      ),
    );
  }

  Widget _colorField(String hint, TextEditingController ctrl) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: _inputStyle,
        decoration: _inputDecoration.copyWith(hintText: hint),
      ),
    );
  }

  Widget _buildDropdown<T>(String label, List<T> items, T value,
      ValueChanged<T?> onChanged, String Function(T) nameOf) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: _labelStyle),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: _bg,
                underline: const SizedBox.shrink(),
                iconSize: 16,
                iconEnabledColor: Colors.white54,
                style: _inputStyle,
                items: items
                    .map((e) => DropdownMenuItem<T>(
                          value: e,
                          child: Text(nameOf(e), style: _inputStyle),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: _labelStyle),
          ),
          SizedBox(
            height: 24,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: _accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STYLES ====================

  TextStyle get _labelStyle => const TextStyle(
        color: Colors.white54,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      );

  TextStyle get _inputStyle => const TextStyle(
        color: Colors.white,
        fontSize: 11,
      );

  InputDecoration get _inputDecoration => const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        filled: true,
        fillColor: Colors.black38,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyan),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      );
}
