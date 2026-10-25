import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/app/game_app.dart';
import 'package:papatte_parc/games/refuge/data/progress_store.dart';
import 'package:papatte_parc/games/pattes_friandises/data/match3_progress_store.dart';
import 'package:papatte_parc/games/mahjong_animaux/data/mahjong_progress_store.dart';
import 'package:papatte_parc/games/solitaire_animaux/data/solitaire_progress_store.dart';
import 'package:papatte_parc/games/sudoku_animaux/data/sudoku_progress_store.dart';
import 'package:papatte_parc/games/repas_animaux/data/repas_animaux_progress_store.dart';
import 'package:papatte_parc/games/sentiers_sauvages/data/numberlink_progress_store.dart';
import 'package:papatte_parc/games/familles_du_parc/data/animal_sort_progress_store.dart';
import 'package:papatte_parc/shared/settings_store.dart';
import 'package:papatte_parc/shared/generation_overlay.dart';

Future<PapatteParcApp> testApp() async => PapatteParcApp(
  key: UniqueKey(),
  refugeStore: await ProgressStore.load(),
  match3Store: await Match3ProgressStore.load(),
  mahjongStore: await MahjongProgressStore.load(),
  solitaireStore: await SolitaireProgressStore.load(),
  sudokuStore: await SudokuProgressStore.load(),
  repasStore: await RepasAnimauxProgressStore.load(),
  numberlinkStore: await NumberlinkProgressStore.load(),
  animalSortStore: await AnimalSortProgressStore.load(),
  settings: await SettingsStore.load(),
);

Future<void> settleGeneration(WidgetTester tester) async {
  await tester.pump();
  for (
    var i = 0;
    i < 400 && find.byType(GenerationOverlay).evaluate().isNotEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  expect(
    find.byType(GenerationOverlay),
    findsNothing,
    reason: 'generation must finish or report its error',
  );
  await tester.pumpAndSettle();
}

Future<void> openLevel(WidgetTester tester, String prefix, int level) async {
  await tester.tap(find.byKey(Key('$prefix-level-list')));
  await tester.pumpAndSettle();
  final tile = find.byKey(Key('$prefix-list-level-$level'));
  await tester.scrollUntilVisible(
    tile,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(tile);
  await tester.pumpAndSettle();
  final play = find.byKey(const Key('campaign-play-selected'));
  await tester.ensureVisible(play);
  await tester.tap(play);
  await settleGeneration(tester);
}

Future<void> expectLockedLevel(
  WidgetTester tester,
  String prefix,
  int level,
) async {
  await tester.tap(find.byKey(Key('$prefix-level-list')));
  await tester.pumpAndSettle();
  final tile = find.byKey(Key('$prefix-list-level-$level'));
  await tester.scrollUntilVisible(
    tile,
    150,
    scrollable: find.byType(Scrollable).last,
  );
  expect(tester.widget<ListTile>(tile).enabled, isFalse);
  Navigator.of(tester.element(tile)).pop();
  await tester.pumpAndSettle();
}
