import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/artwork.dart';
import 'package:papatte_parc/shared/game_stage_layout.dart';
import 'package:papatte_parc/shared/wooden_sign.dart';

/// Goldens describe the loaded screen rather than image decoding races.
Future<void> loadVisibleArtwork(WidgetTester tester) async {
  final paths = tester
      .widgetList<ArtworkImage>(find.byType(ArtworkImage))
      .map((widget) => widget.asset)
      .toSet();
  final context = tester.element(find.byType(MaterialApp));
  final hasResultPanel = find.byType(GameResultPanel).evaluate().isNotEmpty;
  await tester.runAsync(() async {
    if (hasResultPanel) {
      await precacheArtwork(
        const ResizeImage(
          AssetImage('assets/optimized/sudoku/parchment-panel.webp'),
          width: 384,
          height: 384,
        ),
        context,
      );
    }
    for (final sign in find.byType(WoodenSign).evaluate()) {
      final backgrounds = find.descendant(
        of: find.byWidget(sign.widget),
        matching: find.byType(DecoratedBox),
      );
      if (backgrounds.evaluate().isNotEmpty) {
        final background = tester.widget<DecoratedBox>(backgrounds.first);
        final decoration = background.decoration;
        if (decoration is BoxDecoration && decoration.image != null) {
          await precacheArtwork(decoration.image!.image, context);
        }
      }
    }
    for (final path in paths) {
      await precacheArtwork(ArtworkResolver.provider(path), context);
    }
  });
  await tester.pumpAndSettle();
}
