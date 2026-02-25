import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import '../state/abilities_config.dart';
import '../state/ability_override_manager.dart';
import '../state/custom_options_manager.dart';
import '../state/custom_ability_manager.dart';
import '../state/action_bar_config.dart';
import '../data/abilities/abilities.dart' show AbilityRegistry;
import 'ability_editor_panel.dart';
import 'stance_editor_panel.dart';
import 'ui_config.dart';
import '../data/abilities/ability_balance.dart';
import '../state/ability_order_manager.dart';
import '../state/game_state.dart';
import '../data/stances/stances.dart' show StanceData, globalStanceOverrideManager;
import 'stance_selector.dart';

part 'abilities_modal_cards.dart';
part 'abilities_modal_filters.dart';
part 'abilities_modal_sections.dart';
part 'abilities_modal_custom.dart';

/// Abilities Panel - Draggable panel displaying all available abilities in the game
///
/// Opened with the 'P' key, this panel shows:
/// - Currently assigned abilities (Player, Monster, Allies)
/// - All potential future abilities organized by category
/// - Draggable icons that can be dropped onto the action bar
class AbilitiesModal extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(String category)? onClassLoaded;
  final GameState? gameState;

  const AbilitiesModal({
    Key? key,
    required this.onClose,
    this.onClassLoaded,
    this.gameState,
  }) : super(key: key);

  @override
  State<AbilitiesModal> createState() => _AbilitiesModalState();
}

class _AbilitiesModalState extends State<AbilitiesModal> {
  double _xPos = 50.0;
  double _yPos = 50.0;
  double _panelWidth = 750.0;
  double _panelHeight = 600.0;

  static const double _minWidth = 500.0;
  static const double _maxWidth = 1200.0;
  static const double _minHeight = 400.0;
  static const double _maxHeight = 900.0;
  static const double _resizeHandleSize = 6.0;

  AbilityData? _editingAbility;
  bool _isCreatingNew = false;
  StanceData? _editingStance;

  /// Currently selected class in the "Load Class" dropdown
  String _selectedLoadClass = 'warrior';

  /// Category filter state
  late Set<String> _enabledCategories;
  bool _filterExpanded = false;

  /// Type filter state
  late Set<AbilityType> _enabledTypes;
  bool _typeFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _enabledCategories = _getAllCategories();
    _enabledTypes = Set<AbilityType>.from(AbilityType.values);
  }

  /// Build all 8 resize handles (4 edges + 4 corners) for the panel.
  List<Widget> _buildResizeHandles() {
    Widget edge({
      double? left, double? right, double? top, double? bottom,
      required MouseCursor cursor,
      required void Function(DragUpdateDetails) onPanUpdate,
      bool isVertical = false,
    }) {
      return Positioned(
        left: left, right: right, top: top, bottom: bottom,
        child: GestureDetector(
          onPanUpdate: onPanUpdate,
          child: MouseRegion(
            cursor: cursor,
            child: Container(
              width: isVertical ? _resizeHandleSize : null,
              height: isVertical ? null : _resizeHandleSize,
              color: Colors.transparent,
            ),
          ),
        ),
      );
    }

    Widget corner({
      double? left, double? right, double? top, double? bottom,
      required MouseCursor cursor,
      required void Function(DragUpdateDetails) onPanUpdate,
    }) {
      return Positioned(
        left: left, right: right, top: top, bottom: bottom,
        child: GestureDetector(
          onPanUpdate: onPanUpdate,
          child: MouseRegion(
            cursor: cursor,
            child: Container(
              width: _resizeHandleSize * 2,
              height: _resizeHandleSize * 2,
              color: Colors.transparent,
            ),
          ),
        ),
      );
    }

    return [
      // Right edge
      edge(right: 0, top: 0, bottom: 0, isVertical: true,
        cursor: SystemMouseCursors.resizeColumn,
        onPanUpdate: (d) => setState(() {
          _panelWidth = (_panelWidth + d.delta.dx).clamp(_minWidth, _maxWidth);
        })),
      // Bottom edge
      edge(left: 0, right: 0, bottom: 0,
        cursor: SystemMouseCursors.resizeRow,
        onPanUpdate: (d) => setState(() {
          _panelHeight = (_panelHeight + d.delta.dy).clamp(_minHeight, _maxHeight);
        })),
      // Left edge
      edge(left: 0, top: 0, bottom: 0, isVertical: true,
        cursor: SystemMouseCursors.resizeColumn,
        onPanUpdate: (d) => setState(() {
          final newW = (_panelWidth - d.delta.dx).clamp(_minWidth, _maxWidth);
          _xPos += _panelWidth - newW;
          _panelWidth = newW;
        })),
      // Top edge
      edge(left: 0, right: 0, top: 0,
        cursor: SystemMouseCursors.resizeRow,
        onPanUpdate: (d) => setState(() {
          final newH = (_panelHeight - d.delta.dy).clamp(_minHeight, _maxHeight);
          _yPos += _panelHeight - newH;
          _panelHeight = newH;
        })),
      // Bottom-right corner
      corner(right: 0, bottom: 0,
        cursor: SystemMouseCursors.resizeDownRight,
        onPanUpdate: (d) => setState(() {
          _panelWidth = (_panelWidth + d.delta.dx).clamp(_minWidth, _maxWidth);
          _panelHeight = (_panelHeight + d.delta.dy).clamp(_minHeight, _maxHeight);
        })),
      // Bottom-left corner
      corner(left: 0, bottom: 0,
        cursor: SystemMouseCursors.resizeDownLeft,
        onPanUpdate: (d) => setState(() {
          final newW = (_panelWidth - d.delta.dx).clamp(_minWidth, _maxWidth);
          _xPos += _panelWidth - newW;
          _panelWidth = newW;
          _panelHeight = (_panelHeight + d.delta.dy).clamp(_minHeight, _maxHeight);
        })),
      // Top-right corner
      corner(right: 0, top: 0,
        cursor: SystemMouseCursors.resizeUpRight,
        onPanUpdate: (d) => setState(() {
          _panelWidth = (_panelWidth + d.delta.dx).clamp(_minWidth, _maxWidth);
          final newH = (_panelHeight - d.delta.dy).clamp(_minHeight, _maxHeight);
          _yPos += _panelHeight - newH;
          _panelHeight = newH;
        })),
      // Top-left corner
      corner(left: 0, top: 0,
        cursor: SystemMouseCursors.resizeUpLeft,
        onPanUpdate: (d) => setState(() {
          final newW = (_panelWidth - d.delta.dx).clamp(_minWidth, _maxWidth);
          _xPos += _panelWidth - newW;
          _panelWidth = newW;
          final newH = (_panelHeight - d.delta.dy).clamp(_minHeight, _maxHeight);
          _yPos += _panelHeight - newH;
          _panelHeight = newH;
        })),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Total width includes editor panel when open (ability or stance, mutually exclusive)
    final hasEditor = _editingAbility != null || _editingStance != null;
    final totalWidth = hasEditor ? _panelWidth + 8.0 + 320.0 : _panelWidth;

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main codex panel wrapped in a Stack for resize handles
          Stack(
            children: [
              Container(
                width: _panelWidth,
                height: _panelHeight,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header (draggable area)
                  GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _xPos += details.delta.dx;
                        _yPos += details.delta.dy;
                        _xPos = _xPos.clamp(0.0, MediaQuery.of(context).size.width - totalWidth);
                        _yPos = _yPos.clamp(0.0, MediaQuery.of(context).size.height - _panelHeight);
                      });
                    },
                    child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.drag_indicator, color: Colors.cyan, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ABILITIES CODEX',
                              style: TextStyle(
                                color: Colors.cyan,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Hint about double-click to edit
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.cyan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.cyan, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, color: Colors.cyan, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Double-click to edit',
                                    style: TextStyle(
                                      color: Colors.cyan,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            // Hint about drag-and-drop
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app, color: Colors.orange, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Drag icons to action bar',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.gameState?.isActiveSummoned ?? false) ...[
                              SizedBox(width: 8),
                              Text('(Summoned unit \u2014 action bar locked)',
                                style: TextStyle(color: Colors.orange, fontSize: 9, fontStyle: FontStyle.italic)),
                            ],
                            SizedBox(width: 12),
                            Text(
                              'Press P to close',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(width: 12),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ),

                  // Category filter (non-scrolling)
                  _buildCategoryFilter(),

                  // Type filter (non-scrolling)
                  _buildTypeFilter(),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exotic Stances section
                          if (widget.gameState != null)
                            StanceCardsSection(
                              gameState: widget.gameState!,
                              onStateChanged: () => setState(() {}),
                              onDoubleTap: (stance) {
                                setState(() {
                                  // Reason: Close ability editor when opening stance editor (mutually exclusive)
                                  _editingAbility = null;
                                  _isCreatingNew = false;
                                  _editingStance = stance;
                                });
                              },
                            ),

                          if (widget.gameState != null)
                            SizedBox(height: 16),

                          // "+ Add New Ability" button at the top
                          _buildAddNewAbilityButton(),

                          SizedBox(height: 12),

                          // "Load Class" dropdown + button
                          _buildLoadClassRow(),

                          SizedBox(height: 16),

                          // Currently Assigned Abilities
                          if (_enabledCategories.contains('player') ||
                              _enabledCategories.contains('monster') ||
                              _enabledCategories.contains('ally'))
                            _buildSection(
                              'CURRENTLY ASSIGNED ABILITIES',
                              Colors.green,
                              [
                                if (_enabledCategories.contains('player')) ...[
                                  _buildCategoryHeader('Player Abilities', Colors.blue),
                                  ...AbilitiesConfig.playerAbilities
                                    .where((a) => _enabledTypes.contains(a.type))
                                    .map((ability) =>
                                      _buildAbilityCard(ability, Colors.blue.shade900,
                                        draggable: !(widget.gameState?.isActiveSummoned ?? false))),
                                  SizedBox(height: 16),
                                ],

                                if (_enabledCategories.contains('monster')) ...[
                                  _buildCategoryHeader('Monster Abilities', Colors.purple),
                                  ...AbilitiesConfig.monsterAbilities
                                    .where((a) => _enabledTypes.contains(a.type))
                                    .map((ability) =>
                                      _buildAbilityCard(ability, Colors.purple.shade900, draggable: false)),
                                  SizedBox(height: 16),
                                ],

                                if (_enabledCategories.contains('ally')) ...[
                                  _buildCategoryHeader('Ally Abilities', Colors.cyan),
                                  ...AbilitiesConfig.allyAbilities
                                    .where((a) => _enabledTypes.contains(a.type))
                                    .map((ability) =>
                                      _buildAbilityCard(ability, Colors.cyan.shade900, draggable: false)),
                                ],
                              ],
                            ),

                          SizedBox(height: 24),

                          // Potential Future Abilities (reorderable per category)
                          _buildSection(
                            'POTENTIAL FUTURE ABILITIES',
                            Colors.orange,
                            [
                              ...AbilitiesConfig.categories.map((category) {
                                if (!_enabledCategories.contains(category)) return SizedBox.shrink();
                                return _buildReorderableCategorySection(category);
                              }).toList(),
                              // Custom categories added via "+ Add New" in editor
                              ..._buildCustomCategorySections(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
              // Resize handles: 4 edges + 4 corners
              ..._buildResizeHandles(),
            ],
          ),
          // Editor panel (side-by-side) — ability or stance, mutually exclusive
          if (_editingAbility != null) ...[
            SizedBox(width: 8),
            AbilityEditorPanel(
              key: ValueKey('${_editingAbility!.name}_${_isCreatingNew}'),
              ability: _editingAbility!,
              isNewAbility: _isCreatingNew,
              onClose: () {
                setState(() {
                  _editingAbility = null;
                  _isCreatingNew = false;
                });
              },
              onSaved: () {
                setState(() {
                  // Refresh the codex to show updated values
                  if (_isCreatingNew) {
                    _editingAbility = null;
                    _isCreatingNew = false;
                  }
                });
              },
            ),
          ],
          if (_editingStance != null) ...[
            SizedBox(width: 8),
            StanceEditorPanel(
              key: ValueKey('stance_${_editingStance!.id.name}'),
              stance: _editingStance!,
              onClose: () {
                setState(() => _editingStance = null);
              },
              onSaved: () {
                setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }
}
