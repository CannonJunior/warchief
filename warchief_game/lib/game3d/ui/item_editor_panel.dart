import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../state/item_config.dart';
import '../state/custom_item_manager.dart';
import 'item_editor_fields.dart';

/// Side-panel editor for creating new items.
///
/// Displays all Item fields as editable inputs, grouped into sections.
/// Includes a computed power level bar and sentience toggle.
/// Opened by clicking "+ ADD NEW ITEM" in the Bag panel.
class ItemEditorPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Function(Item) onItemCreated;

  const ItemEditorPanel({
    Key? key,
    required this.onClose,
    required this.onItemCreated,
  }) : super(key: key);

  @override
  State<ItemEditorPanel> createState() => _ItemEditorPanelState();
}

class _ItemEditorPanelState extends State<ItemEditorPanel> {
  // Identity controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _descriptionCtrl;

  // Attribute controllers (7 primary stats)
  late TextEditingController _brawnCtrl;
  late TextEditingController _yarCtrl;
  late TextEditingController _auspiceCtrl;
  late TextEditingController _valorCtrl;
  late TextEditingController _chuffCtrl;
  late TextEditingController _xCtrl;
  late TextEditingController _zealCtrl;

  // Combat stat controllers
  late TextEditingController _armorCtrl;
  late TextEditingController _damageCtrl;
  late TextEditingController _critChanceCtrl;
  late TextEditingController _healthCtrl;
  late TextEditingController _manaCtrl;

  // Properties controllers
  late TextEditingController _sellValueCtrl;
  late TextEditingController _levelReqCtrl;
  late TextEditingController _stackSizeCtrl;
  late TextEditingController _maxStackCtrl;

  // Dropdown state
  String _selectedType = 'weapon';
  String _selectedRarity = 'common';
  String? _selectedSlot = 'mainHand';

  // Sentience state
  ItemSentience _selectedSentience = ItemSentience.inanimate;

  static const double _panelWidth = 320.0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
    _brawnCtrl = TextEditingController(text: '0');
    _yarCtrl = TextEditingController(text: '0');
    _auspiceCtrl = TextEditingController(text: '0');
    _valorCtrl = TextEditingController(text: '0');
    _chuffCtrl = TextEditingController(text: '0');
    _xCtrl = TextEditingController(text: '0');
    _zealCtrl = TextEditingController(text: '0');
    _armorCtrl = TextEditingController(text: '0');
    _damageCtrl = TextEditingController(text: '0');
    _critChanceCtrl = TextEditingController(text: '0');
    _healthCtrl = TextEditingController(text: '0');
    _manaCtrl = TextEditingController(text: '0');
    _sellValueCtrl = TextEditingController(text: '0');
    _levelReqCtrl = TextEditingController(text: '1');
    _stackSizeCtrl = TextEditingController(text: '1');
    _maxStackCtrl = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _brawnCtrl.dispose();
    _yarCtrl.dispose();
    _auspiceCtrl.dispose();
    _valorCtrl.dispose();
    _chuffCtrl.dispose();
    _xCtrl.dispose();
    _zealCtrl.dispose();
    _armorCtrl.dispose();
    _damageCtrl.dispose();
    _critChanceCtrl.dispose();
    _healthCtrl.dispose();
    _manaCtrl.dispose();
    _sellValueCtrl.dispose();
    _levelReqCtrl.dispose();
    _stackSizeCtrl.dispose();
    _maxStackCtrl.dispose();
    super.dispose();
  }

  /// Build current ItemStats from controllers for power calculation
  ItemStats _currentStats() {
    return ItemStats(
      brawn: int.tryParse(_brawnCtrl.text) ?? 0,
      yar: int.tryParse(_yarCtrl.text) ?? 0,
      auspice: int.tryParse(_auspiceCtrl.text) ?? 0,
      valor: int.tryParse(_valorCtrl.text) ?? 0,
      chuff: int.tryParse(_chuffCtrl.text) ?? 0,
      x: int.tryParse(_xCtrl.text) ?? 0,
      zeal: int.tryParse(_zealCtrl.text) ?? 0,
      armor: int.tryParse(_armorCtrl.text) ?? 0,
      damage: int.tryParse(_damageCtrl.text) ?? 0,
      critChance: int.tryParse(_critChanceCtrl.text) ?? 0,
      health: int.tryParse(_healthCtrl.text) ?? 0,
      mana: int.tryParse(_manaCtrl.text) ?? 0,
    );
  }

  ItemRarity get _currentRarity =>
      ItemRarity.values.firstWhere((r) => r.name == _selectedRarity,
          orElse: () => ItemRarity.common);

  double get _currentPowerLevel {
    final config = globalItemConfig;
    if (config == null) return 0.0;
    return config.calculatePowerLevel(_currentStats(), _currentRarity);
  }

  /// Get the valid slot options based on item type
  List<String>? _getSlotsForType(String typeName) {
    switch (typeName) {
      case 'weapon':
        return ['mainHand', 'offHand'];
      case 'armor':
        return ['helm', 'armor', 'back', 'gloves', 'legs', 'boots', 'offHand'];
      case 'accessory':
        return ['ring1', 'ring2', 'talisman'];
      default:
        return null; // consumable, material, quest — no slot
    }
  }

  bool get _showSlotDropdown => _getSlotsForType(_selectedType) != null;

  bool get _showStackFields =>
      _selectedType == 'consumable' || _selectedType == 'material';

  void _onTypeChanged(String newType) {
    setState(() {
      _selectedType = newType;
      final slots = _getSlotsForType(newType);
      if (slots != null) {
        // Reason: reset slot to first valid option when type changes
        if (_selectedSlot == null || !slots.contains(_selectedSlot)) {
          _selectedSlot = slots.first;
        }
      } else {
        _selectedSlot = null;
      }
    });
  }

  void _autoDowngradeSentience() {
    final power = _currentPowerLevel;
    final config = globalItemConfig;
    final imbuedThreshold = config?.imbuedThreshold ?? 40.0;
    final sentientThreshold = config?.sentientThreshold ?? 100.0;

    if (_selectedSentience == ItemSentience.sentient && power < sentientThreshold) {
      _selectedSentience = power >= imbuedThreshold
          ? ItemSentience.imbued : ItemSentience.inanimate;
    } else if (_selectedSentience == ItemSentience.imbued && power < imbuedThreshold) {
      _selectedSentience = ItemSentience.inanimate;
    }
  }

  void _onCreate() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      print('[ItemEditor] Cannot create: name is empty');
      return;
    }

    final id = CustomItemManager.generateId();
    final stats = _currentStats();
    final rarity = _currentRarity;
    final type = ItemType.values.firstWhere(
        (t) => t.name == _selectedType, orElse: () => ItemType.material);
    final slot = _selectedSlot != null
        ? EquipmentSlot.values.firstWhere(
            (s) => s.name == _selectedSlot, orElse: () => EquipmentSlot.mainHand)
        : null;

    final item = Item(
      id: id,
      name: name,
      description: _descriptionCtrl.text,
      type: type,
      rarity: rarity,
      slot: slot,
      stats: stats,
      stackSize: int.tryParse(_stackSizeCtrl.text) ?? 1,
      maxStack: int.tryParse(_maxStackCtrl.text) ?? 1,
      sellValue: int.tryParse(_sellValueCtrl.text) ?? 0,
      levelRequirement: int.tryParse(_levelReqCtrl.text) ?? 1,
      sentience: _selectedSentience,
    );

    globalCustomItemManager?.saveItem(item);
    widget.onItemCreated(item);
    print('[ItemEditor] Created new item: $name ($id)');
  }

  @override
  Widget build(BuildContext context) {
    // Reason: auto-downgrade sentience before rendering so UI stays consistent
    _autoDowngradeSentience();

    return Container(
      width: _panelWidth,
      height: 600,
      decoration: BoxDecoration(
        color: itemEditorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: itemEditorAccent, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentitySection(),
                  _buildClassificationSection(),
                  _buildAttributesSection(),
                  _buildCombatStatsSection(),
                  _buildPropertiesSection(),
                  buildPowerSentienceSection(
                    powerLevel: _currentPowerLevel,
                    selectedSentience: _selectedSentience,
                    onSentienceChanged: (s) =>
                        setState(() => _selectedSentience = s),
                  ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6), topRight: Radius.circular(6)),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(Icons.add_circle, color: itemEditorAccent, size: 14),
          ),
          const Expanded(
            child: Text('NEW ITEM',
              style: TextStyle(color: itemEditorAccent, fontSize: 14,
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
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
      ),
      child: Row(
        children: [
          Expanded(child: buildEditorButton('Create', itemEditorAccent, _onCreate)),
          const SizedBox(width: 8),
          Expanded(child: buildEditorButton('Cancel', Colors.red, widget.onClose)),
        ],
      ),
    );
  }

  // ==================== SECTIONS ====================

  void _refresh() => setState(() {});

  Widget _buildIdentitySection() {
    return buildEditorSection('IDENTITY', Colors.white70, [
      buildEditorTextField('Name', _nameCtrl, 'name'),
      buildEditorTextField('Description', _descriptionCtrl, 'description',
          multiline: true),
    ]);
  }

  Widget _buildClassificationSection() {
    final typeValues = ItemType.values.map((t) => t.name).toList();
    final rarityValues = ItemRarity.values.map((r) => r.name).toList();

    return buildEditorSection('CLASSIFICATION', itemEditorAccent, [
      buildEditorDropdown('Type', 'type', typeValues, _selectedType,
          (v) => _onTypeChanged(v)),
      buildEditorDropdown('Rarity', 'rarity', rarityValues, _selectedRarity,
          (v) => setState(() => _selectedRarity = v)),
      if (_showSlotDropdown)
        buildEditorDropdown('Slot', 'slot', _getSlotsForType(_selectedType)!,
            _selectedSlot ?? _getSlotsForType(_selectedType)!.first,
            (v) => setState(() => _selectedSlot = v)),
    ]);
  }

  Widget _buildAttributesSection() {
    return buildEditorSection('ATTRIBUTES', Colors.green.shade300, [
      buildEditorNumericRow('Brawn', _brawnCtrl, 'brawn', onChange: _refresh),
      buildEditorNumericRow('Yar', _yarCtrl, 'yar', onChange: _refresh),
      buildEditorNumericRow('Auspice', _auspiceCtrl, 'auspice', onChange: _refresh),
      buildEditorNumericRow('Valor', _valorCtrl, 'valor', onChange: _refresh),
      buildEditorNumericRow('Chuff', _chuffCtrl, 'chuff', onChange: _refresh),
      buildEditorNumericRow('X', _xCtrl, 'x', onChange: _refresh),
      buildEditorNumericRow('Zeal', _zealCtrl, 'zeal', onChange: _refresh),
    ]);
  }

  Widget _buildCombatStatsSection() {
    return buildEditorSection('COMBAT STATS', Colors.red.shade300, [
      buildEditorNumericRow('Armor', _armorCtrl, 'armor', onChange: _refresh),
      buildEditorNumericRow('Damage', _damageCtrl, 'damage', onChange: _refresh),
      buildEditorNumericRow('Crit Chance', _critChanceCtrl, 'critChance', onChange: _refresh),
      buildEditorNumericRow('Health', _healthCtrl, 'health', onChange: _refresh),
      buildEditorNumericRow('Mana', _manaCtrl, 'mana', onChange: _refresh),
    ]);
  }

  Widget _buildPropertiesSection() {
    return buildEditorSection('PROPERTIES', Colors.blue.shade300, [
      buildEditorNumericRow('Sell Value', _sellValueCtrl, 'sellValue'),
      buildEditorNumericRow('Level Req.', _levelReqCtrl, 'levelReq'),
      if (_showStackFields) ...[
        buildEditorNumericRow('Stack Size', _stackSizeCtrl, 'stackSize'),
        buildEditorNumericRow('Max Stack', _maxStackCtrl, 'maxStack'),
      ],
    ]);
  }
}
