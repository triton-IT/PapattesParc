import '../../../shared/artwork.dart';
import '../../../shared/animal_scene.dart';
import '../../../shared/board_camera.dart';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../shared/animal_catalog.dart';
import '../../../shared/animal_food.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/game_help.dart';
import '../../../shared/game_stage_layout.dart';
import '../domain/animal_sort_session.dart';
import '../domain/models.dart';

class AnimalSortScreen extends StatelessWidget {
  const AnimalSortScreen({
    required this.session,
    required this.selectedZone,
    required this.hintMove,
    required this.finished,
    required this.newRecord,
    required this.freeGame,
    required this.onTapZone,
    required this.onUndo,
    required this.onHint,
    required this.onBack,
    required this.onRestart,
    required this.onReplay,
    required this.onLevels,
    required this.onNext,
    required this.onNewGame,
    required this.onConfigure,
    super.key,
  });

  final AnimalSortSession session;
  final int? selectedZone;
  final AnimalSortMove? hintMove;
  final bool finished;
  final bool newRecord;
  final bool freeGame;
  final ValueChanged<int> onTapZone;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final VoidCallback onReplay;
  final VoidCallback onLevels;
  final VoidCallback? onNext;
  final VoidCallback? onNewGame;
  final VoidCallback? onConfigure;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = min(
        constraints.maxWidth / 1672,
        constraints.maxHeight / 941,
      );
      if ((freeGame || session.level.number != 19) &&
          scale >= .8 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
        return _integratedScene();
      }
      return _responsiveScene();
    },
  );

  Widget _responsiveScene() => GameStageLayout(
    wooden: true,
    background: ArtworkImage(session.level.stage.artAsset!, fit: BoxFit.cover),
    scrim: Colors.transparent,
    eyebrow: freeGame ? 'PARTIE LIBRE' : 'NIVEAU ${session.level.number}',
    title: session.level.stage.title,
    backKey: const Key('animal-sort-back'),
    onBack: onBack,
    backTooltip: freeGame ? 'Retour à la configuration' : 'Niveaux',
    helpKind: GameHelpKind.animalSort,
    metrics: [
      GameStageMetric(
        icon: Icons.restaurant_rounded,
        label:
            '${session.completedMeals}/${session.level.animals.length} repas',
      ),
      GameStageMetric(
        icon: Icons.swap_vert_rounded,
        label: '${session.moves} déplacement${session.moves == 1 ? '' : 's'}',
      ),
    ],
    actions: [
      GameStageAction(
        key: const Key('animal-sort-undo'),
        icon: Icons.undo_rounded,
        tooltip: 'Annuler',
        onPressed: session.canUndo ? onUndo : null,
      ),
      GameStageAction(
        key: const Key('animal-sort-hint'),
        icon: Icons.lightbulb_rounded,
        tooltip: 'Indice · ${session.hintsRemaining}',
        onPressed: onHint,
      ),
      GameStageAction(
        key: const Key('animal-sort-restart'),
        icon: Icons.refresh_rounded,
        tooltip: 'Recommencer',
        onPressed: onRestart,
      ),
    ],
    builder: (context, layout) => Padding(
      padding: EdgeInsets.fromLTRB(
        layout.isLandscape ? 52 : 8,
        0,
        layout.isLandscape ? 52 : 8,
        8,
      ),
      child: BoardCamera(
        wooden: true,
        child: _AnimalSortBoard(
          session: session,
          selectedZone: selectedZone,
          hintMove: hintMove,
          landscape: layout.isLandscape,
          onTapZone: onTapZone,
        ),
      ),
    ),
    overlays: [
      if (finished)
        Positioned.fill(
          child: _ResultOverlay(
            session: session,
            newRecord: newRecord,
            freeGame: freeGame,
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
                        key: const Key('animal-sort-scene-background'),
                        image: AssetImage(
                          animalSceneAsset(
                            session.level.number,
                            isFreeGame: freeGame,
                          ),
                        ),
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned.fill(
                      child: BoardCamera(
                        wooden: true,
                        viewerKey: const Key('animal-sort-camera'),
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
                        child: _AnimalSortBoard(
                          session: session,
                          selectedZone: selectedZone,
                          hintMove: hintMove,
                          landscape: true,
                          onTapZone: onTapZone,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 60,
                      top: 42,
                      width: 110,
                      height: 110,
                      child: IconButton(
                        key: const Key('animal-sort-back'),
                        tooltip: 'Retour',
                        onPressed: onBack,
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
                          const Text(
                            'RÉSERVES DU PARC',
                            style: TextStyle(
                              color: Color(0xffffcc69),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              freeGame
                                  ? 'Partie libre'
                                  : 'Niveau ${session.level.number}',
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
                        icon: Icons.restaurant_rounded,
                        label:
                            '${session.completedMeals}/${session.level.animals.length} repas',
                      ),
                    ),
                    Positioned(
                      left: 973,
                      top: 76,
                      width: 320,
                      height: 60,
                      child: _SceneMetric(
                        icon: Icons.swap_vert_rounded,
                        label: '${session.moves} déplacements',
                      ),
                    ),
                    const Positioned(
                      left: 1351,
                      top: 70,
                      width: 75,
                      height: 75,
                      child: GameHelpButton(
                        kind: GameHelpKind.animalSort,
                        color: Color(0xffffecd0),
                        iconSize: 52,
                      ),
                    ),
                    Positioned(
                      left: 1190,
                      top: 300,
                      width: 430,
                      height: 400,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _sceneButton(
                            const Key('animal-sort-undo'),
                            Icons.undo_rounded,
                            'ANNULER',
                            session.canUndo ? onUndo : null,
                          ),
                          const SizedBox(height: 15),
                          _sceneButton(
                            const Key('animal-sort-hint'),
                            Icons.lightbulb_rounded,
                            'INDICE · ${session.hintsRemaining}',
                            onHint,
                          ),
                          const SizedBox(height: 15),
                          _sceneButton(
                            const Key('animal-sort-restart'),
                            Icons.refresh_rounded,
                            'RECOMMENCER',
                            onRestart,
                          ),
                        ],
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
                freeGame: freeGame,
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

  Widget _sceneButton(
    Key key,
    IconData icon,
    String label,
    VoidCallback? action,
  ) => SizedBox(
    width: double.infinity,
    height: 75,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/optimized/sudoku/hint-sign.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: TextButton.icon(
        key: key,
        onPressed: action,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xffffedc2),
          disabledForegroundColor: const Color(0xffb9a483),
        ),
        icon: Icon(icon, size: 35),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Color(0xff30501f),
                blurRadius: 3,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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

class _AnimalSortBoard extends StatelessWidget {
  const _AnimalSortBoard({
    required this.session,
    required this.selectedZone,
    required this.hintMove,
    required this.landscape,
    required this.onTapZone,
  });

  final AnimalSortSession session;
  final int? selectedZone;
  final AnimalSortMove? hintMove;
  final bool landscape;
  final ValueChanged<int> onTapZone;

  @override
  Widget build(BuildContext context) {
    final count = session.zones.length;
    final designSize = landscape ? const Size(760, 400) : const Size(400, 472);
    final placements = landscape
        ? _landscapePlacements(count)
        : _portraitPlacements(count);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = min(
          1.65,
          min(
            constraints.maxWidth / designSize.width,
            max(.75, constraints.maxHeight / designSize.height),
          ),
        );
        final board = SizedBox(
          width: designSize.width * scale,
          height: designSize.height * scale,
          child: FittedBox(
            child: SizedBox(
              key: const Key('animal-sort-board'),
              width: designSize.width,
              height: designSize.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CartGroundShadow(portrait: !landscape),
                    ),
                  ),
                  Positioned.fill(
                    child: ArtworkImage(
                      landscape
                          ? 'assets/food_sort/ui/cart-landscape.png'
                          : 'assets/food_sort/ui/cart-portrait.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  for (var index = 0; index < count; index++)
                    _PlacedBasket(
                      placement: placements[index],
                      child: _FoodBasket(
                        index: index,
                        animals: session.zones[index],
                        selected: selectedZone == index,
                        completed: _complete(session.zones[index]),
                        hintSource: hintMove?.from == index,
                        hintDestination: hintMove?.to == index,
                        validDestination:
                            selectedZone != null &&
                            session.canMove(selectedZone!, index),
                        onTap: () => onTapZone(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        if (board.height! <= constraints.maxHeight) return Center(child: board);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(child: board),
        );
      },
    );
  }

  bool _complete(List<AnimalKind> zone) =>
      zone.length == animalSortZoneCapacity && zone.toSet().length == 1;

  List<_BasketPlacement> _landscapePlacements(int count) {
    final backCount = (count + 1) ~/ 2;
    final backScale = backCount <= 3
        ? .82
        : backCount == 4
        ? .70
        : .58;
    final frontScale = backCount <= 3
        ? .94
        : backCount == 4
        ? .80
        : .68;
    return [
      ..._centeredRow(backCount, 760, 48, backScale, 34),
      ..._centeredRow(count - backCount, 760, 172, frontScale, 34),
    ];
  }

  List<_BasketPlacement> _portraitPlacements(int count) {
    final rows = (count + 1) ~/ 2;
    if (rows <= 3) {
      const tops = [75.0, 185.0, 290.0];
      const scales = [.70, .76, .82];
      return [
        for (var row = 0; row < rows; row++)
          ..._centeredRow(
            min(2, count - row * 2),
            400,
            tops[row],
            scales[row],
            54,
          ),
      ];
    }
    if (rows == 4) {
      const tops = [65.0, 155.0, 245.0, 330.0];
      const scales = [.58, .62, .66, .70];
      return [
        for (var row = 0; row < rows; row++)
          ..._centeredRow(
            min(2, count - row * 2),
            400,
            tops[row],
            scales[row],
            52,
          ),
      ];
    }
    const rowTops = [55.0, 120.0, 188.0, 258.0, 330.0];
    const scales = [.46, .49, .52, .56, .60];
    return [
      for (var row = 0; row < rows; row++)
        ..._centeredRow(
          min(2, count - row * 2),
          400,
          rowTops[row],
          scales[row],
          50,
        ),
    ];
  }

  List<_BasketPlacement> _centeredRow(
    int count,
    double boardWidth,
    double top,
    double scale,
    double gap,
  ) {
    const basketWidth = 104.0;
    final width = basketWidth * scale;
    final rowWidth = count * width + (count - 1) * gap;
    final left = (boardWidth - rowWidth) / 2;
    return [
      for (var index = 0; index < count; index++)
        _BasketPlacement(left + index * (width + gap), top, scale),
    ];
  }
}

class _BasketPlacement {
  const _BasketPlacement(this.left, this.top, this.scale);

  final double left;
  final double top;
  final double scale;
}

class _PlacedBasket extends StatelessWidget {
  const _PlacedBasket({required this.placement, required this.child});

  final _BasketPlacement placement;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: placement.left,
    top: placement.top,
    width: 104 * placement.scale,
    height: 184 * placement.scale,
    child: FittedBox(child: SizedBox(width: 104, height: 184, child: child)),
  );
}

class _CartGroundShadow extends CustomPainter {
  const _CartGroundShadow({required this.portrait});

  final bool portrait;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = portrait
        ? const Rect.fromLTWH(58, 428, 284, 22)
        : const Rect.fromLTWH(105, 354, 550, 24);
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0x66152620)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  @override
  bool shouldRepaint(_CartGroundShadow oldDelegate) =>
      oldDelegate.portrait != portrait;
}

class _FoodBasket extends StatelessWidget {
  const _FoodBasket({
    required this.index,
    required this.animals,
    required this.selected,
    required this.completed,
    required this.hintSource,
    required this.hintDestination,
    required this.validDestination,
    required this.onTap,
  });

  final int index;
  final List<AnimalKind> animals;
  final bool selected;
  final bool completed;
  final bool hintSource;
  final bool hintDestination;
  final bool validDestination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final emphasized = selected || hintSource || hintDestination || completed;
    return Semantics(
      button: true,
      label: animals.isEmpty
          ? 'Panier ${index + 1}, vide'
          : 'Panier ${index + 1}, ${animals.length} portions, '
                '${animals.reversed.map((a) => '${a.foodLabel} pour ${a.label}').join(', ')}',
      child: InkWell(
        key: Key('animal-sort-zone-$index'),
        borderRadius: BorderRadius.circular(38),
        onTap: () {
          if (!BoardCamera.isNavigating(context)) onTap();
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: selected ? 1.04 : 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (emphasized)
                Positioned.fill(
                  child: Transform.scale(
                    scale: 1.05,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                      child: ArtworkImage(
                        'assets/food_sort/ui/basket.png',
                        fit: BoxFit.fill,
                        color: selected
                            ? AppColors.sun
                            : hintSource
                            ? const Color(0xff64b5f6)
                            : AppColors.success,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: ArtworkImage(
                  'assets/food_sort/ui/basket.png',
                  fit: BoxFit.fill,
                ),
              ),
              for (var depth = animalSortZoneCapacity - 1; depth >= 0; depth--)
                if (_animalAt(depth) case final animal?)
                  Positioned(
                    top:
                        13 +
                        (animalSortZoneCapacity - animals.length + depth) * 34,
                    left: 28,
                    right: 28,
                    child: _FoodPortion(
                      animal: animal,
                      depth: depth,
                      lifted: selected && _topGroupContains(depth),
                      lift: (animalSortZoneCapacity - animals.length) * 34 + 14,
                    ),
                  ),
              Positioned(
                left: 0,
                top: 35,
                child: _LeafTag(index: index, completed: completed),
              ),
              if (completed)
                const Positioned(right: 2, top: 29, child: _CompletionSeal()),
              if ((validDestination || hintDestination) && !selected)
                const Positioned(
                  top: -6,
                  right: 11,
                  child: _DestinationLeaves(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  AnimalKind? _animalAt(int depth) {
    final animalIndex = animals.length - 1 - depth;
    return animalIndex >= 0 ? animals[animalIndex] : null;
  }

  bool _topGroupContains(int depth) {
    var count = 1;
    while (count < animals.length &&
        animals[animals.length - 1 - count] == animals.last) {
      count++;
    }
    return depth < count;
  }
}

class _FoodPortion extends StatelessWidget {
  const _FoodPortion({
    required this.animal,
    required this.depth,
    required this.lifted,
    required this.lift,
  });

  final AnimalKind animal;
  final int depth;
  final bool lifted;
  final double lift;

  @override
  Widget build(BuildContext context) => AnimatedSlide(
    duration: const Duration(milliseconds: 180),
    offset: Offset(0, lifted ? -lift / 48 : 0),
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: 1 - depth * .12,
      child: SizedBox(
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: depth == 0 && lifted
                ? const [BoxShadow(color: Color(0xaaffd166), blurRadius: 18)]
                : null,
          ),
          child: Semantics(
            image: true,
            label: '${animal.foodLabel} pour ${animal.label}',
            child: ArtworkImage(animal.foodAsset, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  );
}

class _LeafTag extends StatelessWidget {
  const _LeafTag({required this.index, required this.completed});

  final int index;
  final bool completed;

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 27,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: completed ? AppColors.success : const Color(0xffd4a264),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(18),
      ),
      border: Border.all(color: const Color(0xff70472e), width: 1.5),
    ),
    child: Text(
      '${index + 1}',
      style: const TextStyle(
        color: Color(0xff3e3024),
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _CompletionSeal extends StatelessWidget {
  const _CompletionSeal();

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: const BoxDecoration(
      color: AppColors.success,
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.check_rounded, size: 19, color: Colors.white),
  );
}

class _DestinationLeaves extends StatelessWidget {
  const _DestinationLeaves();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.eco_rounded, size: 21, color: Color(0xff8ed06c)),
      Icon(Icons.eco_rounded, size: 17, color: Color(0xff58a85d)),
    ],
  );
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.session,
    required this.newRecord,
    required this.freeGame,
    required this.onReplay,
    required this.onLevels,
    required this.onNext,
    required this.onNewGame,
    required this.onConfigure,
  });

  final AnimalSortSession session;
  final bool newRecord;
  final bool freeGame;
  final VoidCallback onReplay;
  final VoidCallback onLevels;
  final VoidCallback? onNext;
  final VoidCallback? onNewGame;
  final VoidCallback? onConfigure;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('animal-sort-result'),
    color: const Color(0xaa0f2f26),
    child: GameResultViewport(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: GameResultPanel(
          biome: session.level.stage.biome,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.shopping_basket_rounded,
                  size: 54,
                  color: AppColors.sun,
                ),
                const SizedBox(height: 10),
                Text(
                  'REPAS PRÉPARÉS !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${session.moves} déplacements${newRecord ? ' · Nouveau record !' : ''}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < 3; index++)
                      Icon(
                        Icons.pets_rounded,
                        size: 32,
                        color: index < session.footprints()
                            ? AppColors.sun
                            : AppColors.muted.withValues(alpha: .25),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                if (freeGame) ...[
                  FilledButton.icon(
                    onPressed: onNewGame,
                    icon: const Icon(Icons.shuffle_rounded),
                    label: const Text('NOUVEAU MÉLANGE'),
                  ),
                  TextButton(
                    onPressed: onConfigure,
                    child: const Text('MODIFIER LA PARTIE'),
                  ),
                ] else ...[
                  if (onNext != null)
                    FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('NIVEAU SUIVANT'),
                    ),
                  TextButton(
                    onPressed: onLevels,
                    child: const Text('RETOUR AUX NIVEAUX'),
                  ),
                ],
                TextButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('REJOUER'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
