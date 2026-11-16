import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// A painted pointer above the whole game, without intercepting its controls.
class ParkCursor extends StatefulWidget {
  const ParkCursor({required this.child, super.key});

  final Widget child;

  @override
  State<ParkCursor> createState() => _ParkCursorState();
}

class _ParkCursorState extends State<ParkCursor> {
  Offset? _position;

  void _move(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    setState(() => _position = event.localPosition);
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    clipBehavior: Clip.none,
    children: [
      widget.child,
      Positioned.fill(
        child: MouseRegion(
          cursor: SystemMouseCursors.none,
          opaque: false,
          hitTestBehavior: HitTestBehavior.translucent,
          onEnter: _move,
          onExit: (_) => setState(() => _position = null),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerHover: _move,
            onPointerMove: _move,
          ),
        ),
      ),
      if (_position case final position?)
        Positioned(
          // The arrow tip sits slightly inside the transparent image.
          left: position.dx - 3.2,
          top: position.dy - .3,
          child: const IgnorePointer(
            child: Image(
              key: ValueKey('park-cursor'),
              image: AssetImage(
                'assets/optimized/clay_type/cursor-arrow-256.webp',
              ),
              width: 26,
              height: 26,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ),
    ],
  );
}
