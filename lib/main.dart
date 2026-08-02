import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/game_app.dart';
import 'games/mahjong_animaux/data/mahjong_progress_store.dart';
import 'games/pattes_friandises/data/match3_progress_store.dart';
import 'games/refuge/data/progress_store.dart';
import 'games/solitaire_animaux/data/solitaire_progress_store.dart';
import 'games/sudoku_animaux/data/sudoku_progress_store.dart';
import 'shared/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) await BrowserContextMenu.disableContextMenu();
  runApp(
    PapatteParcApp(
      refugeStore: await ProgressStore.load(),
      match3Store: await Match3ProgressStore.load(),
      mahjongStore: await MahjongProgressStore.load(),
      solitaireStore: await SolitaireProgressStore.load(),
      sudokuStore: await SudokuProgressStore.load(),
      settings: await SettingsStore.load(),
    ),
  );
}
