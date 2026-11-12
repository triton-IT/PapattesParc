import '../../../shared/clay_text.dart';
import '../../../shared/wooden_sign.dart';
import '../../../shared/board_camera.dart';
import '../../../shared/animal_scene.dart';
import '../../../shared/artwork.dart';
import 'package:flutter/foundation.dart';
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
import '../../../shared/game_stage_layout.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({
    this.elapsed,
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

  final ValueListenable<Duration>? elapsed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = min(
        constraints.maxWidth / 1672,
        constraints.maxHeight / 941,
      );
      if ((level.isCustom || level.number != 19) &&
          scale >= .8 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
        return _integratedScene(context);
      }
      return _responsiveScene(context);
    },
  );

  Widget _responsiveScene(BuildContext context) => GameStageLayout(
    background: LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= 900 &&
            constraints.maxWidth > constraints.maxHeight;
        return Transform.scale(
          scale: wide ? 1.12 : 1.2,
          alignment: wide ? Alignment.centerRight : Alignment.bottomCenter,
          child: LevelBackdrop(level: level),
        );
      },
    ),
    backgroundOverlay: const _GameBackdropVeil(),
    wooden: true,
    scrim: Colors.transparent,
    eyebrow: level.isCustom
        ? 'PARTIE LIBRE'
        : 'MISSION ${level.number.toString().padLeft(2, '0')}',
    title: level.isCustom
        ? level.title
        : 'Niveau ${level.number} · ${level.title}',
    backKey: const Key('back-to-course'),
    onBack: onHome,
    backTooltip: level.isCustom ? 'Accueil' : 'Parcours',
    helpKind: GameHelpKind.refuge,
    metrics: [
      GameStageMetric(
        icon: Icons.pets_rounded,
        label: 'À localiser : ${session.remainingAnimals}',
      ),
      GameStageMetric(
        icon: Icons.timer_rounded,
        elapsed: elapsed,
        label: formatDuration(session.elapsed),
      ),
    ],
    builder: (context, layout) => BoardView(
      level: level,
      session: session,
      onReveal: onReveal,
      onFlag: onFlag,
    ),
    overlays: [
      if (generating) const Positioned.fill(child: _GenerationOverlay()),
      if (finished)
        Positioned.fill(
          child: _EndOverlay(
            level: level,
            session: session,
            newRecord: newRecord,
            onReplaySame: onReplaySame,
            onReplayNew: onReplayNew,
            onNext: onNext,
            onHome: onHome,
          ),
        ),
    ],
  );
  Widget _integratedScene(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff986a3e),
    body: Stack(
      children: [
        Positioned.fill(
          child: ArtworkImage(level.artAsset!, fit: BoxFit.cover),
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
                        key: const Key('refuge-scene-background'),
                        image: AssetImage(
                          animalSceneAsset(
                            level.number,
                            isFreeGame: level.isCustom,
                          ),
                        ),
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned.fill(
                      child: _BoardGrid(
                        level: level,
                        session: session,
                        onReveal: onReveal,
                        onFlag: onFlag,
                        integrated: true,
                      ),
                    ),
                    Positioned(
                      left: 60,
                      top: 42,
                      width: 110,
                      height: 110,
                      child: IconButton(
                        key: const Key('back-to-course'),
                        tooltip: level.isCustom ? 'Accueil' : 'Parcours',
                        onPressed: onHome,
                        color: const Color(0xffffedcb),
                        iconSize: 65,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                            'BALISES DU REFUGE',
                            maxLines: 1,
                            style: TextStyle(
                              color: Color(0xffffcc69),
                              fontSize: 28,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ClayText(
                              level.isCustom
                                  ? 'Partie libre'
                                  : 'Niveau ${level.number} · ${level.title}',
                              style: const TextStyle(
                                color: Color(0xffffefd5),
                                fontSize: 40,
                                height: 1,
                                fontWeight: FontWeight.w900,
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
                      child: _RefugeMetric(
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
                      child: _RefugeMetric(
                        icon: Icons.pets_rounded,
                        label: 'À localiser : ${session.remainingAnimals}',
                      ),
                    ),
                    const Positioned(
                      left: 1351,
                      top: 70,
                      width: 75,
                      height: 75,
                      child: GameHelpButton(
                        kind: GameHelpKind.refuge,
                        color: Color(0xffffecd0),
                        iconSize: 52,
                      ),
                    ),
                    Positioned(
                      left: 1190,
                      top: 329,
                      width: 430,
                      height: 350,
                      child: Container(
                        padding: const EdgeInsets.all(34),
                        decoration: parchmentDecoration,
                        child: const SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets_rounded,
                                size: 54,
                                color: Color(0xff79502c),
                              ),
                              SizedBox(height: 18),
                              Text(
                                'OBSERVE ET BALISE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xff563619),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Touche une case pour observer.\nMaintiens-la ou fais un clic droit pour poser une balise.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xff563619),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
        if (generating) const Positioned.fill(child: _GenerationOverlay()),
        if (finished)
          Positioned.fill(
            child: _EndOverlay(
              level: level,
              session: session,
              newRecord: newRecord,
              onReplaySame: onReplaySame,
              onReplayNew: onReplayNew,
              onNext: onNext,
              onHome: onHome,
            ),
          ),
      ],
    ),
  );
}

class _RefugeMetric extends StatelessWidget {
  const _RefugeMetric({required this.icon, required this.label, this.elapsed});
  final IconData icon;
  final String label;
  final ValueListenable<Duration>? elapsed;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: const Color(0xffffecd0), size: 39),
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

class _GameBackdropVeil extends StatelessWidget {
  const _GameBackdropVeil();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900 && size.width > size.height;
    return Stack(
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
      final short =
          constraints.maxWidth > constraints.maxHeight &&
          constraints.maxHeight < 400;
      final config = session.config;
      final compactHeight =
          config.height * 48 + (config.height - 1) * spacing + padding * 2 + 54;
      return Padding(
        padding: EdgeInsets.all(
          short
              ? 8
              : compact
              ? 12
              : 20,
        ),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: wide ? min(820, constraints.maxWidth * .47) : 820,
              maxHeight: 820,
            ),
            child: SizedBox(
              height: compact && !short
                  ? min(compactHeight, constraints.maxHeight - 24)
                  : null,
              child: Flex(
                key: const Key('board-background'),
                direction: short ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (short)
                    SizedBox(
                      width: 160,
                      child: Center(
                        child: _BoardLabel(level: level, compact: true),
                      ),
                    )
                  else
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
    this.integrated = false,
  });

  final LevelDefinition level;
  final GameSession session;
  final ValueChanged<CellPosition> onReveal;
  final ValueChanged<CellPosition> onFlag;
  final bool integrated;

  @override
  State<_BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends State<_BoardGrid> {
  static const _cellSize = 72.0;
  // Inset the camera viewport from the illustrated frame, including when
  // the player zooms or pans the board.
  static const _integratedViewport = Rect.fromLTWH(213, 245, 515, 491);

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
      final viewport = widget.integrated
          ? _integratedViewport.size
          : Size(
              (constraints.maxWidth - 48).clamp(1, double.infinity),
              constraints.maxHeight,
            );
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
      return BoardCamera(
        viewerKey: const Key('refuge-board-viewer'),
        wooden: true,
        layoutBuilder: widget.integrated
            ? (context, viewport, controls) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: _integratedViewport.left,
                    top: _integratedViewport.top,
                    width: _integratedViewport.width,
                    height: _integratedViewport.height,
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
              )
            : null,
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
    if (!_dragging &&
        !_longPressConsumed &&
        !BoardCamera.isNavigating(context)) {
      widget.onReveal();
    }
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
          : ArtworkImage(
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
                    image: covered
                        ? const DecorationImage(
                            image: AssetImage(
                              'assets/optimized/sudoku/sandstone-tile.webp',
                            ),
                            fit: BoxFit.fill,
                          )
                        : null,
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
    return ColoredBox(
      key: const Key('end-overlay'),
      color: const Color(0xaa173a31),
      child: GameResultViewport(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: GameResultPanel(
            biome: level.biome,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    won ? Icons.verified_rounded : Icons.pets_rounded,
                    color: AppColors.sun,
                    size: 44,
                  ),
                  Text(
                    won ? 'REFUGE SÉCURISÉ !' : 'UN ANIMAL S’EST ÉLOIGNÉ',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xff3f3a20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    level.isCustom
                        ? level.title
                        : 'Niveau ${level.number} · ${level.title}',
                    textAlign: TextAlign.center,
                  ),
                  Text(level.species, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    '${level.config.width} × ${level.config.height} · ${level.config.animalCount} animaux · ${formatDuration(session.elapsed)}',
                    textAlign: TextAlign.center,
                  ),
                  if (newRecord || session.isPractice)
                    Text(
                      newRecord
                          ? 'Nouveau meilleur temps !'
                          : 'Entraînement · record non enregistré',
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    won
                        ? 'Tous les animaux sont en sécurité.'
                        : 'Observe les indices avant de t’approcher.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (won && !level.isCustom && level.number < levels.length)
                    FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Niveau suivant'),
                    ),
                  if (won)
                    TextButton.icon(
                      onPressed: onReplayNew,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Nouvelle observation'),
                    ),
                  TextButton.icon(
                    onPressed: onReplaySame,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(
                      won && !level.isCustom
                          ? 'Revoir cette grille · entraînement'
                          : 'Revoir cette grille',
                    ),
                  ),
                  if (!won)
                    TextButton.icon(
                      onPressed: onReplayNew,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Nouvelle observation'),
                    ),
                  TextButton.icon(
                    onPressed: onHome,
                    icon: Icon(
                      level.isCustom ? Icons.home_rounded : Icons.map_rounded,
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
    );
  }
}
