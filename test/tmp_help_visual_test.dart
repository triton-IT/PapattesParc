import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/app_theme.dart';
import 'package:papatte_parc/shared/game_help.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('aperçu temporaire du guide', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: Center(child: GameHelpButton(kind: GameHelpKind.match3)),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('help-match3')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(
      tester.renderObject<RenderImage>(
        find.descendant(
          of: find.byKey(const Key('help-coach-suricate')),
          matching: find.byType(RawImage),
        ),
      ).image,
      isNotNull,
    );
    await expectLater(
      find.byType(Overlay),
      matchesGoldenFile('../tmp/help-coach-360x800.png'),
    );
  });
}
