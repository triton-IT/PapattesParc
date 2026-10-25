import 'shared/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/game_app.dart';
import 'games/mahjong_animaux/data/mahjong_progress_store.dart';
import 'games/pattes_friandises/data/match3_progress_store.dart';
import 'games/refuge/data/progress_store.dart';
import 'games/repas_animaux/data/repas_animaux_progress_store.dart';
import 'games/sentiers_sauvages/data/numberlink_progress_store.dart';
import 'games/solitaire_animaux/data/solitaire_progress_store.dart';
import 'games/sudoku_animaux/data/sudoku_progress_store.dart';
import 'games/familles_du_parc/data/animal_sort_progress_store.dart';
import 'shared/settings_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _StartupApp());
}

Future<PapatteParcApp> _loadApplication() async {
  if (kIsWeb) await BrowserContextMenu.disableContextMenu();
  return PapatteParcApp(
    refugeStore: await ProgressStore.load(),
    match3Store: await Match3ProgressStore.load(),
    mahjongStore: await MahjongProgressStore.load(),
    solitaireStore: await SolitaireProgressStore.load(),
    sudokuStore: await SudokuProgressStore.load(),
    repasStore: await RepasAnimauxProgressStore.load(),
    numberlinkStore: await NumberlinkProgressStore.load(),
    animalSortStore: await AnimalSortProgressStore.load(),
    settings: await SettingsStore.load(),
  );
}

class _StartupApp extends StatefulWidget {
  const _StartupApp();
  @override
  State<_StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<_StartupApp> {
  late Future<PapatteParcApp> _loading = _loadApplication();
  @override
  Widget build(BuildContext context) => FutureBuilder<PapatteParcApp>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) return snapshot.data!;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Papatte Parc',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deep,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (snapshot.hasError) ...[
                      const Text(
                        'Le jeu ne peut pas être ouvert. Réessaie dans un instant.',
                        textAlign: TextAlign.center,
                      ),
                      FilledButton(
                        onPressed: () =>
                            setState(() => _loading = _loadApplication()),
                        child: const Text('Réessayer'),
                      ),
                    ] else ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Préparation de ton aventure…'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
