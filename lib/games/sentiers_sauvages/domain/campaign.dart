import 'dart:math';

import '../../../shared/animal_catalog.dart';
import '../../../shared/park_catalog.dart';
import 'models.dart';

List<NumberlinkLevelDefinition> buildNumberlinkCampaign(
  List<ParkStage> stages,
) => [
  for (var index = 0; index < stages.length; index++)
    _buildLevel(
      stages[index],
      _boardSpecs[index],
      stages[index].biome,
      stages[index].number,
    ),
];

NumberlinkLevelDefinition buildFreeNumberlinkLevel(
  ParkStage stage,
  NumberlinkFreeGameConfig config,
  int seed,
) {
  final random = Random(seed);
  final group = _groupStart(config.size, config.difficulty);
  final source = _boardSpecs[group + random.nextInt(5)];
  final transform = random.nextInt(8);
  return _buildLevel(stage, source, config.biome, seed, transform: transform);
}

int numberlinkFreePairCount(NumberlinkFreeGameConfig config) =>
    switch ((config.size, config.difficulty)) {
      (5, NumberlinkDifficulty.easy) => 3,
      (5, NumberlinkDifficulty.medium) => 4,
      (5, NumberlinkDifficulty.hard) => 5,
      (7, NumberlinkDifficulty.easy) => 4,
      (7, NumberlinkDifficulty.medium) => 5,
      (7, NumberlinkDifficulty.hard) => 6,
      (9, NumberlinkDifficulty.easy) => 6,
      (9, NumberlinkDifficulty.medium) => 7,
      _ => 8,
    };

int countNumberlinkSolutions(NumberlinkLevelDefinition level) {
  if (!_hasValidReference(level)) return 0;
  final key = _canonicalEndpointSignature(level);
  final cached = _solutionCounts[key];
  if (cached != null) return cached;
  if (level.size < 9 && _hasUniquenessCertificate(level, {})) {
    _solutionCounts[key] = 1;
    return 1;
  }
  final solver = _ExactNumberlinkSolver(level);
  final result = solver.countSolutions();
  _solutionCounts[key] = result;
  _solveEfforts[key] = solver.visitedStates;
  return result;
}

int numberlinkSolveEffort(NumberlinkLevelDefinition level) {
  final key = _canonicalEndpointSignature(level);
  final cached = _solveEfforts[key];
  if (cached != null) return cached;
  final solver = _ExactNumberlinkSolver(level)..countSolutions();
  _solveEfforts[key] = solver.visitedStates;
  return solver.visitedStates;
}

final _solutionCounts = <String, int>{};
final _solveEfforts = <String, int>{};

NumberlinkLevelDefinition _buildLevel(
  ParkStage stage,
  _BoardSpec spec,
  LevelBiome biome,
  int seed, {
  int transform = 0,
}) {
  final pool = animalsByBiome[biome]!;
  final pairs = <NumberlinkPair>[];
  for (var id = 0; id < spec.paths.length; id++) {
    final indices = [
      for (final index in spec.paths[id])
        _transform(
          _transform(index, spec.size, spec.transform),
          spec.size,
          transform,
        ),
    ];
    final path = [
      for (final index in indices)
        NumberlinkPosition(index % spec.size, index ~/ spec.size),
    ];
    pairs.add(
      NumberlinkPair(
        id: id,
        animal: pool[(id + seed) % pool.length],
        animalPosition: path.first,
        enclosurePosition: path.last,
        referencePath: List.unmodifiable(path),
      ),
    );
  }
  return NumberlinkLevelDefinition(
    stage: stage,
    size: spec.size,
    pairs: List.unmodifiable(pairs),
  );
}

int _groupStart(int size, NumberlinkDifficulty difficulty) {
  final sizeTier = switch (size) {
    5 => 0,
    7 => 1,
    _ => 2,
  };
  return (sizeTier * 3 + difficulty.index) * 5;
}

int _transform(int index, int size, int transform) {
  var x = index % size;
  var y = index ~/ size;
  if (transform >= 4) x = size - 1 - x;
  for (var turn = 0; turn < transform % 4; turn++) {
    final previousX = x;
    x = size - 1 - y;
    y = previousX;
  }
  return y * size + x;
}

List<int> _neighbours(int index, int size) {
  final x = index % size;
  final y = index ~/ size;
  return [
    if (y > 0) index - size,
    if (x < size - 1) index + 1,
    if (y < size - 1) index + size,
    if (x > 0) index - 1,
  ];
}

bool _hasValidReference(NumberlinkLevelDefinition level) {
  final occupied = <int>{};
  for (final pair in level.pairs) {
    final path = pair.referencePath;
    if (path.first != pair.animalPosition ||
        path.last != pair.enclosurePosition) {
      return false;
    }
    for (var index = 0; index < path.length; index++) {
      final position = path[index];
      if (position.x < 0 ||
          position.x >= level.size ||
          position.y < 0 ||
          position.y >= level.size ||
          !occupied.add(position.index(level.size))) {
        return false;
      }
      if (index > 0 && !path[index - 1].isAdjacentTo(position)) return false;
    }
  }
  return occupied.length == level.size * level.size;
}

bool _hasUniquenessCertificate(
  NumberlinkLevelDefinition level,
  Map<String, bool> memo,
) {
  final key = _endpointSignature(level);
  final cached = memo[key];
  if (cached != null) return cached;
  if (_hasForcedCertificate(level)) {
    memo[key] = true;
    return true;
  }
  memo[key] = false;
  for (var first = 0; first < level.pairs.length; first++) {
    for (var second = first + 1; second < level.pairs.length; second++) {
      for (final firstInner in _endpoints(level.pairs[first])) {
        for (final secondInner in _endpoints(level.pairs[second])) {
          if (!firstInner.isAdjacentTo(secondInner)) continue;
          final parent = _mergePairs(
            level,
            first,
            second,
            firstInner,
            secondInner,
          );
          if (_hasUniquenessCertificate(parent, memo)) {
            memo[key] = true;
            return true;
          }
        }
      }
    }
  }
  return false;
}

bool _hasForcedCertificate(NumberlinkLevelDefinition level) {
  final neighbours = [
    for (var index = 0; index < level.size * level.size; index++)
      _neighbours(index, level.size),
  ];
  final references = [
    for (final pair in level.pairs)
      [for (final position in pair.referencePath) position.index(level.size)],
  ];
  final heads = [for (final path in references) path.first];
  final targets = [for (final path in references) path.last];
  final cursors = List.filled(level.pairCount, 1);
  final completed = <int>{};
  final occupied = <int>{...heads, ...targets};

  while (completed.length < level.pairCount) {
    (int, int)? forced;
    for (var pair = 0; pair < level.pairCount; pair++) {
      if (completed.contains(pair)) continue;
      final candidates = [
        for (final next in neighbours[heads[pair]])
          if ((next == targets[pair] || !occupied.contains(next)) &&
              _moveKeepsNecessaryConditions(
                pair,
                next,
                heads,
                targets,
                completed,
                occupied,
                neighbours,
              ))
            next,
      ];
      if (candidates.length == 1 &&
          cursors[pair] < references[pair].length &&
          candidates.single == references[pair][cursors[pair]]) {
        forced = (pair, candidates.single);
        break;
      }
    }
    if (forced == null) return false;
    final (pair, next) = forced;
    cursors[pair]++;
    if (next == targets[pair]) {
      completed.add(pair);
    } else {
      heads[pair] = next;
      occupied.add(next);
    }
  }
  return occupied.length == level.size * level.size &&
      [
        for (var pair = 0; pair < level.pairCount; pair++)
          cursors[pair] == references[pair].length,
      ].every((value) => value);
}

bool _moveKeepsNecessaryConditions(
  int pair,
  int next,
  List<int> heads,
  List<int> targets,
  Set<int> completed,
  Set<int> occupied,
  List<List<int>> neighbours,
) {
  final nextHeads = heads.toList();
  final nextCompleted = completed.toSet();
  final nextOccupied = occupied.toSet();
  if (next == targets[pair]) {
    nextCompleted.add(pair);
  } else {
    nextHeads[pair] = next;
    nextOccupied.add(next);
  }
  final unfinished = [
    for (var index = 0; index < heads.length; index++)
      if (!nextCompleted.contains(index)) index,
  ];
  for (final index in unfinished) {
    if (!_isReachable(
      nextHeads[index],
      targets[index],
      nextOccupied,
      neighbours,
    )) {
      return false;
    }
  }

  final ports = <int>{
    for (final index in unfinished) ...[nextHeads[index], targets[index]],
  };
  final empty = <int>{
    for (var index = 0; index < neighbours.length; index++)
      if (!nextOccupied.contains(index)) index,
  };
  for (final cell in empty) {
    final available = neighbours[cell].where(
      (candidate) =>
          !nextOccupied.contains(candidate) || ports.contains(candidate),
    );
    if (available.length < 2) return false;
  }

  final remaining = empty.toSet();
  while (remaining.isNotEmpty) {
    final component = <int>{remaining.first};
    final pending = [remaining.first];
    remaining.remove(remaining.first);
    while (pending.isNotEmpty) {
      final cell = pending.removeLast();
      for (final candidate in neighbours[cell]) {
        if (!remaining.remove(candidate)) continue;
        component.add(candidate);
        pending.add(candidate);
      }
    }
    final serviceable = unfinished.any(
      (index) =>
          neighbours[nextHeads[index]].any(component.contains) &&
          neighbours[targets[index]].any(component.contains),
    );
    if (!serviceable) return false;
  }
  return true;
}

bool _isReachable(
  int start,
  int target,
  Set<int> occupied,
  List<List<int>> neighbours,
) {
  final visited = <int>{start};
  final pending = [start];
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    if (current == target) return true;
    for (final candidate in neighbours[current]) {
      if (visited.contains(candidate) ||
          (candidate != target && occupied.contains(candidate))) {
        continue;
      }
      visited.add(candidate);
      pending.add(candidate);
    }
  }
  return false;
}

class _ExactNumberlinkSolver {
  _ExactNumberlinkSolver(this.level)
    : _neighboursByCell = [
        for (var cell = 0; cell < level.size * level.size; cell++)
          _neighbours(cell, level.size),
      ],
      _references = [
        for (final pair in level.pairs)
          [
            for (final position in pair.referencePath)
              position.index(level.size),
          ],
      ],
      _heads = [
        for (final pair in level.pairs) pair.animalPosition.index(level.size),
      ],
      _targets = [
        for (final pair in level.pairs)
          pair.enclosurePosition.index(level.size),
      ],
      _done = List.filled(level.pairCount, false),
      _pathLengths = List.filled(level.pairCount, 1),
      _owners = List.filled(level.size * level.size, -1),
      _componentIds = List.filled(level.size * level.size, 0),
      _ports = List.filled(level.size * level.size, false),
      _queue = List.filled(level.size * level.size, 0) {
    for (final pair in level.pairs) {
      _owners[pair.animalPosition.index(level.size)] = pair.id;
      _owners[pair.enclosurePosition.index(level.size)] = pair.id;
    }
  }

  final NumberlinkLevelDefinition level;
  final List<List<int>> _neighboursByCell;
  final List<List<int>> _references;
  final List<int> _heads;
  final List<int> _targets;
  final List<bool> _done;
  final List<int> _pathLengths;
  final List<int> _owners;
  final List<int> _componentIds;
  final List<bool> _ports;
  final List<int> _queue;
  int _solutions = 0;
  int visitedStates = 0;

  int countSolutions() {
    _search();
    return _solutions;
  }

  void _search() {
    visitedStates++;
    if (_solutions >= 2) return;
    var allDone = true;
    for (final done in _done) {
      if (!done) allDone = false;
    }
    if (allDone) {
      var covered = true;
      for (final owner in _owners) {
        if (owner < 0) covered = false;
      }
      if (covered) _solutions++;
      return;
    }

    var selected = -1;
    var selectedMoveCount = 5;
    var selectedMoves = 0;
    for (var pair = 0; pair < level.pairCount; pair++) {
      if (_done[pair]) continue;
      var moveCount = 0;
      var moves = 0;
      for (final candidate in _neighboursByCell[_heads[pair]]) {
        if (candidate != _targets[pair] && _owners[candidate] >= 0) continue;
        moves |= candidate << (moveCount * 7);
        moveCount++;
      }
      if (moveCount == 0) return;
      if (moveCount >= selectedMoveCount) continue;
      selected = pair;
      selectedMoveCount = moveCount;
      selectedMoves = moves;
    }

    final reference = _pathLengths[selected] < _references[selected].length
        ? _references[selected][_pathLengths[selected]]
        : -1;
    var orderedMoves = 0;
    var orderedCount = 0;
    for (var index = 0; index < selectedMoveCount; index++) {
      final candidate = (selectedMoves >> (index * 7)) & 127;
      if (candidate == reference) {
        orderedMoves |= candidate << (orderedCount++ * 7);
      }
    }
    for (var index = 0; index < selectedMoveCount; index++) {
      final candidate = (selectedMoves >> (index * 7)) & 127;
      if (candidate != reference) {
        orderedMoves |= candidate << (orderedCount++ * 7);
      }
    }
    final previousHead = _heads[selected];
    for (var index = 0; index < selectedMoveCount; index++) {
      final candidate = (orderedMoves >> (index * 7)) & 127;
      _heads[selected] = candidate;
      _pathLengths[selected]++;
      if (candidate == _targets[selected]) {
        _done[selected] = true;
        if (_isViable()) _search();
        _done[selected] = false;
      } else {
        _owners[candidate] = selected;
        if (_isViable()) _search();
        _owners[candidate] = -1;
      }
      _pathLengths[selected]--;
      _heads[selected] = previousHead;
      if (_solutions >= 2) return;
    }
  }

  bool _isViable() {
    _ports.fillRange(0, _ports.length, false);
    for (var pair = 0; pair < level.pairCount; pair++) {
      if (_done[pair]) continue;
      _ports[_heads[pair]] = true;
      _ports[_targets[pair]] = true;
    }

    for (var cell = 0; cell < _owners.length; cell++) {
      if (_owners[cell] >= 0) continue;
      var available = 0;
      for (final candidate in _neighboursByCell[cell]) {
        if (_owners[candidate] < 0 || _ports[candidate]) available++;
      }
      if (available < 2) return false;
    }

    _componentIds.fillRange(0, _componentIds.length, 0);
    var componentId = 0;
    for (var root = 0; root < _owners.length; root++) {
      if (_owners[root] >= 0 || _componentIds[root] != 0) continue;
      componentId++;
      var first = 0;
      var last = 0;
      _queue[last++] = root;
      _componentIds[root] = componentId;
      while (first < last) {
        final cell = _queue[first++];
        for (final candidate in _neighboursByCell[cell]) {
          if (_owners[candidate] >= 0 || _componentIds[candidate] != 0) {
            continue;
          }
          _componentIds[candidate] = componentId;
          _queue[last++] = candidate;
        }
      }
    }

    for (var pair = 0; pair < level.pairCount; pair++) {
      if (_done[pair]) continue;
      var reachable = _neighboursByCell[_heads[pair]].contains(_targets[pair]);
      for (final headNeighbour in _neighboursByCell[_heads[pair]]) {
        final id = _componentIds[headNeighbour];
        if (id == 0) continue;
        for (final targetNeighbour in _neighboursByCell[_targets[pair]]) {
          if (_componentIds[targetNeighbour] == id) reachable = true;
        }
      }
      if (!reachable) return false;
    }

    for (var id = 1; id <= componentId; id++) {
      var serviceable = false;
      for (var pair = 0; pair < level.pairCount && !serviceable; pair++) {
        if (_done[pair]) continue;
        final touchesHead = _neighboursByCell[_heads[pair]].any(
          (candidate) => _componentIds[candidate] == id,
        );
        final touchesTarget = _neighboursByCell[_targets[pair]].any(
          (candidate) => _componentIds[candidate] == id,
        );
        serviceable = touchesHead && touchesTarget;
      }
      if (!serviceable) return false;
    }
    return true;
  }
}

String _endpointSignature(NumberlinkLevelDefinition level) {
  final pairs = [
    for (final pair in level.pairs)
      ([
        pair.animalPosition.index(level.size),
        pair.enclosurePosition.index(level.size),
      ]..sort()).join('-'),
  ]..sort();
  return '${level.size}:${pairs.join(';')}';
}

String _canonicalEndpointSignature(NumberlinkLevelDefinition level) {
  final signatures = <String>[];
  for (var transform = 0; transform < 8; transform++) {
    final pairs = [
      for (final pair in level.pairs)
        ([
          _transform(
            pair.animalPosition.index(level.size),
            level.size,
            transform,
          ),
          _transform(
            pair.enclosurePosition.index(level.size),
            level.size,
            transform,
          ),
        ]..sort()).join('-'),
    ]..sort();
    signatures.add('${level.size}:${pairs.join(';')}');
  }
  signatures.sort();
  return signatures.first;
}

List<NumberlinkPosition> _endpoints(NumberlinkPair pair) => [
  pair.animalPosition,
  pair.enclosurePosition,
];

NumberlinkLevelDefinition _mergePairs(
  NumberlinkLevelDefinition level,
  int first,
  int second,
  NumberlinkPosition firstInner,
  NumberlinkPosition secondInner,
) {
  final firstPair = level.pairs[first];
  final secondPair = level.pairs[second];
  final firstPath = firstPair.referencePath.last == firstInner
      ? firstPair.referencePath
      : firstPair.referencePath.reversed.toList();
  final secondPath = secondPair.referencePath.first == secondInner
      ? secondPair.referencePath
      : secondPair.referencePath.reversed.toList();
  final source = [
    for (var index = 0; index < level.pairs.length; index++)
      if (index != first && index != second) level.pairs[index],
    NumberlinkPair(
      id: 0,
      animal: firstPair.animal,
      animalPosition: firstPath.first,
      enclosurePosition: secondPath.last,
      referencePath: [...firstPath, ...secondPath],
    ),
  ];
  return NumberlinkLevelDefinition(
    stage: level.stage,
    size: level.size,
    pairs: [
      for (var id = 0; id < source.length; id++)
        NumberlinkPair(
          id: id,
          animal: source[id].animal,
          animalPosition: source[id].animalPosition,
          enclosurePosition: source[id].enclosurePosition,
          referencePath: source[id].referencePath,
        ),
    ],
  );
}

class _BoardSpec {
  const _BoardSpec(this.size, this.paths, {this.transform = 0});

  final int size;
  final List<List<int>> paths;
  final int transform;
}

const _boardSpecs = <_BoardSpec>[
  _BoardSpec(5, [
    [4, 3, 2, 7, 12],
    [8, 13, 18, 17, 16, 11, 6, 1, 0],
    [5, 10, 15, 20, 21, 22, 23, 24, 19, 14, 9],
  ]), // effort 23
  _BoardSpec(5, [
    [23, 24, 19, 18, 13, 8, 7, 6, 11, 16],
    [22, 21, 20, 15, 10, 5, 0, 1, 2, 3, 4, 9, 14],
    [17, 12],
  ]), // effort 23
  _BoardSpec(5, [
    [3, 4, 9, 14, 13, 12],
    [22, 23, 24, 19],
    [18, 17, 16, 21, 20, 15, 10, 11, 6, 5, 0, 1, 2, 7, 8],
  ]), // effort 23
  _BoardSpec(5, [
    [8, 13, 12],
    [18, 17, 16, 11, 6, 7, 2, 1, 0, 5, 10, 15, 20, 21, 22, 23, 24, 19, 14],
    [9, 4, 3],
  ]), // effort 36
  _BoardSpec(5, [
    [2, 3, 8, 13, 14, 19, 24, 23, 18, 17, 22, 21],
    [4, 9],
    [12, 7, 6, 1, 0, 5, 10, 11, 16, 15, 20],
  ]), // effort 59
  _BoardSpec(5, [
    [19, 24, 23, 22, 21, 20, 15, 10, 5, 0, 1, 2, 3, 4],
    [11, 12],
    [16, 17, 18, 13],
    [14, 9, 8, 7, 6],
  ]), // effort 22
  _BoardSpec(5, [
    [22, 17, 12, 11, 6],
    [1, 0, 5, 10, 15, 20, 21, 16],
    [2, 7, 8, 13],
    [18, 23, 24, 19, 14, 9, 4, 3],
  ]), // effort 22
  _BoardSpec(5, [
    [2, 3, 4, 9, 8],
    [7, 6, 1, 0, 5, 10],
    [11, 12, 17, 16, 15, 20, 21, 22, 23, 18],
    [13, 14, 19, 24],
  ]), // effort 23
  _BoardSpec(5, [
    [9, 4, 3, 2, 1, 0, 5, 6],
    [8, 7, 12, 11, 10, 15],
    [18, 13, 14, 19, 24, 23, 22, 17, 16],
    [21, 20],
  ]), // effort 24
  _BoardSpec(5, [
    [2, 7, 12, 13, 18],
    [23, 24, 19, 14, 9, 4, 3, 8],
    [6, 11, 16, 17, 22, 21],
    [20, 15, 10, 5, 0, 1],
  ]), // effort 26
  _BoardSpec(5, [
    [10, 11, 12, 13, 8],
    [7, 6, 5, 0],
    [15, 16],
    [1, 2, 3, 4, 9, 14, 19, 24, 23],
    [18, 17, 22, 21, 20],
  ]), // effort 21
  _BoardSpec(5, [
    [22, 21],
    [20, 15, 10, 11],
    [16, 17, 12, 7, 6],
    [5, 0, 1, 2, 3],
    [4, 9, 8, 13, 18, 23, 24, 19, 14],
  ]), // effort 21
  _BoardSpec(5, [
    [20, 15, 10, 5],
    [0, 1, 2, 3, 8, 9, 4],
    [21, 16, 11, 6, 7],
    [22, 17, 12, 13],
    [18, 23, 24, 19, 14],
  ]), // effort 22
  _BoardSpec(5, [
    [12, 7, 8, 13, 18, 17, 16],
    [15, 20, 21, 22, 23],
    [24, 19, 14, 9, 4, 3],
    [2, 1, 0, 5],
    [6, 11, 10],
  ]), // effort 32
  _BoardSpec(5, [
    [2, 1, 0, 5, 6, 7, 8, 3, 4],
    [9, 14, 13, 12, 11, 16],
    [10, 15],
    [17, 22, 21, 20],
    [18, 19, 24, 23],
  ]), // effort 36
  _BoardSpec(7, [
    [
      13,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
      7,
      14,
      21,
      28,
      35,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      41,
      34,
      27,
      20,
    ],
    [17, 16, 23, 30, 31, 32],
    [10, 9, 8, 15, 22, 29, 36, 37, 38, 39, 40, 33, 26, 19],
    [12, 11, 18, 25, 24],
  ]), // effort 46
  _BoardSpec(7, [
    [
      35,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      41,
      34,
      27,
      20,
      13,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
      7,
      14,
      21,
      28,
    ],
    [31, 32, 25, 18, 17, 16],
    [36, 29, 22, 15, 8, 9, 10, 11, 12, 19, 26, 33, 40, 39],
    [38, 37, 30, 23, 24],
  ]), // effort 58
  _BoardSpec(7, [
    [15, 16, 17, 24],
    [23, 30, 31, 32, 25, 18],
    [
      14,
      21,
      28,
      35,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      41,
      34,
      27,
      20,
      13,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
      7,
      8,
      9,
    ],
    [10, 11, 12, 19, 26, 33, 40, 39, 38, 37, 36, 29, 22],
  ]), // effort 67
  _BoardSpec(7, [
    [33, 32, 31, 24],
    [25, 18, 17, 16, 23, 30],
    [34, 27, 20, 13, 6, 5, 4, 3, 2, 1, 0, 7, 14, 21, 28, 35, 42, 43, 44, 45],
    [46, 47, 48, 41, 40, 39, 38, 37, 36, 29, 22, 15, 8, 9, 10, 11, 12, 19, 26],
  ]), // effort 81
  _BoardSpec(7, [
    [29, 30, 31, 24],
    [23, 16, 17, 18, 25, 32],
    [
      44,
      45,
      46,
      47,
      48,
      41,
      34,
      27,
      20,
      13,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
      7,
      14,
      21,
      22,
      15,
    ],
    [8, 9, 10, 11, 12, 19, 26, 33, 40, 39, 38, 37, 36, 43, 42, 35, 28],
  ]), // effort 458
  _BoardSpec(7, [
    [32, 25, 18, 17, 10],
    [9, 16, 23],
    [24, 31, 30],
    [
      5,
      6,
      13,
      20,
      27,
      34,
      41,
      48,
      47,
      46,
      45,
      44,
      43,
      42,
      35,
      28,
      21,
      14,
      7,
      0,
      1,
    ],
    [2, 3, 4, 11, 12, 19, 26, 33, 40, 39, 38, 37, 36, 29, 22, 15, 8],
  ]), // effort 47
  _BoardSpec(7, [
    [
      41,
      48,
      47,
      46,
      45,
      44,
      43,
      42,
      35,
      28,
      21,
      14,
      7,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      13,
      20,
      27,
      34,
    ],
    [16, 23, 30, 31, 38],
    [37, 36, 29, 22, 15, 8, 9, 10, 11, 12, 19, 26, 33, 40],
    [39, 32, 25, 18],
    [17, 24],
  ]), // effort 47
  _BoardSpec(7, [
    [
      13,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
      7,
      14,
      21,
      28,
      35,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      41,
      34,
      27,
      20,
    ],
    [30, 31, 32, 25, 26],
    [33, 40, 39, 38, 37, 36, 29, 22, 15, 8, 9, 10, 11, 12],
    [19, 18, 17, 24],
    [23, 16],
  ]), // effort 54
  _BoardSpec(7, [
    [
      35,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      41,
      34,
      27,
      20,
      13,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
      7,
      14,
      21,
      28,
    ],
    [18, 17, 16, 23, 22],
    [24, 25, 32],
    [15, 8, 9, 10, 11, 12, 19, 26, 33, 40, 39, 38],
    [31, 30, 29, 36, 37],
  ]), // effort 96
  _BoardSpec(7, [
    [
      1,
      0,
      7,
      14,
      21,
      28,
      35,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      41,
      34,
      27,
      20,
      13,
      6,
      5,
      4,
      3,
      2,
    ],
    [9, 8, 15, 22, 29, 36, 37, 38, 39, 40, 33, 26, 19, 12],
    [24, 31, 32],
    [30, 23, 16, 17, 10, 11],
    [18, 25],
  ]), // effort 341
  _BoardSpec(7, [
    [12, 19, 26, 33, 40, 39, 38, 37, 36],
    [11, 18],
    [25, 32, 31, 30, 29],
    [
      2,
      3,
      4,
      5,
      6,
      13,
      20,
      27,
      34,
      41,
      48,
      47,
      46,
      45,
      44,
      43,
      42,
      35,
      28,
      21,
      14,
      7,
      0,
      1,
    ],
    [10, 9],
    [8, 15, 22, 23, 24, 17, 16],
  ]), // effort 47
  _BoardSpec(7, [
    [
      46,
      45,
      44,
      43,
      42,
      35,
      28,
      21,
      14,
      7,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      13,
      20,
      27,
      34,
      41,
      48,
      47,
    ],
    [37, 30, 23, 16, 17],
    [18, 19],
    [12, 11, 10, 9, 8, 15, 22, 29, 36],
    [32, 39, 40],
    [33, 26, 25, 24, 31, 38],
  ]), // effort 52
  _BoardSpec(7, [
    [
      4,
      3,
      2,
      1,
      0,
      7,
      14,
      21,
      28,
      35,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      41,
      34,
      27,
      20,
      13,
      6,
      5,
    ],
    [26, 19, 12, 11, 18],
    [25, 24, 17, 10],
    [40, 39, 38, 37, 36, 29, 22, 15, 8],
    [9, 16],
    [23, 30, 31, 32, 33],
  ]), // effort 114
  _BoardSpec(7, [
    [
      28,
      21,
      14,
      7,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      13,
      20,
      27,
      34,
      41,
      48,
      47,
      46,
      45,
      44,
      43,
      42,
      35,
    ],
    [40, 33, 26, 19, 12, 11, 10, 9, 8],
    [30, 29, 36, 37],
    [39, 38],
    [22, 23, 24, 31, 32],
    [25, 18, 17, 16, 15],
  ]), // effort 135
  _BoardSpec(7, [
    [
      44,
      45,
      46,
      47,
      48,
      41,
      34,
      27,
      20,
      13,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
      7,
      14,
      21,
      28,
      35,
      42,
      43,
    ],
    [22, 29, 36, 37, 30],
    [23, 24, 31, 38],
    [8, 9, 10, 11, 12, 19, 26, 33, 40],
    [39, 32, 25],
    [18, 17, 16, 15],
  ]), // effort 205
  _BoardSpec(9, [
    [
      6,
      5,
      4,
      3,
      2,
      1,
      0,
      9,
      18,
      27,
      36,
      45,
      54,
      63,
      72,
      73,
      74,
      75,
      76,
      77,
      78,
      79,
      80,
      71,
      62,
      53,
      44,
      35,
      26,
    ],
    [7, 8, 17],
    [
      25,
      16,
      15,
      14,
      13,
      12,
      11,
      10,
      19,
      28,
      37,
      46,
      55,
      64,
      65,
      66,
      67,
      68,
      69,
      70,
      61,
      52,
      43,
      34,
    ],
    [22, 21, 20, 29, 38, 47, 56, 57, 58, 59, 60, 51, 42, 33, 24],
    [23, 32, 41, 40],
    [31, 30, 39, 48, 49, 50],
  ]), // effort 2117
  _BoardSpec(9, [
    [
      45,
      36,
      27,
      18,
      9,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      17,
      26,
      35,
      44,
      53,
      62,
      71,
      80,
      79,
      78,
      77,
      76,
      75,
      74,
    ],
    [58, 59, 60, 51, 42, 33, 24, 23, 22, 21, 20, 29, 38, 47, 56],
    [57, 48, 39, 40],
    [49, 50, 41, 32, 31, 30],
    [
      73,
      72,
      63,
      54,
      55,
      64,
      65,
      66,
      67,
      68,
      69,
      70,
      61,
      52,
      43,
      34,
      25,
      16,
      15,
      14,
      13,
      12,
      11,
      10,
      19,
    ],
    [28, 37, 46],
  ]), // effort 3291
  _BoardSpec(9, [
    [73, 72, 63],
    [38, 29, 20, 21, 22, 23, 24, 33, 42, 51, 60, 59, 58, 57, 56],
    [47, 48, 49, 40],
    [39, 30, 31, 32, 41, 50],
    [
      54,
      45,
      36,
      27,
      18,
      9,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      17,
      26,
      35,
      44,
      53,
      62,
      71,
      80,
      79,
      78,
      77,
      76,
      75,
    ],
    [
      74,
      65,
      64,
      55,
      46,
      37,
      28,
      19,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      25,
      34,
      43,
      52,
      61,
      70,
      69,
      68,
      67,
      66,
    ],
  ]), // effort 4259
  _BoardSpec(9, [
    [
      3,
      4,
      5,
      6,
      7,
      8,
      17,
      26,
      35,
      44,
      53,
      62,
      71,
      80,
      79,
      78,
      77,
      76,
      75,
      74,
      73,
      72,
      63,
      54,
      45,
      36,
      27,
      18,
    ],
    [38, 47, 56, 57, 58, 59, 60, 51, 42, 33, 24, 23, 22, 21, 20],
    [29, 30, 31, 40],
    [39, 48, 49, 50, 41, 32],
    [9, 0, 1, 2, 11],
    [
      10,
      19,
      28,
      37,
      46,
      55,
      64,
      65,
      66,
      67,
      68,
      69,
      70,
      61,
      52,
      43,
      34,
      25,
      16,
      15,
      14,
      13,
      12,
    ],
  ]), // effort 4748
  _BoardSpec(9, [
    [
      69,
      70,
      61,
      52,
      43,
      34,
      25,
      16,
      15,
      14,
      13,
      12,
      11,
      10,
      19,
      28,
      37,
      46,
      55,
      64,
      65,
      66,
      67,
      68,
    ],
    [42, 33, 24, 23, 22, 21, 20, 29, 38, 47, 56, 57, 58, 59, 60],
    [51, 50, 49, 40],
    [41, 32, 31, 30, 39, 48],
    [
      62,
      53,
      44,
      35,
      26,
      17,
      8,
      7,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
      9,
      18,
      27,
      36,
      45,
      54,
      63,
      72,
      73,
      74,
      75,
      76,
      77,
    ],
    [78, 79, 80, 71],
  ]), // effort 38685
  _BoardSpec(9, [
    [71, 80, 79],
    [
      61,
      70,
      69,
      68,
      67,
      66,
      65,
      64,
      55,
      46,
      37,
      28,
      19,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      25,
      34,
      43,
      52,
    ],
    [58, 57, 56, 47, 38, 29, 20, 21, 22, 23, 24, 33, 42, 51, 60],
    [59, 50, 41, 40],
    [49, 48, 39, 30, 31, 32],
    [62, 53, 44, 35, 26, 17, 8, 7, 6, 5, 4, 3, 2, 1, 0, 9, 18, 27, 36, 45, 54],
    [63, 72, 73, 74, 75, 76, 77, 78],
  ]), // effort 181
  _BoardSpec(9, [
    [15, 16, 25, 34, 43, 52, 61, 70, 69, 68, 67, 66, 65, 64, 55, 54, 63, 72],
    [26, 35, 44, 53, 62, 71, 80, 79, 78, 77, 76, 75, 74, 73],
    [24, 23, 22, 21, 20, 29, 38, 47, 56, 57, 58, 59, 60, 51, 42],
    [33, 32, 31, 40],
    [30, 39, 48, 49, 50, 41],
    [17, 8, 7, 6, 5, 4, 3, 2, 1, 0, 9, 18, 27, 36, 45],
    [46, 37, 28, 19, 10, 11, 12, 13, 14],
  ]), // effort 1017
  _BoardSpec(9, [
    [27, 36, 45, 54, 63, 72, 73, 74, 75, 76, 77, 78, 79, 80],
    [71, 62, 53, 44, 35, 26, 17, 8, 7, 6, 5, 4, 3, 2],
    [22, 23, 24, 33, 42, 51, 60, 59, 58, 57, 56, 47, 38, 29, 20],
    [21, 30, 39, 40],
    [31, 32, 41, 50, 49, 48],
    [
      1,
      0,
      9,
      18,
      19,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      25,
      34,
      43,
      52,
      61,
      70,
      69,
      68,
      67,
      66,
      65,
      64,
    ],
    [55, 46, 37, 28],
  ]), // effort 7371
  _BoardSpec(9, [
    [6, 5, 4, 3, 2, 1, 0, 9, 18, 27, 36, 45, 54, 63],
    [72, 73, 74, 75, 76, 77, 78, 79, 80, 71, 62, 53, 44, 35, 26],
    [17, 8, 7],
    [
      15,
      16,
      25,
      34,
      43,
      52,
      61,
      70,
      69,
      68,
      67,
      66,
      65,
      64,
      55,
      46,
      37,
      28,
      19,
      10,
      11,
      12,
      13,
      14,
    ],
    [31, 40],
    [30, 39, 48, 49, 50, 41, 32, 33],
    [24, 23, 22, 21, 20, 29, 38, 47, 56, 57, 58, 59, 60, 51, 42],
  ]), // effort 24731
  _BoardSpec(9, [
    [73, 74, 75, 76, 77, 78, 79, 80, 71, 62, 53, 44, 35, 26],
    [42, 51, 60, 59, 58, 57, 56, 47, 38, 29, 20, 21, 22, 23, 24],
    [33, 32, 31, 40],
    [41, 50, 49, 48, 39, 30],
    [7, 8, 17],
    [14, 13, 12, 11, 10, 19, 28, 37, 46, 55, 64, 65, 66, 67, 68, 69, 70],
    [
      61,
      52,
      43,
      34,
      25,
      16,
      15,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
      9,
      18,
      27,
      36,
      45,
      54,
      63,
      72,
    ],
  ]), // effort 45377
  _BoardSpec(9, [
    [48, 39, 30, 31, 32, 41],
    [40, 49, 50, 51],
    [42, 33, 24, 23, 22, 21, 20, 29, 38, 47, 56, 57, 58, 59, 60, 69],
    [70, 61, 52, 43, 34, 25, 16, 15, 14, 13, 12, 11],
    [10, 19, 28, 37, 46, 55, 64, 65, 66, 67, 68, 77],
    [76, 75, 74, 73, 72, 63, 54, 45, 36, 27, 18],
    [9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 17, 26, 35, 44, 53],
    [62, 71, 80, 79, 78],
  ]), // effort 13163
  _BoardSpec(9, [
    [18, 9, 0, 1, 2, 3],
    [4, 5, 6, 7, 8, 17, 26, 35, 44, 53, 62, 71, 80, 79, 78, 77],
    [76, 75, 74, 73, 72, 63, 54, 45, 36, 27, 28, 37],
    [46, 55, 64, 65, 66, 67, 68, 69],
    [70, 61, 52, 43, 34, 25, 16, 15, 14, 13, 12, 11],
    [10, 19, 20, 29, 38, 47, 56, 57, 58, 59, 60, 51, 42, 33, 24, 23],
    [22, 21, 30, 39],
    [40, 31, 32, 41, 50, 49, 48],
  ], transform: 1), // effort 28423
  _BoardSpec(9, [
    [6, 7, 8, 17, 26, 35, 44],
    [53, 62, 71, 80, 79, 78],
    [77, 76, 75, 74, 73, 72, 63, 54, 45, 36, 27, 18, 9, 0, 1, 2, 3, 4],
    [5, 14, 13, 12, 11, 10, 19, 28, 37, 46, 55, 64, 65, 66],
    [67, 68, 69, 70, 61, 52, 43, 34, 25, 16, 15],
    [24, 23, 22, 21, 20, 29, 38, 47, 56, 57, 58, 59, 60, 51],
    [42, 33, 32, 31],
    [40, 41, 50, 49, 48, 39, 30],
  ], transform: 4), // effort 64046
  _BoardSpec(9, [
    [18, 9],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 17, 26, 35, 44, 53, 62, 71],
    [80, 79, 78, 77, 76, 75, 74, 73, 72, 63, 54, 45, 36, 27],
    [28, 37, 46, 55, 64, 65, 66, 67, 68, 69, 70],
    [61, 52, 43, 34, 25, 16, 15, 14, 13, 12, 11, 10, 19],
    [20, 29, 38, 47, 56, 57, 58, 59, 60, 51, 42, 33, 24, 23],
    [22, 21, 30, 39],
    [40, 31, 32, 41, 50, 49, 48],
  ], transform: 2), // effort 93957
  _BoardSpec(9, [
    [62, 71, 80],
    [79, 78, 77, 76, 75, 74, 73, 72, 63, 54, 45, 36],
    [27, 18, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 17, 26, 35, 44, 53, 52, 43],
    [34, 25, 16, 15, 14, 13, 12, 11],
    [10, 19, 28, 37, 46, 55, 64, 65, 66, 67, 68, 69, 70, 61],
    [60, 51, 42, 33, 24, 23, 22, 21, 20, 29, 38, 47, 56, 57],
    [58, 59, 50, 41],
    [40, 49, 48, 39, 30, 31, 32],
  ], transform: 5), // effort 190620
];
