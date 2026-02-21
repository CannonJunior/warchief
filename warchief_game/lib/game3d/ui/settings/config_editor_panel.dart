import 'package:flutter/material.dart';

/// Field type for config editor entries.
enum ConfigFieldType { double_, int_, bool_, string_ }

/// Definition of a single editable field in a config section.
class ConfigFieldDef {
  final String label;
  final String dotKey;
  final ConfigFieldType type;
  final String tooltip;

  const ConfigFieldDef({
    required this.label,
    required this.dotKey,
    required this.type,
    this.tooltip = '',
  });
}

/// Definition of a section grouping related config fields.
class ConfigSectionDef {
  final String title;
  final Color color;
  final List<ConfigFieldDef> fields;

  const ConfigSectionDef({
    required this.title,
    required this.color,
    required this.fields,
  });
}

/// Callbacks for reading/writing config values.
class ConfigCallbacks {
  /// Get the current effective value for a dot-notation key.
  final dynamic Function(String key) getValue;

  /// Get the default value for a dot-notation key.
  final dynamic Function(String key) getDefault;

  /// Set a single override value.
  final void Function(String key, dynamic value) setOverride;

  /// Clear all overrides (restore defaults).
  final void Function() clearAllOverrides;

  /// Check if any overrides exist.
  final bool Function() hasAnyOverrides;

  const ConfigCallbacks({
    required this.getValue,
    required this.getDefault,
    required this.setOverride,
    required this.clearAllOverrides,
    required this.hasAnyOverrides,
  });
}

/// Generic config editor panel that renders editable sections from field
/// definitions and persists changes via config callbacks.
///
/// Follows the same visual style as AbilityEditorPanel / StanceEditorPanel.
class ConfigEditorPanel extends StatefulWidget {
  final String title;
  final List<ConfigSectionDef> sections;
  final ConfigCallbacks callbacks;
  final VoidCallback? onClose;

  const ConfigEditorPanel({
    Key? key,
    required this.title,
    required this.sections,
    required this.callbacks,
    this.onClose,
  }) : super(key: key);

  @override
  State<ConfigEditorPanel> createState() => _ConfigEditorPanelState();
}

class _ConfigEditorPanelState extends State<ConfigEditorPanel> {
  static const _bg = Color(0xFF1a1a2e);
  static const _sectionBg = Color(0xFF252542);
  static const _accent = Colors.cyan;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _boolValues = {};

  @override
  void initState() {
    super.initState();
    _populateFromConfig();
  }

  @override
  void didUpdateWidget(ConfigEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      _disposeControllers();
      _populateFromConfig();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    _controllers.clear();
    _boolValues.clear();
  }

  void _populateFromConfig() {
    for (final section in widget.sections) {
      for (final field in section.fields) {
        final value = widget.callbacks.getValue(field.dotKey);
        if (field.type == ConfigFieldType.bool_) {
          _boolValues[field.dotKey] = value is bool ? value : false;
        } else {
          final text = _formatValue(value, field.type);
          _controllers[field.dotKey] = TextEditingController(text: text);
        }
      }
    }
  }

  String _formatValue(dynamic value, ConfigFieldType type) {
    if (value == null) return '0';
    if (type == ConfigFieldType.double_) {
      return (value is num) ? value.toDouble().toString() : value.toString();
    }
    if (type == ConfigFieldType.int_) {
      return (value is num) ? value.toInt().toString() : value.toString();
    }
    return value.toString();
  }

  void _onSave() {
    for (final section in widget.sections) {
      for (final field in section.fields) {
        if (field.type == ConfigFieldType.bool_) {
          final current = _boolValues[field.dotKey] ?? false;
          final defaultVal = widget.callbacks.getDefault(field.dotKey);
          final defaultBool = defaultVal is bool ? defaultVal : false;
          if (current != defaultBool) {
            widget.callbacks.setOverride(field.dotKey, current);
          }
        } else {
          final ctrl = _controllers[field.dotKey];
          if (ctrl == null) continue;
          final text = ctrl.text.trim();
          final defaultVal = widget.callbacks.getDefault(field.dotKey);

          switch (field.type) {
            case ConfigFieldType.double_:
              final parsed = double.tryParse(text);
              if (parsed != null) {
                final defaultDouble =
                    defaultVal is num ? defaultVal.toDouble() : 0.0;
                if ((parsed - defaultDouble).abs() > 0.0001) {
                  widget.callbacks.setOverride(field.dotKey, parsed);
                }
              }
              break;
            case ConfigFieldType.int_:
              final parsed = int.tryParse(text);
              if (parsed != null) {
                final defaultInt = defaultVal is num ? defaultVal.toInt() : 0;
                if (parsed != defaultInt) {
                  widget.callbacks.setOverride(field.dotKey, parsed);
                }
              }
              break;
            case ConfigFieldType.string_:
              final defaultStr = defaultVal is String ? defaultVal : '';
              if (text != defaultStr) {
                widget.callbacks.setOverride(field.dotKey, text);
              }
              break;
            default:
              break;
          }
        }
      }
    }
    setState(() {});
  }

  void _onRestore() {
    widget.callbacks.clearAllOverrides();
    _disposeControllers();
    _populateFromConfig();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                for (final section in widget.sections)
                  _buildSection(section),
              ],
            ),
          ),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _sectionBg,
        border: Border(bottom: BorderSide(color: _accent.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, color: _accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: _accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (widget.onClose != null)
            GestureDetector(
              onTap: widget.onClose,
              child: const Icon(Icons.close, color: Colors.white54, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(ConfigSectionDef section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _sectionBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              section.title,
              style: TextStyle(
                color: section.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Column(
              children: [
                for (final field in section.fields) _buildField(field),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(ConfigFieldDef field) {
    if (field.type == ConfigFieldType.bool_) {
      return _buildSwitchRow(field);
    }
    return _buildNumericRow(field);
  }

  Widget _buildNumericRow(ConfigFieldDef field) {
    final ctrl = _controllers[field.dotKey];
    if (ctrl == null) return const SizedBox.shrink();

    final isText = field.type == ConfigFieldType.string_;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: _withTooltip(
              field.tooltip,
              Text(field.label, style: _labelStyle),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType:
                  isText ? TextInputType.text : TextInputType.number,
              style: _inputStyle,
              decoration: _inputDecoration,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(ConfigFieldDef field) {
    final value = _boolValues[field.dotKey] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: _withTooltip(
              field.tooltip,
              Text(field.label, style: _labelStyle),
            ),
          ),
          SizedBox(
            height: 24,
            child: Switch(
              value: value,
              onChanged: (v) => setState(() => _boolValues[field.dotKey] = v),
              activeColor: _accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _withTooltip(String tooltip, Widget child) {
    if (tooltip.isEmpty) return child;
    return Tooltip(
      message: tooltip,
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

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _buildButton('Save', _accent, _onSave),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton('Restore Defaults', Colors.orange, _onRestore),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  TextStyle get _labelStyle =>
      const TextStyle(color: Colors.white70, fontSize: 11);

  TextStyle get _inputStyle =>
      const TextStyle(color: Colors.white, fontSize: 11);

  InputDecoration get _inputDecoration => InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: _accent),
        ),
        filled: true,
        fillColor: Colors.black38,
      );
}
