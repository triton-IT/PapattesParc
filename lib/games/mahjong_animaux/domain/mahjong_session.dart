import 'dart:math';

import '../../../shared/animal_catalog.dart';
import '../../../shared/park_catalog.dart';
import 'mahjong_generator.dart';
import 'mahjong_solver.dart';
import 'models.dart';

class MahjongSession {
  MahjongSession({
    required this.layout,
    required this.biome,
    required this.seed,
    PreparedMahjongDeal? prepared,
  }) : _random = Random(seed) {
    _buildTiles(prepared);
  }

  final MahjongLayoutDefinition layout;
  final LevelBiome biome;
  final int seed;
  final Random _random;
  final List<MahjongTile> _tiles = [];
  late final List<bool> _present;
  late List<MahjongPair> _solution;
  late final int complexity;

  MahjongStatus status = MahjongStatus.playing;
  Duration elapsed = Duration.zero;
  int shufflesRemaining = 3;
  int shufflesUsed = 0;
  int? selectedId;

  int get remainingPairs => _present.where((present) => present).length ~/ 2;
  bool get hasMoved =>
      remainingPairs * 2 != layout.tileCount || shufflesUsed > 0;
  bool get isBlocked =>
      availablePair == null && status == MahjongStatus.playing;
  int get footprints => shufflesUsed == 0
      ? 3
      : shufflesUsed == 1
      ? 2
      : 1;

  Iterable<MahjongTileSnapshot> get tiles sync* {
    for (var id = 0; id < _tiles.length; id++) {
      yield snapshot(id);
    }
  }

  MahjongTileSnapshot snapshot(int id) => MahjongTileSnapshot(
    tile: _tiles[id],
    isPresent: _present[id],
    isFree: _present[id] && _isFree(id, _present),
  );

  void tick(Duration delta) {
    if (status == MahjongStatus.playing) elapsed += delta;
  }

  MahjongSelectionResult select(int id) {
    if (status != MahjongStatus.playing ||
        !_present[id] ||
        !_isFree(id, _present)) {
      return MahjongSelectionResult.ignored;
    }
    if (selectedId == id) {
      selectedId = null;
      return MahjongSelectionResult.deselected;
    }
    final selected = selectedId;
    if (selected == null) {
      selectedId = id;
      return MahjongSelectionResult.selected;
    }
    if (_tiles[selected].animal != _tiles[id].animal) {
      selectedId = id;
      return MahjongSelectionResult.replaced;
    }
    _present[selected] = false;
    _present[id] = false;
    final solutionIndex = _solution.indexWhere(
      (pair) => _samePair(pair, selected, id),
    );
    if (solutionIndex < 0) {
      _solution.clear();
    } else {
      _solution.removeAt(solutionIndex);
    }
    selectedId = null;
    if (remainingPairs == 0) {
      status = MahjongStatus.won;
      return MahjongSelectionResult.won;
    }
    if (availablePair == null && shufflesRemaining == 0) {
      status = MahjongStatus.lost;
      return MahjongSelectionResult.lost;
    }
    return MahjongSelectionResult.matched;
  }

  ({int first, int second})? hint() {
    if (_solution.isNotEmpty) return _solution.first;
    final solution = MahjongSolver(layout.positions, [
      for (final tile in _tiles) tile.animal.index,
    ]).solve(_present, maxStates: 20000);
    if (solution == null) return availablePair;
    _solution = solution.moves;
    return _solution.firstOrNull;
  }

  ({int first, int second})? get availablePair {
    final free = [
      for (var id = 0; id < _tiles.length; id++)
        if (_present[id] && _isFree(id, _present)) id,
    ];
    for (var first = 0; first < free.length; first++) {
      for (var second = first + 1; second < free.length; second++) {
        if (_tiles[free[first]].animal == _tiles[free[second]].animal) {
          return (first: free[first], second: free[second]);
        }
      }
    }
    return null;
  }

  bool shuffle() {
    if (status != MahjongStatus.playing || shufflesRemaining == 0) return false;
    final order = MahjongSolver(
      layout.positions,
      List.filled(layout.tileCount, 0),
    ).geometricRemovalOrder(_present);
    if (order.isEmpty) return false;
    final animals = <AnimalKind>[];
    for (var id = 0; id < _tiles.length; id++) {
      if (_present[id]) animals.add(_tiles[id].animal);
    }
    final pairs = <AnimalKind>[];
    for (final animal in AnimalKind.values) {
      final count = animals.where((item) => item == animal).length;
      for (var pair = 0; pair < count ~/ 2; pair++) {
        pairs.add(animal);
      }
    }
    pairs.shuffle(_random);
    for (var index = 0; index < order.length; index++) {
      final pair = order[index];
      final animal = pairs[index];
      _tiles[pair.first] = MahjongTile(
        id: pair.first,
        position: _tiles[pair.first].position,
        animal: animal,
      );
      _tiles[pair.second] = MahjongTile(
        id: pair.second,
        position: _tiles[pair.second].position,
        animal: animal,
      );
    }
    _solution = order;
    selectedId = null;
    shufflesRemaining--;
    shufflesUsed++;
    return true;
  }

  void _buildTiles(PreparedMahjongDeal? prepared) {
    _present = List.filled(layout.tileCount, true);
    final preferred = animalsByBiome[biome]!;
    final pool = [
      ...preferred,
      ...AnimalKind.values.where((animal) => !preferred.contains(animal)),
    ].take(layout.speciesCount).toList();
    late final MahjongDeal deal;
    if (prepared == null) {
      deal = MahjongGenerator(
        layout: layout,
        animals: pool,
        random: _random,
      ).generate();
    } else {
      for (final call in prepared.randomCalls) {
        if (call == -1) {
          _random.nextDouble();
        } else if (call == -2) {
          _random.nextBool();
        } else {
          _random.nextInt(call);
        }
      }
      deal = prepared.deal;
    }
    complexity = deal.complexity;
    _solution = List.of(deal.solution);
    _tiles.addAll([
      for (var id = 0; id < layout.positions.length; id++)
        MahjongTile(
          id: id,
          position: layout.positions[id],
          animal: deal.animals[id],
        ),
    ]);
  }

  bool _samePair(MahjongPair pair, int first, int second) =>
      pair.first == first && pair.second == second ||
      pair.first == second && pair.second == first;

  MahjongPosition _tilesOrPosition(int id) =>
      _tiles.isEmpty ? layout.positions[id] : _tiles[id].position;

  bool _isFree(int id, List<bool> present) {
    final position = _tilesOrPosition(id);
    var leftBlocked = false;
    var rightBlocked = false;
    for (var otherId = 0; otherId < present.length; otherId++) {
      if (otherId == id || !present[otherId]) continue;
      final other = _tilesOrPosition(otherId);
      if (other.layer > position.layer &&
          (other.x - position.x).abs() < 2 &&
          (other.y - position.y).abs() < 2) {
        return false;
      }
      if (other.layer != position.layer || (other.y - position.y).abs() >= 2) {
        continue;
      }
      if (other.x == position.x - 2) leftBlocked = true;
      if (other.x == position.x + 2) rightBlocked = true;
    }
    return !leftBlocked || !rightBlocked;
  }
}
