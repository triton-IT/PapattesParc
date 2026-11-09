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
    final before = viewer.transformationController!.value.entry(0, 0);
    await tester.tap(find.byTooltip('Agrandir le plateau'));
    await tester.pump();
    expect(
      viewer.transformationController!.value.entry(0, 0),
      closeTo(before * 1.4, .001),
    );
    await tester.tap(find.byTooltip('Réduire le plateau'));
    await tester.pump();
    expect(
      viewer.transformationController!.value.entry(0, 0),
      closeTo(before, .001),
    );
  });

  testWidgets('la grande grille tient dans le cadre et peut être recentrée', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1672, 941));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final level = levels[10];
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: level,
          session: GameSession(level.config),
          generating: false,
          finished: false,
          newRecord: false,
          onHome: () {},
          onReveal: (_) {},
          onFlag: (_) {},
          onReplaySame: () {},
          onReplayNew: () {},
          onNext: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final viewerFinder = find.byKey(const Key('refuge-board-viewer'));
    final viewport = tester.getRect(viewerFinder);
    // The parchment starts near (193, 225); keep the clipped camera area
    // inside its illustrated border, including at higher zoom levels.
    expect(viewport, const Rect.fromLTWH(213, 245, 515, 491));
    final first = tester.getRect(find.byKey(const Key('cell-0-0')));
    final last = tester.getRect(find.byKey(const Key('cell-11-9')));
    expect(viewport.contains(first.topLeft), isTrue);
    expect(viewport.contains(last.bottomRight), isTrue);
    final camera = tester
        .widget<InteractiveViewer>(viewerFinder)
        .transformationController!;
    final overview = camera.value.clone();
    await tester.tap(find.byTooltip('Agrandir le plateau'));
    await tester.pump();
    await tester.tap(find.byTooltip('Recentrer le plateau'));
    await tester.pump();
    expect(camera.value, overview);
  });
}
