import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/artwork.dart';
import 'package:papatte_parc/shared/game_stage_layout.dart';

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
          width: 192,
          height: 192,
        ),
        context,
      );
    }
    for (final path in paths) {
      await precacheArtwork(ArtworkResolver.provider(path), context);
    }
  });
  await tester.pumpAndSettle();
}
