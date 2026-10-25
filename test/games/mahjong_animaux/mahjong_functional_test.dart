import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/mahjong_animaux/data/mahjong_progress_store.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/mahjong_session.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/models.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/shared/animal_catalog.dart';
import 'package:papatte_parc/shared/park_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('les 45 plateaux sont pairs, déterministes et jouables', () {
    final campaign = buildMahjongCampaign(levels);
    final stopwatch = Stopwatch()..start();
    final complexities = <int>[];

    expect(campaign, hasLength(45));
    expect(campaign.first.layout.tileCount, 32);
    expect(campaign.last.layout.tileCount, 144);
    for (var index = 0; index < campaign.length; index++) {
      final level = campaign[index];
      expect(level.layout.tileCount.isEven, isTrue);
      if (index > 0) {
        expect(
          level.layout.challenge - campaign[index - 1].layout.challenge,
          closeTo(0.75 / 44, 0.000001),
        );
        expect(
          level.layout.tileCount,
          greaterThanOrEqualTo(campaign[index - 1].layout.tileCount),
        );
      }
      for (final position in level.layout.positions.where(
        (position) => position.layer > 0,
      )) {
        final supports = level.layout.positions.where(
          (candidate) =>
              candidate.layer == position.layer - 1 &&
              (candidate.x - position.x).abs() < 2 &&
              (candidate.y - position.y).abs() < 2,
        );
        expect(
          supports,
          hasLength(4),
          reason:
              'tuile sans support au niveau ${level.number}, couche ${position.layer}',
        );
      }
      final first = MahjongSession(
        layout: level.layout,
        biome: level.stage.biome,
        seed: 73,
      );
      final second = MahjongSession(
        layout: level.layout,
        biome: level.stage.biome,
        seed: 73,
      );
      expect(
        first.tiles.map((snapshot) => snapshot.tile.animal),
        second.tiles.map((snapshot) => snapshot.tile.animal),
      );
      final animalCounts = <AnimalKind, int>{};
      for (final snapshot in first.tiles) {
        animalCounts.update(
          snapshot.tile.animal,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      expect(animalCounts.values, everyElement(4));
      expect(first.complexity, second.complexity);
      if ([0, 14, 29, 44].contains(index)) {
        complexities.add(first.complexity);
      }
      _finish(first);
      expect(first.status, MahjongStatus.won, reason: 'niveau ${level.number}');
      expect(first.shufflesUsed, 0);
    }
    for (var index = 1; index < complexities.length; index++) {
      expect(complexities[index], greaterThan(complexities[index - 1]));
    }
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 15)));
  }, tags: ['performance']);

  test('les difficultés libres produisent des parties plus complexes', () {
    for (final name in mahjongLayoutNames) {
      final id = name.toLowerCase().replaceAll(' ', '-');
      final sessions = [
        for (final difficulty in MahjongDifficulty.values)
          MahjongSession(
            layout: mahjongLayout(id, difficulty),
            biome: LevelBiome.savanna,
            seed: 73,
          ),
      ];

      expect(
        sessions[1].complexity,
        greaterThan(sessions[0].complexity),
        reason: name,
      );
      expect(
        sessions[2].complexity,
        greaterThan(sessions[1].complexity),
        reason: name,
      );
      for (final session in sessions.skip(1)) {
        _finish(session);
        expect(session.status, MahjongStatus.won);
        expect(session.shufflesUsed, 0);
      }
    }
    expect(mahjongLayout('empreinte', MahjongDifficulty.medium).tileCount, 72);
    expect(mahjongLayout('empreinte', MahjongDifficulty.hard).tileCount, 112);
  });

  test('une tuile bloquée est refusée et une paire libre est retirée', () {
    final level = buildMahjongCampaign(levels)[20];
    final session = MahjongSession(
      layout: level.layout,
      biome: level.stage.biome,
      seed: 19,
    );
    final blocked = session.tiles.firstWhere((snapshot) => !snapshot.isFree);
    expect(session.select(blocked.tile.id), MahjongSelectionResult.ignored);

    final pair = session.availablePair!;
    expect(session.select(pair.first), MahjongSelectionResult.selected);
    expect(
      session.select(pair.second),
      anyOf(MahjongSelectionResult.matched, MahjongSelectionResult.won),
    );
    expect(session.remainingPairs, level.layout.tileCount ~/ 2 - 1);
  });

  test('trois mélanges au maximum modifient les empreintes', () {
    final level = buildMahjongCampaign(levels).first;
    final session = MahjongSession(
      layout: level.layout,
      biome: level.stage.biome,
      seed: 31,
    );
    expect(session.footprints, 3);
    expect(session.shuffle(), isTrue);
    expect(session.footprints, 2);
    expect(session.shuffle(), isTrue);
    expect(session.footprints, 1);
    expect(session.shuffle(), isTrue);
    expect(session.shuffle(), isFalse);
    expect(session.shufflesRemaining, 0);
  });

  test('campagne et records libres restent séparés', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await MahjongProgressStore.load();
    const config = MahjongFreeGameConfig(
      layoutId: 'empreinte',
      difficulty: MahjongDifficulty.easy,
      biome: LevelBiome.savanna,
    );
    const otherBiome = MahjongFreeGameConfig(
      layoutId: 'empreinte',
      difficulty: MahjongDifficulty.easy,
      biome: LevelBiome.tropical,
    );

    expect(
      await store.completeFreeGame(config, const Duration(seconds: 40)),
      isTrue,
    );
    expect(
      await store.completeFreeGame(config, const Duration(seconds: 50)),
      isFalse,
    );
    expect(store.freeBestTime(config), const Duration(seconds: 40));
    expect(store.freeBestTime(otherBiome), isNull);
    expect(store.unlockedLevel, 1);
    expect(store.totalFootprints, 0);

    await store.completeLevel(1, const Duration(seconds: 60), 2);
    expect(store.unlockedLevel, 2);
    expect(store.footprints(1), 2);
    expect(store.freeBestTime(config), const Duration(seconds: 40));
  });
}

void _finish(MahjongSession session) {
  var attempts = 0;
  while (session.status == MahjongStatus.playing && attempts++ < 200) {
    final pair = session.hint();
    if (pair == null) {
      expect(session.shuffle(), isTrue);
      continue;
    }
    session.select(pair.first);
    session.select(pair.second);
  }
}
