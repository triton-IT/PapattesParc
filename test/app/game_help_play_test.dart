import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/app_harness.dart';

void main() {
  testWidgets('aide en partie et fermeture', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('game-pattes-friandises')));
    await tester.pumpAndSettle();
    await openLevel(tester, 'match3', 1);
    await tester.tap(find.byKey(const Key('help-match3')));
    await tester.pumpAndSettle();
    expect(find.text('J’AI COMPRIS'), findsOneWidget);
    await tester.tap(find.text('J’AI COMPRIS'));
    await tester.pumpAndSettle();
    expect(find.text('J’AI COMPRIS'), findsNothing);
    await tester.tap(find.byKey(const Key('help-match3')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('J’AI COMPRIS'), findsNothing);
    await tester.tap(find.byKey(const Key('help-match3')));
    await tester.pumpAndSettle();
    expect(find.text('J’AI COMPRIS'), findsOneWidget);
  });
}
