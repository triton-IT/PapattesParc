import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/board_camera.dart';
import 'package:papatte_parc/shared/park_stages.dart';
import 'package:papatte_parc/games/repas_animaux/domain/models.dart';
import 'package:papatte_parc/games/repas_animaux/domain/repas_session.dart';
import 'package:papatte_parc/games/repas_animaux/presentation/repas_screen.dart';

void main() {
  testWidgets('zoom, touch navigation and recenter preserve one finger play', (
    tester,
  ) async {
    final camera = TransformationController();
    addTearDown(camera.dispose);
    var taps = 0;
    var drags = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: BoardCamera(
              transformationController: camera,
              child: GestureDetector(
                key: const Key('game-drag-target'),
                onTap: () => taps++,
                onPanUpdate: (_) {
                  final context = tester.element(
                    find.byKey(const Key('game-drag-target')),
                  );
                  if (!BoardCamera.isNavigating(context)) drags++;
                },
                child: const SizedBox(
                  width: 352,
                  height: 300,
                  child: ColoredBox(color: Colors.green),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(100, 100));
    expect(taps, 1);
    expect(drags, 0);
    await tester.tap(find.byTooltip('Agrandir le plateau'));
    await tester.pump();
    expect(camera.value.getMaxScaleOnAxis(), closeTo(1.4, .001));
    final before = camera.value.clone();
    final first = await tester.startGesture(const Offset(100, 100), pointer: 1);
    final second = await tester.startGesture(
      const Offset(200, 100),
      pointer: 2,
    );
    await tester.pump();
    await first.moveBy(const Offset(50, 30));
    await second.moveBy(const Offset(50, 30));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(camera.value, isNot(before));
    expect(taps, 1);
    expect(drags, 0);
    await tester.tap(find.byTooltip('Recentrer le plateau'));
    await tester.pump();
    expect(camera.value, Matrix4.identity());
  });

  testWidgets('a mouse can pan an enlarged board', (tester) async {
    final camera = TransformationController();
    addTearDown(camera.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: BoardCamera(
              transformationController: camera,
              child: const SizedBox(
                width: 352,
                height: 300,
                child: ColoredBox(color: Colors.green),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Agrandir le plateau'));
    await tester.pump();
    final before = camera.value.clone();
    await tester.tap(find.byTooltip('Déplacer le plateau'));
    await tester.pump();
    final mouse = await tester.startGesture(
      const Offset(120, 120),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await mouse.moveBy(const Offset(40, 0));
    await mouse.moveBy(const Offset(40, 0));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(camera.value, isNot(before));
  });

  testWidgets('Repas camera gestures never move the keeper', (tester) async {
    var moves = 0;
    final session = RepasSession(
      RepasLevelDefinition(
        stage: parkStages.first,
        rows: const ['#####', '#s..#', '#.c.#', '#.t.#', '#####'],
        parPushes: 1,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: RepasBoard(session: session, onMove: (_) => moves++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Agrandir le plateau'));
    await tester.pump();
    final first = await tester.startGesture(const Offset(140, 150), pointer: 1);
    final second = await tester.startGesture(
      const Offset(220, 150),
      pointer: 2,
    );
    await first.moveBy(const Offset(30, 10));
    await second.moveBy(const Offset(30, 10));
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(moves, 0);
    await tester.tap(find.byTooltip('Déplacer le plateau'));
    await tester.pump();
    final mouse = await tester.startGesture(
      const Offset(180, 150),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveBy(const Offset(50, 0));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(moves, 0);
    await tester.tap(find.byTooltip('Déplacer le plateau'));
    await tester.tap(find.byTooltip('Recentrer le plateau'));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(180, 150), const Offset(50, 0));
    await tester.pumpAndSettle();
    expect(moves, 1);
    expect(tester.takeException(), isNull);
  });
}
