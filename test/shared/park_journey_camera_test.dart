import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/campaign_selection_controller.dart';
import 'package:papatte_parc/shared/park_journey_map.dart';

void main() {
  testWidgets(
    'overview is locked, zoom pans within the scene, and overview resets',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = CampaignSelectionController(0, 1);
      addTearDown(controller.camera.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParkJourneyMap(
              itemCount: 1,
              unlockedLevel: 1,
              keyPrefix: 'camera-test',
              labelBuilder: (_) => 'Mission',
              onSelect: (_) {},
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pump();
      final initial = controller.camera.value.clone();
      await tester.drag(find.byType(InteractiveViewer), const Offset(80, 60));
      await tester.pump();
      expect(controller.camera.value, initial);
      await tester.tap(find.byTooltip('Zoom +'));
      await tester.pump();
      final zoomed = controller.camera.value.clone();
      expect(
        zoomed.getMaxScaleOnAxis(),
        greaterThan(initial.getMaxScaleOnAxis()),
      );
      await tester.drag(find.byType(InteractiveViewer), const Offset(80, 60));
      await tester.pump();
      expect(controller.camera.value, isNot(zoomed));
      await tester.tap(find.byTooltip('Vue du parc'));
      await tester.pump();
      expect(controller.camera.value, initial);
      await tester.tap(find.byTooltip('Zoom +'));
      await tester.pump();
      await tester.tap(find.byTooltip('Zoom −'));
      await tester.pump();
      expect(controller.camera.value, initial);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('foliage covers the area above a lowered scene', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundary,
          child: const ParkSceneBackdrop(
            imageRect: Rect.fromLTWH(0, 100, 800, 450),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
    final pixels = await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    // The source's upper foliage contains green pixels; the fallback earth
    // is orange. Sample the actual top edge to catch a gap above the scene.
    var greenPixels = 0;
    for (var x = 0; x < 800; x++) {
      final i = x * 4;
      if (pixels![i + 1] > pixels[i] + 10) greenPixels++;
    }
    expect(greenPixels, greaterThan(20));
  });
}
