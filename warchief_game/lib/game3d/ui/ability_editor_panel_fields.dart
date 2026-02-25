part of 'ability_editor_panel.dart';

extension _AbilityEditorPanelFields on _AbilityEditorPanelState {

  // ==================== FIELD WIDGETS ====================

  Widget _withTooltip(String tooltipKey, Widget child) {
    final tip = _tooltips[tooltipKey];
    if (tip == null) return child;
    return Tooltip(
      message: tip,
      preferBelow: false,
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      decoration: BoxDecoration(
        color: const Color(0xDD1a1a2e),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.cyan.withOpacity(0.5)),
      ),
      waitDuration: const Duration(milliseconds: 400),
      child: child,
    );
  }

  Widget _buildReadOnlyField(String label, String value, String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      String tooltipKey, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(width: 80, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          Expanded(
            child: TextField(
              controller: ctrl, maxLines: multiline ? 2 : 1,
              style: _inputStyle, decoration: _inputDecoration),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericRow(String label, TextEditingController ctrl, String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          Expanded(
            child: TextField(
              controller: ctrl, keyboardType: TextInputType.number,
              style: _inputStyle, decoration: _inputDecoration),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, TextEditingController rCtrl,
      TextEditingController gCtrl, TextEditingController bCtrl, String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          _colorField('R', rCtrl),
          const SizedBox(width: 4),
          _colorField('G', gCtrl),
          const SizedBox(width: 4),
          _colorField('B', bCtrl),
        ],
      ),
    );
  }

  Widget _colorField(String hint, TextEditingController ctrl) {
    return Expanded(
      child: TextField(
        controller: ctrl, keyboardType: TextInputType.number,
        style: _inputStyle, decoration: _inputDecoration.copyWith(hintText: hint)),
    );
  }

  /// Dropdown with "+ Add New" option at the bottom
  Widget _buildDropdownWithAddNew({
    required String label,
    required String tooltipKey,
    required List<String> builtInValues,
    required String customKey,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final customValues = globalCustomOptionsManager?.getCustomValues(customKey) ?? [];
    // Combine built-in + custom (avoid duplicates)
    final allValues = [...builtInValues];
    for (final cv in customValues) {
      if (!allValues.contains(cv)) allValues.add(cv);
    }
    // Ensure selected value is in list
    if (!allValues.contains(selectedValue)) allValues.add(selectedValue);

    const addNewSentinel = '__add_new__';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                dropdownColor: _editorBg,
                underline: const SizedBox.shrink(),
                iconSize: 16,
                iconEnabledColor: Colors.white54,
                style: _inputStyle,
                items: [
                  ...allValues.map((v) {
                    final isCustom = globalCustomOptionsManager?.isCustomValue(customKey, v) ?? false;
                    return DropdownMenuItem<String>(
                      value: v,
                      child: Text(v, style: _inputStyle.copyWith(
                        color: isCustom ? Colors.yellow : Colors.white)),
                    );
                  }),
                  // Separator + Add New
                  DropdownMenuItem<String>(
                    value: addNewSentinel,
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text('+ Add New', style: _inputStyle.copyWith(color: Colors.green)),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == addNewSentinel) {
                    _showAddNewDialog(customKey, label, onChanged);
                  } else if (v != null) {
                    onChanged(v);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog for adding a new dropdown value
  void _showAddNewDialog(String customKey, String label, ValueChanged<String> onChanged) {
    final controller = TextEditingController();
    final secondaryEffects = CustomOptionsManager.getSecondaryEffectsInfo(customKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _editorBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _editorAccent, width: 2)),
        title: Text('Add New $label', style: const TextStyle(color: _editorAccent, fontSize: 14)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Enter new ${label.toLowerCase()} name...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true, fillColor: Colors.black38,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Secondary Effects:',
                      style: TextStyle(color: Colors.orange, fontSize: 10,
                        fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(secondaryEffects,
                      style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              final value = controller.text.trim().toLowerCase().replaceAll(' ', '_');
              if (value.isNotEmpty) {
                globalCustomOptionsManager?.addCustomValue(customKey, value);
                onChanged(value);
                Navigator.of(ctx).pop();
                setState(() {}); // Refresh dropdowns
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.green))),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged,
      String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 150, child: _withTooltip(tooltipKey,
            Text(label, style: _labelStyle))),
          SizedBox(
            height: 24,
            child: Switch(
              value: value, onChanged: onChanged,
              activeColor: _editorAccent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
        ],
      ),
    );
  }

  // ==================== STYLES ====================

  TextStyle get _labelStyle => const TextStyle(
    color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold);

  TextStyle get _inputStyle => const TextStyle(color: Colors.white, fontSize: 11);

  InputDecoration get _inputDecoration => const InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    filled: true, fillColor: Colors.black38,
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white24),
      borderRadius: BorderRadius.all(Radius.circular(3))),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white24),
      borderRadius: BorderRadius.all(Radius.circular(3))),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.cyan),
      borderRadius: BorderRadius.all(Radius.circular(3))),
  );
}
