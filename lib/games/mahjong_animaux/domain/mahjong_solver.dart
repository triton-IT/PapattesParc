import 'dart:math';

import 'models.dart';

typedef MahjongPair = ({int first, int second});

class MahjongSolution {
  const MahjongSolution(this.moves, this.complexity, this.exploredStates);

  final List<MahjongPair> moves;
  final int complexity;
  final int exploredStates;
}

class MahjongSolver {
  MahjongSolver(this.positions, this.symbols)
    : _above = List.filled(positions.length, BigInt.zero),
      _left = List.filled(positions.length, BigInt.zero),
      _right = List.filled(positions.length, BigInt.zero) {
    _buildBlockers();
  }

  final List<MahjongPosition> positions;
  final List<int> symbols;
  final List<BigInt> _above;
  final List<BigInt> _left;
  final List<BigInt> _right;

  MahjongSolution? solve(List<bool> present, {int maxStates = 8000}) {
    final start = _mask(present);
    final path = <MahjongPair>[];
    final dead = <BigInt>{};
    var explored = 0;
    var exhausted = false;

    bool search(BigInt state) {
      if (state == BigInt.zero) return true;
      if (dead.contains(state)) return false;
      if (++explored > maxStates) {
        exhausted = true;
        return false;
      }
      final moves = availablePairs(state);
      for (final move in moves) {
        final next = state & ~(_bit(move.first) | _bit(move.second));
        path.add(move);
        if (search(next)) return true;
        path.removeLast();
        if (exhausted) return false;
      }
      dead.add(state);
      return false;
    }

    if (!search(start)) return null;
    return MahjongSolution(List.of(path), _complexity(start, path), explored);
  }

  MahjongSolution evaluate(List<bool> present, List<MahjongPair> moves) =>
      MahjongSolution(moves, _complexity(_mask(present), moves), 0);

  List<MahjongPair> geometricRemovalOrder(List<bool> present) {
    var state = _mask(present);
    final order = <MahjongPair>[];
    while (state != BigInt.zero) {
      final free = freeTiles(state)
        ..sort((first, second) {
          final layer = positions[second].layer.compareTo(
            positions[first].layer,
          );
          return layer != 0 ? layer : first.compareTo(second);
        });
      if (free.length < 2) return const [];
      final pair = (first: free.first, second: free.last);
      order.add(pair);
      state &= ~(_bit(pair.first) | _bit(pair.second));
    }
    return order;
  }

  List<MahjongPair> availablePairs(BigInt state) {
    final bySymbol = <int, List<int>>{};
    for (final id in freeTiles(state)) {
      bySymbol.putIfAbsent(symbols[id], () => []).add(id);
    }
    return [
      for (final ids in bySymbol.values)
        for (var first = 0; first < ids.length; first++)
          for (var second = first + 1; second < ids.length; second++)
            (first: ids[first], second: ids[second]),
    ];
  }

  List<int> freeTiles(BigInt state) => [
    for (var id = 0; id < positions.length; id++)
      if (_contains(state, id) && _isFree(id, state)) id,
  ];

  int _complexity(BigInt start, List<MahjongPair> solution) {
    var state = start;
    var score = positions.length * positions.length ~/ 16;
    for (final move in solution) {
      final choices = availablePairs(state);
      final free = freeTiles(state);
      score += min(choices.length - 1, 12) * 3;
      score += max(0, free.length - 4);
      final sameSymbol = free
          .where((id) => symbols[id] == symbols[move.first])
          .length;
      if (sameSymbol > 2) score += (sameSymbol - 2) * 5;
      state &= ~(_bit(move.first) | _bit(move.second));
    }
    return score;
  }

  bool _isFree(int id, BigInt state) =>
      (state & _above[id]) == BigInt.zero &&
      ((state & _left[id]) == BigInt.zero ||
          (state & _right[id]) == BigInt.zero);

  void _buildBlockers() {
    for (var id = 0; id < positions.length; id++) {
      final position = positions[id];
      for (var otherId = 0; otherId < positions.length; otherId++) {
        if (id == otherId) continue;
        final other = positions[otherId];
        if (other.layer > position.layer &&
            (other.x - position.x).abs() < 2 &&
            (other.y - position.y).abs() < 2) {
          _above[id] |= _bit(otherId);
        }
        if (other.layer != position.layer ||
            (other.y - position.y).abs() >= 2) {
          continue;
        }
        if (other.x == position.x - 2) _left[id] |= _bit(otherId);
        if (other.x == position.x + 2) _right[id] |= _bit(otherId);
      }
    }
  }

  BigInt _mask(List<bool> present) {
    var result = BigInt.zero;
    for (var id = 0; id < present.length; id++) {
      if (present[id]) result |= _bit(id);
    }
    return result;
  }

  bool _contains(BigInt state, int id) => state & _bit(id) != BigInt.zero;
  BigInt _bit(int id) => BigInt.one << id;
}
