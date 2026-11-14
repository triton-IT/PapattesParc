import '../support/visible_artwork.dart';
import 'package:papatte_parc/shared/artwork.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/familles_du_parc/domain/animal_sort_session.dart';
import 'package:papatte_parc/games/familles_du_parc/domain/campaign.dart';
import 'package:papatte_parc/games/familles_du_parc/domain/models.dart';
import 'package:papatte_parc/games/familles_du_parc/domain/sort_food.dart';
import 'package:papatte_parc/games/familles_du_parc/presentation/animal_sort_screen.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/shared/app_theme.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('chaque repas possède son illustration', (tester) async {
    for (final animal in SortFood.values) {
      final path = animal.asset;
      expect(
        (await rootBundle.load(path)).lengthInBytes,
        greaterThan(0),
        reason: animal.name,
      );
    }
  });

  testWidgets('références visuelles des réserves du parc', (tester) async {
    final level = buildAnimalSortCampaign(levels)[1];
    final session = AnimalSortSession(level);
    for (final size in _sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: AnimalSortScreen(
            session: session,
            selectedZone: 1,
            hintMove: null,
            finished: false,
            newRecord: false,
            freeGame: false,
            onTapZone: (_) {},
            onUndo: () {},
            onHint: () {},
            onBack: () {},
            onRestart: () {},
            onReplay: () {},
            onLevels: () {},
            onNext: () {},
            onNewGame: null,
            onConfigure: null,
          ),
        ),
      );
      await tester.runAsync(
        () => Future.wait([
          precacheArtwork(
            ArtworkResolver.provider(level.stage.artAsset!),
            tester.element(find.byType(MaterialApp)),
          ),
          for (final animal in level.foods)
            precacheArtwork(
              ArtworkResolver.provider(animal.asset),
              tester.element(find.byType(MaterialApp)),
            ),
        ]),
      );
      await tester.pumpAndSettle();
      await loadVisibleArtwork(tester);
      expect(tester.takeException(), isNull, reason: '$size');
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/animal-sort-mission-${_name(size)}.png'),
      );
    }
  }, skip: !Platform.isWindows);

  testWidgets('la scène permet de choisir un panier et de zoomer', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(tester.view.reset);
    final session = AnimalSortSession(buildAnimalSortCampaign(levels).first);
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AnimalSortScreen(
          session: session,
          selectedZone: null,
          hintMove: null,
          finished: false,
          newRecord: false,
          freeGame: false,
          onTapZone: (index) => selected = index,
          onUndo: () {},
          onHint: () {},
          onBack: () {},
          onRestart: () {},
          onReplay: () {},
          onLevels: () {},
          onNext: () {},
          onNewGame: null,
          onConfigure: null,
        ),
      ),
    );
    expect(
      find.byKey(const Key('animal-sort-scene-background')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('animal-sort-zone-0')));
    expect(selected, 0);
    final viewer = tester.widget<InteractiveViewer>(
      find.byKey(const Key('animal-sort-camera')),
    );
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
    await tester.tap(find.byTooltip('Agrandir le plateau'));
    await tester.pump();
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );
    await tester.tap(find.byTooltip('Recentrer le plateau'));
    await tester.pump();
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
  });

  testWidgets('les portions restantes descendent après un déplacement', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(tester.view.reset);
    final session = AnimalSortSession(
      AnimalSortLevelDefinition(
        stage: levels.first,
        foods: const [SortFood.beef, SortFood.acaciaLeaves],
        initialZones: const [
          [SortFood.beef, SortFood.acaciaLeaves],
          [],
          [],
        ],
        referenceSolution: const [AnimalSortMove(0, 1)],
      ),
    );
    Widget screen() => MaterialApp(
      theme: buildAppTheme(),
      home: AnimalSortScreen(
        session: session,
        selectedZone: null,
        hintMove: null,
        finished: false,
        newRecord: false,
        freeGame: false,
        onTapZone: (_) {},
        onUndo: () {},
        onHint: () {},
        onBack: () {},
        onRestart: () {},
        onReplay: () {},
        onLevels: () {},
        onNext: () {},
        onNewGame: null,
        onConfigure: null,
      ),
    );
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    final food = find.descendant(
      of: find.byKey(const Key('animal-sort-zone-0')),
      matching: find.byKey(const ValueKey('food-0')),
    );
    final before = tester.getTopLeft(food).dy;
    expect(session.move(0, 1), AnimalSortMoveResult.moved);
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(food).dy, greaterThan(before));
    expect(find.text('Prends la portion du dessus'), findsNothing);
  });

  testWidgets('les dix paniers restent dans le plateau', (tester) async {
    final level = buildAnimalSortCampaign(levels).last;
    final session = AnimalSortSession(level);
    for (final size in const [Size(360, 800), Size(1366, 768)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: AnimalSortScreen(
            session: session,
            selectedZone: null,
            hintMove: null,
            finished: false,
            newRecord: false,
            freeGame: false,
            onTapZone: (_) {},
            onUndo: () {},
            onHint: () {},
            onBack: () {},
            onRestart: () {},
            onReplay: () {},
            onLevels: () {},
            onNext: () {},
            onNewGame: null,
            onConfigure: null,
          ),
        ),
      );
      await tester.runAsync(
        () => Future.wait([
          precacheArtwork(
            ArtworkResolver.provider(level.stage.artAsset!),
            tester.element(find.byType(MaterialApp)),
          ),
          for (final animal in level.foods)
            precacheArtwork(
              ArtworkResolver.provider(animal.asset),
              tester.element(find.byType(MaterialApp)),
            ),
        ]),
      );
      await tester.pumpAndSettle();
      final board = tester.getRect(find.byKey(const Key('animal-sort-board')));
      for (var index = 0; index < session.zones.length; index++) {
        final basket = tester.getRect(
          find.byKey(Key('animal-sort-zone-$index')),
        );
        expect(
          board.contains(basket.topLeft),
          isTrue,
          reason: '$size panier $index',
        );
        expect(
          board.contains(basket.bottomRight),
          isTrue,
          reason: '$size panier $index',
        );
      }
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/animal-sort-max-${_name(size)}.png'),
      );
    }
  }, skip: !Platform.isWindows);
}

const _sizes = [
  Size(800, 360),
  Size(360, 800),
  Size(800, 1280),
  Size(1366, 768),
  Size(1920, 1080),
];

String _name(Size size) => '${size.width.toInt()}x${size.height.toInt()}';
