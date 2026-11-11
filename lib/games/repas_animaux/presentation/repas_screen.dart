import '../../../shared/clay_text.dart';
import '../../../shared/wooden_sign.dart';
import '../../../shared/board_camera.dart';
import '../../../shared/artwork.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/animal_scene.dart';
import '../../../shared/game_help.dart';
import '../../../shared/game_stage_layout.dart';
import '../domain/models.dart';
import '../domain/repas_session.dart';

class RepasScreen extends StatelessWidget {
  const RepasScreen({
    required this.session,
    required this.finished,
    required this.newRecord,
    this.freeGameLabel,
    required this.onMove,
    required this.onUndo,
    required this.onRestart,
    required this.onLevels,
    required this.onRetry,
    this.onNew,
    this.onConfigure,
    required this.onNext,
    super.key,
  });

  final RepasSession session;
  final bool finished;
  final bool newRecord;
  final String? freeGameLabel;
  final ValueChanged<RepasDirection> onMove;
  final VoidCallback onUndo;
  final VoidCallback onRestart;
  final VoidCallback onLevels;
  final VoidCallback onRetry;
  final VoidCallback? onNew;
  final VoidCallback? onConfigure;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: (_, event) {
      final direction = event is KeyDownEvent
          ? _keyDirection(event.logicalKey)
          : null;
      if (direction == null) return KeyEventResult.ignored;
      onMove(direction);
      return KeyEventResult.handled;
    },
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scale = min(
          constraints.maxWidth / 1672,
          constraints.maxHeight / 941,
        );
        if ((freeGameLabel != null || session.level.number != 19) &&
            scale >= .8 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
          return _integratedScene();
        }
        return _responsiveScene();
      },
    ),
  );

  Widget _responsiveScene() => GameStageLayout(
    wooden: true,
    scrim: Colors.transparent,
    background: ArtworkImage(
      session.level.resolvedBackgroundAsset,
      fit: BoxFit.cover,
    ),
    eyebrow: freeGameLabel ?? 'NIVEAU ${session.level.number}',
    title: session.level.stage.title,
    backKey: const Key('repas-back-to-levels'),
    onBack: onLevels,
    backTooltip: 'Retour aux niveaux',
    helpKind: GameHelpKind.repasAnimaux,
    metrics: [
      GameStageMetric(
        icon: Icons.inventory_2_rounded,
        label: '${session.cratesRemaining} à livrer',
      ),
      GameStageMetric(
        icon: Icons.directions_walk_rounded,
        label: '${session.moves}',
      ),
      GameStageMetric(
        icon: Icons.open_with_rounded,
        label: '${session.pushes} poussées',
      ),
    ],
    builder: (context, layout) => _MissionLayout(
      wide: layout.isLandscape,
      session: session,
      onMove: onMove,
      onUndo: onUndo,
      onRestart: onRestart,
    ),
    overlays: [
      if (finished)
        Positioned.fill(
          child: _ResultOverlay(
            session: session,
            newRecord: newRecord,
            freeGame: freeGameLabel != null,
            onLevels: onLevels,
            onRetry: onRetry,
            onNew: onNew,
            onConfigure: onConfigure,
            onNext: onNext,
          ),
        ),
    ],
  );

  Widget _integratedScene() => Scaffold(
    backgroundColor: const Color(0xff986a3e),
    body: Stack(
      children: [
        Positioned.fill(
          child: ArtworkImage(
            session.level.resolvedBackgroundAsset,
            fit: BoxFit.cover,
          ),
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
                        key: const Key('repas-scene-background'),
                        image: AssetImage(
                          animalSceneAsset(
                            session.level.number,
                            isFreeGame: freeGameLabel != null,
                          ),
                        ),
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned.fill(
                      child: RepasBoard(
                        session: session,
                        onMove: onMove,
                        integrated: true,
                      ),
                    ),
                    Positioned(
                      left: 60,
                      top: 42,
                      width: 110,
                      height: 110,
                      child: IconButton(
                        key: const Key('repas-back-to-levels'),
                        tooltip: 'Retour aux niveaux',
                        onPressed: onLevels,
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
                            'LE REPAS DES ANIMAUX',
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
                            alignment: Alignment.centerLeft,
                            child: ClayText(
                              freeGameLabel ?? 'Niveau ${session.level.number}',
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
                        icon: Icons.inventory_2_rounded,
                        label: '${session.cratesRemaining} à livrer',
                      ),
                    ),
                    Positioned(
                      left: 973,
                      top: 76,
                      width: 320,
                      height: 60,
                      child: _SceneMetric(
                        icon: Icons.directions_walk_rounded,
                        label: '${session.moves} · ${session.pushes} poussées',
                      ),
                    ),
                    const Positioned(
                      left: 1351,
                      top: 70,
                      width: 75,
                      height: 75,
                      child: GameHelpButton(
                        kind: GameHelpKind.repasAnimaux,
                        color: Color(0xffffecd0),
                        iconSize: 52,
                      ),
                    ),
                    Positioned(
                      left: 1190,
                      top: 310,
                      width: 430,
                      height: 390,
                      child: _SceneCommands(
                        session: session,
                        onMove: onMove,
                        onUndo: onUndo,
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
                freeGame: freeGameLabel != null,
                onLevels: onLevels,
                onRetry: onRetry,
                onNew: onNew,
                onConfigure: onConfigure,
                onNext: onNext,
              ),
            ),
          ),
      ],
    ),
  );

  RepasDirection? _keyDirection(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      return RepasDirection.north;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      return RepasDirection.east;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      return RepasDirection.south;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      return RepasDirection.west;
    }
    return null;
  }
}

class _MissionLayout extends StatelessWidget {
  const _MissionLayout({
    required this.wide,
    required this.session,
    required this.onMove,
    required this.onUndo,
    required this.onRestart,
  });

  final bool wide;
  final RepasSession session;
  final ValueChanged<RepasDirection> onMove;
  final VoidCallback onUndo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      return GameStageSplit(
        wide: wide,
        board: RepasBoard(session: session, onMove: onMove),
        panel: _MissionPanel(
          session: session,
          onMove: onMove,
          onUndo: onUndo,
          onRestart: onRestart,
        ),
      );
    },
  );
}

class RepasBoard extends StatefulWidget {
  const RepasBoard({
    required this.session,
    required this.onMove,
    this.integrated = false,
    super.key,
  });

  final bool integrated;

  final RepasSession session;
  final ValueChanged<RepasDirection> onMove;

  @override
  State<RepasBoard> createState() => _RepasBoardState();
}

class _RepasBoardState extends State<RepasBoard> {
  Offset _drag = Offset.zero;
  final Set<int> _pointers = {};
  bool _singlePointer = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final level = widget.session.level;
      final geometry = _BoardGeometry.fit(
        BoxConstraints(
          maxWidth: widget.integrated ? 555 : max(1, constraints.maxWidth - 48),
          maxHeight: widget.integrated ? 531 : constraints.maxHeight,
        ),
        bounds: level.boardBounds,
      );
      return BoardCamera(
        viewerKey: const Key('repas-board'),
        wooden: true,
        layoutBuilder: widget.integrated
            ? (context, viewport, controls) => Stack(
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
              )
            : null,
        clipBehavior: Clip.hardEdge,
        minScale: 1,
        maxScale: 3,
        panEnabled: true,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            _pointers.add(event.pointer);
            _singlePointer = _pointers.length == 1;
            _drag = Offset.zero;
          },
          onPointerMove: (event) {
            if (_singlePointer && _pointers.length == 1) {
              _drag += event.delta;
            }
          },
          onPointerUp: (event) {
            final move = _singlePointer && _pointers.length == 1;
            _pointers.remove(event.pointer);
            if (move) _finishDrag();
            if (_pointers.isEmpty) _singlePointer = false;
          },
          onPointerCancel: (event) {
            _pointers.remove(event.pointer);
            if (_pointers.isEmpty) _singlePointer = false;
          },
          child: Center(
            child: RepaintBoundary(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  geometry.cellWidth * .08,
                  geometry.cellWidth * .31,
                  geometry.cellWidth * .08,
                  geometry.cellWidth * .04,
                ),
                child: _BoardScene(session: widget.session, geometry: geometry),
              ),
            ),
          ),
        ),
      );
    },
  );

  void _finishDrag() {
    if (_drag.distance < 18) return;
    final horizontal = _drag.dx.abs() > _drag.dy.abs();
    widget.onMove(
      horizontal
          ? (_drag.dx > 0 ? RepasDirection.east : RepasDirection.west)
          : (_drag.dy > 0 ? RepasDirection.south : RepasDirection.north),
    );
  }
}

class _BoardGeometry {
  const _BoardGeometry({required this.cellWidth, required this.bounds});

  factory _BoardGeometry.fit(
    BoxConstraints constraints, {
    required RepasBoardBounds bounds,
  }) => _BoardGeometry(
    cellWidth: min(
      constraints.maxWidth / (bounds.width + .16),
      constraints.maxHeight / (bounds.height * .88 + .35),
    ),
    bounds: bounds,
  );

  final double cellWidth;
  final RepasBoardBounds bounds;

  double get cellHeight => cellWidth * .88;
  double get innerWidth => cellWidth * bounds.width;
  double get innerHeight => cellHeight * bounds.height;
  bool contains(RepasPosition position) =>
      position.x >= bounds.origin.x &&
      position.y >= bounds.origin.y &&
      position.x < bounds.origin.x + bounds.width &&
      position.y < bounds.origin.y + bounds.height;
  double leftFor(RepasPosition position) =>
      (position.x - bounds.origin.x) * cellWidth;
  double topFor(RepasPosition position) =>
      (position.y - bounds.origin.y) * cellHeight;
}

class _BoardScene extends StatelessWidget {
  const _BoardScene({required this.session, required this.geometry});

  final RepasSession session;
  final _BoardGeometry geometry;

  @override
  Widget build(BuildContext context) {
    final level = session.level;
    final sprites =
        [
          for (final position in level.walls)
            if (geometry.contains(position))
              _BoardItem(
                position: position,
                asset: 'assets/sokoban/fence-v2.png',
                scale: 1.15,
                anchor: .96,
              ),
          for (final position in session.crates)
            _BoardItem(
              position: position,
              asset: _foodCrateAsset(level.number),
              key: Key('repas-crate-${position.x}-${position.y}'),
              scale: 1.05,
              anchor: 1.02,
            ),
          _BoardItem(
            position: session.keeper,
            asset: 'assets/sokoban/keeper-${session.facing.name}.png',
            key: const Key('repas-keeper'),
            scale: 1.10,
            anchor: 1.04,
          ),
        ]..sort((a, b) {
          final depth = a.depth.compareTo(b.depth);
          return depth != 0 ? depth : a.position.x.compareTo(b.position.x);
        });
    final board = Stack(
      clipBehavior: Clip.none,
      children: [
        for (var y = 0; y < geometry.bounds.height; y++)
          for (var x = 0; x < geometry.bounds.width; x++)
            Positioned(
              left: x * geometry.cellWidth,
              top: y * geometry.cellHeight,
              width: geometry.cellWidth,
              height: geometry.cellHeight,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ArtworkImage(
                    'assets/sokoban/grid-cell-overlay.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
        for (final position in level.targets)
          _BoardSprite(
            position: position,
            geometry: geometry,
            asset: 'assets/sokoban/feeding-spot-v2.png',
            scale: 1,
            anchor: .88,
            imageKey: Key('repas-target-${position.x}-${position.y}'),
          ),
        for (final sprite in sprites)
          _BoardSprite(
            position: sprite.position,
            geometry: geometry,
            asset: sprite.asset,
            scale: sprite.scale,
            anchor: sprite.anchor,
            imageKey: sprite.key,
          ),
        for (var y = 0; y < geometry.bounds.height; y++)
          for (var x = 0; x < geometry.bounds.width; x++)
            _BoardSemanticsCell(
              position: RepasPosition(
                x + geometry.bounds.origin.x,
                y + geometry.bounds.origin.y,
              ),
              geometry: geometry,
              session: session,
            ),
      ],
    );
    return SizedBox(
      width: geometry.innerWidth,
      height: geometry.innerHeight,
      child: board,
    );
  }
}

class _BoardSprite extends StatelessWidget {
  const _BoardSprite({
    required this.position,
    required this.geometry,
    required this.asset,
    required this.scale,
    required this.anchor,
    this.imageKey,
  });

  final RepasPosition position;
  final _BoardGeometry geometry;
  final String asset;
  final double scale;
  final double anchor;
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    final size = geometry.cellWidth * scale;
    return Positioned(
      left: geometry.leftFor(position) + (geometry.cellWidth - size) / 2,
      top: geometry.topFor(position) + anchor * geometry.cellHeight - size,
      width: size,
      height: size,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: ArtworkImage(
            asset,
            key: imageKey,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _BoardSemanticsCell extends StatelessWidget {
  const _BoardSemanticsCell({
    required this.position,
    required this.geometry,
    required this.session,
  });

  final RepasPosition position;
  final _BoardGeometry geometry;
  final RepasSession session;

  @override
  Widget build(BuildContext context) {
    final level = session.level;
    final wall = level.walls.contains(position);
    final floor = level.floor.contains(position);
    if (!wall && !floor) return const SizedBox.shrink();
    final target = level.targets.contains(position);
    final crate = session.crates.contains(position);
    final keeper = session.keeper == position;
    return Positioned(
      key: Key('repas-cell-${position.x}-${position.y}'),
      left: geometry.leftFor(position),
      top: geometry.topFor(position),
      width: geometry.cellWidth,
      height: geometry.cellHeight,
      child: Semantics(
        label: wall
            ? 'Clôture'
            : keeper
            ? 'Soigneur'
            : crate
            ? 'Caisse de nourriture${target ? ' livrée' : ''}'
            : target
            ? 'Point de nourrissage'
            : 'Allée',
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BoardItem {
  const _BoardItem({
    required this.position,
    required this.asset,
    required this.scale,
    required this.anchor,
    this.key,
  });

  final RepasPosition position;
  final String asset;
  final Key? key;
  final double scale;
  final double anchor;

  double get depth => position.y + anchor;
}

String _foodCrateAsset(int stage) {
  final food = switch (stage) {
    2 ||
    11 ||
    15 ||
    18 ||
    19 ||
    20 ||
    26 ||
    28 ||
    30 ||
    35 ||
    41 ||
    42 ||
    43 => 'meat',
    6 || 7 || 8 || 13 || 16 || 25 || 37 || 38 || 39 || 40 || 44 => 'fruit',
    9 || 34 => 'fish',
    1 || 10 || 14 || 27 || 32 => 'mixed',
    _ => 'herbivore',
  };
  return 'assets/sokoban/food-crate-$food.png';
}

class _SceneMetric extends StatelessWidget {
  const _SceneMetric({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: const Color(0xffffecd0), size: 39),
      const SizedBox(width: 10),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ClayText(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xffffecd0),
              fontWeight: FontWeight.w900,
              fontSize: 29,
              shadows: [
                Shadow(
                  color: Color(0xff523017),
                  blurRadius: 4,
                  offset: Offset(1, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _SceneCommands extends StatelessWidget {
  const _SceneCommands({
    required this.session,
    required this.onMove,
    required this.onUndo,
    required this.onRestart,
  });
  final RepasSession session;
  final ValueChanged<RepasDirection> onMove;
  final VoidCallback onUndo, onRestart;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _DirectionPad(onMove: onMove, wooden: true),
      const SizedBox(height: 20),
      _sign(
        const Key('repas-undo'),
        Icons.undo_rounded,
        'ANNULER',
        session.canUndo ? onUndo : null,
      ),
      const SizedBox(height: 12),
      _sign(
        const Key('repas-restart'),
        Icons.refresh_rounded,
        'RECOMMENCER',
        onRestart,
      ),
    ],
  );
  Widget _sign(Key key, IconData icon, String label, VoidCallback? action) =>
      SizedBox(
        width: double.infinity,
        height: 75,
        child: WoodenSign(
          child: TextButton.icon(
            key: key,
            onPressed: action,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xffffedc2),
              disabledForegroundColor: const Color(0xffa98f6c),
            ),
            icon: Icon(icon, size: 35),
            label: Text(
              label,
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );
}

class _MissionPanel extends StatelessWidget {
  const _MissionPanel({
    required this.session,
    required this.onMove,
    required this.onUndo,
    required this.onRestart,
  });

  final RepasSession session;
  final ValueChanged<RepasDirection> onMove;
  final VoidCallback onUndo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => GameStagePanel(
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        _DirectionPad(onMove: onMove),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ControlButton(
              key: const Key('repas-undo'),
              tooltip: 'Annuler',
              onPressed: session.canUndo ? onUndo : null,
              icon: Icons.undo_rounded,
            ),
            const SizedBox(height: 8),
            _ControlButton(
              key: const Key('repas-restart'),
              tooltip: 'Recommencer',
              onPressed: onRestart,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ],
    ),
  );
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.wooden = false,
    super.key,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool wooden;

  @override
  Widget build(BuildContext context) {
    if (wooden) {
      return SizedBox.square(
        dimension: 48,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/optimized/sudoku/camera-stone.webp'),
              fit: BoxFit.fill,
            ),
          ),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            color: const Color(0xff226957),
            iconSize: 28,
            icon: Icon(icon),
          ),
        ),
      );
    }
    return Material(
      color: onPressed == null
          ? Colors.white.withValues(alpha: .12)
          : wooden
          ? const Color(0xff80552f)
          : AppColors.success,
      elevation: onPressed == null ? 0 : 5,
      shadowColor: const Color(0x660f2f26),
      borderRadius: BorderRadius.circular(15),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        disabledColor: Colors.white.withValues(alpha: .3),
        icon: Icon(icon),
      ),
    );
  }
}

class _DirectionPad extends StatelessWidget {
  const _DirectionPad({required this.onMove, this.wooden = false});

  final bool wooden;

  final ValueChanged<RepasDirection> onMove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    height: 104,
    child: Stack(
      children: [
        _button(RepasDirection.north, Icons.arrow_upward_rounded, 56, 0),
        _button(RepasDirection.west, Icons.arrow_back_rounded, 0, 56),
        _button(RepasDirection.south, Icons.arrow_downward_rounded, 56, 56),
        _button(RepasDirection.east, Icons.arrow_forward_rounded, 112, 56),
      ],
    ),
  );

  Widget _button(
    RepasDirection direction,
    IconData icon,
    double left,
    double top,
  ) => Positioned(
    left: left,
    top: top,
    child: _ControlButton(
      key: Key('repas-move-${direction.name}'),
      tooltip: switch (direction) {
        RepasDirection.north => 'Monter',
        RepasDirection.east => 'Aller à droite',
        RepasDirection.south => 'Descendre',
        RepasDirection.west => 'Aller à gauche',
      },
      onPressed: () => onMove(direction),
      icon: icon,
      wooden: wooden,
    ),
  );
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.session,
    required this.newRecord,
    required this.freeGame,
    required this.onLevels,
    required this.onRetry,
    required this.onNew,
    required this.onConfigure,
    required this.onNext,
  });

  final RepasSession session;
  final bool newRecord;
  final bool freeGame;
  final VoidCallback onLevels;
  final VoidCallback onRetry;
  final VoidCallback? onNew;
  final VoidCallback? onConfigure;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('repas-result-overlay'),
    color: const Color(0x990f2f26),
    child: GameResultViewport(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GameResultPanel(
          biome: session.level.stage.biome,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  size: 54,
                  color: AppColors.sun,
                ),
                const SizedBox(height: 10),
                Text(
                  'REPAS DISTRIBUÉ !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  freeGame
                      ? '${session.pushes} poussées'
                      : '${session.pushes} poussées · '
                            '${session.footprints()} empreinte(s)'
                            '${newRecord ? '\nNouveau record !' : ''}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                if (onNew != null)
                  FilledButton.icon(
                    key: const Key('repas-new-free-game'),
                    onPressed: onNew,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('NOUVELLE GRILLE'),
                  )
                else if (onNext != null)
                  FilledButton.icon(
                    key: const Key('repas-next-level'),
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('NIVEAU SUIVANT'),
                  ),
                TextButton.icon(
                  key: const Key('repas-retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('REJOUER'),
                ),
                if (onConfigure != null)
                  TextButton.icon(
                    onPressed: onConfigure,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('CONFIGURER'),
                  )
                else
                  TextButton.icon(
                    onPressed: onLevels,
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('CHOISIR UN NIVEAU'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
