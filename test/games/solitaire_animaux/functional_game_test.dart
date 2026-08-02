import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart' as park;
import 'package:papatte_parc/games/solitaire_animaux/data/solitaire_progress_store.dart';
import 'package:papatte_parc/games/solitaire_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/solitaire_animaux/domain/models.dart';
import 'package:papatte_parc/games/solitaire_animaux/domain/solitaire_session.dart';
import 'package:papatte_parc/games/solitaire_animaux/presentation/game_screen.dart';
import 'package:papatte_parc/shared/animal_catalog.dart';
import 'package:papatte_parc/shared/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../tool/check_solitaire_greedy.dart';

void main() {
  test('les 45 missions sont déterministes et réalisables', () {
    final campaign = buildSolitaireCampaign(park.levels);
    final rebuilt = buildSolitaireCampaign(park.levels);
    expect(campaign, hasLength(45));
    expect(
      campaign.map((level) => level.number),
      orderedEquals([for (var level = 1; level <= 45; level++) level]),
    );
    expect(campaign.map((level) => level.seed).toSet(), hasLength(45));
    expect(
      campaign.take(15).every((level) => level.mode == SolitaireMode.drawOne),
      isTrue,
    );
    expect(
      campaign
          .skip(15)
          .take(15)
          .every((level) => level.mode == SolitaireMode.drawThree),
      isTrue,
    );
    for (var index = 30; index < 45; index++) {
      expect(
        campaign[index].mode,
        campaign[index].number.isOdd
            ? SolitaireMode.drawOne
            : SolitaireMode.drawThree,
      );
    }
    for (var index = 0; index < campaign.length; index++) {
      final level = campaign[index];
      expect(rebuilt[index].seed, level.seed);
      expect(rebuilt[index].targetRedeals, level.targetRedeals);
      final solution = solveSolitaireDeal(level.mode, level.seed);
      expect(solution, isNotNull, reason: 'niveau ${level.number}');
      expect(
        solution!.redealCount,
        lessThanOrEqualTo(level.targetRedeals),
        reason: 'niveau ${level.number}',
      );
    }
  });

  test('les empreintes dépendent uniquement des recyclages', () {
    final level = buildSolitaireCampaign(park.levels).first;
    expect(solitaireFootprints(level, level.targetRedeals), 3);
    expect(solitaireFootprints(level, level.targetRedeals + 1), 2);
    expect(solitaireFootprints(level, level.targetRedeals + 2), 1);
  });

  test(
    'la donne contient les 52 cartes une seule fois dans les deux modes',
    () {
      for (final mode in SolitaireMode.values) {
        final session = SolitaireSession(mode: mode, seed: 41);
        expect(session.cards.length, 52);
        expect(session.cards.map((card) => card.id).toSet().length, 52);
        expect(session.stock.length, 24);
        expect(
          session.tableau.map((pile) => pile.length),
          orderedEquals([1, 2, 3, 4, 5, 6, 7]),
        );
        for (final pile in session.tableau) {
          expect(pile.last.faceUp, isTrue);
          expect(
            pile.take(pile.length - 1).every((card) => !card.faceUp),
            isTrue,
          );
        }
      }
    },
  );

  test('la pioche respecte le mode, le recyclage et l’annulation', () {
    for (final mode in SolitaireMode.values) {
      final session = SolitaireSession(mode: mode, seed: 73);
      final firstDrawn = session.stock.last.id;
      final stockBefore = session.stock.map((card) => card.id).toList();

      expect(session.draw(), isTrue);
      expect(session.waste.length, mode.drawCount);
      expect(session.undo(), isTrue);
      expect(session.waste, isEmpty);
      expect(session.stock.map((card) => card.id), orderedEquals(stockBefore));

      while (session.stock.isNotEmpty) {
        session.draw();
      }
      expect(session.draw(), isTrue);
      expect(session.waste, isEmpty);
      expect(session.stock.last.id, firstDrawn);
      expect(session.redealCount, 1);
      expect(session.undo(), isTrue);
      expect(session.redealCount, 1);
    }
  });

  test(
    'un déplacement légal est réversible et un déplacement illégal refusé',
    () {
      final session = SolitaireSession(mode: SolitaireMode.drawOne, seed: 9);
      final illegal = SolitaireMove(
        const CardLocation.tableau(1, 0),
        const CardLocation.tableau(0, -1),
      );
      expect(session.canMove(illegal), isFalse);

      final move = _firstLegalMove(session);
      expect(move, isNotNull);
      final before = _signature(session);
      expect(session.move(move!), isTrue);
      expect(_signature(session), isNot(before));
      expect(session.undo(), isTrue);
      expect(_signature(session), before);
    },
  );

  test('la finition sûre envoie les quatre rois vers les fondations', () {
    final session = SolitaireSession(mode: SolitaireMode.drawOne, seed: 1);
    session.stock.clear();
    session.waste.clear();
    for (final pile in session.tableau) {
      pile.clear();
    }
    for (final suit in CardSuit.values) {
      session.foundations[suit.index]
        ..clear()
        ..addAll([
          for (final rank in CardRank.values.take(12))
            SolitaireCard(
              id: suit.index * 13 + rank.index,
              suit: suit,
              rank: rank,
              faceUp: true,
            ),
        ]);
      session.tableau[suit.index].add(
        SolitaireCard(
          id: suit.index * 13 + CardRank.king.index,
          suit: suit,
          rank: CardRank.king,
          faceUp: true,
        ),
      );
    }

    expect(session.canAutoFinish, isTrue);
    expect(session.autoFinish(), isTrue);
    expect(session.status, SolitaireStatus.won);
    expect(session.foundationCount, 52);
    expect(session.undo(), isTrue);
    expect(session.foundationCount, 48);
  });

  test('la finition automatique reste visible jusqu’à la dernière carte', () {
    final session = SolitaireSession(mode: SolitaireMode.drawOne, seed: 1);
    session.stock.clear();
    session.waste.clear();
    for (final pile in session.tableau) {
      pile.clear();
    }
    for (final suit in CardSuit.values) {
      session.foundations[suit.index]
        ..clear()
        ..addAll([
          for (final rank in CardRank.values.take(12))
            SolitaireCard(
              id: suit.index * 13 + rank.index,
              suit: suit,
              rank: rank,
              faceUp: true,
            ),
        ]);
      session.stock.add(
        SolitaireCard(
          id: suit.index * 13 + CardRank.king.index,
          suit: suit,
          rank: CardRank.king,
        ),
      );
    }

    expect(session.prepareAutoFinish(), isTrue);
    expect(session.autoFinishStep(), isTrue);
    expect(session.stock, hasLength(3));
    expect(session.waste, hasLength(1));
    expect(session.status, SolitaireStatus.playing);

    while (session.status == SolitaireStatus.playing) {
      expect(session.autoFinishStep(), isTrue);
    }
    expect(session.stock, isEmpty);
    expect(session.waste, isEmpty);
    expect(session.foundationCount, 52);
    expect(session.undo(), isTrue);
    expect(session.stock, hasLength(4));
  });

  test('l’indice nomme la carte source et la destination en fondation', () {
    final session = _foundationHintSession();
    final hint = session.hint()!;
    expect(
      hint.message,
      'Déplace le 7 de pique sur le 6 de pique dans la fondation.',
    );
    expect(hint.move!.source, const CardLocation.tableau(0, 0));
    expect(hint.move!.target, CardLocation.foundation(CardSuit.spades));
  });

  testWidgets('l’indice distingue la source verte de la destination jaune', (
    tester,
  ) async {
    final session = _foundationHintSession();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: SolitaireGameScreen(
          session: session,
          backAnimal: AnimalKind.suricate,
          backgroundAsset: AnimalKind.suricate.backgroundAsset,
          level: null,
          footprints: 0,
          selected: null,
          hint: session.hint(),
          finished: false,
          newRecord: false,
          onDraw: () {},
          onCardTap: (_) {},
          onDoubleTap: (_) {},
          onMove: (_) {},
          onUndo: () {},
          onHint: () {},
          onBack: () {},
          onNewGame: () {},
          onReplay: () {},
          onConfigure: () {},
          onLevels: () {},
          onNext: null,
        ),
      ),
    );

    Color borderColor(int id) {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(Key('solitaire-card-$id')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return ((container.decoration! as BoxDecoration).border! as Border)
          .top
          .color;
    }

    expect(borderColor(45), AppColors.success);
    expect(borderColor(44), AppColors.sun);
  });

  testWidgets('le résultat de campagne propose les actions du parcours', (
    tester,
  ) async {
    final campaign = buildSolitaireCampaign(park.levels);
    final level = campaign.first;
    final session = SolitaireSession(mode: level.mode, seed: level.seed)
      ..redealCount = level.targetRedeals
      ..tick(const Duration(minutes: 3));
    var replayed = false;
    var openedLevels = false;
    var openedNext = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: SolitaireGameScreen(
          session: session,
          backAnimal: AnimalKind.suricate,
          backgroundAsset: level.stage.artAsset!,
          level: level,
          footprints: 3,
          selected: null,
          hint: null,
          finished: true,
          newRecord: true,
          onDraw: () {},
          onCardTap: (_) {},
          onDoubleTap: (_) {},
          onMove: (_) {},
          onUndo: () {},
          onHint: () {},
          onBack: () {},
          onNewGame: () {},
          onReplay: () => replayed = true,
          onConfigure: null,
          onLevels: () => openedLevels = true,
          onNext: () => openedNext = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('NIVEAU 1 RÉUSSI !'), findsOneWidget);
    expect(
      find.textContaining('objectif ${level.targetRedeals}'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('solitaire-replay')));
    await tester.tap(find.byKey(const Key('solitaire-next-level')));
    await tester.tap(find.byKey(const Key('solitaire-result-levels')));
    expect(replayed, isTrue);
    expect(openedNext, isTrue);
    expect(openedLevels, isTrue);

    final last = campaign.last;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: SolitaireGameScreen(
          session: SolitaireSession(mode: last.mode, seed: last.seed),
          backAnimal: AnimalKind.suricate,
          backgroundAsset: last.stage.artAsset!,
          level: last,
          footprints: 1,
          selected: null,
          hint: null,
          finished: true,
          newRecord: false,
          onDraw: () {},
          onCardTap: (_) {},
          onDoubleTap: (_) {},
          onMove: (_) {},
          onUndo: () {},
          onHint: () {},
          onBack: () {},
          onNewGame: () {},
          onReplay: () {},
          onConfigure: null,
          onLevels: () {},
          onNext: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('solitaire-next-level')), findsNothing);
  });

  test('les préférences et records restent séparés par mode', () async {
    SharedPreferences.setMockInitialValues({});
    var store = await SolitaireProgressStore.load();
    expect(store.mode, SolitaireMode.drawOne);
    expect(store.backAnimal, AnimalKind.suricate);

    await store.setMode(SolitaireMode.drawThree);
    await store.setBackAnimal(AnimalKind.panthereNeiges);
    expect(
      await store.complete(SolitaireMode.drawOne, const Duration(minutes: 4)),
      isTrue,
    );
    expect(
      await store.complete(SolitaireMode.drawOne, const Duration(minutes: 5)),
      isFalse,
    );
    await store.complete(SolitaireMode.drawThree, const Duration(minutes: 8));

    store = await SolitaireProgressStore.load();
    expect(store.mode, SolitaireMode.drawThree);
    expect(store.backAnimal, AnimalKind.panthereNeiges);
    expect(store.wins(SolitaireMode.drawOne), 2);
    expect(store.wins(SolitaireMode.drawThree), 1);
    expect(store.bestTime(SolitaireMode.drawOne), const Duration(minutes: 4));
    expect(store.bestTime(SolitaireMode.drawThree), const Duration(minutes: 8));
  });

  test(
    'la campagne conserve ses records séparément de la partie libre',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = await SolitaireProgressStore.load();
      await store.complete(SolitaireMode.drawOne, const Duration(minutes: 4));
      expect(
        await store.completeLevel(1, const Duration(minutes: 6), 2),
        isTrue,
      );
      expect(
        await store.completeLevel(1, const Duration(minutes: 7), 3),
        isFalse,
      );
      expect(store.unlockedLevel, 2);
      expect(store.levelBestTime(1), const Duration(minutes: 6));
      expect(store.levelFootprints(1), 3);
      expect(store.totalFootprints, 3);
      expect(store.wins(SolitaireMode.drawOne), 1);
      expect(store.bestTime(SolitaireMode.drawOne), const Duration(minutes: 4));
    },
  );
}

SolitaireSession _foundationHintSession() {
  final session = SolitaireSession(mode: SolitaireMode.drawOne, seed: 1);
  session.stock.clear();
  session.waste.clear();
  for (final pile in [...session.tableau, ...session.foundations]) {
    pile.clear();
  }
  session.foundations[CardSuit.spades.index].addAll([
    for (final rank in CardRank.values.take(6))
      SolitaireCard(
        id: CardSuit.spades.index * 13 + rank.index,
        suit: CardSuit.spades,
        rank: rank,
        faceUp: true,
      ),
  ]);
  session.tableau.first.add(
    SolitaireCard(
      id: CardSuit.spades.index * 13 + CardRank.seven.index,
      suit: CardSuit.spades,
      rank: CardRank.seven,
      faceUp: true,
    ),
  );
  return session;
}

SolitaireMove? _firstLegalMove(SolitaireSession session) {
  for (var from = 0; from < 7; from++) {
    final pile = session.tableau[from];
    for (var card = 0; card < pile.length; card++) {
      if (!pile[card].faceUp) continue;
      final source = CardLocation.tableau(from, card);
      for (var target = 0; target < 7; target++) {
        if (target == from) continue;
        final move = SolitaireMove(source, CardLocation.tableau(target, -1));
        if (session.canMove(move)) return move;
      }
      final foundation = SolitaireMove(
        source,
        CardLocation.foundation(pile[card].suit),
      );
      if (session.canMove(foundation)) return foundation;
    }
  }
  return null;
}

String _signature(SolitaireSession session) => [
  session.stock.map((card) => '${card.id}:${card.faceUp}').join(','),
  session.waste.map((card) => '${card.id}:${card.faceUp}').join(','),
  for (final pile in session.tableau)
    pile.map((card) => '${card.id}:${card.faceUp}').join(','),
  for (final pile in session.foundations)
    pile.map((card) => '${card.id}:${card.faceUp}').join(','),
].join('|');
