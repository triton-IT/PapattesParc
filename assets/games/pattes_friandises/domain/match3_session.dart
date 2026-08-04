import 'dart:math';

import 'models.dart';

class Match3Session {
  Match3Session(this.level, int seed) : _random = Random(seed) {
    _inactive.addAll(level.inactiveCells.map(_index));
    for (final placement in level.blockers) {
      final index = _index(placement.position);
      _blockers[index] = placement.kind;
      _blockerLayers[index] = placement.layers;
    }
    _buildBoard();
  }

  static const size = 8;

  final Match3LevelDefinition level;
  final Random _random;
  final List<Match3Tile?> _tiles = List.filled(size * size, null);
  final List<BlockerKind?> _blockers = List.filled(size * size, null);
  final List<int> _blockerLayers = List.filled(size * size, 0);
  final Set<int> _inactive = {};
  late final List<int> _goalProgress = List.filled(level.goals.length, 0);

  Match3Status status = Match3Status.playing;
  late int movesLeft = level.moves;
  int score = 0;

  int goalProgress(int index) => _goalProgress[index];

  int footprintsForScore() {
    if (status != Match3Status.won) return 0;
    if (score >= level.threeFootprints) return 3;
    if (score >= level.twoFootprints) return 2;
    return 1;
  }

  Match3CellSnapshot cell(Match3Position position) {
    final index = _index(position);
    return Match3CellSnapshot(
      tile: _tiles[index],
      blocker: _blockers[index],
      blockerLayers: _blockerLayers[index],
      isActive: !_inactive.contains(index),
    );
  }

  bool get hasMatches => _findMatches().isNotEmpty;
  bool get hasAvailableMove => _hasAvailableMove();
  bool canMove(Match3Position position) => _canMove(_index(position));

  Match3MoveResult swap(Match3Position first, Match3Position second) {
    if (status != Match3Status.playing || !_areAdjacent(first, second)) {
      return const Match3MoveResult(changed: false, reshuffled: false);
    }
    final firstIndex = _index(first);
    final secondIndex = _index(second);
    if (!_canMove(firstIndex) || !_canMove(secondIndex)) {
      return const Match3MoveResult(changed: false, reshuffled: false);
    }
    final firstTile = _tiles[firstIndex]!;
    final secondTile = _tiles[secondIndex]!;
    _swap(firstIndex, secondIndex);

    final matches = _findMatches();
    final combinesSpecials =
        firstTile.special != SpecialKind.none &&
        secondTile.special != SpecialKind.none;
    if (matches.isEmpty && !combinesSpecials) {
      _swap(firstIndex, secondIndex);
      return const Match3MoveResult(changed: false, reshuffled: false);
    }

    movesLeft--;
    final initial = _snapshot();
    final steps = combinesSpecials
        ? _resolveSpecialCombination(firstIndex, secondIndex)
        : _resolve(matches, secondIndex);
    _finishTurn();
    final reshuffled = status == Match3Status.playing && !_hasAvailableMove();
    if (reshuffled) _reshuffle();
    steps[steps.length - 1] = Match3ResolutionStep(
      cascade: steps.last.cascade,
      cleared: steps.last.cleared,
      result: _snapshot(),
    );
    return Match3MoveResult(
      changed: true,
      reshuffled: reshuffled,
      initial: initial,
      steps: List.unmodifiable(steps),
    );
  }

  void _buildBoard() {
    for (var attempt = 0; attempt < 200; attempt++) {
      _fillWithoutMatches();
      _placeBaskets();
      if (_findMatches().isEmpty && _hasAvailableMove()) return;
    }
    throw StateError('Impossible de créer un plateau jouable.');
  }

  void _fillWithoutMatches() {
    for (var index = 0; index < _tiles.length; index++) {
      if (_inactive.contains(index)) {
        _tiles[index] = null;
        continue;
      }
      final forbidden = <AnimalKind>{};
      final x = index % size;
      final y = index ~/ size;
      if (x >= 2 &&
          _tiles[index - 1] != null &&
          _tiles[index - 1]?.animal == _tiles[index - 2]?.animal) {
        forbidden.add(_tiles[index - 1]!.animal);
      }
      if (y >= 2 &&
          _tiles[index - size] != null &&
          _tiles[index - size]?.animal == _tiles[index - size * 2]?.animal) {
        forbidden.add(_tiles[index - size]!.animal);
      }
      final choices = level.animals
          .where((animal) => !forbidden.contains(animal))
          .toList();
      _tiles[index] = Match3Tile(
        animal: choices[_random.nextInt(choices.length)],
      );
    }
  }

  void _placeBaskets() {
    for (final column in level.basketColumns) {
      for (var y = 0; y < size; y++) {
        final index = y * size + column;
        if (_inactive.contains(index)) continue;
        _tiles[index] = const Match3Tile.basket();
        break;
      }
    }
  }

  List<Match3ResolutionStep> _resolve(Set<int> matches, int preferred) {
    final steps = <Match3ResolutionStep>[];
    var cascade = 1;
    var current = matches;
    var specialPreference = preferred;
    while (current.isNotEmpty) {
      final specials = _specialsFor(current, specialPreference);
      final specialAnimals = {
        for (final entry in specials.entries)
          entry.key: _tiles[entry.key]!.animal,
      };
      final clear = _expandSpecials(current);
      final clearedIndexes = <int>{};
      var clearedAnimals = 0;
      for (final index in clear) {
        final tile = _tiles[index];
        if (tile == null || tile.isBasket) continue;
        _damageBlocker(index);
        if (_blockers[index] == BlockerKind.vines) continue;
        _collectAnimal(tile.animal);
        _tiles[index] = null;
        clearedIndexes.add(index);
        clearedAnimals++;
      }
      _damageAdjacentBlockers(clear);
      for (final entry in specials.entries) {
        if (_inactive.contains(entry.key)) continue;
        _tiles[entry.key] = Match3Tile(
          animal: specialAnimals[entry.key]!,
          special: entry.value,
        );
      }
      score +=
          clearedAnimals * 100 * min(cascade, 5).toInt() +
          specials.length * 300;
      _applyGravity();
      _deliverBaskets();
      _fillEmptyCells();
      steps.add(
        Match3ResolutionStep(
          cascade: cascade,
          cleared: {
            for (final index in clearedIndexes)
              Match3Position(index % size, index ~/ size),
          },
          result: _snapshot(),
        ),
      );
      current = _findMatches();
      specialPreference = -1;
      cascade++;
    }
    return steps;
  }

  List<Match3ResolutionStep> _resolveSpecialCombination(int first, int second) {
    final firstTile = _tiles[first]!;
    final secondTile = _tiles[second]!;
    final clear = <int>{};
    if (firstTile.special == SpecialKind.goldenPaw &&
        secondTile.special == SpecialKind.goldenPaw) {
      clear.addAll(_activeTileIndexes);
    } else if (firstTile.special == SpecialKind.goldenPaw) {
      clear.addAll(_indexesForAnimal(secondTile.animal));
      clear.addAll(_specialTargets(second, secondTile));
    } else if (secondTile.special == SpecialKind.goldenPaw) {
      clear.addAll(_indexesForAnimal(firstTile.animal));
      clear.addAll(_specialTargets(first, firstTile));
    } else {
      clear.addAll(_specialTargets(first, firstTile));
      clear.addAll(_specialTargets(second, secondTile));
    }
    _tiles[first] = Match3Tile(animal: firstTile.animal);
    _tiles[second] = Match3Tile(animal: secondTile.animal);
    return _resolve(clear, -1);
  }

  Set<int> _expandSpecials(Set<int> initial) {
    final clear = {...initial};
    final pending = [...initial];
    final triggered = <int>{};
    while (pending.isNotEmpty) {
      final index = pending.removeLast();
      final tile = _tiles[index];
      if (tile == null ||
          tile.special == SpecialKind.none ||
          !triggered.add(index)) {
        continue;
      }
      final targets = _specialTargets(index, tile);
      for (final target in targets) {
        if (clear.add(target)) pending.add(target);
      }
      score += 300;
    }
    return clear;
  }

  Set<int> _specialTargets(int index, Match3Tile tile) {
    final x = index % size;
    final y = index ~/ size;
    return switch (tile.special) {
      SpecialKind.horizontalBinoculars => {
        for (var column = 0; column < size; column++)
          if (!_inactive.contains(y * size + column)) y * size + column,
      },
      SpecialKind.verticalBinoculars => {
        for (var row = 0; row < size; row++)
          if (!_inactive.contains(row * size + x)) row * size + x,
      },
      SpecialKind.basketBlast => {
        for (var row = max(0, y - 1); row <= min(size - 1, y + 1); row++)
          for (
            var column = max(0, x - 1);
            column <= min(size - 1, x + 1);
            column++
          )
            if (!_inactive.contains(row * size + column)) row * size + column,
      },
      SpecialKind.goldenPaw => _indexesForAnimal(tile.animal).toSet(),
      SpecialKind.none => {index},
    };
  }

  Map<int, SpecialKind> _specialsFor(Set<int> matches, int preferred) {
    final candidates = preferred >= 0 && matches.contains(preferred)
        ? [preferred, ...matches.where((index) => index != preferred)]
        : matches.toList();
    for (final index in candidates) {
      final horizontal = _runLength(index, 1, 0);
      final vertical = _runLength(index, 0, 1);
      if (horizontal >= 5 || vertical >= 5) {
        return {index: SpecialKind.goldenPaw};
      }
      if (horizontal >= 3 && vertical >= 3) {
        return {index: SpecialKind.basketBlast};
      }
      if (horizontal == 4) {
        return {index: SpecialKind.horizontalBinoculars};
      }
      if (vertical == 4) {
        return {index: SpecialKind.verticalBinoculars};
      }
    }
    return const {};
  }

  int _runLength(int index, int dx, int dy) {
    final tile = _tiles[index];
    if (tile == null || tile.isBasket) return 0;
    var length = 1;
    for (final direction in [-1, 1]) {
      var x = index % size + dx * direction;
      var y = index ~/ size + dy * direction;
      while (x >= 0 && x < size && y >= 0 && y < size) {
        final next = _tiles[y * size + x];
        if (next == null || next.isBasket || next.animal != tile.animal) break;
        length++;
        x += dx * direction;
        y += dy * direction;
      }
    }
    return length;
  }

  Set<int> _findMatches() {
    final matches = <int>{};
    for (var y = 0; y < size; y++) {
      var start = 0;
      while (start < size) {
        final first = _matchableTile(y * size + start);
        var end = start + 1;
        while (end < size &&
            first != null &&
            !first.isBasket &&
            _matchableTile(y * size + end)?.animal == first.animal &&
            !_matchableTile(y * size + end)!.isBasket) {
          end++;
        }
        if (first != null && !first.isBasket && end - start >= 3) {
          for (var x = start; x < end; x++) {
            matches.add(y * size + x);
          }
        }
        start = end;
      }
    }
    for (var x = 0; x < size; x++) {
      var start = 0;
      while (start < size) {
        final first = _matchableTile(start * size + x);
        var end = start + 1;
        while (end < size &&
            first != null &&
            !first.isBasket &&
            _matchableTile(end * size + x)?.animal == first.animal &&
            !_matchableTile(end * size + x)!.isBasket) {
          end++;
        }
        if (first != null && !first.isBasket && end - start >= 3) {
          for (var y = start; y < end; y++) {
            matches.add(y * size + x);
          }
        }
        start = end;
      }
    }
    return matches;
  }

  Match3Tile? _matchableTile(int index) =>
      _blockers[index] == BlockerKind.leaves ? null : _tiles[index];

  void _damageBlocker(int index) {
    if (_blockerLayers[index] == 0) return;
    _blockerLayers[index]--;
    _advanceGoal(Match3GoalKind.clearBlockers);
    if (_blockerLayers[index] == 0) _blockers[index] = null;
    score += 250;
  }

  void _damageAdjacentBlockers(Set<int> clear) {
    for (final index in clear) {
      for (final neighbour in _neighbours(index)) {
        if (_blockers[neighbour] != BlockerKind.leaves &&
            _blockers[neighbour] != BlockerKind.vines) {
          continue;
        }
        _damageBlocker(neighbour);
      }
    }
  }

  void _collectAnimal(AnimalKind animal) {
    for (var i = 0; i < level.goals.length; i++) {
      final goal = level.goals[i];
      if (goal.kind == Match3GoalKind.collectAnimal && goal.animal == animal) {
        _goalProgress[i] = min(goal.target, _goalProgress[i] + 1);
      }
    }
  }

  void _advanceGoal(Match3GoalKind kind) {
    for (var i = 0; i < level.goals.length; i++) {
      final goal = level.goals[i];
      if (goal.kind == kind) {
        _goalProgress[i] = min(goal.target, _goalProgress[i] + 1);
      }
    }
  }

  void _applyGravity() {
    for (var x = 0; x < size; x++) {
      final activeRows = [
        for (var y = size - 1; y >= 0; y--)
          if (!_inactive.contains(y * size + x)) y,
      ];
      final tiles = [
        for (final y in activeRows)
          if (_tiles[y * size + x] != null) _tiles[y * size + x]!,
      ];
      for (var i = 0; i < activeRows.length; i++) {
        _tiles[activeRows[i] * size + x] = i < tiles.length ? tiles[i] : null;
      }
    }
  }

  void _deliverBaskets() {
    for (var x = 0; x < size; x++) {
      for (var y = size - 1; y >= 0; y--) {
        final index = y * size + x;
        if (_inactive.contains(index)) continue;
        if (_tiles[index]?.isBasket == true) {
          _tiles[index] = null;
          _advanceGoal(Match3GoalKind.deliverBaskets);
          score += 500;
        }
        break;
      }
    }
    _applyGravity();
  }

  void _fillEmptyCells() {
    for (var index = 0; index < _tiles.length; index++) {
      if (_inactive.contains(index) || _tiles[index] != null) continue;
      _tiles[index] = Match3Tile(
        animal: level.animals[_random.nextInt(level.animals.length)],
      );
    }
  }

  void _finishTurn() {
    if (_goalsComplete) {
      score += movesLeft * 1000;
      status = Match3Status.won;
      return;
    }
    if (movesLeft == 0) status = Match3Status.lost;
  }

  bool get _goalsComplete {
    for (var i = 0; i < level.goals.length; i++) {
      if (_goalProgress[i] < level.goals[i].target) return false;
    }
    return true;
  }

  bool _hasAvailableMove() {
    for (var index = 0; index < _tiles.length; index++) {
      if (!_canMove(index)) continue;
      final x = index % size;
      final y = index ~/ size;
      for (final next in [
        if (x + 1 < size) index + 1,
        if (y + 1 < size) index + size,
      ]) {
        if (!_canMove(next)) continue;
        final firstSpecial = _tiles[index]!.special;
        final secondSpecial = _tiles[next]!.special;
        if (firstSpecial != SpecialKind.none &&
            secondSpecial != SpecialKind.none) {
          return true;
        }
        _swap(index, next);
        final matches = _findMatches().isNotEmpty;
        _swap(index, next);
        if (matches) return true;
      }
    }
    return false;
  }

  void _reshuffle() {
    final indexes = [
      for (final index in _activeTileIndexes)
        if (_tiles[index]?.isBasket == false) index,
    ];
    final tiles = [for (final index in indexes) _tiles[index]!];
    for (var attempt = 0; attempt < 200; attempt++) {
      tiles.shuffle(_random);
      for (var i = 0; i < indexes.length; i++) {
        _tiles[indexes[i]] = tiles[i];
      }
      if (_findMatches().isEmpty && _hasAvailableMove()) return;
    }
    _buildBoard();
  }

  Iterable<int> get _activeTileIndexes sync* {
    for (var index = 0; index < _tiles.length; index++) {
      if (!_inactive.contains(index) && _tiles[index] != null) yield index;
    }
  }

  Iterable<int> _indexesForAnimal(AnimalKind animal) sync* {
    for (final index in _activeTileIndexes) {
      final tile = _tiles[index]!;
      if (!tile.isBasket && tile.animal == animal) yield index;
    }
  }

  Iterable<int> _neighbours(int index) sync* {
    final x = index % size;
    final y = index ~/ size;
    if (x > 0) yield index - 1;
    if (x + 1 < size) yield index + 1;
    if (y > 0) yield index - size;
    if (y + 1 < size) yield index + size;
  }

  bool _canMove(int index) =>
      !_inactive.contains(index) &&
      _tiles[index] != null &&
      !_tiles[index]!.isBasket &&
      _blockers[index] != BlockerKind.leaves &&
      _blockers[index] != BlockerKind.vines;

  bool _areAdjacent(Match3Position first, Match3Position second) =>
      (first.x - second.x).abs() + (first.y - second.y).abs() == 1;

  int _index(Match3Position position) => position.y * size + position.x;

  void _swap(int first, int second) {
    final tile = _tiles[first];
    _tiles[first] = _tiles[second];
    _tiles[second] = tile;
  }

  Match3BoardSnapshot _snapshot() => Match3BoardSnapshot(
    cells: List.unmodifiable([
      for (var index = 0; index < _tiles.length; index++)
        Match3CellSnapshot(
          tile: _tiles[index],
          blocker: _blockers[index],
          blockerLayers: _blockerLayers[index],
          isActive: !_inactive.contains(index),
        ),
    ]),
    goalProgress: List.unmodifiable(_goalProgress),
    score: score,
    status: status,
  );
}
