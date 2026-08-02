import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/pattes_friandises/presentation/custom_game_screen.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/sudoku_animaux/domain/models.dart';
import 'package:papatte_parc/games/sudoku_animaux/presentation/custom_game_screen.dart';
import 'package:papatte_parc/shared/app_theme.dart';
import 'package:papatte_parc/shared/park_catalog.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final size in _sizes) {
    testWidgets('références des parties libres ${_name(size)}', (tester) async {
      await _pump(
        tester,
        size,
        Match3CustomGameScreen(stages: levels, onBack: () {}, onStart: (_) {}),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/match3-custom-${_name(size)}.png'),
      );

      await _pump(
        tester,
        size,
        SudokuCustomGameScreen(
          stages: levels,
          initialConfig: const SudokuFreeGameConfig(
            size: 6,
            difficulty: SudokuDifficulty.medium,
            biome: LevelBiome.riverside,
          ),
          onBack: () {},
          onStart: (_) {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/sudoku-custom-${_name(size)}.png'),
      );
    }, skip: !Platform.isWindows);
  }
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
    () => Future.wait([
      precacheImage(
        const AssetImage('assets/level_art/level-01-suricates-porcs-epics.png'),
        tester.element(find.byType(MaterialApp)),
      ),
      precacheImage(
        const AssetImage('assets/level_art/level-09-gibbons-loutres-asie.png'),
        tester.element(find.byType(MaterialApp)),
      ),
    ]),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: '$size');
}

String _name(Size size) => '${size.width.toInt()}x${size.height.toInt()}';
