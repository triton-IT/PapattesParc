import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/animal_background.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/game_help.dart';
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: AnimalBackground(
      asset: session.level.stage.artAsset!,
      child: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            final direction = event is KeyDownEvent
                ? _keyDirection(event.logicalKey)
                : null;
            if (direction == null) return KeyEventResult.ignored;
            onMove(direction);
            return KeyEventResult.handled;
          },
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth >= 900 &&
                      constraints.maxWidth > constraints.maxHeight;
                  final board = RepasBoard(session: session, onMove: onMove);
                  final panel = _MissionPanel(
                    session: session,
                    modeLabel: freeGameLabel,
                    compact: !wide,
                    onMove: onMove,
                    onUndo: onUndo,
                    onRestart: onRestart,
                  );
                  if (wide) {
                    return Row(
                      children: [
                        Expanded(child: board),
                        SizedBox(width: 340, child: panel),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 54),
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
                  key: const Key('repas-back-to-levels'),
                  tooltip: 'Retour aux niveaux',
                  onPressed: onLevels,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const Positioned(
                right: 12,
                top: 12,
                child: GameHelpButton(kind: GameHelpKind.repasAnimaux),
              ),
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
        ),
      ),
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
      final cellSize = min(
        (constraints.maxWidth - 24) / level.width,
        (constraints.maxHeight - 24) / level.height,
      );
      return Listener(
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
        child: InteractiveViewer(
          key: const Key('repas-board'),
          minScale: 1,
          maxScale: 3,
          panEnabled: false,
          child: Center(
            child: SizedBox(
              width: cellSize * level.width,
              height: cellSize * level.height,
              child: Stack(
                children: [
                  for (var y = 0; y < level.height; y++)
                    for (var x = 0; x < level.width; x++)
                      _BoardCell(
                        position: RepasPosition(x, y),
                        size: cellSize,
                        session: widget.session,
                      ),
                ],
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

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.position,
    required this.size,
    required this.session,
  });

  final RepasPosition position;
  final double size;
  final RepasSession session;

  @override
  Widget build(BuildContext context) {
    final level = session.level;
    final wall = level.walls.contains(position);
    final floor = level.floor.contains(position);
    if (!wall && !floor) return const SizedBox.shrink();
    final boundary =
        position.x == 0 ||
        position.y == 0 ||
        position.x == level.width - 1 ||
        position.y == level.height - 1;
    final target = level.targets.contains(position);
    final crate = session.crates.contains(position);
    final keeper = session.keeper == position;
    return Positioned(
      key: Key('repas-cell-${position.x}-${position.y}'),
      left: position.x * size,
      top: position.y * size,
      width: size,
      height: size,
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: wall
                ? biomeCoveredColor(level.stage.biome)
                : biomeBoardColor(level.stage.biome),
            border: Border.all(
              color: Colors.white.withValues(alpha: .22),
              width: .7,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (wall && !boundary)
                Image.asset('assets/sokoban/fence-v2.png', fit: BoxFit.contain),
              if (target)
                Image.asset(
                  'assets/sokoban/feeding-spot-v2.png',
                  key: Key('repas-target-${position.x}-${position.y}'),
                  fit: BoxFit.contain,
                ),
              if (crate)
                Image.asset(
                  _foodCrateAsset(level.number),
                  key: Key('repas-crate-${position.x}-${position.y}'),
                  fit: BoxFit.contain,
                ),
              if (keeper)
                Image.asset(
                  'assets/sokoban/keeper-${session.facing.name}.png',
                  key: const Key('repas-keeper'),
                  fit: BoxFit.contain,
                ),
            ],
          ),
        ),
      ),
    );
  }
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
    required this.modeLabel,
    required this.compact,
    required this.onMove,
    required this.onUndo,
    required this.onRestart,
  });

  final RepasSession session;
  final String? modeLabel;
  final bool compact;
  final ValueChanged<RepasDirection> onMove;
  final VoidCallback onUndo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.fromLTRB(12, compact ? 0 : 70, 12, 12),
    child: Padding(
      padding: EdgeInsets.all(compact ? 10 : 18),
      child: compact
          ? Row(
              children: [
                Expanded(child: _Counters(session: session)),
                _DirectionPad(onMove: onMove),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const Key('repas-undo'),
                      tooltip: 'Annuler',
                      onPressed: session.canUndo ? onUndo : null,
                      icon: const Icon(Icons.undo_rounded),
                    ),
                    IconButton(
                      key: const Key('repas-restart'),
                      tooltip: 'Recommencer',
                      onPressed: onRestart,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  modeLabel ?? 'NIVEAU ${session.level.number}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  session.level.stage.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(session.level.stage.species),
                const SizedBox(height: 20),
                _Counters(session: session),
                const Spacer(),
                Center(child: _DirectionPad(onMove: onMove)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        key: const Key('repas-undo'),
                        onPressed: session.canUndo ? onUndo : null,
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('ANNULER'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      key: const Key('repas-restart'),
                      tooltip: 'Recommencer',
                      onPressed: onRestart,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ],
            ),
    ),
  );
}

class _Counters extends StatelessWidget {
  const _Counters({required this.session});

  final RepasSession session;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      _Counter(
        icon: Icons.inventory_2_rounded,
        label: '${session.cratesRemaining} à livrer',
      ),
      _Counter(icon: Icons.directions_walk_rounded, label: '${session.moves}'),
      _Counter(
        icon: Icons.open_with_rounded,
        label: '${session.pushes} poussées',
      ),
    ],
  );
}

class _Counter extends StatelessWidget {
  const _Counter({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _DirectionPad extends StatelessWidget {
  const _DirectionPad({required this.onMove});

  final ValueChanged<RepasDirection> onMove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 132,
    height: 92,
    child: Stack(
      children: [
        _button(RepasDirection.north, Icons.keyboard_arrow_up_rounded, 44, 0),
        _button(RepasDirection.west, Icons.keyboard_arrow_left_rounded, 0, 44),
        _button(
          RepasDirection.south,
          Icons.keyboard_arrow_down_rounded,
          44,
          44,
        ),
        _button(
          RepasDirection.east,
          Icons.keyboard_arrow_right_rounded,
          88,
          44,
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
    child: IconButton.filledTonal(
      key: Key('repas-move-${direction.name}'),
      tooltip: switch (direction) {
        RepasDirection.north => 'Monter',
        RepasDirection.east => 'Aller à droite',
        RepasDirection.south => 'Descendre',
        RepasDirection.west => 'Aller à gauche',
      },
      onPressed: () => onMove(direction),
      icon: Icon(icon),
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
    child: Center(
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
