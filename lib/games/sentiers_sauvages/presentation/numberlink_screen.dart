import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/animal_background.dart';
import '../../../shared/animal_catalog.dart';
import '../../../shared/animal_colors.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/game_help.dart';
import '../domain/models.dart';
import '../domain/numberlink_session.dart';

typedef NumberlinkTraceCallback =
    NumberlinkTraceResult Function(NumberlinkPosition position);

class NumberlinkScreen extends StatelessWidget {
  const NumberlinkScreen({
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: AnimalBackground(
      asset: session.level.stage.artAsset!,
      child: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 900 &&
                    constraints.maxWidth > constraints.maxHeight;
                final board = NumberlinkBoard(
                  session: session,
                  enabled: !finished,
                  onBegin: onBegin,
                  onTrace: onTrace,
                  onEndTrace: onEndTrace,
                );
                final panel = _GamePanel(
                  session: session,
                  wide: wide,
                  isFreeGame: isFreeGame,
                  onHint: onHint,
                  onRestart: onRestart,
                );
                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: board),
                      SizedBox(width: 350, child: panel),
                    ],
                  );
                }
                return Column(
                  children: [
                    const SizedBox(height: 58),
                    Expanded(child: board),
                    panel,
                  ],
                );
              },
            ),
            Positioned(
              left: 12,
              top: 12,
              child: IconButton.filledTonal(
                key: const Key('numberlink-back'),
                tooltip: 'Retour',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const Positioned(
              right: 12,
              top: 12,
              child: GameHelpButton(kind: GameHelpKind.numberlink),
            ),
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
        ),
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
                    ? (details) =>
                          _tap(_positionAt(details.localPosition, side))
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
                onPanStart: widget.enabled ? (_) => _startDrag() : null,
                onPanUpdate: widget.enabled
                    ? (details) =>
                          _drag(_positionAt(details.localPosition, side))
                    : null,
                onPanEnd: widget.enabled ? (_) => _finishDrag() : null,
                onPanCancel: widget.enabled ? _finishDrag : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 3),
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
    final isAnimal = pair?.animalPosition == position;
    final slot = pair == null ? 0 : session.level.pairs.indexOf(pair);
    return Semantics(
      label: _label(pair, isAnimal),
      child: Container(
        key: Key('numberlink-cell-${position.index(session.level.size)}'),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.deep.withValues(alpha: .15),
            width: .5,
          ),
        ),
        child: pair == null
            ? const SizedBox.expand()
            : _Endpoint(
                pair: pair,
                animal: isAnimal,
                color: animalHaloColors[slot % animalHaloColors.length],
              ),
      ),
    );
  }

  String _label(NumberlinkPair? pair, bool isAnimal) {
    final location = 'Ligne ${position.y + 1}, colonne ${position.x + 1}';
    if (pair == null) return '$location, case de sentier';
    return '$location, ${isAnimal ? pair.animal.label : 'enclos de ${pair.animal.label}'}';
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.pair,
    required this.animal,
    required this.color,
  });

  final NumberlinkPair pair;
  final bool animal;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(3),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x44245b4a), blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: animal
            ? Image.asset(pair.animal.asset, fit: BoxFit.contain)
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(pair.animal.asset, fit: BoxFit.contain),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: .85,
                      heightFactor: .55,
                      child: Image.asset(
                        'assets/sokoban/fence-v2.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
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
    required this.wide,
    required this.isFreeGame,
    required this.onHint,
    required this.onRestart,
  });

  final NumberlinkSession session;
  final bool wide;
  final bool isFreeGame;
  final VoidCallback onHint;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface.withValues(alpha: .96),
    child: Padding(
      padding: EdgeInsets.all(wide ? 18 : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide) ...[
            const Text(
              'SENTIERS SAUVAGES',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            Text(
              '${isFreeGame ? 'Partie libre' : 'Niveau ${session.level.number}'} · '
              '${session.level.size} × ${session.level.size}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Relie chaque animal à son enclos et remplis la grille.',
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              _Stat(
                icon: Icons.timer_outlined,
                value: formatDuration(session.elapsed),
                label: 'temps',
              ),
              _Stat(
                icon: Icons.route_rounded,
                value: '${session.completedPairs}/${session.level.pairCount}',
                label: 'sentiers',
              ),
              _Stat(
                icon: Icons.grid_4x4_rounded,
                value: '${session.remainingCells}',
                label: 'cases libres',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('numberlink-hint'),
                  onPressed: session.hintsRemaining == 0 ? null : onHint,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(40, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.lightbulb_rounded),
                  label: Text('INDICE ${session.hintsRemaining}/3'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('numberlink-restart'),
                  onPressed: onRestart,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(40, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('RECOMMENCER'),
                ),
              ),
            ],
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
          if (wide) ...[
            const SizedBox(height: 12),
            Text(
              '${session.footprints} empreinte(s) disponible(s)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
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
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.pets_rounded, size: 54, color: AppColors.sun),
                Text(
                  'TOUS À L’ABRI !',
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
                FilledButton.tonalIcon(
                  key: const Key('numberlink-replay'),
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('REJOUER'),
                ),
                if (onNewGame != null)
                  FilledButton.tonalIcon(
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
