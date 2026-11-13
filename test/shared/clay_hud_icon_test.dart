import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/clay_hud_icon.dart';

void main() {
  testWidgets('les symboles du panneau utilisent le même atlas', (
    tester,
  ) async {
    const symbols = [
      Icons.undo_rounded,
      Icons.lightbulb_rounded,
      Icons.refresh_rounded,
      Icons.pets_rounded,
      Icons.zoom_in,
      Icons.zoom_out,
      Icons.pan_tool_outlined,
      Icons.center_focus_strong,
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: IconTheme(
          data: const IconThemeData(color: Color(0xff245b4a), size: 32),
          child: Row(children: [for (final icon in symbols) ClaySymbol(icon)]),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    expect(find.byType(ClayHudIcon), findsNWidgets(symbols.length));
    expect(
      find.descendant(
        of: find.byType(ClayHudIcon),
        matching: find.byType(CustomPaint),
      ),
      findsNWidgets(symbols.length),
    );
    expect(tester.takeException(), isNull);
  });
}
