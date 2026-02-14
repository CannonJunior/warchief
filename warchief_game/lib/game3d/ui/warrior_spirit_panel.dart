import 'package:flutter/material.dart';
import '../../models/ai_chat_message.dart';

/// Warrior Spirit Panel — Chat panel for direct conversation with the Spirit.
///
/// Opened with the 'V' key. Provides:
/// - Message history with Spirit (purple) and player (gold) messages
/// - Text input field at bottom for typing messages
/// - Send button
/// - Async "Spirit is thinking..." indicator during LLM calls
///
/// Follows the same draggable pattern as [BuildingPanel].
class WarriorSpiritPanel extends StatefulWidget {
  final List<AIChatMessage> messages;
  final Future<void> Function(String) onSendMessage;
  final VoidCallback onClose;

  const WarriorSpiritPanel({
    Key? key,
    required this.messages,
    required this.onSendMessage,
    required this.onClose,
  }) : super(key: key);

  @override
  State<WarriorSpiritPanel> createState() => _WarriorSpiritPanelState();
}

class _WarriorSpiritPanelState extends State<WarriorSpiritPanel> {
  double _xPos = 80.0;
  double _yPos = 200.0;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isThinking = false;

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

    await widget.onSendMessage(text);

    if (mounted) {
      setState(() { _isThinking = false; });
    }
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
          width: 320,
          height: 350,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF6A4C9C),
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
              // Header
              _buildHeader(),

              // Message list
              Expanded(
                child: _buildMessageList(),
              ),

              // Thinking indicator
              if (_isThinking)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF9C7CCC)),
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
                ),

              // Input area
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the header bar with title and close button.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2A1F3D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF9C7CCC), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'WARRIOR SPIRIT',
              style: TextStyle(
                color: Color(0xFF9C7CCC),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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

  /// Build the scrolling message list.
  Widget _buildMessageList() {
    if (widget.messages.isEmpty) {
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
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          final reversedIndex = widget.messages.length - 1 - index;
          final message = widget.messages[reversedIndex];
          return _buildMessage(message);
        },
      ),
    );
  }

  /// Build a single message bubble.
  Widget _buildMessage(AIChatMessage message) {
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

  /// Build the input area with text field and send button.
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
