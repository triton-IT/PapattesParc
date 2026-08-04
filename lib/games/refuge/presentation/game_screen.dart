import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/game_session.dart';
import '../domain/levels.dart';
import '../domain/models.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/game_help.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({
    required this.level,
    required this.session,
    required this.generating,
    required this.finished,
    required this.newRecord,
    required this.onHome,
    required this.onReveal,
    required this.onFlag,
    required this.onReplaySame,
    required this.onReplayNew,
    required this.onNext,
    super.key,
  });

  final LevelDefinition level;
  final GameSession session;
  final bool generating;
  final bool finished;
  final bool newRecord;
  final VoidCallback onHome;
  final ValueChanged<CellPosition> onReveal;
  final ValueChanged<CellPosition> onFlag;
  final VoidCallback onReplaySame;
  final VoidCallback onReplayNew;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Transform.scale(
              scale: wide ? 1.12 : 1.2,
              alignment: wide ? Alignment.centerRight : Alignment.bottomCenter,
              child: LevelBackdrop(level: level),
            ),
          ),
          Positioned.fill(child: _GameBackdropVeil(wide: wide)),
          Column(
            children: [
              _GameHeader(level: level, session: session, onHome: onHome),
              Expanded(
                child: BoardView(
                  level: level,
                  session: session,
                  onReveal: onReveal,
                  onFlag: onFlag,
                ),
              ),
            ],
          ),
          if (generating) const _GenerationOverlay(),
          if (finished)
            _EndOverlay(
              level: level,
              session: session,
              newRecord: newRecord,
              onReplaySame: onReplaySame,
              onReplayNew: onReplayNew,
              onNext: onNext,
              onHome: onHome,
            ),
        ],
      ),
    );
  }
}

class _GameBackdropVeil extends StatelessWidget {
  const _GameBackdropVeil({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: wide ? Alignment.centerLeft : Alignment.topCenter,
              end: wide ? Alignment.centerRight : Alignment.bottomCenter,
              colors: wide
                  ? [
                      Colors.transparent,
                      AppColors.deep.withValues(alpha: .08),
                      AppColors.deep.withValues(alpha: .4),
                    ]
                  : [
                      AppColors.deep.withValues(alpha: .12),
                      Colors.transparent,
                      AppColors.deep.withValues(alpha: .2),
                    ],
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.deep.withValues(alpha: .68),
                Colors.transparent,
              ],
              stops: const [0, .24],
            ),
          ),
        ),
      ),
    ],
  );
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.level,
    required this.session,
    required this.onHome,
  });

  final LevelDefinition level;
  final GameSession session;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 760
            ? _WideHeader(level: level, session: session, onHome: onHome)
            : _CompactHeader(level: level, session: session, onHome: onHome),
      ),
    ),
  );
}

class _WideHeader extends StatelessWidget {
  const _WideHeader({
    required this.level,
    required this.session,
    required this.onHome,
  });

  final LevelDefinition level;
  final GameSession session;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        TextButton.icon(
          onPressed: onHome,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: .12),
            minimumSize: const Size(48, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(
            level.isCustom ? Icons.home_rounded : Icons.map_rounded,
            size: 20,
          ),
          label: Text(level.isCustom ? 'Accueil' : 'Parcours'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                level.isCustom
                    ? 'PARTIE LIBRE'
                    : 'MISSION ${level.number.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppColors.sun,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                level.isCustom
                    ? level.title
                    : 'Niveau ${level.number} · ${level.title}',
                key: const Key('game-level-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _HeaderMetric(
          icon: Icons.pets_rounded,
          text: 'À localiser : ${session.remainingAnimals}',
        ),
        const SizedBox(width: 12),
        _HeaderMetric(
          icon: Icons.timer_rounded,
          text: formatDuration(session.elapsed),
        ),
        const SizedBox(width: 12),
        const GameHelpButton(kind: GameHelpKind.refuge, color: Colors.white),
        const SizedBox(width: 4),
        const Flexible(
          child: _Instruction(
            text: 'Toucher : observer · Appui long : baliser',
          ),
        ),
      ],
    ),
  );
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.level,
    required this.session,
    required this.onHome,
  });

  final LevelDefinition level;
  final GameSession session;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 7, 10, 9),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('back-to-course'),
              tooltip: level.isCustom ? 'Accueil' : 'Parcours',
              onPressed: onHome,
              color: AppColors.sun,
              icon: Icon(
                level.isCustom ? Icons.home_rounded : Icons.map_rounded,
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.isCustom
                        ? 'PARTIE LIBRE'
                        : 'MISSION ${level.number.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.sun,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    level.isCustom
                        ? level.title
                        : 'Niveau ${level.number} · ${level.title}',
                    key: const Key('game-level-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _HeaderMetric(
              icon: Icons.timer_rounded,
              text: formatDuration(session.elapsed),
            ),
            const GameHelpButton(
              kind: GameHelpKind.refuge,
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _HeaderMetric(
              icon: Icons.pets_rounded,
              text: '${session.remainingAnimals} à localiser',
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _Instruction(
                text: 'Toucher · Maintenir : baliser',
                compact: true,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Instruction extends StatelessWidget {
  const _Instruction({required this.text, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.touch_app_rounded, color: Color(0xffdbeee3), size: 16),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: const Color(0xffdbeee3),
            fontSize: compact ? 11 : 13,
          ),
        ),
      ),
    ],
  );
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: .1)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class BoardView extends StatelessWidget {
  const BoardView({
    required this.level,
    required this.session,
    required this.onReveal,
    required this.onFlag,
    super.key,
  });

  static const spacing = 4.0;
  static const padding = 14.0;
  final LevelDefinition level;
  final GameSession session;
  final ValueChanged<CellPosition> onReveal;
  final ValueChanged<CellPosition> onFlag;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      final wide = constraints.maxWidth >= 1000;
      final config = session.config;
      final compactHeight =
          config.height * 48 + (config.height - 1) * spacing + padding * 2 + 54;
      return Padding(
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: Align(
          alignment: wide ? Alignment.centerRight : Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: wide ? min(820, constraints.maxWidth * .47) : 820,
              maxHeight: 820,
            ),
            child: SizedBox(
              height: compact
                  ? min(compactHeight, constraints.maxHeight - 24)
                  : null,
              child: Column(
                key: const Key('board-background'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BoardLabel(level: level, compact: compact),
                  Expanded(
                    child: Material(
                      color: biomeBoardColor(
                        level.biome,
                      ).withValues(alpha: .92),
                      elevation: 16,
                      shadowColor: AppColors.deep.withValues(alpha: .32),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(compact ? 22 : 28),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: .72),
                          width: 2,
                        ),
                      ),
                      child: _BoardGrid(
                        level: level,
                        session: session,
                        onReveal: onReveal,
                        onFlag: onFlag,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _BoardLabel extends StatelessWidget {
  const _BoardLabel({required this.level, required this.compact});

  final LevelDefinition level;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(8, compact ? 5 : 8, 8, compact ? 8 : 10),
    child: Row(
      children: [
        Icon(Icons.eco_rounded, color: Colors.white, size: compact ? 18 : 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ZONE D’OBSERVATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              if (!compact)
                Text(
                  level.species,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xffe3eee8),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
        Icon(Icons.pets_rounded, color: AppColors.sun, size: compact ? 20 : 23),
      ],
    ),
  );
}

class _BoardGrid extends StatefulWidget {
  const _BoardGrid({
    required this.level,
    required this.session,
    required this.onReveal,
    required this.onFlag,
  });

  final LevelDefinition level;
  final GameSession session;
  final ValueChanged<CellPosition> onReveal;
  final ValueChanged<CellPosition> onFlag;

  @override
  State<_BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends State<_BoardGrid> {
  static const _cellSize = 72.0;

  final TransformationController _controller = TransformationController();
  GameSession? _session;
  Size? _viewport;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final config = widget.session.config;
      final boardWidth =
          config.width * _cellSize + (config.width - 1) * BoardView.spacing;
      final boardHeight =
          config.height * _cellSize + (config.height - 1) * BoardView.spacing;
      final contentWidth = boardWidth + BoardView.padding * 2;
      final contentHeight = boardHeight + BoardView.padding * 2;
      final viewport = Size(constraints.maxWidth, constraints.maxHeight);
      final fitScale = min(
        1.0,
        min(viewport.width / contentWidth, viewport.height / contentHeight),
      );
      if (_session != widget.session || _viewport != viewport) {
        _session = widget.session;
        _viewport = viewport;
        _controller.value = Matrix4.diagonal3Values(fitScale, fitScale, 1)
          ..setTranslationRaw(
            (viewport.width - contentWidth * fitScale) / 2,
            (viewport.height - contentHeight * fitScale) / 2,
            0,
          );
      }
      return InteractiveViewer(
        key: const Key('refuge-board-viewer'),
        transformationController: _controller,
        constrained: false,
        minScale: fitScale,
        maxScale: max(1, min(2.4, fitScale * 5)),
        boundaryMargin: const EdgeInsets.all(BoardView.padding),
        child: SizedBox(
          width: contentWidth,
          height: contentHeight,
          child: Center(
            child: SizedBox(
              width: boardWidth,
              height: boardHeight,
              child: Column(
                children: [
                  for (var y = 0; y < config.height; y++) ...[
                    if (y > 0) const SizedBox(height: BoardView.spacing),
                    Row(
                      children: [
                        for (var x = 0; x < config.width; x++) ...[
                          if (x > 0) const SizedBox(width: BoardView.spacing),
                          _Cell(
                            key: Key('cell-$x-$y'),
                            size: _cellSize,
                            coveredColor: biomeCoveredColor(widget.level.biome),
                            animalAsset: widget.level.animalMarkerAsset,
                            snapshot: widget.session.cell(CellPosition(x, y)),
                            onReveal: () => widget.onReveal(CellPosition(x, y)),
                            onFlag: () => widget.onFlag(CellPosition(x, y)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Cell extends StatefulWidget {
  const _Cell({
    required this.size,
    required this.coveredColor,
    required this.animalAsset,
    required this.snapshot,
    required this.onReveal,
    required this.onFlag,
    super.key,
  });

  final double size;
  final Color coveredColor;
  final String? animalAsset;
  final CellSnapshot snapshot;
  final VoidCallback onReveal;
  final VoidCallback onFlag;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  final FocusNode _focusNode = FocusNode();
  Timer? _longPress;
  Offset? _pressPosition;
  bool _dragging = false;
  bool _longPressConsumed = false;
  bool _focused = false;
  bool _hovered = false;

  @override
  void dispose() {
    _longPress?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _pointerDown(PointerDownEvent event) {
    if ((event.buttons & kPrimaryButton) == 0) return;
    _focusNode.requestFocus();
    _pressPosition = event.position;
    _dragging = false;
    _longPressConsumed = false;
    _longPress = Timer(const Duration(milliseconds: 450), () {
      if (_dragging) return;
      _longPressConsumed = true;
      widget.onFlag();
    });
  }

  void _pointerMove(PointerMoveEvent event) {
    if (_pressPosition == null ||
        (event.position - _pressPosition!).distance <= 12) {
      return;
    }
    _dragging = true;
    _cancelLongPress();
  }

  void _pointerUp(PointerUpEvent event) {
    if (_pressPosition == null) return;
    _cancelLongPress();
    if (!_dragging && !_longPressConsumed) widget.onReveal();
    _pressPosition = null;
  }

  void _cancelLongPress() {
    _longPress?.cancel();
    _longPress = null;
  }

  KeyEventResult _keyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      widget.onReveal();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      widget.onFlag();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cell = widget.snapshot;
    var color = widget.coveredColor;
    var covered = true;
    Widget? content;
    Border? stateBorder;
    if (cell.isWrongFlag) {
      color = AppColors.surface;
      covered = false;
      stateBorder = Border.all(color: AppColors.danger, width: 3);
      content = const Icon(Icons.close_rounded, color: AppColors.danger);
    } else if (cell.isFlagged) {
      content = widget.animalAsset == null
          ? const Icon(Icons.pets_rounded, color: AppColors.deep)
          : Image.asset(
              widget.animalAsset!,
              key: const Key('flagged-animal-image'),
              width: widget.size * .9,
              height: widget.size * .9,
              fit: BoxFit.contain,
            );
    } else if (cell.isRevealed && cell.isAnimal) {
      covered = false;
      color = cell.isTriggeredAnimal ? AppColors.danger : AppColors.muted;
      content = Icon(
        cell.isTriggeredAnimal ? Icons.warning_rounded : Icons.pets_rounded,
        color: Colors.white,
      );
    } else if (cell.isRevealed) {
      covered = false;
      color = AppColors.surface;
      if (cell.adjacentAnimals > 0) {
        content = Text(
          '${cell.adjacentAnimals}',
          style: TextStyle(
            color: _indexColors[cell.adjacentAnimals]!,
            fontSize: (widget.size * .46).clamp(18, 48),
            fontWeight: FontWeight.w800,
          ),
        );
      }
    }
    final focusBorder = _focused
        ? Border.all(color: Colors.white, width: 3)
        : _hovered
        ? Border.all(color: AppColors.deep.withValues(alpha: .55), width: 2)
        : stateBorder;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      label: cell.isRevealed
          ? cell.isAnimal
                ? 'Animal'
                : cell.adjacentAnimals == 0
                ? 'Secteur vide'
                : '${cell.adjacentAnimals} animaux voisins'
          : cell.isFlagged
          ? 'Secteur balisé'
          : 'Secteur à observer',
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: _keyEvent,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Listener(
            onPointerDown: _pointerDown,
            onPointerMove: _pointerMove,
            onPointerUp: _pointerUp,
            onPointerCancel: (_) => _cancelLongPress(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTap: widget.onFlag,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: color,
                    gradient: covered
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(color, Colors.white, .16)!,
                              color,
                            ],
                          )
                        : null,
                    border: focusBorder,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: cell.isRevealed
                        ? [
                            BoxShadow(
                              color: AppColors.deep.withValues(alpha: .08),
                              blurRadius: 1,
                            ),
                          ]
                        : const [
                            BoxShadow(
                              color: Color(0x35183d32),
                              blurRadius: 4,
                              offset: Offset(0, 3),
                            ),
                          ],
                  ),
                  alignment: Alignment.center,
                  child: IconTheme(
                    data: IconThemeData(
                      size: (widget.size * .48).clamp(20, 46),
                    ),
                    child: content ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _indexColors = <int, Color>{
  1: Color(0xff2878b8),
  2: Color(0xff2e8b57),
  3: Color(0xffd95d4f),
  4: Color(0xff6656a3),
  5: Color(0xffa75536),
  6: Color(0xff168a8a),
  7: Color(0xff38404a),
  8: Color(0xff7a4d7d),
};

class _GenerationOverlay extends StatefulWidget {
  const _GenerationOverlay();

  @override
  State<_GenerationOverlay> createState() => _GenerationOverlayState();
}

class _GenerationOverlayState extends State<_GenerationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final leaf = Icon(
      Icons.eco_rounded,
      color: AppColors.sun,
      size: 52,
      semanticLabel: 'Préparation',
    );
    return ColoredBox(
      key: const Key('generation-overlay'),
      color: const Color(0xeb173d30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            reduceMotion
                ? leaf
                : RotationTransition(turns: _controller, child: leaf),
            const SizedBox(height: 20),
            const Text(
              'Préparation du refuge…',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'L’équipe sécurise la zone.',
              style: TextStyle(color: Color(0xffdbeee3)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndOverlay extends StatelessWidget {
  const _EndOverlay({
    required this.level,
    required this.session,
    required this.newRecord,
    required this.onReplaySame,
    required this.onReplayNew,
    required this.onNext,
    required this.onHome,
  });

  final LevelDefinition level;
  final GameSession session;
  final bool newRecord;
  final VoidCallback onReplaySame;
  final VoidCallback onReplayNew;
  final VoidCallback onNext;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final won = session.status == GameStatus.won;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Stack(
          key: const Key('end-overlay'),
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: compact ? Alignment.topCenter : Alignment.centerLeft,
                    end: compact
                        ? Alignment.bottomCenter
                        : Alignment.centerRight,
                    colors: [
                      AppColors.deep.withValues(alpha: compact ? .16 : .34),
                      AppColors.deep.withValues(alpha: .98),
                    ],
                    stops: compact ? const [.12, .42] : const [.28, .62],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: compact
                    ? Alignment.bottomCenter
                    : Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? constraints.maxWidth : 680,
                    maxHeight: constraints.maxHeight,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(compact ? 22 : 38),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (compact)
                          SizedBox(height: constraints.maxHeight * .22),
                        Icon(
                          won ? Icons.verified_rounded : Icons.pets_rounded,
                          color: won ? AppColors.sun : AppColors.danger,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          won ? 'REFUGE SÉCURISÉ !' : 'UN ANIMAL S’EST ÉLOIGNÉ',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          level.isCustom
                              ? level.title
                              : 'Niveau ${level.number} · ${level.title}',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          level.species,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xffe3eee8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (newRecord || session.isPractice) ...[
                          const SizedBox(height: 14),
                          Center(
                            child: _ResultBadge(
                              icon: newRecord
                                  ? Icons.emoji_events_rounded
                                  : Icons.replay_rounded,
                              text: newRecord
                                  ? 'Nouveau meilleur temps !'
                                  : 'Entraînement · record non enregistré',
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _ResultMetric(
                                label: 'Terrain',
                                value:
                                    '${level.config.width} × ${level.config.height}',
                              ),
                            ),
                            Expanded(
                              child: _ResultMetric(
                                label: 'Animaux',
                                value: '${level.config.animalCount}',
                              ),
                            ),
                            Expanded(
                              child: _ResultMetric(
                                label: 'Temps',
                                value: formatDuration(session.elapsed),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          won
                              ? 'Tous les animaux sont en sécurité.'
                              : 'Observe les indices avant de t’approcher.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xffe3eee8),
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (won)
                          if (!level.isCustom &&
                              level.number < levels.length) ...[
                            _PrimaryResultButton(
                              icon: Icons.arrow_forward_rounded,
                              label: 'Niveau suivant',
                              onPressed: onNext,
                            ),
                            _SecondaryResultButton(
                              icon: Icons.refresh_rounded,
                              label: 'Nouvelle observation',
                              onPressed: onReplayNew,
                            ),
                          ] else
                            _PrimaryResultButton(
                              icon: Icons.refresh_rounded,
                              label: 'Nouvelle observation',
                              onPressed: onReplayNew,
                            )
                        else
                          _PrimaryResultButton(
                            icon: Icons.replay_rounded,
                            label: 'Revoir cette grille',
                            onPressed: onReplaySame,
                          ),
                        if (won)
                          _SecondaryResultButton(
                            icon: Icons.replay_rounded,
                            label: level.isCustom
                                ? 'Revoir cette grille'
                                : 'Revoir cette grille · entraînement',
                            onPressed: onReplaySame,
                          )
                        else
                          _SecondaryResultButton(
                            icon: Icons.refresh_rounded,
                            label: 'Nouvelle observation',
                            onPressed: onReplayNew,
                          ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: onHome,
                          icon: Icon(
                            level.isCustom
                                ? Icons.home_rounded
                                : Icons.map_rounded,
                          ),
                          label: Text(
                            level.isCustom
                                ? 'Retour à l’accueil'
                                : 'Retour au parcours',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.sun.withValues(alpha: .28),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.sun, size: 19),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(color: Color(0xffb9d8c9))),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _PrimaryResultButton extends StatelessWidget {
  const _PrimaryResultButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: AppColors.success),
      icon: Icon(icon),
      label: Text(label),
    ),
  );
}

class _SecondaryResultButton extends StatelessWidget {
  const _SecondaryResultButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
      ),
      icon: Icon(icon),
      label: Text(label),
    ),
  );
}
