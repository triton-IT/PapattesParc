import '../../../shared/game_gesture_target.dart';
import 'dart:async';
import '../../../shared/game_activity.dart';
import '../../../shared/artwork.dart';
import '../../../shared/animal_scene.dart';
import '../../../shared/board_camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/animal_catalog.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/game_help.dart';
import '../../../shared/game_stage_layout.dart';
import '../domain/models.dart';
import '../domain/solitaire_session.dart';
import 'card_view.dart';

class SolitaireGameScreen extends StatelessWidget {
  const SolitaireGameScreen({
    this.elapsed,
    required this.session,
    required this.backAnimal,
    required this.backgroundAsset,
    required this.level,
    required this.footprints,
    required this.selected,
    required this.hint,
    required this.finished,
    required this.newRecord,
    required this.onDraw,
    required this.onCardTap,
    required this.onDoubleTap,
    required this.onMove,
    required this.onUndo,
    required this.onHint,
    required this.onBack,
    required this.onNewGame,
    required this.onReplay,
    required this.onConfigure,
    required this.onLevels,
    required this.onNext,
    super.key,
  });

  final SolitaireSession session;
  final AnimalKind backAnimal;
  final String backgroundAsset;
  final SolitaireLevelDefinition? level;
  final int footprints;
  final CardLocation? selected;
  final SolitaireHint? hint;
  final bool finished;
  final bool newRecord;
  final VoidCallback onDraw;
  final ValueChanged<CardLocation> onCardTap;
  final ValueChanged<CardLocation> onDoubleTap;
  final ValueChanged<SolitaireMove> onMove;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onBack;
  final VoidCallback onNewGame;
  final VoidCallback onReplay;
  final VoidCallback? onConfigure;
  final VoidCallback onLevels;
  final VoidCallback? onNext;

  final ValueListenable<Duration>? elapsed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = min(
        constraints.maxWidth / 1672,
        constraints.maxHeight / 941,
      );
      if (scale >= .8 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3 &&
          level?.number != 19) {
        return _integratedScene();
      }
      return _responsiveScene();
    },
  );

  Widget _board() => _Board(
    session: session,
    backAnimal: backAnimal,
    selected: selected,
    hint: hint,
    onDraw: onDraw,
    onCardTap: onCardTap,
    onDoubleTap: onDoubleTap,
    onMove: onMove,
  );

  Widget _responsiveScene() => GameStageLayout(
    background: level?.number == 1
        ? const Image(
            image: AssetImage('assets/optimized/sudoku/savanna.webp'),
            fit: BoxFit.cover,
          )
        : ArtworkImage(backgroundAsset, fit: BoxFit.cover),
    wooden: true,
    scrim: Colors.transparent,
    backgroundColor: const Color(0xffd8e8cf),
    eyebrow: level == null ? 'PARTIE LIBRE' : 'NIVEAU ${level!.number}',
    title: session.mode.label,
    backKey: const Key('solitaire-back'),
    onBack: onBack,
    helpKind: GameHelpKind.solitaire,
    metrics: [
      GameStageMetric(
        icon: Icons.timer_rounded,
        elapsed: elapsed,
        label: formatDuration(session.elapsed),
      ),
      GameStageMetric(
        key: const Key('solitaire-redeals'),
        icon: Icons.replay_circle_filled_rounded,
        label: level == null
            ? '${session.redealCount}'
            : '${session.redealCount}/${level!.targetRedeals}',
      ),
      GameStageMetric(
        icon: Icons.flag_rounded,
        label: '${session.foundationCount}/52',
      ),
    ],
    actions: [
      GameStageAction(
        key: const Key('solitaire-undo'),
        tooltip: 'Annuler',
        onPressed: session.canUndo ? onUndo : null,
        icon: Icons.undo_rounded,
      ),
      GameStageAction(
        key: const Key('solitaire-hint'),
        tooltip: 'Indice',
        onPressed: onHint,
        icon: Icons.lightbulb_outline_rounded,
      ),
      GameStageAction(
        key: const Key('solitaire-new-game'),
        tooltip: level == null ? 'Nouvelle donne' : 'Recommencer',
        onPressed: onNewGame,
        icon: Icons.refresh_rounded,
      ),
    ],
    builder: (context, layout) => BoardCamera(wooden: true, child: _board()),
    overlays: [
      if (finished)
        Positioned.fill(
          child: _ResultOverlay(
            session: session,
            level: level,
            footprints: footprints,
            newRecord: newRecord,
            onReplay: onReplay,
            onConfigure: onConfigure,
            onLevels: onLevels,
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
          child: ArtworkImage(backgroundAsset, fit: BoxFit.cover),
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
                        key: const Key('solitaire-scene-background'),
                        image: AssetImage(
                          animalSceneAsset(
                            level?.number ?? 1,
                            isFreeGame: level == null,
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
                        child: _board(),
                      ),
                    ),
                    Positioned(
                      left: 60,
                      top: 42,
                      width: 110,
                      height: 110,
                      child: IconButton(
                        key: const Key('solitaire-back'),
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
                            'SOLITAIRE DES ANIMAUX',
                            maxLines: 1,
                            style: TextStyle(
                              color: Color(0xffffcc69),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${level == null ? 'Partie libre' : 'Niveau ${level!.number}'} · ${session.mode.label}',
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
                        key: const Key('solitaire-redeals'),
                        icon: Icons.replay_circle_filled_rounded,
                        label:
                            '${session.redealCount}${level == null ? '' : '/${level!.targetRedeals}'} · ${session.foundationCount}/52',
                      ),
                    ),
                    const Positioned(
                      left: 1351,
                      top: 70,
                      width: 75,
                      height: 75,
                      child: GameHelpButton(
                        kind: GameHelpKind.solitaire,
                        color: Color(0xffffecd0),
                        iconSize: 52,
                      ),
                    ),
                    Positioned(
                      left: 1190,
                      top: 329,
                      width: 430,
                      height: 350,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SceneAction(
                            key: const Key('solitaire-undo'),
                            icon: Icons.undo_rounded,
                            label: 'ANNULER',
                            onPressed: session.canUndo ? onUndo : null,
                          ),
                          const SizedBox(height: 12),
                          _SceneAction(
                            key: const Key('solitaire-hint'),
                            icon: Icons.lightbulb_rounded,
                            label: 'INDICE',
                            onPressed: onHint,
                          ),
                          const SizedBox(height: 12),
                          _SceneAction(
                            key: const Key('solitaire-new-game'),
                            icon: Icons.refresh_rounded,
                            label: level == null
                                ? 'NOUVELLE DONNE'
                                : 'RECOMMENCER',
                            onPressed: onNewGame,
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
                level: level,
                footprints: footprints,
                newRecord: newRecord,
                onReplay: onReplay,
                onConfigure: onConfigure,
                onLevels: onLevels,
                onNext: onNext,
              ),
            ),
          ),
      ],
    ),
  );
}

class _SceneMetric extends StatelessWidget {
  const _SceneMetric({
    required this.icon,
    required this.label,
    this.elapsed,
    super.key,
  });
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
    child: Text(
      value,
      maxLines: 1,
      style: const TextStyle(
        color: Color(0xffffecd0),
        fontWeight: FontWeight.w900,
        fontSize: 29,
        shadows: [
          Shadow(color: Color(0xff523017), blurRadius: 4, offset: Offset(1, 2)),
        ],
      ),
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
    child: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/optimized/sudoku/hint-sign.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xffffedc2),
          disabledForegroundColor: const Color(0xffbba989),
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

class _Board extends StatefulWidget {
  const _Board({
    required this.session,
    required this.backAnimal,
    required this.selected,
    required this.hint,
    required this.onDraw,
    required this.onCardTap,
    required this.onDoubleTap,
    required this.onMove,
  });

  final SolitaireSession session;
  final AnimalKind backAnimal;
  final CardLocation? selected;
  final SolitaireHint? hint;
  final VoidCallback onDraw;
  final ValueChanged<CardLocation> onCardTap;
  final ValueChanged<CardLocation> onDoubleTap;
  final ValueChanged<SolitaireMove> onMove;

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> {
  final ScrollController _scroll = ScrollController();
  Timer? _edgeTimer;
  bool _dragging = false;
  double _edgeDirection = 0;
  final GlobalKey _viewportKey = GlobalKey();
  SolitaireSession get session => widget.session;
  AnimalKind get backAnimal => widget.backAnimal;
  CardLocation? get selected => widget.selected;
  SolitaireHint? get hint => widget.hint;
  VoidCallback get onDraw => widget.onDraw;
  ValueChanged<CardLocation> get onCardTap => widget.onCardTap;
  ValueChanged<CardLocation> get onDoubleTap => widget.onDoubleTap;
  ValueChanged<SolitaireMove> get onMove => widget.onMove;

  void dragging(bool value) {
    _dragging = value;
    _edgeTimer?.cancel();
    if (!value) return;
    _edgeTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scroll.hasClients ||
          !GameActivity.instance.value ||
          _edgeDirection == 0) {
        return;
      }
      _scroll.jumpTo(
        (_scroll.offset + _edgeDirection * 5).clamp(
          0.0,
          _scroll.position.maxScrollExtent,
        ),
      );
    });
  }

  void _pointer(Offset global) {
    if (!_dragging) return;
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final y = box.globalToLocal(global).dy;
    _edgeDirection = y < 40
        ? -1
        : y > box.size.height - 40
        ? 1
        : 0;
  }

  @override
  void dispose() {
    _edgeTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final minimumPadding = constraints.maxWidth < 500 ? 7.0 : 18.0;
      final gap = (constraints.maxWidth * .009).clamp(3.0, 12.0);
      final width = min(
        88.0,
        (constraints.maxWidth - minimumPadding * 2 - gap * 6) / 7,
      );
      final boardWidth = width * 7 + gap * 6;
      final horizontalPadding = max(
        minimumPadding,
        (constraints.maxWidth - boardWidth) / 2,
      );
      final cardHeight = width * 1.4;
      final top = minimumPadding;
      final tableauTop = top + cardHeight + max(10, gap);
      final tableauHeight = max(0.0, constraints.maxHeight - tableauTop - 6);
      final deepest = session.tableau.fold<int>(
        1,
        (value, pile) => max(value, pile.length),
      );
      final overlap = width * .31;
      final contentHeight = max(
        tableauHeight,
        cardHeight + max(0, deepest - 1) * overlap + 8,
      );
      final stride = width + gap;
      return Semantics(
        label: 'Plateau de solitaire',
        child: Column(
          key: const Key('solitaire-board'),
          children: [
            SizedBox(
              height: tableauTop,
              child: Stack(
                children: [
                  Positioned(
                    left: horizontalPadding,
                    top: top,
                    child: _Stock(
                      session: session,
                      animal: backAnimal,
                      width: width,
                      onDraw: onDraw,
                    ),
                  ),
                  Positioned(
                    left: horizontalPadding + stride,
                    top: top,
                    child: session.waste.isEmpty
                        ? EmptyCardSlot(width: width)
                        : _PlayableCard(
                            card: session.waste.last,
                            location: const CardLocation.waste(),
                            animal: backAnimal,
                            width: width,
                            selected: selected == const CardLocation.waste(),
                            highlighted: _isHintSource(
                              const CardLocation.waste(),
                            ),
                            childWhenDragging: session.waste.length == 1
                                ? EmptyCardSlot(
                                    key: const Key(
                                      'solitaire-waste-empty-drag',
                                    ),
                                    width: width,
                                  )
                                : SolitaireCardView(
                                    key: Key(
                                      'solitaire-card-${session.waste[session.waste.length - 2].id}',
                                    ),
                                    card:
                                        session.waste[session.waste.length - 2],
                                    backAnimal: backAnimal,
                                    width: width,
                                  ),
                            onTap: onCardTap,
                            onDoubleTap: onDoubleTap,
                          ),
                  ),
                  for (final suit in CardSuit.values)
                    Positioned(
                      left: horizontalPadding + stride * (suit.index + 3),
                      top: top,
                      child: _Foundation(
                        suit: suit,
                        cards: session.foundations[suit.index],
                        session: session,
                        animal: backAnimal,
                        width: width,
                        selected: selected,
                        highlighted:
                            hint?.move?.target == CardLocation.foundation(suit),
                        onCardTap: onCardTap,
                        onDoubleTap: onDoubleTap,
                        onMove: onMove,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Listener(
                key: _viewportKey,
                onPointerMove: (event) => _pointer(event.position),
                onPointerUp: (_) => dragging(false),
                onPointerCancel: (_) => dragging(false),
                child: SingleChildScrollView(
                  controller: _scroll,
                  key: const Key('solitaire-tableau-scroll'),
                  child: SizedBox(
                    height: contentHeight,
                    child: Stack(
                      children: [
                        for (var pile = 0; pile < 7; pile++)
                          Positioned(
                            left: horizontalPadding + stride * pile,
                            top: 0,
                            child: _TableauPile(
                              pile: pile,
                              cards: session.tableau[pile],
                              session: session,
                              animal: backAnimal,
                              width: width,
                              height: contentHeight,
                              overlap: overlap,
                              selected: selected,
                              hint: hint,
                              onCardTap: onCardTap,
                              onDoubleTap: onDoubleTap,
                              onMove: onMove,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  bool _isHintSource(CardLocation location) => hint?.move?.source == location;
}

class _Stock extends StatelessWidget {
  const _Stock({
    required this.session,
    required this.animal,
    required this.width,
    required this.onDraw,
  });

  final SolitaireSession session;
  final AnimalKind animal;
  final double width;
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: session.stock.isEmpty ? 'Recycler la défausse' : 'Piocher',
    child: GameGestureTarget(
      key: const Key('solitaire-stock'),
      onTap: onDraw,
      child: session.stock.isEmpty
          ? EmptyCardSlot(width: width, label: '↻')
          : SolitaireCardView(
              card: session.stock.last,
              backAnimal: animal,
              width: width,
            ),
    ),
  );
}

class _Foundation extends StatelessWidget {
  const _Foundation({
    required this.suit,
    required this.cards,
    required this.session,
    required this.animal,
    required this.width,
    required this.selected,
    required this.highlighted,
    required this.onCardTap,
    required this.onDoubleTap,
    required this.onMove,
  });

  final CardSuit suit;
  final List<SolitaireCard> cards;
  final SolitaireSession session;
  final AnimalKind animal;
  final double width;
  final CardLocation? selected;
  final bool highlighted;
  final ValueChanged<CardLocation> onCardTap;
  final ValueChanged<CardLocation> onDoubleTap;
  final ValueChanged<SolitaireMove> onMove;

  @override
  Widget build(BuildContext context) {
    final location = CardLocation.foundation(suit);
    return DragTarget<CardLocation>(
      onWillAcceptWithDetails: (details) =>
          session.canMove(SolitaireMove(details.data, location)),
      onAcceptWithDetails: (details) =>
          onMove(SolitaireMove(details.data, location)),
      builder: (context, candidates, _) => GameGestureTarget(
        key: Key('solitaire-foundation-${suit.name}'),
        onTap: () => onCardTap(location),
        onDoubleTap: cards.isEmpty ? null : () => onDoubleTap(location),
        child: cards.isEmpty
            ? EmptyCardSlot(
                width: width,
                suit: suit,
                highlightColor: highlighted
                    ? AppColors.sun
                    : candidates.isNotEmpty
                    ? AppColors.success
                    : null,
              )
            : _PlayableCard(
                card: cards.last,
                location: location,
                animal: animal,
                width: width,
                selected: selected == location,
                highlighted: false,
                highlightColor: highlighted
                    ? AppColors.sun
                    : candidates.isNotEmpty
                    ? AppColors.success
                    : null,
                onTap: onCardTap,
                onDoubleTap: onDoubleTap,
              ),
      ),
    );
  }
}

class _TableauPile extends StatelessWidget {
  const _TableauPile({
    required this.pile,
    required this.cards,
    required this.session,
    required this.animal,
    required this.width,
    required this.height,
    required this.overlap,
    required this.selected,
    required this.hint,
    required this.onCardTap,
    required this.onDoubleTap,
    required this.onMove,
  });

  final int pile;
  final List<SolitaireCard> cards;
  final SolitaireSession session;
  final AnimalKind animal;
  final double width;
  final double height;
  final double overlap;
  final CardLocation? selected;
  final SolitaireHint? hint;
  final ValueChanged<CardLocation> onCardTap;
  final ValueChanged<CardLocation> onDoubleTap;
  final ValueChanged<SolitaireMove> onMove;

  @override
  Widget build(BuildContext context) {
    final target = CardLocation.tableau(pile, -1);
    final hintedTarget = hint?.move?.target == target;
    return DragTarget<CardLocation>(
      onWillAcceptWithDetails: (details) =>
          session.canMove(SolitaireMove(details.data, target)),
      onAcceptWithDetails: (details) =>
          onMove(SolitaireMove(details.data, target)),
      builder: (context, candidates, _) => SizedBox(
        key: Key('solitaire-tableau-$pile'),
        width: width,
        height: height,
        child: GameGestureTarget(
          behavior: HitTestBehavior.translucent,
          onTap: cards.isEmpty ? () => onCardTap(target) : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (cards.isEmpty)
                EmptyCardSlot(
                  width: width,
                  label: 'R',
                  highlightColor: hintedTarget
                      ? AppColors.sun
                      : candidates.isNotEmpty
                      ? AppColors.success
                      : null,
                )
              else
                for (var index = 0; index < cards.length; index++)
                  Positioned(
                    top: overlap * index,
                    child: cards[index].faceUp
                        ? _PlayableCard(
                            card: cards[index],
                            location: CardLocation.tableau(pile, index),
                            animal: animal,
                            width: width,
                            selected:
                                selected == CardLocation.tableau(pile, index),
                            highlighted:
                                hint?.move?.source ==
                                CardLocation.tableau(pile, index),
                            highlightColor:
                                hintedTarget && index == cards.length - 1
                                ? AppColors.sun
                                : candidates.isNotEmpty &&
                                      index == cards.length - 1
                                ? AppColors.success
                                : null,
                            onTap: onCardTap,
                            onDoubleTap: onDoubleTap,
                          )
                        : SolitaireCardView(
                            key: Key('solitaire-card-${cards[index].id}'),
                            card: cards[index],
                            backAnimal: animal,
                            width: width,
                          ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayableCard extends StatelessWidget {
  const _PlayableCard({
    required this.card,
    required this.location,
    required this.animal,
    required this.width,
    required this.selected,
    required this.highlighted,
    this.highlightColor,
    this.childWhenDragging,
    required this.onTap,
    required this.onDoubleTap,
  });

  final SolitaireCard card;
  final CardLocation location;
  final AnimalKind animal;
  final double width;
  final bool selected;
  final bool highlighted;
  final Color? highlightColor;
  final Widget? childWhenDragging;
  final ValueChanged<CardLocation> onTap;
  final ValueChanged<CardLocation> onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final view = GameGestureTarget(
      onTap: () => onTap(location),
      onDoubleTap: () => onDoubleTap(location),
      child: SolitaireCardView(
        key: Key('solitaire-card-${card.id}'),
        card: card,
        backAnimal: animal,
        width: width,
        selected: selected,
        highlighted: highlighted,
        highlightColor: highlightColor,
      ),
    );
    return Semantics(
      button: true,
      label: card.label,
      child: Draggable<CardLocation>(
        data: location,
        onDragStarted: () =>
            context.findAncestorStateOfType<_BoardState>()?.dragging(true),
        onDragEnd: (_) =>
            context.findAncestorStateOfType<_BoardState>()?.dragging(false),
        feedback: Material(
          color: Colors.transparent,
          child: SolitaireCardView(
            card: card,
            backAnimal: animal,
            width: width,
            selected: true,
          ),
        ),
        childWhenDragging:
            childWhenDragging ?? Opacity(opacity: .3, child: view),
        child: view,
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.session,
    required this.level,
    required this.footprints,
    required this.newRecord,
    required this.onReplay,
    required this.onConfigure,
    required this.onLevels,
    required this.onNext,
  });

  final SolitaireSession session;
  final SolitaireLevelDefinition? level;
  final int footprints;
  final bool newRecord;
  final VoidCallback onReplay;
  final VoidCallback? onConfigure;
  final VoidCallback onLevels;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('solitaire-result'),
    color: const Color(0xaa173a31),
    child: GameResultViewport(
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
                  level == null
                      ? 'PATIENCE RÉUSSIE !'
                      : 'NIVEAU ${level!.number} RÉUSSI !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                if (level != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < 3; index++)
                        Icon(
                          Icons.pets_rounded,
                          color: index < footprints
                              ? AppColors.sun
                              : AppColors.muted.withValues(alpha: .35),
                          size: 28,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  '${session.mode.label} · ${formatDuration(session.elapsed)}\n'
                  '${session.redealCount} recyclage(s)'
                  '${level == null ? '' : ' · objectif ${level!.targetRedeals}'}'
                  '${newRecord ? '\nNouveau record !' : ''}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('solitaire-replay'),
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(level == null ? 'NOUVELLE DONNE' : 'REJOUER'),
                ),
                if (onNext != null)
                  FilledButton.tonalIcon(
                    key: const Key('solitaire-next-level'),
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('NIVEAU SUIVANT'),
                  ),
                if (onConfigure != null)
                  FilledButton.tonalIcon(
                    key: const Key('solitaire-configure'),
                    onPressed: onConfigure,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('MODIFIER LES RÉGLAGES'),
                  ),
                TextButton.icon(
                  key: const Key('solitaire-result-levels'),
                  onPressed: onLevels,
                  icon: const Icon(Icons.grid_view_rounded),
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
