import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/sentiers_sauvages/data/numberlink_progress_store.dart';
import 'package:papatte_parc/games/sentiers_sauvages/domain/campaign.dart';
import 'package:papatte_parc/games/sentiers_sauvages/domain/models.dart';
import 'package:papatte_parc/games/sentiers_sauvages/domain/numberlink_session.dart';
import 'package:papatte_parc/games/sentiers_sauvages/presentation/numberlink_screen.dart';
import 'package:papatte_parc/shared/animal_catalog.dart';
import 'package:papatte_parc/shared/park_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('les 45 niveaux sont distincts, couvrants et certifiés uniques', () {
    final campaign = buildNumberlinkCampaign(levels);
    final second = buildNumberlinkCampaign(levels);
    final signatures = <String>{};
    countNumberlinkSolutions(_smallLevel());
    numberlinkSolveEffort(campaign[30]);
    final stopwatch = Stopwatch()..start();
    final solutionCounts = [
      for (final level in campaign) countNumberlinkSolutions(level),
    ];
    stopwatch.stop();

    expect(campaign, hasLength(45));
    expect(solutionCounts.every((count) => count == 1), isTrue);
    if (const bool.fromEnvironment('NUMBERLINK_PERFORMANCE')) {
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    }
    for (var index = 0; index < campaign.length; index++) {
      final level = campaign[index];
      final expectedSize = index < 15
          ? 5
          : index < 30
          ? 7
          : 9;
      final expectedPairs = switch (index) {
        < 5 => 3,
        < 10 => 4,
        < 15 => 5,
        < 20 => 4,
        < 25 => 5,
        < 30 => 6,
        < 35 => 6,
        < 40 => 7,
        _ => 8,
      };

      expect(level.number, index + 1);
      expect(level.size, expectedSize, reason: 'niveau ${level.number}');
      expect(level.pairCount, expectedPairs, reason: 'niveau ${level.number}');
      expect(
        level.pairs.map((pair) => pair.animal).toSet(),
        hasLength(expectedPairs),
      );
      expect(
        level.pairs.every(
          (pair) => animalsByBiome[level.stage.biome]!.contains(pair.animal),
        ),
        isTrue,
      );
      _expectReferenceCoversBoard(level);
      expect(signatures.add(_signature(level)), isTrue);
      expect(_signature(second[index]), _signature(level));

      final session = NumberlinkSession(level);
      _replayReference(session);
      expect(session.status, NumberlinkStatus.won);
      expect(session.remainingCells, 0);
    }
  });

  test('les tracés, blocages et rétractions conduisent à la victoire', () {
    final level = _smallLevel();
    final session = NumberlinkSession(level);

    session.tick(const Duration(seconds: 2));
    expect(session.elapsed, Duration.zero);
    expect(
      session.begin(const NumberlinkPosition(0, 0)),
      NumberlinkTraceResult.started,
    );
    expect(
      session.trace(const NumberlinkPosition(0, 1)),
      NumberlinkTraceResult.blocked,
    );
    expect(session.pathFor(0), [const NumberlinkPosition(0, 0)]);
    expect(
      session.trace(const NumberlinkPosition(1, 0)),
      NumberlinkTraceResult.extended,
    );
    expect(
      session.trace(const NumberlinkPosition(0, 0)),
      NumberlinkTraceResult.retracted,
    );
    session.tick(const Duration(seconds: 2));
    expect(session.elapsed, const Duration(seconds: 2));
    session.endTrace();

    _replayReference(session);
    expect(session.status, NumberlinkStatus.won);
    expect(session.completedPairs, level.pairCount);
    expect(session.remainingCells, 0);
    expect(session.footprints, 3);
  });

  test('la difficulté augmente fortement dans chaque palier', () {
    final campaign = buildNumberlinkCampaign(levels);
    final efforts = [
      for (final level in campaign) numberlinkSolveEffort(level),
    ];

    for (var start = 0; start < efforts.length; start += 5) {
      final group = efforts.sublist(start, start + 5);
      expect(group, orderedEquals([...group]..sort()));
    }
    expect(efforts.last, greaterThan(efforts.first * 5000));
  });

  test('les indices restent visuels et déterminent les empreintes', () {
    final level = buildNumberlinkCampaign(levels).first;
    final session = NumberlinkSession(level);

    expect(session.footprints, 3);
    expect(session.hint(), 0);
    expect(session.footprints, 2);
    expect(session.paths.values.every((path) => path.isEmpty), isTrue);
    expect(session.hint(), 1);
    expect(session.footprints, 1);
    expect(session.hint(), 2);
    expect(session.hintsRemaining, 0);
    expect(session.hint(), isNull);
    expect(session.hintedPairIds, {0, 1, 2});
  });

  testWidgets('la souris, le tapotement et le clavier tracent les sentiers', (
    tester,
  ) async {
    final session = NumberlinkSession(_smallLevel());
    await _pumpBoard(tester, session);
    var rect = tester.getRect(find.byKey(const Key('numberlink-board')));
    Offset cell(int x, int y) => Offset(
      rect.left + (x + .5) * rect.width / 3,
      rect.top + (y + .5) * rect.height / 3,
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.down(cell(0, 0));
    await mouse.moveTo(cell(1, 0));
    await mouse.moveTo(cell(2, 0));
    await mouse.up();
    expect(session.isPairConnected(0), isTrue);

    for (final key in const [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowLeft,
    ]) {
      await tester.sendKeyEvent(key);
    }
    expect(session.status, NumberlinkStatus.won);

    final tapped = NumberlinkSession(_smallLevel());
    await _pumpBoard(tester, tapped);
    rect = tester.getRect(find.byKey(const Key('numberlink-board')));
    for (final pair in tapped.level.pairs) {
      for (final position in pair.referencePath) {
        await tester.tapAt(cell(position.x, position.y));
      }
    }
    expect(tapped.status, NumberlinkStatus.won);
  });

  test('les 63 configurations libres restent certifiées et reproductibles', () {
    final stopwatch = Stopwatch()..start();
    final signatures = <String>{};
    var seed = 104729;

    for (final size in const [5, 7, 9]) {
      for (final difficulty in NumberlinkDifficulty.values) {
        for (final biome in LevelBiome.values) {
          final config = NumberlinkFreeGameConfig(
            size: size,
            difficulty: difficulty,
            biome: biome,
          );
          final stage = levels.firstWhere((stage) => stage.biome == biome);
          final level = buildFreeNumberlinkLevel(stage, config, seed);
          final duplicate = buildFreeNumberlinkLevel(stage, config, seed++);

          expect(level.size, size);
          expect(level.pairCount, numberlinkFreePairCount(config));
          expect(
            level.pairs.map((pair) => pair.animal).toSet(),
            hasLength(level.pairCount),
          );
          expect(
            level.pairs.every(
              (pair) => animalsByBiome[biome]!.contains(pair.animal),
            ),
            isTrue,
          );
          _expectReferenceCoversBoard(level);
          expect(countNumberlinkSolutions(level), 1);
          expect(_signature(duplicate), _signature(level));
          expect(
            duplicate.pairs.map((pair) => pair.animal),
            level.pairs.map((pair) => pair.animal),
          );
          signatures.add(_signature(level));
        }
      }
    }

    expect(signatures.length, greaterThan(9));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('la progression conserve le record et reste isolée', () async {
    SharedPreferences.setMockInitialValues({'match3:unlockedLevel': 12});
    final store = await NumberlinkProgressStore.load();

    expect(
      await store.completeLevel(1, const Duration(seconds: 50), 2),
      isTrue,
    );
    expect(
      await store.completeLevel(1, const Duration(seconds: 60), 1),
      isFalse,
    );
    expect(
      await store.completeLevel(1, const Duration(seconds: 40), 3),
      isTrue,
    );

    expect(store.unlockedLevel, 2);
    expect(store.bestTime(1), const Duration(seconds: 40));
    expect(store.footprints(1), 3);
    expect(store.totalFootprints, 3);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('match3:unlockedLevel'), 12);
    expect(preferences.getInt('numberlink:unlockedLevel'), 2);
    expect(preferences.getInt('numberlink:bestTime:1'), 40000);
    expect(preferences.getInt('numberlink:footprints:1'), 3);
  });
}

void _expectReferenceCoversBoard(NumberlinkLevelDefinition level) {
  final occupied = <NumberlinkPosition>{};
  for (final pair in level.pairs) {
    expect(pair.referencePath.first, pair.animalPosition);
    expect(pair.referencePath.last, pair.enclosurePosition);
    for (var index = 0; index < pair.referencePath.length; index++) {
      final position = pair.referencePath[index];
      expect(occupied.add(position), isTrue);
      if (index > 0) {
        expect(pair.referencePath[index - 1].isAdjacentTo(position), isTrue);
      }
    }
  }
  expect(occupied, hasLength(level.size * level.size));
}

void _replayReference(NumberlinkSession session) {
  for (final pair in session.level.pairs) {
    session.begin(pair.referencePath.first);
    for (final position in pair.referencePath.skip(1)) {
      session.trace(position);
    }
  }
}

String _signature(NumberlinkLevelDefinition level) => [
  level.size,
  for (final pair in level.pairs) ...[
    for (final position in pair.referencePath) position.index(level.size),
    -1,
  ],
].join(',');

NumberlinkLevelDefinition _smallLevel() => NumberlinkLevelDefinition(
  stage: levels.first,
  size: 3,
  pairs: const [
    NumberlinkPair(
      id: 0,
      animal: AnimalKind.suricate,
      animalPosition: NumberlinkPosition(0, 0),
      enclosurePosition: NumberlinkPosition(2, 0),
      referencePath: [
        NumberlinkPosition(0, 0),
        NumberlinkPosition(1, 0),
        NumberlinkPosition(2, 0),
      ],
    ),
    NumberlinkPair(
      id: 1,
      animal: AnimalKind.lion,
      animalPosition: NumberlinkPosition(0, 1),
      enclosurePosition: NumberlinkPosition(1, 1),
      referencePath: [
        NumberlinkPosition(0, 1),
        NumberlinkPosition(0, 2),
        NumberlinkPosition(1, 2),
        NumberlinkPosition(2, 2),
        NumberlinkPosition(2, 1),
        NumberlinkPosition(1, 1),
      ],
    ),
  ],
);

Future<void> _pumpBoard(WidgetTester tester, NumberlinkSession session) async =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumberlinkBoard(
            session: session,
            enabled: true,
            onBegin: session.begin,
            onTrace: session.trace,
            onEndTrace: session.endTrace,
          ),
        ),
      ),
    );
