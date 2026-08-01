import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/app/game_app.dart';
import 'package:papatte_parc/games/pattes_friandises/data/match3_progress_store.dart';
import 'package:papatte_parc/games/pattes_friandises/domain/match3_session.dart';
import 'package:papatte_parc/games/pattes_friandises/domain/models.dart';
import 'package:papatte_parc/games/mahjong_animaux/data/mahjong_progress_store.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/mahjong_animaux/domain/mahjong_session.dart';
import 'package:papatte_parc/games/mahjong_animaux/presentation/mahjong_screen.dart';
import 'package:papatte_parc/games/refuge/data/progress_store.dart';
import 'package:papatte_parc/games/refuge/domain/board_generator.dart';
import 'package:papatte_parc/games/refuge/domain/custom_game.dart';
import 'package:papatte_parc/games/refuge/domain/game_session.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/refuge/domain/models.dart';
import 'package:papatte_parc/games/refuge/presentation/game_screen.dart';
import 'package:papatte_parc/games/solitaire_animaux/data/solitaire_progress_store.dart';
import 'package:papatte_parc/shared/app_theme.dart';
import 'package:papatte_parc/shared/animal_colors.dart';
import 'package:papatte_parc/shared/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('le menu principal ouvre les quatre jeux', (tester) async {
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

    await _pumpRoot(tester, refugeStore, const Size(1366, 768));
    expect(find.text('Mahjong des animaux'), findsOneWidget);
    await tester.tap(find.byKey(const Key('game-mahjong-animaux')));
    await tester.pump();
    expect(find.byKey(const Key('mahjong-level-grid')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mahjong-level-1')));
    await tester.pump();
    expect(find.byKey(const Key('mahjong-board')), findsOneWidget);
  });

  testWidgets(
    'le solitaire mémorise sa configuration et lance les deux modes',
    (tester) async {
      for (final size in _referenceSizes) {
        SharedPreferences.setMockInitialValues({});
        final store = await ProgressStore.load();
        await _pumpRoot(tester, store, size);

        if (find
            .byKey(const Key('game-solitaire-animaux'))
            .evaluate()
            .isEmpty) {
          await tester.scrollUntilVisible(
            find.byKey(const Key('game-solitaire-animaux')),
            400,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.drag(find.byType(ListView).first, const Offset(0, -180));
          await tester.pump();
        }
        await tester.tap(find.byKey(const Key('game-solitaire-animaux')));
        await tester.pump();
        expect(find.byKey(const Key('solitaire-setup')), findsOneWidget);
        expect(
          find.byKey(const Key('solitaire-animal-suricate')),
          findsOneWidget,
        );

        await tester.tap(find.text('Pioche 3 cartes').first);
        await tester.pump();
        await tester.scrollUntilVisible(
          find.byKey(const Key('solitaire-animal-panthereNeiges')),
          400,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -140));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('solitaire-animal-panthereNeiges')),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('solitaire-start')));
        await tester.pump();

        expect(find.byKey(const Key('solitaire-board')), findsOneWidget);
        expect(find.byKey(const Key('solitaire-stock')), findsOneWidget);
        expect(find.byKey(const Key('solitaire-tableau-6')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$size');

        final solitaireStore = await SolitaireProgressStore.load();
        expect(solitaireStore.mode.name, 'drawThree');
        expect(solitaireStore.backAnimal.name, 'panthereNeiges');
      }
    },
  );

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

  testWidgets(
    'le retour Android conserve ou abandonne la partie à la demande',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();
      await _pumpApp(tester, store, const Size(360, 800));
      await tester.tap(find.byKey(const Key('start-mission')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cell-3-3')));
      await tester.pump();
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

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Abandonner la partie en cours ?'), findsOneWidget);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cell-3-3')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('start-mission')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Pattes & Friandises'), findsOneWidget);
    },
  );

  testWidgets('le retour est bloqué pendant une opération en cours', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await _pumpApp(tester, store, const Size(360, 800));
    await tester.tap(find.byKey(const Key('start-mission')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cell-3-3')));
    await tester.pump();
    expect(find.byKey(const Key('generation-overlay')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Le refuge est en cours de préparation.'), findsOneWidget);
    expect(find.byKey(const Key('generation-overlay')), findsOneWidget);

    await _pumpRoot(tester, store, const Size(360, 800));
    await tester.tap(find.byKey(const Key('game-pattes-friandises')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('match3-level-1')));
    await tester.pump();
    for (
      var y = 0;
      y < Match3Session.size &&
          find.byKey(const Key('match3-resolving')).evaluate().isEmpty;
      y++
    ) {
      for (
        var x = 0;
        x < Match3Session.size &&
            find.byKey(const Key('match3-resolving')).evaluate().isEmpty;
        x++
      ) {
        for (final target in [
          if (x + 1 < Match3Session.size) Match3Position(x + 1, y),
          if (y + 1 < Match3Session.size) Match3Position(x, y + 1),
        ]) {
          await tester.tap(find.byKey(Key('match3-cell-$x-$y')));
          await tester.tap(
            find.byKey(Key('match3-cell-${target.x}-${target.y}')),
          );
          await tester.pump();
          if (find.byKey(const Key('match3-resolving')).evaluate().isNotEmpty) {
            break;
          }
        }
      }
    }
    expect(find.byKey(const Key('match3-resolving')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Le coup est en cours de résolution.'), findsOneWidget);
    expect(find.byKey(const Key('match3-resolving')), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('les grands plateaux sont visibles et permettent le zoom', (
    tester,
  ) async {
    final refugeLevel = createCustomLevel(
      levels.first,
      const BoardConfig(25, 20, 40),
    );
    final refugeSession = GameSession(refugeLevel.config);
    await _pumpPlayingGame(
      tester,
      refugeLevel,
      refugeSession,
      const Size(360, 800),
    );
    _expectInside(
      tester,
      const Key('refuge-board-viewer'),
      const Key('cell-0-0'),
    );
    _expectInside(
      tester,
      const Key('refuge-board-viewer'),
      const Key('cell-24-19'),
    );
    final refugeViewer = find.byKey(const Key('refuge-board-viewer'));
    final refugeInteractive = tester.widget<InteractiveViewer>(refugeViewer);
    expect(
      refugeInteractive.maxScale,
      greaterThan(refugeInteractive.transformationController!.value.storage[0]),
    );

    final level = buildMahjongCampaign(levels).reduce(
      (first, second) =>
          first.layout.tileCount > second.layout.tileCount ? first : second,
    );
    final mahjongSession = MahjongSession(
      layout: level.layout,
      biome: level.stage.biome,
      seed: 41,
    );
    await _pumpMahjong(tester, mahjongSession, const Size(360, 800));
    final board = find.byKey(const Key('mahjong-board'));
    final firstTile = mahjongSession.tiles.first.tile;
    final tileDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.byKey(Key('mahjong-tile-${firstTile.id}')),
                )
                .decoration
            as BoxDecoration;
    expect(tileDecoration.color, animalHaloColor(firstTile.animal));
    for (final snapshot in mahjongSession.tiles) {
      _expectInside(
        tester,
        const Key('mahjong-board'),
        Key('mahjong-tile-${snapshot.tile.id}'),
      );
    }
    final mahjongInteractive = tester.widget<InteractiveViewer>(board);
    expect(
      mahjongInteractive.maxScale,
      greaterThan(
        mahjongInteractive.transformationController!.value.storage[0],
      ),
    );
  });

  testWidgets('les aides et les repères animaux sont accessibles', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await _pumpRoot(tester, store, const Size(360, 800));
    await tester.tap(find.byKey(const Key('game-pattes-friandises')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('help-match3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('help-content-match3')), findsOneWidget);
    await tester.tap(find.text('J’AI COMPRIS'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('match3-level-1')));
    await tester.pump();
    expect(
      find.byKey(const Key('match3-goal-animal-suricate')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('help-match3')), findsOneWidget);
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
      mahjongStore: await MahjongProgressStore.load(),
      solitaireStore: await SolitaireProgressStore.load(),
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
      mahjongStore: await MahjongProgressStore.load(),
      solitaireStore: await SolitaireProgressStore.load(),
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

Future<void> _pumpPlayingGame(
  WidgetTester tester,
  LevelDefinition level,
  GameSession session,
  Size size,
) async {
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
        finished: false,
        newRecord: false,
        onHome: () {},
        onReveal: (_) {},
        onFlag: (_) {},
        onReplaySame: () {},
        onReplayNew: () {},
        onNext: () {},
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpMahjong(
  WidgetTester tester,
  MahjongSession session,
  Size size,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: MahjongScreen(
        session: session,
        title: 'Grand plateau',
        isFreeGame: false,
        hintedIds: const {},
        finished: false,
        newRecord: false,
        onSelect: (_) {},
        onBlocked: () {},
        onHint: () {},
        onShuffle: () {},
        onBack: () {},
        onReplaySame: () {},
        onReplayNew: () {},
        onLevels: () {},
        onConfigure: null,
        onNext: null,
      ),
    ),
  );
  await tester.pump();
}

void _expectInside(WidgetTester tester, Key parentKey, Key childKey) {
  final parent = tester.getRect(find.byKey(parentKey));
  final child = tester.getRect(find.byKey(childKey));
  expect(
    parent.inflate(1).contains(child.topLeft),
    isTrue,
    reason: '$childKey',
  );
  expect(
    parent.inflate(1).contains(child.bottomRight),
    isTrue,
    reason: '$childKey',
  );
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
