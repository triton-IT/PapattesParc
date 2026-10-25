import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/campaign_selection_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/app_harness.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(1024, 600),
  ]) {
    testWidgets('free configurations remain accessible at text 200% $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({
        'settings:musicEnabled': false,
        'settings:effectsEnabled': false,
      });
      for (final (menu, prefix, start) in const [
        ('game-refuge', 'refuge', 'start-custom-game'),
        ('game-pattes-friandises', 'match3', 'match3-start-custom'),
        ('game-mahjong-animaux', 'mahjong', 'mahjong-start-custom'),
        ('game-solitaire-animaux', 'solitaire', 'solitaire-start'),
        ('game-sudoku-animaux', 'sudoku', 'sudoku-start-custom'),
        ('game-repas-animaux', 'repas', 'repas-custom-start'),
        ('game-numberlink', 'numberlink', 'numberlink-start-custom'),
        ('game-animal-sort', 'animal-sort', 'animal-sort-custom-start'),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        CampaignSelectionController.clearSessions();
        await tester.pumpWidget(await testApp());
        await tester.pumpAndSettle();
        final card = find.byKey(Key(menu));
        await tester.scrollUntilVisible(
          card,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final launch = find.descendant(
          of: card,
          matching: find.byType(FilledButton),
        );
        await tester.ensureVisible(launch);
        await tester.pumpAndSettle();
        await tester.tap(launch);
        await tester.pumpAndSettle();
        final custom = find.byKey(Key('$prefix-open-custom'));
        await tester.ensureVisible(custom);
        await tester.pumpAndSettle();
        await tester.tap(custom);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$prefix configuration');
        final button = find.byKey(Key(start));
        expect(button, findsOneWidget, reason: prefix);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        final center = tester.getCenter(button);
        expect(center.dy, inInclusiveRange(0, size.height));
        expect(tester.takeException(), isNull, reason: prefix);
      }
    });
  }
}
