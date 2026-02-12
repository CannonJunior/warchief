import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../state/item_config.dart';
import '../state/custom_item_manager.dart';
import 'item_editor_fields.dart';

/// Side-panel editor for creating or editing items.
///
/// Displays all Item fields as editable inputs, grouped into sections.
/// Includes a computed power level bar and sentience toggle.
/// Supports both create mode (new item) and edit mode (existing item).
class ItemEditorPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Function(Item) onItemCreated;
  final Item? existingItem;
  final int? existingItemIndex;
  final Function(int index, Item item)? onItemSaved;

  const ItemEditorPanel({
    Key? key,
    required this.onClose,
    required this.onItemCreated,
    this.existingItem,
    this.existingItemIndex,
    this.onItemSaved,
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

  // Per-color mana controllers
  late TextEditingController _maxBlueManaCtrl;
  late TextEditingController _maxRedManaCtrl;
  late TextEditingController _maxWhiteManaCtrl;
  late TextEditingController _blueManaRegenCtrl;
  late TextEditingController _redManaRegenCtrl;
  late TextEditingController _whiteManaRegenCtrl;

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

  bool get _isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _descriptionCtrl = TextEditingController(text: item?.description ?? '');
    _brawnCtrl = TextEditingController(text: '${item?.stats.brawn ?? 0}');
    _yarCtrl = TextEditingController(text: '${item?.stats.yar ?? 0}');
    _auspiceCtrl = TextEditingController(text: '${item?.stats.auspice ?? 0}');
    _valorCtrl = TextEditingController(text: '${item?.stats.valor ?? 0}');
    _chuffCtrl = TextEditingController(text: '${item?.stats.chuff ?? 0}');
    _xCtrl = TextEditingController(text: '${item?.stats.x ?? 0}');
    _zealCtrl = TextEditingController(text: '${item?.stats.zeal ?? 0}');
    _armorCtrl = TextEditingController(text: '${item?.stats.armor ?? 0}');
    _damageCtrl = TextEditingController(text: '${item?.stats.damage ?? 0}');
    _critChanceCtrl = TextEditingController(text: '${item?.stats.critChance ?? 0}');
    _healthCtrl = TextEditingController(text: '${item?.stats.health ?? 0}');
    _maxBlueManaCtrl = TextEditingController(text: '${item?.stats.maxBlueMana ?? 0}');
    _maxRedManaCtrl = TextEditingController(text: '${item?.stats.maxRedMana ?? 0}');
    _maxWhiteManaCtrl = TextEditingController(text: '${item?.stats.maxWhiteMana ?? 0}');
    _blueManaRegenCtrl = TextEditingController(text: '${item?.stats.blueManaRegen ?? 0}');
    _redManaRegenCtrl = TextEditingController(text: '${item?.stats.redManaRegen ?? 0}');
    _whiteManaRegenCtrl = TextEditingController(text: '${item?.stats.whiteManaRegen ?? 0}');
    _sellValueCtrl = TextEditingController(text: '${item?.sellValue ?? 0}');
    _levelReqCtrl = TextEditingController(text: '${item?.levelRequirement ?? 1}');
    _stackSizeCtrl = TextEditingController(text: '${item?.stackSize ?? 1}');
    _maxStackCtrl = TextEditingController(text: '${item?.maxStack ?? 1}');
    if (item != null) {
      _selectedType = item.type.name;
      _selectedRarity = item.rarity.name;
      _selectedSlot = item.slot?.name;
      _selectedSentience = item.sentience;
    }
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
    _maxBlueManaCtrl.dispose();
    _maxRedManaCtrl.dispose();
    _maxWhiteManaCtrl.dispose();
    _blueManaRegenCtrl.dispose();
    _redManaRegenCtrl.dispose();
    _whiteManaRegenCtrl.dispose();
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
      maxBlueMana: int.tryParse(_maxBlueManaCtrl.text) ?? 0,
      maxRedMana: int.tryParse(_maxRedManaCtrl.text) ?? 0,
      maxWhiteMana: int.tryParse(_maxWhiteManaCtrl.text) ?? 0,
      blueManaRegen: int.tryParse(_blueManaRegenCtrl.text) ?? 0,
      redManaRegen: int.tryParse(_redManaRegenCtrl.text) ?? 0,
      whiteManaRegen: int.tryParse(_whiteManaRegenCtrl.text) ?? 0,
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

  void _onSave() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      print('[ItemEditor] Cannot save: name is empty');
      return;
    }

    final stats = _currentStats();
    final rarity = _currentRarity;
    final type = ItemType.values.firstWhere(
        (t) => t.name == _selectedType, orElse: () => ItemType.material);
    final slot = _selectedSlot != null
        ? EquipmentSlot.values.firstWhere(
            (s) => s.name == _selectedSlot, orElse: () => EquipmentSlot.mainHand)
        : null;

    // Reason: preserve original item's id when editing
    final item = Item(
      id: widget.existingItem!.id,
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
    widget.onItemSaved?.call(widget.existingItemIndex!, item);
    print('[ItemEditor] Saved item: $name (${item.id})');
  }

  void _onRevert() {
    final item = widget.existingItem;
    if (item == null) return;
    setState(() {
      _nameCtrl.text = item.name;
      _descriptionCtrl.text = item.description;
      _selectedType = item.type.name;
      _selectedRarity = item.rarity.name;
      _selectedSlot = item.slot?.name;
      _selectedSentience = item.sentience;
      _brawnCtrl.text = '${item.stats.brawn}';
      _yarCtrl.text = '${item.stats.yar}';
      _auspiceCtrl.text = '${item.stats.auspice}';
      _valorCtrl.text = '${item.stats.valor}';
      _chuffCtrl.text = '${item.stats.chuff}';
      _xCtrl.text = '${item.stats.x}';
      _zealCtrl.text = '${item.stats.zeal}';
      _armorCtrl.text = '${item.stats.armor}';
      _damageCtrl.text = '${item.stats.damage}';
      _critChanceCtrl.text = '${item.stats.critChance}';
      _healthCtrl.text = '${item.stats.health}';
      _maxBlueManaCtrl.text = '${item.stats.maxBlueMana}';
      _maxRedManaCtrl.text = '${item.stats.maxRedMana}';
      _maxWhiteManaCtrl.text = '${item.stats.maxWhiteMana}';
      _blueManaRegenCtrl.text = '${item.stats.blueManaRegen}';
      _redManaRegenCtrl.text = '${item.stats.redManaRegen}';
      _whiteManaRegenCtrl.text = '${item.stats.whiteManaRegen}';
      _sellValueCtrl.text = '${item.sellValue}';
      _levelReqCtrl.text = '${item.levelRequirement}';
      _stackSizeCtrl.text = '${item.stackSize}';
      _maxStackCtrl.text = '${item.maxStack}';
    });
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
                  _buildManaSection(),
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
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              _isEditMode ? Icons.edit : Icons.add_circle,
              color: itemEditorAccent, size: 14),
          ),
          Expanded(
            child: Text(_isEditMode ? 'EDIT ITEM' : 'NEW ITEM',
              style: const TextStyle(color: itemEditorAccent, fontSize: 14,
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
          Expanded(child: buildEditorButton(
            _isEditMode ? 'Save' : 'Create',
            itemEditorAccent,
            _isEditMode ? _onSave : _onCreate,
          )),
          const SizedBox(width: 8),
          Expanded(child: buildEditorButton(
            _isEditMode ? 'Revert' : 'Cancel',
            _isEditMode ? Colors.orange : Colors.red,
            _isEditMode ? _onRevert : widget.onClose,
          )),
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
    ]);
  }

  Widget _buildManaSection() {
    return buildEditorSection('MANA', Colors.cyan.shade300, [
      buildEditorNumericRow('Max Blue', _maxBlueManaCtrl, 'maxBlueMana', onChange: _refresh),
      buildEditorNumericRow('Max Red', _maxRedManaCtrl, 'maxRedMana', onChange: _refresh),
      buildEditorNumericRow('Max White', _maxWhiteManaCtrl, 'maxWhiteMana', onChange: _refresh),
      buildEditorNumericRow('Blue Regen', _blueManaRegenCtrl, 'blueManaRegen', onChange: _refresh),
      buildEditorNumericRow('Red Regen', _redManaRegenCtrl, 'redManaRegen', onChange: _refresh),
      buildEditorNumericRow('White Regen', _whiteManaRegenCtrl, 'whiteManaRegen', onChange: _refresh),
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
