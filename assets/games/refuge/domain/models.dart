import '../../../shared/park_catalog.dart';

class BoardConfig {
  const BoardConfig(this.width, this.height, this.animalCount);

  final int width;
  final int height;
  final int animalCount;
  int get cellCount => width * height;
}

class CellPosition {
  const CellPosition(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is CellPosition && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

enum GameStatus { waitingFirstMove, running, won, lost }

enum DeductionKind {
  initialReveal,
  revealSafeCells,
  flagAnimals,
  revealRemainingCells,
  flagRemainingAnimals,
}

class DeductionStep {
  DeductionStep(this.kind, this.source, Iterable<CellPosition> targets)
    : targets = List.unmodifiable(targets);

  final DeductionKind kind;
  final CellPosition source;
  final List<CellPosition> targets;
}

class GeneratedBoard {
  GeneratedBoard(
    this.config,
    this.seed,
    this.firstMove,
    List<bool> animals,
    List<int> adjacentAnimals,
    Iterable<DeductionStep> certificate,
  ) : _animals = List.unmodifiable(animals),
      _adjacentAnimals = List.unmodifiable(adjacentAnimals),
      certificate = List.unmodifiable(certificate);

  final BoardConfig config;
  final int seed;
  final CellPosition firstMove;
  final List<bool> _animals;
  final List<int> _adjacentAnimals;
  final List<DeductionStep> certificate;

  bool isAnimal(CellPosition position) => _animals[_index(position)];
  int adjacentAnimals(CellPosition position) =>
      _adjacentAnimals[_index(position)];
  int _index(CellPosition position) => position.y * config.width + position.x;
}

class CellSnapshot {
  const CellSnapshot({
    required this.isAnimal,
    required this.isRevealed,
    required this.isFlagged,
    required this.isTriggeredAnimal,
    required this.isWrongFlag,
    required this.adjacentAnimals,
  });

  final bool isAnimal;
  final bool isRevealed;
  final bool isFlagged;
  final bool isTriggeredAnimal;
  final bool isWrongFlag;
  final int adjacentAnimals;
}

enum FlagResult { ignored, changed, limitReached }

class LevelDefinition implements ParkStage {
  const LevelDefinition(
    this.number,
    this.title,
    this.species,
    this.config,
    this.biome, [
    this.artAsset,
    this.animalMarkerAsset,
  ]) : customTemperament = null,
       isCustom = false;

  const LevelDefinition.custom(
    this.title,
    this.species,
    this.config,
    this.biome,
    this.artAsset,
    this.animalMarkerAsset,
    this.customTemperament,
  ) : number = 0,
      isCustom = true;

  @override
  final int number;
  @override
  final String title;
  @override
  final String species;
  final BoardConfig config;
  @override
  final LevelBiome biome;
  @override
  final String? artAsset;
  @override
  final String? animalMarkerAsset;
  final AnimalTemperament? customTemperament;
  final bool isCustom;
}
