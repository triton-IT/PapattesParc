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
