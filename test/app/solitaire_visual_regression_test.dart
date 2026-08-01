import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/solitaire_animaux/data/solitaire_progress_store.dart';
import 'package:papatte_parc/games/solitaire_animaux/domain/models.dart';
import 'package:papatte_parc/games/solitaire_animaux/domain/solitaire_session.dart';
import 'package:papatte_parc/games/solitaire_animaux/presentation/game_screen.dart';
import 'package:papatte_parc/games/solitaire_animaux/presentation/setup_screen.dart';
import 'package:papatte_parc/shared/animal_catalog.dart';
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

  testWidgets('références visuelles du solitaire', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final progress = await SolitaireProgressStore.load();
    for (final size in _sizes) {
      await _pump(
        tester,
        size,
        SolitaireSetupScreen(
          progress: progress,
          mode: SolitaireMode.drawOne,
          animal: AnimalKind.suricate,
          musicEnabled: true,
          effectsEnabled: true,
          onModeChanged: (_) {},
          onAnimalChanged: (_) {},
          onToggleMusic: () {},
          onToggleEffects: () {},
          onStart: () {},
          onExit: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/solitaire-setup-${_name(size)}.png'),
      );

      final session = SolitaireSession(mode: SolitaireMode.drawThree, seed: 41);
      session.draw();
      await _pump(tester, size, _screen(session));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/solitaire-game-${_name(size)}.png'),
      );

      session.tick(const Duration(minutes: 4, seconds: 12));
      await _pump(tester, size, _screen(session, finished: true));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/solitaire-result-${_name(size)}.png'),
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

Future<void> _pump(WidgetTester tester, Size size, Widget screen) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: screen));
  for (final animal in AnimalKind.values) {
    await tester.runAsync(
      () => precacheImage(
        AssetImage(animal.asset),
        tester.element(find.byType(MaterialApp)),
      ),
    );
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: '$size');
}

SolitaireGameScreen _screen(
  SolitaireSession session, {
  bool finished = false,
}) => SolitaireGameScreen(
  session: session,
  backAnimal: AnimalKind.suricate,
  selected: null,
  hint: null,
  finished: finished,
  newRecord: finished,
  onDraw: () {},
  onCardTap: (_) {},
  onDoubleTap: (_) {},
  onMove: (_) {},
  onUndo: () {},
  onHint: () {},
  onBack: () {},
  onNewGame: () {},
  onReplay: () {},
  onConfigure: () {},
  onExit: () {},
);

String _name(Size size) => '${size.width.toInt()}x${size.height.toInt()}';
