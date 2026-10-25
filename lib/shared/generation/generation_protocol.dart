import '../../games/refuge/domain/board_generator.dart' as refuge;
import '../../games/refuge/domain/models.dart' as r;
import '../../games/repas_animaux/domain/generator.dart' as repas;
import '../../games/sudoku_animaux/domain/campaign.dart' as sudoku;
import '../../games/sudoku_animaux/domain/models.dart' as s;
import '../../games/mahjong_animaux/domain/mahjong_generator.dart';
import '../../games/mahjong_animaux/domain/models.dart' as m;
import '../animal_catalog.dart';
import '../park_catalog.dart';
import '../park_stages.dart';

List<int> ints(dynamic value) => (value as List).cast<int>();

Map<String, Object?> encodeMahjongLayout(m.MahjongLayoutDefinition layout) => {
  'id': layout.id,
  'name': layout.name,
  'difficulty': layout.difficulty.index,
  'species': layout.speciesCount,
  'challenge': layout.challenge,
  'positions': [
    for (final p in layout.positions) [p.x, p.y, p.layer],
  ],
};
m.MahjongLayoutDefinition decodeMahjongLayout(Map<String, dynamic> data) =>
    m.MahjongLayoutDefinition(
      id: data['id'] as String,
      name: data['name'] as String,
      difficulty: m.MahjongDifficulty.values[data['difficulty'] as int],
      speciesCount: data['species'] as int,
      challenge: (data['challenge'] as num).toDouble(),
      positions: [
        for (final p in data['positions'] as List)
          m.MahjongPosition(p[0] as int, p[1] as int, p[2] as int),
      ],
    );

Map<String, Object?> encodeSudoku(s.SudokuLevelDefinition level) => {
  'stage': level.number,
  'size': level.size,
  'boxWidth': level.boxWidth,
  'boxHeight': level.boxHeight,
  'animals': level.animals.map((a) => a.index).toList(),
  'solution': level.solution,
  'puzzle': level.puzzle,
};
s.SudokuLevelDefinition decodeSudoku(
  Map<String, dynamic> data,
  ParkStage stage,
) => s.SudokuLevelDefinition(
  stage: stage,
  size: data['size'] as int,
  boxWidth: data['boxWidth'] as int,
  boxHeight: data['boxHeight'] as int,
  animals: ints(data['animals']).map((i) => AnimalKind.values[i]).toList(),
  solution: ints(data['solution']),
  puzzle: ints(data['puzzle']),
);

/// Pure Dart entrypoint shared by isolates and the browser worker.
Map<String, dynamic> executeGeneration(Map<String, dynamic> request) {
  final seed = request['seed'] as int;
  switch (request['kind']) {
    case 'sudoku':
      final stage = parkStages[(request['stage'] as int) - 1];
      final free = request['free'] == true;
      final level = free
          ? sudoku.buildFreeSudokuLevel(
              stage,
              s.SudokuFreeGameConfig(
                size: request['size'] as int,
                difficulty:
                    s.SudokuDifficulty.values[request['difficulty'] as int],
                biome: stage.biome,
              ),
              seed,
            )
          : sudoku.buildSudokuLevel(stage);
      return encodeSudoku(level);
    case 'mahjong':
      final layout = decodeMahjongLayout(
        (request['layout'] as Map).cast<String, dynamic>(),
      );
      final biome = LevelBiome.values[request['biome'] as int];
      final preferred = animalsByBiome[biome]!;
      final pool = [
        ...preferred,
        ...AnimalKind.values.where((a) => !preferred.contains(a)),
      ].take(layout.speciesCount).toList();
      final random = RecordedRandom(seed);
      final deal = MahjongGenerator(
        layout: layout,
        animals: pool,
        random: random,
      ).generate();
      return {
        'animals': deal.animals.map((a) => a.index).toList(),
        'solution': [
          for (final pair in deal.solution) [pair.first, pair.second],
        ],
        'complexity': deal.complexity,
        'randomCalls': random.calls,
      };
    case 'repas':
      final board = repas.generateRepasBoard((
        repas.RepasFreeGameConfig(
          size: repas.RepasBoardSize.values[request['size'] as int],
          difficulty:
              repas.RepasDifficulty.values[request['difficulty'] as int],
        ),
        seed,
      ));
      return {
        'rows': board.rows,
        'pushes': board.parPushes,
        'solution': board.solution.map((d) => d.index).toList(),
      };
    case 'refuge':
      final config = r.BoardConfig(
        request['width'] as int,
        request['height'] as int,
        request['count'] as int,
      );
      final first = r.CellPosition(request['x'] as int, request['y'] as int);
      final board = refuge.generateBoard(
        refuge.BoardGenerationRequest(config, first, seed),
      );
      if (board == null) return {'board': null};
      return {
        'seed': board.seed,
        'animals': [
          for (var i = 0; i < config.cellCount; i++)
            board.isAnimal(r.CellPosition(i % config.width, i ~/ config.width)),
        ],
        'adjacent': [
          for (var i = 0; i < config.cellCount; i++)
            board.adjacentAnimals(
              r.CellPosition(i % config.width, i ~/ config.width),
            ),
        ],
        'certificate': [
          for (final step in board.certificate)
            {
              'kind': step.kind.index,
              'source': [step.source.x, step.source.y],
              'targets': [
                for (final t in step.targets) [t.x, t.y],
              ],
            },
        ],
      };
    default:
      throw ArgumentError.value(request['kind'], 'kind', 'Unknown generator');
  }
}
