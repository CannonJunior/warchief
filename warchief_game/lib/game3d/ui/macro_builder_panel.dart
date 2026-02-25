import 'package:flutter/material.dart';
import '../../models/macro.dart';
import '../../models/ally.dart';
import '../ai/ally_strategy.dart';
import '../state/game_state.dart';
import '../state/macro_config.dart';
import '../state/macro_manager.dart';
import '../systems/macro_system.dart';
import 'macro_step_list.dart';

part 'macro_builder_panel_views.dart';

/// Main Macro Builder panel widget.
///
/// Two modes: **list view** (default) showing saved macros for the active
/// character, and **editor view** for creating/editing a macro. Draggable,
/// dark themed, 420x520.
class MacroBuilderPanel extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onClose;
  final VoidCallback onMacroStarted;

  const MacroBuilderPanel({
    Key? key,
    required this.gameState,
    required this.onClose,
    required this.onMacroStarted,
  }) : super(key: key);

  @override
  State<MacroBuilderPanel> createState() => _MacroBuilderPanelState();
}

class _MacroBuilderPanelState extends State<MacroBuilderPanel> {
  double _xPos = 120.0;
  double _yPos = 80.0;

  // View modes
  bool _isEditing = false;
  Macro? _editingMacro; // null = creating new

  // Editor state
  final TextEditingController _nameController = TextEditingController();
  bool _loop = false;
  int? _loopCount;
  List<MacroStep> _steps = [];
  final TextEditingController _loopCountController = TextEditingController();

  int get _charIndex => widget.gameState.activeCharacterIndex;

  /// Character display name matching Character Panel format:
  /// 'Warchief · Lv10 Warrior · "The Commander"'
  /// 'Ally N · LvX Class · "Title"'
  String get _charName {
    if (_charIndex == 0) {
      return 'Warchief · Lv10 Warrior · "The Commander"';
    }
    final allyIdx = _charIndex - 1;
    if (allyIdx < widget.gameState.allies.length) {
      final ally = widget.gameState.allies[allyIdx];
      final cls = _getAllyClass(ally);
      final title = _getAllyTitle(ally);
      return 'Ally $_charIndex · Lv${5 + _charIndex} $cls · "$title"';
    }
    return 'Ally $_charIndex';
  }

  String _getAllyClass(Ally ally) {
    switch (ally.abilityIndex) {
      case 0: return 'Fighter';
      case 1: return 'Mage';
      case 2: return 'Healer';
      default: return 'Fighter';
    }
  }

  String _getAllyTitle(Ally ally) {
    switch (ally.strategyType) {
      case AllyStrategyType.aggressive: return 'The Berserker';
      case AllyStrategyType.defensive: return 'The Guardian';
      case AllyStrategyType.support: return 'The Protector';
      case AllyStrategyType.balanced: return 'The Companion';
      case AllyStrategyType.berserker: return 'The Reckless';
    }
  }

  List<Macro> get _macros =>
      globalMacroManager?.getMacrosForCharacter(_charIndex) ?? [];

  bool get _isRunning => MacroSystem.isRunningOnCharacter(_charIndex);

  @override
  void dispose() {
    _nameController.dispose();
    _loopCountController.dispose();
    super.dispose();
  }

  // ==================== EDITOR HELPERS ====================

  void _openEditor(Macro? macro) {
    setState(() {
      _isEditing = true;
      _editingMacro = macro;
      if (macro != null) {
        _nameController.text = macro.name;
        _loop = macro.loop;
        _loopCount = macro.loopCount;
        _loopCountController.text =
            macro.loopCount?.toString() ?? '';
        _steps = List<MacroStep>.from(macro.steps);
      } else {
        _nameController.text = '';
        _loop = false;
        _loopCount = null;
        _loopCountController.text = '';
        _steps = [];
      }
    });
  }

  void _closeEditor() {
    setState(() {
      _isEditing = false;
      _editingMacro = null;
    });
  }

  void _saveMacro() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_steps.isEmpty) return;

    final id = _editingMacro?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final macro = Macro(
      id: id,
      name: name,
      steps: List<MacroStep>.from(_steps),
      loop: _loop,
      loopCount: _loop ? _loopCount : null,
    );

    globalMacroManager?.saveMacro(_charIndex, macro);
    _closeEditor();
  }

  void _deleteMacro(Macro macro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Delete Macro',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${macro.name}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              globalMacroManager?.deleteMacro(_charIndex, macro.id);
              setState(() {});
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _playMacro(Macro macro) {
    MacroSystem.startMacro(macro, _charIndex, widget.gameState);
    widget.onMacroStarted();
    setState(() {});
  }

  void _stopMacro() {
    MacroSystem.stopMacro(_charIndex);
    setState(() {});
  }

  // ==================== BUILD ====================

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
          });
        },
        child: Container(
          width: 420,
          height: 520,
          decoration: BoxDecoration(
            color: const Color(0xF01a1a2e),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isRunning
                  ? Colors.green.withOpacity(0.6)
                  : Colors.amber.withOpacity(0.4),
              width: _isRunning ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isRunning ? Colors.green : Colors.black)
                    .withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isEditing ? _buildEditorView() : _buildListView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
      ),
      child: Row(
        children: [
          if (_isEditing) ...[
            InkWell(
              onTap: _closeEditor,
              child: const Icon(Icons.arrow_back,
                  color: Colors.white54, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            _isEditing ? Icons.edit : Icons.queue_music,
            color: Colors.amber,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isEditing
                  ? (_editingMacro != null
                      ? 'EDIT: ${_editingMacro!.name}'
                      : 'NEW MACRO')
                  : 'MACRO BUILDER',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_isEditing) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _charName,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          InkWell(
            onTap: widget.onClose,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close,
                  size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
