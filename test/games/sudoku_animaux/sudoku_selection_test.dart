import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/sudoku_animaux/data/sudoku_progress_store.dart';
import 'package:papatte_parc/games/sudoku_animaux/presentation/sudoku_game_flow.dart';
import 'package:papatte_parc/games/sudoku_animaux/presentation/sudoku_screen.dart';
import 'package:papatte_parc/shared/campaign_selection_controller.dart';
import 'package:papatte_parc/shared/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/app_harness.dart';

void main() {
  for (final size in [const Size(1366, 768), const Size(360, 800)]) {
    testWidgets('sélection après placement sur $size', (tester) async {
      SharedPreferences.setMockInitialValues({
        'settings:musicEnabled': false,
        'settings:effectsEnabled': false,
      });
      CampaignSelectionController.clearSessions();
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: SudokuGameFlow(
            stages: levels,
            progress: await SudokuProgressStore.load(),
            settings: await SettingsStore.load(),
            onExit: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openLevel(tester, 'sudoku', 1);

      SudokuScreen screen() =>
          tester.widget<SudokuScreen>(find.byType(SudokuScreen));
      final session = screen().session;
      final first = session.entries.indexOf(null);
      final second = session.entries.indexOf(null, first + 1);
      await tester.tap(find.byKey(Key('sudoku-cell-$first')));
      await tester.pump();
      final wrong = (session.level.solution[first] + 1) % session.level.size;
      await tester.tap(find.byKey(Key('sudoku-animal-$wrong')));
      await tester.pump();
      expect(screen().selectedIndex, first);

      await tester.tap(
        find.byKey(Key('sudoku-animal-${session.level.solution[first]}')),
      );
      await tester.pump();
      expect(session.entries[first], session.level.solution[first]);
      expect(screen().selectedIndex, isNull);

      await tester.tap(find.byKey(Key('sudoku-cell-$second')));
      await tester.pump();
      expect(screen().selectedIndex, second);
      await tester.tap(find.byKey(Key('sudoku-cell-$first')));
      await tester.pump();
      expect(screen().selectedIndex, first);
    });
  }
}
