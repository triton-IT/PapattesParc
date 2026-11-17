import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/campaign_level_select_screen.dart';
import 'package:papatte_parc/shared/campaign_selection_controller.dart';
import 'package:papatte_parc/shared/clay_text.dart';
import 'package:papatte_parc/shared/game_help.dart';
import 'package:papatte_parc/shared/park_journey_map.dart';

void main() {
  testWidgets('clay campaign list, details and settings remain interactive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    CampaignSelectionController.clearSessions();
    addTearDown(CampaignSelectionController.clearSessions);
    var musicToggles = 0;
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: CampaignLevelSelectScreen(
          title: 'BALISES DU REFUGE',

          helpKind: GameHelpKind.refuge,
          keyPrefix: 'clay-contract',
          itemCount: 3,
          unlockedLevel: 2,

          missionBuilder: (_) => const CampaignMission(
            title: 'Plaine sud-américaine',
            subtitle:
                'Tapirs terrestres · Coendous · Capybaras · Fourmiliers géants',
            artAsset: 'assets/optimized/sudoku/south-american-plain-scene.webp',
            stats: [CampaignMissionStat(Icons.pets, '26', 'animaux')],
          ),
          labelBuilder: (index) => 'Niveau ${index + 1}',
          musicEnabled: false,
          effectsEnabled: true,
          onBack: () {},
          onPlay: (_) {},
          onCustom: () {},
          onToggleMusic: () => musicToggles++,
          onToggleEffects: () {},
          onSelectionChanged: (index) => selected = index,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final panel = find.byKey(const Key('campaign-mission-panel'));
    for (final tooltip in [
      'Zoom +',
      'Zoom −',
      'Recentrer',
      'Vue du parc',
      'Liste des niveaux',
    ]) {
      expect(
        find.descendant(of: panel, matching: find.byTooltip(tooltip)),
        findsOneWidget,
      );
    }
    final controller = CampaignSelectionController.forGame('clay-contract', 2);
    final initialScale = controller.camera.value.getMaxScaleOnAxis();
    await tester.tap(find.byTooltip('Zoom +'));
    await tester.pumpAndSettle();
    expect(
      controller.camera.value.getMaxScaleOnAxis(),
      greaterThan(initialScale),
    );
    await tester.tap(find.byTooltip('Vue du parc'));
    await tester.pumpAndSettle();
    expect(
      controller.camera.value.getMaxScaleOnAxis(),
      closeTo(initialScale, .0001),
    );
    Finder clay(String value) =>
        find.byWidgetPredicate((w) => w is ClayText && w.text == value);
    await tester.tap(clay('Détails et record'));
    await tester.pumpAndSettle();
    expect(find.byType(ClayParagraph), findsWidgets);
    await tester.tap(find.byTooltip('Réglages'));
    await tester.pumpAndSettle();
    expect(clay('Musique'), findsOneWidget);
    await tester.tap(clay('Musique'));
    await tester.pumpAndSettle();
    expect(musicToggles, 1);
    await tester.tap(find.byKey(const Key('clay-contract-level-list')));
    await tester.pumpAndSettle();
    expect(clay('Niveaux du parc'), findsOneWidget);
    expect(clay('1 · Niveau 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('clay-contract-list-level-1')));
    await tester.pumpAndSettle();
    expect(selected, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('la barre modelée permet de parcourir les niveaux', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    CampaignSelectionController.clearSessions();
    addTearDown(CampaignSelectionController.clearSessions);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParkJourneyMap(
            itemCount: 45,
            unlockedLevel: 45,
            keyPrefix: 'clay-scroll',
            labelBuilder: (i) => 'Niveau ${i + 1}',
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Liste des niveaux'));
    await tester.pumpAndSettle();
    final bar = find.byKey(const Key('clay-level-scrollbar'));
    expect(bar, findsOneWidget);
    expect(find.byKey(const Key('clay-scroll-list-level-45')), findsNothing);
    await tester.drag(bar, const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clay-scroll-list-level-45')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('long clay details wrap with enlarged text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              child: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(2)),
                child: ClayParagraph(
                  'Tapirs terrestres · Coendous · Capybaras · Fourmiliers géants',
                  style: TextStyle(fontSize: 16, color: Color(0xff315a3c)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
