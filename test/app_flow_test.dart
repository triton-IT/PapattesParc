import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/data/progress_store.dart';
import 'package:papatte_parc/domain/board_generator.dart';
import 'package:papatte_parc/domain/game_session.dart';
import 'package:papatte_parc/domain/levels.dart';
import 'package:papatte_parc/domain/models.dart';
import 'package:papatte_parc/presentation/app_theme.dart';
import 'package:papatte_parc/presentation/game_app.dart';
import 'package:papatte_parc/presentation/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('le bouton quitter est réservé à Windows', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await _pumpApp(tester, store, const Size(1366, 768));
    expect(find.byKey(const Key('quit-app')), findsOneWidget);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await _pumpApp(tester, store, const Size(1366, 768));
    expect(find.byKey(const Key('quit-app')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('le parcours ouvre la première mission', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await _pumpApp(tester, store, const Size(1366, 768));

    expect(find.text('PAPATTE PARC'), findsOneWidget);
    expect(find.text('Terrier des sentinelles'), findsOneWidget);
    await tester.tap(find.byKey(const Key('start-mission')));
    await tester.pump();

    expect(find.textContaining('Niveau 1 · Terrier'), findsOneWidget);
    expect(find.byKey(const Key('cell-0-0')), findsOneWidget);
    expect(find.textContaining('À localiser : 5'), findsOneWidget);
  });

  testWidgets('l’accueil remplit les quatre formats de référence', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    for (final size in _referenceSizes) {
      await _pumpApp(tester, store, size);
      expect(tester.getSize(find.byType(Scaffold)), size);
      expect(tester.takeException(), isNull, reason: '$size');
      expect(find.byKey(const Key('start-mission')), findsOneWidget);
    }
  });

  testWidgets('la première observation prépare puis affiche le refuge', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await _pumpApp(tester, store, const Size(800, 1280));
    await tester.tap(find.byKey(const Key('start-mission')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cell-3-3')));
    await tester.pump();

    expect(find.byKey(const Key('generation-overlay')), findsOneWidget);
    for (
      var attempt = 0;
      attempt < 100 &&
          find.byKey(const Key('generation-overlay')).evaluate().isNotEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(find.byKey(const Key('generation-overlay')), findsNothing);
    expect(find.byKey(const Key('cell-3-3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'les limites du parcours et les missions verrouillées sont claires',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();
      await _pumpApp(tester, store, const Size(1366, 768));

      await tester.tap(find.byKey(const Key('level-marker-4')));
      await tester.pump();

      expect(find.text('Serre de Madagascar'), findsOneWidget);
      expect(find.byKey(const Key('selected-level-art')), findsOneWidget);
      expect(
        find.text('Termine la mission précédente pour continuer.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('start-selected-mission')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('le dernier niveau débloqué est sélectionné au lancement', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'journey:unlockedLevel': 45});
    final store = await ProgressStore.load();
    await _pumpApp(tester, store, const Size(800, 1280));

    expect(find.text('Prairie des alpagas'), findsOneWidget);
    expect(find.byKey(const Key('level-art')), findsOneWidget);
  });

  testWidgets('le choix de musique est mémorisé', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await _pumpApp(tester, store, const Size(800, 1280));

    await tester.tap(find.byKey(const Key('toggle-music')));
    await tester.pump();

    expect(store.musicEnabled, isFalse);
    expect(find.byIcon(Icons.music_off_rounded), findsOneWidget);
  });

  testWidgets('le plateau accepte appui long, clic droit et clavier', (
    tester,
  ) async {
    final level = levels.first;
    final board = generateCertifiedBoard(
      level.config,
      const CellPosition(3, 3),
      19,
    )!;
    final session = GameSession(level.config)..prepare(board, practice: false);
    final animals = _animalPositions(board);

    await _pumpBoard(tester, level, session);
    await tester.longPress(_cell(animals[0]));
    await tester.pump();
    expect(find.byKey(const Key('flagged-animal-image')), findsOneWidget);

    await tester.tap(
      _cell(animals[1]),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(find.byKey(const Key('flagged-animal-image')), findsNWidgets(2));

    final gesture = await tester.startGesture(
      tester.getCenter(_cell(animals[2])),
    );
    await gesture.moveBy(const Offset(20, 0));
    await gesture.up();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(find.byKey(const Key('flagged-animal-image')), findsNWidgets(3));
  });

  testWidgets('les résultats réussite et échec gardent leurs actions', (
    tester,
  ) async {
    final level = levels.first;
    final wonSession = _wonSession(level);
    var nextPressed = false;
    await _pumpGame(
      tester,
      level,
      wonSession,
      const Size(1366, 768),
      onNext: () => nextPressed = true,
    );
    expect(find.byKey(const Key('end-overlay')), findsOneWidget);
    expect(find.text('REFUGE SÉCURISÉ !'), findsOneWidget);
    await tester.tap(find.text('Niveau suivant'));
    expect(nextPressed, isTrue);

    final lostSession = _lostSession(level);
    var replayPressed = false;
    await _pumpGame(
      tester,
      level,
      lostSession,
      const Size(360, 800),
      onReplaySame: () => replayPressed = true,
    );
    expect(find.text('UN ANIMAL S’EST ÉLOIGNÉ'), findsOneWidget);
    await tester.ensureVisible(find.text('Revoir cette grille'));
    await tester.tap(find.text('Revoir cette grille'));
    expect(replayPressed, isTrue);
    expect(tester.takeException(), isNull);
  });
}

const _referenceSizes = [
  Size(360, 800),
  Size(800, 1280),
  Size(1366, 768),
  Size(1920, 1080),
];

Future<void> _pumpApp(
  WidgetTester tester,
  ProgressStore store,
  Size size,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PapatteParcApp(store: store));
  await tester.pump();
}

Future<void> _pumpBoard(
  WidgetTester tester,
  LevelDefinition level,
  GameSession session,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => BoardView(
            level: level,
            session: session,
            onReveal: (position) => setState(() => session.reveal(position)),
            onFlag: (position) => setState(() => session.toggleFlag(position)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpGame(
  WidgetTester tester,
  LevelDefinition level,
  GameSession session,
  Size size, {
  VoidCallback? onReplaySame,
  VoidCallback? onNext,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: GameScreen(
        level: level,
        session: session,
        generating: false,
        finished: true,
        newRecord: false,
        onHome: () {},
        onReveal: (_) {},
        onFlag: (_) {},
        onReplaySame: onReplaySame ?? () {},
        onReplayNew: () {},
        onNext: onNext ?? () {},
      ),
    ),
  );
  await tester.pump();
}

Finder _cell(CellPosition position) =>
    find.byKey(Key('cell-${position.x}-${position.y}'));

List<CellPosition> _animalPositions(GeneratedBoard board) => [
  for (var y = 0; y < board.config.height; y++)
    for (var x = 0; x < board.config.width; x++)
      if (board.isAnimal(CellPosition(x, y))) CellPosition(x, y),
];

GameSession _wonSession(LevelDefinition level) {
  final board = generateCertifiedBoard(
    level.config,
    const CellPosition(3, 3),
    41,
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

GameSession _lostSession(LevelDefinition level) {
  final board = generateCertifiedBoard(
    level.config,
    const CellPosition(3, 3),
    47,
  )!;
  final session = GameSession(level.config)..prepare(board, practice: false);
  session.reveal(_animalPositions(board).first);
  return session;
}
