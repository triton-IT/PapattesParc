import '../../../shared/park_catalog.dart';
import 'models.dart';

const _animalPools = <LevelBiome, List<AnimalKind>>{
  LevelBiome.savanna: [
    AnimalKind.suricate,
    AnimalKind.lion,
    AnimalKind.girafe,
    AnimalKind.zebre,
    AnimalKind.guepard,
    AnimalKind.addax,
  ],
  LevelBiome.tropical: [
    AnimalKind.atele,
    AnimalKind.gibbon,
    AnimalKind.paresseux,
    AnimalKind.tamarin,
    AnimalKind.lemurien,
    AnimalKind.saimiri,
  ],
  LevelBiome.riverside: [
    AnimalKind.loutre,
    AnimalKind.hippopotame,
    AnimalKind.capybara,
    AnimalKind.vison,
    AnimalKind.tortue,
    AnimalKind.tapir,
  ],
  LevelBiome.woodland: [
    AnimalKind.tigre,
    AnimalKind.pandaRoux,
    AnimalKind.loup,
    AnimalKind.ours,
    AnimalKind.glouton,
    AnimalKind.cerfSika,
  ],
  LevelBiome.steppe: [
    AnimalKind.kulan,
    AnimalKind.renne,
    AnimalKind.addax,
    AnimalKind.oryx,
    AnimalKind.gazelle,
    AnimalKind.cerfCochon,
  ],
  LevelBiome.mountain: [
    AnimalKind.goral,
    AnimalKind.tahr,
    AnimalKind.markhor,
    AnimalKind.panthereNeiges,
    AnimalKind.alpaga,
    AnimalKind.urial,
  ],
  LevelBiome.tundra: [
    AnimalKind.renne,
    AnimalKind.panthereAmour,
    AnimalKind.loup,
    AnimalKind.ours,
    AnimalKind.panthereNeiges,
    AnimalKind.glouton,
  ],
};

List<Match3LevelDefinition> buildMatch3Campaign(List<ParkStage> stages) => [
  for (final stage in stages) _buildLevel(stage),
];

Match3LevelDefinition _buildLevel(ParkStage stage) {
  final chapter = (stage.number - 1) ~/ 5;
  final slot = (stage.number - 1) % 5;
  final animals = _animalPools[stage.biome]!.take(stage.number < 16 ? 5 : 6);
  final inactiveCells = stage.number >= 36 && stage.number <= 40
      ? _inactivePattern(slot)
      : const <Match3Position>{};
  final blockers = _blockers(
    stage.number,
  ).where((placement) => !inactiveCells.contains(placement.position)).toList();
  final baskets = stage.number >= 26 && stage.number <= 30
      ? [for (var i = 0; i < 2 + slot ~/ 2; i++) (i * 3 + slot) % 8]
      : stage.number == 45
      ? [1, 3, 5, 7]
      : const <int>[];
  final goals = _goals(
    stage.number,
    animals.toList(),
    blockers.fold(0, (total, item) => total + item.layers),
    baskets.length,
  );
  final moves = (28 - chapter ~/ 2 - (slot == 3 ? 1 : 0)).clamp(21, 28);
  final baseline =
      goals.fold(0, (total, goal) => total + goal.target * 180) + chapter * 900;
  return Match3LevelDefinition(
    stage: stage,
    animals: animals.toList(),
    moves: moves,
    goals: goals,
    blockers: blockers,
    inactiveCells: inactiveCells,
    basketColumns: baskets,
    twoFootprints: baseline,
    threeFootprints: (baseline * 1.55).round(),
  );
}

List<Match3Goal> _goals(
  int level,
  List<AnimalKind> animals,
  int blockerLayers,
  int basketCount,
) {
  final chapter = (level - 1) ~/ 5;
  final slot = (level - 1) % 5;
  if (level == 45) {
    return [
      Match3Goal(Match3GoalKind.deliverBaskets, basketCount),
      Match3Goal(Match3GoalKind.clearBlockers, blockerLayers),
    ];
  }
  if (basketCount > 0) {
    return [
      Match3Goal(Match3GoalKind.deliverBaskets, basketCount),
      Match3Goal(
        Match3GoalKind.collectAnimal,
        12 + chapter,
        animals[slot % animals.length],
      ),
    ];
  }
  if (blockerLayers > 0 && slot >= 2) {
    if (slot == 3) {
      return [
        Match3Goal(Match3GoalKind.clearBlockers, blockerLayers),
        Match3Goal(Match3GoalKind.collectAnimal, 12 + chapter, animals.first),
      ];
    }
    return [Match3Goal(Match3GoalKind.clearBlockers, blockerLayers)];
  }
  if (slot == 1 || slot == 4) {
    return [
      Match3Goal(
        Match3GoalKind.collectAnimal,
        9 + chapter,
        animals[slot % animals.length],
      ),
      Match3Goal(
        Match3GoalKind.collectAnimal,
        9 + chapter,
        animals[(slot + 2) % animals.length],
      ),
    ];
  }
  return [
    Match3Goal(
      Match3GoalKind.collectAnimal,
      15 + chapter * 2,
      animals[slot % animals.length],
    ),
  ];
}

List<BlockerPlacement> _blockers(int level) {
  if (level < 6 || (level >= 26 && level <= 30)) return const [];
  final slot = (level - 1) % 5;
  final positions = _pattern(8 + slot * 2);
  if (level <= 10) return _place(positions, BlockerKind.leaves);
  if (level <= 15) return _place(positions, BlockerKind.mud);
  if (level <= 20) return _place(positions, BlockerKind.vines);
  if (level <= 25) {
    return _place(positions, BlockerKind.ice, level >= 24 ? 2 : 1);
  }
  if (level <= 35) {
    return [
      ..._place(positions.take(positions.length ~/ 2), BlockerKind.mud),
      ..._place(positions.skip(positions.length ~/ 2), BlockerKind.ice, 2),
    ];
  }
  if (level <= 40) {
    return [
      ..._place(positions.take(positions.length ~/ 2), BlockerKind.leaves),
      ..._place(positions.skip(positions.length ~/ 2), BlockerKind.vines),
    ];
  }
  return [
    ..._place(positions.take(positions.length ~/ 2), BlockerKind.ice, 2),
    ..._place(positions.skip(positions.length ~/ 2), BlockerKind.vines),
  ];
}

List<BlockerPlacement> _place(
  Iterable<Match3Position> positions,
  BlockerKind kind, [
  int layers = 1,
]) => [
  for (final position in positions) BlockerPlacement(position, kind, layers),
];

List<Match3Position> _pattern(int count) {
  const order = [
    Match3Position(2, 2),
    Match3Position(3, 2),
    Match3Position(4, 2),
    Match3Position(5, 2),
    Match3Position(2, 3),
    Match3Position(5, 3),
    Match3Position(2, 4),
    Match3Position(5, 4),
    Match3Position(2, 5),
    Match3Position(3, 5),
    Match3Position(4, 5),
    Match3Position(5, 5),
    Match3Position(1, 3),
    Match3Position(6, 3),
    Match3Position(1, 4),
    Match3Position(6, 4),
  ];
  return order.take(count.clamp(0, order.length)).toList();
}

Set<Match3Position> _inactivePattern(int slot) => switch (slot) {
  0 => {
    Match3Position(0, 0),
    Match3Position(7, 0),
    Match3Position(0, 7),
    Match3Position(7, 7),
  },
  1 => {
    Match3Position(0, 0),
    Match3Position(1, 0),
    Match3Position(6, 0),
    Match3Position(7, 0),
  },
  2 => {
    Match3Position(0, 3),
    Match3Position(0, 4),
    Match3Position(7, 3),
    Match3Position(7, 4),
  },
  3 => {
    Match3Position(0, 0),
    Match3Position(7, 0),
    Match3Position(0, 7),
    Match3Position(7, 7),
    Match3Position(3, 3),
    Match3Position(4, 4),
  },
  _ => {
    Match3Position(0, 0),
    Match3Position(1, 0),
    Match3Position(6, 0),
    Match3Position(7, 0),
    Match3Position(0, 7),
    Match3Position(1, 7),
    Match3Position(6, 7),
    Match3Position(7, 7),
  },
};
