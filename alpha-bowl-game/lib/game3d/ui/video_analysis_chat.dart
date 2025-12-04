import 'package:flutter/material.dart';

/// Video Analysis Chat Message
class VideoAnalysisMessage {
  final String text;
  final DateTime timestamp;
  final bool isSystem;

  VideoAnalysisMessage({
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });
}

/// Video Analysis Chat Panel - Shows AI analysis of football videos
///
/// Opened with the 'C' key, this panel displays:
/// - Video analysis results from the "Make Play" button
/// - Formation descriptions
/// - Player positions and routes
class VideoAnalysisChatPanel extends StatefulWidget {
  final VoidCallback onClose;
  final List<VideoAnalysisMessage> messages;
  final Function(String)? onSendMessage;

  const VideoAnalysisChatPanel({
    Key? key,
    required this.onClose,
    required this.messages,
    this.onSendMessage,
  }) : super(key: key);

  @override
  State<VideoAnalysisChatPanel> createState() => _VideoAnalysisChatPanelState();
}

class _VideoAnalysisChatPanelState extends State<VideoAnalysisChatPanel> {
  double _xPos = 100.0;
  double _yPos = 100.0;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoAnalysisChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new messages arrive
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && widget.onSendMessage != null) {
      widget.onSendMessage!(text);
      _messageController.clear();
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
            // Clamp position to screen bounds
            _xPos = _xPos.clamp(0.0, MediaQuery.of(context).size.width - 600);
            _yPos = _yPos.clamp(0.0, MediaQuery.of(context).size.height - 500);
          });
        },
        child: Container(
          width: 600,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header (draggable area)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.drag_indicator, color: Colors.purple, size: 20),
                        SizedBox(width: 8),
                        Icon(Icons.video_library, color: Colors.purple, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'VIDEO ANALYSIS CHAT',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Press C to close',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Messages Area
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: widget.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.purple.withOpacity(0.5),
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No video analysis yet',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Select a video in the Video Panel (V) and click "Make Play"',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: widget.messages.length,
                          itemBuilder: (context, index) {
                            final message = widget.messages[index];
                            return _buildMessage(message);
                          },
                        ),
                ),
              ),

              // Input Area (optional - for future interactive queries)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  border: Border(
                    top: BorderSide(color: Colors.purple, width: 1),
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask about the video... (Coming soon)',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.purple),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.purple.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.purple, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          enabled: false, // Disabled for now
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.purple.withOpacity(0.3)),
                      onPressed: null, // Disabled for now
                      tooltip: 'Coming soon',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(VideoAnalysisMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isSystem
            ? Colors.purple.shade900.withOpacity(0.3)
            : Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: message.isSystem
              ? Colors.purple.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message header
          Row(
            children: [
              Icon(
                message.isSystem ? Icons.smart_toy : Icons.person,
                color: message.isSystem ? Colors.purple : Colors.cyan,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                message.isSystem ? 'Video Analyzer' : 'You',
                style: TextStyle(
                  color: message.isSystem ? Colors.purple : Colors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Message text
          Text(
            message.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
