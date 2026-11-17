import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/campaign_level_select_screen.dart';
import 'package:papatte_parc/shared/campaign_selection_controller.dart';
import 'package:papatte_parc/shared/game_help.dart';
import 'package:papatte_parc/shared/park_journey_map.dart';

void main() {
  testWidgets('le fond reste visible au retour du jeu avec la caméra conservée', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    CampaignSelectionController.clearSessions();
    addTearDown(CampaignSelectionController.clearSessions);
    final playing = ValueNotifier(false);
    addTearDown(playing.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: playing,
          builder: (context, inGame, _) => inGame
              ? TextButton(
                  onPressed: () => playing.value = false,
                  child: const Text('Retour du jeu'),
                )
              : CampaignLevelSelectScreen(
                  title: 'BALISES DU REFUGE',

                  helpKind: GameHelpKind.refuge,
                  keyPrefix: 'backdrop-return',
                  itemCount: 1,
                  unlockedLevel: 1,

                  missionBuilder: (_) => const CampaignMission(
                    title: 'Mission',
                    subtitle: 'Animaux',
                    artAsset:
                        'assets/optimized/sudoku/south-american-plain-scene.webp',
                    stats: [],
                  ),
                  labelBuilder: (_) => 'Mission',
                  musicEnabled: false,
                  effectsEnabled: true,
                  onBack: () {},
                  onPlay: (_) => playing.value = true,
                  onCustom: () {},
                  onToggleMusic: () {},
                  onToggleEffects: () {},
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ParkSceneBackdrop), findsOneWidget);
    await tester.tap(find.byKey(const Key('campaign-play-selected')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retour du jeu'));
    await tester.pumpAndSettle();
    expect(find.byType(ParkSceneBackdrop), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(ParkSceneBackdrop),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Zoom +'));
    await tester.pumpAndSettle();
    final camera = CampaignSelectionController.forGame(
      'backdrop-return',
      1,
    ).camera.value.clone();
    await tester.tap(find.byKey(const Key('campaign-play-selected')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retour du jeu'));
    await tester.pumpAndSettle();
    expect(find.byType(ParkSceneBackdrop), findsOneWidget);
    expect(
      CampaignSelectionController.forGame('backdrop-return', 1).camera.value,
      camera,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
