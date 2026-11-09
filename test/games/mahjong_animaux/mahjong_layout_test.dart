import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/mahjong_session.dart';
import 'package:papatte_parc/games/mahjong_animaux/presentation/mahjong_screen.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';

void main() {
  testWidgets('le décor et les commandes du mahjong restent utilisables', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1672, 941));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final campaign = buildMahjongCampaign(levels);
    for (final index in [0, 1, 17, 30, 44]) {
      final level = campaign[index];
      final session = MahjongSession(
        layout: level.layout,
        biome: level.stage.biome,
        seed: 41,
      );
      int? selected;
      var hints = 0, shuffles = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MahjongScreen(
            session: session,
            title: 'Niveau ${level.number}',
            backgroundAsset: level.stage.artAsset!,
            levelNumber: level.number,
            isFreeGame: false,
            hintedIds: const {},
            finished: false,
            newRecord: false,
            onSelect: (id) => selected = id,
            onBlocked: () {},
            onHint: () => hints++,
            onShuffle: () => shuffles++,
            onBack: () {},
            onReplaySame: () {},
            onReplayNew: () {},
            onLevels: () {},
            onConfigure: null,
            onNext: null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scene = tester.widget<Image>(
        find.byKey(const Key('mahjong-scene-background')),
      );
      expect(
        (scene.image as AssetImage).assetName,
        index == 0
            ? 'assets/optimized/sudoku/integrated-scene.webp'
            : index == 1
            ? 'assets/optimized/sudoku/lions-scene.webp'
            : index == 17
            ? 'assets/optimized/sudoku/tiger-river-scene-v2.webp'
            : index == 30
            ? 'assets/optimized/sudoku/urials-turs-caucasus-scene.webp'
            : 'assets/optimized/sudoku/alpaca-highland-meadow-scene.webp',
      );
      final freeTile = session.tiles.firstWhere((tile) => tile.isFree);
      await tester.tap(find.byKey(Key('mahjong-tile-${freeTile.tile.id}')));
      expect(selected, freeTile.tile.id);
      await tester.tap(find.byKey(const Key('mahjong-hint')));
      await tester.tap(find.byKey(const Key('mahjong-shuffle')));
      expect(hints, 1);
      expect(shuffles, 1);
      expect(
        tester.getCenter(find.byTooltip('Agrandir le plateau')).dx,
        closeTo(1084, 1),
      );
      await tester.tap(find.byTooltip('Agrandir le plateau'));
      await tester.pump();
      await tester.tap(find.byTooltip('Recentrer le plateau'));
      expect(tester.takeException(), isNull);
    }
  });
}
