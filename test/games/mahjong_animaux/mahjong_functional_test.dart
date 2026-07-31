import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/mahjong_animaux/data/mahjong_progress_store.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/mahjong_session.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/models.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/shared/park_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('les 45 plateaux sont pairs, déterministes et jouables', () {
    final campaign = buildMahjongCampaign(levels);
    final stopwatch = Stopwatch()..start();

    expect(campaign, hasLength(45));
    for (final level in campaign) {
      expect(level.layout.tileCount.isEven, isTrue);
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
      _finish(first);
      expect(first.status, MahjongStatus.won, reason: 'niveau ${level.number}');
    }
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
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
