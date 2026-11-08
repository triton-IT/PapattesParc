import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/repas_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/repas_animaux/domain/models.dart';
import 'package:papatte_parc/games/repas_animaux/domain/repas_session.dart';
import 'package:papatte_parc/games/repas_animaux/presentation/repas_screen.dart';

void main() {
  testWidgets('décors et commandes du repas sur grand écran', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1672, 941));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final campaign = buildRepasCampaign(levels);
    for (final index in [0, 1, 17, 30, 44]) {
      final session = RepasSession(campaign[index]);
      RepasDirection? direction;
      var restarts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: RepasScreen(
            session: session,
            finished: false,
            newRecord: false,
            onMove: (value) => direction = value,
            onUndo: () {},
            onRestart: () => restarts++,
            onLevels: () {},
            onRetry: () {},
            onNext: null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(
        find.byKey(const Key('repas-scene-background')),
      );
      expect(
        (image.image as AssetImage).assetName,
        [
          'assets/optimized/sudoku/integrated-scene.webp',
          'assets/optimized/sudoku/lions-scene.webp',
          'assets/optimized/sudoku/tiger-river-scene-v2.webp',
          'assets/optimized/sudoku/urials-turs-caucasus-scene.webp',
          'assets/optimized/sudoku/alpaca-highland-meadow-scene.webp',
        ][[0, 1, 17, 30, 44].indexOf(index)],
      );
      for (final move in RepasDirection.values) {
        await tester.tap(find.byKey(Key('repas-move-${move.name}')));
        expect(direction, move);
      }
      await tester.tap(find.byKey(const Key('repas-restart')));
      expect(restarts, 1);
      expect(
        tester.getCenter(find.byTooltip('Agrandir le plateau')).dx,
        closeTo(1084, 1),
      );
      await tester.tap(find.byTooltip('Agrandir le plateau'));
      await tester.pump();
      await tester.tap(find.byTooltip('Recentrer le plateau'));
      expect(tester.takeException(), isNull);
    }
  });
}
