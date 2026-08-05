import 'dart:math';

import 'package:meta/meta.dart';

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

  @visibleForTesting
  factory Match3Session.forTesting(
    Match3LevelDefinition level,
    int seed,
    List<Match3Tile?> tiles,
  ) {
    final session = Match3Session(level, seed);
    session._tiles.setAll(0, tiles);
    return session;
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

  bool get hasMatches => _analyzeMatches().isNotEmpty;
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

    final matches = _analyzeMatches();
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
        : _resolve(matches, [secondIndex, firstIndex]);
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
      if (_analyzeMatches().isEmpty && _hasAvailableMove()) return;
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
      if (x > 0 &&
          y > 0 &&
          _tiles[index - 1]?.animal == _tiles[index - size]?.animal &&
          _tiles[index - 1]?.animal == _tiles[index - size - 1]?.animal) {
        forbidden.add(_tiles[index - 1]!.animal);
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

  List<Match3ResolutionStep> _resolve(
    _MatchAnalysis initial,
    List<int> preferred,
  ) {
    final steps = <Match3ResolutionStep>[];
    var cascade = 1;
    var analysis = initial;
    var specialPreference = preferred;
    while (analysis.isNotEmpty) {
      final specials = _specialsFor(analysis, specialPreference);
      final specialAnimals = {
        for (final entry in specials.entries)
          entry.key: _tiles[entry.key]!.animal,
      };
      final clear = _expandSpecials(analysis.cells);
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
      analysis = _analyzeMatches();
      specialPreference = const [];
      cascade++;
    }
    return steps;
  }

  List<Match3ResolutionStep> _resolveSpecialCombination(int first, int second) {
    final firstTile = _tiles[first]!;
    final secondTile = _tiles[second]!;
    final clear = <int>{first, second};
    if (firstTile.special == SpecialKind.goldenPaw &&
        secondTile.special == SpecialKind.goldenPaw) {
      _removeSpecial(first);
      _removeSpecial(second);
      clear.addAll(
        _activeTileIndexes.where((index) => !_tiles[index]!.isBasket),
      );
    } else if (firstTile.special == SpecialKind.goldenPaw) {
      _transformAnimal(first, second, secondTile);
      clear.addAll(_indexesForAnimal(secondTile.animal));
    } else if (secondTile.special == SpecialKind.goldenPaw) {
      _transformAnimal(first, second, firstTile);
      clear.addAll(_indexesForAnimal(firstTile.animal));
    } else {
      _removeSpecial(first);
      _removeSpecial(second);
      if (firstTile.special == SpecialKind.scout &&
          secondTile.special == SpecialKind.scout) {
        clear.addAll(_scoutTargets(second, 3, {first, second}));
      } else if (firstTile.special == SpecialKind.scout ||
          secondTile.special == SpecialKind.scout) {
        final scout = firstTile.special == SpecialKind.scout ? first : second;
        final carried = scout == first ? secondTile.special : firstTile.special;
        final target = _scoutTargets(scout, 1, {first, second}).single;
        clear.addAll(_effectAt(target, carried));
      } else if (_isArrow(firstTile.special) && _isArrow(secondTile.special)) {
        clear.addAll(_crossBands(second, 0));
      } else if (_isArrow(firstTile.special) || _isArrow(secondTile.special)) {
        final area = _isArea(firstTile.special)
            ? firstTile.special
            : secondTile.special;
        clear.addAll(_crossBands(second, _areaRadius(area)));
      } else {
        clear.addAll(
          _area(
            second,
            min(
              4,
              _areaRadius(firstTile.special) + _areaRadius(secondTile.special),
            ),
          ),
        );
      }
    }
    return _resolve(_MatchAnalysis.clear(clear), const []);
  }

  void _transformAnimal(int first, int second, Match3Tile transformed) {
    _removeSpecial(first);
    _removeSpecial(second);
    for (final index in _indexesForAnimal(transformed.animal).toList()) {
      _tiles[index] = Match3Tile(
        animal: transformed.animal,
        special: transformed.special,
      );
    }
  }

  void _removeSpecial(int index) {
    final tile = _tiles[index]!;
    _tiles[index] = Match3Tile(animal: tile.animal);
  }

  Set<int> _expandSpecials(Set<int> initial) {
    final clear = {...initial};
    final pending = [...initial];
    final triggered = <int>{};
    final reservedTargets = {...initial};
    while (pending.isNotEmpty) {
      final index = pending.removeLast();
      final tile = _tiles[index];
      if (tile == null ||
          tile.special == SpecialKind.none ||
          !triggered.add(index)) {
        continue;
      }
      if (tile.special == SpecialKind.scout) reservedTargets.add(index);
      final targets = _specialTargets(index, tile, reservedTargets);
      for (final target in targets) {
        if (clear.add(target)) pending.add(target);
      }
      score += 300;
    }
    return clear;
  }

  Set<int> _specialTargets(
    int index,
    Match3Tile tile,
    Set<int> reservedTargets,
  ) {
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
      SpecialKind.basketBlast => {..._area(index, 1)},
      SpecialKind.goldenPaw => _indexesForAnimal(tile.animal).toSet(),
      SpecialKind.scout => _scoutTargets(index, 1, reservedTargets),
      SpecialKind.largeGift => _area(index, 2),
      SpecialKind.giantGift => _area(index, 3),
      SpecialKind.none => {index},
    };
  }

  Set<int> _effectAt(int index, SpecialKind special) {
    if (_isArrow(special)) {
      final x = index % size;
      final y = index ~/ size;
      return special == SpecialKind.horizontalBinoculars
          ? {
              for (var column = 0; column < size; column++)
                if (!_inactive.contains(y * size + column)) y * size + column,
            }
          : {
              for (var row = 0; row < size; row++)
                if (!_inactive.contains(row * size + x)) row * size + x,
            };
    }
    return _area(index, _areaRadius(special));
  }

  Set<int> _area(int center, int radius) {
    final x = center % size;
    final y = center ~/ size;
    return {
      for (
        var row = max(0, y - radius);
        row <= min(size - 1, y + radius);
        row++
      )
        for (
          var column = max(0, x - radius);
          column <= min(size - 1, x + radius);
          column++
        )
          if (!_inactive.contains(row * size + column)) row * size + column,
    };
  }

  Set<int> _crossBands(int center, int radius) {
    final x = center % size;
    final y = center ~/ size;
    return {
      for (
        var row = max(0, y - radius);
        row <= min(size - 1, y + radius);
        row++
      )
        for (var column = 0; column < size; column++)
          if (!_inactive.contains(row * size + column)) row * size + column,
      for (
        var column = max(0, x - radius);
        column <= min(size - 1, x + radius);
        column++
      )
        for (var row = 0; row < size; row++)
          if (!_inactive.contains(row * size + column)) row * size + column,
    };
  }

  Set<int> _scoutTargets(int origin, int count, [Set<int>? initiallyReserved]) {
    final reserved = {...?initiallyReserved};
    final targets = <int>{};
    for (var i = 0; i < count; i++) {
      final target = _scoutTarget(origin, reserved);
      targets.add(target);
      reserved.add(target);
    }
    return targets;
  }

  int _scoutTarget(int origin, Set<int> reserved) {
    for (var i = 0; i < level.goals.length; i++) {
      if (_goalProgress[i] >= level.goals[i].target) continue;
      final target = _nearest(
        origin,
        _goalTargets(
          level.goals[i],
        ).where((index) => !reserved.contains(index)),
      );
      if (target != null) return target;
    }
    final fallback = _activeTileIndexes.where(
      (index) =>
          !_tiles[index]!.isBasket &&
          index != origin &&
          !reserved.contains(index),
    );
    final fallbackTarget = _nearest(origin, fallback);
    if (fallbackTarget != null) return fallbackTarget;
    for (var i = 0; i < level.goals.length; i++) {
      if (_goalProgress[i] >= level.goals[i].target) continue;
      final target = _nearest(origin, _goalTargets(level.goals[i]));
      if (target != null) return target;
    }
    return _nearest(
      origin,
      _activeTileIndexes.where((index) => !_tiles[index]!.isBasket),
    )!;
  }

  Iterable<int> _goalTargets(Match3Goal goal) sync* {
    switch (goal.kind) {
      case Match3GoalKind.clearBlockers:
        for (final index in _activeTileIndexes) {
          if (_blockerLayers[index] > 0 && !_tiles[index]!.isBasket) {
            yield index;
          }
        }
        return;
      case Match3GoalKind.collectAnimal:
        yield* _indexesForAnimal(goal.animal!);
        return;
      case Match3GoalKind.deliverBaskets:
        for (final basket in _activeTileIndexes.where(
          (index) => _tiles[index]!.isBasket,
        )) {
          final x = basket % size;
          for (var y = basket ~/ size + 1; y < size; y++) {
            final index = y * size + x;
            if (!_inactive.contains(index) &&
                _tiles[index] != null &&
                !_tiles[index]!.isBasket) {
              yield index;
            }
          }
        }
        return;
    }
  }

  int? _nearest(int origin, Iterable<int> candidates) {
    int? best;
    var bestDistance = 1 << 30;
    for (final candidate in candidates) {
      final distance =
          ((candidate % size) - (origin % size)).abs() +
          ((candidate ~/ size) - (origin ~/ size)).abs();
      if (distance < bestDistance ||
          (distance == bestDistance && (best == null || candidate < best))) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return best;
  }

  Map<int, SpecialKind> _specialsFor(
    _MatchAnalysis analysis,
    List<int> preferred,
  ) => {
    for (final candidate in analysis.candidates)
      preferred.firstWhere(
        candidate.cells.contains,
        orElse: () => candidate.anchor,
      ): candidate.kind,
  };

  _MatchAnalysis _analyzeMatches() {
    final runs = <_MatchRun>[];
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
          runs.add(
            _MatchRun(_MatchAxis.horizontal, [
              for (var x = start; x < end; x++) y * size + x,
            ]),
          );
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
          runs.add(
            _MatchRun(_MatchAxis.vertical, [
              for (var y = start; y < end; y++) y * size + x,
            ]),
          );
        }
        start = end;
      }
    }
    final squares = <Set<int>>[];
    for (var y = 0; y < size - 1; y++) {
      for (var x = 0; x < size - 1; x++) {
        final indexes = {
          y * size + x,
          y * size + x + 1,
          (y + 1) * size + x,
          (y + 1) * size + x + 1,
        };
        final first = _matchableTile(indexes.first);
        if (first != null &&
            !first.isBasket &&
            indexes.every(
              (index) => _matchableTile(index)?.animal == first.animal,
            )) {
          squares.add(indexes);
        }
      }
    }
    final cells = <int>{
      for (final run in runs) ...run.cells,
      for (final square in squares) ...square,
    };
    final candidates =
        <_SpecialCandidate>[
          for (final run in runs)
            if (run.cells.length >= 4)
              _SpecialCandidate(
                run.cells.toSet(),
                _specialFor(run),
                run.cells[(run.cells.length - 1) ~/ 2],
              ),
          for (final horizontal in runs.where(
            (run) => run.axis == _MatchAxis.horizontal,
          ))
            for (final vertical in runs.where(
              (run) => run.axis == _MatchAxis.vertical,
            ))
              for (final intersection in horizontal.cells.toSet().intersection(
                vertical.cells.toSet(),
              ))
                _SpecialCandidate(
                  {...horizontal.cells, ...vertical.cells},
                  SpecialKind.basketBlast,
                  intersection,
                ),
          for (final square in squares)
            _SpecialCandidate(square, SpecialKind.scout, square.reduce(min)),
        ]..sort((first, second) {
          final priority = second.priority.compareTo(first.priority);
          return priority != 0
              ? priority
              : first.anchor.compareTo(second.anchor);
        });
    final accepted = <_SpecialCandidate>[];
    final claimed = <int>{};
    for (final candidate in candidates) {
      if (candidate.cells.any(claimed.contains)) continue;
      accepted.add(candidate);
      claimed.addAll(candidate.cells);
    }
    return _MatchAnalysis(cells, accepted);
  }

  SpecialKind _specialFor(_MatchRun run) => switch (run.cells.length) {
    >= 7 => SpecialKind.giantGift,
    6 => SpecialKind.largeGift,
    5 => SpecialKind.goldenPaw,
    _ =>
      run.axis == _MatchAxis.horizontal
          ? SpecialKind.horizontalBinoculars
          : SpecialKind.verticalBinoculars,
  };

  bool _isArrow(SpecialKind special) =>
      special == SpecialKind.horizontalBinoculars ||
      special == SpecialKind.verticalBinoculars;

  bool _isArea(SpecialKind special) =>
      special == SpecialKind.basketBlast ||
      special == SpecialKind.largeGift ||
      special == SpecialKind.giantGift;

  int _areaRadius(SpecialKind special) => switch (special) {
    SpecialKind.basketBlast => 1,
    SpecialKind.largeGift => 2,
    SpecialKind.giantGift => 3,
    _ => throw StateError('$special n’est pas un bonus de zone.'),
  };

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
        final matches = _analyzeMatches().isNotEmpty;
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
      if (_analyzeMatches().isEmpty && _hasAvailableMove()) return;
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

enum _MatchAxis { horizontal, vertical }

class _MatchRun {
  const _MatchRun(this.axis, this.cells);

  final _MatchAxis axis;
  final List<int> cells;
}

class _SpecialCandidate {
  const _SpecialCandidate(this.cells, this.kind, this.anchor);

  final Set<int> cells;
  final SpecialKind kind;
  final int anchor;

  int get priority => switch (kind) {
    SpecialKind.giantGift => 6,
    SpecialKind.largeGift => 5,
    SpecialKind.goldenPaw => 4,
    SpecialKind.basketBlast => 3,
    SpecialKind.horizontalBinoculars || SpecialKind.verticalBinoculars => 2,
    SpecialKind.scout => 1,
    SpecialKind.none => 0,
  };
}

class _MatchAnalysis {
  const _MatchAnalysis(this.cells, this.candidates);

  const _MatchAnalysis.clear(this.cells) : candidates = const [];

  final Set<int> cells;
  final List<_SpecialCandidate> candidates;

  bool get isEmpty => cells.isEmpty;
  bool get isNotEmpty => cells.isNotEmpty;
}
