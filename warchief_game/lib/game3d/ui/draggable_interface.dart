/// Draggable Interface Wrapper
///
/// A reusable widget that wraps any interface panel and makes it draggable.
/// Uses InterfaceConfigManager to persist positions and respect lock state.

import 'package:flutter/material.dart';
import 'settings/interface_config.dart';

/// Wrapper that makes any widget draggable based on interface config
class DraggableInterface extends StatefulWidget {
  /// The interface ID from InterfaceConfigManager
  final String interfaceId;

  /// The interface config manager
  final InterfaceConfigManager? configManager;

  /// The child widget to make draggable
  final Widget child;

  /// Whether to use bottom positioning (true) or top positioning (false)
  final bool useBottomPosition;

  /// Whether to use right positioning (true) or left positioning (false)
  final bool useRightPosition;

  /// Optional callback when position changes
  final void Function(Offset newPosition)? onPositionChanged;

  /// Whether to show a drag handle indicator
  final bool showDragHandle;

  const DraggableInterface({
    Key? key,
    required this.interfaceId,
    required this.configManager,
    required this.child,
    this.useBottomPosition = true,
    this.useRightPosition = false,
    this.onPositionChanged,
    this.showDragHandle = true,
  }) : super(key: key);

  @override
  State<DraggableInterface> createState() => _DraggableInterfaceState();
}

class _DraggableInterfaceState extends State<DraggableInterface> {
  bool _isDragging = false;

  Offset get _position {
    return widget.configManager?.getPosition(widget.interfaceId) ?? const Offset(10, 10);
  }

  bool get _isLocked {
    return widget.configManager?.interfacesLocked ?? true;
  }

  void _updatePosition(Offset delta) {
    if (_isLocked) return;

    final currentPos = _position;
    Offset newPos;

    if (widget.useBottomPosition) {
      // For bottom-positioned widgets, invert Y delta
      newPos = Offset(
        currentPos.dx + (widget.useRightPosition ? -delta.dx : delta.dx),
        currentPos.dy - delta.dy,
      );
    } else {
      // For top-positioned widgets
      newPos = Offset(
        currentPos.dx + (widget.useRightPosition ? -delta.dx : delta.dx),
        currentPos.dy + delta.dy,
      );
    }

    // Clamp to reasonable bounds
    newPos = Offset(
      newPos.dx.clamp(-500, 2000),
      newPos.dy.clamp(-500, 2000),
    );

    widget.configManager?.setPosition(widget.interfaceId, newPos);
    widget.onPositionChanged?.call(newPos);
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _isLocked;

    return GestureDetector(
      onPanStart: isLocked ? null : (_) => setState(() => _isDragging = true),
      onPanUpdate: isLocked ? null : (details) {
        _updatePosition(details.delta);
      },
      onPanEnd: isLocked ? null : (_) => setState(() => _isDragging = false),
      child: MouseRegion(
        cursor: isLocked ? SystemMouseCursors.basic : SystemMouseCursors.move,
        child: Stack(
          children: [
            widget.child,
            // Drag indicator (shown when unlocked)
            if (!isLocked && widget.showDragHandle)
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? const Color(0xFF4cc9f0).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 12,
                    color: _isDragging
                        ? const Color(0xFF4cc9f0)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A positioned version of DraggableInterface for use in Stack
class PositionedDraggableInterface extends StatelessWidget {
  /// The interface ID from InterfaceConfigManager
  final String interfaceId;

  /// The interface config manager
  final InterfaceConfigManager? configManager;

  /// The child widget to make draggable
  final Widget child;

  /// Whether to use bottom positioning (true) or top positioning (false)
  final bool useBottomPosition;

  /// Whether to use right positioning (true) or left positioning (false)
  final bool useRightPosition;

  /// Optional callback when position changes
  final void Function(Offset newPosition)? onPositionChanged;

  /// Whether to show a drag handle indicator
  final bool showDragHandle;

  const PositionedDraggableInterface({
    Key? key,
    required this.interfaceId,
    required this.configManager,
    required this.child,
    this.useBottomPosition = true,
    this.useRightPosition = false,
    this.onPositionChanged,
    this.showDragHandle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final position = configManager?.getPosition(interfaceId) ?? const Offset(10, 10);

    return Positioned(
      left: useRightPosition ? null : position.dx,
      right: useRightPosition ? position.dx : null,
      top: useBottomPosition ? null : position.dy,
      bottom: useBottomPosition ? position.dy : null,
      child: DraggableInterface(
        interfaceId: interfaceId,
        configManager: configManager,
        useBottomPosition: useBottomPosition,
        useRightPosition: useRightPosition,
        onPositionChanged: onPositionChanged,
        showDragHandle: showDragHandle,
        child: child,
      ),
    );
  }
}
