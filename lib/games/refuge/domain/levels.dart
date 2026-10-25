import 'models.dart';
import '../../../shared/park_catalog.dart';
import '../../../shared/park_stages.dart';

const _configs = [
  BoardConfig(6, 6, 5),
  BoardConfig(7, 7, 7),
  BoardConfig(8, 8, 9),
  BoardConfig(8, 8, 10),
  BoardConfig(9, 9, 12),
  BoardConfig(9, 9, 13),
  BoardConfig(10, 9, 14),
  BoardConfig(10, 10, 16),
  BoardConfig(11, 10, 18),
  BoardConfig(11, 11, 20),
  BoardConfig(12, 10, 20),
  BoardConfig(12, 11, 22),
  BoardConfig(12, 12, 24),
  BoardConfig(13, 12, 26),
  BoardConfig(13, 13, 28),
  BoardConfig(14, 12, 30),
  BoardConfig(14, 13, 32),
  BoardConfig(14, 14, 34),
  BoardConfig(15, 13, 36),
  BoardConfig(15, 14, 38),
  BoardConfig(15, 15, 40),
  BoardConfig(16, 14, 42),
  BoardConfig(16, 15, 44),
  BoardConfig(16, 16, 46),
  BoardConfig(17, 15, 48),
  BoardConfig(17, 16, 50),
  BoardConfig(18, 15, 52),
  BoardConfig(18, 16, 54),
  BoardConfig(18, 17, 56),
  BoardConfig(19, 16, 58),
  BoardConfig(19, 17, 60),
  BoardConfig(20, 16, 62),
  BoardConfig(20, 17, 64),
  BoardConfig(20, 18, 66),
  BoardConfig(21, 17, 68),
  BoardConfig(21, 18, 70),
  BoardConfig(22, 17, 72),
  BoardConfig(22, 18, 74),
  BoardConfig(22, 19, 76),
  BoardConfig(23, 18, 78),
  BoardConfig(23, 19, 80),
  BoardConfig(24, 18, 82),
  BoardConfig(24, 19, 84),
  BoardConfig(25, 19, 86),
  BoardConfig(25, 20, 88),
];

final levels = List<LevelDefinition>.unmodifiable([
  for (var i = 0; i < parkStages.length; i++)
    LevelDefinition(
      parkStages[i].number,
      parkStages[i].title,
      parkStages[i].species,
      _configs[i],
      parkStages[i].biome,
      parkStages[i].artAsset,
      parkStages[i].animalMarkerAsset,
    ),
]);

extension LevelTemperament on LevelDefinition {
  AnimalTemperament get temperament =>
      customTemperament ??
      switch (number) {
        6 ||
        7 ||
        8 ||
        9 ||
        10 ||
        13 ||
        25 ||
        34 ||
        37 ||
        38 ||
        39 ||
        40 ||
        44 => AnimalTemperament.curious,
        2 ||
        11 ||
        15 ||
        18 ||
        28 ||
        30 ||
        41 ||
        42 ||
        43 => AnimalTemperament.majestic,
        3 ||
        4 ||
        12 ||
        14 ||
        16 ||
        17 ||
        29 ||
        36 ||
        45 => AnimalTemperament.peaceful,
        5 || 21 || 22 || 23 || 24 || 31 || 33 => AnimalTemperament.adventurous,
        1 || 19 || 20 || 26 || 27 || 32 || 35 => AnimalTemperament.brave,
        _ => throw StateError('Niveau sans tempérament : $number'),
      };
}
