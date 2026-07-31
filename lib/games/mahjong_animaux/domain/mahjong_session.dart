import 'dart:math';

import '../../../shared/animal_catalog.dart';
import '../../../shared/park_catalog.dart';
import 'models.dart';

class MahjongSession {
  MahjongSession({
    required this.layout,
    required this.biome,
    required this.seed,
  }) : _random = Random(seed) {
    _buildTiles();
  }

  final MahjongLayoutDefinition layout;
  final LevelBiome biome;
  final int seed;
  final Random _random;
  final List<MahjongTile> _tiles = [];
  late final List<bool> _present;
  late List<({int first, int second})> _certifiedOrder;

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
    for (final pair in _certifiedOrder) {
      if (_present[pair.first] &&
          _present[pair.second] &&
          _isFree(pair.first, _present) &&
          _isFree(pair.second, _present) &&
          _tiles[pair.first].animal == _tiles[pair.second].animal) {
        return pair;
      }
    }
    return availablePair;
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
    final order = _removalOrder(_present);
    if (order == null) return false;
    _certifiedOrder = order;
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
    selectedId = null;
    shufflesRemaining--;
    shufflesUsed++;
    return true;
  }

  void _buildTiles() {
    _present = List.filled(layout.tileCount, true);
    final order = _removalOrder(_present)!;
    _certifiedOrder = order;
    final pool = animalsByBiome[biome]!.take(layout.speciesCount).toList();
    final pairAnimals = [
      for (var index = 0; index < order.length; index++)
        pool[index % pool.length],
    ]..shuffle(_random);
    _tiles.addAll([
      for (var id = 0; id < layout.positions.length; id++)
        MahjongTile(
          id: id,
          position: layout.positions[id],
          animal: AnimalKind.suricate,
        ),
    ]);
    for (var index = 0; index < order.length; index++) {
      final pair = order[index];
      for (final id in [pair.first, pair.second]) {
        _tiles[id] = MahjongTile(
          id: id,
          position: _tiles[id].position,
          animal: pairAnimals[index],
        );
      }
    }
  }

  List<({int first, int second})>? _removalOrder(List<bool> source) {
    final present = List<bool>.from(source);
    final order = <({int first, int second})>[];
    bool search() {
      final free =
          [
            for (var id = 0; id < present.length; id++)
              if (present[id] && _isFree(id, present)) id,
          ]..sort((first, second) {
            final layer = _tilesOrPosition(
              second,
            ).layer.compareTo(_tilesOrPosition(first).layer);
            return layer != 0 ? layer : first.compareTo(second);
          });
      if (free.isEmpty) return true;
      if (free.length < 2) return false;
      final first = free.first;
      for (final second in free.skip(1).toList().reversed) {
        present[first] = false;
        present[second] = false;
        order.add((first: first, second: second));
        if (search()) return true;
        order.removeLast();
        present[first] = true;
        present[second] = true;
      }
      return false;
    }

    return search() ? order : null;
  }

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
