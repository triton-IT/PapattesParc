import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/sudoku_animaux/data/sudoku_progress_store.dart';
import 'package:papatte_parc/games/sudoku_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/sudoku_animaux/domain/models.dart';
import 'package:papatte_parc/games/sudoku_animaux/domain/sudoku_session.dart';
import 'package:papatte_parc/shared/animal_catalog.dart';
import 'package:papatte_parc/shared/park_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('les 45 missions sont déterministes, valides et uniques', () {
    final stopwatch = Stopwatch()..start();
    final campaign = buildSudokuCampaign(levels);
    final second = buildSudokuCampaign(levels);

    expect(campaign, hasLength(45));
    for (var index = 0; index < campaign.length; index++) {
      final level = campaign[index];
      final expectedSize = index < 15
          ? 4
          : index < 30
          ? 6
          : 9;
      expect(level.size, expectedSize, reason: 'niveau ${level.number}');
      expect(level.animals, hasLength(expectedSize));
      expect(level.animals.toSet(), hasLength(expectedSize));
      expect(
        level.animals.every(AnimalKind.values.contains),
        isTrue,
        reason: 'niveau ${level.number}',
      );
      _expectValidSolution(level);
      for (var cell = 0; cell < level.puzzle.length; cell++) {
        if (level.puzzle[cell] >= 0) {
          expect(level.puzzle[cell], level.solution[cell]);
        }
      }
      expect(countSudokuSolutions(level), 1, reason: 'niveau ${level.number}');
      expect(second[index].animals, level.animals);
      expect(second[index].solution, level.solution);
      expect(second[index].puzzle, level.puzzle);
      if (index % 15 != 0) {
        expect(
          level.clueCount,
          lessThanOrEqualTo(campaign[index - 1].clueCount),
        );
      }
    }
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('placements, notes, gomme et indices conduisent à la victoire', () {
    final level = buildSudokuCampaign(levels)[14];
    final session = SudokuSession(level);
    final pair = _emptyPeers(level);
    final first = pair.$1;
    final peer = pair.$2;
    final value = level.solution[first];

    final before = session.entries.toList();
    expect(
      session.place(first, (value + 1) % level.size),
      SudokuPlacementResult.wrong,
    );
    expect(session.entries, before);
    expect(session.hasMoved, isFalse);
    expect(session.footprints, 3);

    session.toggleNote(peer, value);
    expect(session.notes[peer], contains(value));
    expect(session.place(first, value), SudokuPlacementResult.placed);
    expect(session.notes[peer], isNot(contains(value)));
    session.clear(first);
    expect(session.entries[first], isNull);

    expect(session.hint(first), first);
    expect(session.hint(), isNotNull);
    expect(session.hint(), isNotNull);
    expect(session.hint(), isNull);
    expect(session.hintsRemaining, 0);
    expect(session.footprints, 1);

    for (var index = 0; index < session.entries.length; index++) {
      if (session.entries[index] == null) {
        session.place(index, level.solution[index]);
      }
    }
    expect(session.status, SudokuStatus.won);
  });

  test('tous les paramètres libres créent une grille unique', () {
    var seed = 1;
    for (final biome in LevelBiome.values) {
      final stage = levels.firstWhere((level) => level.biome == biome);
      for (final size in const [4, 6, 9]) {
        var previousClues = size * size + 1;
        for (final difficulty in SudokuDifficulty.values) {
          final config = SudokuFreeGameConfig(
            size: size,
            difficulty: difficulty,
            biome: biome,
          );
          final level = buildFreeSudokuLevel(stage, config, seed++);
          expect(level.size, size);
          expect(level.stage.biome, biome);
          expect(level.animals, hasLength(size));
          expect(level.clueCount, lessThan(previousClues));
          expect(
            level.clueCount,
            greaterThanOrEqualTo(sudokuFreeClueCount(config)),
          );
          expect(countSudokuSolutions(level), 1);
          _expectValidSolution(level);
          previousClues = level.clueCount;
        }
      }
    }
  });

  test(
    'progression, meilleurs résultats et autres sauvegardes sont séparés',
    () async {
      SharedPreferences.setMockInitialValues({'match3:unlockedLevel': 12});
      final store = await SudokuProgressStore.load();

      await store.completeLevel(1, const Duration(minutes: 2), 2);
      await store.completeLevel(1, const Duration(minutes: 3), 3);
      expect(store.unlockedLevel, 2);
      expect(store.bestTime(1), const Duration(minutes: 2));
      expect(store.footprints(1), 3);
      expect(store.totalFootprints, 3);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('match3:unlockedLevel'), 12);
    },
  );
}

void _expectValidSolution(SudokuLevelDefinition level) {
  final expected = {for (var value = 0; value < level.size; value++) value};
  for (var row = 0; row < level.size; row++) {
    expect({
      for (var column = 0; column < level.size; column++)
        level.solution[row * level.size + column],
    }, expected);
  }
  for (var column = 0; column < level.size; column++) {
    expect({
      for (var row = 0; row < level.size; row++)
        level.solution[row * level.size + column],
    }, expected);
  }
  for (var boxRow = 0; boxRow < level.size; boxRow += level.boxHeight) {
    for (
      var boxColumn = 0;
      boxColumn < level.size;
      boxColumn += level.boxWidth
    ) {
      expect({
        for (var y = 0; y < level.boxHeight; y++)
          for (var x = 0; x < level.boxWidth; x++)
            level.solution[(boxRow + y) * level.size + boxColumn + x],
      }, expected);
    }
  }
}

(int, int) _emptyPeers(SudokuLevelDefinition level) {
  for (var first = 0; first < level.puzzle.length; first++) {
    if (level.puzzle[first] >= 0) continue;
    for (var peer = 0; peer < level.puzzle.length; peer++) {
      if (level.puzzle[peer] >= 0 || first == peer) continue;
      final sameRow = first ~/ level.size == peer ~/ level.size;
      final sameColumn = first % level.size == peer % level.size;
      final sameBox =
          first ~/ level.size ~/ level.boxHeight ==
              peer ~/ level.size ~/ level.boxHeight &&
          first % level.size ~/ level.boxWidth ==
              peer % level.size ~/ level.boxWidth;
      if (sameRow || sameColumn || sameBox) return (first, peer);
    }
  }
  throw StateError('Aucune paire vide voisine');
}
