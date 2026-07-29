import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/data/progress_store.dart';
import 'package:papatte_parc/domain/board_generator.dart';
import 'package:papatte_parc/domain/game_session.dart';
import 'package:papatte_parc/domain/levels.dart';
import 'package:papatte_parc/domain/models.dart';
import 'package:papatte_parc/presentation/app_theme.dart';
import 'package:papatte_parc/presentation/custom_game_screen.dart';
import 'package:papatte_parc/presentation/game_screen.dart';
import 'package:papatte_parc/presentation/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('références visuelles responsive', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final level = levels.first;
    for (final size in _sizes) {
      await _pump(
        tester,
        size,
        HomeScreen(
          levelIndex: 0,
          store: store,
          onSelectLevel: (_) {},
          onPlayLevel: (_) {},
          onCreateCustom: () {},
          musicEnabled: true,
          onToggleMusic: () {},
          effectsEnabled: true,
          onToggleEffects: () {},
          onButtonClick: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/home-${_name(size)}.png'),
      );

      await _pump(
        tester,
        size,
        CustomGameScreen(onBack: () {}, onStart: (_) {}, onButtonClick: () {}),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/custom-${_name(size)}.png'),
      );

      final playing = _playingSession(level);
      await _pump(
        tester,
        size,
        GameScreen(
          level: level,
          session: playing,
          generating: false,
          finished: false,
          newRecord: false,
          onHome: () {},
          onReveal: (_) {},
          onFlag: (_) {},
          onReplaySame: () {},
          onReplayNew: () {},
          onNext: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/mission-${_name(size)}.png'),
      );

      final won = _wonSession(level);
      await _pump(
        tester,
        size,
        GameScreen(
          level: level,
          session: won,
          generating: false,
          finished: true,
          newRecord: true,
          onHome: () {},
          onReveal: (_) {},
          onFlag: (_) {},
          onReplaySame: () {},
          onReplayNew: () {},
          onNext: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/result-${_name(size)}.png'),
      );
    }
  });
}

const _sizes = [
  Size(360, 800),
  Size(800, 1280),
  Size(1366, 768),
  Size(1920, 1080),
];

Future<void> _pump(WidgetTester tester, Size size, Widget screen) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: screen));
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/level_art/level-01-suricates-porcs-epics.png'),
      tester.element(find.byType(MaterialApp)),
    ),
  );
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/park_map.png'),
      tester.element(find.byType(MaterialApp)),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: '$size');
}

String _name(Size size) => '${size.width.toInt()}x${size.height.toInt()}';

GameSession _playingSession(LevelDefinition level) {
  final board = generateCertifiedBoard(
    level.config,
    const CellPosition(3, 3),
    71,
  )!;
  return GameSession(level.config)..prepare(board, practice: false);
}

GameSession _wonSession(LevelDefinition level) {
  final board = generateCertifiedBoard(
    level.config,
    const CellPosition(3, 3),
    73,
  )!;
  final session = GameSession(level.config)..prepare(board, practice: false);
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
  return session;
}
