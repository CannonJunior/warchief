import 'package:flutter/material.dart';
import '../../models/macro.dart';
import '../../models/ally.dart';
import '../ai/ally_strategy.dart';
import '../state/game_state.dart';
import '../state/macro_config.dart';
import '../state/macro_manager.dart';
import '../systems/macro_system.dart';
import 'macro_step_list.dart';

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

  // ==================== LIST VIEW ====================

  Widget _buildListView() {
    final macros = _macros;

    return Column(
      children: [
        // Active macro indicator
        if (_isRunning)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.green.withOpacity(0.15),
            child: Row(
              children: [
                Icon(Icons.play_circle_fill,
                    color: Colors.greenAccent, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Macro running on $_charName',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _stopMacro,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('STOP',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

        // Macro list
        Expanded(
          child: macros.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.queue_music,
                          color: Colors.white24, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'No macros yet',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create one to automate spell rotations',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  itemCount: macros.length,
                  itemBuilder: (ctx, i) =>
                      _buildMacroRow(macros[i]),
                ),
        ),

        // Create new macro button
        Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => _openEditor(null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Create New Macro',
                  style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.2),
                foregroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: Colors.amber.withOpacity(0.4)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroRow(Macro macro) {
    final gcd = globalMacroConfig?.gcdBase ?? 1.5;
    final duration = macro.estimatedDuration(gcd);
    final durationStr = duration < 60
        ? '${duration.toStringAsFixed(1)}s'
        : '${(duration / 60).toStringAsFixed(1)}m';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Macro info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        macro.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (macro.loop) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.loop,
                          size: 12, color: Colors.cyan.withOpacity(0.7)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${macro.steps.length} steps  ·  ${macro.abilityStepCount} abilities  ·  ~$durationStr',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          _macroActionButton(
            icon: Icons.play_arrow,
            color: Colors.greenAccent,
            tooltip: 'Play',
            onTap: () => _playMacro(macro),
          ),
          const SizedBox(width: 4),
          _macroActionButton(
            icon: Icons.edit,
            color: Colors.cyanAccent,
            tooltip: 'Edit',
            onTap: () => _openEditor(macro),
          ),
          const SizedBox(width: 4),
          _macroActionButton(
            icon: Icons.delete_outline,
            color: Colors.redAccent,
            tooltip: 'Delete',
            onTap: () => _deleteMacro(macro),
          ),
        ],
      ),
    );
  }

  Widget _macroActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  // ==================== EDITOR VIEW ====================

  Widget _buildEditorView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                const Text('Name',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _nameController,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      hintText: 'Macro name...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Loop toggle
                Row(
                  children: [
                    const Text('Loop',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: _loop,
                        onChanged: (v) => setState(() => _loop = v),
                        activeColor: Colors.amber,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    if (_loop) ...[
                      const SizedBox(width: 12),
                      const Text('Count: ',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 11)),
                      SizedBox(
                        width: 50,
                        height: 24,
                        child: TextField(
                          controller: _loopCountController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            hintText: '∞',
                            hintStyle:
                                const TextStyle(color: Colors.white24),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                  color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                  color: Colors.white24),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            _loopCount =
                                v.isEmpty ? null : int.tryParse(v);
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _loopCount == null ? '(infinite)' : 'loops',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Steps header
                Row(
                  children: [
                    const Text('STEPS',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        )),
                    const Spacer(),
                    Text(
                      '${_steps.length} step${_steps.length != 1 ? "s" : ""}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Step list + add form
                MacroStepList(
                  steps: _steps,
                  onStepsChanged: (updated) {
                    setState(() => _steps = updated);
                  },
                ),
              ],
            ),
          ),
        ),

        // Footer: Save + Cancel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(9)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: _closeEditor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: _saveMacro,
                    icon: const Icon(Icons.save, size: 14),
                    label: const Text('Save',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.withOpacity(0.3),
                      foregroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
