import 'dart:math';

import 'models.dart';
import 'solver.dart';

enum RepasDifficulty { easy, medium, hard }

extension RepasDifficultyLabel on RepasDifficulty {
  String get label => switch (this) {
    RepasDifficulty.easy => 'Facile',
    RepasDifficulty.medium => 'Moyenne',
    RepasDifficulty.hard => 'Difficile',
  };
}

enum RepasBoardSize { small, medium, large }

extension RepasBoardSizeInfo on RepasBoardSize {
  int get side => switch (this) {
    RepasBoardSize.small => 7,
    RepasBoardSize.medium => 9,
    RepasBoardSize.large => 11,
  };

  String get label => switch (this) {
    RepasBoardSize.small => 'Petite · 7 × 7',
    RepasBoardSize.medium => 'Moyenne · 9 × 9',
    RepasBoardSize.large => 'Grande · 11 × 11',
  };
}

class RepasFreeGameConfig {
  const RepasFreeGameConfig({required this.size, required this.difficulty});

  final RepasBoardSize size;
  final RepasDifficulty difficulty;
}

class RepasGeneratedBoard {
  const RepasGeneratedBoard(this.rows, this.parPushes, this.solution);

  final List<String> rows;
  final int parPushes;
  final List<RepasDirection> solution;
}

RepasGeneratedBoard generateRepasBoard((RepasFreeGameConfig, int) request) {
  final (config, seed) = request;
  final random = Random(seed);
  final side = config.size.side;
  final crateCount = _crateCount(config);
  final (minimum, maximum) = _pushRange(config.difficulty, crateCount);
  var bestPushes = 0;
  for (var attempt = 0; attempt < 400; attempt++) {
    final floor = _floorPlan(side, config.difficulty, random);
    final targets = _targets(floor, crateCount, random);
    if (targets == null) continue;
    final scrambled = _scramble(
      floor,
      targets,
      minimum + random.nextInt(maximum - minimum + 1),
      random,
    );
    if (scrambled == null ||
        scrambled.pushes < minimum ||
        scrambled.pushes > maximum) {
      continue;
    }
    if (scrambled.pushes > bestPushes) bestPushes = scrambled.pushes;
    return RepasGeneratedBoard(
      _rows(side, floor, targets, scrambled.crates, scrambled.keeper),
      scrambled.pushes,
      scrambled.solution,
    );
  }
  throw StateError(
    'Aucun niveau ${config.difficulty.label} généré '
    '(meilleur résultat : $bestPushes poussées).',
  );
}

int _crateCount(RepasFreeGameConfig config) =>
    switch ((config.size, config.difficulty)) {
      (RepasBoardSize.small, RepasDifficulty.easy) => 2,
      (RepasBoardSize.small, RepasDifficulty.medium) => 2,
      (RepasBoardSize.small, RepasDifficulty.hard) => 2,
      (RepasBoardSize.medium, RepasDifficulty.easy) => 2,
      (RepasBoardSize.medium, RepasDifficulty.medium) => 3,
      (RepasBoardSize.medium, RepasDifficulty.hard) => 4,
      (RepasBoardSize.large, RepasDifficulty.easy) => 3,
      (RepasBoardSize.large, RepasDifficulty.medium) => 4,
      (RepasBoardSize.large, RepasDifficulty.hard) => 5,
    };

(int, int) _pushRange(RepasDifficulty difficulty, int crates) =>
    switch (difficulty) {
      RepasDifficulty.easy => (crates, crates * 3),
      RepasDifficulty.medium => (crates * 3 + 1, crates * 6),
      RepasDifficulty.hard => (crates * 3 + 1, crates * 8),
    };

Set<RepasPosition> _floorPlan(
  int side,
  RepasDifficulty difficulty,
  Random random,
) {
  final floor = {
    for (var y = 1; y < side - 1; y++)
      for (var x = 1; x < side - 1; x++) RepasPosition(x, y),
  };
  final density = switch (difficulty) {
    RepasDifficulty.easy => .08,
    RepasDifficulty.medium => .15,
    RepasDifficulty.hard => .22,
  };
  final wallCount = (floor.length * density).round();
  final candidates = floor.toList()..shuffle(random);
  for (final wall in candidates) {
    if (floor.length <= (side - 2) * (side - 2) - wallCount) break;
    floor.remove(wall);
    if (_connected(floor)) continue;
    floor.add(wall);
  }
  return floor;
}

bool _connected(Set<RepasPosition> floor) =>
    reachableRepasFloor(floor, floor.first, const {}).length == floor.length;

Set<RepasPosition>? _targets(
  Set<RepasPosition> floor,
  int count,
  Random random,
) {
  final candidates = floor.where((position) => _canPullFrom(position, floor));
  final shuffled = candidates.toList()..shuffle(random);
  final targets = <RepasPosition>{};
  for (final candidate in shuffled) {
    if (targets.any((target) => _distance(target, candidate) < 3)) continue;
    targets.add(candidate);
    if (targets.length == count) return targets;
  }
  return null;
}

bool _canPullFrom(RepasPosition crate, Set<RepasPosition> floor) {
  for (final direction in RepasDirection.values) {
    final source = crate - direction.offset;
    final behind = source - direction.offset;
    if (floor.contains(source) && floor.contains(behind)) return true;
  }
  return false;
}

_ScrambledBoard? _scramble(
  Set<RepasPosition> floor,
  Set<RepasPosition> targets,
  int steps,
  Random random,
) {
  var crates = {...targets};
  var keeper = (floor.difference(crates).toList()..shuffle(random)).first;
  _Pull? previous;
  var performed = 0;
  final history = <_Pull>[];
  final visited = <String>{_cratesKey(crates)};
  for (var step = 0; step < steps; step++) {
    final reachable = reachableRepasFloor(floor, keeper, crates);
    final currentDistance = _assignmentDistance(crates, targets);
    final pulls = <(_Pull, int)>[];
    for (final crate in crates) {
      for (final direction in RepasDirection.values) {
        final source = crate - direction.offset;
        final behind = source - direction.offset;
        if (!reachable.contains(source) ||
            !floor.contains(behind) ||
            crates.contains(source) ||
            crates.contains(behind) ||
            (previous?.source == crate &&
                previous?.direction == _opposite(direction))) {
          continue;
        }
        final pull = _Pull(crate, source, behind, direction);
        final moved = {...crates}
          ..remove(crate)
          ..add(source);
        if (visited.contains(_cratesKey(moved))) continue;
        pulls.add((pull, _assignmentDistance(moved, targets)));
      }
    }
    final improving = pulls
        .where((candidate) => candidate.$2 > currentDistance)
        .toList();
    final stable = pulls
        .where((candidate) => candidate.$2 == currentDistance)
        .toList();
    final candidates = improving.isNotEmpty ? improving : stable;
    if (candidates.isEmpty) break;
    final best = candidates.fold(
      0,
      (best, candidate) => max(best, candidate.$2),
    );
    final useful = candidates
        .where((candidate) => candidate.$2 >= best - 1)
        .toList();
    final pull = useful[random.nextInt(useful.length)].$1;
    crates = {...crates}
      ..remove(pull.crate)
      ..add(pull.source);
    keeper = pull.behind;
    previous = pull;
    performed++;
    history.add(pull);
    visited.add(_cratesKey(crates));
  }
  if (performed < targets.length || targets.every(crates.contains)) return null;
  return _ScrambledBoard(
    crates,
    keeper,
    performed,
    _solution(floor, crates, keeper, history),
  );
}

RepasDirection _opposite(RepasDirection direction) => switch (direction) {
  RepasDirection.north => RepasDirection.south,
  RepasDirection.east => RepasDirection.west,
  RepasDirection.south => RepasDirection.north,
  RepasDirection.west => RepasDirection.east,
};

List<String> _rows(
  int side,
  Set<RepasPosition> floor,
  Set<RepasPosition> targets,
  Set<RepasPosition> crates,
  RepasPosition keeper,
) => [
  for (var y = 0; y < side; y++)
    [
      for (var x = 0; x < side; x++)
        _cell(RepasPosition(x, y), floor, targets, crates, keeper),
    ].join(),
];

String _cell(
  RepasPosition position,
  Set<RepasPosition> floor,
  Set<RepasPosition> targets,
  Set<RepasPosition> crates,
  RepasPosition keeper,
) {
  if (!floor.contains(position)) return '#';
  if (position == keeper) return targets.contains(position) ? 'S' : 's';
  if (crates.contains(position)) return targets.contains(position) ? 'C' : 'c';
  return targets.contains(position) ? 't' : '.';
}

int _distance(RepasPosition first, RepasPosition second) =>
    (first.x - second.x).abs() + (first.y - second.y).abs();

int _assignmentDistance(
  Set<RepasPosition> crates,
  Set<RepasPosition> targets,
) => _assign(crates.toList(), targets.toList(), 0);

int _assign(
  List<RepasPosition> crates,
  List<RepasPosition> targets,
  int index,
) {
  if (index == crates.length) return 0;
  var best = 1 << 30;
  for (var targetIndex = 0; targetIndex < targets.length; targetIndex++) {
    final target = targets.removeAt(targetIndex);
    best = min(
      best,
      _distance(crates[index], target) + _assign(crates, targets, index + 1),
    );
    targets.insert(targetIndex, target);
  }
  return best;
}

List<RepasDirection> _solution(
  Set<RepasPosition> floor,
  Set<RepasPosition> initialCrates,
  RepasPosition initialKeeper,
  List<_Pull> history,
) {
  var crates = {...initialCrates};
  var keeper = initialKeeper;
  final solution = <RepasDirection>[];
  for (final pull in history.reversed) {
    solution.addAll(_path(floor, keeper, pull.behind, crates));
    solution.add(pull.direction);
    crates = {...crates}
      ..remove(pull.source)
      ..add(pull.crate);
    keeper = pull.source;
  }
  return solution;
}

List<RepasDirection> _path(
  Set<RepasPosition> floor,
  RepasPosition start,
  RepasPosition destination,
  Set<RepasPosition> crates,
) {
  final queue = <RepasPosition>[start];
  final previous = <RepasPosition, (RepasPosition, RepasDirection)>{};
  final visited = {start};
  for (var index = 0; index < queue.length; index++) {
    final position = queue[index];
    if (position == destination) break;
    for (final direction in RepasDirection.values) {
      final next = position + direction.offset;
      if (!floor.contains(next) ||
          crates.contains(next) ||
          !visited.add(next)) {
        continue;
      }
      previous[next] = (position, direction);
      queue.add(next);
    }
  }
  final path = <RepasDirection>[];
  var current = destination;
  while (current != start) {
    final step = previous[current]!;
    path.add(step.$2);
    current = step.$1;
  }
  return path.reversed.toList();
}

String _cratesKey(Set<RepasPosition> crates) {
  final sorted = crates.toList()
    ..sort(
      (first, second) => first.y == second.y
          ? first.x.compareTo(second.x)
          : first.y.compareTo(second.y),
    );
  return sorted.map((position) => '${position.x},${position.y}').join(';');
}

class _Pull {
  const _Pull(this.crate, this.source, this.behind, this.direction);

  final RepasPosition crate;
  final RepasPosition source;
  final RepasPosition behind;
  final RepasDirection direction;
}

class _ScrambledBoard {
  const _ScrambledBoard(this.crates, this.keeper, this.pushes, this.solution);

  final Set<RepasPosition> crates;
  final RepasPosition keeper;
  final int pushes;
  final List<RepasDirection> solution;
}
