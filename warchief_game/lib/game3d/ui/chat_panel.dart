import 'package:flutter/material.dart';
import '../../models/ai_chat_message.dart';
import '../../models/raid_chat_message.dart';
import '../../models/combat_log_entry.dart';
import 'raid_chat.dart';
import 'combat_log_tab.dart';

/// Unified tabbed chat panel with Spirit and Raid Chat tabs.
///
/// Replaces the standalone [WarriorSpiritPanel] as the main chat
/// interface. Opened with the backtick key.
///
/// **Spirit tab** (purple): Interactive chat with the Warrior Spirit.
/// **Raid tab** (orange): System-generated combat alerts (read-only).
class ChatPanel extends StatefulWidget {
  final List<AIChatMessage> spiritMessages;
  final Future<void> Function(String) onSendSpiritMessage;
  final List<RaidChatMessage> raidMessages;
  final List<CombatLogEntry> combatLogMessages;
  final int initialTab;
  final VoidCallback onClose;
  final void Function(int)? onTabChanged;

  const ChatPanel({
    Key? key,
    required this.spiritMessages,
    required this.onSendSpiritMessage,
    required this.raidMessages,
    required this.combatLogMessages,
    this.initialTab = 0,
    required this.onClose,
    this.onTabChanged,
  }) : super(key: key);

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  double _xPos = 80.0;
  double _yPos = 200.0;
  late int _activeTab;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _textController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isThinking) return;

    _textController.clear();
    setState(() { _isThinking = true; });

    await widget.onSendSpiritMessage(text);

    if (mounted) {
      setState(() { _isThinking = false; });
    }
  }

  void _switchTab(int tab) {
    setState(() { _activeTab = tab; });
    widget.onTabChanged?.call(tab);
  }

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
          width: 340,
          height: 400,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _activeTab == 0
                  ? const Color(0xFF6A4C9C)   // Purple for Spirit
                  : _activeTab == 1
                      ? const Color(0xFFCC7722)   // Orange for Raid
                      : const Color(0xFFCC3333),  // Red for Combat
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with tabs
              _buildHeader(),

              // Tab content
              Expanded(
                child: _activeTab == 0
                    ? _buildSpiritTab()
                    : _activeTab == 1
                        ? RaidChatTab(messages: widget.raidMessages)
                        : CombatLogTab(messages: widget.combatLogMessages),
              ),

              // Thinking indicator (Spirit tab only)
              if (_activeTab == 0 && _isThinking)
                _buildThinkingIndicator(),

              // Input area (Spirit tab only)
              if (_activeTab == 0)
                _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  /// Header bar with title, tab buttons, and close button.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF2A1F3D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          // Tab: Spirit
          _buildTabButton(
            index: 0,
            icon: Icons.auto_awesome,
            label: 'Spirit',
            activeColor: const Color(0xFF9C7CCC),
          ),
          const SizedBox(width: 6),
          // Tab: Raid
          _buildTabButton(
            index: 1,
            icon: Icons.campaign,
            label: 'Raid',
            activeColor: const Color(0xFFCC7722),
          ),
          const SizedBox(width: 6),
          // Tab: Combat
          _buildTabButton(
            index: 2,
            icon: Icons.menu_book,
            label: 'Combat',
            activeColor: const Color(0xFFCC3333),
          ),
          const Spacer(),
          // Close button
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFFFF6B6B),
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Individual tab button.
  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isActive = _activeTab == index;
    final color = isActive ? activeColor : const Color(0xFF666666);
    final bgColor = isActive
        ? activeColor.withValues(alpha: 0.15)
        : Colors.transparent;

    return GestureDetector(
      onTap: () => _switchTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: isActive
              ? Border.all(color: activeColor.withValues(alpha: 0.4), width: 1)
              : null,
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
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Spirit tab: message list.
  Widget _buildSpiritTab() {
    if (widget.spiritMessages.isEmpty) {
      return const Center(
        child: Text(
          'The spirit awaits...',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(8),
        itemCount: widget.spiritMessages.length,
        itemBuilder: (context, index) {
          final reversedIndex = widget.spiritMessages.length - 1 - index;
          final message = widget.spiritMessages[reversedIndex];
          return _buildSpiritMessage(message);
        },
      ),
    );
  }

  /// Build a single spirit message bubble.
  Widget _buildSpiritMessage(AIChatMessage message) {
    final isPlayer = message.isInput;
    final arrowChar = isPlayer ? '\u2192 ' : '\u2190 ';
    final color = isPlayer
        ? const Color(0xFFD4A76A) // Gold for player
        : const Color(0xFF9C7CCC); // Purple for spirit

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arrowChar,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              message.text,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Spirit is thinking..." indicator.
  Widget _buildThinkingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C7CCC)),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Spirit is thinking...',
            style: TextStyle(
              color: Color(0xFF9C7CCC),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Text input area for Spirit tab.
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFF252542),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _textController,
                focusNode: _inputFocusNode,
                style: const TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 11,
                ),
                decoration: InputDecoration(
                  hintText: 'Speak to the Spirit...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1a1a2e),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF3a3a5c)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF3a3a5c)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF9C7CCC)),
                  ),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isThinking ? null : _handleSend,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isThinking
                      ? const Color(0xFF444444)
                      : const Color(0xFF6A4C9C).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _isThinking
                        ? const Color(0xFF555555)
                        : const Color(0xFF9C7CCC),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Send',
                  style: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
