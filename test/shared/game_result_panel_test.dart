import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/game_stage_layout.dart';
import 'package:papatte_parc/shared/park_catalog.dart';

void main() {
  testWidgets('result actions remain accessible on a short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameResultViewport(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GameResultPanel(
                biome: LevelBiome.tropical,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restaurant, size: 54),
                      const SizedBox(height: 10),
                      const Text(
                        'REPAS DISTRIBUÉ !',
                        style: TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '7 poussées · 3 empreintes\nNouveau record !',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('NIVEAU SUIVANT'),
                      ),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('REJOUER'),
                      ),
                      TextButton(
                        onPressed: () => pressed = true,
                        child: const Text('CHOISIR UN NIVEAU'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final action = find.text('CHOISIR UN NIVEAU');
    await tester.ensureVisible(action);
    await tester.tap(action);
    expect(pressed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmation preserves both decisions on a short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bool? decision;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                decision = await showDialog<bool>(
                  context: context,
                  builder: (context) => GameConfirmDialog(
                    biome: LevelBiome.riverside,
                    title: const Text('Abandonner ce niveau ?'),
                    content: const Text(
                      'La progression de cette partie sera perdue.',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Continuer'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Quitter'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    for (final label in ['Continuer', 'Quitter']) {
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.byType(GameConfirmDialog), findsOneWidget);
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(decision, label == 'Quitter');
      expect(tester.takeException(), isNull);
    }
  });
}
