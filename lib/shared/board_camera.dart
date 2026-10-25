import 'package:flutter/material.dart';

/// Keeps navigation separate from a board's one-pointer gameplay gestures.
class BoardCamera extends StatefulWidget {
  const BoardCamera({
    required this.child,
    this.transformationController,
    this.viewerKey,
    this.constrained = true,
    this.minScale = 1,
    this.maxScale = 3,
    this.boundaryMargin = EdgeInsets.zero,
    this.clipBehavior = Clip.hardEdge,
    this.panEnabled = true,
    super.key,
  });
  final Widget child;
  final TransformationController? transformationController;
  final Key? viewerKey;
  final bool constrained, panEnabled;
  final double minScale, maxScale;
  final EdgeInsets boundaryMargin;
  final Clip clipBehavior;
  static bool isNavigating(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<_CameraNavigation>()
          ?.notifier
          ?.value ??
      false;
  @override
  State<BoardCamera> createState() => _BoardCameraState();
}

class _BoardCameraState extends State<BoardCamera> {
  final TransformationController _own = TransformationController();
  final Map<int, Offset> _pointers = {};
  final ValueNotifier<bool> _navigation = ValueNotifier(false);
  bool _moveMode = false;
  bool _cameraGesture = false;
  Matrix4? _overview;
  Size _viewport = const Size(320, 240);
  TransformationController get _camera =>
      widget.transformationController ?? _own;
  @override
  void dispose() {
    _own.dispose();
    _navigation.dispose();
    super.dispose();
  }

  void _pointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length >= 2 || _moveMode) _cameraGesture = true;
    _navigation.value = _cameraGesture;
  }

  void _pointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) {
      _cameraGesture = false;
      _navigation.value = _moveMode;
    }
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    final previous = _pointers.values.take(2).toList();
    _pointers[event.pointer] = event.localPosition;
    if (!widget.panEnabled || !_cameraGesture) return;
    final current = _pointers.values.take(2).toList();
    if (previous.length == 1 && !_moveMode) return;
    final before =
        previous.reduce((a, b) => a + b) / previous.length.toDouble();
    final after = current.reduce((a, b) => a + b) / current.length.toDouble();
    var ratio = 1.0;
    if (previous.length == 2) {
      final distance = (previous[1] - previous[0]).distance;
      if (distance > 1) ratio = (current[1] - current[0]).distance / distance;
    }
    final world = _camera.toScene(before);
    final scale = (_camera.value.getMaxScaleOnAxis() * ratio).clamp(
      widget.minScale,
      widget.maxScale,
    );
    _camera.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        after.dx - world.dx * scale,
        after.dy - world.dy * scale,
        0,
      );
  }

  void _zoom(double factor, Size viewport) {
    final scene = _camera.toScene(viewport.center(Offset.zero));
    final scale = (_camera.value.getMaxScaleOnAxis() * factor).clamp(
      widget.minScale,
      widget.maxScale,
    );
    _camera.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        viewport.width / 2 - scene.dx * scale,
        viewport.height / 2 - scene.dy * scale,
        0,
      );
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_overview == null || _viewport != constraints.biggest) {
              _overview = _camera.value.clone();
            }
            _viewport = constraints.biggest;
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _pointerDown,
              onPointerMove: _pointerMove,
              onPointerUp: _pointerUp,
              onPointerCancel: _pointerUp,
              child: InteractiveViewer(
                key: widget.viewerKey,
                transformationController: _camera,
                constrained: widget.constrained,
                minScale: widget.minScale,
                maxScale: widget.maxScale,
                boundaryMargin: widget.boundaryMargin,
                clipBehavior: widget.clipBehavior,
                panEnabled: false,
                scaleEnabled: false,
                child: _CameraNavigation(
                  notifier: _navigation,
                  child: AbsorbPointer(
                    absorbing: _moveMode,
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      SizedBox(
        width: 48,
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.center,
            child: Material(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Agrandir le plateau',
                        onPressed: () => _zoom(1.4, _viewport),
                        icon: const Icon(Icons.zoom_in),
                      ),
                      IconButton(
                        tooltip: 'Réduire le plateau',
                        onPressed: () => _zoom(1 / 1.4, _viewport),
                        icon: const Icon(Icons.zoom_out),
                      ),
                      IconButton(
                        tooltip: 'Déplacer le plateau',
                        isSelected: _moveMode,
                        onPressed: widget.panEnabled
                            ? () => setState(() {
                                _moveMode = !_moveMode;
                                _navigation.value = _moveMode;
                              })
                            : null,
                        icon: const Icon(Icons.pan_tool_outlined),
                      ),
                      IconButton(
                        tooltip: 'Recentrer le plateau',
                        onPressed: () {
                          if (_overview != null) {
                            _camera.value = _overview!.clone();
                          }
                        },
                        icon: const Icon(Icons.center_focus_strong),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _CameraNavigation extends InheritedNotifier<ValueNotifier<bool>> {
  const _CameraNavigation({required super.notifier, required super.child});
}
