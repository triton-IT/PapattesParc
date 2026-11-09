import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/game_help.dart';
import 'package:papatte_parc/shared/wooden_sign.dart';

void main() {
  testWidgets('aide Mahjong utilise le panneau du jeu et garde ses consignes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GameHelpButton(kind: GameHelpKind.mahjong)),
      ),
    );
    await tester.tap(find.byKey(const Key('help-mahjong')));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox && widget.decoration == parchmentDecoration,
      ),
      findsOneWidget,
    );
    expect(find.byType(WoodenSign), findsOneWidget);
    expect(find.text('1 sur 3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('help-coach-next')));
    await tester.pumpAndSettle();
    expect(find.text('2 sur 3'), findsOneWidget);
    expect(find.textContaining('Une tuile est libre'), findsOneWidget);
    await tester.tap(find.byKey(const Key('help-coach-previous')));
    await tester.pumpAndSettle();
    expect(find.text('1 sur 3'), findsOneWidget);
  });

  for (final size in [const Size(360, 800), const Size(800, 360)]) {
    for (final kind in GameHelpKind.values) {
      testWidgets('aide ${kind.name} à $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var presses = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  GameHelpButton(kind: kind),
                  TextButton(
                    onPressed: () => presses++,
                    child: const Text('Continuer'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(Key('help-${kind.name}')));
        await tester.pumpAndSettle();
        expect(find.byKey(Key('help-content-${kind.name}')), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration == parchmentDecoration,
          ),
          findsOneWidget,
        );
        expect(find.byType(WoodenSign), findsOneWidget);
        if (kind == GameHelpKind.match3) {
          expect(find.byKey(const Key('match3-legend')), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('À LIVRER'),
            200,
            scrollable: find.descendant(
              of: find.byKey(const Key('help-content-match3')),
              matching: find.byType(Scrollable),
            ),
          );
          expect(find.text('À LIVRER'), findsOneWidget);
        }
        expect(find.text('J’AI COMPRIS'), findsOneWidget);
        await tester.tap(find.text('J’AI COMPRIS'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continuer'));
        expect(presses, 1);
      });
    }
  }
}
