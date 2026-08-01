import '../../../shared/animal_catalog.dart';
import '../../../shared/park_catalog.dart';

export '../../../shared/animal_catalog.dart' show AnimalKind, AnimalKindLabel;

enum Match3Status { playing, won, lost }

enum SpecialKind {
  none,
  horizontalBinoculars,
  verticalBinoculars,
  basketBlast,
  goldenPaw,
}

enum BlockerKind { leaves, mud, vines, ice }

enum Match3GoalKind { collectAnimal, clearBlockers, deliverBaskets }

class Match3Position {
  const Match3Position(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is Match3Position && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

class Match3Goal {
  const Match3Goal(this.kind, this.target, [this.animal]);

  final Match3GoalKind kind;
  final int target;
  final AnimalKind? animal;
}

class BlockerPlacement {
  const BlockerPlacement(this.position, this.kind, [this.layers = 1]);

  final Match3Position position;
  final BlockerKind kind;
  final int layers;
}

class Match3LevelDefinition {
  const Match3LevelDefinition({
    required this.stage,
    required this.animals,
    required this.moves,
    required this.goals,
    required this.blockers,
    required this.inactiveCells,
    required this.basketColumns,
    required this.twoFootprints,
    required this.threeFootprints,
  });

  final ParkStage stage;
  final List<AnimalKind> animals;
  final int moves;
  final List<Match3Goal> goals;
  final List<BlockerPlacement> blockers;
  final Set<Match3Position> inactiveCells;
  final List<int> basketColumns;
  final int twoFootprints;
  final int threeFootprints;

  int get number => stage.number;
}

class Match3Tile {
  const Match3Tile({
    required this.animal,
    this.special = SpecialKind.none,
    this.isBasket = false,
  });

  const Match3Tile.basket()
    : animal = AnimalKind.suricate,
      special = SpecialKind.none,
      isBasket = true;

  final AnimalKind animal;
  final SpecialKind special;
  final bool isBasket;

  Match3Tile withSpecial(SpecialKind value) =>
      Match3Tile(animal: animal, special: value);
}

class Match3CellSnapshot {
  const Match3CellSnapshot({
    required this.tile,
    required this.blocker,
    required this.blockerLayers,
    required this.isActive,
  });

  final Match3Tile? tile;
  final BlockerKind? blocker;
  final int blockerLayers;
  final bool isActive;
}

class Match3BoardSnapshot {
  const Match3BoardSnapshot({
    required this.cells,
    required this.goalProgress,
    required this.score,
    required this.status,
  });

  final List<Match3CellSnapshot> cells;
  final List<int> goalProgress;
  final int score;
  final Match3Status status;

  Match3CellSnapshot cell(Match3Position position) =>
      cells[position.y * 8 + position.x];
}

class Match3ResolutionStep {
  const Match3ResolutionStep({
    required this.cascade,
    required this.cleared,
    required this.result,
  });

  final int cascade;
  final Set<Match3Position> cleared;
  final Match3BoardSnapshot result;
}

class Match3MoveResult {
  const Match3MoveResult({
    required this.changed,
    required this.reshuffled,
    this.initial,
    this.steps = const [],
  });

  final bool changed;
  final bool reshuffled;
  final Match3BoardSnapshot? initial;
  final List<Match3ResolutionStep> steps;
}
