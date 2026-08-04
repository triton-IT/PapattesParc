import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/app/main_menu_screen.dart';
import 'package:papatte_parc/games/mahjong_animaux/data/mahjong_progress_store.dart';
import 'package:papatte_parc/games/pattes_friandises/data/match3_progress_store.dart';
import 'package:papatte_parc/games/refuge/data/progress_store.dart';
import 'package:papatte_parc/games/repas_animaux/data/repas_animaux_progress_store.dart';
import 'package:papatte_parc/games/solitaire_animaux/data/solitaire_progress_store.dart';
import 'package:papatte_parc/games/sudoku_animaux/data/sudoku_progress_store.dart';
import 'package:papatte_parc/shared/app_theme.dart';
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

  testWidgets('références visuelles du menu', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final refuge = await ProgressStore.load();
    final match3 = await Match3ProgressStore.load();
    final mahjong = await MahjongProgressStore.load();
    final solitaire = await SolitaireProgressStore.load();
    final sudoku = await SudokuProgressStore.load();
    final repas = await RepasAnimauxProgressStore.load();
    for (final size in _sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MainMenuScreen(
            refugeStore: refuge,
            match3Store: match3,
            mahjongStore: mahjong,
            solitaireStore: solitaire,
            sudokuStore: sudoku,
            repasStore: repas,
            musicEnabled: true,
            effectsEnabled: true,
            onSelect: (_) {},
            onToggleMusic: () {},
            onToggleEffects: () {},
            onQuit: null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/menu-progress-${_name(size)}.png'),
      );
    }
  }, skip: !Platform.isWindows);
}

const _sizes = [
  Size(360, 800),
  Size(800, 1280),
  Size(1366, 768),
  Size(1920, 1080),
];

String _name(Size size) => '${size.width.toInt()}x${size.height.toInt()}';
