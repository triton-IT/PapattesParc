import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/artwork.dart';

/// Goldens describe the loaded screen rather than image decoding races.
Future<void> loadVisibleArtwork(WidgetTester tester) async {
  final paths = tester
      .widgetList<ArtworkImage>(find.byType(ArtworkImage))
      .map((widget) => widget.asset)
      .toSet();
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final path in paths) {
      await precacheArtwork(ArtworkResolver.provider(path), context);
    }
  });
  await tester.pumpAndSettle();
}
