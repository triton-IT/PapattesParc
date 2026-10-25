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
      _buildFreeLayout(index, difficulty),
];

List<MahjongLevelDefinition> buildMahjongCampaign(List<ParkStage> stages) => [
  for (final stage in stages)
    MahjongLevelDefinition(
      stage: stage,
      layout: _buildCampaignLayout(stage.number),
    ),
];

MahjongLayoutDefinition mahjongLayout(
  String id,
  MahjongDifficulty difficulty,
) => mahjongLayouts.firstWhere(
  (layout) => layout.id == id && layout.difficulty == difficulty,
);

MahjongLayoutDefinition _buildCampaignLayout(int level) {
  final progress = (level - 1) / 44;
  final speciesCount = 8 + (28 * progress).round();
  final difficulty = MahjongDifficulty.values[(level - 1) ~/ 15];
  return _buildLayout(
    (level - 1) % mahjongLayoutNames.length,
    difficulty,
    speciesCount,
    1 + (4 * progress).round(),
    0.25 + progress * 0.75,
  );
}

MahjongLayoutDefinition _buildFreeLayout(
  int index,
  MahjongDifficulty difficulty,
) {
  final speciesCount = switch (difficulty) {
    MahjongDifficulty.easy => 8 + index % 5,
    MahjongDifficulty.medium => 18 + index % 5,
    MahjongDifficulty.hard => 28 + index % 5 * 2,
  };
  final layerCount = switch (difficulty) {
    MahjongDifficulty.easy => index % 3 == 2 ? 2 : 1,
    MahjongDifficulty.medium => index % 3 == 2 ? 4 : 3,
    MahjongDifficulty.hard => index % 4 == 3 ? 5 : 4,
  };
  final challenge = switch (difficulty) {
    MahjongDifficulty.easy => 0.25,
    MahjongDifficulty.medium => 0.7,
    MahjongDifficulty.hard => 1.0,
  };
  return _buildLayout(index, difficulty, speciesCount, layerCount, challenge);
}

MahjongLayoutDefinition _buildLayout(
  int index,
  MahjongDifficulty difficulty,
  int speciesCount,
  int layerCount,
  double challenge,
) {
  final name = mahjongLayoutNames[index];
  return MahjongLayoutDefinition(
    id: name.toLowerCase().replaceAll(' ', '-'),
    name: name,
    difficulty: difficulty,
    positions: _positions(speciesCount * 4, layerCount, index),
    speciesCount: speciesCount,
    challenge: challenge,
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
