import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/refuge/domain/game_session.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/refuge/presentation/game_screen.dart';

void main() {
  testWidgets('décor et commandes du refuge restent interactifs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1672, 941));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final level = levels[1];
    var reveals = 0;
    var flags = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: level,
          session: GameSession(level.config),
          generating: false,
          finished: false,
          newRecord: false,
          onHome: () {},
          onReveal: (_) => reveals++,
          onFlag: (_) => flags++,
          onReplaySame: () {},
          onReplayNew: () {},
          onNext: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scene = tester.widget<Image>(
      find.byKey(const Key('refuge-scene-background')),
    );
    expect(
      (scene.image as AssetImage).assetName,
      'assets/optimized/sudoku/lions-scene.webp',
    );
    await tester.tap(find.byKey(const Key('cell-0-0')));
    expect(reveals, 1);
    await tester.longPress(find.byKey(const Key('cell-0-0')));
    expect(flags, 1);
    final viewer = tester.widget<InteractiveViewer>(
      find.byKey(const Key('refuge-board-viewer')),
    );
    final before = viewer.transformationController!.value.getMaxScaleOnAxis();
    await tester.tap(find.byTooltip('Agrandir le plateau'));
    await tester.pump();
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(before),
    );
  });
}
