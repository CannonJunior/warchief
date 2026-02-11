import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../ai/ally_strategy.dart';
import '../../models/ally.dart';
import '../../models/item.dart';
import '../../models/inventory.dart';
import 'character_panel_columns.dart';

/// Character Panel - 3-column draggable panel displaying player/ally info
///
/// Opened with the 'C' key. Layout: 750x560, no scrolling.
/// Left column: Attributes with color-coded accent bars
/// Center column: Rotatable paper doll cube with equipment slots
/// Right column: Resources, combat stats, gear bonuses
///
/// API unchanged: CharacterPanel({onClose, gameState})
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

  /// Cube rotation angle in degrees, controlled by horizontal drag
  double _cubeRotation = 0.0;

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

  /// Handle equipping an item from the bag to a specific equipment slot.
  ///
  /// Removes the item from the bag, equips it to the target slot,
  /// and returns any displaced item back to the bag.
  /// Adjusts player health when equipment health bonuses change.
  void _handleEquipFromBag(EquipmentSlot slot, Item item) {
    setState(() {
      final gs = widget.gameState;
      final inventory = gs.playerInventory;
      final oldMaxHealth = gs.playerMaxHealth;
      final bag = inventory.bag;

      // Find and remove the item from the bag
      for (int i = 0; i < bag.length; i++) {
        if (identical(bag[i], item)) {
          inventory.removeFromBag(i);
          break;
        }
      }

      // Equip the item to the specific slot, get displaced item
      final oldItem = inventory.equipToSlot(slot, item);

      // If an old item was displaced, put it back in the bag
      if (oldItem != null) {
        inventory.addToBag(oldItem);
      }

      // Reason: adjust current health by the delta so equipping +30 HP
      // adds 30 to current health, and unequipping removes it.
      final healthDelta = gs.playerMaxHealth - oldMaxHealth;
      gs.playerHealth =
          (gs.playerHealth + healthDelta).clamp(0.0, gs.playerMaxHealth);
    });
  }

  /// Handle unequipping an item from an equipment slot to the bag.
  ///
  /// Called when a player drags an equipped item onto the bag panel.
  /// Adjusts player health when equipment health bonuses change.
  void _handleUnequipToBag(EquipmentSlot slot, Item item) {
    setState(() {
      final gs = widget.gameState;
      final inventory = gs.playerInventory;
      final oldMaxHealth = gs.playerMaxHealth;

      inventory.unequip(slot);
      inventory.addToBag(item);

      final healthDelta = gs.playerMaxHealth - oldMaxHealth;
      gs.playerHealth =
          (gs.playerHealth + healthDelta).clamp(0.0, gs.playerMaxHealth);
    });
  }

  void _previousCharacter() {
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + _totalCharacters) % _totalCharacters;
    });
  }

  void _nextCharacter() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _totalCharacters;
    });
  }

  Color _getAllyColor(int index) {
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF9C27B0),
      Color(0xFFFF9800),
      Color(0xFF00BCD4),
    ];
    return colors[index % colors.length];
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: Container(
        width: 750,
        height: 560,
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
            _buildHeader(screenSize),
            // Carousel navigation (only show if there are allies)
            if (widget.gameState.allies.isNotEmpty) _buildCarouselNav(),
            // Compact character info row below carousel
            _buildCharacterInfoRow(),
            // 3-column layout
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: Attributes
                  SizedBox(
                    width: 190,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 4),
                      child: buildAttributesColumn(
                        isPlayer: _isViewingPlayer,
                        allyIndex: _currentIndex - 1,
                      ),
                    ),
                  ),
                  // Vertical divider
                  Container(
                    width: 1,
                    color: const Color(0xFF252542),
                  ),
                  // Center column: Paper doll with rotation gesture
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _cubeRotation += details.delta.dx * 1.5;
                          // Keep within 0-360 range
                          _cubeRotation = _cubeRotation % 360;
                        });
                      },
                      child: buildPaperDollColumn(
                        isPlayer: _isViewingPlayer,
                        currentIndex: _currentIndex,
                        ally: _currentAlly,
                        cubeRotation: _cubeRotation,
                        portraitColor: _isViewingPlayer
                            ? const Color(0xFF4D80CC)
                            : _getAllyColor(_currentIndex - 1),
                        inventory: widget.gameState.playerInventory,
                        onEquipItem: _isViewingPlayer
                            ? _handleEquipFromBag
                            : null,
                        onUnequipItem: _isViewingPlayer
                            ? _handleUnequipToBag
                            : null,
                      ),
                    ),
                  ),
                  // Vertical divider
                  Container(
                    width: 1,
                    color: const Color(0xFF252542),
                  ),
                  // Right column: Resources, combat stats, gear bonus
                  SizedBox(
                    width: 190,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 4),
                      child: buildStatsColumn(
                        isPlayer: _isViewingPlayer,
                        currentIndex: _currentIndex,
                        ally: _currentAlly,
                        gameState: widget.gameState,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header bar - draggable to move panel
  Widget _buildHeader(Size screenSize) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _xPos += details.delta.dx;
          _yPos += details.delta.dy;
          _xPos = _xPos.clamp(0.0, screenSize.width - 750);
          _yPos = _yPos.clamp(0.0, screenSize.height - 560);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator,
                color: Color(0xFF4cc9f0), size: 18),
            const SizedBox(width: 8),
            const Text(
              'CHARACTER',
              style: TextStyle(
                color: Color(0xFF4cc9f0),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 12),
            // Compact character summary in header
            Expanded(
              child: _buildHeaderSummary(),
            ),
            Text(
              '[C]',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
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
                child:
                    const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact summary in header: "Warchief · Lv10 Warrior · The Commander"
  Widget _buildHeaderSummary() {
    final ally = _currentAlly;
    final isPlayer = _isViewingPlayer;

    final name = isPlayer ? 'Warchief' : 'Ally $_currentIndex';
    final levelClass = isPlayer
        ? 'Lv10 Warrior'
        : 'Lv${5 + _currentIndex} ${_getAllyClass(ally)}';
    final title = isPlayer ? '"The Commander"' : '"${_getAllyTitle(ally)}"';

    return Text(
      '$name \u00b7 $levelClass \u00b7 $title',
      style: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 11,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Carousel navigation for switching between player and allies
  Widget _buildCarouselNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF252542), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousCharacter,
            icon: const Icon(Icons.chevron_left, color: Color(0xFF4cc9f0)),
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _isViewingPlayer ? 'PLAYER' : 'ALLY $_currentIndex',
                  style: TextStyle(
                    color: _isViewingPlayer
                        ? const Color(0xFF4cc9f0)
                        : const Color(0xFF4CAF50),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalCharacters, (index) {
                    final isActive = index == _currentIndex;
                    final isPlayer = index == 0;
                    return GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      child: Container(
                        width: isActive ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isPlayer
                                  ? const Color(0xFF4cc9f0)
                                  : const Color(0xFF4CAF50))
                              : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(4),
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
          IconButton(
            onPressed: _nextCharacter,
            icon:
                const Icon(Icons.chevron_right, color: Color(0xFF4cc9f0)),
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  /// Compact character info row between carousel and columns
  Widget _buildCharacterInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF252542), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Small portrait color indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isViewingPlayer
                  ? const Color(0xFF4D80CC)
                  : _getAllyColor(_currentIndex - 1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isViewingPlayer
                    ? const Color(0xFF4cc9f0)
                    : const Color(0xFF4CAF50),
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isViewingPlayer ? 'Warchief' : 'Ally $_currentIndex',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isViewingPlayer
                ? 'Level 10 Warrior'
                : 'Level ${5 + _currentIndex} ${_getAllyClass(_currentAlly)}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isViewingPlayer
                ? '"The Commander"'
                : '"${_getAllyTitle(_currentAlly)}"',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
