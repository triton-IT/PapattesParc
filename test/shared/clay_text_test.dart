import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/clay_text.dart';
import 'package:papatte_parc/shared/park_stages.dart';

void main() {
  testWidgets('les lettres étroites ne réservent pas un espace vide', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 48);
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            ClayText('li', key: ValueKey('li'), style: style),
            ClayText('ii', key: ValueKey('ii'), style: style),
          ],
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('li')),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    final li = tester.getSize(find.byKey(const ValueKey('li'))).width;
    final ii = tester.getSize(find.byKey(const ValueKey('ii'))).width;
    expect((li - ii).abs(), lessThan(2));
  });

  testWidgets('le texte reste accessible et suit les changements du chrono', (
    tester,
  ) async {
    Widget subject(String value) => MaterialApp(
      home: Center(
        child: ClayText(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 29),
        ),
      ),
    );

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(subject('00:59'));
    expect(find.bySemanticsLabel('00:59'), findsOneWidget);
    await tester.pumpWidget(subject('01:00'));
    expect(find.bySemanticsLabel('01:00'), findsOneWidget);
    expect(find.bySemanticsLabel('00:59'), findsNothing);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(ClayText),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('un caractère absent reste lisible grâce au texte de secours', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClayText(
          'Niveau spécial 🐾',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    expect(find.text('Niveau spécial 🐾'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('les noms de tous les décors utilisent les lettres illustrées', (
    tester,
  ) async {
    for (final title in [
      ...parkStages.map((stage) => stage.title),
      'RÉSERVES DU PARC',
      'À localiser : 12',
      '3/12 · 4 poussées',
      '15 déplacements',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: ClayText(title, style: const TextStyle(fontSize: 24)),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(ClayText),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
        reason: title,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
