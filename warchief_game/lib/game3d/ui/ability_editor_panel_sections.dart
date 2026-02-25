part of 'ability_editor_panel.dart';

extension _AbilityEditorPanelSections on _AbilityEditorPanelState {

  // ==================== BALANCE PREVIEW ====================

  /// Constructs a temporary AbilityData from current editor field values
  /// for live balance score computation.
  AbilityData _buildPreviewAbility() {
    return AbilityData(
      name: _nameCtrl.text,
      description: _descriptionCtrl.text,
      type: AbilityType.values.firstWhere(
        (t) => t.name == _selectedType, orElse: () => AbilityType.melee),
      damage: double.tryParse(_damageCtrl.text) ?? 0.0,
      cooldown: double.tryParse(_cooldownCtrl.text) ?? 1.0,
      duration: double.tryParse(_durationCtrl.text) ?? 0.0,
      range: double.tryParse(_rangeCtrl.text) ?? 0.0,
      healAmount: double.tryParse(_healAmountCtrl.text) ?? 0.0,
      manaColor: ManaColor.values.firstWhere(
        (m) => m.name == _selectedManaColor, orElse: () => ManaColor.none),
      manaCost: double.tryParse(_manaCostCtrl.text) ?? 0.0,
      secondaryManaColor: ManaColor.values.firstWhere(
        (m) => m.name == _selectedSecondaryManaColor, orElse: () => ManaColor.none),
      secondaryManaCost: double.tryParse(_secondaryManaCostCtrl.text) ?? 0.0,
      color: Vector3(1, 1, 1),
      impactColor: Vector3(1, 1, 1),
      statusEffect: StatusEffect.values.firstWhere(
        (s) => s.name == _selectedStatusEffect, orElse: () => StatusEffect.none),
      statusDuration: double.tryParse(_statusDurationCtrl.text) ?? 0.0,
      statusStrength: double.tryParse(_statusStrengthCtrl.text) ?? 0.0,
      aoeRadius: double.tryParse(_aoeRadiusCtrl.text) ?? 0.0,
      maxTargets: int.tryParse(_maxTargetsCtrl.text) ?? 1,
      dotTicks: int.tryParse(_dotTicksCtrl.text) ?? 0,
      knockbackForce: double.tryParse(_knockbackForceCtrl.text) ?? 0.0,
      castTime: double.tryParse(_castTimeCtrl.text) ?? 0.0,
      windupTime: double.tryParse(_windupTimeCtrl.text) ?? 0.0,
      windupMovementSpeed: double.tryParse(_windupMovementSpeedCtrl.text) ?? 1.0,
      hitRadius: double.tryParse(_hitRadiusCtrl.text),
      piercing: _piercing,
      requiresStationary: _requiresStationary,
      category: _selectedCategory,
      channelEffect: ChannelEffect.values.firstWhere((c) => c.name == _selectedChannelEffect, orElse: () => ChannelEffect.none),
    );
  }

  /// Colored badge showing live balance score in the editor header.
  Widget _buildEditorBalancePreview() {
    final preview = _buildPreviewAbility();
    final score = computeBalanceScore(preview);
    final color = balanceScoreColor(score);
    final label = balanceScoreLabel(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        'BAL: ${score.toStringAsFixed(2)} $label',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==================== HEADER / FOOTER ====================

  Widget _buildHeader(bool hasOverrides) {
    final title = widget.isNewAbility ? 'NEW ABILITY' : widget.ability.name;
    final titleColor = widget.isNewAbility ? Colors.green : _editorAccent;

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
          _buildEditorBalancePreview(),
          const SizedBox(width: 6),
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
    final saveColor = widget.isNewAbility ? Colors.green : _editorAccent;
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
      decoration: BoxDecoration(color: _editorSectionBg, borderRadius: BorderRadius.circular(4)),
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
      _buildDropdownWithAddNew(
        label: 'Secondary Mana Color',
        tooltipKey: 'manaColor',
        builtInValues: ManaColor.values.map((m) => m.name).toList(),
        customKey: 'secondaryManaColor',
        selectedValue: _selectedSecondaryManaColor,
        onChanged: (v) => setState(() => _selectedSecondaryManaColor = v),
      ),
      _buildNumericRow('Secondary Mana Cost', _secondaryManaCostCtrl, 'secondaryManaCost'),
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
      _buildDropdownWithAddNew(
        label: 'Channel Effect',
        tooltipKey: 'channelEffect',
        builtInValues: ChannelEffect.values.map((c) => c.name).toList(),
        customKey: 'channelEffect',
        selectedValue: _selectedChannelEffect,
        onChanged: (v) => setState(() => _selectedChannelEffect = v),
      ),
    ]);
  }
}
