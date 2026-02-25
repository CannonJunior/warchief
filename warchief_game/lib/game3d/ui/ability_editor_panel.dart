import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import '../data/abilities/ability_types.dart';
import '../data/abilities/ability_balance.dart';
import '../state/ability_override_manager.dart';
import '../state/custom_options_manager.dart';
import '../state/custom_ability_manager.dart';

part 'ability_editor_panel_sections.dart';
part 'ability_editor_panel_fields.dart';

// ==================== SHARED CONSTANTS ====================
// Reason: top-level so extension methods in part files can access them directly
// (static class members require qualified access from extension methods)
const _editorBg = Color(0xFF1a1a2e);
const _editorSectionBg = Color(0xFF252542);
const _editorAccent = Colors.cyan;
const double _editorPanelWidth = 320.0;

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
  'channelEffect': 'Visual effect displayed while channeling this ability.',
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
  late TextEditingController _secondaryManaCostCtrl;
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
  late String _selectedSecondaryManaColor;
  late String _selectedStatusEffect;
  late String _selectedCategory;
  late bool _piercing;
  late bool _requiresStationary;
  late String _selectedChannelEffect;

  // Reason: aliases to top-level constants for backward-compat within this file
  static const _bg = _editorBg;
  static const _accent = _editorAccent;
  static const double _panelWidth = _editorPanelWidth;

  @override
  void initState() {
    super.initState();
    _populateFromAbility(widget.ability);
  }

  @override
  void didUpdateWidget(AbilityEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ability.name != widget.ability.name ||
        oldWidget.isNewAbility != widget.isNewAbility) {
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
    _secondaryManaCostCtrl = TextEditingController(text: effective.secondaryManaCost.toString());
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
    _selectedSecondaryManaColor = effective.secondaryManaColor.name;
    _selectedStatusEffect = effective.statusEffect.name;
    _selectedCategory = effective.category;
    _piercing = effective.piercing;
    _requiresStationary = effective.requiresStationary;
    _selectedChannelEffect = effective.channelEffect.name;

    // Attach listeners to balance-relevant fields for live preview updates
    for (final ctrl in _balanceRelevantControllers) {
      ctrl.addListener(_onBalanceFieldChanged);
    }
  }

  /// Controllers whose values affect the balance score.
  List<TextEditingController> get _balanceRelevantControllers => [
    _damageCtrl, _cooldownCtrl, _rangeCtrl, _healAmountCtrl,
    _manaCostCtrl, _secondaryManaCostCtrl, _statusDurationCtrl,
    _aoeRadiusCtrl, _maxTargetsCtrl, _dotTicksCtrl,
    _knockbackForceCtrl, _castTimeCtrl, _windupTimeCtrl,
    _windupMovementSpeedCtrl,
  ];

  /// Triggers a rebuild so the balance preview badge updates.
  void _onBalanceFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final ctrl in _balanceRelevantControllers) {
      ctrl.removeListener(_onBalanceFieldChanged);
    }
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _damageCtrl.dispose();
    _cooldownCtrl.dispose();
    _durationCtrl.dispose();
    _rangeCtrl.dispose();
    _healAmountCtrl.dispose();
    _manaCostCtrl.dispose();
    _secondaryManaCostCtrl.dispose();
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

    final secManaEnum = ManaColor.values.where((m) => m.name == _selectedSecondaryManaColor);
    if (secManaEnum.isNotEmpty && secManaEnum.first != original.secondaryManaColor) {
      overrides['secondaryManaColor'] = secManaEnum.first.index;
    }
    checkDbl('secondaryManaCost', _secondaryManaCostCtrl.text, original.secondaryManaCost);

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

    final chEnum = ChannelEffect.values.where((c) => c.name == _selectedChannelEffect);
    if (chEnum.isNotEmpty && chEnum.first != original.channelEffect) {
      overrides['channelEffect'] = chEnum.first.index;
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
      secondaryManaColor: ManaColor.values.firstWhere((m) => m.name == _selectedSecondaryManaColor, orElse: () => ManaColor.none),
      secondaryManaCost: double.tryParse(_secondaryManaCostCtrl.text) ?? 0.0,
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
      channelEffect: ChannelEffect.values.firstWhere((c) => c.name == _selectedChannelEffect, orElse: () => ChannelEffect.none),
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
}
