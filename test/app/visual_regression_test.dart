import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/app/main_menu_screen.dart';
import 'package:papatte_parc/games/pattes_friandises/data/match3_progress_store.dart';
import 'package:papatte_parc/games/mahjong_animaux/data/mahjong_progress_store.dart';
import 'package:papatte_parc/games/pattes_friandises/domain/campaign.dart';
import 'package:papatte_parc/games/pattes_friandises/domain/match3_session.dart';
import 'package:papatte_parc/games/pattes_friandises/domain/models.dart';
import 'package:papatte_parc/games/pattes_friandises/presentation/level_select_screen.dart';
import 'package:papatte_parc/games/pattes_friandises/presentation/match3_screen.dart';
import 'package:papatte_parc/games/refuge/data/progress_store.dart';
import 'package:papatte_parc/games/refuge/domain/board_generator.dart';
import 'package:papatte_parc/games/refuge/domain/game_session.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/refuge/domain/models.dart';
import 'package:papatte_parc/games/refuge/presentation/custom_game_screen.dart';
import 'package:papatte_parc/games/refuge/presentation/game_screen.dart';
import 'package:papatte_parc/games/refuge/presentation/home_screen.dart';
import 'package:papatte_parc/games/solitaire_animaux/data/solitaire_progress_store.dart';
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

  testWidgets('références visuelles responsive', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final match3Store = await Match3ProgressStore.load();
    final mahjongStore = await MahjongProgressStore.load();
    final solitaireStore = await SolitaireProgressStore.load();
    final level = levels.first;
    final match3Levels = buildMatch3Campaign(levels);
    for (final size in _sizes) {
      await _pump(
        tester,
        size,
        MainMenuScreen(
          refugeStore: store,
          match3Store: match3Store,
          mahjongStore: mahjongStore,
          solitaireStore: solitaireStore,
          musicEnabled: true,
          effectsEnabled: true,
          onSelect: (_) {},
          onToggleMusic: () {},
          onToggleEffects: () {},
          onQuit: null,
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/menu-${_name(size)}.png'),
      );

      await _pump(
        tester,
        size,
        HomeScreen(
          levelIndex: 0,
          store: store,
          onSelectLevel: (_) {},
          onPlayLevel: (_) {},
          onCreateCustom: () {},
          musicEnabled: true,
          onToggleMusic: () {},
          effectsEnabled: true,
          onToggleEffects: () {},
          onButtonClick: () {},
          onGames: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/home-${_name(size)}.png'),
      );

      await _pump(
        tester,
        size,
        CustomGameScreen(onBack: () {}, onStart: (_) {}, onButtonClick: () {}),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/custom-${_name(size)}.png'),
      );

      final playing = _playingSession(level);
      await _pump(
        tester,
        size,
        GameScreen(
          level: level,
          session: playing,
          generating: false,
          finished: false,
          newRecord: false,
          onHome: () {},
          onReveal: (_) {},
          onFlag: (_) {},
          onReplaySame: () {},
          onReplayNew: () {},
          onNext: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/mission-${_name(size)}.png'),
      );

      final won = _wonSession(level);
      await _pump(
        tester,
        size,
        GameScreen(
          level: level,
          session: won,
          generating: false,
          finished: true,
          newRecord: true,
          onHome: () {},
          onReveal: (_) {},
          onFlag: (_) {},
          onReplaySame: () {},
          onReplayNew: () {},
          onNext: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/result-${_name(size)}.png'),
      );

      await _pump(
        tester,
        size,
        Match3LevelSelectScreen(
          levels: match3Levels,
          store: match3Store,
          musicEnabled: true,
          effectsEnabled: true,
          onBack: () {},
          onPlay: (_) {},
          onToggleMusic: () {},
          onToggleEffects: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/match3-levels-${_name(size)}.png'),
      );

      final match3Session = Match3Session(match3Levels.first, 37);
      await _pump(
        tester,
        size,
        Match3Screen(
          session: match3Session,
          selected: const Match3Position(3, 3),
          onSelect: (_) {},
          onSwap: (_, _) {},
          onLevels: () {},
          onRetry: () {},
          onNext: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/match3-mission-${_name(size)}.png'),
      );

      _finishMatch3(match3Session);
      await _pump(
        tester,
        size,
        Match3Screen(
          session: match3Session,
          selected: null,
          onSelect: (_) {},
          onSwap: (_, _) {},
          onLevels: () {},
          onRetry: () {},
          onNext: () {},
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/match3-result-${_name(size)}.png'),
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

Future<void> _pump(WidgetTester tester, Size size, Widget screen) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: screen));
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/level_art/level-01-suricates-porcs-epics.png'),
      tester.element(find.byType(MaterialApp)),
    ),
  );
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/park_map.png'),
      tester.element(find.byType(MaterialApp)),
    ),
  );
  for (final asset in [
    'assets/level_art/level-45-alpagas.png',
    'assets/mahjong/mahjong-cover.png',
    'assets/match3/animals/suricate.png',
    'assets/match3/animals/lion.png',
    'assets/match3/animals/girafe.png',
    'assets/match3/animals/zebre.png',
    'assets/match3/animals/guepard.png',
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

void _finishMatch3(Match3Session session) {
  for (
    var turn = 0;
    turn < 80 && session.status == Match3Status.playing;
    turn++
  ) {
    var moved = false;
    for (var y = 0; y < Match3Session.size && !moved; y++) {
      for (var x = 0; x < Match3Session.size && !moved; x++) {
        for (final target in [
          if (x + 1 < Match3Session.size) Match3Position(x + 1, y),
          if (y + 1 < Match3Session.size) Match3Position(x, y + 1),
        ]) {
          if (session.swap(Match3Position(x, y), target).changed) {
            moved = true;
            break;
          }
        }
      }
    }
  }
}

String _name(Size size) => '${size.width.toInt()}x${size.height.toInt()}';

GameSession _playingSession(LevelDefinition level) {
  final board = generateCertifiedBoard(
    level.config,
    const CellPosition(3, 3),
    71,
  )!;
  return GameSession(level.config)..prepare(board, practice: false);
}

GameSession _wonSession(LevelDefinition level) {
  final board = generateCertifiedBoard(
    level.config,
    const CellPosition(3, 3),
    73,
  )!;
  final session = GameSession(level.config)..prepare(board, practice: false);
  for (final step in board.certificate.skip(1)) {
    for (final target in step.targets) {
      if (step.kind == DeductionKind.flagAnimals ||
          step.kind == DeductionKind.flagRemainingAnimals) {
        session.toggleFlag(target);
      } else {
        session.reveal(target);
      }
    }
  }
  return session;
}
