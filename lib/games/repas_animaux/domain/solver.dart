import 'dart:collection';

import 'models.dart';

int? minimumRepasPushes(RepasLevelDefinition level, {int maxStates = 100000}) =>
    minimumRepasPushesFor(
      floor: level.floor,
      targets: level.targets,
      crates: level.initialCrates,
      keeper: level.initialKeeper,
      maxStates: maxStates,
    );

int? minimumRepasPushesFor({
  required Set<RepasPosition> floor,
  required Set<RepasPosition> targets,
  required Set<RepasPosition> crates,
  required RepasPosition keeper,
  required int maxStates,
}) {
  final queue = Queue<_SolverState>()..add(_SolverState(keeper, crates, 0));
  final visited = <String>{};
  while (queue.isNotEmpty && visited.length < maxStates) {
    final state = queue.removeFirst();
    final reachable = _reachable(floor, state.keeper, state.crates);
    if (!visited.add(_stateKey(reachable, state.crates))) continue;
    if (targets.every(state.crates.contains)) return state.pushes;
    for (final crate in state.crates) {
      for (final direction in RepasDirection.values) {
        final destination = crate + direction.offset;
        final behind = crate - direction.offset;
        if (!reachable.contains(behind) ||
            !floor.contains(destination) ||
            state.crates.contains(destination) ||
            _isDeadCorner(destination, floor, targets)) {
          continue;
        }
        queue.add(
          _SolverState(
            crate,
            {...state.crates}
              ..remove(crate)
              ..add(destination),
            state.pushes + 1,
          ),
        );
      }
    }
  }
  return null;
}

Set<RepasPosition> reachableRepasFloor(
  Set<RepasPosition> floor,
  RepasPosition start,
  Set<RepasPosition> crates,
) => _reachable(floor, start, crates);

Set<RepasPosition> _reachable(
  Set<RepasPosition> floor,
  RepasPosition start,
  Set<RepasPosition> crates,
) {
  final queue = Queue<RepasPosition>()..add(start);
  final reached = <RepasPosition>{};
  while (queue.isNotEmpty) {
    final position = queue.removeFirst();
    if (!reached.add(position)) continue;
    for (final direction in RepasDirection.values) {
      final next = position + direction.offset;
      if (floor.contains(next) &&
          !crates.contains(next) &&
          !reached.contains(next)) {
        queue.add(next);
      }
    }
  }
  return reached;
}

bool _isDeadCorner(
  RepasPosition position,
  Set<RepasPosition> floor,
  Set<RepasPosition> targets,
) {
  if (targets.contains(position)) return false;
  final north = !floor.contains(position + RepasDirection.north.offset);
  final east = !floor.contains(position + RepasDirection.east.offset);
  final south = !floor.contains(position + RepasDirection.south.offset);
  final west = !floor.contains(position + RepasDirection.west.offset);
  return (north || south) && (east || west);
}

String _stateKey(Set<RepasPosition> reachable, Set<RepasPosition> crates) {
  final region = reachable.reduce(_firstPosition);
  final sorted = crates.toList()..sort(_comparePositions);
  return '${region.x},${region.y}|'
      '${sorted.map((position) => '${position.x},${position.y}').join(';')}';
}

RepasPosition _firstPosition(RepasPosition first, RepasPosition second) =>
    _comparePositions(first, second) <= 0 ? first : second;

int _comparePositions(RepasPosition first, RepasPosition second) =>
    first.y == second.y
    ? first.x.compareTo(second.x)
    : first.y.compareTo(second.y);

class _SolverState {
  const _SolverState(this.keeper, this.crates, this.pushes);

  final RepasPosition keeper;
  final Set<RepasPosition> crates;
  final int pushes;
}
