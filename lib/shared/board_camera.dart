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
    this.wooden = false,
    this.layoutBuilder,
    super.key,
  });
  final Widget child;
  final TransformationController? transformationController;
  final Key? viewerKey;
  final bool constrained, panEnabled;
  final bool wooden;
  final Widget Function(BuildContext context, Widget viewport, Widget controls)?
  layoutBuilder;
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
  // The Z axis stays at 1, so Matrix4.getMaxScaleOnAxis() reports at least 1
  // even when the two-dimensional board is displayed at a smaller scale.
  double get _scale => _camera.value.entry(0, 0);
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
    final scale = (_scale * ratio).clamp(widget.minScale, widget.maxScale);
    _camera.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        after.dx - world.dx * scale,
        after.dy - world.dy * scale,
        0,
      );
  }

  void _zoom(double factor, Size viewport) {
    final scene = _camera.toScene(viewport.center(Offset.zero));
    final scale = (_scale * factor).clamp(widget.minScale, widget.maxScale);
    _camera.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        viewport.width / 2 - scene.dx * scale,
        viewport.height / 2 - scene.dy * scale,
        0,
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewport = LayoutBuilder(
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
              child: AbsorbPointer(absorbing: _moveMode, child: widget.child),
            ),
          ),
        );
      },
    );
    final integrated = widget.wooden && widget.layoutBuilder != null;
    Widget cameraButton(Widget button) => integrated
        ? SizedBox.square(
            dimension: 86,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/optimized/sudoku/camera-stone.webp',
                  ),
                  fit: BoxFit.fill,
                ),
              ),
              child: button,
            ),
          )
        : button;
    final controls = SizedBox(
      width: widget.wooden
          ? (MediaQuery.sizeOf(context).width / 20).clamp(48.0, 84.0)
          : 48,
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.center,
          child: Material(
            color: integrated
                ? Colors.transparent
                : widget.wooden
                ? const Color(0xffbc9060)
                : Theme.of(context).colorScheme.surface.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: SingleChildScrollView(
                child: IconButtonTheme(
                  data: IconButtonThemeData(
                    style: widget.wooden
                        ? IconButton.styleFrom(
                            backgroundColor: integrated
                                ? Colors.transparent
                                : const Color(0xffecd2a1),
                            foregroundColor: const Color(0xff245b4a),
                            iconSize: (MediaQuery.sizeOf(context).width / 50)
                                .clamp(24.0, 36.0),
                            minimumSize: Size.square(
                              (MediaQuery.sizeOf(context).width / 24).clamp(
                                44.0,
                                70.0,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: integrated
                                  ? BorderSide.none
                                  : const BorderSide(
                                      color: Color(0xff80562f),
                                      width: 2,
                                    ),
                            ),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      cameraButton(
                        IconButton(
                          tooltip: 'Agrandir le plateau',
                          onPressed: () => _zoom(1.4, _viewport),
                          icon: const Icon(Icons.zoom_in),
                        ),
                      ),
                      if (integrated) const SizedBox(height: 20),
                      cameraButton(
                        IconButton(
                          tooltip: 'Réduire le plateau',
                          onPressed: () => _zoom(1 / 1.4, _viewport),
                          icon: const Icon(Icons.zoom_out),
                        ),
                      ),
                      if (integrated) const SizedBox(height: 20),
                      cameraButton(
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
                      ),
                      if (integrated) const SizedBox(height: 20),
                      cameraButton(
                        IconButton(
                          tooltip: 'Recentrer le plateau',
                          onPressed: () {
                            if (_overview != null) {
                              _camera.value = _overview!.clone();
                            }
                          },
                          icon: const Icon(Icons.center_focus_strong),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.layoutBuilder case final builder?) {
      return builder(context, viewport, controls);
    }
    return Row(
      children: [
        Expanded(child: viewport),
        controls,
      ],
    );
  }
}

class _CameraNavigation extends InheritedNotifier<ValueNotifier<bool>> {
  const _CameraNavigation({required super.notifier, required super.child});
}
