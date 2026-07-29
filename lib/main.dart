import 'package:flutter/material.dart';

import 'data/progress_store.dart';
import 'presentation/game_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PapatteParcApp(store: await ProgressStore.load()));
}
