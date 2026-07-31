import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/app/game_app.dart';
import 'package:papatte_parc/games/pattes_friandises/data/match3_progress_store.dart';
import 'package:papatte_parc/games/refuge/data/progress_store.dart';
import 'package:papatte_parc/games/refuge/domain/board_generator.dart';
import 'package:papatte_parc/games/refuge/domain/custom_game.dart';
import 'package:papatte_parc/games/refuge/domain/game_session.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/refuge/domain/models.dart';
import 'package:papatte_parc/games/refuge/presentation/game_screen.dart';
import 'package:papatte_parc/shared/app_theme.dart';
import 'package:papatte_parc/shared/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('le menu principal ouvre les deux jeux', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final refugeStore = await ProgressStore.load();
    await _pumpRoot(tester, refugeStore, const Size(1366, 768));

    expect(find.text('Balises du refuge'), findsOneWidget);
    expect(find.text('Pattes & Friandises'), findsOneWidget);
    await tester.tap(find.byKey(const Key('game-pattes-friandises')));
    await tester.pump();

    expect(find.byKey(const Key('match3-level-grid')), findsOneWidget);
    await tester.tap(find.byKey(const Key('match3-level-1')));
    await tester.pump();

    expect(find.byKey(const Key('match3-cell-0-0')), findsOneWidget);
    expect(find.textContaining('28 coups'), findsWidgets);
  });

  testWidgets('le bouton quitter est réservé à Windows', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    MethodCall? applicationCall;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('papatte_parc/application'),
      (call) async {
        applicationCall = call;
        return null;
      },
    );
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await _pumpApp(tester, store, const Size(1366, 768));
    expect(find.byKey(const Key('quit-app')), findsOneWidget);
    expect(find.text('QUITTER'), findsNothing);
    expect(find.byIcon(Icons.exit_to_app_rounded), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const Key('quit-app'))).dx,
      greaterThan(
        tester.getCenter(find.byKey(const Key('journey-progress'))).dx,
      ),
    );
    await tester.tap(find.byKey(const Key('quit-app')));
    expect(applicationCall?.method, 'quit');

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
    expect(find.text('Clique sur un point de la carte'), findsOneWidget);
    await tester.tap(find.byKey(const Key('start-mission')));
    await tester.pump();

    expect(find.textContaining('Niveau 1 · Terrier'), findsOneWidget);
    expect(find.byKey(const Key('cell-0-0')), findsOneWidget);
    expect(find.textContaining('À localiser : 5'), findsOneWidget);
  });

  testWidgets('une grille personnalisée reprend les choix du joueur', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await _pumpApp(tester, store, const Size(800, 1280));

    final customButton = tester.getCenter(
      find.byKey(const Key('open-custom-game')),
    );
    expect(customButton.dx, greaterThan(400));
    expect(customButton.dy, greaterThan(640));
    await tester.tap(find.byKey(const Key('open-custom-game')));
    await tester.pump();
    expect(find.text('Crée ton refuge'), findsOneWidget);
    expect(find.byKey(const Key('level-art')), findsOneWidget);

    await tester.tap(find.byKey(const Key('custom-animal-type')));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Ink) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration &&
            decoration.color == AppColors.primary;
      }),
      findsOneWidget,
    );
    await tester.tap(find.text('Lions d’Afrique').last);
    await tester.pumpAndSettle();
    final preview = tester.widget<Image>(find.byKey(const Key('level-art')));
    expect((preview.image as AssetImage).assetName, levels[1].artAsset);

    await tester.tap(find.byKey(const Key('start-custom-game')));
    await tester.pump();

    expect(find.text('PARTIE LIBRE'), findsOneWidget);
    expect(find.text('Lions d’Afrique'), findsOneWidget);
    expect(find.textContaining('À localiser : 10'), findsOneWidget);
    expect(find.byKey(const Key('cell-7-7')), findsOneWidget);
  });

  testWidgets('les limites personnalisées bloquent les choix impossibles', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await _pumpApp(tester, store, const Size(800, 1280));
    await tester.tap(find.byKey(const Key('open-custom-game')));
    await tester.pump();

    final width = find.byKey(const Key('custom-width'));
    final decrease = find.descendant(
      of: width,
      matching: find.byIcon(Icons.remove_rounded),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(decrease);
      await tester.pump();
    }

    expect(find.text('Pour une grille 5 × 8 : 1 à 8 animaux.'), findsOneWidget);
    final decreaseButton = find.ancestor(
      of: decrease,
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(decreaseButton).onPressed, isNull);
    expect(
      find.descendant(
        of: find.byKey(const Key('custom-animal-count')),
        matching: find.text('8'),
      ),
      findsOneWidget,
    );
    final increaseAnimals = find.ancestor(
      of: find.descendant(
        of: find.byKey(const Key('custom-animal-count')),
        matching: find.byIcon(Icons.add_rounded),
      ),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(increaseAnimals).onPressed, isNull);
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

  testWidgets('le choix des effets sonores est mémorisé séparément', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await _pumpApp(tester, store, const Size(800, 1280));

    await tester.tap(find.byKey(const Key('toggle-effects')));
    await tester.pump();

    expect(store.effectsEnabled, isFalse);
    expect(store.musicEnabled, isTrue);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-music')));
    await tester.pump();

    expect(store.effectsEnabled, isFalse);
    expect(store.musicEnabled, isFalse);
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

    final customLevel = createCustomLevel(level, level.config);
    await _pumpGame(
      tester,
      customLevel,
      _wonSession(customLevel),
      const Size(800, 1280),
    );
    expect(find.text('Niveau suivant'), findsNothing);
    expect(find.text('Revoir cette grille'), findsOneWidget);
    expect(find.text('Retour à l’accueil'), findsOneWidget);
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
  await tester.pumpWidget(
    PapatteParcApp(
      key: UniqueKey(),
      refugeStore: store,
      match3Store: await Match3ProgressStore.load(),
      settings: await SettingsStore.load(),
    ),
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('game-refuge')));
  await tester.pump();
}

Future<void> _pumpRoot(
  WidgetTester tester,
  ProgressStore store,
  Size size,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    PapatteParcApp(
      key: UniqueKey(),
      refugeStore: store,
      match3Store: await Match3ProgressStore.load(),
      settings: await SettingsStore.load(),
    ),
  );
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
