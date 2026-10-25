import 'package:flutter/foundation.dart';
import '../games/refuge/domain/models.dart' as r;
import '../games/repas_animaux/domain/generator.dart' as repas;
import '../games/repas_animaux/domain/models.dart' as food;
import '../games/sudoku_animaux/domain/models.dart' as s;
import '../games/mahjong_animaux/domain/models.dart' as m;
import '../games/mahjong_animaux/domain/mahjong_generator.dart';
import 'animal_catalog.dart';
import 'park_catalog.dart';
import 'game_activity.dart';
import 'generation/generation_protocol.dart';
import 'generation/generation_backend_native.dart'
    if (dart.library.js_interop) 'generation/generation_backend_web.dart'
    as backend;

class StaleGeneration implements Exception {}

class GenerationService extends ValueNotifier<bool> {
  GenerationService() : super(false);
  int _requestId = 0;
  bool _disposed = false;
  static final Map<String, Map<String, dynamic>> _fixed = {};

  void cancel() {
    _requestId++;
    value = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }

  Future<Map<String, dynamic>> _run(
    Map<String, dynamic> request, {
    String? cacheKey,
  }) async {
    final id = ++_requestId;
    value = true;
    try {
      final cached = cacheKey == null ? null : _fixed[cacheKey];
      final result =
          cached ?? await backend.generateInBackground({...request, 'id': id});
      if (cacheKey != null) _fixed[cacheKey] = result;
      await GameActivity.instance.whenActive;
      if (_disposed || id != _requestId) throw StaleGeneration();
      return result;
    } finally {
      if (!_disposed && id == _requestId) value = false;
    }
  }

  Future<s.SudokuLevelDefinition> sudoku(
    ParkStage stage, {
    s.SudokuFreeGameConfig? config,
    int seed = 0,
  }) async {
    final data = await _run({
      'kind': 'sudoku',
      'stage': stage.number,
      'seed': seed,
      'free': config != null,
      if (config != null) 'size': config.size,
      if (config != null) 'difficulty': config.difficulty.index,
    }, cacheKey: config == null ? 'sudoku:${stage.number}' : null);
    return decodeSudoku(data, stage);
  }

  Future<PreparedMahjongDeal> mahjong(
    m.MahjongLayoutDefinition layout,
    LevelBiome biome,
    int seed,
  ) async {
    final data = await _run({
      'kind': 'mahjong',
      'seed': seed,
      'biome': biome.index,
      'layout': encodeMahjongLayout(layout),
    });
    return PreparedMahjongDeal(
      MahjongDeal(
        ints(data['animals']).map((i) => AnimalKind.values[i]).toList(),
        [
          for (final pair in data['solution'] as List)
            (first: pair[0] as int, second: pair[1] as int),
        ],
        data['complexity'] as int,
      ),
      ints(data['randomCalls']),
    );
  }

  Future<repas.RepasGeneratedBoard> repasBoard(
    repas.RepasFreeGameConfig config,
    int seed,
  ) async {
    final data = await _run({
      'kind': 'repas',
      'seed': seed,
      'size': config.size.index,
      'difficulty': config.difficulty.index,
    });
    return repas.RepasGeneratedBoard(
      (data['rows'] as List).cast<String>(),
      data['pushes'] as int,
      ints(data['solution']).map((i) => food.RepasDirection.values[i]).toList(),
    );
  }

  Future<r.GeneratedBoard?> refuge(
    r.BoardConfig config,
    r.CellPosition first,
    int seed,
  ) async {
    final data = await _run({
      'kind': 'refuge',
      'seed': seed,
      'width': config.width,
      'height': config.height,
      'count': config.animalCount,
      'x': first.x,
      'y': first.y,
    });
    if (data.containsKey('board') && data['board'] == null) return null;
    return r.GeneratedBoard(
      config,
      data['seed'] as int,
      first,
      (data['animals'] as List).cast<bool>(),
      ints(data['adjacent']),
      [
        for (final step in data['certificate'] as List)
          r.DeductionStep(
            r.DeductionKind.values[step['kind'] as int],
            r.CellPosition(step['source'][0] as int, step['source'][1] as int),
            [
              for (final t in step['targets'] as List)
                r.CellPosition(t[0] as int, t[1] as int),
            ],
          ),
      ],
    );
  }
}
