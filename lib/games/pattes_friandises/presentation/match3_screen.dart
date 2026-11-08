import 'dart:math' as math;
import '../../../shared/animal_scene.dart';
import '../../../shared/board_camera.dart';
import '../../../shared/game_gesture_target.dart';
import '../../../shared/artwork.dart';
import 'package:flutter/material.dart';

import '../../../shared/animal_colors.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/game_help.dart';
import '../../../shared/game_stage_layout.dart';
import '../domain/match3_session.dart';
import '../domain/models.dart';

class Match3Screen extends StatelessWidget {
  const Match3Screen({
    required this.session,
    this.displayed,
    this.clearing = const {},
    this.cascade = 0,
    this.inputEnabled = true,
    this.showResult,
    required this.selected,
    required this.onSelect,
    required this.onSwap,
    required this.onLevels,
    required this.onRetry,
    required this.onNext,
    this.isFreeGame = false,
    this.onConfigure,
    this.onBack,
    super.key,
  });

  final Match3Session session;
  final Match3BoardSnapshot? displayed;
  final Set<Match3Position> clearing;
  final int cascade;
  final bool inputEnabled;
  final bool? showResult;
  final Match3Position? selected;
  final ValueChanged<Match3Position> onSelect;
  final void Function(Match3Position, Match3Position) onSwap;
  final VoidCallback onLevels;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final bool isFreeGame;
  final VoidCallback? onConfigure;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = math.min(
        constraints.maxWidth / 1672,
        constraints.maxHeight / 941,
      );
      if ((isFreeGame || session.level.number != 19) &&
          scale >= .8 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
        return _integratedScene(context);
      }
      return _responsiveScene();
    },
  );

  Widget _responsiveScene() => GameStageLayout(
    background: session.level.number == 1 && !isFreeGame
        ? const Image(
            image: AssetImage('assets/optimized/sudoku/savanna.webp'),
            fit: BoxFit.cover,
          )
        : ArtworkImage(session.level.stage.artAsset!, fit: BoxFit.cover),
    wooden: true,
    scrim: Colors.transparent,
    eyebrow: 'NIVEAU ${session.level.number}',
    title: session.level.stage.title,
    backKey: const Key('match3-back-to-levels'),
    onBack: onBack ?? onLevels,
    helpKind: GameHelpKind.match3,
    metrics: [
      GameStageMetric(
        icon: Icons.touch_app_rounded,
        label: '${session.movesLeft} coups',
      ),
      GameStageMetric(
        icon: Icons.stars_rounded,
        label: '${displayed?.score ?? session.score} points',
      ),
    ],
    builder: (context, layout) => GameStageSplit(
      wide: layout.isLandscape,
      board: BoardCamera(wooden: true, child: _board),
      panel: _objectives,
    ),
    overlays: [
      if (!inputEnabled)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Chip(
              key: const Key('match3-resolving'),
              avatar: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(cascade > 1 ? 'CASCADE ×$cascade' : 'ALIGNEMENT'),
              labelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
              backgroundColor: Colors.white.withValues(alpha: .14),
              side: BorderSide(color: Colors.white.withValues(alpha: .22)),
            ),
          ),
        ),
      if (showResult ?? session.status != Match3Status.playing)
        Positioned.fill(
          child: _ResultOverlay(
            session: session,
            onLevels: onLevels,
            onRetry: onRetry,
            onNext: onNext,
            isFreeGame: isFreeGame,
            onConfigure: onConfigure,
          ),
        ),
    ],
  );

  Widget _integratedScene(BuildContext context) => Scaffold(
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
                        key: const Key('match3-scene-background'),
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
                        child: _integratedBoard,
                      ),
                    ),
                    Positioned(
                      left: 60,
                      top: 42,
                      width: 110,
                      height: 110,
                      child: IconButton(
                        key: const Key('match3-back-to-levels'),
                        tooltip: 'Retour',
                        onPressed: onBack ?? onLevels,
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
                          Text(
                            isFreeGame
                                ? 'PARTIE LIBRE'
                                : 'NIVEAU ${session.level.number}',
                            style: const TextStyle(
                              color: Color(0xffffcc69),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              session.level.stage.title,
                              style: const TextStyle(
                                color: Color(0xffffefd5),
                                fontSize: 40,
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
                      child: _SceneMetric(
                        icon: Icons.touch_app_rounded,
                        label: '${session.movesLeft} coups',
                      ),
                    ),
                    Positioned(
                      left: 973,
                      top: 76,
                      width: 320,
                      height: 60,
                      child: _SceneMetric(
                        icon: Icons.stars_rounded,
                        label: '${displayed?.score ?? session.score} points',
                      ),
                    ),
                    const Positioned(
                      left: 1351,
                      top: 70,
                      width: 75,
                      height: 75,
                      child: GameHelpButton(
                        kind: GameHelpKind.match3,
                        color: Color(0xffffecd0),
                        iconSize: 52,
                      ),
                    ),
                    Positioned(
                      left: 1190,
                      top: 329,
                      width: 430,
                      height: 350,
                      child: SingleChildScrollView(child: _objectives),
                    ),
                    if (!inputEnabled)
                      Positioned(
                        left: 193,
                        top: 170,
                        width: 555,
                        child: Center(
                          child: Chip(
                            key: const Key('match3-resolving'),
                            label: Text(
                              cascade > 1 ? 'CASCADE ×$cascade' : 'ALIGNEMENT',
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
        if (showResult ?? session.status != Match3Status.playing)
          Positioned.fill(
            child: SafeArea(
              child: _ResultOverlay(
                session: session,
                onLevels: onLevels,
                onRetry: onRetry,
                onNext: onNext,
                isFreeGame: isFreeGame,
                onConfigure: onConfigure,
              ),
            ),
          ),
      ],
    ),
  );

  Widget get _integratedBoard => Match3Board(
    session: session,
    displayed: displayed,
    clearing: clearing,
    inputEnabled: inputEnabled,
    selected: selected,
    onSelect: onSelect,
    onSwap: onSwap,
    integrated: true,
  );

  Widget get _board => Match3Board(
    session: session,
    displayed: displayed,
    clearing: clearing,
    inputEnabled: inputEnabled,
    selected: selected,
    onSelect: onSelect,
    onSwap: onSwap,
  );

  Widget get _objectives => _Objectives(session: session, displayed: displayed);
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
          child: Text(
            label,
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

class Match3Board extends StatefulWidget {
  const Match3Board({
    required this.session,
    required this.displayed,
    required this.clearing,
    required this.inputEnabled,
    required this.selected,
    required this.onSelect,
    required this.onSwap,
    this.integrated = false,
    super.key,
  });

  final bool integrated;
  final Match3Session session;
  final Match3BoardSnapshot? displayed;
  final Set<Match3Position> clearing;
  final bool inputEnabled;
  final Match3Position? selected;
  final ValueChanged<Match3Position> onSelect;
  final void Function(Match3Position, Match3Position) onSwap;

  @override
  State<Match3Board> createState() => _Match3BoardState();
}

class _Match3BoardState extends State<Match3Board> {
  Match3Position? _dragPosition;
  Offset _dragDelta = Offset.zero;
  Map<Match3Position, Offset> _dropOffsets = const {};

  @override
  void didUpdateWidget(Match3Board oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.displayed;
    final current = widget.displayed;
    _dropOffsets = previous == null || current == null || previous == current
        ? const {}
        : _drops(previous, current, oldWidget.clearing);
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.center,
    child: Padding(
      padding: EdgeInsets.all(widget.integrated ? 8 : 28),
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xffa97847),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xff744625),
              width: widget.integrated ? 2 : 8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40245b4a),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Match3Session.size,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: Match3Session.size * Match3Session.size,
              itemBuilder: (context, index) {
                final position = Match3Position(
                  index % Match3Session.size,
                  index ~/ Match3Session.size,
                );
                final snapshot =
                    widget.displayed?.cell(position) ??
                    widget.session.cell(position);
                return TweenAnimationBuilder<Offset>(
                  key: ValueKey((widget.displayed, position)),
                  tween: Tween(
                    begin: _dropOffsets[position] ?? Offset.zero,
                    end: Offset.zero,
                  ),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, offset, child) =>
                      FractionalTranslation(translation: offset, child: child),
                  child: GameGestureTarget(
                    onTap: widget.inputEnabled && snapshot.isActive
                        ? () => widget.onSelect(position)
                        : null,
                    onPanStart: widget.inputEnabled && snapshot.isActive
                        ? (_) {
                            _dragPosition = position;
                            _dragDelta = Offset.zero;
                          }
                        : null,
                    onPanUpdate: widget.inputEnabled && snapshot.isActive
                        ? (details) => _dragDelta += details.delta
                        : null,
                    onPanEnd: widget.inputEnabled && snapshot.isActive
                        ? (_) => _finishDrag()
                        : null,
                    child: AnimatedOpacity(
                      opacity: widget.clearing.contains(position) ? 0 : 1,
                      duration: const Duration(milliseconds: 220),
                      child: AnimatedScale(
                        scale: widget.clearing.contains(position) ? .3 : 1,
                        duration: const Duration(milliseconds: 220),
                        child: _Match3Cell(
                          position: position,
                          snapshot: snapshot,
                          haloColor: snapshot.tile?.isBasket == false
                              ? animalHaloColor(snapshot.tile!.animal)
                              : const Color(0xfffffdf5),
                          selected: widget.selected == position,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  Map<Match3Position, Offset> _drops(
    Match3BoardSnapshot previous,
    Match3BoardSnapshot current,
    Set<Match3Position> cleared,
  ) {
    final drops = <Match3Position, Offset>{};
    for (var x = 0; x < Match3Session.size; x++) {
      final origins = <int>[
        for (var y = Match3Session.size - 1; y >= 0; y--)
          if (previous.cell(Match3Position(x, y)).tile != null &&
              !cleared.contains(Match3Position(x, y)))
            y,
      ];
      final destinations = <int>[
        for (var y = Match3Session.size - 1; y >= 0; y--)
          if (current.cell(Match3Position(x, y)).tile != null) y,
      ];
      for (var i = 0; i < destinations.length; i++) {
        final destination = destinations[i];
        final origin = i < origins.length
            ? origins[i]
            : -1 - i + origins.length;
        if (origin != destination) {
          drops[Match3Position(x, destination)] = Offset(
            0,
            (origin - destination).toDouble(),
          );
        }
      }
    }
    return drops;
  }

  void _finishDrag() {
    final start = _dragPosition;
    if (start == null || _dragDelta.distance < 12) return;
    final horizontal = _dragDelta.dx.abs() > _dragDelta.dy.abs();
    final target = Match3Position(
      start.x + (horizontal ? _dragDelta.dx.sign.toInt() : 0),
      start.y + (horizontal ? 0 : _dragDelta.dy.sign.toInt()),
    );
    if (target.x < 0 ||
        target.x >= Match3Session.size ||
        target.y < 0 ||
        target.y >= Match3Session.size) {
      return;
    }
    widget.onSwap(start, target);
  }
}

class _Match3Cell extends StatelessWidget {
  const _Match3Cell({
    required this.position,
    required this.snapshot,
    required this.haloColor,
    required this.selected,
  });

  final Match3Position position;
  final Match3CellSnapshot snapshot;
  final Color haloColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.isActive) {
      return const ColoredBox(color: Colors.transparent);
    }
    final tile = snapshot.tile;
    return Semantics(
      button: true,
      selected: selected,
      label: tile?.isBasket == true
          ? 'Panier de friandises'
          : tile == null
          ? null
          : tile.special == SpecialKind.none
          ? tile.animal.label
          : '${tile.animal.label}, ${_specialLabel(tile.special)}',
      child: AnimatedContainer(
        key: Key('match3-cell-${position.x}-${position.y}'),
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/optimized/sudoku/sandstone-tile.webp'),
            fit: BoxFit.fill,
          ),
          color: haloColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.sun : const Color(0xffba9162),
            width: selected ? 4 : 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tile != null)
              Padding(
                padding: const EdgeInsets.all(4),
                child: tile.isBasket
                    ? const Icon(
                        Icons.shopping_basket_rounded,
                        color: Color(0xffb56736),
                      )
                    : ArtworkImage(
                        tile.animal.asset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => CircleAvatar(
                          backgroundColor: haloColor,
                          child: Text(
                            tile.animal.label.characters.first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
              ),
            if (snapshot.blocker != null)
              _BlockerOverlay(
                kind: snapshot.blocker!,
                layers: snapshot.blockerLayers,
              ),
            if (tile != null && tile.special != SpecialKind.none)
              Align(
                alignment: Alignment.bottomRight,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.sun,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      _specialIcon(tile.special),
                      size: 17,
                      color: AppColors.deep,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _specialIcon(SpecialKind special) => switch (special) {
    SpecialKind.horizontalBinoculars => Icons.swap_horiz_rounded,
    SpecialKind.verticalBinoculars => Icons.swap_vert_rounded,
    SpecialKind.basketBlast => Icons.redeem_rounded,
    SpecialKind.goldenPaw => Icons.pets_rounded,
    SpecialKind.scout => Icons.explore_rounded,
    SpecialKind.largeGift => Icons.card_giftcard_rounded,
    SpecialKind.giantGift => Icons.celebration_rounded,
    SpecialKind.none => Icons.circle,
  };

  String _specialLabel(SpecialKind special) => switch (special) {
    SpecialKind.horizontalBinoculars => 'flèches horizontales',
    SpecialKind.verticalBinoculars => 'flèches verticales',
    SpecialKind.basketBlast => 'cadeau',
    SpecialKind.goldenPaw => 'patte dorée',
    SpecialKind.scout => 'éclaireur',
    SpecialKind.largeGift => 'grand cadeau',
    SpecialKind.giantGift => 'cadeau géant',
    SpecialKind.none => '',
  };
}

class _BlockerOverlay extends StatelessWidget {
  const _BlockerOverlay({required this.kind, required this.layers});

  final BlockerKind kind;
  final int layers;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _color, width: layers == 2 ? 4 : 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Icon(_icon, color: _color, size: 17),
      ),
    ),
  );

  Color get _color => switch (kind) {
    BlockerKind.leaves => const Color(0xff39784f),
    BlockerKind.mud => const Color(0xff70432e),
    BlockerKind.vines => const Color(0xff245b4a),
    BlockerKind.ice => const Color(0xff31889b),
  };

  IconData get _icon => switch (kind) {
    BlockerKind.leaves => Icons.eco_rounded,
    BlockerKind.mud => Icons.water_drop_rounded,
    BlockerKind.vines => Icons.grass_rounded,
    BlockerKind.ice => Icons.ac_unit_rounded,
  };
}

class _Objectives extends StatelessWidget {
  const _Objectives({required this.session, required this.displayed});

  final Match3Session session;
  final Match3BoardSnapshot? displayed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/optimized/sudoku/parchment-panel.webp'),
        fit: BoxFit.fill,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < session.level.goals.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == session.level.goals.length - 1 ? 0 : 6,
              ),
              child: _GoalLine(
                goal: session.level.goals[i],
                blockerKinds: session.level.blockers
                    .map((blocker) => blocker.kind)
                    .toSet(),
                progress: displayed?.goalProgress[i] ?? session.goalProgress(i),
                color: session.level.goals[i].animal == null
                    ? AppColors.primary
                    : animalHaloColor(session.level.goals[i].animal!),
              ),
            ),
        ],
      ),
    ),
  );
}

class _GoalLine extends StatelessWidget {
  const _GoalLine({
    required this.goal,
    required this.blockerKinds,
    required this.progress,
    required this.color,
  });

  final Match3Goal goal;
  final Set<BlockerKind> blockerKinds;
  final int progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (goal.kind == Match3GoalKind.collectAnimal)
        Container(
          key: Key('match3-goal-animal-${goal.animal!.name}'),
          width: 28,
          height: 28,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: ArtworkImage(goal.animal!.asset),
        )
      else
        Icon(_icon, color: const Color(0xff563619), size: 24),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff563619),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '$progress / ${goal.target}',
              style: TextStyle(
                color: progress >= goal.target
                    ? const Color(0xff39784f)
                    : const Color(0xff563619),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  IconData get _icon => switch (goal.kind) {
    Match3GoalKind.collectAnimal => Icons.pets_rounded,
    Match3GoalKind.clearBlockers => Icons.auto_awesome_rounded,
    Match3GoalKind.deliverBaskets => Icons.shopping_basket_rounded,
  };

  String get _label => switch (goal.kind) {
    Match3GoalKind.collectAnimal => goal.animal!.label,
    Match3GoalKind.clearBlockers =>
      blockerKinds.map((kind) => kind.goalLabel).join(' · '),
    Match3GoalKind.deliverBaskets => 'Livrer les paniers',
  };
}

extension on BlockerKind {
  String get goalLabel => switch (this) {
    BlockerKind.leaves => 'Balayer les feuilles',
    BlockerKind.mud => 'Nettoyer la boue',
    BlockerKind.vines => 'Couper les lianes',
    BlockerKind.ice => 'Briser la glace',
  };
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.session,
    required this.onLevels,
    required this.onRetry,
    required this.onNext,
    required this.isFreeGame,
    required this.onConfigure,
  });

  final Match3Session session;
  final VoidCallback onLevels;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final bool isFreeGame;
  final VoidCallback? onConfigure;

  @override
  Widget build(BuildContext context) {
    final won = session.status == Match3Status.won;
    return ColoredBox(
      key: const Key('match3-result-overlay'),
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
                  Icon(
                    won ? Icons.pets_rounded : Icons.refresh_rounded,
                    size: 54,
                    color: won ? AppColors.sun : AppColors.danger,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    won ? 'MISSION ACCOMPLIE !' : 'PLUS DE COUPS',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    won
                        ? isFreeGame
                              ? '${session.score} points'
                              : '${session.score} points · ${session.footprintsForScore()} empreinte(s)'
                        : 'La mission peut être réussie autrement. Réessaie sans limite.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  if (won && onNext != null)
                    FilledButton.icon(
                      key: const Key('match3-next-level'),
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('NIVEAU SUIVANT'),
                    ),
                  FilledButton.tonalIcon(
                    key: const Key('match3-retry'),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('REJOUER'),
                  ),
                  if (onConfigure != null)
                    TextButton.icon(
                      key: const Key('match3-configure'),
                      onPressed: onConfigure,
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('MODIFIER LES RÉGLAGES'),
                    ),
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
}
