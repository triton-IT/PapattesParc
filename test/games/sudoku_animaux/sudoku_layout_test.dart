import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/sudoku_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/sudoku_animaux/domain/sudoku_session.dart';
import 'package:papatte_parc/games/sudoku_animaux/presentation/sudoku_screen.dart';
import 'package:papatte_parc/shared/artwork.dart';

void main() {
  testWidgets('plateau et animaux restent disponibles selon la taille', (
    tester,
  ) async {
    final campaign = buildSudokuCampaign(levels);
    for (final dimensions in [
      const Size(800, 360),
      const Size(360, 800),
      const Size(1672, 941),
    ]) {
      await tester.binding.setSurfaceSize(dimensions);
      for (final levelIndex in [0, 15, 18, 30]) {
        final session = SudokuSession(campaign[levelIndex]);
        final selected = session.entries.indexOf(null);
        await tester.pumpWidget(
          MaterialApp(
            home: SudokuScreen(
              session: session,
              selectedIndex: selected,
              noteMode: false,
              wrongIndex: null,
              finished: false,
              newRecord: false,
              onSelectCell: (_) {},
              onSelectAnimal: (_) {},
              onToggleNotes: () {},
              onClear: () {},
              onHint: () {},
              onBack: () {},
              onReplay: () {},
              onLevels: () {},
              onNext: () {},
            ),
          ),
        );
        await tester.pump();
        if (levelIndex == 18) {
          expect(
            find.byWidgetPredicate(
              (widget) => widget is ArtworkImage &&
                  widget.asset == 'assets/level_art/level-19-dholes.png',
            ),
            findsOneWidget,
          );
        }
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pump();
        expect(find.byKey(const Key('sudoku-board')), findsOneWidget);
        expect(
          find.byKey(Key('sudoku-cell-${session.entries.length - 1}')),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('sudoku-animal-${session.level.animals.length - 1}')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    }
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'la grille en perspective et les commandes restent interactives',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1672, 941));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final campaign = buildSudokuCampaign(levels);
      const controlTooltips = [
        'Agrandir le plateau',
        'Réduire le plateau',
        'Déplacer le plateau',
        'Recentrer le plateau',
      ];
      const expectedControlCenters = [
        Offset(1084, 338),
        Offset(1084, 444),
        Offset(1084, 550),
        Offset(1084, 656),
      ];
      for (final levelIndex in [0, 15, ...List.generate(15, (i) => 30 + i)]) {
        final session = SudokuSession(campaign[levelIndex]);
        final selected = session.entries.lastIndexOf(null);
        int? tappedCell, tappedAnimal;
        var notes = 0, cleared = 0, hints = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: SudokuScreen(
              session: session,
              selectedIndex: selected,
              noteMode: false,
              wrongIndex: null,
              finished: false,
              newRecord: false,
              onSelectCell: (i) => tappedCell = i,
              onSelectAnimal: (i) => tappedAnimal = i,
              onToggleNotes: () => notes++,
              onClear: () => cleared++,
              onHint: () => hints++,
              onBack: () {},
              onReplay: () {},
              onLevels: () {},
              onNext: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < controlTooltips.length; i++) {
          final center = tester.getCenter(find.byTooltip(controlTooltips[i]));
          expect(center.dx, closeTo(expectedControlCenters[i].dx, 1));
          expect(center.dy, closeTo(expectedControlCenters[i].dy, 1));
        }
        await tester.tap(find.byKey(Key('sudoku-cell-$selected')));
        expect(tappedCell, selected);
        final animal = find.byKey(
          Key('sudoku-animal-${session.level.size - 1}'),
        );
        await tester.ensureVisible(animal);
        await tester.tap(animal);
        expect(tappedAnimal, session.level.size - 1);
        expect(
          find.byKey(const Key('sudoku-hint')).hitTestable(),
          findsOneWidget,
        );
        for (final entry in [
          (const Key('sudoku-notes'), () => notes),
          (const Key('sudoku-clear'), () => cleared),
          (const Key('sudoku-hint'), () => hints),
        ]) {
          final button = find.byKey(entry.$1);
          await tester.ensureVisible(button);
          await tester.tap(button);
          expect(entry.$2(), 1);
        }
        await tester.tap(find.byTooltip('Agrandir le plateau'));
        await tester.pump();
        await tester.tap(find.byTooltip('Recentrer le plateau'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('les infobulles des commandes utilisent le style du Sudoku', (
    tester,
  ) async {
    for (final dimensions in [const Size(1672, 941), const Size(800, 360)]) {
      await tester.binding.setSurfaceSize(dimensions);
      final session = SudokuSession(buildSudokuCampaign(levels).first);
      await tester.pumpWidget(
        MaterialApp(
          home: SudokuScreen(
            session: session,
            selectedIndex: session.entries.indexOf(null),
            noteMode: false,
            wrongIndex: null,
            finished: false,
            newRecord: false,
            onSelectCell: (_) {},
            onSelectAnimal: (_) {},
            onToggleNotes: () {},
            onClear: () {},
            onHint: () {},
            onBack: () {},
            onReplay: () {},
            onLevels: () {},
            onNext: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = find.byTooltip('Agrandir le plateau');
      final theme = TooltipTheme.of(tester.element(target));
      expect(theme.textStyle?.color, const Color(0xff563619));
      expect(theme.decoration, isA<BoxDecoration>());
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(target));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Agrandir le plateau', findRichText: true),
        findsOneWidget,
      );
      await mouse.removePointer();
      await tester.pumpAndSettle();
    }
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('chaque niveau utilise son décor', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1672, 941));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final campaign = buildSudokuCampaign(levels);
    const cameraTooltips = [
      'Agrandir le plateau',
      'Réduire le plateau',
      'Déplacer le plateau',
      'Recentrer le plateau',
    ];
    const cameraCenters = [
      Offset(1084, 338),
      Offset(1084, 444),
      Offset(1084, 550),
      Offset(1084, 656),
    ];
    for (final entry in [
      (0, false, 'assets/optimized/sudoku/integrated-scene.webp'),
      (1, false, 'assets/optimized/sudoku/lions-scene.webp'),
      (2, false, 'assets/optimized/sudoku/giraffes-scene.webp'),
      (3, false, 'assets/optimized/sudoku/madagascar-scene.webp'),
      (4, false, 'assets/optimized/sudoku/grande-savane-scene.webp'),
      (9, false, 'assets/optimized/sudoku/tamarins-armadillo-sloth-scene-v2.webp'),
      (17, false, 'assets/optimized/sudoku/tiger-river-scene-v2.webp'),
      (30, false, 'assets/optimized/sudoku/urials-turs-caucasus-scene.webp'),
      (31, false, 'assets/optimized/sudoku/brown-bear-valley-scene.webp'),
      (32, false, 'assets/optimized/sudoku/takin-markhor-cliffs-scene.webp'),
      (33, false, 'assets/optimized/sudoku/european-mink-stream-scene.webp'),
      (34, false, 'assets/optimized/sudoku/wolverine-woodland-scene.webp'),
      (35, false, 'assets/optimized/sudoku/deer-pig-forest-scene.webp'),
      (
        36,
        false,
        'assets/optimized/sudoku/red-pandas-winter-forest-scene.webp',
      ),
      (37, false, 'assets/optimized/sudoku/lemur-island-scene.webp'),
      (38, false, 'assets/optimized/sudoku/prevost-squirrel-canopy-scene.webp'),
      (39, false, 'assets/optimized/sudoku/barbary-macaque-forest-scene.webp'),
      (40, false, 'assets/optimized/sudoku/snow-leopard-cliffs-scene.webp'),
      (41, false, 'assets/optimized/sudoku/cheetah-grassland-scene.webp'),
      (42, false, 'assets/optimized/sudoku/cheetah-running-savanna-scene.webp'),
      (43, false, 'assets/optimized/sudoku/saimiri-pudu-rainforest-scene.webp'),
      (44, false, 'assets/optimized/sudoku/alpaca-highland-meadow-scene.webp'),
      (4, true, 'assets/optimized/sudoku/integrated-scene.webp'),
      (3, true, 'assets/optimized/sudoku/integrated-scene.webp'),
      (2, true, 'assets/optimized/sudoku/integrated-scene.webp'),
      (1, true, 'assets/optimized/sudoku/integrated-scene.webp'),
    ]) {
      final session = SudokuSession(campaign[entry.$1]);
      await tester.pumpWidget(
        MaterialApp(
          home: SudokuScreen(
            session: session,
            isFreeGame: entry.$2,
            selectedIndex: null,
            noteMode: false,
            wrongIndex: null,
            finished: false,
            newRecord: false,
            onSelectCell: (_) {},
            onSelectAnimal: (_) {},
            onToggleNotes: () {},
            onClear: () {},
            onHint: () {},
            onBack: () {},
            onReplay: () {},
            onLevels: () {},
            onNext: () {},
          ),
        ),
      );
      await tester.pump();
      final image = tester.widget<Image>(
        find.byKey(const Key('sudoku-scene-background')),
      );
      expect((image.image as AssetImage).assetName, entry.$3);
      await tester.runAsync(
        () => precacheImage(
          image.image,
          tester.element(find.byType(MaterialApp)),
        ),
      );
      await tester.pump();
      for (var i = 0; i < cameraTooltips.length; i++) {
        final center = tester.getCenter(find.byTooltip(cameraTooltips[i]));
        expect(center.dx, closeTo(cameraCenters[i].dx, 1));
        expect(center.dy, closeTo(cameraCenters[i].dy, 1));
      }
    }
  });
}
