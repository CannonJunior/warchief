import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../ai/ally_strategy.dart';
import '../../models/ally.dart';
import '../../models/item.dart';
import '../../models/inventory.dart';

/// Character Panel - Draggable panel displaying player/ally character information
///
/// Opened with the 'C' key, this panel shows:
/// - Carousel to switch between Player and Allies
/// - Character name, level, and class
/// - Core stats (Health, Mana, etc.)
/// - Attributes (Strength, Agility, Intelligence, etc.)
/// - Combat stats (Damage, Armor, Critical, etc.)
class CharacterPanel extends StatefulWidget {
  final VoidCallback onClose;
  final GameState gameState;

  const CharacterPanel({
    Key? key,
    required this.onClose,
    required this.gameState,
  }) : super(key: key);

  @override
  State<CharacterPanel> createState() => _CharacterPanelState();
}

class _CharacterPanelState extends State<CharacterPanel> {
  double _xPos = 100.0;
  double _yPos = 80.0;

  /// Current carousel index: 0 = Player, 1+ = Allies
  int _currentIndex = 0;

  /// Total number of characters (player + allies)
  int get _totalCharacters => 1 + widget.gameState.allies.length;

  /// Whether we're viewing the player
  bool get _isViewingPlayer => _currentIndex == 0;

  /// Get the ally being viewed (null if viewing player)
  Ally? get _currentAlly {
    if (_isViewingPlayer || _currentIndex > widget.gameState.allies.length) {
      return null;
    }
    return widget.gameState.allies[_currentIndex - 1];
  }

  void _previousCharacter() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _totalCharacters) % _totalCharacters;
    });
  }

  void _nextCharacter() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _totalCharacters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPos += details.delta.dx;
            _yPos += details.delta.dy;
            _xPos = _xPos.clamp(0.0, MediaQuery.of(context).size.width - 320);
            _yPos = _yPos.clamp(0.0, MediaQuery.of(context).size.height - 520);
          });
        },
        child: Container(
          width: 320,
          height: 520,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4cc9f0), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              // Carousel navigation (only show if there are allies)
              if (widget.gameState.allies.isNotEmpty) _buildCarouselNav(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCharacterInfo(),
                      const SizedBox(height: 16),
                      _buildResourceBars(),
                      const SizedBox(height: 16),
                      _buildAttributesSection(),
                      const SizedBox(height: 16),
                      _buildCombatStatsSection(),
                      const SizedBox(height: 16),
                      if (_isViewingPlayer) _buildEquipmentSection(),
                      if (!_isViewingPlayer) _buildAllyInfoSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.drag_indicator, color: Color(0xFF4cc9f0), size: 20),
              const SizedBox(width: 8),
              const Text(
                'CHARACTER',
                style: TextStyle(
                  color: Color(0xFF4cc9f0),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '[C]',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF252542), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          IconButton(
            onPressed: _previousCharacter,
            icon: const Icon(Icons.chevron_left, color: Color(0xFF4cc9f0)),
            iconSize: 28,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          // Indicator dots and label
          Expanded(
            child: Column(
              children: [
                Text(
                  _isViewingPlayer ? 'PLAYER' : 'ALLY ${_currentIndex}',
                  style: TextStyle(
                    color: _isViewingPlayer
                        ? const Color(0xFF4cc9f0)
                        : const Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalCharacters, (index) {
                    final isActive = index == _currentIndex;
                    final isPlayer = index == 0;
                    return GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      child: Container(
                        width: isActive ? 24 : 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isPlayer ? const Color(0xFF4cc9f0) : const Color(0xFF4CAF50))
                              : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(5),
                          border: isActive
                              ? Border.all(color: Colors.white24, width: 1)
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          // Next button
          IconButton(
            onPressed: _nextCharacter,
            icon: const Icon(Icons.chevron_right, color: Color(0xFF4cc9f0)),
            iconSize: 28,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterInfo() {
    final ally = _currentAlly;
    final isPlayer = _isViewingPlayer;

    final name = isPlayer ? 'Warchief' : 'Ally ${_currentIndex}';
    final levelClass = isPlayer
        ? 'Level 10 Warrior'
        : 'Level ${5 + _currentIndex} ${_getAllyClass(ally)}';
    final title = isPlayer
        ? 'The Commander'
        : _getAllyTitle(ally);
    final portraitColor = isPlayer
        ? const Color(0xFF4D80CC)
        : _getAllyColor(_currentIndex - 1);
    final borderColor = isPlayer
        ? const Color(0xFF4cc9f0)
        : const Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF252542)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: portraitColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Icon(
              isPlayer ? Icons.person : Icons.groups,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  levelClass,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAllyClass(Ally? ally) {
    if (ally == null) return 'Fighter';
    switch (ally.abilityIndex) {
      case 0: return 'Fighter';
      case 1: return 'Mage';
      case 2: return 'Healer';
      default: return 'Fighter';
    }
  }

  String _getAllyTitle(Ally? ally) {
    if (ally == null) return 'Companion';
    switch (ally.strategyType) {
      case AllyStrategyType.aggressive: return 'The Berserker';
      case AllyStrategyType.defensive: return 'The Guardian';
      case AllyStrategyType.support: return 'The Protector';
      case AllyStrategyType.balanced: return 'The Companion';
      case AllyStrategyType.berserker: return 'The Reckless';
    }
  }

  Color _getAllyColor(int index) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF00BCD4),
    ];
    return colors[index % colors.length];
  }

  Widget _buildResourceBars() {
    final ally = _currentAlly;
    final gs = widget.gameState;

    final health = _isViewingPlayer ? gs.playerHealth : (ally?.health ?? 0);
    final maxHealth = _isViewingPlayer ? gs.playerMaxHealth : (ally?.maxHealth ?? 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Resources'),
        const SizedBox(height: 8),
        _buildResourceBar(
          label: 'Health',
          current: health,
          max: maxHealth,
          color: const Color(0xFF4CAF50),
          icon: Icons.favorite,
        ),
        const SizedBox(height: 8),
        _buildResourceBar(
          label: 'Mana',
          current: _isViewingPlayer ? 80 : 60,
          max: 100,
          color: const Color(0xFF2196F3),
          icon: Icons.auto_awesome,
        ),
        const SizedBox(height: 8),
        _buildResourceBar(
          label: 'Stamina',
          current: 100,
          max: 100,
          color: const Color(0xFFFFB300),
          icon: Icons.flash_on,
        ),
      ],
    );
  }

  Widget _buildResourceBar({
    required String label,
    required double current,
    required double max,
    required Color color,
    required IconData icon,
  }) {
    final percentage = max > 0 ? current / max : 0.0;
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            '${current.toInt()}/${max.toInt()}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesSection() {
    // Generate different stats for player vs allies
    // Attributes: Auspice, Brawn, Chuff, X, Yar, Zeal, Valor
    final isPlayer = _isViewingPlayer;
    final allyIndex = _currentIndex - 1;

    final auspice = isPlayer ? 14 : 8 + (allyIndex * 2);   // Favor, omens
    final brawn = isPlayer ? 25 : 15 + (allyIndex * 3);    // Physical power
    final chuff = isPlayer ? 18 : 12 + (allyIndex * 2);    // Satisfaction, spirit
    final x = isPlayer ? 7 : 3 + allyIndex;                // The unknown factor
    final yar = isPlayer ? 20 : 14 + (allyIndex * 2);      // Quick, agile, ready
    final zeal = isPlayer ? 16 : 10 + (allyIndex * 2);     // Fervent energy
    final valor = isPlayer ? 22 : 16 + (allyIndex * 2);    // Courage, worth

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Attributes'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildAttribute('Auspice', auspice, const Color(0xFFE0B0FF))), // Mauve/mystic
            const SizedBox(width: 8),
            Expanded(child: _buildAttribute('Brawn', brawn, const Color(0xFFCD5C5C))), // Indian red
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildAttribute('Chuff', chuff, const Color(0xFFDEB887))), // Burlywood/warm
            const SizedBox(width: 8),
            Expanded(child: _buildAttribute('X', x, const Color(0xFF808080))), // Gray/mysterious
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildAttribute('Yar', yar, const Color(0xFF20B2AA))), // Light sea green
            const SizedBox(width: 8),
            Expanded(child: _buildAttribute('Zeal', zeal, const Color(0xFFFF6347))), // Tomato/fiery
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildAttribute('Valor', valor, const Color(0xFFFFD700))), // Gold
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()), // Empty for odd number
          ],
        ),
      ],
    );
  }

  Widget _buildAttribute(String name, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 11),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombatStatsSection() {
    final isPlayer = _isViewingPlayer;
    final ally = _currentAlly;

    // Different combat stats for player vs allies
    String damage = isPlayer ? '45-52' : '${20 + (_currentIndex * 5)}-${28 + (_currentIndex * 5)}';
    String armor = isPlayer ? '120' : '${60 + (_currentIndex * 15)}';
    String crit = isPlayer ? '15%' : '${8 + _currentIndex * 2}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Combat Stats'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildStatChip('Damage', damage, Icons.sports_martial_arts),
            _buildStatChip('Armor', armor, Icons.shield),
            _buildStatChip('Crit', crit, Icons.flash_on),
            if (isPlayer) ...[
              _buildStatChip('Haste', '8%', Icons.speed),
              _buildStatChip('Block', '22%', Icons.block),
              _buildStatChip('Dodge', '5%', Icons.directions_run),
            ],
            if (!isPlayer && ally != null) ...[
              _buildStatChip('Cooldown', '${ally.abilityCooldownMax.toInt()}s', Icons.timer),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3a3a5c)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF4cc9f0), size: 14),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    final inventory = widget.gameState.playerInventory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Equipment'),
        const SizedBox(height: 8),
        // Row 1: Helm, Armor, Back
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildEquipmentSlotFromInventory(EquipmentSlot.helm, 'Helm', Icons.face, inventory),
            _buildEquipmentSlotFromInventory(EquipmentSlot.armor, 'Armor', Icons.checkroom, inventory),
            _buildEquipmentSlotFromInventory(EquipmentSlot.back, 'Back', Icons.wind_power, inventory),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: Gloves, Legs, Boots
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildEquipmentSlotFromInventory(EquipmentSlot.gloves, 'Gloves', Icons.back_hand, inventory),
            _buildEquipmentSlotFromInventory(EquipmentSlot.legs, 'Legs', Icons.airline_seat_legroom_normal, inventory),
            _buildEquipmentSlotFromInventory(EquipmentSlot.boots, 'Boots', Icons.skateboarding, inventory),
          ],
        ),
        const SizedBox(height: 8),
        // Row 3: Main Hand, Off Hand
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildEquipmentSlotFromInventory(EquipmentSlot.mainHand, 'Main', Icons.gavel, inventory),
            _buildEquipmentSlotFromInventory(EquipmentSlot.offHand, 'Off', Icons.shield, inventory),
          ],
        ),
        const SizedBox(height: 8),
        // Row 4: Ring 1, Ring 2
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildEquipmentSlotFromInventory(EquipmentSlot.ring1, 'Ring 1', Icons.radio_button_unchecked, inventory),
            _buildEquipmentSlotFromInventory(EquipmentSlot.ring2, 'Ring 2', Icons.radio_button_unchecked, inventory),
          ],
        ),
      ],
    );
  }

  Widget _buildEquipmentSlotFromInventory(EquipmentSlot slot, String label, IconData icon, Inventory inventory) {
    final item = inventory.getEquipped(slot);
    return _buildEquipmentSlotWithItem(label, icon, item);
  }

  Widget _buildEquipmentSlotWithItem(String slot, IconData icon, Item? item) {
    final hasItem = item != null;
    final borderColor = hasItem ? item.rarity.color : const Color(0xFF3a3a3a);
    final bgColor = hasItem ? item.rarity.color.withValues(alpha: 0.15) : const Color(0xFF1a1a1a);

    return Tooltip(
      message: hasItem ? '${item.name}\n${item.rarity.displayName} ${item.type.name}' : 'Empty $slot slot',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: hasItem ? 2 : 1,
          ),
          boxShadow: hasItem
              ? [
                  BoxShadow(
                    color: item.rarity.color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: hasItem ? item.rarity.color : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              slot,
              style: TextStyle(
                color: hasItem ? Colors.white70 : Colors.grey.shade600,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllyInfoSection() {
    final ally = _currentAlly;
    if (ally == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ally Status'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF252542)),
          ),
          child: Column(
            children: [
              _buildAllyInfoRow('Strategy', ally.strategy.name, Icons.psychology),
              const SizedBox(height: 8),
              _buildAllyInfoRow('Command', _getCommandName(ally.currentCommand), Icons.assignment),
              const SizedBox(height: 8),
              _buildAllyInfoRow('Mode', _getMovementModeName(ally.movementMode), Icons.directions_walk),
              const SizedBox(height: 8),
              _buildAllyInfoRow('Ability', _getAbilityName(ally.abilityIndex), Icons.auto_fix_high),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllyInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4cc9f0), size: 16),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getCommandName(AllyCommand command) {
    switch (command) {
      case AllyCommand.none: return 'AI Control';
      case AllyCommand.follow: return 'Following';
      case AllyCommand.attack: return 'Attacking';
      case AllyCommand.hold: return 'Holding';
      case AllyCommand.defensive: return 'Defensive';
    }
  }

  String _getMovementModeName(AllyMovementMode mode) {
    switch (mode) {
      case AllyMovementMode.stationary: return 'Stationary';
      case AllyMovementMode.followPlayer: return 'Following';
      case AllyMovementMode.commanded: return 'Commanded';
      case AllyMovementMode.tactical: return 'Tactical';
    }
  }

  String _getAbilityName(int index) {
    switch (index) {
      case 0: return 'Sword Strike';
      case 1: return 'Fireball';
      case 2: return 'Heal';
      default: return 'Unknown';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF4cc9f0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF4cc9f0),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
