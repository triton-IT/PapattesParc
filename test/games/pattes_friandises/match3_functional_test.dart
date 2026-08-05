import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/pattes_friandises/data/match3_progress_store.dart';
import 'package:papatte_parc/games/pattes_friandises/domain/campaign.dart';
import 'package:papatte_parc/games/pattes_friandises/domain/match3_session.dart';
import 'package:papatte_parc/games/pattes_friandises/domain/models.dart';
import 'package:papatte_parc/games/pattes_friandises/presentation/match3_screen.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/shared/app_theme.dart';
import 'package:papatte_parc/shared/park_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('les 45 niveaux démarrent sans alignement et avec un coup possible', () {
    final campaign = buildMatch3Campaign(levels);

    expect(campaign, hasLength(45));
    for (final level in campaign) {
      final session = Match3Session(level, level.number * 7919);
      expect(session.hasMatches, isFalse, reason: 'niveau ${level.number}');
      expect(
        session.hasAvailableMove,
        isTrue,
        reason: 'niveau ${level.number}',
      );
      expect(level.goals.length, lessThanOrEqualTo(2));
    }
  });

  test('un échange invalide ne consomme pas de coup', () {
    final session = Match3Session(buildMatch3Campaign(levels).first, 19);
    final moves = session.movesLeft;

    final result = session.swap(
      const Match3Position(0, 0),
      const Match3Position(7, 7),
    );

    expect(result.changed, isFalse);
    expect(session.movesLeft, moves);
  });

  test('un carré crée un éclaireur', () {
    final level = _testLevel();
    final board = _board(level);
    final animal = level.animals.first;
    for (final position in const [
      Match3Position(1, 1),
      Match3Position(2, 1),
      Match3Position(1, 2),
      Match3Position(3, 2),
    ]) {
      _put(board, position, animal);
    }
    _put(board, const Match3Position(2, 2), level.animals[1]);
    final session = Match3Session.forTesting(level, 1, board);

    final result = session.swap(
      const Match3Position(3, 2),
      const Match3Position(2, 2),
    );

    expect(result.changed, isTrue);
    expect(
      _specials(result.steps.first.result, SpecialKind.scout),
      hasLength(1),
    );
  });

  test('les lignes de 6 et 7 créent leurs cadeaux distincts', () {
    for (final entry in const {
      6: SpecialKind.largeGift,
      7: SpecialKind.giantGift,
    }.entries) {
      final level = _testLevel();
      final board = _board(level);
      final animal = level.animals.first;
      final start = (Match3Session.size - entry.key) ~/ 2;
      for (var x = start; x < start + entry.key; x++) {
        _put(board, Match3Position(x, 3), animal);
      }
      final session = Match3Session.forTesting(level, entry.key, board);

      final result = session.swap(
        Match3Position(start, 3),
        Match3Position(start + 1, 3),
      );

      expect(result.changed, isTrue);
      expect(_specials(result.steps.first.result, entry.value), hasLength(1));
    }
  });

  test('deux alignements indépendants créent deux bonus', () {
    final level = _testLevel();
    final board = _board(level);
    final firstAnimal = level.animals.first;
    final secondAnimal = level.animals[1];
    for (final x in [1, 2, 4]) {
      _put(board, Match3Position(x, 3), secondAnimal);
      _put(board, Match3Position(x, 4), firstAnimal);
    }
    for (final y in [3, 4]) {
      _put(board, Match3Position(0, y), level.animals[2]);
      _put(board, Match3Position(5, y), level.animals[3]);
    }
    _put(board, const Match3Position(3, 3), firstAnimal);
    _put(board, const Match3Position(3, 4), secondAnimal);
    final session = Match3Session.forTesting(level, 2, board);

    final result = session.swap(
      const Match3Position(3, 3),
      const Match3Position(3, 4),
    );

    expect(result.changed, isTrue);
    expect(
      _specials(result.steps.first.result, SpecialKind.horizontalBinoculars),
      hasLength(2),
    );
  });

  test('une ligne de 6 prime sur une intersection superposée', () {
    final level = _testLevel();
    final board = _board(level);
    final animal = level.animals.first;
    for (var x = 1; x <= 6; x++) {
      _put(board, Match3Position(x, 3), animal);
    }
    for (var y = 1; y <= 2; y++) {
      _put(board, Match3Position(3, y), animal);
    }
    final session = Match3Session.forTesting(level, 8, board);

    final result = session.swap(
      const Match3Position(1, 3),
      const Match3Position(2, 3),
    );

    expect(
      _specials(result.steps.first.result, SpecialKind.largeGift),
      hasLength(1),
    );
    expect(
      _specials(result.steps.first.result, SpecialKind.basketBlast),
      isEmpty,
    );
  });

  test('les familles de combinaisons amplifient leurs zones', () {
    final cases = [
      (
        first: SpecialKind.horizontalBinoculars,
        second: SpecialKind.verticalBinoculars,
        cleared: 15,
      ),
      (
        first: SpecialKind.horizontalBinoculars,
        second: SpecialKind.basketBlast,
        cleared: 39,
      ),
      (
        first: SpecialKind.basketBlast,
        second: SpecialKind.largeGift,
        cleared: 49,
      ),
    ];
    for (final value in cases) {
      final level = _testLevel();
      final board = _board(level);
      _put(board, const Match3Position(3, 3), level.animals.first, value.first);
      _put(board, const Match3Position(4, 3), level.animals[1], value.second);
      final session = Match3Session.forTesting(level, value.cleared, board);

      final result = session.swap(
        const Match3Position(3, 3),
        const Match3Position(4, 3),
      );

      expect(result.steps.first.cleared, hasLength(value.cleared));
    }
  });

  test(
    'les zones ignorent les cases inactives et ne suppriment pas les paniers',
    () {
      const inactive = Match3Position(0, 0);
      const basket = Match3Position(1, 1);
      final level = _testLevel(
        goals: const [Match3Goal(Match3GoalKind.deliverBaskets, 1)],
        basketColumns: const [1],
        inactiveCells: {inactive},
      );
      final board = _board(
        level,
      )..[basket.y * Match3Session.size + basket.x] = const Match3Tile.basket();
      _put(
        board,
        const Match3Position(3, 3),
        level.animals.first,
        SpecialKind.giantGift,
      );
      _put(
        board,
        const Match3Position(4, 3),
        level.animals[1],
        SpecialKind.giantGift,
      );
      final session = Match3Session.forTesting(level, 9, board);

      final result = session.swap(
        const Match3Position(3, 3),
        const Match3Position(4, 3),
      );

      expect(result.steps.first.cleared, isNot(contains(inactive)));
      expect(result.steps.first.cleared, isNot(contains(basket)));
    },
  );

  test('les éclaireurs ciblent chaque type d’objectif', () {
    final target = const Match3Position(6, 6);
    for (final kind in Match3GoalKind.values) {
      final animal = _testLevel().animals.first;
      final level = _testLevel(
        goals: [
          Match3Goal(
            kind,
            2,
            kind == Match3GoalKind.collectAnimal ? animal : null,
          ),
        ],
        blockers: kind == Match3GoalKind.clearBlockers
            ? [BlockerPlacement(target, BlockerKind.ice, 2)]
            : const [],
        basketColumns: kind == Match3GoalKind.deliverBaskets
            ? const [6]
            : const [],
      );
      final board = _board(
        level,
        excludedAnimal: kind == Match3GoalKind.collectAnimal ? animal : null,
      );
      if (kind == Match3GoalKind.collectAnimal) _put(board, target, animal);
      if (kind == Match3GoalKind.deliverBaskets) {
        board[6] = const Match3Tile.basket();
      }
      _put(
        board,
        const Match3Position(4, 5),
        level.animals[1],
        SpecialKind.scout,
      );
      _put(
        board,
        const Match3Position(5, 5),
        level.animals[2],
        SpecialKind.scout,
      );
      final session = Match3Session.forTesting(level, kind.index + 10, board);

      final result = session.swap(
        const Match3Position(4, 5),
        const Match3Position(5, 5),
      );

      if (kind == Match3GoalKind.clearBlockers) {
        expect(result.steps.first.result.cell(target).blockerLayers, 1);
      } else if (kind == Match3GoalKind.collectAnimal) {
        expect(result.steps.first.cleared, contains(target));
      } else {
        expect(
          result.steps.first.cleared,
          contains(const Match3Position(6, 5)),
        );
        expect(
          _positions(result.steps.first.result).where(
            (position) =>
                result.steps.first.result.cell(position).tile?.isBasket == true,
          ),
          isNotEmpty,
        );
      }
    }
  });

  test('patte et bonus transforment le plateau sans boucle', () {
    final level = _testLevel();
    final board = _board(level);
    final animal = level.animals.first;
    for (var index = 0; index < board.length; index += 2) {
      board[index] = Match3Tile(animal: animal);
    }
    _put(
      board,
      const Match3Position(3, 3),
      level.animals[1],
      SpecialKind.goldenPaw,
    );
    _put(board, const Match3Position(4, 3), animal, SpecialKind.scout);
    final session = Match3Session.forTesting(level, 42, board);
    final stopwatch = Stopwatch()..start();

    final result = session.swap(
      const Match3Position(3, 3),
      const Match3Position(4, 3),
    );
    stopwatch.stop();

    expect(result.changed, isTrue);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
  });

  test(
    'les feuilles bloquent leur case et partent par un alignement voisin',
    () {
      final level = buildMatch3Campaign(levels)[7];
      final leaf = level.blockers.first.position;
      final neighbour = Match3Position(leaf.x - 1, leaf.y);
      final blockedSession = Match3Session(level, 1);

      expect(blockedSession.canMove(leaf), isFalse);
      expect(blockedSession.swap(leaf, neighbour).changed, isFalse);

      Match3MoveResult? clearingMove;
      Match3Session? clearingSession;
      for (var seed = 1; seed <= 100 && clearingMove == null; seed++) {
        for (var y = 0; y < Match3Session.size && clearingMove == null; y++) {
          for (var x = 0; x < Match3Session.size && clearingMove == null; x++) {
            for (final target in [
              if (x + 1 < Match3Session.size) Match3Position(x + 1, y),
              if (y + 1 < Match3Session.size) Match3Position(x, y + 1),
            ]) {
              final session = Match3Session(level, seed);
              final result = session.swap(Match3Position(x, y), target);
              if (result.changed && session.goalProgress(0) > 0) {
                clearingSession = session;
                clearingMove = result;
                break;
              }
            }
          }
        }
      }

      expect(clearingMove, isNotNull);
      expect(clearingSession!.goalProgress(0), greaterThan(0));
    },
  );

  testWidgets('chaque objectif nomme les obstacles à retirer', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final campaign = buildMatch3Campaign(levels);
    const labels = {
      8: 'Balayer les feuilles',
      13: 'Nettoyer la boue',
      18: 'Couper les lianes',
      23: 'Briser la glace',
      33: 'Nettoyer la boue · Briser la glace',
      38: 'Balayer les feuilles · Couper les lianes',
      43: 'Briser la glace · Couper les lianes',
    };

    for (final entry in labels.entries) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Match3Screen(
            session: Match3Session(campaign[entry.key - 1], 1),
            selected: null,
            onSelect: (_) {},
            onSwap: (_, _) {},
            onLevels: () {},
            onRetry: () {},
            onNext: null,
          ),
        ),
      );
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  test('tous les paramètres libres créent un plateau jouable', () {
    var seed = 1;
    for (final biome in LevelBiome.values) {
      final stage = levels.firstWhere((level) => level.biome == biome);
      for (final goal in Match3FreeGoal.values) {
        var previousMoves = 100;
        for (final difficulty in Match3Difficulty.values) {
          final config = Match3FreeGameConfig(
            goal: goal,
            difficulty: difficulty,
            biome: biome,
          );
          final level = buildFreeMatch3Level(stage, config);
          final session = Match3Session(level, seed++);
          expect(level.stage.biome, biome);
          expect(level.goals.single.kind.index, goal.index);
          expect(level.moves, lessThan(previousMoves));
          expect(session.hasMatches, isFalse);
          expect(session.hasAvailableMove, isTrue);
          previousMoves = level.moves;
        }
      }
    }
  });

  test('un échange valide déclenche la résolution complète', () {
    final session = Match3Session(buildMatch3Campaign(levels).first, 37);
    Match3MoveResult? result;

    for (var y = 0; y < Match3Session.size && result == null; y++) {
      for (var x = 0; x < Match3Session.size && result == null; x++) {
        for (final target in [
          if (x + 1 < Match3Session.size) Match3Position(x + 1, y),
          if (y + 1 < Match3Session.size) Match3Position(x, y + 1),
        ]) {
          final candidate = session.swap(Match3Position(x, y), target);
          if (candidate.changed) result = candidate;
        }
      }
    }

    expect(result?.changed, isTrue);
    expect(session.movesLeft, session.level.moves - 1);
    expect(session.hasMatches, isFalse);
    expect(session.score, greaterThan(0));
  });

  test('les cascades exposent chaque progression avant le total final', () {
    Match3Session? cascadeSession;
    Match3MoveResult? cascadeResult;
    for (var seed = 1; seed <= 300 && cascadeResult == null; seed++) {
      final session = Match3Session(buildMatch3Campaign(levels).first, seed);
      for (var y = 0; y < Match3Session.size && cascadeResult == null; y++) {
        for (var x = 0; x < Match3Session.size && cascadeResult == null; x++) {
          for (final target in [
            if (x + 1 < Match3Session.size) Match3Position(x + 1, y),
            if (y + 1 < Match3Session.size) Match3Position(x, y + 1),
          ]) {
            final result = session.swap(Match3Position(x, y), target);
            if (result.steps.length > 1) {
              cascadeSession = session;
              cascadeResult = result;
              break;
            }
            if (result.changed) break;
          }
        }
      }
    }

    expect(cascadeResult, isNotNull);
    expect(cascadeResult!.steps.first.cascade, 1);
    expect(cascadeResult.steps.last.cascade, cascadeResult.steps.length);
    expect(cascadeResult.steps.last.result.score, cascadeSession!.score);
    for (var goal = 0; goal < cascadeSession.level.goals.length; goal++) {
      expect(
        cascadeResult.steps.last.result.goalProgress[goal],
        cascadeSession.goalProgress(goal),
      );
    }
  });

  test(
    'la progression match-3 reste séparée et conserve le meilleur score',
    () async {
      SharedPreferences.setMockInitialValues({'journey:unlockedLevel': 12});
      final store = await Match3ProgressStore.load();

      await store.completeLevel(1, 4200, 2);
      await store.completeLevel(1, 3100, 1);

      expect(store.unlockedLevel, 2);
      expect(store.bestScore(1), 4200);
      expect(store.footprints(1), 2);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('journey:unlockedLevel'), 12);
    },
  );
}

Match3LevelDefinition _testLevel({
  List<Match3Goal>? goals,
  List<BlockerPlacement> blockers = const [],
  List<int> basketColumns = const [],
  Set<Match3Position> inactiveCells = const {},
}) {
  final base = buildMatch3Campaign(levels).first;
  return Match3LevelDefinition(
    stage: base.stage,
    animals: base.animals,
    moves: 20,
    goals:
        goals ??
        [Match3Goal(Match3GoalKind.collectAnimal, 20, base.animals.first)],
    blockers: blockers,
    inactiveCells: inactiveCells,
    basketColumns: basketColumns,
    twoFootprints: 1000,
    threeFootprints: 2000,
  );
}

List<Match3Tile?> _board(
  Match3LevelDefinition level, {
  AnimalKind? excludedAnimal,
}) {
  final animals = level.animals
      .where((animal) => animal != excludedAnimal)
      .toList();
  return [
    for (
      var index = 0;
      index < Match3Session.size * Match3Session.size;
      index++
    )
      level.inactiveCells.contains(
            Match3Position(
              index % Match3Session.size,
              index ~/ Match3Session.size,
            ),
          )
          ? null
          : Match3Tile(
              animal:
                  animals[(index % Match3Session.size +
                          2 * (index ~/ Match3Session.size)) %
                      animals.length],
            ),
  ];
}

void _put(
  List<Match3Tile?> board,
  Match3Position position,
  AnimalKind animal, [
  SpecialKind special = SpecialKind.none,
]) {
  board[position.y * Match3Session.size + position.x] = Match3Tile(
    animal: animal,
    special: special,
  );
}

Iterable<Match3Position> _positions(Match3BoardSnapshot snapshot) sync* {
  for (var y = 0; y < Match3Session.size; y++) {
    for (var x = 0; x < Match3Session.size; x++) {
      yield Match3Position(x, y);
    }
  }
}

List<Match3Position> _specials(
  Match3BoardSnapshot snapshot,
  SpecialKind special,
) => [
  for (final position in _positions(snapshot))
    if (snapshot.cell(position).tile?.special == special) position,
];
