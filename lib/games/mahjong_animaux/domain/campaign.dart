import '../../../shared/park_catalog.dart';
import 'models.dart';

const mahjongLayoutNames = [
  'Empreinte',
  'Terrier',
  'Rivière',
  'Savane',
  'Canopée',
  'Nid',
  'Pont',
  'Papillon',
  'Tortue',
  'Pagode',
  'Montagne',
  'Pyramide',
  'Cascade',
  'Grande patte',
  'Parc',
];

final List<MahjongLayoutDefinition> mahjongLayouts = [
  for (final difficulty in MahjongDifficulty.values)
    for (var index = 0; index < mahjongLayoutNames.length; index++)
      _buildLayout(index, difficulty),
];

List<MahjongLevelDefinition> buildMahjongCampaign(List<ParkStage> stages) => [
  for (final stage in stages)
    MahjongLevelDefinition(
      stage: stage,
      layout: mahjongLayout(
        mahjongLayoutNames[(stage.number - 1) % mahjongLayoutNames.length]
            .toLowerCase()
            .replaceAll(' ', '-'),
        MahjongDifficulty.values[(stage.number - 1) ~/ 15],
      ),
    ),
];

MahjongLayoutDefinition mahjongLayout(
  String id,
  MahjongDifficulty difficulty,
) => mahjongLayouts.firstWhere(
  (layout) => layout.id == id && layout.difficulty == difficulty,
);

MahjongLayoutDefinition _buildLayout(int index, MahjongDifficulty difficulty) {
  final tileCount = switch (difficulty) {
    MahjongDifficulty.easy => 24 + (index % 5) * 4,
    MahjongDifficulty.medium => 48 + (index % 5) * 4,
    MahjongDifficulty.hard => 72 + (index % 5) * 6,
  };
  final layerCount = switch (difficulty) {
    MahjongDifficulty.easy => index % 3 == 2 ? 2 : 1,
    MahjongDifficulty.medium => index % 3 == 2 ? 3 : 2,
    MahjongDifficulty.hard => index % 4 == 3 ? 4 : 3,
  };
  final name = mahjongLayoutNames[index];
  return MahjongLayoutDefinition(
    id: name.toLowerCase().replaceAll(' ', '-'),
    name: name,
    difficulty: difficulty,
    positions: _positions(tileCount, layerCount, index),
    speciesCount: switch (difficulty) {
      MahjongDifficulty.easy => 4,
      MahjongDifficulty.medium => 6,
      MahjongDifficulty.hard => 8,
    },
  );
}

List<MahjongPosition> _positions(int total, int layers, int variant) {
  final counts = List.filled(layers, (total ~/ layers) ~/ 2 * 2);
  var assigned = counts.fold(0, (sum, count) => sum + count);
  for (var layer = 0; assigned < total; layer = (layer + 1) % layers) {
    counts[layer] += 2;
    assigned += 2;
  }
  final positions = <MahjongPosition>[];
  for (var layer = 0; layer < layers; layer++) {
    var remaining = counts[layer];
    var row = 0;
    final columns = 4 + ((variant + layer) % 3) * 2;
    while (remaining > 0) {
      final rowLength = remaining < columns ? remaining : columns;
      final centered = columns - rowLength;
      for (var column = 0; column < rowLength; column++) {
        positions.add(
          MahjongPosition(
            centered + column * 2 + layer % 2,
            row * 2 + layer % 2,
            layer,
          ),
        );
      }
      remaining -= rowLength;
      row++;
    }
  }
  return positions;
}

extension LevelBiomeLabel on LevelBiome {
  String get label => switch (this) {
    LevelBiome.savanna => 'Savane',
    LevelBiome.tropical => 'Forêt tropicale',
    LevelBiome.riverside => 'Bord de rivière',
    LevelBiome.woodland => 'Sous-bois',
    LevelBiome.steppe => 'Steppe',
    LevelBiome.mountain => 'Montagne',
    LevelBiome.tundra => 'Toundra',
  };
}
