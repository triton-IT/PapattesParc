import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/game_activity.dart';
import 'package:papatte_parc/shared/game_records.dart';
import 'package:papatte_parc/shared/generation_service.dart';
import 'package:papatte_parc/shared/generation/generation_protocol.dart';
import 'package:papatte_parc/shared/park_stages.dart';
import 'package:papatte_parc/shared/park_catalog.dart';
import 'package:papatte_parc/shared/artwork.dart';
import 'package:papatte_parc/games/refuge/data/progress_store.dart';
import 'package:papatte_parc/games/pattes_friandises/data/match3_progress_store.dart';
import 'package:papatte_parc/games/repas_animaux/data/repas_animaux_progress_store.dart';
import 'package:papatte_parc/games/sudoku_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/refuge/domain/models.dart' as refuge;
import 'package:papatte_parc/games/mahjong_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/mahjong_session.dart';
import 'package:papatte_parc/games/repas_animaux/domain/generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(
    () => GameActivity.instance.didChangeAppLifecycleState(
      AppLifecycleState.resumed,
    ),
  );

  test(
    'record policies preserve better values, zero records and separate keys',
    () async {
      SharedPreferences.setMockInitialValues({
        'time': 1000,
        'score': 500,
        'pushes': 0,
        'legacySeconds': 0.0,
        'free:time': 3000,
      });
      final preferences = await SharedPreferences.getInstance();
      final records = GameRecords(preferences);
      expect(
        await records.saveDuration('time', const Duration(seconds: 2)),
        isFalse,
      );
      expect(
        await records.saveInteger('score', 400, order: RecordOrder.higherWins),
        isFalse,
      );
      expect(
        await records.saveInteger('pushes', 1, order: RecordOrder.lowerWins),
        isFalse,
      );
      expect(
        await records.saveSeconds('legacySeconds', const Duration(seconds: 1)),
        isFalse,
      );
      expect(
        await records.saveDuration('time', const Duration(milliseconds: 500)),
        isTrue,
      );
      expect(
        await records.saveInteger('score', 600, order: RecordOrder.higherWins),
        isTrue,
      );
      expect(preferences.getInt('free:time'), 3000);
      expect(preferences.getInt('pushes'), 0);
    },
  );

  test(
    'migration preserves records, recognizes final victory and remains idempotent',
    () async {
      SharedPreferences.setMockInitialValues({
        'journey:unlockedLevel': 45,
        'bestTime:level:45': 0.0,
        'bestTime:level:1': 18.5,
        'match3:unlockedLevel': 2,
        'match3:bestScore:1': 500,
        'repas:unlockedLevel': 1,
        'repas:bestPushes:45': 0,
      });
      final store = await ProgressStore.load();
      expect(store.completedCount, 45);
      final match = await Match3ProgressStore.load();
      expect(match.completedCount, 1);
      final food = await RepasAnimauxProgressStore.load();
      expect(food.completedCount, 1);
      expect(food.bestPushes(45), 0);
      await match.completeLevel(45, 300, 1);
      expect(match.completedCount, 2);
      expect(match.bestScore(1), 500);
      expect((await ProgressStore.load()).completedCount, 45);
      expect((await Match3ProgressStore.load()).completedCount, 2);
    },
  );

  test(
    'artwork selects bounded variants without changing logical asset IDs',
    () {
      const source = 'assets/level_art/level-01-suricates-porcs-epics.png';
      expect(
        ArtworkResolver.resolve(source, physicalWidth: 300),
        endsWith('-320.webp'),
      );
      expect(
        ArtworkResolver.resolve(source, physicalWidth: 500),
        endsWith('-640.webp'),
      );
      expect(
        ArtworkResolver.resolve(source, physicalWidth: 900),
        endsWith('-1280.webp'),
      );
      expect(
        ArtworkResolver.resolve('assets/fonts/Nunito-Variable.ttf'),
        'assets/fonts/Nunito-Variable.ttf',
      );
    },
  );

  test(
    'Sudoku metadata stays lightweight and background puzzle matches reference',
    () async {
      final metadata = buildSudokuCampaignMetadata(parkStages);
      expect(metadata, hasLength(45));
      expect(
        metadata.every(
          (level) => level.needsGeneration && level.puzzle.isEmpty,
        ),
        isTrue,
      );
      final service = GenerationService();
      addTearDown(service.dispose);
      final ready = await service.sudoku(parkStages.last);
      final reference = buildSudokuLevel(parkStages.last);
      expect(ready.puzzle, reference.puzzle);
      expect(ready.solution, reference.solution);
      expect(countSudokuSolutions(ready), 1);
      final wire =
          jsonDecode(jsonEncode(encodeSudoku(ready))) as Map<String, dynamic>;
      expect(decodeSudoku(wire, parkStages.last).puzzle, ready.puzzle);
    },
  );

  test(
    'prepared Mahjong preserves tiles, solutions, and subsequent RNG stream',
    () async {
      final level = buildMahjongCampaign(parkStages)[17];
      final service = GenerationService();
      addTearDown(service.dispose);
      final prepared = await service.mahjong(
        level.layout,
        LevelBiome.savanna,
        73,
      );
      final first = MahjongSession(
        layout: level.layout,
        biome: LevelBiome.savanna,
        seed: 73,
      );
      final second = MahjongSession(
        layout: level.layout,
        biome: LevelBiome.savanna,
        seed: 73,
        prepared: prepared,
      );
      expect(
        second.tiles.map((t) => t.tile.animal),
        first.tiles.map((t) => t.tile.animal),
      );
      expect(second.complexity, first.complexity);
      for (final session in [first, second]) {
        final pair = session.hint()!;
        session.select(pair.first);
        session.select(pair.second);
        session.shuffle();
      }
      expect(
        second.tiles.map((t) => t.tile.animal),
        first.tiles.map((t) => t.tile.animal),
      );
      expect(second.hint(), first.hint());
    },
  );

  test('Refuge and Repas results survive worker serialization', () async {
    final service = GenerationService();
    addTearDown(service.dispose);
    final board = await service.refuge(
      const refuge.BoardConfig(6, 6, 5),
      const refuge.CellPosition(3, 3),
      123,
    );
    expect(board, isNotNull);
    expect(board!.isAnimal(const refuge.CellPosition(3, 3)), isFalse);
    expect(board.certificate, isNotEmpty);
    const config = RepasFreeGameConfig(
      size: RepasBoardSize.small,
      difficulty: RepasDifficulty.easy,
    );
    final generated = await service.repasBoard(config, 73);
    final reference = generateRepasBoard((config, 73));
    expect(generated.rows, reference.rows);
    expect(generated.solution, reference.solution);
  });

  test('cancelled generation cannot install a late result', () async {
    final service = GenerationService();
    final future = service.sudoku(parkStages[0]);
    service.cancel();
    await expectLater(future, throwsA(isA<StaleGeneration>()));
    expect(service.value, isFalse);
    service.dispose();
  });

  testWidgets('clock excludes background time and resumes automatically', (
    tester,
  ) async {
    final watch = _ControlledWatch();
    var elapsed = Duration.zero;
    final clock = ActiveGameClock(
      stopwatch: watch,
      onTick: (delta) => elapsed += delta,
    );
    watch.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, const Duration(seconds: 1));
    GameActivity.instance.didChangeAppLifecycleState(
      AppLifecycleState.inactive,
    );
    watch.advance(const Duration(minutes: 10));
    await tester.pump(const Duration(minutes: 10));
    expect(clock.value, const Duration(seconds: 1));
    GameActivity.instance.didChangeAppLifecycleState(AppLifecycleState.resumed);
    watch.advance(const Duration(milliseconds: 250));
    clock.flush();
    expect(clock.value, const Duration(milliseconds: 1250));
    clock.dispose();
  });

  testWidgets('a delayed action stays suspended until automatic resume', (
    tester,
  ) async {
    var fired = false;
    final timer = ActiveGameTimer(
      const Duration(milliseconds: 200),
      () => fired = true,
    );
    addTearDown(timer.cancel);
    GameActivity.instance.didChangeAppLifecycleState(
      AppLifecycleState.inactive,
    );
    await tester.pump(const Duration(minutes: 10));
    expect(fired, isFalse);
    GameActivity.instance.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 200));
    expect(fired, isTrue);
  });

  testWidgets(
    'a prepared level is only delivered when the app becomes active',
    (tester) async {
      final service = GenerationService();
      addTearDown(service.dispose);
      GameActivity.instance.didChangeAppLifecycleState(
        AppLifecycleState.inactive,
      );
      var delivered = false;
      final pending = service
          .sudoku(parkStages.first)
          .then((_) => delivered = true);
      await tester.pump();
      expect(delivered, isFalse);
      expect(service.value, isTrue);
      GameActivity.instance.didChangeAppLifecycleState(
        AppLifecycleState.resumed,
      );
      await tester.runAsync(() => pending);
      expect(delivered, isTrue);
      expect(service.value, isFalse);
    },
  );
}

class _ControlledWatch implements Stopwatch {
  int _microseconds = 0;
  @override
  bool isRunning = false;
  void advance(Duration value) {
    if (isRunning) _microseconds += value.inMicroseconds;
  }

  @override
  void start() {
    isRunning = true;
  }

  @override
  void stop() {
    isRunning = false;
  }

  @override
  void reset() {
    _microseconds = 0;
  }

  @override
  Duration get elapsed => Duration(microseconds: _microseconds);
  @override
  int get elapsedTicks => _microseconds;
  @override
  int get elapsedMicroseconds => _microseconds;
  @override
  int get elapsedMilliseconds => _microseconds ~/ 1000;
  @override
  int get frequency => 1000000;
}
