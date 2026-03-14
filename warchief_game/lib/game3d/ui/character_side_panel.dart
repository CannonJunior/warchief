import 'package:flutter/material.dart';

// ==================== CONSTANTS ====================

const Color _kPanelBg    = Color(0xFF1a1a2e);
const Color _kHeaderBg   = Color(0xFF0f0f1e);
const Color _kAccent     = Color(0xFF4cc9f0);
const Color _kBorder     = Color(0xFF4cc9f0);
const Color _kSoftPin    = Color(0xFFFFD700); // gold — soft pin active
const Color _kHardPin    = Color(0xFF4cc9f0); // cyan — hard pin active

/// Animated side-panel shell that attaches to the right of [CharacterPanel].
///
/// Expand/collapse is driven by the parent via [isOpen].
/// The header contains soft-pin and hard-pin toggle buttons.
///
/// - **Soft pin** (📌): panel re-opens whenever the character sheet opens.
/// - **Hard pin** (🔒): panel stays open even when the character sheet closes.
///   Activating hard pin also forces soft pin on.
class SidePanelShell extends StatelessWidget {
  /// Label shown in the header bar.
  final String title;

  /// Icon shown next to the title.
  final IconData icon;

  /// Scrollable body content.
  final Widget child;

  /// When false the panel collapses to zero width.
  final bool isOpen;

  /// True when soft-pinned (opens with character sheet).
  final bool softPinned;

  /// True when hard-pinned (stays open independently).
  final bool hardPinned;

  final VoidCallback onToggleSoftPin;
  final VoidCallback onToggleHardPin;

  /// Called when the user presses the ✕ button in the header.
  final VoidCallback? onClose;

  /// Fixed panel width when open.
  static const double panelWidth = 300.0;

  /// Fixed panel height — matches CharacterPanel height so they align.
  static const double panelHeight = 560.0;

  const SidePanelShell({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.isOpen,
    required this.softPinned,
    required this.hardPinned,
    required this.onToggleSoftPin,
    required this.onToggleHardPin,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: isOpen ? panelWidth : 0.0,
      height: panelHeight,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: panelWidth,
          minWidth: panelWidth,
          child: Container(
            width: panelWidth,
            height: panelHeight,
            decoration: BoxDecoration(
              color: _kPanelBg,
              border: Border(
                top:    BorderSide(color: _kBorder, width: 2),
                right:  BorderSide(color: _kBorder, width: 2),
                bottom: BorderSide(color: _kBorder, width: 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _kHeaderBg,
        border: Border(
          bottom: BorderSide(color: _kBorder.withValues(alpha: 0.4), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kAccent, size: 14),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: _kAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          // Soft-pin toggle
          Tooltip(
            message: softPinned
                ? 'Soft pinned — opens with character sheet'
                : 'Soft pin — re-open when character sheet opens',
            preferBelow: false,
            child: InkWell(
              onTap: onToggleSoftPin,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  softPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 15,
                  color: softPinned ? _kSoftPin : Colors.white38,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          // Hard-pin toggle
          Tooltip(
            message: hardPinned
                ? 'Hard pinned — stays open when character sheet closes'
                : 'Hard pin — keep open independently',
            preferBelow: false,
            child: InkWell(
              onTap: onToggleHardPin,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  hardPinned ? Icons.lock : Icons.lock_outline,
                  size: 15,
                  color: hardPinned ? _kHardPin : Colors.white38,
                ),
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
