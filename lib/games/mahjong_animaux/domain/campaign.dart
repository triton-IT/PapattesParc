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
  if (layers == 1) return _groundPositions(total, 4 + variant % 3 * 2);

  final upperCount = [
    for (var size = layers; size >= 2; size--) size * size,
  ].fold(0, (sum, count) => sum + count);
  final groundCount = total - upperCount;
  final desiredColumns = 4 + variant % 3 * 2;
  final columns = desiredColumns.clamp(layers + 1, groundCount ~/ (layers + 1));
  final positions = _groundPositions(groundCount, columns);
  final coreStart = (columns - layers - 1) ~/ 2;
  for (var layer = 1; layer < layers; layer++) {
    final size = layers + 1 - layer;
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        positions.add(
          MahjongPosition(
            (coreStart + column) * 2 + layer,
            row * 2 + layer,
            layer,
          ),
        );
      }
    }
  }
  return positions;
}

List<MahjongPosition> _groundPositions(int count, int columns) => [
  for (var index = 0; index < count; index++)
    MahjongPosition((index % columns) * 2, (index ~/ columns) * 2, 0),
];
