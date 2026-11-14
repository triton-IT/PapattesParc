import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/refuge/domain/board_generator.dart';
import 'package:papatte_parc/games/refuge/domain/game_session.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/refuge/domain/models.dart';
import 'package:papatte_parc/shared/park_catalog.dart';

void main() {
  test('annuler restaure une balise et son compteur', () {
    const config = BoardConfig(9, 9, 10);
    final board = generateCertifiedBoard(config, const CellPosition(4, 4), 91)!;
    final session = GameSession(config)..prepare(board, practice: false);
    final position = [
      for (var y = 0; y < config.height; y++)
        for (var x = 0; x < config.width; x++) CellPosition(x, y),
    ].firstWhere((p) => !session.cell(p).isRevealed);
    final remaining = session.remainingAnimals;
    session.toggleFlag(position);
    expect(session.cell(position).isFlagged, isTrue);
    expect(session.undo(), isTrue);
    expect(session.cell(position).isFlagged, isFalse);
    expect(session.remainingAnimals, remaining);
  });
  test(
    'les indices du refuge restent corrects et signalent une balise erronée',
    () {
      const config = BoardConfig(9, 9, 10);
      final board = generateCertifiedBoard(
        config,
        const CellPosition(4, 4),
        91,
      )!;
      final session = GameSession(config)..prepare(board, practice: false);
      final hint = session.hint();
      expect(hint, isNotNull);
      expect(board.isAnimal(hint!.$1), hint.$2 == 'pose une balise ici');
      const small = BoardConfig(3, 3, 1);
      final wrongFlagSession = GameSession(small)
        ..prepare(
          GeneratedBoard(
            small,
            1,
            const CellPosition(0, 0),
            [false, true, false, false, false, false, false, false, false],
            List.filled(9, 1),
            const [],
          ),
          practice: false,
        );
      const wrong = CellPosition(0, 1);
      wrongFlagSession.toggleFlag(wrong);
      expect(wrongFlagSession.hint(), (wrong, 'retire cette balise'));
    },
  );
  test('les cinq tempéraments couvrent les 45 missions', () {
    final counts = {
      for (final temperament in AnimalTemperament.values)
        temperament: levels
            .where((level) => level.temperament == temperament)
            .length,
    };

    expect(counts, {
      AnimalTemperament.curious: 13,
      AnimalTemperament.majestic: 9,
      AnimalTemperament.peaceful: 9,
      AnimalTemperament.adventurous: 7,
      AnimalTemperament.brave: 7,
    });
  });

  test('les 45 missions sont jouables sans hasard', () {
    for (final level in levels) {
      final firstMove = CellPosition(
        level.config.width ~/ 2,
        level.config.height ~/ 2,
      );
      final board = generateCertifiedBoard(
        level.config,
        firstMove,
        level.number,
      );
      expect(board, isNotNull, reason: 'Niveau ${level.number}');
      expect(CertificateVerifier.verify(board!), isTrue);
      for (var y = firstMove.y - 1; y <= firstMove.y + 1; y++) {
        for (var x = firstMove.x - 1; x <= firstMove.x + 1; x++) {
          expect(board.isAnimal(CellPosition(x, y)), isFalse);
        }
      }
    }
  });

  test('le certificat mène à une victoire complète', () {
    final config = const BoardConfig(9, 9, 10);
    final board = generateCertifiedBoard(config, const CellPosition(4, 4), 91)!;
    final session = GameSession(config)..prepare(board, practice: false);
    for (final step in board.certificate.skip(1)) {
      for (final target in step.targets) {
        if (step.kind == DeductionKind.flagAnimals ||
            step.kind == DeductionKind.flagRemainingAnimals) {
          session.toggleFlag(target);
        } else {
          session.reveal(target);
        }
      }
    }
    expect(session.status, GameStatus.won);
  });

  test('une défaite ne révèle pas les autres animaux', () {
    const config = BoardConfig(9, 9, 10);
    final board = generateCertifiedBoard(config, const CellPosition(4, 4), 47)!;
    final animals = [
      for (var y = 0; y < config.height; y++)
        for (var x = 0; x < config.width; x++)
          if (board.isAnimal(CellPosition(x, y))) CellPosition(x, y),
    ];
    final session = GameSession(config)..prepare(board, practice: false);

    session.reveal(animals.first);

    expect(session.status, GameStatus.lost);
    expect(session.cell(animals.first).isRevealed, isTrue);
    for (final animal in animals.skip(1)) {
      expect(session.cell(animal).isRevealed, isFalse);
    }
  });

  test('la génération experte respecte le budget de performance', () {
    const config = BoardConfig(30, 16, 99);
    final stopwatch = Stopwatch()..start();
    for (var sample = 0; sample < 20; sample++) {
      expect(
        generateCertifiedBoard(
          config,
          const CellPosition(15, 8),
          sample * 1009,
        ),
        isNotNull,
      );
    }
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(5000));
  });
}
