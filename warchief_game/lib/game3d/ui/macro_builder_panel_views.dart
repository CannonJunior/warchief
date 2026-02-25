part of 'macro_builder_panel.dart';

extension _MacroBuilderViews on _MacroBuilderPanelState {

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
