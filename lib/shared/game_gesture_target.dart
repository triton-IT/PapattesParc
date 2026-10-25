import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Adds keyboard activation to custom game gestures without changing drag rules.
class GameGestureTarget extends StatefulWidget {
  const GameGestureTarget({
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.behavior,
    super.key,
  });
  final Widget child;
  final VoidCallback? onTap, onDoubleTap, onPanCancel;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final HitTestBehavior? behavior;
  @override
  State<GameGestureTarget> createState() => _GameGestureTargetState();
}

class _GameGestureTargetState extends State<GameGestureTarget> {
  bool _focus = false;
  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    enabled: widget.onTap != null,
    onShowFocusHighlight: (value) => setState(() => _focus = value),
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    },
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          widget.onTap?.call();
          return null;
        },
      ),
    },
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: _focus ? Border.all(color: Colors.amber, width: 3) : null,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onPanStart: widget.onPanStart,
        onPanUpdate: widget.onPanUpdate,
        onPanEnd: widget.onPanEnd,
        onPanCancel: widget.onPanCancel,
        behavior: widget.behavior,
        child: widget.child,
      ),
    ),
  );
}
