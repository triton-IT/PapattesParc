import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/game_app.dart';
import 'games/pattes_friandises/data/match3_progress_store.dart';
import 'games/refuge/data/progress_store.dart';
import 'shared/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) await BrowserContextMenu.disableContextMenu();
  runApp(
    PapatteParcApp(
      refugeStore: await ProgressStore.load(),
      match3Store: await Match3ProgressStore.load(),
      settings: await SettingsStore.load(),
    ),
  );
}
