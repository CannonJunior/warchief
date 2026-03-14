import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../state/combo_config.dart';
import 'character_panel.dart';
import 'character_side_panel.dart';
import 'character_combo_panel.dart';

/// Hosts [CharacterPanel] and its expandable side panels inside a single
/// [Positioned] widget, so they all move together when dragged.
///
/// The host owns the panel position ([_xPos], [_yPos]) and passes drag
/// deltas down to [CharacterPanel] via [CharacterPanel.onDragDelta].
///
/// Side-panel open state:
/// - **Explicit open**: user clicks the ✦ button in [CharacterPanel]'s header.
/// - **Soft pin**: automatically re-opened whenever this host is mounted.
/// - **Hard pin**: persists outside this widget (game_state + independent overlay).
class CharacterPanelHost extends StatefulWidget {
  final VoidCallback onClose;
  final GameState gameState;
  final int initialIndex;

  const CharacterPanelHost({
    super.key,
    required this.onClose,
    required this.gameState,
    required this.initialIndex,
  });

  @override
  State<CharacterPanelHost> createState() => _CharacterPanelHostState();
}

class _CharacterPanelHostState extends State<CharacterPanelHost> {
  double _xPos = 100.0;
  double _yPos = 80.0;

  /// Whether the user has explicitly toggled the combo panel open this session.
  bool _comboExplicitOpen = false;

  /// Which character carousel index is currently showing — mirrors the
  /// value tracked inside CharacterPanel so we can pass it to CombosPanel.
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Soft-pinned panels open automatically with the character sheet.
    _comboExplicitOpen = widget.gameState.comboSidePanelSoftPinned;
  }

  /// The combo panel is visible when explicitly opened OR soft-pinned.
  bool get _comboPanelOpen =>
      _comboExplicitOpen || widget.gameState.comboSidePanelSoftPinned;

  /// Resolve AbilityRegistry category string from carousel index.
  String get _currentCategory {
    if (_currentIndex == 0) return 'player';
    final allies = widget.gameState.allies;
    if (_currentIndex - 1 < allies.length) {
      return allyIndexToCategory(allies[_currentIndex - 1].abilityIndex);
    }
    return 'player';
  }

  void _onDragDelta(Offset delta, Size screenSize) {
    setState(() {
      _xPos = (_xPos + delta.dx)
          .clamp(0.0, screenSize.width - 750);
      _yPos = (_yPos + delta.dy)
          .clamp(0.0, screenSize.height - SidePanelShell.panelHeight);
    });
  }

  void _toggleSoftPin() {
    setState(() {
      widget.gameState.comboSidePanelSoftPinned =
          !widget.gameState.comboSidePanelSoftPinned;
      // Soft-pin on → open the panel; soft-pin off → just unpin (keep open).
      if (widget.gameState.comboSidePanelSoftPinned) {
        _comboExplicitOpen = true;
      }
    });
  }

  void _toggleHardPin() {
    setState(() {
      widget.gameState.comboSidePanelHardPinned =
          !widget.gameState.comboSidePanelHardPinned;
      // Reason: hard pin implies soft pin — the panel must also re-open
      // with the character sheet, otherwise the hard-pin handoff to the
      // standalone overlay won't have a matching panel to show.
      if (widget.gameState.comboSidePanelHardPinned) {
        widget.gameState.comboSidePanelSoftPinned = true;
        _comboExplicitOpen = true;
      }
    });
  }

  void _closeComboPanel() {
    setState(() {
      _comboExplicitOpen = false;
      widget.gameState.comboSidePanelSoftPinned = false;
      widget.gameState.comboSidePanelHardPinned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Core character panel ──────────────────────────────────────
          CharacterPanel(
            embedded: true,
            gameState: widget.gameState,
            initialIndex: widget.initialIndex,
            onClose: widget.onClose,
            onDragDelta: (delta) => _onDragDelta(delta, screenSize),
            onCurrentIndexChanged: (i) =>
                setState(() => _currentIndex = i),
            onToggleComboPanel: () =>
                setState(() => _comboExplicitOpen = !_comboExplicitOpen),
            comboPanelOpen: _comboPanelOpen,
          ),

          // ── Combo side panel ─────────────────────────────────────────
          SidePanelShell(
            title: 'COMBOS',
            icon: Icons.link,
            isOpen: _comboPanelOpen,
            softPinned: widget.gameState.comboSidePanelSoftPinned,
            hardPinned: widget.gameState.comboSidePanelHardPinned,
            onToggleSoftPin: _toggleSoftPin,
            onToggleHardPin: _toggleHardPin,
            onClose: _closeComboPanel,
            child: CombosPanel(
              category: _currentCategory,
              comboConfig: globalComboConfig,
            ),
          ),
        ],
      ),
    );
  }
}
