import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../ai/ollama_client.dart';
import '../../state/goals_config.dart';

/// Settings tab for configuring the Ollama AI backend.
///
/// Shows connection settings (endpoint URL + live test), the active model
/// (with a picker populated from Ollama's /api/tags), and Warrior Spirit
/// tuning values (temperature, goal interval, max active goals).
class OllamaTab extends StatefulWidget {
  const OllamaTab({Key? key}) : super(key: key);

  @override
  State<OllamaTab> createState() => _OllamaTabState();
}

class _OllamaTabState extends State<OllamaTab> {
  late TextEditingController _endpointCtrl;
  late TextEditingController _modelCtrl;

  // null = not yet tested, true = reachable, false = unreachable
  bool? _connectionStatus;
  bool _isTesting = false;
  bool _isLoadingModels = false;
  List<String> _availableModels = [];

  double _temperature = 0.8;
  double _goalInterval = 120.0;
  int _maxGoals = 5;

  // ==================== LIFECYCLE ====================

  @override
  void initState() {
    super.initState();
    final cfg = globalGoalsConfig;
    _endpointCtrl = TextEditingController(text: OllamaClient.baseUrl);
    _modelCtrl = TextEditingController(text: cfg?.warriorSpiritModel ?? 'qwen2.5:7b');
    _temperature = cfg?.warriorSpiritTemperature ?? 0.8;
    _goalInterval = cfg?.goalCheckInterval ?? 120.0;
    _maxGoals = cfg?.maxActiveGoals ?? 5;
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  // ==================== ACTIONS ====================

  Future<void> _testConnection() async {
    setState(() { _isTesting = true; _connectionStatus = null; });
    // Reason: test against the entered URL, not necessarily the live one yet
    final enteredUrl = _endpointCtrl.text.trim();
    final saved = OllamaClient.baseUrl;
    OllamaClient.baseUrl = enteredUrl;
    final ok = await OllamaClient().isAvailable();
    OllamaClient.baseUrl = saved; // restore until saved
    if (mounted) setState(() { _isTesting = false; _connectionStatus = ok; });
  }

  Future<void> _fetchModels() async {
    setState(() { _isLoadingModels = true; });
    // Use the currently entered endpoint for the fetch
    final saved = OllamaClient.baseUrl;
    OllamaClient.baseUrl = _endpointCtrl.text.trim();
    final models = await OllamaClient().listModels();
    OllamaClient.baseUrl = saved;
    if (mounted) setState(() { _availableModels = models; _isLoadingModels = false; });
  }

  Future<void> _saveAll() async {
    final endpoint = _endpointCtrl.text.trim();
    final model = _modelCtrl.text.trim();

    // Persist endpoint
    await OllamaClient.saveEndpoint(endpoint);

    // Persist Warrior Spirit fields
    final cfg = globalGoalsConfig;
    if (cfg != null) {
      if (model.isNotEmpty) cfg.setOverride('warrior_spirit.model', model);
      cfg.setOverride('warrior_spirit.temperature', _temperature);
      cfg.setOverride('warrior_spirit.goal_check_interval_seconds', _goalInterval);
      cfg.setOverride('warrior_spirit.max_active_goals', _maxGoals);
    }

    // Also save raw endpoint to SharedPreferences (in case cfg is null)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ollama_endpoint', endpoint);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ollama settings saved'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF1a3a1a),
        ),
      );
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConnectionSection(),
          const SizedBox(height: 20),
          _buildModelSection(),
          const SizedBox(height: 20),
          _buildWarriorSpiritSection(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // ==================== SECTIONS ====================

  Widget _buildConnectionSection() {
    return _section(
      title: 'CONNECTION',
      color: const Color(0xFF4cc9f0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Endpoint URL'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _endpointCtrl,
                  hint: 'http://localhost:11434',
                  onChanged: (_) => setState(() => _connectionStatus = null),
                ),
              ),
              const SizedBox(width: 8),
              _actionButton(
                label: _isTesting ? '…' : 'Test',
                onPressed: _isTesting ? null : _testConnection,
                color: const Color(0xFF4cc9f0),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _connectionStatusChip(),
        ],
      ),
    );
  }

  Widget _buildModelSection() {
    return _section(
      title: 'MODEL',
      color: const Color(0xFF9b59b6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Model Name'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _modelCtrl,
                  hint: 'e.g. qwen2.5:7b',
                ),
              ),
              const SizedBox(width: 8),
              _actionButton(
                label: _isLoadingModels ? '…' : 'Fetch',
                onPressed: _isLoadingModels ? null : _fetchModels,
                color: const Color(0xFF9b59b6),
              ),
            ],
          ),
          if (_availableModels.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label('Available on server — tap to select'),
            const SizedBox(height: 6),
            _modelList(),
          ],
        ],
      ),
    );
  }

  Widget _buildWarriorSpiritSection() {
    return _section(
      title: 'WARRIOR SPIRIT',
      color: Colors.amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Temperature  (${_temperature.toStringAsFixed(2)})'),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amber,
              thumbColor: Colors.amber,
              overlayColor: Colors.amber.withValues(alpha:0.2),
              inactiveTrackColor: const Color(0xFF3a3a5a),
            ),
            child: Slider(
              value: _temperature,
              min: 0.0,
              max: 2.0,
              divisions: 40,
              onChanged: (v) => setState(() => _temperature = v),
            ),
          ),
          const SizedBox(height: 12),
          _label('Goal Check Interval  (${_goalInterval.toStringAsFixed(0)} s)'),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amber,
              thumbColor: Colors.amber,
              overlayColor: Colors.amber.withValues(alpha:0.2),
              inactiveTrackColor: const Color(0xFF3a3a5a),
            ),
            child: Slider(
              value: _goalInterval,
              min: 30.0,
              max: 600.0,
              divisions: 57,
              onChanged: (v) => setState(() => _goalInterval = v),
            ),
          ),
          const SizedBox(height: 12),
          _label('Max Active Goals  ($_maxGoals)'),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amber,
              thumbColor: Colors.amber,
              overlayColor: Colors.amber.withValues(alpha:0.2),
              inactiveTrackColor: const Color(0xFF3a3a5a),
            ),
            child: Slider(
              value: _maxGoals.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _maxGoals = v.round()),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _section({
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF252542), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFFCCCCDD), fontSize: 12),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d1a),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF333355), width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF555577), fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: onPressed != null
              ? color.withValues(alpha:0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: onPressed != null ? color : const Color(0xFF333344),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onPressed != null ? color : const Color(0xFF555566),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _connectionStatusChip() {
    if (_connectionStatus == null) {
      return const Text(
        'Not tested',
        style: TextStyle(color: Color(0xFF666677), fontSize: 11),
      );
    }
    final ok = _connectionStatus!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ok ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          ok ? 'Connected' : 'Unreachable',
          style: TextStyle(
            color: ok ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _modelList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d1a),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF333355), width: 1),
      ),
      child: Column(
        children: _availableModels.map((model) {
          final isSelected = _modelCtrl.text.trim() == model;
          return GestureDetector(
            onTap: () => setState(() => _modelCtrl.text = model),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF9b59b6).withValues(alpha:0.15)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF252542),
                    width: model == _availableModels.last ? 0 : 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF9b59b6)
                        : const Color(0xFF555577),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    model,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFCCAAFF)
                          : const Color(0xFFAAAAAA),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _saveAll,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4cc9f0).withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4cc9f0), width: 1),
          ),
          child: const Center(
            child: Text(
              'Save Changes',
              style: TextStyle(
                color: Color(0xFF4cc9f0),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
