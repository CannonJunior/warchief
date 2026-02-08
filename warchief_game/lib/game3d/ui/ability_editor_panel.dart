import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import '../data/abilities/ability_types.dart';
import '../state/ability_override_manager.dart';
import '../state/custom_options_manager.dart';
import '../state/custom_ability_manager.dart';

/// Tooltip text for every editor field
const Map<String, String> _tooltips = {
  'name': 'Unique identifier for this ability. Cannot be changed.',
  'description': 'Flavor text shown in the Abilities Codex and on mouseover.',
  'type': 'How the ability is delivered: melee, ranged, heal, buff, etc.',
  'category': 'The class or school this ability belongs to.',
  'damage': 'Base damage dealt per activation before modifiers.',
  'cooldown': 'Seconds before this ability can be used again.',
  'duration': 'How long the active effect lasts (seconds).',
  'range': 'Maximum targeting distance in game units (1 unit = 1 yard).',
  'healAmount': 'Health points restored to the target per cast.',
  'manaColor': 'Which mana pool this ability draws from.',
  'manaCost': 'Amount of mana consumed per cast.',
  'projSpeed': 'Travel speed of the projectile (units/second).',
  'projSize': 'Visual radius of the projectile mesh.',
  'impactSize': 'Visual scale of the impact hit effect.',
  'color': 'Primary visual RGB color of the ability (0.0–1.0 per channel).',
  'impactColor': 'RGB color of the impact/hit effect (0.0–1.0 per channel).',
  'effect': 'Status condition applied on hit.',
  'effectDesc': 'Detailed explanation of how this ability\'s effect works.',
  'statusDuration': 'How long the status effect persists (seconds).',
  'statusStrength': 'Intensity of the effect. Meaning varies by type.',
  'aoeRadius': 'Radius of the area of effect in game units.',
  'maxTargets': 'Maximum number of targets hit per activation.',
  'dotTicks': 'Number of damage/heal ticks over the effect duration.',
  'knockback': 'Pushback force applied to target on hit.',
  'castTime': 'Seconds of channeling before the ability fires.',
  'windupTime': 'Seconds of preparation before a melee strike connects.',
  'windupSpeed': 'Movement speed multiplier during windup (0.0–1.0).',
  'hitRadius': 'Radius for hit detection. Defaults to Range if unset.',
  'piercing': 'Whether the projectile passes through targets.',
  'stationary': 'Must stand still to cast. Movement cancels the cast.',
};

/// Side-panel editor for modifying ability stats
///
/// Displays all AbilityData fields as editable inputs, grouped into sections.
/// Save persists changes as overrides, Restore resets to original defaults.
/// Opened by double-clicking an ability card in the Abilities Codex.
///
/// When [isNewAbility] is true, operates in "create" mode:
/// - Name field is editable
/// - Save creates a new custom ability via CustomAbilityManager
/// - Restore clears all fields to defaults
class AbilityEditorPanel extends StatefulWidget {
  final AbilityData ability;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final bool isNewAbility;

  const AbilityEditorPanel({
    Key? key,
    required this.ability,
    required this.onClose,
    required this.onSaved,
    this.isNewAbility = false,
  }) : super(key: key);

  @override
  State<AbilityEditorPanel> createState() => _AbilityEditorPanelState();
}

class _AbilityEditorPanelState extends State<AbilityEditorPanel> {
  // Controllers for text fields
  late TextEditingController _nameCtrl;
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
  late TextEditingController _effectDescCtrl;
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

  // Dropdown values (stored as strings for custom value support)
  late String _selectedType;
  late String _selectedManaColor;
  late String _selectedStatusEffect;
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
    final effective = widget.isNewAbility ? a : (globalAbilityOverrideManager?.getEffectiveAbility(a) ?? a);

    _nameCtrl = TextEditingController(text: effective.name);
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

    // Effect description: check overrides first, then JSON defaults
    final overrides = globalAbilityOverrideManager?.getOverrides(a.name);
    final overrideDesc = overrides?['effectDescription'] as String?;
    final defaultDesc = globalCustomOptionsManager?.getEffectDescription(a.name) ?? '';
    _effectDescCtrl = TextEditingController(text: overrideDesc ?? defaultDesc);

    _selectedType = effective.type.name;
    _selectedManaColor = effective.manaColor.name;
    _selectedStatusEffect = effective.statusEffect.name;
    _selectedCategory = effective.category;
    _piercing = effective.piercing;
    _requiresStationary = effective.requiresStationary;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
    _effectDescCtrl.dispose();
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

  /// Build the override map from current controller values.
  /// Only includes fields that differ from the original ability.
  Map<String, dynamic> _buildOverrideMap() {
    final original = widget.ability;
    final overrides = <String, dynamic>{};

    void checkStr(String key, String val, String orig) {
      if (val != orig) overrides[key] = val;
    }
    void checkDbl(String key, String val, double orig) {
      final p = double.tryParse(val);
      if (p != null && p != orig) overrides[key] = p;
    }
    void checkInt(String key, String val, int orig) {
      final p = int.tryParse(val);
      if (p != null && p != orig) overrides[key] = p;
    }

    checkStr('description', _descriptionCtrl.text, original.description);

    // Type: try to map string back to enum index, or store as string for custom
    final typeEnum = AbilityType.values.where((t) => t.name == _selectedType);
    if (typeEnum.isNotEmpty && typeEnum.first != original.type) {
      overrides['type'] = typeEnum.first.index;
    }

    if (_selectedCategory != original.category) overrides['category'] = _selectedCategory;
    checkDbl('damage', _damageCtrl.text, original.damage);
    checkDbl('cooldown', _cooldownCtrl.text, original.cooldown);
    checkDbl('duration', _durationCtrl.text, original.duration);
    checkDbl('range', _rangeCtrl.text, original.range);
    checkDbl('healAmount', _healAmountCtrl.text, original.healAmount);

    final manaEnum = ManaColor.values.where((m) => m.name == _selectedManaColor);
    if (manaEnum.isNotEmpty && manaEnum.first != original.manaColor) {
      overrides['manaColor'] = manaEnum.first.index;
    }

    checkDbl('manaCost', _manaCostCtrl.text, original.manaCost);
    checkDbl('projectileSpeed', _projectileSpeedCtrl.text, original.projectileSpeed);
    checkDbl('projectileSize', _projectileSizeCtrl.text, original.projectileSize);
    checkDbl('impactSize', _impactSizeCtrl.text, original.impactSize);

    final r = double.tryParse(_colorRCtrl.text) ?? original.color.x;
    final g = double.tryParse(_colorGCtrl.text) ?? original.color.y;
    final b = double.tryParse(_colorBCtrl.text) ?? original.color.z;
    if (r != original.color.x || g != original.color.y || b != original.color.z) {
      overrides['color'] = [r, g, b];
    }

    final ir = double.tryParse(_impactColorRCtrl.text) ?? original.impactColor.x;
    final ig = double.tryParse(_impactColorGCtrl.text) ?? original.impactColor.y;
    final ib = double.tryParse(_impactColorBCtrl.text) ?? original.impactColor.z;
    if (ir != original.impactColor.x || ig != original.impactColor.y || ib != original.impactColor.z) {
      overrides['impactColor'] = [ir, ig, ib];
    }

    final fxEnum = StatusEffect.values.where((s) => s.name == _selectedStatusEffect);
    if (fxEnum.isNotEmpty && fxEnum.first != original.statusEffect) {
      overrides['statusEffect'] = fxEnum.first.index;
    }

    // Effect description override
    final defaultEffectDesc = globalCustomOptionsManager?.getEffectDescription(original.name) ?? '';
    if (_effectDescCtrl.text != defaultEffectDesc) {
      overrides['effectDescription'] = _effectDescCtrl.text;
    }

    checkDbl('statusDuration', _statusDurationCtrl.text, original.statusDuration);
    checkDbl('statusStrength', _statusStrengthCtrl.text, original.statusStrength);
    checkDbl('aoeRadius', _aoeRadiusCtrl.text, original.aoeRadius);
    checkInt('maxTargets', _maxTargetsCtrl.text, original.maxTargets);
    checkInt('dotTicks', _dotTicksCtrl.text, original.dotTicks);
    checkDbl('knockbackForce', _knockbackForceCtrl.text, original.knockbackForce);
    checkDbl('castTime', _castTimeCtrl.text, original.castTime);
    checkDbl('windupTime', _windupTimeCtrl.text, original.windupTime);
    checkDbl('windupMovementSpeed', _windupMovementSpeedCtrl.text, original.windupMovementSpeed);

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
    if (widget.isNewAbility) {
      _onSaveNewAbility();
    } else {
      final overrides = _buildOverrideMap();
      globalAbilityOverrideManager?.setOverrides(widget.ability.name, overrides);
      print('[Editor] Saved ${overrides.length} overrides for ${widget.ability.name}');
      widget.onSaved();
    }
  }

  void _onSaveNewAbility() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      print('[Editor] Cannot save: name is empty');
      return;
    }
    // Build a full AbilityData from current field values
    final ability = AbilityData(
      name: name,
      description: _descriptionCtrl.text,
      type: AbilityType.values.firstWhere((t) => t.name == _selectedType, orElse: () => AbilityType.melee),
      damage: double.tryParse(_damageCtrl.text) ?? 0.0,
      cooldown: double.tryParse(_cooldownCtrl.text) ?? 1.0,
      duration: double.tryParse(_durationCtrl.text) ?? 0.0,
      range: double.tryParse(_rangeCtrl.text) ?? 0.0,
      healAmount: double.tryParse(_healAmountCtrl.text) ?? 0.0,
      manaColor: ManaColor.values.firstWhere((m) => m.name == _selectedManaColor, orElse: () => ManaColor.none),
      manaCost: double.tryParse(_manaCostCtrl.text) ?? 0.0,
      projectileSpeed: double.tryParse(_projectileSpeedCtrl.text) ?? 0.0,
      projectileSize: double.tryParse(_projectileSizeCtrl.text) ?? 0.0,
      impactSize: double.tryParse(_impactSizeCtrl.text) ?? 0.5,
      color: Vector3(
        double.tryParse(_colorRCtrl.text) ?? 1.0,
        double.tryParse(_colorGCtrl.text) ?? 1.0,
        double.tryParse(_colorBCtrl.text) ?? 1.0,
      ),
      impactColor: Vector3(
        double.tryParse(_impactColorRCtrl.text) ?? 1.0,
        double.tryParse(_impactColorGCtrl.text) ?? 1.0,
        double.tryParse(_impactColorBCtrl.text) ?? 1.0,
      ),
      statusEffect: StatusEffect.values.firstWhere((s) => s.name == _selectedStatusEffect, orElse: () => StatusEffect.none),
      statusDuration: double.tryParse(_statusDurationCtrl.text) ?? 0.0,
      statusStrength: double.tryParse(_statusStrengthCtrl.text) ?? 0.0,
      aoeRadius: double.tryParse(_aoeRadiusCtrl.text) ?? 0.0,
      maxTargets: int.tryParse(_maxTargetsCtrl.text) ?? 1,
      dotTicks: int.tryParse(_dotTicksCtrl.text) ?? 0,
      knockbackForce: double.tryParse(_knockbackForceCtrl.text) ?? 0.0,
      castTime: double.tryParse(_castTimeCtrl.text) ?? 0.0,
      category: _selectedCategory,
      windupTime: double.tryParse(_windupTimeCtrl.text) ?? 0.0,
      windupMovementSpeed: double.tryParse(_windupMovementSpeedCtrl.text) ?? 1.0,
      hitRadius: double.tryParse(_hitRadiusCtrl.text),
      requiresStationary: _requiresStationary,
      piercing: _piercing,
    );
    globalCustomAbilityManager?.saveAbility(ability);
    // Save effect description if provided
    if (_effectDescCtrl.text.isNotEmpty) {
      globalAbilityOverrideManager?.setOverrides(name, {'effectDescription': _effectDescCtrl.text});
    }
    print('[Editor] Created new custom ability: $name');
    widget.onSaved();
  }

  void _onRestore() {
    if (widget.isNewAbility) {
      // Reset to blank defaults
      setState(() => _populateFromAbility(widget.ability));
      return;
    }
    globalAbilityOverrideManager?.clearOverrides(widget.ability.name);
    setState(() => _populateFromAbility(widget.ability));
    print('[Editor] Restored defaults for ${widget.ability.name}');
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final hasOverrides = widget.isNewAbility ? false : (globalAbilityOverrideManager?.hasOverrides(widget.ability.name) ?? false);

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
          _buildFooter(),
        ],
      ),
    );
  }

  // ==================== HEADER / FOOTER ====================

  Widget _buildHeader(bool hasOverrides) {
    final title = widget.isNewAbility ? 'NEW ABILITY' : widget.ability.name;
    final titleColor = widget.isNewAbility ? Colors.green : _accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6), topRight: Radius.circular(6)),
      ),
      child: Row(
        children: [
          if (widget.isNewAbility)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.add_circle, color: Colors.green, size: 14),
            )
          else if (hasOverrides)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.edit, color: Colors.yellow, size: 14),
            ),
          Expanded(
            child: Text(title,
              style: TextStyle(color: titleColor, fontSize: 14,
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
    final saveLabel = widget.isNewAbility ? 'Create' : 'Save';
    final saveColor = widget.isNewAbility ? Colors.green : _accent;
    final restoreLabel = widget.isNewAbility ? 'Clear' : 'Restore Defaults';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildButton(saveLabel, saveColor, _onSave)),
          const SizedBox(width: 8),
          Expanded(child: _buildButton(restoreLabel, Colors.orange, _onRestore)),
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
    final builtInCategories = [
      'general', 'warrior', 'mage', 'rogue', 'healer',
      'nature', 'necromancer', 'elemental', 'utility',
    ];
    final customCategories = globalCustomOptionsManager?.getCustomValues('category') ?? [];
    final allCategories = [...builtInCategories, ...customCategories];

    return _buildSection('IDENTITY', Colors.white70, [
      if (widget.isNewAbility)
        _buildTextField('Name', _nameCtrl, 'name')
      else
        _buildReadOnlyField('Name', widget.ability.name, 'name'),
      _buildTextField('Description', _descriptionCtrl, 'description', multiline: true),
      _buildDropdownWithAddNew(
        label: 'Type',
        tooltipKey: 'type',
        builtInValues: AbilityType.values.map((t) => t.name).toList(),
        customKey: 'type',
        selectedValue: _selectedType,
        onChanged: (v) => setState(() => _selectedType = v),
      ),
      _buildDropdownWithAddNew(
        label: 'Category',
        tooltipKey: 'category',
        builtInValues: allCategories,
        customKey: 'category',
        selectedValue: _selectedCategory,
        onChanged: (v) => setState(() => _selectedCategory = v),
      ),
    ]);
  }

  Widget _buildCombatSection() {
    return _buildSection('COMBAT', Colors.red.shade300, [
      _buildNumericRow('Damage', _damageCtrl, 'damage'),
      _buildNumericRow('Cooldown', _cooldownCtrl, 'cooldown'),
      _buildNumericRow('Duration', _durationCtrl, 'duration'),
      _buildNumericRow('Range', _rangeCtrl, 'range'),
      _buildNumericRow('Heal Amount', _healAmountCtrl, 'healAmount'),
    ]);
  }

  Widget _buildManaSection() {
    return _buildSection('MANA', Colors.blue.shade300, [
      _buildDropdownWithAddNew(
        label: 'Mana Color',
        tooltipKey: 'manaColor',
        builtInValues: ManaColor.values.map((m) => m.name).toList(),
        customKey: 'manaColor',
        selectedValue: _selectedManaColor,
        onChanged: (v) => setState(() => _selectedManaColor = v),
      ),
      _buildNumericRow('Mana Cost', _manaCostCtrl, 'manaCost'),
    ]);
  }

  Widget _buildProjectileSection() {
    return _buildSection('PROJECTILE', Colors.orange.shade300, [
      _buildNumericRow('Speed', _projectileSpeedCtrl, 'projSpeed'),
      _buildNumericRow('Size', _projectileSizeCtrl, 'projSize'),
    ]);
  }

  Widget _buildVisualSection() {
    return _buildSection('VISUAL', Colors.purple.shade300, [
      _buildNumericRow('Impact Size', _impactSizeCtrl, 'impactSize'),
      _buildColorRow('Color (RGB)', _colorRCtrl, _colorGCtrl, _colorBCtrl, 'color'),
      _buildColorRow('Impact Color', _impactColorRCtrl, _impactColorGCtrl, _impactColorBCtrl, 'impactColor'),
    ]);
  }

  Widget _buildStatusEffectSection() {
    return _buildSection('STATUS EFFECT', Colors.pink.shade300, [
      _buildDropdownWithAddNew(
        label: 'Effect',
        tooltipKey: 'effect',
        builtInValues: StatusEffect.values.map((s) => s.name).toList(),
        customKey: 'statusEffect',
        selectedValue: _selectedStatusEffect,
        onChanged: (v) => setState(() => _selectedStatusEffect = v),
      ),
      _buildTextField('Effect Desc', _effectDescCtrl, 'effectDesc', multiline: true),
      _buildNumericRow('Duration', _statusDurationCtrl, 'statusDuration'),
      _buildNumericRow('Strength', _statusStrengthCtrl, 'statusStrength'),
    ]);
  }

  Widget _buildAoeTargetingSection() {
    return _buildSection('AOE / TARGETING', Colors.yellow.shade300, [
      _buildNumericRow('AoE Radius', _aoeRadiusCtrl, 'aoeRadius'),
      _buildNumericRow('Max Targets', _maxTargetsCtrl, 'maxTargets'),
      _buildNumericRow('DoT Ticks', _dotTicksCtrl, 'dotTicks'),
    ]);
  }

  Widget _buildMechanicsSection() {
    return _buildSection('MECHANICS', Colors.green.shade300, [
      _buildNumericRow('Knockback Force', _knockbackForceCtrl, 'knockback'),
      _buildNumericRow('Cast Time', _castTimeCtrl, 'castTime'),
      _buildNumericRow('Windup Time', _windupTimeCtrl, 'windupTime'),
      _buildNumericRow('Windup Move Spd', _windupMovementSpeedCtrl, 'windupSpeed'),
      _buildNumericRow('Hit Radius', _hitRadiusCtrl, 'hitRadius'),
      _buildSwitchRow('Piercing', _piercing, (v) => setState(() => _piercing = v), 'piercing'),
      _buildSwitchRow('Req. Stationary', _requiresStationary,
          (v) => setState(() => _requiresStationary = v), 'stationary'),
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
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11))),
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
      TextEditingController gCtrl, TextEditingController bCtrl, String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
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
        controller: ctrl, keyboardType: TextInputType.number,
        style: _inputStyle, decoration: _inputDecoration.copyWith(hintText: hint)),
    );
  }

  /// Dropdown with "+ Add New" option at the bottom
  Widget _buildDropdownWithAddNew({
    required String label,
    required String tooltipKey,
    required List<String> builtInValues,
    required String customKey,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final customValues = globalCustomOptionsManager?.getCustomValues(customKey) ?? [];
    // Combine built-in + custom (avoid duplicates)
    final allValues = [...builtInValues];
    for (final cv in customValues) {
      if (!allValues.contains(cv)) allValues.add(cv);
    }
    // Ensure selected value is in list
    if (!allValues.contains(selectedValue)) allValues.add(selectedValue);

    const addNewSentinel = '__add_new__';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                dropdownColor: _bg,
                underline: const SizedBox.shrink(),
                iconSize: 16,
                iconEnabledColor: Colors.white54,
                style: _inputStyle,
                items: [
                  ...allValues.map((v) {
                    final isCustom = globalCustomOptionsManager?.isCustomValue(customKey, v) ?? false;
                    return DropdownMenuItem<String>(
                      value: v,
                      child: Text(v, style: _inputStyle.copyWith(
                        color: isCustom ? Colors.yellow : Colors.white)),
                    );
                  }),
                  // Separator + Add New
                  DropdownMenuItem<String>(
                    value: addNewSentinel,
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text('+ Add New', style: _inputStyle.copyWith(color: Colors.green)),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == addNewSentinel) {
                    _showAddNewDialog(customKey, label, onChanged);
                  } else if (v != null) {
                    onChanged(v);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog for adding a new dropdown value
  void _showAddNewDialog(String customKey, String label, ValueChanged<String> onChanged) {
    final controller = TextEditingController();
    final secondaryEffects = CustomOptionsManager.getSecondaryEffectsInfo(customKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _accent, width: 2)),
        title: Text('Add New $label', style: const TextStyle(color: _accent, fontSize: 14)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Enter new ${label.toLowerCase()} name...',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true, fillColor: Colors.black38,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Secondary Effects:',
                      style: TextStyle(color: Colors.orange, fontSize: 10,
                        fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(secondaryEffects,
                      style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              final value = controller.text.trim().toLowerCase().replaceAll(' ', '_');
              if (value.isNotEmpty) {
                globalCustomOptionsManager?.addCustomValue(customKey, value);
                onChanged(value);
                Navigator.of(ctx).pop();
                setState(() {}); // Refresh dropdowns
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.green))),
        ],
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
