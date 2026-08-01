import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/mahjong_animaux/data/mahjong_progress_store.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/mahjong_session.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/models.dart';
import 'package:papatte_parc/games/mahjong_animaux/presentation/custom_game_screen.dart';
import 'package:papatte_parc/games/mahjong_animaux/presentation/level_select_screen.dart';
import 'package:papatte_parc/games/mahjong_animaux/presentation/mahjong_screen.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/shared/app_theme.dart';
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

  testWidgets('références visuelles du mahjong', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await MahjongProgressStore.load();
    final campaign = buildMahjongCampaign(levels);
    for (final size in _sizes) {
      await _pump(
        tester,
        size,
        MahjongLevelSelectScreen(
          levels: campaign,
          store: store,
          musicEnabled: true,
          effectsEnabled: true,
          onBack: () {},
          onPlay: (_) {},
          onCustom: () {},
          onToggleMusic: () {},
          onToggleEffects: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/mahjong-levels-${_name(size)}.png'),
      );

      await _pump(
        tester,
        size,
        MahjongCustomGameScreen(onBack: () {}, onStart: (_) {}),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/mahjong-custom-${_name(size)}.png'),
      );

      final layeredLevel = campaign[17];
      final session = MahjongSession(
        layout: layeredLevel.layout,
        biome: layeredLevel.stage.biome,
        seed: 41,
      );
      await _pump(
        tester,
        size,
        _screen(
          session,
          title: 'Niveau 18 · ${layeredLevel.layout.name}',
          finished: false,
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/mahjong-mission-${_name(size)}.png'),
      );

      _finish(session);
      await _pump(
        tester,
        size,
        _screen(
          session,
          title: 'Niveau 18 · ${layeredLevel.layout.name}',
          finished: true,
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/mahjong-result-${_name(size)}.png'),
      );
    }
  });
}

const _sizes = [
  Size(360, 800),
  Size(800, 1280),
  Size(1366, 768),
  Size(1920, 1080),
];

Future<void> _pump(WidgetTester tester, Size size, Widget screen) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: screen));
  for (final asset in [
    'assets/level_art/level-01-suricates-porcs-epics.png',
    'assets/match3/animals/suricate.png',
    'assets/match3/animals/lion.png',
    'assets/match3/animals/girafe.png',
    'assets/match3/animals/zebre.png',
  ]) {
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

void _finish(MahjongSession session) {
  while (session.status == MahjongStatus.playing) {
    final pair = session.hint()!;
    session.select(pair.first);
    session.select(pair.second);
  }
}

MahjongScreen _screen(
  MahjongSession session, {
  required String title,
  required bool finished,
}) => MahjongScreen(
  session: session,
  title: title,
  isFreeGame: false,
  hintedIds: const {},
  finished: finished,
  newRecord: finished,
  onSelect: (_) {},
  onBlocked: () {},
  onHint: () {},
  onShuffle: () {},
  onBack: () {},
  onReplaySame: () {},
  onReplayNew: () {},
  onLevels: () {},
  onConfigure: null,
  onNext: () {},
);

String _name(Size size) => '${size.width.toInt()}x${size.height.toInt()}';
