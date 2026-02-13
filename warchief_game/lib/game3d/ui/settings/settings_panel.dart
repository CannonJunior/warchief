import 'package:flutter/material.dart';
import 'source_tree_model.dart';
import 'source_code_tab.dart';
import 'interface_config.dart';
import 'interfaces_tab.dart';

/// Settings panel with tabs for General, Interfaces, Source Code, and About
class SettingsPanel extends StatefulWidget {
  final VoidCallback onClose;
  final InterfaceConfigManager? interfaceConfig;
  final void Function(String id, bool visible)? onInterfaceVisibilityChanged;

  const SettingsPanel({
    Key? key,
    required this.onClose,
    this.interfaceConfig,
    this.onInterfaceVisibilityChanged,
  }) : super(key: key);

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  int _currentTabIndex = 0;
  SourceTreeData? _sourceTree;
  bool _isLoadingSourceTree = false;

  final List<_TabItem> _tabs = [
    _TabItem(id: 'general', label: 'General', icon: Icons.settings),
    _TabItem(id: 'interfaces', label: 'Interfaces', icon: Icons.dashboard),
    _TabItem(id: 'source', label: 'Source Code', icon: Icons.folder_open),
    _TabItem(id: 'about', label: 'About', icon: Icons.info_outline),
  ];

  @override
  void initState() {
    super.initState();
  }

  void _loadSourceTree() async {
    if (_sourceTree != null || _isLoadingSourceTree) return;

    setState(() => _isLoadingSourceTree = true);

    final data = await SourceTreeData.load();

    if (mounted) {
      setState(() {
        _sourceTree = data;
        _isLoadingSourceTree = false;
      });
    }
  }

  void _switchTab(int index) {
    setState(() => _currentTabIndex = index);

    // Lazy load source tree when switching to that tab
    if (_tabs[index].id == 'source') {
      _loadSourceTree();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Modal overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.black54,
              ),
            ),
          ),
          // Settings panel
          Center(
            child: Container(
              width: 700,
              height: 500,
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Row(
                      children: [
                        _buildSidebar(),
                        Expanded(child: _buildContent()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.settings,
            color: Color(0xFF4cc9f0),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white54),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ..._tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = _currentTabIndex == index;

            return InkWell(
              onTap: () => _switchTab(index),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4cc9f0).withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isSelected
                          ? const Color(0xFF4cc9f0)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tab.icon,
                      color: isSelected
                          ? const Color(0xFF4cc9f0)
                          : Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tab.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_tabs[_currentTabIndex].id) {
      case 'general':
        return _buildGeneralTab();
      case 'interfaces':
        return _buildInterfacesTab();
      case 'source':
        return _buildSourceTab();
      case 'about':
        return _buildAboutTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingToggle(
            'Show FPS Counter',
            'Display frames per second in the corner',
            false,
            (value) {},
          ),
          _buildSettingToggle(
            'Sound Effects',
            'Play sounds for abilities and combat',
            true,
            (value) {},
          ),
          _buildSettingToggle(
            'Show Debug Info',
            'Display debug information overlay',
            false,
            (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildInterfacesTab() {
    final config = widget.interfaceConfig;
    if (config == null) {
      return const Center(
        child: Text(
          'Interface configuration not available',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return InterfacesTab(
      interfaceConfig: config,
      onVisibilityChanged: widget.onInterfaceVisibilityChanged,
    );
  }

  Widget _buildSettingToggle(
    String label,
    String hint,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4cc9f0),
            activeTrackColor: const Color(0xFF4cc9f0).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTab() {
    if (_isLoadingSourceTree) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Color(0xFF4cc9f0)),
          SizedBox(height: 12),
          Text('Loading source tree...', style: TextStyle(color: Colors.white54)),
        ]),
      );
    }
    if (_sourceTree == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 48),
          const SizedBox(height: 12),
          const Text('Failed to load source tree', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() { _sourceTree = null; _isLoadingSourceTree = false; });
              _loadSourceTree();
            },
            child: const Text('Retry', style: TextStyle(color: Color(0xFF4cc9f0))),
          ),
        ]),
      );
    }
    return SourceCodeTab(sourceTree: _sourceTree!);
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Warchief',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildAboutItem('Version', '0.2.0'),
          _buildAboutItem('Engine', 'Flutter + Custom WebGL'),
          _buildAboutItem('Framework', 'Flame Game Engine'),
          _buildAboutItem('Platform', 'Web (WebGL 2.0)'),
          const SizedBox(height: 20),
          const Text(
            'Built With',
            style: TextStyle(
              color: Color(0xFF4cc9f0),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTechBadge('Flutter'),
              _buildTechBadge('Dart'),
              _buildTechBadge('WebGL'),
              _buildTechBadge('Flame'),
              _buildTechBadge('Riverpod'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF252542),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.code, color: Color(0xFF4cc9f0), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A WoW-inspired 3D isometric action game with AI-powered NPCs',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildTechBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4cc9f0).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4cc9f0).withValues(alpha: 0.3)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF4cc9f0), fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

/// Tab item model
class _TabItem {
  final String id;
  final String label;
  final IconData icon;

  const _TabItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
