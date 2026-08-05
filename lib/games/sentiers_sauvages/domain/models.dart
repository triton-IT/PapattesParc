import '../../../shared/animal_catalog.dart';
import '../../../shared/park_catalog.dart';

enum NumberlinkStatus { playing, won }

enum NumberlinkTraceResult {
  blocked,
  started,
  extended,
  retracted,
  connected,
  won,
}

enum NumberlinkDifficulty { easy, medium, hard }

extension NumberlinkDifficultyLabel on NumberlinkDifficulty {
  String get label => switch (this) {
    NumberlinkDifficulty.easy => 'Facile',
    NumberlinkDifficulty.medium => 'Moyen',
    NumberlinkDifficulty.hard => 'Difficile',
  };
}

class NumberlinkFreeGameConfig {
  const NumberlinkFreeGameConfig({
    required this.size,
    required this.difficulty,
    required this.biome,
  });

  final int size;
  final NumberlinkDifficulty difficulty;
  final LevelBiome biome;
}

class NumberlinkPosition {
  const NumberlinkPosition(this.x, this.y);

  final int x;
  final int y;

  int index(int size) => y * size + x;

  bool isAdjacentTo(NumberlinkPosition other) =>
      (x - other.x).abs() + (y - other.y).abs() == 1;

  @override
  bool operator ==(Object other) =>
      other is NumberlinkPosition && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

class NumberlinkPair {
  const NumberlinkPair({
    required this.id,
    required this.animal,
    required this.animalPosition,
    required this.enclosurePosition,
    required this.referencePath,
  });

  final int id;
  final AnimalKind animal;
  final NumberlinkPosition animalPosition;
  final NumberlinkPosition enclosurePosition;
  final List<NumberlinkPosition> referencePath;

  bool isEndpoint(NumberlinkPosition position) =>
      position == animalPosition || position == enclosurePosition;

  NumberlinkPosition otherEndpoint(NumberlinkPosition position) =>
      position == animalPosition ? enclosurePosition : animalPosition;
}

class NumberlinkLevelDefinition {
  const NumberlinkLevelDefinition({
    required this.stage,
    required this.size,
    required this.pairs,
  });

  final ParkStage stage;
  final int size;
  final List<NumberlinkPair> pairs;

  int get number => stage.number;
  int get pairCount => pairs.length;

  NumberlinkPair? pairAtEndpoint(NumberlinkPosition position) {
    for (final pair in pairs) {
      if (pair.isEndpoint(position)) return pair;
    }
    return null;
  }
}
