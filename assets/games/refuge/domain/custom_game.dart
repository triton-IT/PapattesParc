import 'dart:math';

import 'levels.dart';
import 'models.dart';

abstract final class CustomBoardRules {
  static const minWidth = 5;
  static const maxWidth = 25;
  static const minHeight = 5;
  static const maxHeight = 25;
  static const minAnimals = 1;

  static int maxAnimals(int width, int height) => min(99, width * height ~/ 5);
}

final customAnimalTypes = [
  for (final level in levels)
    if (levels.indexWhere((candidate) => candidate.species == level.species) ==
        levels.indexOf(level))
      level,
];

LevelDefinition createCustomLevel(
  LevelDefinition animalType,
  BoardConfig config,
) => LevelDefinition.custom(
  'Refuge personnalisé',
  animalType.species,
  config,
  animalType.biome,
  animalType.artAsset,
  animalType.animalMarkerAsset,
  animalType.temperament,
);
