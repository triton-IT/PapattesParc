import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/wooden_sign.dart';
import 'package:papatte_parc/shared/game_stage_layout.dart';
import 'package:papatte_parc/shared/park_catalog.dart';

void main() {
  testWidgets('result button labels remain centered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: GameResultPanel(
                biome: LevelBiome.tropical,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
        ),
      ),
    );
    for (final label in ['Continuer', 'Quitter']) {
      final sign = find
          .ancestor(of: find.text(label), matching: find.byType(WoodenSign))
          .first;
      expect(
        tester.getCenter(find.text(label)).dx,
        closeTo(tester.getCenter(sign).dx, 0.01),
      );
      expect(
        tester.getCenter(find.text(label)).dy,
        closeTo(tester.getCenter(sign).dy, 0.01),
      );
    }
  });

  testWidgets('wooden signs paint at narrow and wide sizes', (tester) async {
    for (final green in [true, false]) {
      for (final size in [
        const Size(90, 58),
        const Size(320, 48),
        const Size(700, 75),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: WoodenSign(
                    green: green,
                    child: const Center(child: Text('Action')),
                  ),
                ),
              ),
            ),
          ),
        );
        final context = tester.element(find.byType(WoodenSign));
        final background = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(WoodenSign),
                matching: find.byType(DecoratedBox),
              ),
            )
            .first;
        final image = (background.decoration as BoxDecoration).image!.image;
        await tester.runAsync(() => precacheImage(image, context));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(WoodenSign)), size);
      }
    }
  });
}
