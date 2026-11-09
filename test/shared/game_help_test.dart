import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/game_help.dart';

void main() {
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
        expect(find.text('J’AI COMPRIS'), findsOneWidget);
        await tester.tap(find.text('J’AI COMPRIS'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continuer'));
        expect(presses, 1);
      });
    }
  }
}
