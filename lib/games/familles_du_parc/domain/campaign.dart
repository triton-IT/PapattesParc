import 'dart:math';

import '../../../shared/animal_catalog.dart';
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
  final offset = seed.abs() % foodPool.length;
  final animals = [
    for (var index = 0; index < speciesCount; index++)
      foodPool[(offset + index) % foodPool.length],
  ];
  final zones = <List<AnimalKind>>[
    for (final animal in animals)
      List<AnimalKind>.filled(animalSortZoneCapacity, animal, growable: true),
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
    animals: List.unmodifiable(animals),
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

List<AnimalKind> _foodPool(int level, LevelBiome biome) => switch (level) {
  1 => _suricateFoods,
  2 || 11 => _lionFoods,
  3 => _savannaBrowse,
  4 => _tortoiseFoods,
  5 => _savannaGraze,
  6 => _primateFoods,
  7 || 8 => _gibbonFoods,
  9 => _riverPrimateFoods,
  10 => _smallOmnivoreFoods,
  12 => _wetlandHerbivoreFoods,
  13 => _tamarinFoods,
  14 => _southAmericaFoods,
  15 || 18 => _tigerFoods,
  16 => _woodlandHerbivoreFoods,
  17 => _deerFoods,
  19 || 26 => _wolfFoods,
  20 || 35 => _wolverineFoods,
  21 => _mountainHerbivoreFoods,
  22 || 23 => _steppeFoods,
  24 => _tahrFoods,
  25 || 37 => _redPandaFoods,
  27 || 32 => _bearFoods,
  28 || 30 => _leopardFoods,
  29 => _reindeerFoods,
  31 => _urialFoods,
  33 => _markhorFoods,
  34 => _otterFoods,
  36 => _deerFoods,
  38 => _lemurFoods,
  39 => _squirrelFoods,
  40 || 44 => _primateFoods,
  41 => _snowLeopardFoods,
  42 || 43 => _cheetahFoods,
  45 => _alpacaFoods,
  _ => animalsByBiome[biome]!,
};

const _plantFoods = [
  AnimalKind.girafe,
  AnimalKind.zebre,
  AnimalKind.addax,
  AnimalKind.gibbon,
  AnimalKind.paresseux,
  AnimalKind.tamarin,
  AnimalKind.lemurien,
  AnimalKind.hippopotame,
  AnimalKind.capybara,
  AnimalKind.tortue,
  AnimalKind.tapir,
  AnimalKind.pandaRoux,
  AnimalKind.cerfSika,
  AnimalKind.kulan,
  AnimalKind.renne,
  AnimalKind.oryx,
  AnimalKind.gazelle,
  AnimalKind.cerfCochon,
  AnimalKind.goral,
  AnimalKind.tahr,
  AnimalKind.markhor,
  AnimalKind.alpaga,
  AnimalKind.urial,
];
const _meatFoods = [
  AnimalKind.lion,
  AnimalKind.guepard,
  AnimalKind.tigre,
  AnimalKind.loup,
  AnimalKind.glouton,
  AnimalKind.panthereNeiges,
  AnimalKind.panthereAmour,
  AnimalKind.vison,
  AnimalKind.loutre,
  AnimalKind.ours,
];
const _suricateFoods = [
  AnimalKind.suricate,
  AnimalKind.saimiri,
  AnimalKind.tapir,
  AnimalKind.cerfSika,
  AnimalKind.lemurien,
  AnimalKind.tortue,
  AnimalKind.atele,
  AnimalKind.gibbon,
];
const _lionFoods = _meatFoods;
const _savannaBrowse = [
  AnimalKind.girafe,
  AnimalKind.gazelle,
  AnimalKind.addax,
  AnimalKind.oryx,
  AnimalKind.zebre,
  AnimalKind.kulan,
  AnimalKind.cerfSika,
  AnimalKind.capybara,
];
const _tortoiseFoods = [
  AnimalKind.tortue,
  AnimalKind.capybara,
  AnimalKind.tapir,
  AnimalKind.paresseux,
  AnimalKind.girafe,
  AnimalKind.gazelle,
  AnimalKind.addax,
  AnimalKind.tamarin,
];
const _savannaGraze = _savannaBrowse;
const _primateFoods = [
  AnimalKind.atele,
  AnimalKind.gibbon,
  AnimalKind.lemurien,
  AnimalKind.saimiri,
  AnimalKind.tamarin,
  AnimalKind.tapir,
  AnimalKind.pandaRoux,
  AnimalKind.suricate,
];
const _gibbonFoods = _primateFoods;
const _riverPrimateFoods = [
  AnimalKind.gibbon,
  AnimalKind.loutre,
  AnimalKind.vison,
  AnimalKind.atele,
  AnimalKind.saimiri,
  AnimalKind.lemurien,
  AnimalKind.tamarin,
  AnimalKind.tapir,
];
const _smallOmnivoreFoods = [
  AnimalKind.tamarin,
  AnimalKind.suricate,
  AnimalKind.paresseux,
  AnimalKind.saimiri,
  AnimalKind.cerfSika,
  AnimalKind.tapir,
  AnimalKind.lemurien,
  AnimalKind.tortue,
];
const _wetlandHerbivoreFoods = [
  AnimalKind.hippopotame,
  AnimalKind.tortue,
  AnimalKind.capybara,
  AnimalKind.cerfCochon,
  AnimalKind.tapir,
  AnimalKind.paresseux,
  AnimalKind.girafe,
  AnimalKind.addax,
];
const _tamarinFoods = _primateFoods;
const _southAmericaFoods = [
  AnimalKind.tapir,
  AnimalKind.capybara,
  AnimalKind.cerfSika,
  AnimalKind.suricate,
  AnimalKind.atele,
  AnimalKind.tortue,
  AnimalKind.lemurien,
  AnimalKind.gibbon,
];
const _tigerFoods = _meatFoods;
const _woodlandHerbivoreFoods = _plantFoods;
const _deerFoods = _plantFoods;
const _wolfFoods = _meatFoods;
const _wolverineFoods = [
  AnimalKind.glouton,
  AnimalKind.loup,
  AnimalKind.panthereAmour,
  AnimalKind.vison,
  AnimalKind.ours,
  AnimalKind.tigre,
  AnimalKind.guepard,
  AnimalKind.lion,
];
const _mountainHerbivoreFoods = _plantFoods;
const _steppeFoods = _plantFoods;
const _tahrFoods = _plantFoods;
const _redPandaFoods = [
  AnimalKind.pandaRoux,
  AnimalKind.atele,
  AnimalKind.gibbon,
  AnimalKind.tapir,
  AnimalKind.tamarin,
  AnimalKind.lemurien,
  AnimalKind.paresseux,
  AnimalKind.cerfSika,
];
const _bearFoods = [
  AnimalKind.ours,
  AnimalKind.vison,
  AnimalKind.atele,
  AnimalKind.tapir,
  AnimalKind.glouton,
  AnimalKind.cerfSika,
  AnimalKind.suricate,
  AnimalKind.loutre,
];
const _leopardFoods = _meatFoods;
const _reindeerFoods = _plantFoods;
const _urialFoods = _plantFoods;
const _markhorFoods = _plantFoods;
const _otterFoods = [
  AnimalKind.loutre,
  AnimalKind.vison,
  AnimalKind.ours,
  AnimalKind.suricate,
  AnimalKind.saimiri,
  AnimalKind.hippopotame,
  AnimalKind.capybara,
  AnimalKind.tortue,
];
const _lemurFoods = _primateFoods;
const _squirrelFoods = [
  AnimalKind.cerfSika,
  AnimalKind.saimiri,
  AnimalKind.atele,
  AnimalKind.gibbon,
  AnimalKind.lemurien,
  AnimalKind.tamarin,
  AnimalKind.gazelle,
  AnimalKind.tapir,
];
const _snowLeopardFoods = _meatFoods;
const _cheetahFoods = _meatFoods;
const _alpacaFoods = _plantFoods;

List<_InverseMove> _inverseCandidates(List<List<AnimalKind>> zones) {
  final candidates = <_InverseMove>[];
  final reservedEmpty = zones.length - 1;
  for (var from = 0; from < zones.length; from++) {
    final source = zones[from];
    if (source.isEmpty) continue;
    final animal = source.last;
    final run = _topRun(source);
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

int _disorderAfter(List<List<AnimalKind>> zones, _InverseMove move) {
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

void _applyInverse(List<List<AnimalKind>> zones, _InverseMove move) {
  final animal = zones[move.from].last;
  zones[move.from].removeRange(
    zones[move.from].length - move.count,
    zones[move.from].length,
  );
  zones[move.to].addAll(List.filled(move.count, animal));
}

int _topRun(List<AnimalKind> zone) {
  var count = 1;
  while (count < zone.length && zone[zone.length - 1 - count] == zone.last) {
    count++;
  }
  return count;
}

List<List<AnimalKind>> _copyZones(List<List<AnimalKind>> zones) => [
  for (final zone in zones) [...zone],
];

String _signature(List<List<AnimalKind>> zones) =>
    zones.map((zone) => zone.map((animal) => animal.index).join(',')).join('|');

class _InverseMove {
  const _InverseMove(this.from, this.to, this.count);

  final int from;
  final int to;
  final int count;
}
