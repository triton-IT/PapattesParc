import '../support/visible_artwork.dart';
import 'package:papatte_parc/shared/artwork.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/familles_du_parc/domain/animal_sort_session.dart';
import 'package:papatte_parc/games/familles_du_parc/domain/campaign.dart';
import 'package:papatte_parc/games/familles_du_parc/presentation/animal_sort_screen.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/shared/animal_food.dart';
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

  testWidgets('références visuelles des réserves du parc', (tester) async {
    final level = buildAnimalSortCampaign(levels).first;
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
          for (final asset in const [
            'assets/food_sort/ui/basket.png',
            'assets/food_sort/ui/cart-landscape.png',
            'assets/food_sort/ui/cart-portrait.png',
          ])
            precacheArtwork(
              ArtworkResolver.provider(asset),
              tester.element(find.byType(MaterialApp)),
            ),
          for (final animal in level.animals)
            precacheArtwork(
              ArtworkResolver.provider(animal.foodAsset),
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

  testWidgets('les dix paniers restent sur le chariot', (tester) async {
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
          for (final asset in const [
            'assets/food_sort/ui/basket.png',
            'assets/food_sort/ui/cart-landscape.png',
            'assets/food_sort/ui/cart-portrait.png',
          ])
            precacheArtwork(
              ArtworkResolver.provider(asset),
              tester.element(find.byType(MaterialApp)),
            ),
          for (final animal in level.animals)
            precacheArtwork(
              ArtworkResolver.provider(animal.foodAsset),
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
