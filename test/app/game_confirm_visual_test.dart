import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/app_theme.dart';
import 'package:papatte_parc/shared/game_stage_layout.dart';
import 'package:papatte_parc/shared/park_catalog.dart';

import '../support/visible_artwork.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'confirmation de sortie aux formats portrait et paysage',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final size in [const Size(800, 360), const Size(360, 800)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              backgroundColor: const Color(0xff355846),
              body: Center(
                child: GameConfirmDialog(
                  biome: LevelBiome.tropical,
                  title: const Text('Abandonner ce niveau ?'),
                  content: const Text(
                    'La progression de cette partie sera perdue.',
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Continuer'),
                    ),
                    TextButton(onPressed: () {}, child: const Text('Quitter')),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await loadVisibleArtwork(tester);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile(
            '../goldens/confirm-exit-${size.width.toInt()}x${size.height.toInt()}.png',
          ),
        );
      }
    },
    skip: !Platform.isWindows,
  );
}
