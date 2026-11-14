import 'dart:math';

import 'sort_food.dart';
import '../../../shared/park_catalog.dart';
import 'models.dart';

List<AnimalSortLevelDefinition> buildAnimalSortCampaign(
  List<ParkStage> stages,
) => [
  for (final stage in stages)
    buildAnimalSortLevel(
      stage,
      speciesCount: _campaignSpeciesCount(stage.number),
      seed: stage.number * 104729,
    ),
];

AnimalSortLevelDefinition buildAnimalSortLevel(
  ParkStage stage, {
  required int speciesCount,
  required int seed,
}) {
  final foodPool = _foodPool(stage.number, stage.biome);
  if (speciesCount < 1 || speciesCount > foodPool.length) {
    throw ArgumentError.value(
      speciesCount,
      'speciesCount',
      'Not enough distinct foods for this level',
    );
  }
  final foods = foodPool.take(speciesCount).toList();
  final zones = <List<SortFood>>[
    for (final animal in foods)
      List<SortFood>.filled(animalSortZoneCapacity, animal, growable: true),
    [],
    [],
  ];
  final random = Random(seed);
  final inverseSolution = <AnimalSortMove>[];
  final visited = {_signature(zones)};
  final target = 10 + speciesCount * 4 + stage.number % 6;

  while (inverseSolution.length < target) {
    final candidates = _inverseCandidates(zones).where((candidate) {
      final next = _copyZones(zones);
      _applyInverse(next, candidate);
      return !visited.contains(_signature(next));
    }).toList();
    if (candidates.isEmpty) break;
    candidates.shuffle(random);
    candidates.sort((a, b) {
      final aScore = _disorderAfter(zones, a);
      final bScore = _disorderAfter(zones, b);
      return bScore.compareTo(aScore);
    });
    final choice = candidates[random.nextInt(min(4, candidates.length))];
    _applyInverse(zones, choice);
    visited.add(_signature(zones));
    inverseSolution.add(AnimalSortMove(choice.to, choice.from));
  }

  return AnimalSortLevelDefinition(
    stage: stage,
    foods: List.unmodifiable(foods),
    initialZones: [for (final zone in zones) List.unmodifiable(zone)],
    referenceSolution: List.unmodifiable(inverseSolution.reversed),
  );
}

int _campaignSpeciesCount(int level) => switch (level) {
  <= 5 => 3,
  <= 15 => 4,
  <= 25 => 5,
  <= 35 => 6,
  <= 40 => 7,
  _ => 8,
};

// Pools describe foods appropriate to at least one species pictured in the
// stage. Order matters: earlier levels show the most representative foods.
// In free play the first stage of the chosen biome supplies the same pool.
List<SortFood> _foodPool(int level, LevelBiome biome) => switch (level) {
  1 => _suricatePorcupine,
  2 || 11 || 15 || 18 || 19 || 28 || 30 || 41 || 42 || 43 => _meat,
  3 => _savannaBrowse,
  4 => _tortoise,
  5 => _savannaGraze,
  6 || 7 || 8 || 38 || 40 => _primate,
  13 => _tamarin,
  9 => _riverAnimals,
  10 || 14 => _mixedTropical,
  44 => _monkeyDeer,
  12 => _wetland,
  16 || 17 || 36 => _browse,
  24 || 31 || 33 => _mountainBrowse,
  29 => _reindeer,
  20 || 26 || 35 => _wolfWolverine,
  21 || 22 || 23 || 45 => _grazers,
  25 || 37 => _redPanda,
  27 || 32 => _bear,
  34 => _mink,
  39 => _squirrel,
  _ => switch (biome) {
    LevelBiome.savanna => _savannaGraze,
    LevelBiome.tropical => _primate,
    LevelBiome.riverside => _riverAnimals,
    LevelBiome.woodland => _browse,
    LevelBiome.steppe || LevelBiome.mountain || LevelBiome.tundra => _grazers,
  },
};

const _meat = [
  SortFood.beef,
  SortFood.poultry,
  SortFood.boar,
  SortFood.ribs,
  SortFood.venison,
  SortFood.mutton,
  SortFood.heart,
  SortFood.meatParcel,
];
const _suricatePorcupine = [
  SortFood.mealworms,
  SortFood.nuts,
  SortFood.desertRoots,
  SortFood.pumpkin,
  SortFood.apple,
  SortFood.acorn,
  SortFood.tropicalFruit,
  SortFood.mountainGrass,
];
const _savannaBrowse = [
  SortFood.acaciaLeaves,
  SortFood.acaciaPods,
  SortFood.savannaGrass,
  SortFood.meadowGrass,
  SortFood.dryGrass,
  SortFood.ryeGrass,
  SortFood.hay,
  SortFood.steppeGrass,
];
const _tortoise = [
  SortFood.dandelion,
  SortFood.meadowGrass,
  SortFood.clover,
  SortFood.savannaGrass,
  SortFood.ryeGrass,
  SortFood.hay,
  SortFood.dryGrass,
  SortFood.oatGrass,
];
const _savannaGraze = [
  SortFood.savannaGrass,
  SortFood.meadowGrass,
  SortFood.acaciaLeaves,
  SortFood.ryeGrass,
  SortFood.hay,
  SortFood.dryGrass,
  SortFood.steppeGrass,
  SortFood.oatGrass,
];
const _primate = [
  SortFood.tropicalFruit,
  SortFood.fig,
  SortFood.apple,
  SortFood.banana,
  SortFood.grapes,
  SortFood.blueberries,
  SortFood.flower,
  SortFood.mealworms,
];
const _tamarin = [
  SortFood.tropicalFruit,
  SortFood.fig,
  SortFood.flower,
  SortFood.mealworms,
  SortFood.apple,
  SortFood.banana,
  SortFood.grapes,
  SortFood.blueberries,
];
const _riverAnimals = [
  SortFood.fig,
  SortFood.tropicalFruit,
  SortFood.crayfish,
  SortFood.smallFish,
  SortFood.apple,
  SortFood.banana,
  SortFood.crab,
  SortFood.shrimp,
];
const _mixedTropical = [
  SortFood.fruitRoots,
  SortFood.cecropia,
  SortFood.mealworms,
  SortFood.tropicalFruit,
  SortFood.fig,
  SortFood.apple,
  SortFood.pumpkin,
  SortFood.nuts,
];
const _wetland = [
  SortFood.meadowGrass,
  SortFood.dandelion,
  SortFood.aquaticGrass,
  SortFood.hay,
  SortFood.clover,
  SortFood.savannaGrass,
  SortFood.ryeGrass,
  SortFood.oatGrass,
];
const _browse = [
  SortFood.meadowGrass,
  SortFood.twigs,
  SortFood.hay,
  SortFood.dandelion,
  SortFood.acorn,
  SortFood.ryeGrass,
  SortFood.orchardGrass,
  SortFood.oatGrass,
];
const _mountainBrowse = [
  SortFood.meadowGrass,
  SortFood.twigs,
  SortFood.hay,
  SortFood.clover,
  SortFood.oatGrass,
  SortFood.dryGrass,
  SortFood.orchardGrass,
  SortFood.hayCube,
];
const _reindeer = [
  SortFood.lichen,
  SortFood.meadowGrass,
  SortFood.twigs,
  SortFood.hay,
  SortFood.mushroom,
  SortFood.dryGrass,
  SortFood.orchardGrass,
  SortFood.oatGrass,
];
const _monkeyDeer = [
  SortFood.tropicalFruit,
  SortFood.fig,
  SortFood.meadowGrass,
  SortFood.twigs,
  SortFood.apple,
  SortFood.banana,
  SortFood.grapes,
  SortFood.blueberries,
];
const _wolfWolverine = [
  SortFood.venison,
  SortFood.boar,
  SortFood.poultry,
  SortFood.ribs,
  SortFood.beef,
  SortFood.mutton,
  SortFood.meatParcel,
  SortFood.heart,
];
const _grazers = [
  SortFood.meadowGrass,
  SortFood.hay,
  SortFood.clover,
  SortFood.dandelion,
  SortFood.oatGrass,
  SortFood.dryGrass,
  SortFood.orchardGrass,
  SortFood.hayCube,
];
// Bamboo is the red panda's principal food; fruit is a supplement.
const _redPanda = [
  SortFood.bambooLeaves,
  SortFood.bambooShoot,
  SortFood.apple,
  SortFood.grapes,
  SortFood.blueberries,
  SortFood.banana,
  SortFood.meadowGrass,
  SortFood.mealworms,
];
const _bear = [
  SortFood.salmonBerries,
  SortFood.fishFillet,
  SortFood.blueberries,
  SortFood.apple,
  SortFood.nuts,
  SortFood.mealworms,
  SortFood.meadowGrass,
  SortFood.venison,
];
const _mink = [
  SortFood.smallFish,
  SortFood.crayfish,
  SortFood.frogLegs,
  SortFood.fishFillet,
  SortFood.crab,
  SortFood.shrimp,
  SortFood.poultry,
  SortFood.meatParcel,
];
const _squirrel = [
  SortFood.nuts,
  SortFood.acorn,
  SortFood.tropicalFruit,
  SortFood.fig,
  SortFood.apple,
  SortFood.grapes,
  SortFood.flower,
  SortFood.banana,
];

List<_InverseMove> _inverseCandidates(List<List<SortFood>> zones) {
  final candidates = <_InverseMove>[];
  final reservedEmpty = zones.length - 1;
  for (var from = 0; from < zones.length; from++) {
    final source = zones[from];
    if (source.isEmpty) continue;
    final animal = source.last;
    final run = _bottomRun(source);
    for (var to = 0; to < zones.length; to++) {
      if (to == from || to == reservedEmpty) continue;
      final destination = zones[to];
      if (destination.length == animalSortZoneCapacity ||
          (destination.isNotEmpty && destination.last == animal)) {
        continue;
      }
      final maximum = min(run, animalSortZoneCapacity - destination.length);
      for (var count = 1; count <= maximum; count++) {
        if (count == run && source.length > run) continue;
        candidates.add(_InverseMove(from, to, count));
      }
    }
  }
  return candidates;
}

int _disorderAfter(List<List<SortFood>> zones, _InverseMove move) {
  final next = _copyZones(zones);
  _applyInverse(next, move);
  var segments = 0;
  var mixed = 0;
  var complete = 0;
  for (final zone in next) {
    if (zone.isEmpty) continue;
    segments++;
    for (var index = 1; index < zone.length; index++) {
      if (zone[index] != zone[index - 1]) segments++;
    }
    if (zone.toSet().length > 1) mixed++;
    if (zone.length == animalSortZoneCapacity && zone.toSet().length == 1) {
      complete++;
    }
  }
  return segments * 3 + mixed * 5 - complete * 4;
}

void _applyInverse(List<List<SortFood>> zones, _InverseMove move) {
  final animal = zones[move.from].last;
  zones[move.from].removeRange(
    zones[move.from].length - move.count,
    zones[move.from].length,
  );
  zones[move.to].addAll(List.filled(move.count, animal));
}

int _bottomRun(List<SortFood> zone) {
  var count = 1;
  while (count < zone.length && zone[zone.length - 1 - count] == zone.last) {
    count++;
  }
  return count;
}

List<List<SortFood>> _copyZones(List<List<SortFood>> zones) => [
  for (final zone in zones) [...zone],
];

String _signature(List<List<SortFood>> zones) =>
    zones.map((zone) => zone.map((animal) => animal.index).join(',')).join('|');

class _InverseMove {
  const _InverseMove(this.from, this.to, this.count);

  final int from;
  final int to;
  final int count;
}
