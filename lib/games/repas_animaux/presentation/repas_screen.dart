import '../../../shared/board_camera.dart';
import '../../../shared/artwork.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/app_theme.dart';
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
    child: GameStageLayout(
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
  const RepasBoard({required this.session, required this.onMove, super.key});

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
          maxWidth: max(1, constraints.maxWidth - 48),
          maxHeight: constraints.maxHeight,
        ),
        bounds: level.boardBounds,
      );
      return BoardCamera(
        viewerKey: const Key('repas-board'),
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
    super.key,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Material(
    color: onPressed == null
        ? Colors.white.withValues(alpha: .12)
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

class _DirectionPad extends StatelessWidget {
  const _DirectionPad({required this.onMove});

  final ValueChanged<RepasDirection> onMove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    height: 104,
    child: Stack(
      children: [
        _button(RepasDirection.north, Icons.keyboard_arrow_up_rounded, 56, 0),
        _button(RepasDirection.west, Icons.keyboard_arrow_left_rounded, 0, 56),
        _button(
          RepasDirection.south,
          Icons.keyboard_arrow_down_rounded,
          56,
          56,
        ),
        _button(
          RepasDirection.east,
          Icons.keyboard_arrow_right_rounded,
          112,
          56,
        ),
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
        child: Card(
          margin: const EdgeInsets.all(20),
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
                FilledButton.tonalIcon(
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
