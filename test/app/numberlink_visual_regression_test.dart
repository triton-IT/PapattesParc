import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/sentiers_sauvages/data/numberlink_progress_store.dart';
import 'package:papatte_parc/games/sentiers_sauvages/domain/campaign.dart';
import 'package:papatte_parc/games/sentiers_sauvages/domain/models.dart';
import 'package:papatte_parc/games/sentiers_sauvages/domain/numberlink_session.dart';
import 'package:papatte_parc/games/sentiers_sauvages/presentation/custom_game_screen.dart';
import 'package:papatte_parc/games/sentiers_sauvages/presentation/level_select_screen.dart';
import 'package:papatte_parc/games/sentiers_sauvages/presentation/numberlink_screen.dart';
import 'package:papatte_parc/shared/animal_catalog.dart';
import 'package:papatte_parc/shared/app_theme.dart';
import 'package:papatte_parc/shared/park_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('références visuelles des sentiers sauvages', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await NumberlinkProgressStore.load();
    final campaign = buildNumberlinkCampaign(levels);
    final level = campaign[30];
    final assets = {
      'assets/park_map.png',
      'assets/sokoban/fence-v2.png',
      levels.first.artAsset!,
      levels
          .firstWhere((stage) => stage.biome == LevelBiome.riverside)
          .artAsset!,
      level.stage.artAsset!,
      for (final pair in level.pairs) pair.animal.asset,
    };

    for (final size in _sizes) {
      await _pump(
        tester,
        size,
        NumberlinkLevelSelectScreen(
          levels: campaign,
          store: store,
          musicEnabled: true,
          effectsEnabled: true,
          onBack: () {},
          onPlay: (_) {},
          onCustom: () {},
          onToggleMusic: () {},
          onToggleEffects: () {},
          onQuit: () {},
        ),
        assets,
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/numberlink-levels-${_name(size)}.png'),
      );

      await _pump(
        tester,
        size,
        NumberlinkCustomGameScreen(
          stages: levels,
          initialConfig: const NumberlinkFreeGameConfig(
            size: 7,
            difficulty: NumberlinkDifficulty.medium,
            biome: LevelBiome.riverside,
          ),
          onBack: () {},
          onStart: (_) {},
        ),
        assets,
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/numberlink-custom-${_name(size)}.png'),
      );

      final playing = NumberlinkSession(level)..hint();
      _tracePrefix(playing, level.pairs.first.referencePath);
      await _pump(tester, size, _screen(playing, finished: false), assets);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/numberlink-mission-${_name(size)}.png'),
      );

      final finished = _finish(level);
      await _pump(tester, size, _screen(finished, finished: true), assets);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/numberlink-result-${_name(size)}.png'),
      );
    }
  }, skip: !Platform.isWindows);
}

const _sizes = [
  Size(360, 800),
  Size(800, 1280),
  Size(1366, 768),
  Size(1920, 1080),
];

Future<void> _pump(
  WidgetTester tester,
  Size size,
  Widget screen,
  Set<String> assets,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: screen));
  for (final asset in assets) {
    await tester.runAsync(
      () => precacheImage(
        AssetImage(asset),
        tester.element(find.byType(MaterialApp)),
      ),
    );
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: '$size');
}

void _tracePrefix(
  NumberlinkSession session,
  List<NumberlinkPosition> referencePath,
) {
  session.begin(referencePath.first);
  for (final position in referencePath.skip(1).take(4)) {
    session.trace(position);
  }
  session.endTrace();
}

NumberlinkSession _finish(NumberlinkLevelDefinition level) {
  final session = NumberlinkSession(level);
  for (final pair in level.pairs) {
    session.begin(pair.referencePath.first);
    for (final position in pair.referencePath.skip(1)) {
      session.trace(position);
    }
  }
  return session;
}

NumberlinkScreen _screen(NumberlinkSession session, {required bool finished}) =>
    NumberlinkScreen(
      session: session,
      finished: finished,
      newRecord: finished,
      isFreeGame: false,
      onBegin: session.begin,
      onTrace: session.trace,
      onEndTrace: session.endTrace,
      onHint: session.hint,
      onBack: () {},
      onRestart: () {},
      onReplay: () {},
      onLevels: () {},
      onNext: () {},
    );

String _name(Size size) => '${size.width.toInt()}x${size.height.toInt()}';
