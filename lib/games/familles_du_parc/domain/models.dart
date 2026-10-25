import '../../../shared/animal_catalog.dart';
import '../../../shared/park_catalog.dart';

const animalSortZoneCapacity = 4;

enum AnimalSortStatus { playing, won }

enum AnimalSortMoveResult { blocked, moved, won }

class AnimalSortMove {
  const AnimalSortMove(this.from, this.to);

  final int from;
  final int to;

  @override
  bool operator ==(Object other) =>
      other is AnimalSortMove && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(from, to);
}

class AnimalSortLevelDefinition {
  const AnimalSortLevelDefinition({
    required this.stage,
    required this.animals,
    required this.initialZones,
    required this.referenceSolution,
  });

  final ParkStage stage;
  final List<AnimalKind> animals;
  final List<List<AnimalKind>> initialZones;
  final List<AnimalSortMove> referenceSolution;

  int get number => stage.number;
  int get parMoves => referenceSolution.length;
}

class AnimalSortFreeGameConfig {
  const AnimalSortFreeGameConfig({
    required this.speciesCount,
    required this.biome,
  });

  final int speciesCount;
  final LevelBiome biome;
}
