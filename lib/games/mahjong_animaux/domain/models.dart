import '../../../shared/animal_catalog.dart';
import '../../../shared/park_catalog.dart';

enum MahjongStatus { playing, won, lost }

enum MahjongDifficulty { easy, medium, hard }

extension MahjongDifficultyLabel on MahjongDifficulty {
  String get label => switch (this) {
    MahjongDifficulty.easy => 'Facile',
    MahjongDifficulty.medium => 'Moyen',
    MahjongDifficulty.hard => 'Difficile',
  };
}

class MahjongPosition {
  const MahjongPosition(this.x, this.y, this.layer);

  final int x;
  final int y;
  final int layer;

  @override
  bool operator ==(Object other) =>
      other is MahjongPosition &&
      x == other.x &&
      y == other.y &&
      layer == other.layer;

  @override
  int get hashCode => Object.hash(x, y, layer);
}

class MahjongLayoutDefinition {
  const MahjongLayoutDefinition({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.positions,
    required this.speciesCount,
  });

  final String id;
  final String name;
  final MahjongDifficulty difficulty;
  final List<MahjongPosition> positions;
  final int speciesCount;

  int get tileCount => positions.length;
  int get maxLayers => positions.fold(
    0,
    (maximum, position) =>
        position.layer + 1 > maximum ? position.layer + 1 : maximum,
  );
}

class MahjongLevelDefinition {
  const MahjongLevelDefinition({required this.stage, required this.layout});

  final ParkStage stage;
  final MahjongLayoutDefinition layout;

  int get number => stage.number;
}

class MahjongFreeGameConfig {
  const MahjongFreeGameConfig({
    required this.layoutId,
    required this.difficulty,
    required this.biome,
  });

  final String layoutId;
  final MahjongDifficulty difficulty;
  final LevelBiome biome;
}

class MahjongTile {
  const MahjongTile({
    required this.id,
    required this.position,
    required this.animal,
  });

  final int id;
  final MahjongPosition position;
  final AnimalKind animal;
}

class MahjongTileSnapshot {
  const MahjongTileSnapshot({
    required this.tile,
    required this.isPresent,
    required this.isFree,
  });

  final MahjongTile tile;
  final bool isPresent;
  final bool isFree;
}

enum MahjongSelectionResult {
  ignored,
  selected,
  deselected,
  replaced,
  matched,
  won,
  lost,
}
