import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/repas_animaux/data/repas_animaux_progress_store.dart';
import 'package:papatte_parc/games/repas_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/repas_animaux/domain/generator.dart';
import 'package:papatte_parc/games/repas_animaux/domain/models.dart';
import 'package:papatte_parc/games/repas_animaux/domain/repas_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'les déplacements, poussées, blocages et annulations restent cohérents',
    () {
      final level = RepasLevelDefinition(
        stage: levels.first,
        parPushes: 1,
        rows: const ['######', '#....#', '#sct.#', '#....#', '######'],
      );
      final session = RepasSession(level);

      expect(session.move(RepasDirection.west), RepasMoveResult.blocked);
      expect(session.moves, 0);
      expect(session.move(RepasDirection.east), RepasMoveResult.won);
      expect(session.moves, 1);
      expect(session.pushes, 1);
      expect(session.footprints(), 3);
      expect(session.undo(), isTrue);
      expect(session.status, RepasStatus.playing);
      expect(session.moves, 0);
      expect(session.pushes, 0);
    },
  );

  test('une caisse ne peut pas en pousser une autre', () {
    final session = RepasSession(
      RepasLevelDefinition(
        stage: levels.first,
        parPushes: 2,
        rows: const ['#######', '#scc.tt#', '#######'],
      ),
    );

    expect(session.move(RepasDirection.east), RepasMoveResult.blocked);
    expect(session.crates, {
      const RepasPosition(2, 1),
      const RepasPosition(3, 1),
    });
  });

  test('les empreintes suivent le nombre de poussées de référence', () {
    RepasSession session(int distance) => RepasSession(
      RepasLevelDefinition(
        stage: levels.first,
        parPushes: 1,
        rows: [
          '#####',
          '#s..#',
          '#.c.#',
          for (var index = 1; index < distance; index++) '#...#',
          '#.t.#',
          '#####',
        ],
      ),
    );

    final twoPushes = session(2)
      ..move(RepasDirection.east)
      ..move(RepasDirection.south)
      ..move(RepasDirection.south);
    final threePushes = session(3)
      ..move(RepasDirection.east)
      ..move(RepasDirection.south)
      ..move(RepasDirection.south)
      ..move(RepasDirection.south);

    expect(twoPushes.status, RepasStatus.won);
    expect(twoPushes.footprints(), 2);
    expect(threePushes.status, RepasStatus.won);
    expect(threePushes.footprints(), 1);
  });

  test(
    'les 45 niveaux sont valides et atteignables au nombre de poussées annoncé',
    () {
      final campaign = buildRepasCampaign(levels);

      expect(campaign, hasLength(45));
      for (final level in campaign) {
        expect(level.initialCrates.length, level.targets.length);
        expect(level.floor.contains(level.initialKeeper), isTrue);
        final expectedCrates = switch (level.number) {
          <= 15 => (2, 3),
          <= 30 => (2, 4),
          _ => (2, 5),
        };
        expect(
          level.initialCrates.length,
          inInclusiveRange(expectedCrates.$1, expectedCrates.$2),
        );
        expect(
          level.walls.any(
            (wall) =>
                wall.x > 0 &&
                wall.y > 0 &&
                wall.x < level.width - 1 &&
                wall.y < level.height - 1,
          ),
          isTrue,
          reason: 'obstacles internes du niveau ${level.number}',
        );
        expect(
          _replayReference(level),
          level.parPushes,
          reason: 'niveau ${level.number}',
        );
      }
    },
  );

  test(
    'la progression reste séparée et conserve le meilleur résultat',
    () async {
      SharedPreferences.setMockInitialValues({'match3:unlockedLevel': 12});
      final store = await RepasAnimauxProgressStore.load();

      expect(await store.completeLevel(1, 8, 2), isTrue);
      expect(await store.completeLevel(1, 10, 1), isFalse);
      expect(await store.completeLevel(1, 6, 3), isTrue);

      expect(store.unlockedLevel, 2);
      expect(store.bestPushes(1), 6);
      expect(store.footprints(1), 3);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('match3:unlockedLevel'), 12);
    },
  );

  test('la partie libre génère chaque format avec une solution certifiée', () {
    final stopwatch = Stopwatch()..start();
    var seed = 100;
    for (final size in RepasBoardSize.values) {
      for (final difficulty in RepasDifficulty.values) {
        for (var sample = 0; sample < 5; sample++) {
          late RepasGeneratedBoard generated;
          try {
            generated = generateRepasBoard((
              RepasFreeGameConfig(size: size, difficulty: difficulty),
              seed++,
            ));
          } on StateError catch (error) {
            fail('${size.name}/${difficulty.name}: $error');
          }
          final level = RepasLevelDefinition(
            stage: levels[seed % levels.length],
            rows: generated.rows,
            parPushes: generated.parPushes,
          );
          final internalWalls = level.walls.where(
            (wall) =>
                wall.x > 0 &&
                wall.y > 0 &&
                wall.x < level.width - 1 &&
                wall.y < level.height - 1,
          );
          final session = RepasSession(level);
          for (final direction in generated.solution) {
            expect(
              session.move(direction),
              isNot(RepasMoveResult.blocked),
              reason: '${size.name}/${difficulty.name}',
            );
          }

          expect(
            internalWalls,
            isNotEmpty,
            reason: '${size.name}/${difficulty.name}',
          );
          expect(session.status, RepasStatus.won);
          expect(session.pushes, generated.parPushes);
        }
      }
    }
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });
}

int _replayReference(RepasLevelDefinition level) {
  final session = RepasSession(level);
  for (final direction in level.referenceSolution) {
    expect(session.move(direction), isNot(RepasMoveResult.blocked));
  }
  expect(session.status, RepasStatus.won);
  return session.pushes;
}
