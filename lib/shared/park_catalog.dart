enum LevelBiome {
  savanna,
  tropical,
  riverside,
  woodland,
  steppe,
  mountain,
  tundra,
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

enum AnimalTemperament { curious, majestic, peaceful, adventurous, brave }

abstract interface class ParkStage {
  int get number;
  String get title;
  String get species;
  LevelBiome get biome;
  String? get artAsset;
  String? get animalMarkerAsset;
}

extension ParkStageTemperament on ParkStage {
  AnimalTemperament get temperament => switch (number) {
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
