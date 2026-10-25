import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/app_theme.dart';
import 'package:papatte_parc/shared/campaign_level_select_screen.dart';
import 'package:papatte_parc/shared/campaign_selection_controller.dart';
import 'package:papatte_parc/shared/game_help.dart';

void main() {
  testWidgets(
    'the list selects before play and a completed campaign shows 100%',
    (tester) async {
      CampaignSelectionController.clearSessions();
      addTearDown(CampaignSelectionController.clearSessions);
      int? played;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: CampaignLevelSelectScreen(
            title: 'Campagne',
            tagline: 'Parcours',
            icon: Icons.pets,
            helpKind: GameHelpKind.sudoku,
            keyPrefix: 'contract',
            itemCount: 45,
            unlockedLevel: 45,
            completedCount: 45,
            progressLabel: 'Terminés',
            missionBuilder: (index) => CampaignMission(
              title: 'Mission ${index + 1}',
              subtitle: 'Animaux',
              artAsset: 'assets/park_map.png',
              stats: const [],
              completed: true,
            ),
            labelBuilder: (index) => 'Mission ${index + 1}',
            musicEnabled: false,
            effectsEnabled: false,
            onBack: () {},
            onPlay: (index) => played = index,
            onCustom: () {},
            onToggleMusic: () {},
            onToggleEffects: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('100 %'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1,
      );
      await tester.tap(find.byKey(const Key('contract-level-list')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contract-list-level-1')));
      await tester.pumpAndSettle();
      expect(played, isNull);
      expect(find.text('Mission 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('campaign-play-selected')));
      expect(played, 0);
      await tester.tap(find.byKey(const Key('campaign-continue')));
      expect(played, 44);

      final controller = CampaignSelectionController.forGame('contract', 45);
      final camera = controller.camera.value.clone();
      expect(
        identical(
          controller,
          CampaignSelectionController.forGame('contract', 45),
        ),
        isTrue,
      );
      expect(controller.selectedIndex, 0);
      expect(controller.camera.value, camera);
      expect(
        CampaignSelectionController.forGame('another-game', 1).selectedIndex,
        0,
      );
      final advancing = CampaignSelectionController.forGame('advancing', 22);
      advancing.select(3);
      expect(
        CampaignSelectionController.forGame('advancing', 23).selectedIndex,
        22,
      );
      expect(advancing.focusRequested, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
