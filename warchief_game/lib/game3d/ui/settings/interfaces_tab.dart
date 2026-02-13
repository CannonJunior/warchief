import 'package:flutter/material.dart';
import 'interface_config.dart';

/// Interfaces tab showing categorized UI panel visibility controls
///
/// Displays interface registrations grouped by category (Game Abilities,
/// UI Panels) with shortcut key badges, expandable details, and
/// quick action chips.
class InterfacesTab extends StatefulWidget {
  final InterfaceConfigManager interfaceConfig;
  final void Function(String id, bool visible)? onVisibilityChanged;

  const InterfacesTab({
    Key? key,
    required this.interfaceConfig,
    this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<InterfacesTab> createState() => _InterfacesTabState();
}

class _InterfacesTabState extends State<InterfacesTab> {
  final Set<String> _expandedInterfaces = {};

  @override
  Widget build(BuildContext context) {
    final config = widget.interfaceConfig;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Text(
                'Interface Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildActionButton(
                icon: Icons.save,
                label: 'Save Layout',
                color: const Color(0xFF4CAF50),
                onPressed: () async {
                  final success = await config.saveConfig();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Layout saved!'
                            : 'Failed to save layout'),
                        backgroundColor:
                            success ? const Color(0xFF4CAF50) : Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.refresh,
                label: 'Reset All',
                color: const Color(0xFFFF6B6B),
                onPressed: () {
                  config.resetAllPositions();
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Toggle interface visibility and save positions as defaults',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Quick actions
          Row(
            children: [
              _buildQuickActionChip(
                label: 'Show All',
                icon: Icons.visibility,
                onPressed: () {
                  config.showAll();
                  setState(() {});
                },
              ),
              const SizedBox(width: 8),
              _buildQuickActionChip(
                label: 'Hide Optional',
                icon: Icons.visibility_off,
                onPressed: () {
                  config.hideAllOptional();
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Categorized interface list
          for (final categoryId in config.categories) ...[
            _buildCategoryHeader(config.categoryLabel(categoryId)),
            const SizedBox(height: 8),
            ...config.interfacesForCategory(categoryId).map(
              (iface) => _buildInterfaceItem(iface),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  /// Category header with cyan label and divider line
  Widget _buildCategoryHeader(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4cc9f0),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF4cc9f0).withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  /// Single interface item with expand/collapse, shortcut badge, and toggle
  Widget _buildInterfaceItem(InterfaceConfig iface) {
    final isExpanded = _expandedInterfaces.contains(iface.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: iface.isVisible
              ? const Color(0xFF4cc9f0).withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header row (always visible)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedInterfaces.remove(iface.id);
                } else {
                  _expandedInterfaces.add(iface.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Expand/collapse icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  // Interface icon
                  Icon(
                    iface.icon,
                    color: iface.isVisible
                        ? const Color(0xFF4cc9f0)
                        : Colors.white38,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  // Name
                  Expanded(
                    child: Text(
                      iface.name,
                      style: TextStyle(
                        color: iface.isVisible ? Colors.white : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Shortcut key badge
                  if (iface.shortcutKey != null) ...[
                    _buildShortcutBadge(iface.shortcutKey!),
                    const SizedBox(width: 8),
                  ],
                  // Visibility toggle
                  Switch(
                    value: iface.isVisible,
                    onChanged: (value) {
                      widget.interfaceConfig.setVisibility(iface.id, value);
                      setState(() {});
                      widget.onVisibilityChanged?.call(iface.id, value);
                    },
                    activeColor: const Color(0xFF4cc9f0),
                    activeTrackColor:
                        const Color(0xFF4cc9f0).withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
          // Expanded details
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    iface.description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.place, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Position: (${iface.position.dx.toStringAsFixed(0)}, ${iface.position.dy.toStringAsFixed(0)})',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          widget.interfaceConfig.resetPosition(iface.id);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1a2e),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.restart_alt,
                                color: Colors.white54,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Reset Position',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Monospace shortcut key badge (e.g. [P], [SHIFT+D])
  Widget _buildShortcutBadge(String key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        key,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
