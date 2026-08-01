import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/animal_catalog.dart';
import '../../../shared/animal_background.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/game_help.dart';
import '../domain/models.dart';
import '../domain/solitaire_session.dart';
import 'card_view.dart';

class SolitaireGameScreen extends StatelessWidget {
  const SolitaireGameScreen({
    required this.session,
    required this.backAnimal,
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
    required this.onExit,
    super.key,
  });

  final SolitaireSession session;
  final AnimalKind backAnimal;
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
  final VoidCallback onConfigure;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xffd8e8cf),
    body: AnimalBackground(
      asset: backAnimal.backgroundAsset,
      scrim: const Color(0x5518382f),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Toolbar(
                  session: session,
                  onBack: onBack,
                  onUndo: onUndo,
                  onHint: onHint,
                  onNewGame: onNewGame,
                ),
                Expanded(
                  child: _Board(
                    session: session,
                    backAnimal: backAnimal,
                    selected: selected,
                    hint: hint,
                    onDraw: onDraw,
                    onCardTap: onCardTap,
                    onDoubleTap: onDoubleTap,
                    onMove: onMove,
                  ),
                ),
              ],
            ),
            if (finished)
              Positioned.fill(
                child: _ResultOverlay(
                  session: session,
                  newRecord: newRecord,
                  onReplay: onReplay,
                  onConfigure: onConfigure,
                  onExit: onExit,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.session,
    required this.onBack,
    required this.onUndo,
    required this.onHint,
    required this.onNewGame,
  });

  final SolitaireSession session;
  final VoidCallback onBack;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return ColoredBox(
      color: const Color(0xfffff4dc),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          children: [
            IconButton(
              key: const Key('solitaire-back'),
              tooltip: 'Retour',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            if (!compact) ...[
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Solitaire des animaux · ${session.mode.label}',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ] else
              const Spacer(),
            _Metric(Icons.timer_rounded, formatDuration(session.elapsed)),
            if (!compact) ...[
              const SizedBox(width: 8),
              _Metric(Icons.flag_rounded, '${session.foundationCount}/52'),
            ],
            IconButton(
              key: const Key('solitaire-undo'),
              tooltip: 'Annuler',
              onPressed: session.canUndo ? onUndo : null,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              key: const Key('solitaire-hint'),
              tooltip: 'Indice',
              onPressed: onHint,
              icon: const Icon(Icons.lightbulb_outline_rounded),
            ),
            IconButton(
              key: const Key('solitaire-new-game'),
              tooltip: 'Nouvelle donne',
              onPressed: onNewGame,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const GameHelpButton(kind: GameHelpKind.solitaire),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.value);

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: AppColors.primary),
      const SizedBox(width: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

class _Board extends StatelessWidget {
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
      final overlap = deepest <= 1
          ? width * .3
          : min(
              width * .31,
              (tableauHeight - cardHeight) / (deepest - 1),
            ).clamp(11.0, width * .31);
      final stride = width + gap;
      return Semantics(
        label: 'Plateau de solitaire',
        child: Stack(
          key: const Key('solitaire-board'),
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
                      highlighted: _isHintSource(const CardLocation.waste()),
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
            for (var pile = 0; pile < 7; pile++)
              Positioned(
                left: horizontalPadding + stride * pile,
                top: tableauTop,
                child: _TableauPile(
                  pile: pile,
                  cards: session.tableau[pile],
                  session: session,
                  animal: backAnimal,
                  width: width,
                  height: tableauHeight,
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
    child: GestureDetector(
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
      builder: (context, candidates, _) => GestureDetector(
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
        child: GestureDetector(
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
  final ValueChanged<CardLocation> onTap;
  final ValueChanged<CardLocation> onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final view = GestureDetector(
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
        feedback: Material(
          color: Colors.transparent,
          child: SolitaireCardView(
            card: card,
            backAnimal: animal,
            width: width,
            selected: true,
          ),
        ),
        childWhenDragging: Opacity(opacity: .3, child: view),
        child: view,
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.session,
    required this.newRecord,
    required this.onReplay,
    required this.onConfigure,
    required this.onExit,
  });

  final SolitaireSession session;
  final bool newRecord;
  final VoidCallback onReplay;
  final VoidCallback onConfigure;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('solitaire-result'),
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
                  'PATIENCE RÉUSSIE !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${session.mode.label} · ${formatDuration(session.elapsed)}'
                  '${newRecord ? '\nNouveau record !' : ''}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('solitaire-replay'),
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('REJOUER'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onConfigure,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('MODIFIER LES RÉGLAGES'),
                ),
                TextButton.icon(
                  onPressed: onExit,
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('RETOUR AUX JEUX'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
