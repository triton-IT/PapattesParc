import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/campaign_selection_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/app_harness.dart';

void main() {
  const games = <(String, String, String)>[
    ('game-refuge', 'refuge', 'board-background'),
    ('game-pattes-friandises', 'match3', 'match3-cell-0-0'),
    ('game-mahjong-animaux', 'mahjong', 'mahjong-board'),
    ('game-solitaire-animaux', 'solitaire', 'solitaire-board'),
    ('game-sudoku-animaux', 'sudoku', 'sudoku-board'),
    ('game-repas-animaux', 'repas', 'repas-board'),
    ('game-numberlink', 'numberlink', 'numberlink-board'),
    ('game-animal-sort', 'animal-sort', 'animal-sort-board'),
  ];
  const sizes = [
    Size(320, 568),
    Size(568, 320),
    Size(800, 360),
    Size(390, 844),
    Size(844, 390),
    Size(611, 896),
    Size(1024, 600),
    Size(1024, 768),
    Size(900, 900),
    Size(2560, 1080),
  ];

  for (final size in sizes) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'eight games fit $size text $scale and keep playable boards',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          SharedPreferences.setMockInitialValues({
            for (final prefix in [
              'journey',
              'match3',
              'mahjong',
              'solitaire',
              'sudoku',
              'repas',
              'numberlink',
              'animalSort',
            ])
              '$prefix:unlockedLevel': 45,
            'settings:musicEnabled': false,
            'settings:effectsEnabled': false,
          });
          for (final (menu, prefix, board) in games) {
            await tester.pumpWidget(const SizedBox.shrink());
            CampaignSelectionController.clearSessions();
            await tester.pumpWidget(await testApp());
            await tester.pumpAndSettle();
            final card = find.byKey(Key(menu));
            await tester.scrollUntilVisible(
              card,
              250,
              scrollable: find.byType(Scrollable).first,
            );
            final button = find.descendant(
              of: card,
              matching: find.byType(FilledButton),
            );
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            await tester.tap(button);
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$prefix levels $size/$scale',
            );
            final play = find.byKey(const Key('campaign-play-selected'));
            await tester.ensureVisible(play);
            await tester.tap(play);
            await settleGeneration(tester);
            expect(find.byKey(Key(board)), findsOneWidget, reason: prefix);
            expect(
              tester.takeException(),
              isNull,
              reason: '$prefix board $size/$scale',
            );
            if (size == const Size(800, 360) &&
                scale == 1 &&
                ['sudoku', 'numberlink'].contains(prefix)) {
              final actual = tester.getSize(find.byKey(Key(board)));
              expect(
                actual.shortestSide,
                greaterThanOrEqualTo(240),
                reason: prefix,
              );
            }
            if (prefix == 'solitaire') {
              expect(
                find.byKey(const Key('solitaire-tableau-scroll')),
                findsOneWidget,
              );
            }
            // Resize an active session without losing its board.
            tester.view.physicalSize = Size(size.height, size.width);
            await tester.pumpAndSettle();
            expect(find.byKey(Key(board)), findsOneWidget);
            expect(tester.takeException(), isNull, reason: '$prefix rotated');
            tester.view.physicalSize = size;
          }
        },
      );
    }
  }
}
