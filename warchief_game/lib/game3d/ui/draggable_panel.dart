import 'package:flutter/material.dart';

/// A draggable panel wrapper that allows any child widget to be dragged around the screen
class DraggablePanel extends StatefulWidget {
  final Widget child;
  final Offset initialPosition;
  final String? panelId; // For saving/restoring position
  final VoidCallback? onClose;
  final bool showCloseButton;

  const DraggablePanel({
    Key? key,
    required this.child,
    required this.initialPosition,
    this.panelId,
    this.onClose,
    this.showCloseButton = true,
  }) : super(key: key);

  @override
  State<DraggablePanel> createState() => _DraggablePanelState();
}

class _DraggablePanelState extends State<DraggablePanel> {
  late Offset _position;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        child: MouseRegion(
          cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: _isDragging
                  ? [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                widget.child,
                // Close button
                if (widget.showCloseButton && widget.onClose != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: InkWell(
                      onTap: widget.onClose,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Drag indicator
                Positioned(
                  top: 2,
                  left: 2,
                  child: Icon(
                    Icons.drag_indicator,
                    size: 12,
                    color: Colors.white30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
