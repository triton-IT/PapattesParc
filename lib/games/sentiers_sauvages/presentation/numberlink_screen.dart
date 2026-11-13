import '../../../shared/clay_hud_icon.dart';
import '../../../shared/clay_text.dart';
import '../../../shared/wooden_sign.dart';
import '../../../shared/board_camera.dart';
import '../../../shared/artwork.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/animal_catalog.dart';
import '../../../shared/animal_scene.dart';
import '../../../shared/animal_colors.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/game_help.dart';
import '../../../shared/game_stage_layout.dart';
import '../domain/models.dart';
import '../domain/numberlink_session.dart';

typedef NumberlinkTraceCallback =
    NumberlinkTraceResult Function(NumberlinkPosition position);

class NumberlinkScreen extends StatelessWidget {
  const NumberlinkScreen({
    this.elapsed,
    required this.session,
    required this.finished,
    required this.newRecord,
    required this.isFreeGame,
    required this.onBegin,
    required this.onTrace,
    required this.onEndTrace,
    required this.onHint,
    required this.onBack,
    required this.onRestart,
    required this.onReplay,
    required this.onLevels,
    required this.onNext,
    this.onNewGame,
    this.onConfigure,
    super.key,
  });

  final NumberlinkSession session;
  final bool finished;
  final bool newRecord;
  final bool isFreeGame;
  final NumberlinkTraceCallback onBegin;
  final NumberlinkTraceCallback onTrace;
  final VoidCallback onEndTrace;
  final VoidCallback onHint;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final VoidCallback onReplay;
  final VoidCallback onLevels;
  final VoidCallback? onNext;
  final VoidCallback? onNewGame;
  final VoidCallback? onConfigure;

  final ValueListenable<Duration>? elapsed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = min(
        constraints.maxWidth / 1672,
        constraints.maxHeight / 941,
      );
      if ((isFreeGame || session.level.number != 19) &&
          scale >= .8 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
        return _integratedScene();
      }
      return _responsiveScene();
    },
  );

  Widget _responsiveScene() => GameStageLayout(
    background: ArtworkImage(session.level.stage.artAsset!, fit: BoxFit.cover),
    wooden: true,
    scrim: Colors.transparent,
    eyebrow: 'SENTIERS SAUVAGES',
    title:
        '${isFreeGame ? 'Partie libre' : 'Niveau ${session.level.number}'} · '
        '${session.level.size} × ${session.level.size}',
    backKey: const Key('numberlink-back'),
    onBack: onBack,
    helpKind: GameHelpKind.numberlink,
    metrics: [
      GameStageMetric(
        icon: Icons.timer_outlined,
        elapsed: elapsed,
        label: formatDuration(session.elapsed),
      ),
      GameStageMetric(
        icon: Icons.route_rounded,
        label: '${session.completedPairs}/${session.level.pairCount}',
      ),
      GameStageMetric(
        icon: Icons.grid_4x4_rounded,
        label: '${session.remainingCells} libres',
      ),
    ],
    builder: (context, layout) => GameStageSplit(
      wide: layout.isLandscape,
      board: BoardCamera(
        wooden: true,
        child: NumberlinkBoard(
          session: session,
          enabled: !finished,
          onBegin: onBegin,
          onTrace: onTrace,
          onEndTrace: onEndTrace,
        ),
      ),
      panel: _GamePanel(session: session, onHint: onHint, onRestart: onRestart),
    ),
    overlays: [
      if (finished)
        Positioned.fill(
          child: _ResultOverlay(
            session: session,
            newRecord: newRecord,
            isFreeGame: isFreeGame,
            onReplay: onReplay,
            onLevels: onLevels,
            onNext: onNext,
            onNewGame: onNewGame,
            onConfigure: onConfigure,
          ),
        ),
    ],
  );

  Widget _integratedScene() => Scaffold(
    backgroundColor: const Color(0xff986a3e),
    body: Stack(
      children: [
        Positioned.fill(
          child: ArtworkImage(session.level.stage.artAsset!, fit: BoxFit.cover),
        ),
        SafeArea(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 1672,
                height: 941,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image(
                        key: const Key('numberlink-scene-background'),
                        image: AssetImage(
                          animalSceneAsset(
                            session.level.number,
                            isFreeGame: isFreeGame,
                          ),
                        ),
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned.fill(
                      child: BoardCamera(
                        wooden: true,
                        layoutBuilder: (context, viewport, controls) => Stack(
                          children: [
                            Positioned(
                              left: 193,
                              top: 225,
                              width: 555,
                              height: 531,
                              child: viewport,
                            ),
                            Positioned(
                              left: 1038,
                              top: 295,
                              width: 92,
                              height: 404,
                              child: controls,
                            ),
                          ],
                        ),
                        child: NumberlinkBoard(
                          session: session,
                          enabled: !finished,
                          onBegin: onBegin,
                          onTrace: onTrace,
                          onEndTrace: onEndTrace,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 60,
                      top: 42,
                      width: 110,
                      height: 110,
                      child: IconButton(
                        key: const Key('numberlink-back'),
                        tooltip: 'Retour',
                        onPressed: onBack,
                        color: const Color(0xffffedcb),
                        iconSize: 65,
                        icon: const ClayHudIcon(ClayHudIconKind.back, size: 65),
                      ),
                    ),
                    Positioned(
                      left: 205,
                      top: 50,
                      width: 460,
                      height: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const ClayText(
                            'SENTIERS SAUVAGES',
                            maxLines: 1,
                            style: TextStyle(
                              color: Color(0xffffcc69),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Color(0xff4d2813),
                                  blurRadius: 4,
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ClayText(
                              '${isFreeGame ? 'Partie libre' : 'Niveau ${session.level.number}'} · ${session.level.size} × ${session.level.size}',
                              style: const TextStyle(
                                color: Color(0xffffefd5),
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Color(0xff4d2813),
                                    blurRadius: 4,
                                    offset: Offset(1, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 708,
                      top: 76,
                      width: 190,
                      height: 60,
                      child: _SceneMetric(
                        icon: Icons.timer_rounded,
                        label: formatDuration(session.elapsed),
                        elapsed: elapsed,
                      ),
                    ),
                    Positioned(
                      left: 973,
                      top: 76,
                      width: 320,
                      height: 60,
                      child: _SceneMetric(
                        icon: Icons.route_rounded,
                        label:
                            '${session.completedPairs}/${session.level.pairCount} · ${session.remainingCells} libres',
                      ),
                    ),
                    Positioned(
                      left: 1351,
                      top: 70,
                      width: 75,
                      height: 75,
                      child: GameHelpButton(
                        clay: true,
                        kind: GameHelpKind.numberlink,
                        color: const Color(0xffffecd0),
                        iconSize: 52,
                      ),
                    ),
                    Positioned(
                      left: 1190,
                      top: 329,
                      width: 430,
                      height: 350,
                      child: _GamePanel(
                        session: session,

                        integrated: true,
                        onHint: onHint,
                        onRestart: onRestart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (finished)
          Positioned.fill(
            child: SafeArea(
              child: _ResultOverlay(
                session: session,
                newRecord: newRecord,
                isFreeGame: isFreeGame,
                onReplay: onReplay,
                onLevels: onLevels,
                onNext: onNext,
                onNewGame: onNewGame,
                onConfigure: onConfigure,
              ),
            ),
          ),
      ],
    ),
  );
}

class _SceneMetric extends StatelessWidget {
  const _SceneMetric({required this.icon, required this.label, this.elapsed});
  final IconData icon;
  final String label;
  final ValueListenable<Duration>? elapsed;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (icon == Icons.timer_rounded)
        const ClayHudIcon(ClayHudIconKind.timer, size: 39)
      else
        ClaySymbol(icon, color: const Color(0xffffecd0), size: 39),
      const SizedBox(width: 10),
      Flexible(
        child: elapsed == null
            ? _text(label)
            : ValueListenableBuilder<Duration>(
                valueListenable: elapsed!,
                builder: (context, value, _) => _text(formatDuration(value)),
              ),
      ),
    ],
  );
  Widget _text(String value) => FittedBox(
    fit: BoxFit.scaleDown,
    child: ClayText(
      value,
      maxLines: 1,
      style: const TextStyle(
        color: Color(0xffffecd0),
        fontSize: 29,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(color: Color(0xff523017), blurRadius: 4, offset: Offset(1, 2)),
        ],
      ),
    ),
  );
}

class NumberlinkBoard extends StatefulWidget {
  const NumberlinkBoard({
    required this.session,
    required this.enabled,
    required this.onBegin,
    required this.onTrace,
    required this.onEndTrace,
    super.key,
  });

  final NumberlinkSession session;
  final bool enabled;
  final NumberlinkTraceCallback onBegin;
  final NumberlinkTraceCallback onTrace;
  final VoidCallback onEndTrace;

  @override
  State<NumberlinkBoard> createState() => _NumberlinkBoardState();
}

class _NumberlinkBoardState extends State<NumberlinkBoard> {
  final FocusNode _focusNode = FocusNode();
  NumberlinkPosition _cursor = const NumberlinkPosition(0, 0);
  NumberlinkPosition? _pointerOrigin;
  NumberlinkPosition? _lastPosition;
  bool _dragDrawing = false;
  bool _tapDrawing = false;
  bool _keyboardDrawing = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NumberlinkBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session == widget.session && widget.enabled) return;
    _cursor = const NumberlinkPosition(0, 0);
    _pointerOrigin = null;
    _lastPosition = null;
    _dragDrawing = false;
    _tapDrawing = false;
    _keyboardDrawing = false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = max(
        0.0,
        min(constraints.maxWidth, constraints.maxHeight) - 24,
      );
      return Center(
        child: SizedBox.square(
          dimension: side,
          child: Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _onKeyEvent,
            child: Semantics(
              label:
                  'Grille de sentiers ${widget.session.level.size} par ${widget.session.level.size}. '
                  'Utilise les flèches pour te déplacer et Entrée pour tracer.',
              child: GestureDetector(
                key: const Key('numberlink-board'),
                behavior: HitTestBehavior.opaque,
                onTapUp: widget.enabled
                    ? (details) {
                        if (!BoardCamera.isNavigating(context)) {
                          _tap(_positionAt(details.localPosition, side));
                        }
                      }
                    : null,
                onPanDown: widget.enabled
                    ? (details) {
                        _focusNode.requestFocus();
                        _pointerOrigin = _positionAt(
                          details.localPosition,
                          side,
                        );
                      }
                    : null,
                onPanStart: widget.enabled
                    ? (_) {
                        if (!BoardCamera.isNavigating(context)) _startDrag();
                      }
                    : null,
                onPanUpdate: widget.enabled
                    ? (details) {
                        if (!BoardCamera.isNavigating(context)) {
                          _drag(_positionAt(details.localPosition, side));
                        }
                      }
                    : null,
                onPanEnd: widget.enabled ? (_) => _finishDrag() : null,
                onPanCancel: widget.enabled ? _finishDrag : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xffc99b65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xff80532e),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66245b4a),
                        blurRadius: 18,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: widget.session.level.size,
                                ),
                            itemCount:
                                widget.session.level.size *
                                widget.session.level.size,
                            itemBuilder: (context, index) => Container(
                              decoration: BoxDecoration(
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/optimized/sudoku/sandstone-tile.webp',
                                  ),
                                  fit: BoxFit.fill,
                                ),
                                border: Border.all(
                                  color: const Color(0xffb38c5e),
                                  width: .5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BoardPainter(
                              session: widget.session,
                              cursor: _cursor,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: widget.session.level.size,
                                  ),
                              itemCount:
                                  widget.session.level.size *
                                  widget.session.level.size,
                              itemBuilder: (context, index) => _BoardCell(
                                session: widget.session,
                                position: NumberlinkPosition(
                                  index % widget.session.level.size,
                                  index ~/ widget.session.level.size,
                                ),
                              ),
                            ),
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
    },
  );

  NumberlinkPosition _positionAt(Offset offset, double side) {
    final size = widget.session.level.size;
    return NumberlinkPosition(
      (offset.dx / side * size).floor().clamp(0, size - 1),
      (offset.dy / side * size).floor().clamp(0, size - 1),
    );
  }

  void _startDrag() {
    final origin = _pointerOrigin;
    if (origin == null) return;
    _stopPersistentTrace();
    final result = widget.onBegin(origin);
    _dragDrawing = result == NumberlinkTraceResult.started;
    _lastPosition = _dragDrawing ? origin : null;
    setState(() => _cursor = origin);
  }

  void _drag(NumberlinkPosition position) {
    if (!_dragDrawing || position == _lastPosition) return;
    for (final step in _stepsTo(position)) {
      final result = widget.onTrace(step);
      if (result == NumberlinkTraceResult.blocked) return;
      _lastPosition = step;
      _cursor = step;
      if (_completed(result)) {
        setState(() {});
        _finishDrag();
        return;
      }
    }
    setState(() {});
  }

  Iterable<NumberlinkPosition> _stepsTo(NumberlinkPosition target) sync* {
    var current = _lastPosition!;
    while (current != target) {
      final dx = target.x - current.x;
      final dy = target.y - current.y;
      current = dx.abs() >= dy.abs()
          ? NumberlinkPosition(current.x + dx.sign, current.y)
          : NumberlinkPosition(current.x, current.y + dy.sign);
      yield current;
    }
  }

  void _finishDrag() {
    if (!_dragDrawing) return;
    widget.onEndTrace();
    _dragDrawing = false;
    _lastPosition = null;
  }

  void _tap(NumberlinkPosition position) {
    _focusNode.requestFocus();
    if (_tapDrawing) {
      if (position == _lastPosition) {
        widget.onEndTrace();
        _tapDrawing = false;
        _lastPosition = null;
        return;
      }
      final result = widget.onTrace(position);
      if (result == NumberlinkTraceResult.blocked) return;
      _lastPosition = position;
      setState(() => _cursor = position);
      if (_completed(result)) {
        widget.onEndTrace();
        _tapDrawing = false;
        _lastPosition = null;
      }
      return;
    }
    final result = widget.onBegin(position);
    _tapDrawing = result == NumberlinkTraceResult.started;
    _lastPosition = _tapDrawing ? position : null;
    setState(() => _cursor = position);
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => const NumberlinkPosition(-1, 0),
      LogicalKeyboardKey.arrowRight => const NumberlinkPosition(1, 0),
      LogicalKeyboardKey.arrowUp => const NumberlinkPosition(0, -1),
      LogicalKeyboardKey.arrowDown => const NumberlinkPosition(0, 1),
      _ => null,
    };
    if (delta != null) {
      _moveCursor(delta);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _toggleKeyboardTrace();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape && _keyboardDrawing) {
      widget.onEndTrace();
      setState(() => _keyboardDrawing = false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveCursor(NumberlinkPosition delta) {
    final size = widget.session.level.size;
    final next = NumberlinkPosition(
      (_cursor.x + delta.x).clamp(0, size - 1),
      (_cursor.y + delta.y).clamp(0, size - 1),
    );
    if (next == _cursor) return;
    if (!_keyboardDrawing) {
      setState(() => _cursor = next);
      return;
    }
    final result = widget.onTrace(next);
    if (result == NumberlinkTraceResult.blocked) return;
    setState(() => _cursor = next);
    if (_completed(result)) {
      widget.onEndTrace();
      _keyboardDrawing = false;
    }
  }

  void _toggleKeyboardTrace() {
    if (_keyboardDrawing) {
      widget.onEndTrace();
      setState(() => _keyboardDrawing = false);
      return;
    }
    _stopPersistentTrace();
    final result = widget.onBegin(_cursor);
    setState(() {
      _keyboardDrawing = result == NumberlinkTraceResult.started;
    });
  }

  void _stopPersistentTrace() {
    if (!_tapDrawing && !_keyboardDrawing) return;
    widget.onEndTrace();
    _tapDrawing = false;
    _keyboardDrawing = false;
    _lastPosition = null;
  }

  bool _completed(NumberlinkTraceResult result) =>
      result == NumberlinkTraceResult.connected ||
      result == NumberlinkTraceResult.won;
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({required this.session, required this.position});

  final NumberlinkSession session;
  final NumberlinkPosition position;

  @override
  Widget build(BuildContext context) {
    final pair = _pairAt(session.level.pairs, position);
    return Semantics(
      label: _label(pair),
      child: Container(
        key: Key('numberlink-cell-${position.index(session.level.size)}'),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffb38c5e), width: .5),
        ),
        child: pair == null
            ? const SizedBox.expand()
            : Padding(
                padding: const EdgeInsets.all(3),
                child: ArtworkImage(pair.animal.asset, fit: BoxFit.contain),
              ),
      ),
    );
  }

  String _label(NumberlinkPair? pair) {
    final location = 'Ligne ${position.y + 1}, colonne ${position.x + 1}';
    if (pair == null) return '$location, case de sentier';
    return '$location, ${pair.animal.label}';
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({required this.session, required this.cursor});

  final NumberlinkSession session;
  final NumberlinkPosition cursor;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cell = canvasSize.width / session.level.size;
    for (var slot = 0; slot < session.level.pairs.length; slot++) {
      final pair = session.level.pairs[slot];
      if (!session.hintedPairIds.contains(pair.id) ||
          session.isPairConnected(pair.id)) {
        continue;
      }
      _paintHint(
        canvas,
        pair.referencePath,
        cell,
        animalHaloColors[slot % animalHaloColors.length],
      );
    }
    for (var slot = 0; slot < session.level.pairs.length; slot++) {
      final pair = session.level.pairs[slot];
      final path = session.paths[pair.id];
      if (path == null || path.length < 2) continue;
      final color = animalHaloColors[slot % animalHaloColors.length];
      _paintPath(canvas, path, cell, Colors.white, cell * .34);
      _paintPath(canvas, path, cell, color, cell * .24);
    }
    final cursorRect = Rect.fromLTWH(
      cursor.x * cell + 2,
      cursor.y * cell + 2,
      cell - 4,
      cell - 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cursorRect, Radius.circular(cell * .14)),
      Paint()
        ..color = AppColors.deep.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _paintPath(
    Canvas canvas,
    List<NumberlinkPosition> positions,
    double cell,
    Color color,
    double width,
  ) {
    final path = Path();
    for (var index = 0; index < positions.length; index++) {
      final center = _center(positions[index], cell);
      index == 0
          ? path.moveTo(center.dx, center.dy)
          : path.lineTo(center.dx, center.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width.clamp(4, 22),
    );
  }

  void _paintHint(
    Canvas canvas,
    List<NumberlinkPosition> positions,
    double cell,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: .38)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (cell * .16).clamp(3, 12);
    for (var index = 1; index < positions.length; index++) {
      final start = _center(positions[index - 1], cell);
      final end = _center(positions[index], cell);
      final delta = end - start;
      final length = delta.distance;
      final direction = delta / length;
      final dash = max(3.0, cell * .16);
      for (var offset = 0.0; offset < length; offset += dash * 2) {
        canvas.drawLine(
          start + direction * offset,
          start + direction * min(offset + dash, length),
          paint,
        );
      }
    }
  }

  Offset _center(NumberlinkPosition position, double cell) =>
      Offset((position.x + .5) * cell, (position.y + .5) * cell);

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) => true;
}

class _GamePanel extends StatelessWidget {
  const _GamePanel({
    required this.session,
    this.integrated = false,
    required this.onHint,
    required this.onRestart,
  });

  final NumberlinkSession session;
  final bool integrated;
  final VoidCallback onHint;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(integrated ? 0 : 28),
    decoration: integrated ? null : parchmentDecoration,
    child: Column(
      mainAxisSize: integrated ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SceneAction(
          key: const Key('numberlink-hint'),
          icon: Icons.lightbulb_rounded,
          label: 'INDICE ${session.hintsRemaining}/3',
          onPressed: session.hintsRemaining == 0 ? null : onHint,
        ),
        const SizedBox(height: 20),
        _SceneAction(
          key: const Key('numberlink-restart'),
          icon: Icons.refresh_rounded,
          label: 'RECOMMENCER',
          onPressed: onRestart,
        ),
        if (session.completedPairs == session.level.pairCount &&
            session.remainingCells > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Encore ${session.remainingCells} case(s) à couvrir : '
            'reprends un sentier.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    ),
  );
}

class _SceneAction extends StatelessWidget {
  const _SceneAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 75,
    child: WoodenSign(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xffffedc2),
          disabledForegroundColor: const Color(0xffbba989),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClaySymbol(icon, size: 35),
              const SizedBox(width: 8),
              ClayText(
                label,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.session,
    required this.newRecord,
    required this.isFreeGame,
    required this.onReplay,
    required this.onLevels,
    required this.onNext,
    required this.onNewGame,
    required this.onConfigure,
  });

  final NumberlinkSession session;
  final bool newRecord;
  final bool isFreeGame;
  final VoidCallback onReplay;
  final VoidCallback onLevels;
  final VoidCallback? onNext;
  final VoidCallback? onNewGame;
  final VoidCallback? onConfigure;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('numberlink-result-overlay'),
    color: const Color(0xaa173a31),
    child: GameResultViewport(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GameResultPanel(
          biome: session.level.stage.biome,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.pets_rounded, size: 54, color: AppColors.sun),
                Text(
                  'SENTIERS TERMINÉS !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatDuration(session.elapsed)} · '
                  '${isFreeGame ? '${session.hintsUsed} indice(s)' : '${session.footprints} empreinte(s)'}'
                  '${newRecord ? '\nNouveau record !' : ''}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                if (onNext != null)
                  FilledButton.icon(
                    key: const Key('numberlink-next'),
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('NIVEAU SUIVANT'),
                  ),
                TextButton.icon(
                  key: const Key('numberlink-replay'),
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('REJOUER'),
                ),
                if (onNewGame != null)
                  TextButton.icon(
                    key: const Key('numberlink-new-free-game'),
                    onPressed: onNewGame,
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('NOUVELLE GRILLE'),
                  ),
                if (onConfigure != null)
                  TextButton.icon(
                    key: const Key('numberlink-configure'),
                    onPressed: onConfigure,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('MODIFIER LES RÉGLAGES'),
                  ),
                TextButton.icon(
                  key: const Key('numberlink-levels'),
                  onPressed: onLevels,
                  icon: const Icon(Icons.route_rounded),
                  label: const Text('RETOUR AUX NIVEAUX'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

NumberlinkPair? _pairAt(
  List<NumberlinkPair> pairs,
  NumberlinkPosition position,
) {
  for (final pair in pairs) {
    if (pair.animalPosition == position || pair.enclosurePosition == position) {
      return pair;
    }
  }
  return null;
}
